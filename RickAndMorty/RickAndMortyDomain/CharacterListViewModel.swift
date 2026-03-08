import Foundation
import Observation

@Observable
public final class CharacterListViewModel {
    public private(set) var isLoading = false
    @ObservationIgnored private let loader: CharacterLoader

    public init(loader: CharacterLoader) {
        self.loader = loader
    }

    public func load() {
        isLoading = true
        loader.load(query: CharacterQuery(page: 1, name: nil, status: nil)) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success:
                isLoading = false
            case .failure:
                isLoading = false
            }
        }
    }
}
