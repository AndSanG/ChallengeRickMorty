public struct CharacterQuery {
    public let page: Int
    public let name: String?
    public let status: CharacterStatus?

    public init(page: Int, name: String? = nil, status: CharacterStatus? = nil) {
        self.page = page
        self.name = name
        self.status = status
    }
}
