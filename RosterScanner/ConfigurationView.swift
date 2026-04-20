import SwiftUI

struct ConfigurationView: View {
    let sourceImage: UIImage?
    let sourcePDF: URL?
    let extractedText: String
    
    @ObservedObject var settingsManager: SettingsManager
    
    @State private var teamDesignator = ""
    @State private var schoolName = ""
    @State private var selectedFormat: ExportFormat = .full
    @State private var selectedSport: SportType = .other
    @State private var parsedPlayers: [Player] = []
    @State private var navigateToPreview = false
    @State private var showingTeamPicker = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 25) {
                // Preview Image/PDF
                if let image = sourceImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                        .cornerRadius(12)
                        .shadow(radius: 5)
                } else if let pdfURL = sourcePDF {
                    HStack {
                        Image(systemName: "doc.fill")
                            .font(.largeTitle)
                            .foregroundColor(.red)
                        VStack(alignment: .leading) {
                            Text("PDF Document")
                                .font(.headline)
                            Text(pdfURL.lastPathComponent)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                }
                
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
                                        selectedSport = team.sportType
                                    }
                                }
                            
                            if !settingsManager.recentTeams.isEmpty {
                                Button(action: {
                                    showingTeamPicker = true
                                }) {
                                    Image(systemName: "clock.arrow.circlepath")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        
                        Text("Short abbreviation for TextExpander triggers")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(8)
                    
                    // School Name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("School Name")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        TextField("e.g., Mississippi State", text: $schoolName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Text("Full name for photo captions")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(8)
                    
                    // Sport Type
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Sport")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Picker("Sport", selection: $selectedSport) {
                            ForEach(SportType.allCases, id: \.self) { sport in
                                Text(sport.rawValue).tag(sport)
                            }
                        }
                        .pickerStyle(.segmented)
                        
                        Text(selectedSport.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(8)
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
                    .pickerStyle(.segmented)
                    
                    // Format Preview
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Example:")
                            .font(.caption)
                            .fontWeight(.medium)
                        
                        let samplePlayer = Player(number: "25", name: "John Smith", position: "QB")
                        let sampleTrigger = selectedSport.allowsDuplicateNumbers ? 
                            "\(teamDesignator.isEmpty ? "m" : teamDesignator)25o" :
                            "\(teamDesignator.isEmpty ? "m" : teamDesignator)25"
                        let sampleExpansion = selectedFormat.formatPlayer(
                            samplePlayer,
                            designator: teamDesignator.isEmpty ? "m" : teamDesignator,
                            schoolName: schoolName.isEmpty ? "School Name" : schoolName,
                            sportType: selectedSport
                        ).components(separatedBy: "\t").last ?? ""
                        
                        HStack(spacing: 4) {
                            Text("Trigger:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(sampleTrigger)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        
                        HStack(spacing: 4) {
                            Text("Expands to:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(sampleExpansion)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(8)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                
                // Continue Button
                Button(action: {
                    parseAndContinue()
                }) {
                    Text("Continue to Preview")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(canContinue ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .disabled(!canContinue)
                .padding(.top, 10)
            }
            .padding()
        }
        .navigationTitle("Configure")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $navigateToPreview) {
            RosterPreviewView(
                players: parsedPlayers,
                teamDesignator: teamDesignator,
                schoolName: schoolName,
                exportFormat: selectedFormat,
                sportType: selectedSport,
                settingsManager: settingsManager
            )
        }
        .sheet(isPresented: $showingTeamPicker) {
            TeamPickerView(
                teams: settingsManager.recentTeams,
                selectedDesignator: $teamDesignator,
                selectedSchoolName: $schoolName,
                selectedSport: $selectedSport
            )
        }
    }
    
    private var canContinue: Bool {
        !teamDesignator.isEmpty && !schoolName.isEmpty
    }
    
    private func parseAndContinue() {
        let parser = RosterParser()
        parsedPlayers = parser.smartParse(extractedText)
        
        // Save team settings
        settingsManager.saveTeam(designator: teamDesignator, schoolName: schoolName, sportType: selectedSport)
        
        navigateToPreview = true
    }
}

// Team Picker Sheet
struct TeamPickerView: View {
    let teams: [TeamSettings]
    @Binding var selectedDesignator: String
    @Binding var selectedSchoolName: String
    @Binding var selectedSport: SportType
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            List(teams) { team in
                Button(action: {
                    selectedDesignator = team.designator
                    selectedSchoolName = team.schoolName
                    selectedSport = team.sportType
                    dismiss()
                }) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(team.schoolName)
                            .font(.headline)
                        HStack {
                            Text("Designator: \(team.designator)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("•")
                                .foregroundColor(.secondary)
                            Text(team.sportType.rawValue)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Text("Last used: \(team.lastUsed.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Recent Teams")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}
