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
}

// MARK: - Helpers

private extension CharacterListViewModelTests {

    func anyPage(results: [Character] = [], nextPage: Int? = nil) -> CharactersPage {
        CharactersPage(results: results, info: PageInfo(count: results.count, pages: 1, nextPage: nextPage))
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
