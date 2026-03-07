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
| Domain | `RickAndMortyDomain` (macOS framework) | `Foundation` only |
| Infrastructure | Inside `RickAndMortyDomain` | `Foundation` only |
| Presentation | iOS app target (added in a later phase) | `SwiftUI` + domain protocols |

**Why this split?**
The domain layer (`Character`, `CharactersPage`, `CharacterLoader`, `HTTPClient`) has zero platform dependencies. By targeting macOS, all domain and networking tests run natively on the Mac in under a second — no simulator boot, no device selection. The iOS app links the same framework; there is no duplication.

Infrastructure types (`RemoteCharacterLoader`, `CharacterItemsMapper`) live in the same macOS framework but depend only on protocols defined there. The only concrete detail they know about is `URLComponents` and `JSONDecoder` — both from `Foundation`.

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

## What I Would Improve or Add Next

- `URLSessionHTTPClient` — concrete `HTTPClient` backed by `URLSession`
- End-to-end test target hitting the real Rick and Morty API
- `RemoteCharacterDetailLoader` — same pattern for `GET /character/{id}`
- SwiftUI views wired to ViewModels via injected loaders
