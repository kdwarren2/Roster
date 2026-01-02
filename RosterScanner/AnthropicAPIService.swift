import Foundation
import UIKit

class AnthropicAPIService {
    private let apiKey: String
    private let apiURL = "https://api.anthropic.com/v1/messages"
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    // Main function to parse roster from image
    func parseRoster(from image: UIImage, teamDesignator: String, schoolName: String, format: ExportFormat) async throws -> String {
        print("Starting Anthropic API roster parsing...")
        
        // Convert image to base64
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw AnthropicAPIError.imageConversionFailed
        }
        
        let base64Image = imageData.base64EncodedString()
        print("Image converted to base64, size: \(base64Image.count) chars")
        
        // Create the prompt
        let prompt = createPrompt(teamDesignator: teamDesignator, schoolName: schoolName, format: format)
        
        // Create the API request
        let requestBody = createRequestBody(base64Image: base64Image, prompt: prompt)
        
        // Make the API call
        let response = try await makeAPICall(requestBody: requestBody)
        
        // Extract the text content
        let tabDelimitedText = extractTextContent(from: response)
        
        print("Successfully parsed roster, length: \(tabDelimitedText.count)")
        return tabDelimitedText
    }
    
    // Create the prompt for Claude
    private func createPrompt(teamDesignator: String, schoolName: String, format: ExportFormat) -> String {
        let formatExample: String
        let formatInstructions: String
        
        switch format {
        case .nameOnly:
            formatExample = "\(teamDesignator)25o\tJohn Smith"
            formatInstructions = "For each player, output: {designator}{number}{position_type}[TAB]{full_name}"
        case .full:
            formatExample = "\(teamDesignator)25o\t\(schoolName) quarterback John Smith (25)"
            formatInstructions = "For each player, output: {designator}{number}{position_type}[TAB]{school} {position_lowercase} {full_name} ({number})"
        }
        
        return """
        You are analyzing a sports roster image. Extract ALL players and output ONLY tab-delimited text with NO other commentary, explanations, or formatting.
        
        CRITICAL RULES:
        1. Output ONLY the tab-delimited text - no markdown, no code blocks, no explanations
        2. Each line: one player
        3. Sort by jersey number (0-99)
        4. Position type suffix:
           - 'o' for offense (QB, RB, WR, TE, OL, C, G, T, FB, HB)
           - 'd' for defense (DL, LB, DB, CB, S, DE, DT, NT, OLB, ILB, MLB, FS, SS)
           - 'k' for special teams (K, P, LS, KR, PR)
        
        FORMAT: \(formatInstructions)
        
        EXAMPLE OUTPUT:
        \(formatExample)
        \(teamDesignator)0d\tJake Williams
        
        TEAM INFO:
        - Designator: \(teamDesignator)
        - School: \(schoolName)
        
        Extract ALL players from the image and output in this exact format. Do not include any other text.
        """
    }
    
    // Create the API request body
    private func createRequestBody(base64Image: String, prompt: String) -> [String: Any] {
        return [
            "model": "claude-sonnet-4-20250514",
            "max_tokens": 4096,
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
                            "text": prompt
                        ]
                    ]
                ]
            ]
        ]
    }
    
    // Make the API call
    private func makeAPICall(requestBody: [String: Any]) async throws -> [String: Any] {
        guard let url = URL(string: apiURL) else {
            throw AnthropicAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        print("Making API call to Anthropic...")
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AnthropicAPIError.invalidResponse
        }
        
        print("API response status: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode != 200 {
            if let errorString = String(data: data, encoding: .utf8) {
                print("API Error: \(errorString)")
            }
            throw AnthropicAPIError.apiError(statusCode: httpResponse.statusCode)
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw AnthropicAPIError.invalidResponse
        }
        
        return json
    }
    
    // Extract text content from API response
    private func extractTextContent(from response: [String: Any]) -> String {
        guard let content = response["content"] as? [[String: Any]] else {
            print("No content array in response")
            return ""
        }
        
        var fullText = ""
        
        for block in content {
            if let type = block["type"] as? String, type == "text",
               let text = block["text"] as? String {
                fullText += text
            }
        }
        
        // Clean up any markdown code blocks if present
        let cleaned = fullText
            .replacingOccurrences(of: "```", with: "")
            .replacingOccurrences(of: "```txt", with: "")
            .replacingOccurrences(of: "```text", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        return cleaned
    }
}

// Errors
enum AnthropicAPIError: LocalizedError {
    case imageConversionFailed
    case invalidURL
    case invalidResponse
    case apiError(statusCode: Int)
    case noTextContent
    
    var errorDescription: String? {
        switch self {
        case .imageConversionFailed:
            return "Failed to convert image to JPEG"
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from API"
        case .apiError(let statusCode):
            return "API error (status code: \(statusCode))"
        case .noTextContent:
            return "No text content in API response"
        }
    }
}
