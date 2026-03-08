import SwiftUI

struct ContentView: View {
    @State private var searchText = ""
    @State private var statusFilter: CharacterItem.Status? = nil

    private var filtered: [CharacterItem] {
        CharacterItem.samples.filter { character in
            let matchesSearch = searchText.isEmpty
                || character.name.localizedCaseInsensitiveContains(searchText)
            let matchesStatus = statusFilter == nil
                || character.status == statusFilter
            return matchesSearch && matchesStatus
        }
    }

    var body: some View {
        NavigationStack {
            List(filtered) { character in
                NavigationLink(destination: CharacterDetailPlaceholder(character: character)) {
                    CharacterRowView(character: character)
                }
            }
            .navigationTitle("Rick & Morty")
            .searchable(text: $searchText, prompt: "Search characters")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            statusFilter = nil
                        } label: {
                            if statusFilter == nil {
                                Label("All", systemImage: "checkmark")
                            } else {
                                Text("All")
                            }
                        }
                        ForEach(CharacterItem.Status.allCases, id: \.self) { status in
                            Button {
                                statusFilter = status
                            } label: {
                                if statusFilter == status {
                                    Label(status.rawValue, systemImage: "checkmark")
                                } else {
                                    Text(status.rawValue)
                                }
                            }
                        }
                    } label: {
                        Label(
                            statusFilter?.rawValue ?? "Filter",
                            systemImage: "line.3.horizontal.decrease.circle"
                        )
                    }
                }
            }
            .refreshable {
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }
}

private struct CharacterDetailPlaceholder: View {
    let character: CharacterItem

    var body: some View {
        VStack(spacing: 20) {
            ShimmerView()
                .frame(width: 150, height: 150)
                .clipShape(Circle())

            Text(character.name)
                .font(.title)
                .bold()

            HStack(spacing: 8) {
                Circle()
                    .fill(character.status.color)
                    .frame(width: 10, height: 10)
                Text("\(character.status.rawValue) — \(character.species)")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(character.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    ContentView()
}
