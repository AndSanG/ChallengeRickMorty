import SwiftUI
import RickAndMortyDomain

@main
struct RickAndMortyApp: App {
    private let listViewModel: CharacterListViewModel
    private let makeDetailViewModel: (Int) -> CharacterDetailViewModel

    init() {
        let baseURL = URL(string: "https://rickandmortyapi.com/api")!
        let client = URLSessionHTTPClient(session: URLSession(configuration: .default))
        let listLoader = RemoteCharacterLoader(baseURL: baseURL, client: client)
        let detailLoader = RemoteCharacterDetailLoader(baseURL: baseURL, client: client)
        listViewModel = CharacterListViewModel(loader: listLoader)
        makeDetailViewModel = { id in
            CharacterDetailViewModel(characterID: id, loader: detailLoader)
        }
    }

    var body: some Scene {
        WindowGroup {
            CharacterListView(
                viewModel: listViewModel,
                makeDetailViewModel: makeDetailViewModel
            )
        }
    }
}
