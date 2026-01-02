import SwiftUI
import PhotosUI

struct ContentView: View {
    @StateObject private var settingsManager = SettingsManager()
    @State private var showingImagePicker = false
    @State private var showingDocumentPicker = false
    @State private var showingCamera = false
    @State private var showingURLInput = false
    @State private var showingSettings = false
    @State private var selectedImage: UIImage?
    @State private var selectedPDFURL: URL?
    @State private var extractedText = ""
    @State private var navigateToConfiguration = false
    @State private var isProcessing = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var urlString = ""
    @State private var parsedPlayersFromWeb: [Player] = []
    @AppStorage("useAnthropicAPI") private var useAnthropicAPI = false
    @AppStorage("anthropicAPIKey") private var apiKey = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 30) {
                    HeaderSection()
                    ImportOptionsSection(
                        showingCamera: $showingCamera,
                        showingImagePicker: $showingImagePicker,
                        showingDocumentPicker: $showingDocumentPicker,
                        showingURLInput: $showingURLInput
                    )
                    SettingsSection(showingSettings: $showingSettings)
                    RecentTeamsSection(settingsManager: settingsManager)
                }
                .padding(.bottom, 20)
            }
            .navigationTitle("RosterIQ")
            .navigationDestination(isPresented: $navigateToConfiguration) {
                if !parsedPlayersFromWeb.isEmpty {
                    URLRosterConfigView(
                        players: parsedPlayersFromWeb,
                        settingsManager: settingsManager
                    )
                } else if let image = selectedImage {
                    ConfigurationView(
                        sourceImage: image,
                        sourcePDF: nil,
                        extractedText: extractedText,
                        settingsManager: settingsManager
                    )
                } else if let pdfURL = selectedPDFURL {
                    ConfigurationView(
                        sourceImage: nil,
                        sourcePDF: pdfURL,
                        extractedText: extractedText,
                        settingsManager: settingsManager
                    )
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $selectedImage, sourceType: .photoLibrary) {
                    if let image = selectedImage {
                        processImage(image)
                    }
                }
            }
            .sheet(isPresented: $showingCamera) {
                ImagePicker(image: $selectedImage, sourceType: .camera) {
                    if let image = selectedImage {
                        processImage(image)
                    }
                }
            }
            .sheet(isPresented: $showingDocumentPicker) {
                DocumentPicker(pdfURL: $selectedPDFURL) {
                    if let url = selectedPDFURL {
                        processPDF(url)
                    }
                }
            }
            .sheet(isPresented: $showingURLInput) {
                URLInputView(urlString: $urlString, onImport: { url in
                    processURL(url)
                })
            }
            .sheet(isPresented: $showingSettings) {
                APIKeySettingsView()
            }
            .overlay {
                if isProcessing {
                    ProcessingOverlay(useAnthropicAPI: useAnthropicAPI, apiKey: apiKey)
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func processImage(_ image: UIImage) {
        isProcessing = true
        
        Task {
            do {
                let ocrService = OCRService()
                extractedText = try await ocrService.extractText(
                    from: image,
                    useAnthropicAPI: useAnthropicAPI,
                    apiKey: apiKey
                )
                
                await MainActor.run {
                    isProcessing = false
                    navigateToConfiguration = true
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                    errorMessage = "Failed to scan image: \(error.localizedDescription)"
                    showingError = true
                }
            }
        }
    }
    
    private func processPDF(_ url: URL) {
        isProcessing = true
        
        Task {
            do {
                let ocrService = OCRService()
                extractedText = try await ocrService.extractText(from: url)
                
                await MainActor.run {
                    isProcessing = false
                    navigateToConfiguration = true
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                    errorMessage = "Failed to process PDF: \(error.localizedDescription)"
                    showingError = true
                }
            }
        }
    }
    
    private func processURL(_ urlString: String) {
        isProcessing = true
        
        Task {
            do {
                let scraper = WebRosterParser()
                let players = try await scraper.fetchRoster(from: urlString)
                
                await MainActor.run {
                    parsedPlayersFromWeb = players
                    isProcessing = false
                    navigateToConfiguration = true
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                    errorMessage = "Failed to import from URL: \(error.localizedDescription)"
                    showingError = true
                }
            }
        }
    }
}

// MARK: - Sub-Views (Broken down to avoid compiler timeout)

struct HeaderSection: View {
    var body: some View {
        VStack(spacing: 15) {
            Image(systemName: "doc.text.viewfinder")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text("Import a Roster")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Scan from photo, PDF, or team website")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 40)
    }
}

struct ImportOptionsSection: View {
    @Binding var showingCamera: Bool
    @Binding var showingImagePicker: Bool
    @Binding var showingDocumentPicker: Bool
    @Binding var showingURLInput: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            ImportButton(
                icon: "camera.fill",
                title: "Take Photo",
                subtitle: "Scan a physical roster",
                action: { showingCamera = true }
            )
            
            ImportButton(
                icon: "photo.fill",
                title: "Choose from Photos",
                subtitle: "Select an existing image",
                action: { showingImagePicker = true }
            )
            
            ImportButton(
                icon: "doc.fill",
                title: "Import PDF",
                subtitle: "Load a PDF roster",
                action: { showingDocumentPicker = true }
            )
            
            ImportButton(
                icon: "link",
                title: "Import from URL",
                subtitle: "Fetch from team website",
                action: { showingURLInput = true }
            )
        }
        .padding(.horizontal)
    }
}

struct ImportButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 15) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

struct SettingsSection: View {
    @Binding var showingSettings: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            Divider()
                .padding(.vertical, 10)
            
            Button(action: { showingSettings = true }) {
                HStack {
                    Image(systemName: "gear")
                        .foregroundColor(.blue)
                    Text("AI Settings (Optional)")
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding(.horizontal)
    }
}

struct RecentTeamsSection: View {
    @ObservedObject var settingsManager: SettingsManager
    
    var body: some View {
        if !settingsManager.recentTeams.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Recent Teams")
                    .font(.headline)
                    .padding(.horizontal)
                
                ForEach(settingsManager.recentTeams) { team in
                    RecentTeamRow(team: team)
                }
            }
        }
    }
}

struct RecentTeamRow: View {
    let team: TeamSettings
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(team.schoolName)
                    .font(.headline)
                Text("Designator: \(team.designator)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(team.lastUsed, style: .relative)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
        .padding(.horizontal)
    }
}

struct ProcessingOverlay: View {
    let useAnthropicAPI: Bool
    let apiKey: String
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                Text(useAnthropicAPI && !apiKey.isEmpty ? "AI-enhanced scanning..." : "Scanning roster...")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding(30)
            .background(Color.gray.opacity(0.9))
            .cornerRadius(16)
        }
    }
}

#Preview {
    ContentView()
}
