import Foundation
import Observation

@Observable
public final class CharacterListViewModel {
    @ObservationIgnored private let loader: CharacterLoader

    public init(loader: CharacterLoader) {
        self.loader = loader
    }

    public func load() {
        loader.load(query: CharacterQuery(page: 1, name: nil, status: nil)) { _ in }
    }
}
