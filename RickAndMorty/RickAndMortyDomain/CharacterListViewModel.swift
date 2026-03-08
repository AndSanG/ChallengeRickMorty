import Foundation
import Observation

@Observable
public final class CharacterListViewModel {
    public private(set) var characters: [Character] = []
    public private(set) var isLoading = false
    public private(set) var errorMessage: String? = nil
    @ObservationIgnored private let loader: CharacterLoader

    public init(loader: CharacterLoader) {
        self.loader = loader
    }

    public func load() {
        isLoading = true
        errorMessage = nil
        loader.load(query: CharacterQuery(page: 1, name: nil, status: nil)) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let page):
                characters = page.results
                isLoading = false
            case .failure:
                isLoading = false
                errorMessage = "Failed to load characters."
            }
        }
    }
}
