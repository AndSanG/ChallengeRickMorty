import Foundation
import Observation

@Observable
public final class CharacterListViewModel {
    public private(set) var characters: [Character] = []
    public private(set) var isLoading = false
    public private(set) var errorMessage: String? = nil
    public private(set) var hasNextPage = false
    public var searchText: String = ""
    public var statusFilter: CharacterStatus? = nil
    @ObservationIgnored private var currentPage = 1
    @ObservationIgnored private let loader: CharacterLoader

    public init(loader: CharacterLoader) {
        self.loader = loader
    }

    public func load() {
        currentPage = 1
        isLoading = true
        errorMessage = nil
        loader.load(query: makeQuery(page: 1)) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let page):
                characters = page.results
                hasNextPage = page.info.nextPage != nil
                isLoading = false
            case .failure:
                isLoading = false
                errorMessage = "Failed to load characters."
            }
        }
    }

    private func makeQuery(page: Int) -> CharacterQuery {
        CharacterQuery(
            page: page,
            name: searchText.isEmpty ? nil : searchText,
            status: statusFilter
        )
    }

    public func loadNextPage() {
        guard hasNextPage, !isLoading else { return }
        let nextPage = currentPage + 1
        isLoading = true
        loader.load(query: makeQuery(page: nextPage)) { [weak self] result in
            guard let self else { return }
            isLoading = false
            switch result {
            case .success(let page):
                currentPage = nextPage
                characters += page.results
                hasNextPage = page.info.nextPage != nil
            case .failure:
                errorMessage = "Failed to load more characters."
            }
        }
    }
}
