import SwiftUI
import RickAndMortyDomain

struct CharacterRowView: View {
    let character: Character

    var body: some View {
        HStack(spacing: 12) {
            CachedAsyncImage(url: character.imageURL) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                case .failure, .empty:
                    Color(.systemGray5)
                }
            }
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
                    Text(character.status.displayName)
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

extension CharacterStatus {
    var color: Color {
        switch self {
        case .alive:   return .green
        case .dead:    return .red
        case .unknown: return .gray
        @unknown default: return .gray
        }
    }

    var displayName: String {
        switch self {
        case .alive:   return "Alive"
        case .dead:    return "Dead"
        case .unknown: return "Unknown"
        @unknown default: return "Unknown"
        }
    }
}
