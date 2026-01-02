import SwiftUI

struct ConfigurationView: View {
    let sourceImage: UIImage?
    let sourcePDF: URL?
    let extractedText: String
    
    @ObservedObject var settingsManager: SettingsManager
    
    @State private var teamDesignator = ""
    @State private var schoolName = ""
    @State private var selectedFormat: ExportFormat = .full
    @State private var navigateToPreview = false
    @State private var parsedPlayers: [Player] = []
    @State private var showingTeamPicker = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 25) {
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
                                    // Auto-fill school name if team exists
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
                        
                        Text("This will be combined with jersey numbers (e.g., 'm25')")
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
                        Text("Example:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        let examplePlayer = Player(number: "25", name: "Dak Prescott", position: "Quarterback")
                        let exampleDesignator = teamDesignator.isEmpty ? "m" : teamDesignator
                        let exampleSchool = schoolName.isEmpty ? "Mississippi State" : schoolName
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Trigger: \(exampleDesignator)25")
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(4)
                            
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
                settingsManager: settingsManager
            )
        }
        .sheet(isPresented: $showingTeamPicker) {
            TeamPickerView(
                teams: settingsManager.recentTeams,
                selectedDesignator: $teamDesignator,
                selectedSchoolName: $schoolName
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
        settingsManager.saveTeam(designator: teamDesignator, schoolName: schoolName)
        
        navigateToPreview = true
    }
}

// Team Picker Sheet
struct TeamPickerView: View {
    let teams: [TeamSettings]
    @Binding var selectedDesignator: String
    @Binding var selectedSchoolName: String
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            List(teams) { team in
                Button(action: {
                    selectedDesignator = team.designator
                    selectedSchoolName = team.schoolName
                    dismiss()
                }) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(team.schoolName)
                            .font(.headline)
                        Text("Designator: \(team.designator)")
                            .font(.caption)
                            .foregroundColor(.secondary)
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
