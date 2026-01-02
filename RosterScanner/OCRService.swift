import Vision
import UIKit
import PDFKit

class OCRService {
    
    // Extract text from UIImage - uses Anthropic API if enabled
    func extractText(from image: UIImage, useAnthropicAPI: Bool = false, apiKey: String = "") async throws -> String {
        if useAnthropicAPI && !apiKey.isEmpty {
            print("🤖 Using Anthropic API for enhanced OCR")
            return try await extractTextWithAPI(from: image, apiKey: apiKey)
        } else {
            print("📱 Using Apple Vision framework for OCR")
            return try await extractTextWithVision(from: image)
        }
    }
    
    // Extract text using Anthropic API (better accuracy)
    private func extractTextWithAPI(from image: UIImage, apiKey: String) async throws -> String {
        // Base64 encoding adds ~33% overhead, so target 3.75MB max for the JPEG
        let maxJPEGSize = 3_750_000 // 3.75MB to account for base64 encoding overhead
        var compression: CGFloat = 0.8
        var imageData = image.jpegData(compressionQuality: compression)
        
        // If image is still too large, reduce quality
        while let data = imageData, data.count > maxJPEGSize && compression > 0.1 {
            compression -= 0.1
            imageData = image.jpegData(compressionQuality: compression)
            print("📉 Compressing... \(data.count) bytes at quality \(compression)")
        }
        
        // If still too large, resize the image
        if let data = imageData, data.count > maxJPEGSize {
            print("⚠️ Image still too large (\(data.count) bytes), resizing...")
            let resizedImage = resizeImage(image, maxDimension: 1600)
            imageData = resizedImage.jpegData(compressionQuality: 0.8)
            
            // Compress resized image if needed
            compression = 0.8
            while let data = imageData, data.count > maxJPEGSize && compression > 0.1 {
                compression -= 0.1
                imageData = resizedImage.jpegData(compressionQuality: compression)
                print("📉 Compressing resized... \(data.count) bytes at quality \(compression)")
            }
        }
        
        guard let finalImageData = imageData else {
            throw OCRError.invalidImage
        }
        
        let base64Image = finalImageData.base64EncodedString()
        let estimatedBase64Size = base64Image.count
        
        print("📊 JPEG size: \(finalImageData.count) bytes, Base64 size: ~\(estimatedBase64Size) bytes (compression: \(String(format: "%.1f", compression * 100))%)")
        
        let requestBody: [String: Any] = [
            "model": "claude-sonnet-4-20250514",
            "max_tokens": 4000,
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "image",
                            "source": [
                                "type": "base64",
                                "media_type": "image/jpeg",
                                "data": base64Image
                            ]
                        ],
                        [
                            "type": "text",
                            "text": """
                            Extract ALL text from this sports roster image. Output the raw text exactly as it appears, preserving the layout and structure. Include all player numbers, names, and positions. Do not add any commentary or explanation - just output the extracted text.
                            """
                        ]
                    ]
                ]
            ]
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            throw OCRError.invalidRequest
        }
        
        var request = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OCRError.networkError
        }
        
        guard httpResponse.statusCode == 200 else {
            print("❌ API Error: Status \(httpResponse.statusCode)")
            if let errorText = String(data: data, encoding: .utf8) {
                print("Error response: \(errorText)")
            }
            throw OCRError.apiError(httpResponse.statusCode)
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let firstContent = content.first,
              let text = firstContent["text"] as? String else {
            throw OCRError.invalidResponse
        }
        
        print("✅ API OCR extracted \(text.count) characters")
        return text
    }
    
    // Helper function to resize image if needed
    private func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let ratio = max(size.width, size.height) / maxDimension
        
        if ratio <= 1 {
            return image // Already small enough
        }
        
        let newSize = CGSize(width: size.width / ratio, height: size.height / ratio)
        
        print("🔄 Resizing from \(size.width)×\(size.height) to \(newSize.width)×\(newSize.height)")
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage ?? image
    }
    
    // Extract text using Apple Vision framework (standard)
    private func extractTextWithVision(from image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else {
            throw OCRError.invalidImage
        }
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        
        try requestHandler.perform([request])
        
        guard let observations = request.results else {
            throw OCRError.noTextFound
        }
        
        let recognizedStrings = observations.compactMap { observation in
            observation.topCandidates(1).first?.string
        }
        
        let text = recognizedStrings.joined(separator: "\n")
        print("✅ Vision OCR extracted \(text.count) characters")
        return text
    }
    
    // Extract text from PDF
    func extractText(from pdfURL: URL) async throws -> String {
        print("📄 Extracting text from PDF: \(pdfURL.lastPathComponent)")
        
        guard let pdfDocument = PDFDocument(url: pdfURL) else {
            throw OCRError.invalidPDF
        }
        
        var allText = ""
        
        for pageIndex in 0..<pdfDocument.pageCount {
            guard let page = pdfDocument.page(at: pageIndex) else { continue }
            
            // First try to extract text directly (for text-based PDFs)
            if let pageText = page.string, !pageText.isEmpty {
                print("📄 Page \(pageIndex + 1): Extracted \(pageText.count) chars directly")
                allText += pageText + "\n"
            } else {
                // If no text, render as image and use OCR (for scanned PDFs)
                print("📄 Page \(pageIndex + 1): No text, using OCR on rendered image")
                let pageRect = page.bounds(for: .mediaBox)
                let renderer = UIGraphicsImageRenderer(size: pageRect.size)
                let image = renderer.image { ctx in
                    UIColor.white.set()
                    ctx.fill(pageRect)
                    ctx.cgContext.translateBy(x: 0, y: pageRect.size.height)
                    ctx.cgContext.scaleBy(x: 1.0, y: -1.0)
                    page.draw(with: .mediaBox, to: ctx.cgContext)
                }
                
                let ocrText = try await extractTextWithVision(from: image)
                allText += ocrText + "\n"
            }
        }
        
        print("✅ PDF: Total extracted \(allText.count) characters from \(pdfDocument.pageCount) pages")
        return allText
    }
}

enum OCRError: LocalizedError {
    case invalidImage
    case invalidPDF
    case noTextFound
    case invalidRequest
    case networkError
    case apiError(Int)
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Invalid image format"
        case .invalidPDF:
            return "Invalid PDF file"
        case .noTextFound:
            return "No text found in image"
        case .invalidRequest:
            return "Failed to create API request"
        case .networkError:
            return "Network error occurred"
        case .apiError(let code):
            return "API error (status \(code))"
        case .invalidResponse:
            return "Invalid API response"
        }
    }
}

