public protocol CharacterDetailLoader {
    func loadDetail(id: Int, completion: @escaping (Result<Character, Error>) -> Void)
}
