# RickAndMorty

A production-style SwiftUI feature that lists Rick and Morty characters, supports search and filtering, and navigates to a detail screen.

---

## How to Run

**Requirements:** Xcode 16+, macOS 15+

**Domain & networking tests (no simulator needed):**
```
xcodebuild test \
  -project RickAndMorty.xcodeproj \
  -scheme RickAndMortyDomain \
  -destination 'platform=macOS'
```

**Run the app:**
Open `RickAndMorty.xcodeproj` in Xcode, select the `RickAndMorty` scheme, choose an iOS 16+ simulator, and press **Run**.

---

## Architecture

**Pattern:** MVVM with a Clean Architecture layer separation.

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

## What I Would Improve or Add Next

- Search debounce (300 ms `Task.sleep` + cancellation on new keystroke) in `CharacterListViewModel`
- Local cache layer (`CharacterStore` protocol + `CoreData` implementation) for offline support
- Image caching (`NSCache`-backed) to avoid re-fetching on scroll
- Accessibility labels on status badges and character images
- UI snapshot tests for `CharacterListView` and `CharacterDetailView`
