# RickAndMorty

A production-style SwiftUI feature that lists Rick and Morty characters, supports search and filtering, and navigates to a detail screen.

---

## Targets

| Target | Purpose |
|---|---|
| `RickAndMorty` | Production iOS app. SwiftUI views + composition root. |
| `RickAndMortyPrototype` | Throwaway design sandbox — hardcoded data, no networking. Used to validate UI/UX before wiring production code. |
| `RickAndMortyDomain` | Cross-platform framework. Domain models, protocols, use cases, ViewModels. Builds for both macOS and iOS. |
| `RickAndMortyTests` | Fast unit tests for the domain framework. Run on macOS — no simulator required. |
| `RickAndMortyAPIEndToEndTests` | Integration tests that hit the real Rick and Morty API. Run manually, never in CI. |

---

## How to Run

**Requirements:** Xcode 16+, iOS 17+ simulator (for app targets)

### Production app (`RickAndMorty`)

Open `RickAndMorty.xcodeproj` in Xcode, select the **`RickAndMorty`** scheme, choose an iOS 17+ simulator, and press **Run (⌘R)**.

```
xcodebuild build \
  -project RickAndMorty.xcodeproj \
  -scheme RickAndMorty \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

### Prototype app (`RickAndMortyPrototype`)

Select the **`RickAndMortyPrototype`** scheme in Xcode, choose a simulator, and press **Run**. No network connection needed — all data is hardcoded. This is useful for testing the UI/UX without network connection, feedback, or clarity on the requirements.

```
xcodebuild build \
  -project RickAndMorty.xcodeproj \
  -scheme RickAndMortyPrototype \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

### Unit tests — no simulator needed (`RickAndMortyTests`)

```
xcodebuild test \
  -project RickAndMorty.xcodeproj \
  -scheme RickAndMortyDomain \
  -destination 'platform=macOS'
```

### End-to-end tests — hits real API (`RickAndMortyAPIEndToEndTests`)

Requires a network connection. Run manually, not in the fast test suite.

