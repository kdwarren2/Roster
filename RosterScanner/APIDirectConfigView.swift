import SwiftUI

struct APIDirectConfigView: View {
    let sourceImage: UIImage
    @ObservedObject var settingsManager: SettingsManager
    
    @AppStorage("anthropicAPIKey") private var apiKey: String = ""
    
    @State private var teamDesignator = ""
    @State private var schoolName = ""
    @State private var selectedFormat: ExportFormat = .full
    @State private var isProcessing = false
    @State private var showingTeamPicker = false
    @State private var exportText: String?
    @State private var navigateToExport = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 25) {
                // Image Preview
                VStack(spacing: 10) {
                    Text("Roster Image")
                        .font(.headline)
                    
                    Image(uiImage: sourceImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(12)
                
                // Team Settings Section
                VStack(alignment: .leading, spacing: 15) {
                    Text("Team Information")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    // Team Designator
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Team Designator")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        HStack {
                            TextField("e.g., m, msu, miss", text: $teamDesignator)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .autocapitalization(.none)
                                .onChange(of: teamDesignator) { oldValue, newValue in
                                    if let team = settingsManager.getTeam(for: newValue) {
                                        schoolName = team.schoolName
                                    }
                                }
                            
                            if !settingsManager.recentTeams.isEmpty {
                                Button(action: {
                                    showingTeamPicker = true
                                }) {
                                    Image(systemName: "clock.arrow.circlepath")
                                        .font(.title3)
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        
                        Text("Used in triggers (e.g., 'm25o')")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // School Name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("School Name")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        TextField("e.g., Mississippi State", text: $schoolName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Text("Full name for expanded text")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                
                // Export Format Section
                VStack(alignment: .leading, spacing: 15) {
                    Text("Export Format")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Picker("Format", selection: $selectedFormat) {
                        ForEach(ExportFormat.allCases, id: \.self) { format in
                            Text(format.rawValue).tag(format)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    // Format Examples
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Example Output:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        let examplePlayer = Player(number: "25", name: "Dak Prescott", position: "QB")
                        let exampleDesignator = teamDesignator.isEmpty ? "m" : teamDesignator
                        let exampleSchool = schoolName.isEmpty ? "Mississippi State" : schoolName
                        
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Trigger: \(exampleDesignator)25o")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(4)
                                
                                Text("(o/d/k suffix)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            
                            Text("Expands to:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(selectedFormat.formatPlayer(examplePlayer, designator: exampleDesignator, schoolName: exampleSchool).components(separatedBy: "\t").last ?? "")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(4)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(8)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                
                // AI Processing Info
                HStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .foregroundColor(.purple)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Claude Vision API")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text("High accuracy OCR • Direct output • ~$0.01 per scan")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.purple.opacity(0.1))
                .cornerRadius(12)
                
                // Process Button
                Button(action: {
                    processWithAPI()
                }) {
                    HStack {
                        if isProcessing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "wand.and.stars")
                            Text("Process with AI")
                        }
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(canProcess ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(!canProcess || isProcessing)
            }
            .padding()
        }
        .navigationTitle("Configure")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $navigateToExport) {
            if let text = exportText {
                APIDirectExportView(
                    exportText: text,
                    teamDesignator: teamDesignator,
                    schoolName: schoolName
                )
            }
        }
        .sheet(isPresented: $showingTeamPicker) {
            TeamPickerView(
                teams: settingsManager.recentTeams,
                selectedDesignator: $teamDesignator,
                selectedSchoolName: $schoolName
            )
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private var canProcess: Bool {
        !teamDesignator.isEmpty && !schoolName.isEmpty && !apiKey.isEmpty
    }
    
    private func processWithAPI() {
        print("Starting API processing...")
        isProcessing = true
        
        Task {
            do {
                let apiService = AnthropicAPIService(apiKey: apiKey)
                let result = try await apiService.parseRoster(
                    from: sourceImage,
                    teamDesignator: teamDesignator,
                    schoolName: schoolName,
                    format: selectedFormat
                )
                
                print("API returned \(result.count) characters of text")
                
                await MainActor.run {
                    exportText = result
                    isProcessing = false
                    
                    // Save team settings
                    settingsManager.saveTeam(designator: teamDesignator, schoolName: schoolName)
                    
                    navigateToExport = true
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                    errorMessage = "API Error: \(error.localizedDescription)"
                    showingError = true
                    print("API Error: \(error)")
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        APIDirectConfigView(
            sourceImage: UIImage(systemName: "photo")!,
            settingsManager: SettingsManager()
        )
    }
}
