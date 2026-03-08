import Foundation

public final class RemoteCharacterDetailLoader: CharacterDetailLoader {
    public enum Error: Swift.Error, Equatable {
        case connectivity
        case invalidData
    }

    private let baseURL: URL
    private let client: HTTPClient

    public init(baseURL: URL, client: HTTPClient) {
        self.baseURL = baseURL
        self.client = client
    }

    public func loadDetail(id: Int, completion: @escaping (Result<Character, Swift.Error>) -> Void) {
        let url = baseURL.appendingPathComponent("character/\(id)")
        client.get(from: url) { [weak self] result in
            guard self != nil else { return }
            switch result {
            case let .success((data, response)):
                completion(Result { try CharacterItemsMapper.mapSingle(data, from: response) })
            case .failure:
                completion(.failure(Error.connectivity))
            }
        }
    }
}
