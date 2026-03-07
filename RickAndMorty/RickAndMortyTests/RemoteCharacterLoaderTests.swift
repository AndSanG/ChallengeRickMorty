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

    // MARK: - Test 3

    @Test func loadTwice_requestsDataFromURLTwice() {
        let (sut, client) = makeSUT()

        sut.load(query: CharacterQuery(page: 1)) { _ in }
        sut.load(query: CharacterQuery(page: 1)) { _ in }

        #expect(client.requestedURLs.count == 2)
    }

    // MARK: - Test 4

    @Test func load_deliversConnectivityErrorOnClientError() {
        let (sut, client) = makeSUT()
        var receivedError: RemoteCharacterLoader.Error?

        sut.load(query: CharacterQuery(page: 1)) { result in
            if case let .failure(error) = result {
                receivedError = error as? RemoteCharacterLoader.Error
            }
        }
        client.complete(with: anyNSError())

        #expect(receivedError == .connectivity)
    }

    // MARK: - Test 5

    @Test("delivers .invalidData on non-200 response", arguments: [199, 201, 300, 400, 500])
    func load_deliversInvalidDataErrorOnNon200Response(statusCode: Int) {
        let (sut, client) = makeSUT()
        var receivedError: RemoteCharacterLoader.Error?

        sut.load(query: CharacterQuery(page: 1)) { result in
            if case let .failure(error) = result {
                receivedError = error as? RemoteCharacterLoader.Error
            }
        }
        client.complete(withStatusCode: statusCode, data: anyData())

        #expect(receivedError == .invalidData)
    }

    // MARK: - Test 6

    @Test func load_deliversInvalidDataErrorOn200ResponseWithInvalidJSON() {
        let (sut, client) = makeSUT()
        var receivedError: RemoteCharacterLoader.Error?

        sut.load(query: CharacterQuery(page: 1)) { result in
            if case let .failure(error) = result {
                receivedError = error as? RemoteCharacterLoader.Error
            }
        }
        client.complete(withStatusCode: 200, data: Data("invalid json".utf8))

        #expect(receivedError == .invalidData)
    }

    // MARK: - Test 7

    @Test func load_deliversNoItemsOn200ResponseWithEmptyJSONList() {
        let (sut, client) = makeSUT()
        var receivedPage: CharactersPage?

        sut.load(query: CharacterQuery(page: 1)) { result in
            if case let .success(page) = result { receivedPage = page }
        }
        client.complete(withStatusCode: 200, data: emptyListJSON())

        #expect(receivedPage?.results.isEmpty == true)
    }

    // MARK: - Test 8

    @Test func load_deliversItemsOn200ResponseWithJSONItems() {
        let (sut, client) = makeSUT()
        let item1 = makeCharacter(id: 1, name: "Rick Sanchez", status: "Alive", species: "Human", gender: "Male", imageURL: URL(string: "https://image1.com")!, originName: "Earth", locationName: "Earth", episodeURLs: [])
        let item2 = makeCharacter(id: 2, name: "Morty Smith", status: "Alive", species: "Human", gender: "Male", imageURL: URL(string: "https://image2.com")!, originName: "Earth", locationName: "Earth", episodeURLs: [])
        var receivedPage: CharactersPage?

        sut.load(query: CharacterQuery(page: 1)) { result in
            if case let .success(page) = result { receivedPage = page }
        }
        client.complete(withStatusCode: 200, data: makeItemsJSON([item1.json, item2.json]))

        #expect(receivedPage?.results.count == 2)
        #expect(receivedPage?.results[0].id == item1.model.id)
        #expect(receivedPage?.results[1].id == item2.model.id)
    }

    // MARK: - Test 9

    @Test func load_doesNotDeliverResultAfterSUTHasBeenDeallocated() {
        let client = HTTPClientSpy()
        var sut: RemoteCharacterLoader? = RemoteCharacterLoader(baseURL: URL(string: "https://any-url.com")!, client: client)
        weak var weakSUT = sut
        var receivedResults: [Result<CharactersPage, Error>] = []

        sut?.load(query: CharacterQuery(page: 1)) { receivedResults.append($0) }
        sut = nil
        client.complete(withStatusCode: 200, data: emptyListJSON())

        #expect(receivedResults.isEmpty)
        #expect(weakSUT == nil, "Potential memory leak in RemoteCharacterLoader")
    }

    // MARK: - Helpers

    private func makeSUT(
        url: URL = URL(string: "https://any-url.com")!
    ) -> (sut: RemoteCharacterLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteCharacterLoader(baseURL: url, client: client)
        return (sut, client)
    }

    private func anyNSError() -> NSError {
        NSError(domain: "any", code: 0)
    }

    private func anyData() -> Data {
        Data("any data".utf8)
    }

    private func emptyListJSON() -> Data {
        let json: [String: Any] = [
            "info": ["count": 0, "pages": 0, "next": NSNull(), "prev": NSNull()],
            "results": []
        ]
        return try! JSONSerialization.data(withJSONObject: json)
    }

    private func makeCharacter(
        id: Int, name: String, status: String, species: String, gender: String,
        imageURL: URL, originName: String, locationName: String, episodeURLs: [URL]
    ) -> (model: Character, json: [String: Any]) {
        let model = Character(
            id: id, name: name,
            status: CharacterStatus(rawValue: status.lowercased()) ?? .unknown,
            species: species,
            gender: CharacterGender(rawValue: gender.lowercased()) ?? .unknown,
            imageURL: imageURL,
            originName: originName,
            locationName: locationName,
            episodeURLs: episodeURLs
        )
        let json: [String: Any] = [
            "id": id,
            "name": name,
            "status": status,
            "species": species,
            "gender": gender,
            "image": imageURL.absoluteString,
            "origin": ["name": originName],
            "location": ["name": locationName],
            "episode": episodeURLs.map { $0.absoluteString }
        ]
        return (model, json)
    }

    private func makeItemsJSON(_ items: [[String: Any]]) -> Data {
        let json: [String: Any] = [
            "info": ["count": items.count, "pages": 1, "next": NSNull(), "prev": NSNull()],
            "results": items
        ]
        return try! JSONSerialization.data(withJSONObject: json)
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
