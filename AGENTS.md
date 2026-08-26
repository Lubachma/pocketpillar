# AGENTS.md

- The mobile app is Flutter (`mobile/`) since the 2026 rewrite — use `flutter analyze` / `flutter test` for verification. The legacy iOS SwiftUI app is archived in the private repo history.
- Before claiming any change is done, run the full local batteries: `make check`, `npm test`, and `(cd mobile && flutter analyze && flutter test)`.
