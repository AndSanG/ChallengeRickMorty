import Foundation

final class RemoteCharacterLoader: CharacterLoader {
    private let baseURL: URL
    private let client: HTTPClient

    init(baseURL: URL, client: HTTPClient) {
        self.baseURL = baseURL
        self.client = client
    }

    func load(query: CharacterQuery, completion: @escaping (Result<CharactersPage, Error>) -> Void) {
    }
}
