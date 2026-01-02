import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("useAnthropicAPI") private var useAnthropicAPI = false
    @AppStorage("anthropicAPIKey") private var apiKey = ""
    
    @State private var currentPage = 0
    @State private var showingAPIKeyInput = false
    @State private var tempAPIKey = ""
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Page content
                TabView(selection: $currentPage) {
                    // Page 1: Welcome
                    OnboardingPage(
                        icon: "photo.badge.plus",
                        iconColor: .blue,
                        title: "Welcome to\nRosterIQ",
                        description: "The fastest way to scan sports rosters and create text expansion shortcuts for game day photography.",
                        pageNumber: 0
                    )
                    .tag(0)
                    
                    // Page 2: How it works
                    OnboardingPage(
                        icon: "camera.viewfinder",
                        iconColor: .green,
                        title: "How It Works",
                        description: "Take a photo, choose your team info, and get tab-delimited text ready for TextExpander or Photo Mechanic.",
                        pageNumber: 1
                    )
                    .tag(1)
                    
                    // Page 3: Import methods
                    VStack(spacing: 30) {
                        Image(systemName: "square.3.layers.3d")
                            .font(.system(size: 80))
                            .foregroundColor(.orange)
                            .padding(.top, 60)
                        
                        Text("Multiple Import Methods")
                            .font(.title)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        VStack(alignment: .leading, spacing: 16) {
                            FeatureRow(icon: "camera.fill", text: "Photo (AI-powered OCR)", color: .blue)
                            FeatureRow(icon: "doc.fill", text: "PDF documents", color: .red)
                            FeatureRow(icon: "link", text: "Team website URLs", color: .green)
                        }
                        .padding(.horizontal, 40)
                        
                        Spacer()
                    }
                    .tag(2)
                    
                    // Page 4: AI Enhancement
                    VStack(spacing: 30) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 80))
                            .foregroundColor(.purple)
                            .padding(.top, 60)
                        
                        Text("AI-Enhanced OCR")
                            .font(.title)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        Text("For best results, use Claude AI vision (optional)")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        
                        VStack(alignment: .leading, spacing: 16) {
                            FeatureRow(icon: "checkmark.circle.fill", text: "95-99% accuracy", color: .green)
                            FeatureRow(icon: "bolt.fill", text: "Handles complex layouts", color: .orange)
                            FeatureRow(icon: "dollarsign.circle.fill", text: "~$0.01 per roster", color: .blue)
                        }
                        .padding(.horizontal, 40)
                        
                        Button(action: {
                            showingAPIKeyInput = true
                        }) {
                            HStack {
                                Image(systemName: "key.fill")
                                Text("Set Up API Key")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.purple)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal, 40)
                        
                        Button(action: {
                            currentPage = 4
                        }) {
                            Text("Skip for now")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .tag(3)
                    
                    // Page 5: Get Started
                    OnboardingPage(
                        icon: "flag.checkered",
                        iconColor: .green,
                        title: "You're Ready!",
                        description: "Start by taking a photo of a roster or importing from a URL. You can always change settings later.",
                        pageNumber: 4
                    )
                    .tag(4)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                
                // Page indicators and buttons
                VStack(spacing: 20) {
                    // Dots
                    HStack(spacing: 8) {
                        ForEach(0..<5) { index in
                            Circle()
                                .fill(currentPage == index ? Color.blue : Color.gray.opacity(0.3))
                                .frame(width: 8, height: 8)
                        }
                    }
                    
                    // Buttons
                    HStack(spacing: 20) {
                        if currentPage > 0 {
                            Button(action: {
                                withAnimation {
                                    currentPage -= 1
                                }
                            }) {
                                Text("Back")
                                    .font(.headline)
                                    .foregroundColor(.blue)
                                    .frame(width: 100)
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(12)
                            }
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            if currentPage < 4 {
                                withAnimation {
                                    currentPage += 1
                                }
                            } else {
                                completeOnboarding()
                            }
                        }) {
                            Text(currentPage == 4 ? "Get Started" : "Next")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(width: currentPage == 4 ? 200 : 100)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 20)
                }
            }
        }
        .sheet(isPresented: $showingAPIKeyInput) {
            APIKeyQuickSetupView(
                apiKey: $tempAPIKey,
                onSave: {
                    apiKey = tempAPIKey
                    useAnthropicAPI = !tempAPIKey.isEmpty
                    showingAPIKeyInput = false
                    currentPage = 4
                },
                onSkip: {
                    showingAPIKeyInput = false
                    currentPage = 4
                }
            )
        }
    }
    
    private func completeOnboarding() {
        hasCompletedOnboarding = true
        dismiss()
    }
}

struct OnboardingPage: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    let pageNumber: Int
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: icon)
                .font(.system(size: 80))
                .foregroundColor(iconColor)
                .padding(.top, 60)
            
            Text(title)
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text(description)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            Text(text)
                .font(.body)
            Spacer()
        }
    }
}

struct APIKeyQuickSetupView: View {
    @Binding var apiKey: String
    let onSave: () -> Void
    let onSkip: () -> Void
    
    @State private var showingKey = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Image(systemName: "key.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.purple)
                    .padding(.top, 40)
                
                Text("Set Up AI Enhancement")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Get superior OCR accuracy with Claude AI")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 20) {
                    Text("Steps:")
                        .font(.headline)
                    
                    HStack(alignment: .top, spacing: 12) {
                        Text("1.")
                            .fontWeight(.bold)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Visit console.anthropic.com")
                                .fontWeight(.medium)
                            Link("Open in Browser →", destination: URL(string: "https://console.anthropic.com/settings/keys")!)
                                .font(.caption)
                        }
                    }
                    
                    HStack(alignment: .top, spacing: 12) {
                        Text("2.")
                            .fontWeight(.bold)
                        Text("Create a free account and generate an API key")
                    }
                    
                    HStack(alignment: .top, spacing: 12) {
                        Text("3.")
                            .fontWeight(.bold)
                        Text("Paste your key below")
                    }
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        if showingKey {
                            TextField("sk-ant-...", text: $apiKey)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .font(.system(.body, design: .monospaced))
                        } else {
                            Text(apiKey.isEmpty ? "Not set" : String(repeating: "•", count: 20))
                                .foregroundColor(apiKey.isEmpty ? .secondary : .primary)
                            Spacer()
                        }
                        
                        Button(action: {
                            showingKey.toggle()
                        }) {
                            Image(systemName: showingKey ? "eye.slash" : "eye")
                                .foregroundColor(.blue)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    
                    Text("Cost: ~$0.01 per roster scan")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                Spacer()
                
                VStack(spacing: 12) {
                    Button(action: onSave) {
                        Text("Save and Continue")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(apiKey.isEmpty ? Color.gray : Color.blue)
                            .cornerRadius(12)
                    }
                    .disabled(apiKey.isEmpty)
                    
                    Button(action: onSkip) {
                        Text("Skip (use standard OCR)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .navigationTitle("AI Setup")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    OnboardingView()
}
