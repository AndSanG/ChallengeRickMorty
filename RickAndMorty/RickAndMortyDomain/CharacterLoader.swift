public protocol CharacterLoader {
    func load(query: CharacterQuery, completion: @escaping (Result<CharactersPage, Error>) -> Void)
}
