import SwiftUI

struct ContentView: View {
    @StateObject private var gemmaService = GemmaService()
    @State private var prompt: String = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("Smart Travel Planner")
                .font(.headline)
            
            // Dual Model Loading State
            if gemmaService.isModelLoading {
                VStack {
                    ProgressView()
                    Text("Loading Models...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                // Show status for both models
                HStack(spacing: 16) {
                    ModelStatusBadge(
                        icon: "🔧",
                        name: "Tool",
                        isLoaded: gemmaService.isToolModelLoaded
                    )
                    ModelStatusBadge(
                        icon: "💬",
                        name: "Chat",
                        isLoaded: gemmaService.isChatModelLoaded
                    )
                }
            }
            
            // Error Display
            if let error = gemmaService.errorMessage, !gemmaService.isModelLoading {
                VStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text("Error")
                        .font(.caption)
                        .fontWeight(.bold)
                    Text(error)
                        .font(.caption2)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            }

            // Output / Streaming Area
            ScrollViewReader { proxy in
                ScrollView {
                    Text(gemmaService.responseText)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .id("bottom")
                }
                .background(Color(UIColor.systemGray6))
                .cornerRadius(12)
                .onChange(of: gemmaService.responseText) { _ in
                    withAnimation {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }
            }

            // Pipeline Progress Indicator
            if gemmaService.isGenerating {
                HStack {
                    ProgressView()
                    Text(gemmaService.pipelineStep)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Input Area
            HStack(spacing: 12) {
                TextField("Ask me anything about travel...", text: $prompt)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disabled(!gemmaService.isAnyModelLoaded || gemmaService.isGenerating)
                    .submitLabel(.send)
                    .onSubmit {
                        if !prompt.isEmpty && gemmaService.isAnyModelLoaded && !gemmaService.isGenerating {
                            gemmaService.generateStream(prompt: prompt)
                        }
                    }

                Button(action: {
                    gemmaService.generateStream(prompt: prompt)
                    // Dismiss keyboard
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }) {
                    Text("Send")
                        .fontWeight(.semibold)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(!gemmaService.isAnyModelLoaded || gemmaService.isGenerating || prompt.isEmpty ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(prompt.isEmpty || !gemmaService.isAnyModelLoaded || gemmaService.isGenerating)
            }
            .padding(.bottom)
        }
        .padding()
    }
}

// MARK: - Model Status Badge Component
struct ModelStatusBadge: View {
    let icon: String
    let name: String
    let isLoaded: Bool
    
    var body: some View {
        HStack(spacing: 6) {
            Text(icon)
                .font(.caption)
            Text(name)
                .font(.caption2)
                .fontWeight(.medium)
            Circle()
                .fill(isLoaded ? Color.green : Color.gray)
                .frame(width: 6, height: 6)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(isLoaded ? Color.green.opacity(0.1) : Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}
