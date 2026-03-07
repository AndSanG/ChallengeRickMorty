import Foundation

enum CharacterItemsMapper {
    private struct RemoteCharactersResponse: Decodable {
        let info: RemotePageInfo
        let results: [RemoteCharacterItem]
    }

    private struct RemotePageInfo: Decodable {
        let count: Int
        let pages: Int
        let next: String?
    }

    private struct RemoteCharacterItem: Decodable {
        let id: Int
        let name: String
        let status: String
        let species: String
        let gender: String
        let image: String
        let origin: RemoteLocation
        let location: RemoteLocation
        let episode: [String]

        var toDomain: Character? {
            guard let imageURL = URL(string: image) else { return nil }
            return Character(
                id: id,
                name: name,
                status: CharacterStatus(rawValue: status.lowercased()) ?? .unknown,
                species: species,
                gender: CharacterGender(rawValue: gender.lowercased()) ?? .unknown,
                imageURL: imageURL,
                originName: origin.name,
                locationName: location.name,
                episodeURLs: episode.compactMap(URL.init)
            )
        }
    }

    private struct RemoteLocation: Decodable {
        let name: String
    }

    static func map(_ data: Data, from response: HTTPURLResponse) throws -> CharactersPage {
        guard response.statusCode == 200,
              let remote = try? JSONDecoder().decode(RemoteCharactersResponse.self, from: data)
        else { throw RemoteCharacterLoader.Error.invalidData }

        return CharactersPage(
            results: remote.results.compactMap(\.toDomain),
            info: PageInfo(
                count: remote.info.count,
                pages: remote.info.pages,
                nextPage: remote.info.next.flatMap { Self.pageNumber(from: $0) }
            )
        )
    }

    private static func pageNumber(from urlString: String) -> Int? {
        guard let url = URL(string: urlString),
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let pageValue = components.queryItems?.first(where: { $0.name == "page" })?.value
        else { return nil }
        return Int(pageValue)
    }
}

