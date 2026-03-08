import Foundation
import Observation

@Observable
public final class CharacterDetailViewModel {
    public private(set) var character: Character? = nil
    public private(set) var isLoading = false
    public private(set) var errorMessage: String? = nil
    @ObservationIgnored private let characterID: Int
    @ObservationIgnored private let loader: CharacterDetailLoader

    public init(characterID: Int, loader: CharacterDetailLoader) {
        self.characterID = characterID
        self.loader = loader
    }

    public func load() {
        isLoading = true
        loader.loadDetail(id: characterID) { [weak self] result in
            guard let self else { return }
            isLoading = false
            switch result {
            case .success(let loaded):
                character = loaded
            case .failure:
                errorMessage = "Failed to load character."
            }
        }
    }
}
