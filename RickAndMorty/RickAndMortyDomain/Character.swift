import Foundation

public struct Character: Equatable {
    public let id: Int
    public let name: String
    public let status: CharacterStatus
    public let species: String
    public let gender: CharacterGender
    public let imageURL: URL
    public let originName: String
    public let locationName: String
    public let episodeURLs: [URL]

    public init(
        id: Int,
        name: String,
        status: CharacterStatus,
        species: String,
        gender: CharacterGender,
        imageURL: URL,
        originName: String,
        locationName: String,
        episodeURLs: [URL]
    ) {
        self.id = id
        self.name = name
        self.status = status
        self.species = species
        self.gender = gender
        self.imageURL = imageURL
        self.originName = originName
        self.locationName = locationName
        self.episodeURLs = episodeURLs
    }
}

public enum CharacterStatus: String {
    case alive
    case dead
    case unknown
}

public enum CharacterGender: String {
    case female
    case male
    case genderless
    case unknown
}
