# Roadmap

## Next

- verify launch after logout/login or restart, signed-out browser login, and menu-bar appearance in light and dark modes
- finish live quota comparison, refresh-feedback visual checks, and failure/recovery checks
- add explicit request timeouts and reconnect coverage for stalled app-server calls
- add a fake-process integration test for JSON-RPC framing and subprocess exit
- implement notifications only after threshold behavior is approved

## Deferred binary release — requires Apple Developer Program membership

- obtain Developer ID Application signing, notarize a DMG, and verify Gatekeeper
- test the exact downloadable binary on a clean Mac before distribution

## Later

- richer daily activity charts
- compatibility telemetry that never includes credentials or prompts
- optional API-organization mode as a separately designed product surface
