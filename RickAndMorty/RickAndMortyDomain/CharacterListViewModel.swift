import Foundation
import Observation

@Observable
public final class CharacterListViewModel {
    @ObservationIgnored private let loader: CharacterLoader

    public init(loader: CharacterLoader) {
        self.loader = loader
    }
}
