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
