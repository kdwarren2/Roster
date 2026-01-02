import SwiftUI

struct RosterPreviewView: View {
    @State var players: [Player]
    let teamDesignator: String
    let schoolName: String
    let exportFormat: ExportFormat
    
    @ObservedObject var settingsManager: SettingsManager
    
    @State private var showingExport = false
    @State private var editingPlayer: Player?
    @State private var searchText = ""
    
    var filteredPlayers: [Player] {
        if searchText.isEmpty {
            return players.sorted { $0.number.localizedStandardCompare($1.number) == .orderedAscending }
        } else {
            return players.filter { player in
                player.name.localizedCaseInsensitiveContains(searchText) ||
                player.number.contains(searchText) ||
                player.position.localizedCaseInsensitiveContains(searchText)
            }.sorted { $0.number.localizedStandardCompare($1.number) == .orderedAscending }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("Search players...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(10)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            .padding()
            
            // Player Count
            HStack {
                Text("\(filteredPlayers.count) players")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Button(action: {
                    addNewPlayer()
                }) {
                    Label("Add Player", systemImage: "plus.circle.fill")
                        .font(.subheadline)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
            
            // Player List
            List {
                ForEach(filteredPlayers) { player in
                    PlayerRowView(
                        player: player,
                        teamDesignator: teamDesignator,
                        schoolName: schoolName,
                        exportFormat: exportFormat
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        editingPlayer = player
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            deletePlayer(player)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        
                        Button {
                            editingPlayer = player
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(.blue)
                    }
                }
            }
            .listStyle(PlainListStyle())
            
            // Export Button
            Button(action: {
                showingExport = true
            }) {
                Text("Export Roster")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding()
        }
        .navigationTitle("Review Roster")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editingPlayer) { player in
            EditPlayerView(
                player: binding(for: player),
                onSave: { updatedPlayer in
                    updatePlayer(updatedPlayer)
                    editingPlayer = nil
                },
                onCancel: {
                    editingPlayer = nil
                }
            )
        }
        .sheet(isPresented: $showingExport) {
            ExportView(
                players: players,
                teamDesignator: teamDesignator,
                schoolName: schoolName,
                exportFormat: exportFormat
            )
        }
    }
    
    private func binding(for player: Player) -> Binding<Player> {
        guard let index = players.firstIndex(where: { $0.id == player.id }) else {
            fatalError("Player not found")
        }
        return $players[index]
    }
    
    private func updatePlayer(_ updatedPlayer: Player) {
        if let index = players.firstIndex(where: { $0.id == updatedPlayer.id }) {
            players[index] = updatedPlayer
        }
    }
    
    private func deletePlayer(_ player: Player) {
        players.removeAll { $0.id == player.id }
    }
    
    private func addNewPlayer() {
        let newPlayer = Player(number: "", name: "", position: "")
        players.append(newPlayer)
        editingPlayer = newPlayer
    }
}

// Player Row View
struct PlayerRowView: View {
    let player: Player
    let teamDesignator: String
    let schoolName: String
    let exportFormat: ExportFormat
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Jersey Number Badge
                Text("#\(player.number)")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.blue)
                    .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(player.name)
                        .font(.headline)
                    Text(player.position)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Preview of expansion
            VStack(alignment: .leading, spacing: 4) {
                Text("Trigger: \(teamDesignator)\(player.number)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                let expandedText = exportFormat.formatPlayer(player, designator: teamDesignator, schoolName: schoolName)
                    .components(separatedBy: "\t").last ?? ""
                
                Text(expandedText)
                    .font(.caption)
                    .foregroundColor(.blue)
                    .lineLimit(2)
            }
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.blue.opacity(0.05))
            .cornerRadius(6)
        }
        .padding(.vertical, 4)
    }
}

// Edit Player View
struct EditPlayerView: View {
    @Binding var player: Player
    let onSave: (Player) -> Void
    let onCancel: () -> Void
    
    @State private var number: String
    @State private var name: String
    @State private var position: String
    
    init(player: Binding<Player>, onSave: @escaping (Player) -> Void, onCancel: @escaping () -> Void) {
        self._player = player
        self.onSave = onSave
        self.onCancel = onCancel
        self._number = State(initialValue: player.wrappedValue.number)
        self._name = State(initialValue: player.wrappedValue.name)
        self._position = State(initialValue: player.wrappedValue.position)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Player Information") {
                    TextField("Jersey Number", text: $number)
                        .keyboardType(.numberPad)
                    
                    TextField("Player Name", text: $name)
                        .autocapitalization(.words)
                    
                    TextField("Position", text: $position)
                        .autocapitalization(.words)
                }
            }
            .navigationTitle("Edit Player")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        var updatedPlayer = player
                        updatedPlayer.number = number
                        updatedPlayer.name = name
                        updatedPlayer.position = position
                        onSave(updatedPlayer)
                    }
                    .disabled(number.isEmpty || name.isEmpty || position.isEmpty)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        RosterPreviewView(
            players: [
                Player(number: "25", name: "Dak Prescott", position: "Quarterback"),
                Player(number: "15", name: "Will Rogers", position: "Quarterback"),
                Player(number: "1", name: "De'Runnya Wilson", position: "Wide Receiver")
            ],
            teamDesignator: "m",
            schoolName: "Mississippi State",
            exportFormat: .full,
            settingsManager: SettingsManager()
        )
    }
}
