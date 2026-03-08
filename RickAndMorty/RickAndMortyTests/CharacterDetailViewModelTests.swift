import Testing
import Foundation
@testable import RickAndMortyDomain

@Suite struct CharacterDetailViewModelTests {

    // MARK: - Test 1

    @Test func init_doesNotLoadDetail() {
        let (_, loader) = makeSUT()

        #expect(loader.loadCallCount == 0)
    }
}

// MARK: - Helpers

private extension CharacterDetailViewModelTests {

    func makeSUT(characterID: Int = 1) -> (sut: CharacterDetailViewModel, loader: CharacterDetailLoaderSpy) {
        let loader = CharacterDetailLoaderSpy()
        let sut = CharacterDetailViewModel(characterID: characterID, loader: loader)
        return (sut, loader)
    }
}

// MARK: - Spy

private final class CharacterDetailLoaderSpy: CharacterDetailLoader {
    private(set) var capturedIDs: [Int] = []
    private var completions: [(Result<Character, Error>) -> Void] = []

    var loadCallCount: Int { completions.count }

    func loadDetail(id: Int, completion: @escaping (Result<Character, Error>) -> Void) {
        capturedIDs.append(id)
        completions.append(completion)
    }

    func complete(with result: Result<Character, Error>, at index: Int = 0) {
        completions[index](result)
    }
}
