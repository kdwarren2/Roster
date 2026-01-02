import Foundation
import Combine

class SettingsManager: ObservableObject {
    @Published var recentTeams: [TeamSettings] = []
    
    private let userDefaults = UserDefaults.standard
    private let teamsKey = "savedTeams"
    
    init() {
        loadTeams()
    }
    
    func saveTeam(designator: String, schoolName: String) {
        // Update existing or create new
        if let index = recentTeams.firstIndex(where: { $0.designator == designator }) {
            recentTeams[index].lastUsed = Date()
            if recentTeams[index].schoolName != schoolName {
                recentTeams[index].schoolName = schoolName
            }
        } else {
            let newTeam = TeamSettings(designator: designator, schoolName: schoolName, lastUsed: Date())
            recentTeams.append(newTeam)
        }
        
        // Sort by most recently used
        recentTeams.sort { $0.lastUsed > $1.lastUsed }
        
        // Keep only the 20 most recent
        if recentTeams.count > 20 {
            recentTeams = Array(recentTeams.prefix(20))
        }
        
        persistTeams()
    }
    
    func getTeam(for designator: String) -> TeamSettings? {
        return recentTeams.first { $0.designator == designator }
    }
    
    func deleteTeam(_ team: TeamSettings) {
        recentTeams.removeAll { $0.id == team.id }
        persistTeams()
    }
    
    private func loadTeams() {
        guard let data = userDefaults.data(forKey: teamsKey),
              let teams = try? JSONDecoder().decode([TeamSettings].self, from: data) else {
            return
        }
        recentTeams = teams.sorted { $0.lastUsed > $1.lastUsed }
    }
    
    private func persistTeams() {
        if let data = try? JSONEncoder().encode(recentTeams) {
            userDefaults.set(data, forKey: teamsKey)
        }
    }
}
