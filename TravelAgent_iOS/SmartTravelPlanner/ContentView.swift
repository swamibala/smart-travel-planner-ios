import SwiftUI

struct ContentView: View {
    @StateObject private var agent = TravelAgentService()
    @State private var userInput = ""
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
               // ... (existing content logic is inside) ...
                // Status bar
                statusBar
                
                Divider()
                
                // Main content
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            if agent.responseText.isEmpty && agent.errorMessage == nil {
                                welcomeView
                            }
                            
                            if let error = agent.errorMessage {
                                errorView(error)
                            }
                            
                            if !agent.responseText.isEmpty {
                                responseView
                            }
                            
                            if agent.isGenerating {
                                generatingView
                            }
                            
                            Color.clear.frame(height: 1).id("bottom")
                        }
                        .padding()
                    }
                    .onChange(of: agent.responseText) {
                        withAnimation {
                            proxy.scrollTo("bottom")
                        }
                    }
                }
                .background(Color(white: 0.95))
                
                Divider()
                
                // Input bar
                inputBar
            }
            .navigationTitle("🧳 Travel Planner")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
        #if os(macOS)
        .frame(minWidth: 400, minHeight: 600)
        #endif
    }
    
    // MARK: - Status Bar
    
    private var statusBar: some View {
        HStack {
            Circle()
                .fill(statusColor)
                .frame(width: 10, height: 10)
            
            Text(agent.modelStatus)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            if agent.isLoading {
                ProgressView().scaleEffect(0.8)
            }
        }
        .padding()
        .background(Color(white: 0.98))
    }
    
    private var statusColor: Color {
        if agent.isLoading { return .orange }
        else if agent.modelStatus == "Model Ready" { return .green }
        else if agent.modelStatus.contains("Failed") { return .red }
        else { return .gray }
    }
    
    // MARK: - Welcome View
    
    private var welcomeView: some View {
        VStack(spacing: 16) {
            Image(systemName: "airplane.departure")
                .font(.system(size: 50))
                .foregroundColor(.blue)
            
            Text("Smart Travel Planner")
                .font(.title2).bold()
            
            Text("Ask me about places, weather, or travel info")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Try:")
                    .font(.caption).foregroundColor(.secondary)
                
                ForEach(["Where is Tower Bridge?", "What's the weather in London?", "Find coffee near Hyde Park"], id: \.self) { sample in
                    Button(action: { userInput = sample }) {
                        Text("\"\(sample)\"")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding(.top)
        }
        .padding()
    }
    
    // MARK: - Error View
    
    private func errorView(_ message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            Text(message).font(.subheadline)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Response View
    
    private var responseView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.purple)
                Text("AI Response")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(agent.responseText)
                .font(.body)
                .textSelection(.enabled)
        }
        .padding()
        .background(.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2)
    }
    
    // MARK: - Generating View
    
    private var generatingView: some View {
        HStack {
            ProgressView().scaleEffect(0.8)
            Text("Thinking...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
    }
    
    // MARK: - Input Bar
    
    private var inputBar: some View {
        HStack(spacing: 12) {
            TextField("Ask about travel...", text: $userInput)
                .textFieldStyle(.roundedBorder)
                .padding(8)
                .onSubmit(sendQuery)
            
            Button(action: sendQuery) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(canSend ? .blue : .gray)
            }
            .disabled(!canSend)
        }
        .padding()
        .background(.white)
    }
    
    private var canSend: Bool {
        !userInput.trimmingCharacters(in: .whitespaces).isEmpty &&
        !agent.isLoading &&
        !agent.isGenerating &&
        agent.modelStatus == "Model Ready"
    }
    
    private func sendQuery() {
        guard canSend else { return }
        
        let query = userInput.trimmingCharacters(in: .whitespaces)
        userInput = ""
        isInputFocused = false
        
        Task {
            await agent.query(query)
        }
    }
}

#Preview {
    ContentView()
}
