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