```
xcodebuild test \
  -project RickAndMorty.xcodeproj \
  -scheme RickAndMortyAPIEndToEndTests \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

---

## Architecture

**Pattern:** MVVM with a Clean Architecture layer separation, VIPER-inspired.

**Why VIPER-inspired?**
VIPER (View · Interactor · Presenter · Entity · Router) enforces a strict one-responsibility-per-layer rule. This project adopts the same discipline without the full VIPER ceremony:

| VIPER role | This project's equivalent |
|---|---|
| **View** | `CharacterListView`, `CharacterDetailView`, `CharacterRowView` — render state, emit user actions |
| **Interactor** | `RemoteCharacterLoader`, `RemoteCharacterDetailLoader` — pure business logic, protocol-driven, no UI knowledge |
| **Presenter** | `CharacterListViewModel`, `CharacterDetailViewModel` — translate raw domain data into display state |
| **Entity** | `Character`, `CharactersPage`, `CharacterQuery` — plain Swift structs, zero framework dependencies |
| **Router** | `NavigationStack` + the `makeDetailViewModel` factory closure in `RickAndMortyApp` — navigation decisions live in the composition root, not in views |

Each role is enforced by **compiler-level target boundaries**, not just naming conventions. The domain framework has no `import SwiftUI`; the app target has no direct reference to `URLSession` or any remote loader. A layer can only call inward — never outward.

This promotes high modularity, testability, and a strict separation of concerns, making the architecture scale cleanly to large, complex apps: adding a new feature means adding a new Interactor + ViewModel pair without touching unrelated code, and every component is independently unit-testable via protocol substitution.

The codebase is split into three explicit boundaries:

| Layer | Target | Allowed imports |
|---|---|---|
| Domain | `RickAndMortyDomain` (cross-platform framework) | `Foundation` only |
| Infrastructure | Inside `RickAndMortyDomain` | `Foundation` only |
| Presentation (ViewModels) | Inside `RickAndMortyDomain` | `Foundation` + `Observation` |
| Presentation (Views) | `RickAndMorty` iOS app target | `SwiftUI` + `RickAndMortyDomain` |
| Composition Root | `RickAndMortyApp.init()` | Everything — this is the only place that imports concrete types |

**Why this split?**
The domain layer (`Character`, `CharactersPage`, `CharacterLoader`, `HTTPClient`) has zero platform dependencies. It builds for both macOS (so test suites run natively without a simulator) and iOS (so the app links the same binary). No duplication.

Infrastructure types (`RemoteCharacterLoader`, `RemoteCharacterDetailLoader`, `CharacterItemsMapper`) live in the same framework but depend only on protocols defined there. The only concrete detail they know about is `URLComponents` and `JSONDecoder` — both from `Foundation`.

The Composition Root (`RickAndMortyApp.init()`) is the single place that creates concrete objects and wires the dependency graph:

```swift
let client = URLSessionHTTPClient(session: .init(configuration: .default))
let listLoader   = RemoteCharacterLoader(baseURL: apiURL, client: client)
let detailLoader = RemoteCharacterDetailLoader(baseURL: apiURL, client: client)
let listVM = CharacterListViewModel(loader: listLoader)
// CharacterDetailViewModel is created per-navigation at the call site
```

`CharacterListView` and `CharacterDetailView` depend only on their ViewModels — they have no knowledge of `URLSession`, `RemoteCharacterLoader`, or any infrastructure type.

---

### SOLID Principles

The architecture heavily relies on SOLID principles to ensure code maintainability, testability, and scalability. Here is how each principle is applied:

- **Single Responsibility Principle (SRP):** Each class and struct does precisely one thing. 
  - `RemoteCharacterLoader` handles fetching and decoding character lists.
  - `CharacterItemsMapper` handles taking raw network data and parsing it to domain models.
  - `CharacterListViewModel` manages state purely for presentation.
- **Open-Closed Principle (OCP):** Components are open for extension but closed for modification. If we were to add a `LocalCharacterLoader` (CoreData cache layer), the existing view models and tests would not require changes because they depend on the abstract `CharacterLoader` protocol.
- **Liskov Substitution Principle (LSP):** Our app seamlessly swaps implementations of protocols. During unit testing, `URLProtocolStub` substitutes real network calls smoothly, and `CharacterLoaderSpy` accurately replaces `RemoteCharacterLoader` without forcing the ViewModel to know the difference.
- **Interface Segregation Principle (ISP):** We prevent "fat" protocols.
  - Rather than one massive `RickAndMortyService` protocol that has every endpoint, we broke it apart into `CharacterLoader` (for arrays) and `CharacterDetailLoader` (for singles).
  - The network layer only requires an `HTTPClient` protocol with a single `get` method. No component is forced to depend on methods it doesn't use.
- **Dependency Inversion Principle (DIP):** High-level modules (`CharacterListViewModel`) do not depend on low-level modules (`RemoteCharacterLoader` or `URLSessionHTTPClient`). Instead, both depend on abstractions (`CharacterLoader` protocol). The instantiation of concrete types is pulled all the way back up to the Composition Root (`RickAndMortyApp`).

---

## Dependency Injection

Every collaborator is injected via the constructor. No type creates its own dependencies.

```swift
// RemoteCharacterLoader receives HTTPClient as a protocol — never URLSession directly
let loader = RemoteCharacterLoader(baseURL: apiURL, client: httpClient)
```

This means:
- Tests inject an `HTTPClientSpy` that captures requests without hitting the network.
- The production app injects `URLSessionHTTPClient` in the Composition Root (the single place that knows the full object graph).
- No type outside the Composition Root knows what its collaborators are made of.

---

## What Was Tested and Why

**`URLSessionHTTPClient` (4 tests — `RickAndMortyTests` target, runs on macOS)**

| Test | Why |
|---|---|
| `get_requestsCorrectURL` | The URL passed to `get` reaches the session unchanged |
| `get_requestsWithGETMethod` | Method is GET, not POST or other |
| `get_deliversErrorOnRequestError` | Transport failure propagates as `.failure` |
| `get_deliversDataAndResponseOn200Response` | Data + `HTTPURLResponse` forwarded on success |

Tests use `URLProtocolStub` — a `URLProtocol` subclass registered into an ephemeral `URLSession` configuration. This intercepts requests at the Foundation level without subclassing `URLSession` or touching the network.

**`RickAndMortyAPIEndToEndTests` (4 tests — separate target, hits real API)**

| Test | Why |
|---|---|
| `load_page1_deliversNonEmptyResults` | API is reachable and returns data |
| `load_page1_deliversExpectedFirstCharacter` | JSON mapping is correct end-to-end |
| `load_withNameFilter_deliversOnlyMatchingResults` | Name query param is sent and respected |
| `load_withStatusFilter_deliversOnlyAliveCharacters` | Status query param is sent and respected |

These are kept in a separate target and run manually — never in the fast unit test suite.

**`RemoteCharacterLoader` (9 tests — `RickAndMortyTests` target, runs on macOS)**

| Test | Why |
|---|---|
| `init_doesNotRequestData` | Proves no accidental side-effects on creation |
| `load_requestsDataFromURL` | Correct `/character` endpoint with query params |
| `loadTwice_requestsDataFromURLTwice` | Loader is stateless across calls |
| `load_deliversConnectivityErrorOnClientError` | Client failure maps to `.connectivity` |
| `"delivers .invalidData on non-200 response" ×5` | Every non-200 status code (parameterised) |
| `load_deliversInvalidDataErrorOn200WithInvalidJSON` | Malformed JSON maps to `.invalidData` |
| `load_deliversNoItemsOn200WithEmptyJSONList` | Empty API response maps to empty page |
| `load_deliversItemsOn200WithJSONItems` | Valid JSON maps to correct domain models |
| `load_doesNotDeliverResultAfterSUTDeallocated` | `[weak self]` prevents delivery after dealloc |

Tests use a `Spy` pattern — captured closures are completed manually in the test body, giving full control over timing without any async primitives.

---

**`CharacterListViewModel` (10 tests — `RickAndMortyTests` target, runs on macOS)**

| Test | Why |
|---|---|
| `init_doesNotLoadCharacters` | No accidental side-effects on creation |
| `load_requestsCharactersFromLoader` | Calling `load()` triggers exactly one loader call |
| `load_setsIsLoadingDuringRequest` | `isLoading` is `true` while request is in flight |
| `load_clearsIsLoadingOnSuccessfulLoad` | `isLoading` is `false` after success |
| `load_clearsIsLoadingOnFailedLoad` | `isLoading` is `false` after failure |
| `load_deliversCharactersOnSuccess` | `characters` reflects the page results |
| `load_setsErrorMessageOnFailure` | `errorMessage` is non-nil on failure |
| `load_clearsErrorBeforeReloading` | Stale error is cleared when `load()` is called again |
| `loadNextPage_appendsCharactersOnSuccess` | Second page is appended to the existing list |
| `loadNextPage_doesNothingWhenOnLastPage` | No loader call when `hasNextPage` is false |

**`CharacterDetailViewModel` (7 tests — `RickAndMortyTests` target, runs on macOS)**

| Test | Why |
|---|---|
| `init_doesNotLoadDetail` | No accidental side-effects on creation |
| `load_requestsDetailFromLoader` | `load()` calls loader with the correct character ID |
| `load_setsIsLoadingDuringRequest` | `isLoading` is `true` while request is in flight |
| `load_clearsIsLoadingOnSuccess` | `isLoading` is `false` after success |
| `load_clearsIsLoadingOnFailure` | `isLoading` is `false` after failure |
| `load_deliversCharacterOnSuccess` | `character` is set from the loader result |
| `load_setsErrorMessageOnFailure` | `errorMessage` is non-nil on failure |

Both ViewModels use `@Observable` (from `import Observation`, not SwiftUI) and depend only on domain protocols, keeping them simulator-free and framework-agnostic.

---

## Assignment Checklist

### Deliverables
- [x] Xcode iOS project
- [x] Full source code
- [x] Unit tests (30+ across 4 test suites)
- [x] README.md — setup, decisions, trade-offs
- [x] Git repository (see commit history for progressive TDD delivery)

### Functional — Character List
- [x] Fetch and display characters from `GET /character`
- [x] Each row: image (`AsyncImage`), name, status with colour indicator, species — see `CharacterRowView`
- [x] Loading state — `ProgressView` while `isLoading && characters.isEmpty`
- [x] Error state with retry — `ContentUnavailableView` + Retry button calling `viewModel.load()`
- [x] Empty state (no results) — `ContentUnavailableView` when list is empty after load
- [x] Pagination — infinite scroll: a `ProgressView` at the bottom of the list triggers `loadNextPage()` via `.onAppear`

### Functional — Search & Filter
- [x] Search by name — `searchable` modifier bound to `viewModel.searchText`; API handles case-insensitivity server-side
- [x] Filter by status (All / Alive / Dead / Unknown) — toolbar `Menu` bound to `viewModel.statusFilter`
- [x] Search or filter change resets to page 1 — `load()` always sets `currentPage = 1`
- [x] Search debounce (250–400 ms)

### Functional — Character Detail
- [x] Tap navigates to detail screen
- [x] Fetches `GET /character/{id}` (preferred boundary design) — via `RemoteCharacterDetailLoader`
- [x] Image & name
- [x] Status, species, and gender
- [x] Origin name and location name
- [x] Episode count

### Non-Functional — Architecture & Code Quality
- [x] SwiftUI
- [x] MVVM + Clean Architecture — see *Architecture* section
- [x] SOLID applied — single-responsibility loaders, protocol-driven dependencies, interface segregation via `CharacterLoader` / `CharacterDetailLoader` / `HTTPClient`
- [x] Constructor injection throughout — see *Dependency Injection* section
- [x] No global singletons — `URLSession.shared` is not used; a configured `URLSession` is injected at the composition root
- [x] Clear boundaries between UI, Domain, and Data — enforced by target membership (`RickAndMortyDomain` has no SwiftUI import; `RickAndMorty` app target never imports infrastructure types directly)

### Non-Functional — Testing
- [x] ≥ 2 unit tests — 30+ provided
- [x] ViewModel behaviour: state transitions and pagination resets covered — `CharacterListViewModelTests` (10 tests), `CharacterDetailViewModelTests` (7 tests)
- [x] Service/API layer: success decoding, connectivity error, non-200 responses, invalid JSON — `RemoteCharacterLoaderTests` (9 tests), `URLSessionHTTPClientTests` (4 tests)
- [x] Tests are deterministic and never hit the real network — Spy pattern for ViewModels; `URLProtocolStub` for HTTP client; real-network tests isolated to `RickAndMortyAPIEndToEndTests` (run manually)

### Constraints
- [x] iOS 17+ deployment target
- [x] No third-party libraries
- [x] Scope kept tight — core requirements first

### README Structure
- [x] How to run the project
- [x] Architecture and reasoning
- [x] Dependency Injection explanation
- [x] What was tested and why
- [x] Observability and security choices — covered inline: ephemeral `URLSession` for E2E tests avoids caching; no credentials or tokens in source; `URLProtocolStub` prevents accidental network calls in unit tests
- [x] What I would improve or add next

---

## What I Would Improve or Add Next

- Organize Domain code in folders.
- Local cache layer (`CharacterStore` protocol + `CoreData` implementation) for offline support
- Accessibility labels on status badges and character images
- UI snapshot tests for `CharacterListView` and `CharacterDetailView`
- Comprehensive SwiftUI Previews for all Views, showcasing loaded, empty, loading, and error states
