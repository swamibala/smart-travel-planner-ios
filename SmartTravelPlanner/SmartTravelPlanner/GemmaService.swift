import Foundation
import Combine
import MediaPipeTasksGenAI

class GemmaService: ObservableObject {
    @Published var responseText: String = ""
    @Published var isModelLoading: Bool = false
    @Published var isGenerating: Bool = false
    @Published var isModelLoaded: Bool = false
    @Published var errorMessage: String?

    private var llmInference: LlmInference?
    private let modelName = "gemma3-1b-it-int4"
    private let modelExtension = "task"

    init() {
        loadModel()
    }

    private func loadModel() {
        isModelLoading = true
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            do {
                guard let modelPath = Bundle.main.path(forResource: self.modelName, ofType: self.modelExtension) else {
                    throw NSError(domain: "GemmaService", code: 1, 
                                userInfo: [NSLocalizedDescriptionKey: "Model file '\(self.modelName).\(self.modelExtension)' not found in app bundle. Please add the .task file to your Xcode project."])
                }

                let options = LlmInference.Options(modelPath: modelPath)
                options.maxTokens = 512

                self.llmInference = try LlmInference(options: options)

                DispatchQueue.main.async {
                    self.isModelLoaded = true
                    self.isModelLoading = false
                    self.errorMessage = nil
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to load model: \(error.localizedDescription)"
                    self.isModelLoading = false
                    self.isModelLoaded = false
                }
            }
        }
    }

    func generateStream(prompt: String) {
        guard let llmInference = llmInference, isModelLoaded else {
            self.errorMessage = "Model is not loaded."
            print("Debug: Model not loaded or llmInference is nil")
            return
        }

        self.responseText = ""
        self.isGenerating = true
        self.errorMessage = nil
        print("Debug: Starting generation for prompt: \(prompt)")
        // Apply Gemma usage formatting
        // <start_of_turn>user\nPROMPT<end_of_turn>\n<start_of_turn>model\n
        let formattedPrompt = "<start_of_turn>user\n" + prompt + "<end_of_turn>\n<start_of_turn>model\n"

        // Running synchronous generation in background to avoid blocking UI
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            do {
                print("Debug: Calling llmInference.generateResponse...")
                // Fallback to synchronous generation since streaming signature is ambiguous in this version
                let result = try self.llmInference?.generateResponse(inputText: formattedPrompt)
                print("Debug: Generation finished. Result length: \(result?.count ?? 0)")
                
                DispatchQueue.main.async {
                    if let result = result {
                        self.responseText = result
                        print("Debug: UI updated with result: \(result.prefix(50))...")
                    } else {
                        print("Debug: Result was nil")
                    }
                    self.isGenerating = false
                }
            } catch {
                print("Debug: Generation error: \(error)")
                DispatchQueue.main.async {
                    self.errorMessage = "Generation error: \(error.localizedDescription)"
                    self.isGenerating = false
                }
            }
        }
    }
}
