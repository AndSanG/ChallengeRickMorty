import Testing
import Foundation
@testable import RickAndMortyDomain

@Suite struct CharacterDetailViewModelTests {

    // MARK: - Test 1

    @Test func init_doesNotLoadDetail() {
        let (_, loader) = makeSUT()

        #expect(loader.loadCallCount == 0)
    }

    // MARK: - Test 2

    @Test func load_requestsDetailFromLoader() {
        let characterID = 42
        let (sut, loader) = makeSUT(characterID: characterID)

        sut.load()

        #expect(loader.capturedIDs == [characterID])
    }

    // MARK: - Test 3

    @Test func load_setsIsLoadingDuringRequest() {
        let (sut, _) = makeSUT()

        sut.load()

        #expect(sut.isLoading == true)
    }

    // MARK: - Test 4

    @Test func load_clearsIsLoadingOnSuccess() {
        let (sut, loader) = makeSUT()

        sut.load()
        loader.complete(with: .success(anyCharacter()))

        #expect(sut.isLoading == false)
    }

    // MARK: - Test 5

    @Test func load_clearsIsLoadingOnFailure() {
        let (sut, loader) = makeSUT()

        sut.load()
        loader.complete(with: .failure(anyError()))

        #expect(sut.isLoading == false)
    }

    // MARK: - Test 6

    @Test func load_deliversCharacterOnSuccess() {
        let (sut, loader) = makeSUT()
        let character = anyCharacter()

        sut.load()
        loader.complete(with: .success(character))

        #expect(sut.character?.id == character.id)
        #expect(sut.character?.name == character.name)
    }
}

// MARK: - Helpers

private extension CharacterDetailViewModelTests {

    func anyCharacter() -> Character {
        Character(
            id: 1,
            name: "Rick Sanchez",
            status: .alive,
            species: "Human",
            gender: .male,
            imageURL: URL(string: "https://example.com/1.png")!,
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
