public struct CharactersPage {
    public let results: [Character]
    public let info: PageInfo

    public init(results: [Character], info: PageInfo) {
        self.results = results
        self.info = info
    }
}

public struct PageInfo {
    public let count: Int
    public let pages: Int
    public let nextPage: Int?

    public init(count: Int, pages: Int, nextPage: Int?) {
        self.count = count
        self.pages = pages
        self.nextPage = nextPage
    }
}
