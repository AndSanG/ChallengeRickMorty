import Testing
import Foundation
@testable import RickAndMortyDomain

@Suite struct CharacterListViewModelTests {

    // MARK: - Test 1

    @Test func init_doesNotLoadCharacters() {
        let (_, loader) = makeSUT()

        #expect(loader.loadCallCount == 0)
    }

    // MARK: - Test 2

    @Test func load_requestsCharactersFromLoader() {
        let (sut, loader) = makeSUT()

        sut.load()

        #expect(loader.loadCallCount == 1)
    }

    // MARK: - Test 3

    @Test func load_setsIsLoadingDuringRequest() {
        let (sut, _) = makeSUT()

        sut.load()

        #expect(sut.isLoading == true)
    }

    // MARK: - Test 4

    @Test func load_clearsIsLoadingOnSuccessfulLoad() {
        let (sut, loader) = makeSUT()

        sut.load()
        loader.complete(with: .success(anyPage()))

        #expect(sut.isLoading == false)
    }

    // MARK: - Test 5

    @Test func load_clearsIsLoadingOnFailedLoad() {
        let (sut, loader) = makeSUT()

        sut.load()
        loader.complete(with: .failure(anyError()))

        #expect(sut.isLoading == false)
    }

    // MARK: - Test 6

    @Test func load_deliversCharactersOnSuccess() {
        let (sut, loader) = makeSUT()
        let characters = [makeCharacter(id: 1), makeCharacter(id: 2)]

        sut.load()
        loader.complete(with: .success(anyPage(results: characters)))

        #expect(sut.characters == characters)
    }

    // MARK: - Test 7

    @Test func load_setsErrorMessageOnFailure() {
        let (sut, loader) = makeSUT()

        sut.load()
        loader.complete(with: .failure(anyError()))

        #expect(sut.errorMessage != nil)
    }

    // MARK: - Test 8

    @Test func load_clearsErrorBeforeReloading() {
        let (sut, loader) = makeSUT()

        sut.load()
        loader.complete(with: .failure(anyError()))

        sut.load()

        #expect(sut.errorMessage == nil)
    }
}

// MARK: - Helpers

private extension CharacterListViewModelTests {

    func anyPage(results: [Character] = [], nextPage: Int? = nil) -> CharactersPage {
        CharactersPage(results: results, info: PageInfo(count: results.count, pages: 1, nextPage: nextPage))
    }

    func makeCharacter(id: Int) -> Character {
        Character(
            id: id,
            name: "Any Name",
            status: .alive,
            species: "Human",
            gender: .male,
            imageURL: URL(string: "https://example.com/\(id).png")!,
            originName: "Earth",
            locationName: "Earth",
            episodeURLs: []
        )
    }

    func anyError() -> NSError {
        NSError(domain: "test", code: 0)
    }
}

// MARK: - Helpers

private extension CharacterListViewModelTests {

    func makeSUT() -> (sut: CharacterListViewModel, loader: CharacterLoaderSpy) {
        let loader = CharacterLoaderSpy()
        let sut = CharacterListViewModel(loader: loader)
        return (sut, loader)
    }
}

// MARK: - Spy

private final class CharacterLoaderSpy: CharacterLoader {
    private(set) var capturedQueries: [CharacterQuery] = []
    private var completions: [(Result<CharactersPage, Error>) -> Void] = []

    var loadCallCount: Int { completions.count }

    func load(query: CharacterQuery, completion: @escaping (Result<CharactersPage, Error>) -> Void) {
        capturedQueries.append(query)
        completions.append(completion)
    }

    func complete(with result: Result<CharactersPage, Error>, at index: Int = 0) {
        completions[index](result)
    }
}
