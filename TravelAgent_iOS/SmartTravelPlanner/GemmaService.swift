import Foundation
import Combine
import MediaPipeTasksGenAI

class GemmaService: ObservableObject {
    // MARK: - Published Properties
    @Published var responseText: String = ""
    @Published var isModelLoading: Bool = false
    @Published var isGenerating: Bool = false
    @Published var errorMessage: String?
    
    // Model-specific loading states
    @Published var isToolModelLoaded: Bool = false
    @Published var isChatModelLoaded: Bool = false
    
    // Pipeline status
    @Published var pipelineStep: String = ""
    
    // MARK: - Private Properties
    private var toolCallingModel: LlmInference?  // FunctionGemma for tool decisions
    private var chatModel: LlmInference?          // Gemma3-1B for chat/summarization
    private let webSearchService = WebSearchService()
    
    // Model configurations
    private let toolModelName = "functiongemma-finetuned"
    private let chatModelName = "gemma3-1b-it-int4"
    
    // MARK: - Computed Properties
    var isAnyModelLoaded: Bool {
        isToolModelLoaded || isChatModelLoaded
    }
    
    // MARK: - Initialization
    init() {
        loadModels()
    }
    
    // MARK: - Model Loading
    private func loadModels() {
        isModelLoading = true
        
        // Load both models in parallel
        let group = DispatchGroup()
        
        group.enter()
        loadToolCallingModel {
            group.leave()
        }
        
        group.enter()
        loadChatModel {
            group.leave()
        }
        
        group.notify(queue: .main) { [weak self] in
            self?.isModelLoading = false
            if self?.isToolModelLoaded == true || self?.isChatModelLoaded == true {
                print("✅ Models loaded successfully")
            }
        }
    }
    
