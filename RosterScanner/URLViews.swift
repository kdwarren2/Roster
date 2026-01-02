import SwiftUI

// URL Input Dialog
struct URLInputView: View {
    @Binding var urlString: String
    let onImport: (String) -> Void
    @Environment(\.dismiss) var dismiss
    
    @State private var inputURL = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Enter Roster Website URL")
                    .font(.headline)
                    .padding(.top)
                
                Text("Example: hailstate.com/sports/football/roster/print")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                TextField("https://...", text: $inputURL)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .keyboardType(.URL)
                    .padding(.horizontal)
                
                Button(action: {
                    var url = inputURL
                    // Add https:// if missing
                    if !url.hasPrefix("http://") && !url.hasPrefix("https://") {
                        url = "https://" + url
                    }
                    onImport(url)
                    dismiss()
                }) {
                    Text("Import Roster")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(inputURL.isEmpty ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .disabled(inputURL.isEmpty)
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Import from URL")
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

// Configuration View for URL-imported rosters
struct URLRosterConfigView: View {
    let players: [Player]
    @ObservedObject var settingsManager: SettingsManager
    
    @State private var teamDesignator = ""
    @State private var schoolName = ""
    @State private var selectedFormat: ExportFormat = .full
    @State private var navigateToPreview = false
    @State private var showingTeamPicker = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 25) {
                // Success Message
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title2)
                    Text("Found \(players.count) players!")
                        .font(.headline)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.green.opacity(0.1))
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
                        
                        Text("This will be combined with jersey numbers (e.g., 'mO25')")
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
                        
                        if let examplePlayer = players.first {
                            let exampleDesignator = teamDesignator.isEmpty ? "m" : teamDesignator
                            let exampleSchool = schoolName.isEmpty ? "Mississippi State" : schoolName
                            let prefix = examplePlayer.positionCategory
                            
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("Trigger: \(exampleDesignator)\(prefix)\(examplePlayer.number)")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(4)
                                    
                                    Text("(O=Offense, D=Defense, K=Kicker)")
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
                    settingsManager.saveTeam(designator: teamDesignator, schoolName: schoolName)
                    navigateToPreview = true
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
                players: players,
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
}
