import Testing
import Foundation
@testable import RickAndMortyDomain

@Suite struct RemoteCharacterLoaderTests {

    // MARK: - Test 1

    @Test func init_doesNotRequestData() {
        let (_, client) = makeSUT()

        #expect(client.requestedURLs.isEmpty)
    }

    // MARK: - Test 2

    @Test func load_requestsDataFromURL() {
        let url = URL(string: "https://rickandmortyapi.com/api")!
        let (sut, client) = makeSUT(url: url)

        sut.load(query: CharacterQuery(page: 1)) { _ in }

        #expect(client.requestedURLs.count == 1)
        #expect(client.requestedURLs.first?.absoluteString.contains("character") == true)
    }

    // MARK: - Helpers

    private func makeSUT(
        url: URL = URL(string: "https://any-url.com")!
    ) -> (sut: RemoteCharacterLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteCharacterLoader(baseURL: url, client: client)
        return (sut, client)
    }
}

// MARK: - HTTPClientSpy

final class HTTPClientSpy: HTTPClient {
    private(set) var requestedURLs: [URL] = []
    private var completions: [(Result<(Data, HTTPURLResponse), Error>) -> Void] = []

    func get(from url: URL, completion: @escaping (Result<(Data, HTTPURLResponse), Error>) -> Void) {
        requestedURLs.append(url)
        completions.append(completion)
    }

    func complete(with error: Error, at index: Int = 0) {
        completions[index](.failure(error))
    }

    func complete(withStatusCode code: Int, data: Data = Data(), at index: Int = 0) {
        let response = HTTPURLResponse(
            url: requestedURLs[index],
            statusCode: code,
            httpVersion: nil,
            headerFields: nil
        )!
        completions[index](.success((data, response)))
    }
}
