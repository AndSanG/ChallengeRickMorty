import Foundation
import Observation

@Observable
public final class CharacterDetailViewModel {
    public private(set) var isLoading = false
    @ObservationIgnored private let characterID: Int
    @ObservationIgnored private let loader: CharacterDetailLoader

    public init(characterID: Int, loader: CharacterDetailLoader) {
        self.characterID = characterID
        self.loader = loader
    }

    public func load() {
        isLoading = true
        loader.loadDetail(id: characterID) { _ in }
    }
}
