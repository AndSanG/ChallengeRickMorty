import SwiftUI

struct CharacterItem: Identifiable {
    let id: Int
    let name: String
    let status: Status
    let species: String

    enum Status: String, CaseIterable {
        case alive = "Alive"
        case dead = "Dead"
        case unknown = "Unknown"

        var color: Color {
            switch self {
            case .alive:   return .green
            case .dead:    return .red
            case .unknown: return .gray
            }
        }
    }
}

extension CharacterItem {
    static let samples: [CharacterItem] = [
        CharacterItem(id: 1,  name: "Rick Sanchez",       status: .alive,   species: "Human"),
        CharacterItem(id: 2,  name: "Morty Smith",        status: .alive,   species: "Human"),
        CharacterItem(id: 3,  name: "Summer Smith",       status: .alive,   species: "Human"),
        CharacterItem(id: 4,  name: "Beth Smith",         status: .alive,   species: "Human"),
        CharacterItem(id: 5,  name: "Jerry Smith",        status: .alive,   species: "Human"),
        CharacterItem(id: 6,  name: "Abadango Cluster",   status: .unknown, species: "Humanoid"),
        CharacterItem(id: 7,  name: "Adjudicator Rick",   status: .dead,    species: "Human"),
        CharacterItem(id: 8,  name: "Agency Director",    status: .dead,    species: "Human"),
        CharacterItem(id: 9,  name: "Alan Rails",         status: .dead,    species: "Human"),
        CharacterItem(id: 10, name: "Albert Einstein",    status: .dead,    species: "Human"),
        CharacterItem(id: 11, name: "Alexander",          status: .dead,    species: "Human"),
        CharacterItem(id: 12, name: "Alien Googah",       status: .dead,    species: "Alien"),
        CharacterItem(id: 13, name: "Alien Morty",        status: .unknown, species: "Alien"),
        CharacterItem(id: 14, name: "Alien Rick",         status: .unknown, species: "Alien"),
        CharacterItem(id: 15, name: "Amish Cyborg",       status: .dead,    species: "Alien"),
    ]
}
