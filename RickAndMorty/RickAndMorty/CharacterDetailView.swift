import SwiftUI
import RickAndMortyDomain

struct CharacterDetailView: View {
    let viewModel: CharacterDetailViewModel

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.character == nil {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let message = viewModel.errorMessage, viewModel.character == nil {
                errorView(message: message)
            } else if let character = viewModel.character {
                characterDetail(character)
            }
        }
        .onAppear { viewModel.load() }
        .navigationBarTitleDisplayMode(.inline)
    }

    private func characterDetail(_ character: Character) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                AsyncImage(url: character.imageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .failure, .empty:
                        Color(.systemGray5)
                    @unknown default:
                        Color(.systemGray5)
                    }
                }
                .frame(width: 200, height: 200)
                .clipShape(Circle())
                .shadow(radius: 8)

                Text(character.name)
                    .font(.title.bold())
                    .multilineTextAlignment(.center)

                HStack(spacing: 8) {
                    Circle()
                        .fill(character.status.color)
                        .frame(width: 10, height: 10)
                    Text("\(character.status.displayName) — \(character.species)")
                        .foregroundStyle(.secondary)
                }

                Divider()

                infoGrid(character)
            }
            .padding()
        }
        .navigationTitle(character.name)
    }

    private func infoGrid(_ character: Character) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            infoRow(label: "Gender", value: character.gender.displayName)
            infoRow(label: "Origin", value: character.originName)
            infoRow(label: "Location", value: character.locationName)
            infoRow(label: "Episodes", value: "\(character.episodeURLs.count)")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func infoRow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.body)
        }
    }

    private func errorView(message: String) -> some View {
        ContentUnavailableView {
            Label("Failed to Load", systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        } actions: {
            Button("Retry") { viewModel.load() }
                .buttonStyle(.borderedProminent)
        }
    }
}

private extension CharacterGender {
    var displayName: String {
        switch self {
        case .male:       return "Male"
        case .female:     return "Female"
        case .genderless: return "Genderless"
        case .unknown:    return "Unknown"
        }
    }
}
