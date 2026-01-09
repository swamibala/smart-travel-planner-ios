import Foundation
import Combine

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
    
    // TODO: Add MLX model and tokenizer properties when packages are configured
    // private var model: LLMModel?
    // private var tokenizer: Tokenizer?
    
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
            guard let modelURL = Bundle.main.url(forResource: "TravelAgent_Model", withExtension: nil) else {
                throw TravelAgentError.modelNotFound
            }
            
            print("📂 Model path: \(modelURL.path)")
            
            // Verify required files
            let requiredFiles = ["config.json", "model.safetensors", "tokenizer.model"]
            for filename in requiredFiles {
                let filePath = modelURL.appendingPathComponent(filename)
                guard FileManager.default.fileExists(atPath: filePath.path) else {
                    throw TravelAgentError.missingFile(filename)
                }
            }
            
            print("✅ All model files present")
            
            // TODO: Load actual MLX model when packages are configured
            // Example code (uncomment when MLX packages added):
            /*
            import MLX
            import MLXLLM
            
            let configuration = ModelConfiguration(directory: modelURL)
            let modelContainer = try await LLMModelFactory.shared.loadContainer(
                configuration: configuration
            )
            self.model = modelContainer.model
            self.tokenizer = modelContainer.tokenizer
            */
            
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
        guard isModelLoaded else {
            errorMessage = "Model not loaded"
            return
        }
        
        isGenerating = true
        responseText = ""
        errorMessage = nil
        
        // Format prompt using ChatML template (matches our training)
        let _ = """
        <start_of_turn>user
        \(input)<end_of_turn>
        <start_of_turn>model
        """
        
        print("📝 Query: \(input)")
        
        // TODO: Replace with actual MLX generation when packages configured
        // Example code (uncomment when MLX packages added):
        /*
        import MLXLLM
        
        let result = try await MLXLLM.generate(
            prompt: prompt,
            model: model!,
            tokenizer: tokenizer!,
            extraEOSTokens: ["<end_of_turn>"],
            maxTokens: 200,
            temperature: 0.3
        )
        responseText = result.output
        */
        
        // Simulated response for now
        await simulateResponse(for: input)
        
        // Parse and execute tools if present
        if responseText.contains("call:{") {
            await parseAndExecuteTool()
        }
        
        isGenerating = false
    }
    
    /// Simulate model response (temporary until MLX packages added)
    private func simulateResponse(for input: String) async {
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        let lowercased = input.lowercased()
        
        if lowercased.contains("where") || lowercased.contains("find") {
            responseText = """
            call:{"tool": "search_places", "parameters": {"query": "\(input)"}}
            """
        } else if lowercased.contains("weather") || lowercased.contains("rain") {
            let location = extractLocation(from: input) ?? "London"
            responseText = """
            call:{"tool": "get_weather", "parameters": {"location_name": "\(location)"}}
            """
        } else if lowercased.contains("ticket") || lowercased.contains("price") {
            responseText = """
            call:{"tool": "search_web", "parameters": {"query": "\(input)"}}
            """
        } else {
            responseText = "I can help you plan your trip! Try asking about places, weather, or travel information."
        }
    }
    
    private func extractLocation(from input: String) -> String? {
        let words = input.components(separatedBy: " ")
        let commonLocations = ["london", "paris", "tokyo", "new york", "rome"]
        
        for word in words {
            if commonLocations.contains(word.lowercased()) {
                return word.capitalized
            }
        }
        return nil
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
            return "TravelAgent_Model folder not found. Please add it to the project."
        case .missingFile(let file):
            return "Missing: \(file)"
        }
    }
}
