# 2026-09-16 Codence Initial Implementation

## Completed

- created the independent Codence macOS project from the current Claudence UI foundation
- replaced browser-cookie auth with Codex app-server JSON-RPC
- added Codex executable discovery and manual selection
- added ChatGPT browser sign-in owned by Codex
- mapped dynamic quota windows, additional buckets, credits, plan, and token activity
- preserved cache, trust state, diagnostics, retry, history, pacing, display settings, and launch at login
- rewrote product, architecture, setup, release, and handoff documentation
- replaced Claude response tests with Codex integration mapping coverage
- verified all 18 Swift tests pass
- verified the unsigned Debug Xcode app build succeeds

## Acceptance boundary

All 18 automated tests and the unsigned Debug Xcode build cover the local implementation. Live browser-login completion, comparison with a real Codex account, signing, notarization, packaging, and clean-Mac acceptance remain manual gates.
