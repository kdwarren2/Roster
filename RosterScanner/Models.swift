import Foundation

// Individual player entry
struct Player: Identifiable, Codable {
    let id = UUID()
    var number: String
    var name: String
    var position: String
    
    enum CodingKeys: String, CodingKey {
        case number, name, position
    }
    
    // Determine if position is Offensive, Defensive, or Special Teams
    var positionCategory: String {
        let pos = position.uppercased()
        
        // Offensive positions
        let offensivePositions = ["QB", "RB", "WR", "TE", "OL", "C", "G", "T", "FB", "HB"]
        // Defensive positions
        let defensivePositions = ["DL", "LB", "DB", "CB", "S", "DE", "DT", "NT", "OLB", "ILB", "MLB", "FS", "SS"]
        // Special teams positions
        let specialTeamsPositions = ["K", "P", "LS", "KR", "PR"]
        
        // Handle dual positions (e.g., LB/S)
        let positions = pos.components(separatedBy: "/")
        if let firstPos = positions.first {
            if offensivePositions.contains(firstPos) {
                return "O"
            } else if defensivePositions.contains(firstPos) {
                return "D"
            } else if specialTeamsPositions.contains(firstPos) {
                return "K"
            }
        }
        
        if offensivePositions.contains(pos) {
            return "O"
        } else if defensivePositions.contains(pos) {
            return "D"
        } else if specialTeamsPositions.contains(pos) {
            return "K"
        } else {
            // Default to offense if unknown
            return "O"
        }
    }
}

// Team settings that can be saved and reused
struct TeamSettings: Codable, Identifiable {
    let id = UUID()
    var designator: String
    var schoolName: String
    var lastUsed: Date
    
    enum CodingKeys: String, CodingKey {
        case designator, schoolName, lastUsed
    }
}

// Export format options
enum ExportFormat: String, CaseIterable {
    case nameOnly = "Name Only"
    case full = "School + Position + Name + Number"
    
    func formatPlayer(_ player: Player, designator: String, schoolName: String) -> String {
        // Add O/D/K suffix to handle duplicate numbers
        let prefix = player.positionCategory
        let trigger = "\(designator)\(player.number)\(prefix.lowercased())"
        
        switch self {
        case .nameOnly:
            return "\(trigger)\t\(player.name)"
        case .full:
            let position = player.position.uppercased()
            return "\(trigger)\t\(schoolName) \(position) \(player.name) (\(player.number))"
        }
    }
}
