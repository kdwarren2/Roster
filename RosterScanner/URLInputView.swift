import SwiftUI

// URL Input View for importing rosters from web
struct URLInputView: View {
    @Binding var inputURL: String
    @Binding var isProcessing: Bool
    @Binding var errorMessage: String?
    var onImport: () -> Void
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Import Roster from URL")
                    .font(.headline)
                    .padding(.top)
                
                Text("Enter the URL of a team roster webpage")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                TextField("https://example.com/roster", text: $inputURL)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .keyboardType(.URL)
                    .padding(.horizontal)
                
                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }
                
                Button(action: {
                    onImport()
                }) {
                    if isProcessing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Import Roster")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(inputURL.isEmpty ? Color.gray : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
                .disabled(inputURL.isEmpty || isProcessing)
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
