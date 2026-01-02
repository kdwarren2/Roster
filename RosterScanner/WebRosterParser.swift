import Foundation

class WebRosterParser {
    
    // Parse HTML table from roster website
    func parseHTMLRoster(html: String) -> [Player] {
        var players: [Player] = []
        
        // Look for table rows in the HTML
        // Pattern: | number | name | position | ...
        let lines = html.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            // Skip empty lines and headers
            guard !trimmed.isEmpty,
                  !trimmed.contains("| # |"),
                  !trimmed.contains("| --- |"),
                  trimmed.hasPrefix("|") else {
                continue
            }
            
            // Split by pipe character
            let columns = trimmed.components(separatedBy: "|")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
            
            // Need at least: number, name, position
            guard columns.count >= 3 else { continue }
            
            let number = columns[0].trimmingCharacters(in: .whitespaces)
            let name = columns[1].trimmingCharacters(in: .whitespaces)
            let position = columns[2].trimmingCharacters(in: .whitespaces)
            
            // Validate number is a digit
            guard let _ = Int(number) else { continue }
            
            // Validate name contains letters
            guard name.rangeOfCharacter(from: .letters) != nil else { continue }
            
            // Validate position is reasonable (2-4 characters, mostly uppercase)
            guard position.count >= 1 && position.count <= 5 else { continue }
            
            players.append(Player(number: number, name: name, position: position))
        }
        
        return players
    }
    
    // Fetch and parse roster from URL
    func fetchRoster(from urlString: String) async throws -> [Player] {
        guard let url = URL(string: urlString) else {
            throw WebRosterError.invalidURL
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        
        guard let html = String(data: data, encoding: .utf8) else {
            throw WebRosterError.invalidData
        }
        
        return parseHTMLRoster(html: html)
    }
}

enum WebRosterError: LocalizedError {
    case invalidURL
    case invalidData
    case noPlayersFound
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL format"
        case .invalidData:
            return "Could not read website data"
        case .noPlayersFound:
            return "No players found on this page"
        }
    }
}
