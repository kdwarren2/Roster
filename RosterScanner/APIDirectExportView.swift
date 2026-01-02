import SwiftUI

struct APIDirectExportView: View {
    let exportText: String
    let teamDesignator: String
    let schoolName: String
    
    @Environment(\.dismiss) var dismiss
    @State private var fileURL: URL?
    
    var body: some View {
        VStack(spacing: 25) {
            // Success Icon
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 70))
                .foregroundColor(.green)
                .padding(.top, 40)
            
            Text("Roster Complete!")
                .font(.title)
                .fontWeight(.bold)
            
            Text("\(playerCount) players processed")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // File Preview
            VStack(alignment: .leading, spacing: 10) {
                Text("Preview:")
                    .font(.headline)
                    .padding(.horizontal)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(previewLines, id: \.self) { line in
                            Text(line.replacingOccurrences(of: "\t", with: " → "))
                                .font(.system(.caption, design: .monospaced))
                                .padding(.horizontal)
                                .padding(.vertical, 2)
                        }
                        
                        if playerCount > 5 {
                            Text("... and \(playerCount - 5) more")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                        }
                    }
                }
                .frame(maxHeight: 250)
                .background(Color.gray.opacity(0.05))
                .cornerRadius(8)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            
            Spacer()
            
            // Share Button
            ShareLink(item: generateFileURL(), subject: Text("\(schoolName) Roster")) {
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
            
            // Copy to Clipboard
            Button(action: {
                UIPasteboard.general.string = exportText
            }) {
                HStack {
                    Image(systemName: "doc.on.clipboard")
                    Text("Copy to Clipboard")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .padding(.horizontal)
            
            Button(action: {
                // Dismiss to root
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
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") {
                    dismiss()
                }
            }
        }
    }
    
    private var previewLines: [String] {
        let lines = exportText.components(separatedBy: .newlines)
            .filter { !$0.isEmpty }
        return Array(lines.prefix(5))
    }
    
    private var playerCount: Int {
        exportText.components(separatedBy: .newlines)
            .filter { !$0.isEmpty }
            .count
    }
    
    private func generateFileURL() -> URL {
        if let url = fileURL {
            return url
        }
        
        let fileName = "\(schoolName.replacingOccurrences(of: " ", with: "_"))_roster.txt"
        let tempDirectory = FileManager.default.temporaryDirectory
        let url = tempDirectory.appendingPathComponent(fileName)
        
        do {
            try exportText.write(to: url, atomically: true, encoding: .utf8)
            fileURL = url
            print("File created at: \(url.path)")
        } catch {
            print("Error creating file: \(error)")
        }
        
        return url
    }
}

#Preview {
    NavigationStack {
        APIDirectExportView(
            exportText: """
            m0o\tBrenden Thompson
            m1d\tKelley Jones
            m2o\tBlake Shapen
            m25o\tDak Prescott
            m99d\tDiesel Moye
            """,
            teamDesignator: "m",
            schoolName: "Mississippi State"
        )
    }
}
