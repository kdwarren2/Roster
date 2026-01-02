import SwiftUI

struct APIKeySettingsView: View {
    @AppStorage("anthropicAPIKey") private var apiKey: String = ""
    @AppStorage("useAnthropicAPI") private var useAnthropicAPI: Bool = false
    
    @State private var showingAPIKey = false
    @State private var tempAPIKey: String = ""
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Use Anthropic API", isOn: $useAnthropicAPI)
                    
                    if useAnthropicAPI {
                        Text("Uses Claude's vision for better OCR accuracy")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("OCR Method")
                }
                
                if useAnthropicAPI {
                    Section {
                        HStack {
                            if showingAPIKey {
                                TextField("sk-ant-...", text: $tempAPIKey)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .font(.system(.body, design: .monospaced))
                            } else {
                                Text(apiKey.isEmpty ? "Not set" : String(repeating: "•", count: 20))
                                    .foregroundColor(apiKey.isEmpty ? .secondary : .primary)
                                Spacer()
                            }
                            
                            Button(action: {
                                showingAPIKey.toggle()
                                if showingAPIKey {
                                    tempAPIKey = apiKey
                                } else {
                                    apiKey = tempAPIKey
                                }
                            }) {
                                Image(systemName: showingAPIKey ? "eye.slash" : "eye")
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        if apiKey.isEmpty {
                            Link("Get API Key →", destination: URL(string: "https://console.anthropic.com/")!)
                                .font(.caption)
                        }
                        
                        if showingAPIKey && !tempAPIKey.isEmpty {
                            Button("Save API Key") {
                                apiKey = tempAPIKey
                                showingAPIKey = false
                            }
                            .font(.headline)
                        }
                    } header: {
                        Text("API Key")
                    } footer: {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Your API key is stored securely on device")
                            Text("Get your key from console.anthropic.com")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    
                    Section {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Better accuracy for complex rosters")
                            }
                            
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Handles multiple columns easily")
                            }
                            
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Direct text output (no parsing needed)")
                            }
                            
                            HStack(spacing: 8) {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.blue)
                                Text("~$0.01 per roster scan")
                            }
                        }
                        .font(.caption)
                    } header: {
                        Text("Benefits")
                    }
                }
            }
            .navigationTitle("API Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    APIKeySettingsView()
}