    private func loadToolCallingModel(completion: @escaping () -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else {
                completion()
                return
            }
            
            do {
                guard let modelPath = Bundle.main.path(forResource: self.toolModelName, ofType: "task") else {
                    throw NSError(domain: "GemmaService", code: 1,
                                userInfo: [NSLocalizedDescriptionKey: "Tool model '\(self.toolModelName).task' not found"])
                }
                
                let options = LlmInference.Options(modelPath: modelPath)
                options.maxTokens = 512
                
                self.toolCallingModel = try LlmInference(options: options)
                
                DispatchQueue.main.async {
                    self.isToolModelLoaded = true
                    print("🔧 Tool Calling Model (FunctionGemma) loaded")
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Tool model error: \(error.localizedDescription)"
                    print("❌ Tool model load failed: \(error)")
                }
            }
            completion()
        }
    }
    
    private func loadChatModel(completion: @escaping () -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else {
                completion()
                return
            }
            
            do {
                guard let modelPath = Bundle.main.path(forResource: self.chatModelName, ofType: "task") else {
                    throw NSError(domain: "GemmaService", code: 3,
                                userInfo: [NSLocalizedDescriptionKey: "Chat model '\(self.chatModelName).task' not found"])
                }
                
                let options = LlmInference.Options(modelPath: modelPath)
                options.maxTokens = 1024  // Larger context for summarization
                
                self.chatModel = try LlmInference(options: options)
                
                DispatchQueue.main.async {
                    self.isChatModelLoaded = true
                    print("💬 Chat Model (Gemma3-1B) loaded")
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Chat model error: \(error.localizedDescription)"
                    print("❌ Chat model load failed: \(error)")
                }
            }
            completion()
        }
    }
    
    // MARK: - Main Generation Pipeline
    func generateStream(prompt: String) {
        guard isAnyModelLoaded else {
            self.errorMessage = "No models are loaded."
            print("❌ ERROR: No models loaded")
            return
        }
        
        print("\n" + String(repeating: "=", count: 60))
        print("🚀 NEW REQUEST STARTED")
        print("📝 User Prompt: \"\(prompt)\"")
        print(String(repeating: "=", count: 60))
        
        self.responseText = ""
        self.isGenerating = true
        self.errorMessage = nil
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.executePipeline(userPrompt: prompt)
        }
    }
    
    private func executePipeline(userPrompt: String) {
        // STEP 1: Check with FunctionGemma if tool is needed
        print("\n┌─── STEP 1: TOOL DETECTION ───────────────────────")
        print("│ Model: FunctionGemma")
        updatePipelineStep("🔍 Analyzing your request...")
        
        guard let toolCallingModel = toolCallingModel, isToolModelLoaded else {
            print("│ ⚠️ Tool model not available, using direct chat")
            print("└──────────────────────────────────────────────────\n")
            executeDirectChat(prompt: userPrompt)
            return
        }
        
        // Format prompt for FunctionGemma tool detection with proper function calling format
        let toolPrompt = """
<start_of_turn>user
You are a helpful assistant with access to the following tool:

Tool: web_search
Description: Search the web for current information
When to use: Use this when the user asks about current events, locations, recommendations, comparisons, or needs factual information that may change over time.

Examples:
- "What are the best restaurants in Paris?" -> USE web_search
- "Current weather in Tokyo" -> USE web_search
- "Where is the Eiffel Tower located?" -> USE web_search
- "Tell me about the Eiffel Tower" -> DO NOT use web_search (historical/general knowledge)
- "What is 2+2?" -> DO NOT use web_search (simple calculation)

User request: \(userPrompt)

Respond with ONLY one of these:
- "web_search" if the tool should be used
- "chat" if the tool should not be used<end_of_turn>
<start_of_turn>model
"""
        
        print("│ Querying FunctionGemma for tool decision...")
        
        do {
            let toolDecision = try toolCallingModel.generateResponse(inputText: toolPrompt)
            print("│ ✅ Decision received: \"\(toolDecision.trimmingCharacters(in: .whitespacesAndNewlines))\"")
            print("└──────────────────────────────────────────────────")
            
            // STEP 2: Execute web search if needed
            if toolDecision.lowercased().contains("web_search") || toolDecision.lowercased().contains("search") {
                print("\n🌐 Route: WEB SEARCH PIPELINE\n")
                executeWebSearchPipeline(userPrompt: userPrompt)
            } else {
                print("\n💬 Route: DIRECT CHAT\n")
                executeDirectChat(prompt: userPrompt)
            }
            
        } catch {
            print("│ ❌ Error: \(error.localizedDescription)")
            print("│ Falling back to direct chat")
            print("└──────────────────────────────────────────────────\n")
            executeDirectChat(prompt: userPrompt)
        }
    }
    
    private func executeWebSearchPipeline(userPrompt: String) {
        print("┌─── STEP 2: WEB SEARCH ───────────────────────────")
        print("│ Service: DuckDuckGo")
        updatePipelineStep("🌐 Searching the web...")
        
        // Perform web search
        Task {
            print("│ Fetching results from DuckDuckGo...")
            if let searchResults = await webSearchService.search(query: userPrompt) {
                let resultPreview = searchResults.prefix(150)
                print("│ ✅ Search completed")
                print("│ Results preview: \(resultPreview)...")
                print("└──────────────────────────────────────────────────")
                
                // STEP 3: Summarize with Gemma3-1B
                await summarizeResults(searchResults: searchResults, originalPrompt: userPrompt)
            } else {
                print("│ ❌ Search failed")
                print("└──────────────────────────────────────────────────\n")
                DispatchQueue.main.async { [weak self] in
                    self?.errorMessage = "Web search failed"
                    self?.isGenerating = false
                    self?.pipelineStep = ""
                }
            }
        }
    }
    
    private func summarizeResults(searchResults: String, originalPrompt: String) async {
        print("\n┌─── STEP 3: SUMMARIZATION ────────────────────────")
        print("│ Model: Gemma3-1B")
        updatePipelineStep("✨ Summarizing results...")
        
        guard let chatModel = chatModel, isChatModelLoaded else {
            print("│ ⚠️ Chat model not available, returning raw results")
            print("└──────────────────────────────────────────────────\n")
            DispatchQueue.main.async { [weak self] in
                self?.responseText = searchResults
                self?.isGenerating = false
                self?.pipelineStep = ""
            }
            return
        }
        
        let summarizationPrompt = """
        <start_of_turn>user
        Based on the following web search results, provide a helpful and concise answer to the question: "\(originalPrompt)"
        
        \(searchResults)
        <end_of_turn>
        <start_of_turn>model
        """
        
        print("│ Generating summary from Gemma3-1B...")
        
        do {
            let summary = try chatModel.generateResponse(inputText: summarizationPrompt)
            let summaryPreview = summary.prefix(100)
            print("│ ✅ Summary generated")
            print("│ Preview: \(summaryPreview)...")
            print("└──────────────────────────────────────────────────")
            print("\n✅ PIPELINE COMPLETE")
            print(String(repeating: "=", count: 60) + "\n")
            
            DispatchQueue.main.async { [weak self] in
                self?.responseText = summary
                self?.isGenerating = false
                self?.pipelineStep = ""
            }
        } catch {
            print("│ ❌ Error: \(error.localizedDescription)")
            print("│ Falling back to raw search results")
            print("└──────────────────────────────────────────────────")
            print("\n⚠️ PIPELINE COMPLETED WITH FALLBACK")
            print(String(repeating: "=", count: 60) + "\n")
            
            DispatchQueue.main.async { [weak self] in
                self?.responseText = searchResults
                self?.errorMessage = "Summarization failed: \(error.localizedDescription)"
                self?.isGenerating = false
                self?.pipelineStep = ""
            }
        }
    }
    
    private func executeDirectChat(prompt: String) {
        print("┌─── STEP 2: DIRECT CHAT ──────────────────────────")
        print("│ Model: Gemma3-1B")
        updatePipelineStep("💬 Generating response...")
        
        guard let chatModel = chatModel, isChatModelLoaded else {
            print("│ ❌ Chat model not available")
            print("└──────────────────────────────────────────────────\n")
            DispatchQueue.main.async { [weak self] in
                self?.errorMessage = "Chat model not available"
                self?.isGenerating = false
                self?.pipelineStep = ""
            }
            return
        }
        
        let formattedPrompt = "<start_of_turn>user\n\(prompt)<end_of_turn>\n<start_of_turn>model\n"
        print("│ Generating response from Gemma3-1B...")
        
        do {
            let result = try chatModel.generateResponse(inputText: formattedPrompt)
            let resultPreview = result.prefix(100)
            print("│ ✅ Response generated")
            print("│ Preview: \(resultPreview)...")
            print("└──────────────────────────────────────────────────")
            print("\n✅ DIRECT CHAT COMPLETE")
            print(String(repeating: "=", count: 60) + "\n")
            
            DispatchQueue.main.async { [weak self] in
                self?.responseText = result
                self?.isGenerating = false
                self?.pipelineStep = ""
            }
        } catch {
            print("│ ❌ Error: \(error.localizedDescription)")
            print("└──────────────────────────────────────────────────")
            print("\n❌ CHAT FAILED")
            print(String(repeating: "=", count: 60) + "\n")
            
            DispatchQueue.main.async { [weak self] in
                self?.errorMessage = "Chat error: \(error.localizedDescription)"
                self?.isGenerating = false
                self?.pipelineStep = ""
            }
        }
    }
    
    private func updatePipelineStep(_ step: String) {
        DispatchQueue.main.async { [weak self] in
            self?.pipelineStep = step
            print("📍 \(step)")
        }
    }
}
