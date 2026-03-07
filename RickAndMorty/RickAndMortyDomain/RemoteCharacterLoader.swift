import Foundation

final class RemoteCharacterLoader: CharacterLoader {
    private let baseURL: URL
    private let client: HTTPClient

    init(baseURL: URL, client: HTTPClient) {
        self.baseURL = baseURL
        self.client = client
    }

    func load(query: CharacterQuery, completion: @escaping (Result<CharactersPage, Error>) -> Void) {
        let url = url(for: query)
        client.get(from: url) { _ in }
    }

    private func url(for query: CharacterQuery) -> URL {
        var components = URLComponents(url: baseURL.appendingPathComponent("character"), resolvingAgainstBaseURL: false)!
        var queryItems: [URLQueryItem] = [URLQueryItem(name: "page", value: "\(query.page)")]
        if let name = query.name { queryItems.append(URLQueryItem(name: "name", value: name)) }
        if let status = query.status { queryItems.append(URLQueryItem(name: "status", value: status.rawValue)) }
        components.queryItems = queryItems
        return components.url!
    }
}
