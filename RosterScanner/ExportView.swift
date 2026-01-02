import SwiftUI
import UniformTypeIdentifiers

struct ExportView: View {
    let players: [Player]
    let teamDesignator: String
    let schoolName: String
    let exportFormat: ExportFormat
    
    @Environment(\.dismiss) var dismiss
    @State private var showingShareSheet = false
    @State private var fileURL: URL?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 25) {
                // Success Icon
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 70))
                    .foregroundColor(.green)
                    .padding(.top, 40)
                
                Text("Roster Ready!")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("\(players.count) players processed")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // File Preview
                VStack(alignment: .leading, spacing: 10) {
                    Text("File Preview:")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 2) {
                            ForEach(players.prefix(5)) { player in
                                let line = exportFormat.formatPlayer(player, designator: teamDesignator, schoolName: schoolName)
                                Text(line.replacingOccurrences(of: "\t", with: " → "))
                                    .font(.system(.caption, design: .monospaced))
                                    .padding(.horizontal)
                                    .padding(.vertical, 2)
                            }
                            
                            if players.count > 5 {
                                Text("... and \(players.count - 5) more")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal)
                            }
                        }
                    }
                    .frame(maxHeight: 200)
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(8)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                
                Spacer()
                
                // Export Button
                Button(action: {
                    exportFile()
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share File")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                
                Button(action: {
                    dismiss()
                }) {
                    Text("Done")
                        .font(.headline)
                        .foregroundColor(.blue)
                }
                .padding(.bottom, 20)
            }
            .padding()
            .navigationTitle("Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let url = fileURL {
                ShareSheet(items: [url])
            }
        }
    }
    
    private func exportFile() {
        // Generate file content
        var content = ""
        
        // Sort players by jersey number
        let sortedPlayers = players.sorted { 
            $0.number.localizedStandardCompare($1.number) == .orderedAscending 
        }
        
        for player in sortedPlayers {
            let line = exportFormat.formatPlayer(player, designator: teamDesignator, schoolName: schoolName)
            content += line + "\n"
        }
        
        // Create temporary file
        let fileName = "\(schoolName.replacingOccurrences(of: " ", with: "_"))_roster.txt"
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileURL = tempDirectory.appendingPathComponent(fileName)
        
        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            self.fileURL = fileURL
            showingShareSheet = true
        } catch {
            print("Error creating file: \(error.localizedDescription)")
        }
    }
}

// Share Sheet for iOS
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        
        // Explicitly include AirDrop, Messages, and Mail
        controller.excludedActivityTypes = [
            .assignToContact,
            .saveToCameraRoll,
            .addToReadingList,
            .postToFlickr,
            .postToVimeo,
            .postToTencentWeibo,
            .postToWeibo,
            .openInIBooks,
            .markupAsPDF
        ]
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No update needed
    }
}

#Preview {
    ExportView(
        players: [
            Player(number: "25", name: "Dak Prescott", position: "Quarterback"),
            Player(number: "15", name: "Will Rogers", position: "Quarterback"),
            Player(number: "1", name: "De'Runnya Wilson", position: "Wide Receiver")
        ],
        teamDesignator: "m",
        schoolName: "Mississippi State",
        exportFormat: .full
    )
}
