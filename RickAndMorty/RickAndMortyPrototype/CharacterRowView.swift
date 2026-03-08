import SwiftUI

struct CharacterRowView: View {
    let character: CharacterItem

    var body: some View {
        HStack(spacing: 12) {
            ShimmerView()
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(character.name)
                    .font(.headline)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Circle()
                        .fill(character.status.color)
                        .frame(width: 8, height: 8)
                    Text(character.status.rawValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("·")
                        .foregroundStyle(.secondary)
                    Text(character.species)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    List {
        CharacterRowView(character: CharacterItem(id: 1, name: "Rick Sanchez", status: .alive, species: "Human"))
        CharacterRowView(character: CharacterItem(id: 2, name: "Adjudicator Rick", status: .dead, species: "Human"))
        CharacterRowView(character: CharacterItem(id: 3, name: "Alien Morty", status: .unknown, species: "Alien"))
    }
}
