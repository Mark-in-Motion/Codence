# Architecture

Codence is a SwiftUI macOS menu-bar app with typed state, protocol-bound services, and file-backed persistence.

## Runtime flow

1. `AppBootstrap` loads settings, cache, diagnostics, activity, and history.
2. `CodexExecutableLocator` resolves a validated Codex executable.
3. `CodexAppServerClient` launches `codex app-server --stdio` with the executable directory prepended to the child PATH, initializes JSON-RPC, correlates requests, and consumes login notifications.
4. `CodexUsageFetchService` verifies ChatGPT authentication, reads rate limits, maps dynamic quota windows, and independently refreshes token activity.
5. `SyncCoordinator` promotes a valid live snapshot or clearly labeled recovered cache.
6. Successful live snapshots feed local history and pacing.
7. `AppBootstrap` publishes a separate typed refresh-feedback state for the menu-bar button and status row. It compares meaningful quota data on successful checks without changing the trust state owned by `SyncCoordinator`.

## Boundaries

- `CodexAppServerServing` isolates the external process and RPC contract.
- `UsageFetchService` isolates quota mapping from orchestration.
- repositories persist settings, diagnostics, snapshots, activity, and history under Application Support.
- credentials remain entirely within Codex; Codence never reads its auth store.

## Compatibility

Required RPC methods are `account/read`, `account/login/start`, `account/rateLimits/read`, and `account/usage/read`. Missing methods are treated as an incompatible Codex installation and surfaced as recovery guidance.
