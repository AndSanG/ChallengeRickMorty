import Foundation
import Observation

@Observable
public final class CharacterDetailViewModel {
    @ObservationIgnored private let characterID: Int
    @ObservationIgnored private let loader: CharacterDetailLoader

    public init(characterID: Int, loader: CharacterDetailLoader) {
        self.characterID = characterID
        self.loader = loader
    }
}
