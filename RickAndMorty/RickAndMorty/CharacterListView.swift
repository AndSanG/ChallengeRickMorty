import SwiftUI
import RickAndMortyDomain

struct CharacterListView: View {
    let viewModel: CharacterListViewModel
    let makeDetailViewModel: (Int) -> CharacterDetailViewModel

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Rick & Morty")
                .navigationDestination(for: Int.self) { id in
                    CharacterDetailView(viewModel: makeDetailViewModel(id))
                }
                .searchable(text: Bindable(viewModel).searchText, prompt: "Search characters")
                .onChange(of: viewModel.searchText) { _, _ in viewModel.debounceSearch() }
                .toolbar { filterToolbar }
                .refreshable { viewModel.load() }
                .onAppear {
                    if viewModel.characters.isEmpty { viewModel.load() }
                }
        }
    }

    @ViewBuilder private var content: some View {
        if viewModel.isLoading && viewModel.characters.isEmpty {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let message = viewModel.errorMessage, viewModel.characters.isEmpty {
            errorView(message: message)
        } else if viewModel.characters.isEmpty {
            emptyView
        } else {
            characterList
        }
    }

    private var characterList: some View {
        List {
            ForEach(viewModel.characters, id: \.id) { character in
                NavigationLink(value: character.id) {
                    CharacterRowView(character: character)
                }
            }
            if let message = viewModel.nextPageErrorMessage {
                VStack(spacing: 8) {
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Button("Retry") { viewModel.loadNextPage() }
                        .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            } else if viewModel.hasNextPage {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .onAppear { viewModel.loadNextPage() }
            }
        }
    }

    private var emptyView: some View {
        ContentUnavailableView(
            "No Characters Found",
            systemImage: "person.slash",
            description: Text("Try adjusting your search or filter.")
        )
    }

    private func errorView(message: String) -> some View {
        ContentUnavailableView {
            Label("Something Went Wrong", systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        } actions: {
            Button("Retry") { viewModel.load() }
                .buttonStyle(.borderedProminent)
        }
    }

    @ToolbarContentBuilder private var filterToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Button {
                    Bindable(viewModel).statusFilter.wrappedValue = nil
                    viewModel.load()
                } label: {
                    if viewModel.statusFilter == nil {
                        Label("All", systemImage: "checkmark")
                    } else {
                        Text("All")
                    }
                }
                ForEach([CharacterStatus.alive, .dead, .unknown], id: \.self) { status in
                    Button {
                        Bindable(viewModel).statusFilter.wrappedValue = status
                        viewModel.load()
                    } label: {
                        if viewModel.statusFilter == status {
                            Label(status.displayName, systemImage: "checkmark")
                        } else {
                            Text(status.displayName)
                        }
                    }
                }
            } label: {
                Label(
                    viewModel.statusFilter?.displayName ?? "Filter",
                    systemImage: "line.3.horizontal.decrease.circle"
                )
            }
        }
    }
}

