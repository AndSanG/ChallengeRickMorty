# BDD Requirements — RickAndMorty

## Use Cases

### UC1 — Load Character List
- **Given** the user opens the app
- **When** the character list screen appears
- **Then** characters are fetched from `GET /character?page=1` and displayed in a list

### UC2 — Paginate Characters (Infinite Scroll)
- **Given** the character list is loaded
- **When** the user scrolls near the last visible item
- **Then** the next page is fetched and appended to the existing list

### UC3 — Search Characters by Name
- **Given** the character list is displayed
- **When** the user types in the search field
- **Then** after a 300ms debounce, `GET /character?name={query}&page=1` is called and the list resets

### UC4 — Filter Characters by Status
- **Given** the character list is displayed
- **When** the user selects a status filter (All / Alive / Dead / Unknown)
- **Then** `GET /character?status={status}&page=1` is called and the list resets to page 1

### UC5 — Combined Search + Filter
- **Given** both a search term and a status filter are active
- **When** either changes
- **Then** both parameters are sent together and the list resets to page 1

### UC6 — Handle Empty Results
- **Given** the user applies a search or filter
- **When** the API returns an empty results array
- **Then** an empty state is shown with a descriptive message

### UC7 — Handle Load Error
- **Given** the character list is loading
- **When** the network request fails (connectivity error or non-200 response)
- **Then** an error state is shown with a retry button

### UC8 — View Character Detail
- **Given** the user taps a character row
- **When** the detail screen opens
- **Then** `GET /character/{id}` is fetched and displays: image, name, status, species, gender, origin name, location name, and episode count

### UC9 — Handle Detail Load Error
- **Given** the detail screen is loading
- **When** the request fails
- **Then** an error state is shown with a retry option

---

## Domain Models

```
Character
  id: Int
  name: String
  status: CharacterStatus         // alive | dead | unknown
  species: String
  gender: CharacterGender         // female | male | genderless | unknown
  imageURL: URL
  originName: String
  locationName: String
  episodeURLs: [URL]

CharactersPage
  results: [Character]
  info: PageInfo

PageInfo
  count: Int
  pages: Int
  nextPage: Int?                  // nil = last page

CharacterQuery
  page: Int
  name: String?
  status: CharacterStatus?
```

---

## Infrastructure DTOs (private, never exposed beyond infrastructure)

```
RemoteCharactersResponse  (Codable)
  info: RemotePageInfo
  results: [RemoteCharacterItem]

RemotePageInfo  (Codable)
  count: Int
  pages: Int
  next: String?

RemoteCharacterItem  (Codable)
  id: Int
  name: String
  status: String
  species: String
  gender: String
  image: String
  origin: RemoteLocation
  location: RemoteLocation
  episode: [String]

RemoteLocation  (Codable)
  name: String
```

---

## Protocol Contracts

```
HTTPClient
  get(from: URL, completion: (Result<(Data, HTTPURLResponse), Error>) -> Void)

CharacterLoader
  load(query: CharacterQuery, completion: (Result<CharactersPage, Error>) -> Void)

CharacterDetailLoader
  loadDetail(id: Int, completion: (Result<Character, Error>) -> Void)
```

---

## Module Map & Dependency Directions

```
┌──────────────────────────────────────────────────────────────┐
│  RickAndMortyApp  (Composition Root — @main)                 │
│  Wires all dependencies; imports everything                  │
├────────────────────────┬─────────────────────────────────────┤
│  RickAndMortyi OS      │  Infrastructure (inside App target) │
│  ViewModels + Views    │  URLSessionHTTPClient               │
│  depends on protocols  │  RemoteCharacterLoader              │
│  only ↓                │  RemoteCharacterDetailLoader        │
│                        │  CharacterItemsMapper               │
│                        │  depends on protocols ↓             │
├────────────────────────┴─────────────────────────────────────┤
│  RickAndMorty  (Domain framework — no imports)               │
│  Character, CharactersPage, CharacterQuery, PageInfo         │
│  CharacterStatus, CharacterGender                            │
│  CharacterLoader, CharacterDetailLoader, HTTPClient          │
└──────────────────────────────────────────────────────────────┘

All arrows point inward → domain has zero outward dependencies.
No UI type imports any infrastructure type.
No domain type imports URLSession, SwiftUI, or Codable.
```

---

## Exit Criteria

- [x] All use cases defined in BDD style (Given / When / Then)
- [x] Domain models identified, separated from API DTOs
- [x] Module boundaries and dependency directions decided
- [x] Protocol contracts defined for HTTPClient, CharacterLoader, CharacterDetailLoader
- [x] Dependency diagram produced
- [x] No framework name (URLSession, SwiftUI, CoreData) appears in domain definitions
