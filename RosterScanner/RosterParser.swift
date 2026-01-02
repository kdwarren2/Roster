import Foundation

class RosterParser {
    
    // Main parsing function - tries smartParse first, falls back to basic if needed
    func parseRoster(from text: String) -> [Player] {
        let smart = smartParse(text)
        return smart.isEmpty ? parseBasic(text) : smart
    }
    
    // Smart parser - handles complex OCR output from Anthropic API
    func smartParse(_ text: String) -> [Player] {
        var players: [Player] = []
        let lines = text.components(separatedBy: .newlines)
        
        print("📋 SmartParse processing \(lines.count) lines...")
        
        // All valid position abbreviations
        let validPositions = Set([
            "QB", "RB", "WR", "TE", "OL", "C", "G", "T", "FB", "HB",  // Offense
            "DL", "LB", "DB", "CB", "S", "DE", "DT", "NT", "OLB", "ILB", "MLB", "FS", "SS",  // Defense
            "K", "P", "LS", "KR", "PR"  // Special teams
        ])
        
        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }
            
            // Skip header/title lines
            let skipPatterns = ["NAME", "POS.", "ROSTER", "Roster", "HOMETOWN", "HIGH SCHOOL",
                              "PREVIOUS", "HT.", "WT.", "YR.", "EXP.", "2025", "2024", "Football"]
            if skipPatterns.contains(where: { trimmed.uppercased().contains($0) }) {
                continue
            }
            
            // Pattern: NUMBER NAME POSITION [extra stuff we don't need]
            // Example: "24 Elijah Cannon CB 6'0" 180 R-Fr. RS Coconut Creek..."
            
            // Extract number at start (0-99, with or without #)
            guard let numberMatch = trimmed.range(of: #"^#?(\d{1,2})\s+"#, options: .regularExpression),
                  let numberValue = Int(trimmed[numberMatch].trimmingCharacters(in: CharacterSet(charactersIn: "# "))) else {
                continue
            }
            
            let number = String(numberValue)
            let afterNumber = String(trimmed[numberMatch.upperBound...]).trimmingCharacters(in: .whitespaces)
            
            // Split into words
            let words = afterNumber.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
            guard words.count >= 3 else { continue } // Need at least: FirstName LastName Position
            
            // Find the position - it's the first valid position abbreviation
            var positionIndex: Int? = nil
            for (i, word) in words.enumerated() {
                if validPositions.contains(word.uppercased()) {
                    positionIndex = i
                    break
                }
            }
            
            guard let posIdx = positionIndex, posIdx >= 1 else {
                print("⚠️ Line \(index + 1): No position found in: \(afterNumber)")
                continue
            }
            
            let position = words[posIdx]
            
            // Name is everything before the position
            let nameParts = Array(words[0..<posIdx])
            
            // Clean up name - remove obvious non-name words
            let cleanName = nameParts.filter { word in
                // Remove measurements, years, etc
                if word.contains("'") || word.contains("\"") { return false }
                if Int(word) != nil { return false }
                if word.count <= 2 && word.uppercased() == word { return false } // Skip abbreviations like "RS", "HS"
                return true
            }.joined(separator: " ")
            
            guard !cleanName.isEmpty else {
                print("⚠️ Line \(index + 1): No valid name found")
                continue
            }
            
            print("✅ Parsed: #\(number) \(cleanName) - \(position)")
            players.append(Player(number: number, name: cleanName, position: position))
        }
        
        print("📊 SmartParse found \(players.count) players")
        return players
    }
    
    // Basic parser - fallback for simpler formats
    func parseBasic(_ text: String) -> [Player] {
        var players: [Player] = []
        let lines = text.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }
            
            // Simple pattern: number, name, position
            let components = trimmed.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
            guard components.count >= 3 else { continue }
            
            if let number = components.first,
               Int(number.replacingOccurrences(of: "#", with: "")) != nil {
                let position = components.last ?? ""
                let name = components.dropFirst().dropLast().joined(separator: " ")
                
                if !name.isEmpty && !position.isEmpty {
                    players.append(Player(number: number, name: name, position: position))
                }
            }
        }
        
        return players
    }
}

