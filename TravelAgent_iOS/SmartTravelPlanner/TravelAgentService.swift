import Foundation
import Combine
import MLX
import MLXLLM
import MLXLMCommon
import Tokenizers

/// Service for loading and running the Travel Agent LLM model
/// Uses MLX Swift for on-device inference with the fused Gemma-2B-IT model
@MainActor
class TravelAgentService: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isLoading = false
    @Published var isGenerating = false
    @Published var responseText = ""
    @Published var errorMessage: String?
    @Published var modelStatus = "Not Loaded"
    
    // MARK: - Private Properties  
    private var isModelLoaded = false
    
    private var modelContext: ModelContext?
    
    // MARK: - Initialization
    init() {
        Task {
            await loadModel()
        }
    }
    
    // MARK: - Model Loading
    
    /// Load the fused Gemma-2B-IT travel agent model
    func loadModel() async {
        guard !isModelLoaded else { return }
        
        isLoading = true
        modelStatus = "Loading model..."
        errorMessage = nil
        
        do {
            // Verify model folder exists in bundle
            guard let modelURL = Bundle.main.url(forResource: "Llama_TravelAgent", withExtension: nil) else {
                throw TravelAgentError.modelNotFound
            }
            
            print("📂 Model path: \(modelURL.path)")
            
            // Verify required files
            let requiredFiles = ["config.json", "model.safetensors", "tokenizer.json"]
            for filename in requiredFiles {
                let filePath = modelURL.appendingPathComponent(filename)
                guard FileManager.default.fileExists(atPath: filePath.path) else {
                    throw TravelAgentError.missingFile(filename)
                }
            }
            
            print("✅ All model files present")
            
            let configuration = ModelConfiguration(directory: modelURL)
            self.modelContext = try await MLXLMCommon.loadModel(configuration: configuration)
            
            isModelLoaded = true
            modelStatus = "Model Ready"
            isLoading = false
            
        } catch let error as TravelAgentError {
            errorMessage = error.localizedDescription
            modelStatus = "Load Failed"
            isLoading = false
            print("❌ Error: \(error.localizedDescription)")
        } catch {
            errorMessage = "Unexpected error: \(error.localizedDescription)"
            modelStatus = "Load Failed"
            isLoading = false
        }
    }
    
    // MARK: - Query Processing
    
    /// Process a user query and generate a response
    func query(_ input: String) async {
        guard let modelContext = modelContext, isModelLoaded else {
            errorMessage = "Model not loaded"
            return
        }
        
        isGenerating = true
        responseText = ""
        errorMessage = nil
        
        // Format prompt using ChatML template (matches our training)
        let prompt = """
        <start_of_turn>user
        \(input)<end_of_turn>
        <start_of_turn>model
        """
        
        print("📝 Query: \(input)")
        
        do {
            // Prepare input
            let lmInput = try await modelContext.processor.prepare(input: .init(prompt: .text(prompt)))
            
            let parameters = GenerateParameters(
                maxTokens: 200,
                temperature: 0.3
            )
            
            let stream = try generate(input: lmInput, parameters: parameters, context: modelContext)
            
            var accumulatedText = ""
            for await generation in stream {
                switch generation {
                case .chunk(let text):
                    accumulatedText += text
                    responseText = accumulatedText
                default: break
                }
            }
            
            // Parse and execute tools if present
            if responseText.contains("call:{") {
                await parseAndExecuteTool()
            }
            
        } catch {
            print("❌ Generation Error: \(error)")
            errorMessage = "Generation failed: \(error.localizedDescription)"
        }
        
        isGenerating = false
    }
    
    // MARK: - Tool Execution
    
    private func parseAndExecuteTool() async {
        guard let jsonStart = responseText.range(of: "call:")?.upperBound else { return }
        
        let jsonString = String(responseText[jsonStart...])
        
        do {
            guard let data = jsonString.data(using: .utf8) else { return }
            let toolCall = try JSONDecoder().decode(ToolCall.self, from: data)
            
            print("🔧 Tool: \(toolCall.tool)")
            
            switch toolCall.tool {
            case "search_places":
                await executeSearchPlaces(query: toolCall.parameters["query"] ?? "")
            case "get_weather":
                await executeGetWeather(location: toolCall.parameters["location_name"] ?? "")
            case "search_web":
                await executeSearchWeb(query: toolCall.parameters["query"] ?? "")
            default:
                print("⚠️ Unknown tool: \(toolCall.tool)")
            }
        } catch {
            print("⚠️ Failed to parse tool: \(error)")
        }
    }
    
    // MARK: - Tool Implementations
    
    private func executeSearchPlaces(query: String) async {
        print("🗺️ MapKit: \(query)")
        responseText += "\n\n📍 [MapKit integration coming soon...]"
    }
    
    private func executeGetWeather(location: String) async {
        print("🌤️ Weather: \(location)")
        responseText += "\n\n🌤️ [Weather API integration coming soon...]"
    }
    
    private func executeSearchWeb(query: String) async {
        print("🌐 Web: \(query)")
        responseText += "\n\n🔍 [Web search integration coming soon...]"
    }
}

// MARK: - Supporting Types

struct ToolCall: Codable {
    let tool: String
    let parameters: [String: String]
}

enum TravelAgentError: LocalizedError {
    case modelNotFound
    case missingFile(String)
    
    var errorDescription: String? {
        switch self {
        case .modelNotFound:
            return "Llama_TravelAgent folder not found. Please add it to the project."
        case .missingFile(let file):
            return "Missing: \(file)"
        }
    }
}
