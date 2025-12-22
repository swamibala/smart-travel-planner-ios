import SwiftUI

struct ContentView: View {
    @StateObject private var gemmaService = GemmaService()
    @State private var prompt: String = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("Gemma 3 1B Sanity Check")
                .font(.headline)
            
            // Model Loading State
            if gemmaService.isModelLoading {
                VStack {
                    ProgressView()
                    Text("Loading Model into Memory...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else if gemmaService.isModelLoaded {
                Text("● Model Ready")
                    .foregroundColor(.green)
                    .font(.caption)
                    .fontWeight(.bold)
            } else if let error = gemmaService.errorMessage, !gemmaService.isModelLoaded {
                VStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text("Model Load Error")
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

            // Generation Loading Indicator
            if gemmaService.isGenerating {
                HStack {
                    ProgressView()
                    Text("Streaming response...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else if let error = gemmaService.errorMessage, gemmaService.isModelLoaded {
                // Runtime generation error
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }

            // Input Area
            HStack(spacing: 12) {
                TextField("Enter your prompt...", text: $prompt)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disabled(!gemmaService.isModelLoaded || gemmaService.isGenerating)
                    .submitLabel(.send)
                    .onSubmit {
                        if !prompt.isEmpty && gemmaService.isModelLoaded && !gemmaService.isGenerating {
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
                        .background(!gemmaService.isModelLoaded || gemmaService.isGenerating || prompt.isEmpty ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(prompt.isEmpty || !gemmaService.isModelLoaded || gemmaService.isGenerating)
            }
            .padding(.bottom)
        }
        .padding()
    }
}
