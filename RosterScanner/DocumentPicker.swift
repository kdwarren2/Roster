import SwiftUI
import UniformTypeIdentifiers

struct DocumentPicker: UIViewControllerRepresentable {
    @Binding var pdfURL: URL?
    var onDismiss: () -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        // CRITICAL: Use asCopy:false to get security-scoped access
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.pdf], asCopy: false)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        picker.shouldShowFileExtensions = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else {
                print("❌ No URL selected")
                parent.onDismiss()
                return
            }
            
            print("📄 Selected file: \(url.lastPathComponent)")
            print("📍 Path: \(url.path)")
            
            // CRITICAL: Start accessing the security-scoped resource
            guard url.startAccessingSecurityScopedResource() else {
                print("❌ Failed to access security-scoped resource")
                parent.onDismiss()
                return
            }
            
            // Defer stopping access until we're completely done
            defer {
                url.stopAccessingSecurityScopedResource()
                print("✅ Stopped accessing security-scoped resource")
            }
            
            do {
                // Verify file exists
                guard FileManager.default.fileExists(atPath: url.path) else {
                    print("❌ File doesn't exist at path: \(url.path)")
                    parent.onDismiss()
                    return
                }
                
                print("✅ File exists, size: \((try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int) ?? 0) bytes")
                
                // Get app's temporary directory (we have full access here)
                let tempDir = FileManager.default.temporaryDirectory
                let destinationURL = tempDir.appendingPathComponent(url.lastPathComponent)
                
                // Remove any existing temp file with same name
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    try FileManager.default.removeItem(at: destinationURL)
                    print("🗑️ Removed existing temp file")
                }
                
                // Copy to our temp directory where we have full access
                try FileManager.default.copyItem(at: url, to: destinationURL)
                print("✅ Successfully copied PDF to temp directory: \(destinationURL.path)")
                
                // Update the binding with the temp URL (not the original security-scoped URL)
                DispatchQueue.main.async {
                    self.parent.pdfURL = destinationURL
                    self.parent.onDismiss()
                }
                
            } catch {
                print("❌ Error copying PDF: \(error.localizedDescription)")
                parent.onDismiss()
            }
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            print("📄 Document picker cancelled")
            parent.onDismiss()
        }
    }
}

