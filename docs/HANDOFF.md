# Handoff

## Resume here

Codence has been created from the Claudence UI foundation and converted to a Codex app-server integration.

## Current reality

- the target is an independent Codence project
- browser-cookie and Keychain credential handling are removed
- the app discovers Codex CLI or accepts a chosen executable
- ChatGPT browser sign-in is initiated through the app server
- the browser login uses the app server's local success page, and Settings hides sign-in when already connected
- login completion lookup and waiter registration now happen under one lock, closing a callback timing race
- canonical and additional quota buckets are mapped dynamically
- quota cards, progress bars, menu-bar labels, and history show remaining percentages like the Codex usage site; stored snapshots and pacing keep used percentages
- the popover now aligns both quota cards and shows relative time until reset; hover reveals the exact reset date and time
- pace wording uses plain-language risk and an even-pace comparison instead of a projected usage percentage above 100%
- token activity is optional and cached independently from required rate-limit data
- the popover preserves the Claudence layout while Settings carries Codex-native account data
- cached fallback, refresh scheduling, retry, pacing, history, and diagnostics remain
- the nvm Codex launcher requires its sibling Node directory on PATH when started by the GUI app; this is now injected into the child process environment
- menu-bar artwork is now transparent monochrome code-drawn template art; the opaque square PNG was removed
- `./scripts/install-local.sh` builds Release and installs to `~/Applications` without overwriting an existing app; source setup and recovery are documented in the README
- GitHub CI is configured for Swift tests and unsigned Debug/Release builds
- the Refresh button now shows a spinner while checking, and a fixed-height status row reports updated, unchanged, or failed results without resizing the popover
- 28 Swift tests pass, including refresh outcome and in-flight-state coverage; unsigned Debug and Release Xcode builds pass
- the local installer created a runnable arm64 `Codence.app` in a temporary install directory, and a second run correctly refused to overwrite it
- the public source repository is https://github.com/Mark-in-Motion/Codence; a fresh public clone, Release installation with `install-local.sh`, Finder launch, live account connection and refresh, and Launch at Login registration were reported successful on 2026-09-17
- Settings → About now links to the README's manual uninstall instructions, which separate app removal from optional local-data removal
- the README now shows Codence-specific popover and Settings screenshots from `docs/images/`, with a concise feature list; the screenshot documentation gate is complete
- v0.1.0 is published on GitHub as a source-only pre-release with no app or DMG asset; public repository metadata is set
- the verified Apple account is free and has an Apple Development identity, not a Developer ID Application certificate; normal signed/notarized distribution is deferred until Apple Developer Program membership

## Open manual gates

- validate the local browser success page in a signed-out account
- compare remaining percentages and reset times in the rebuilt app with the current Codex usage site
- visually confirm the revised popover and new menu-bar icon in light and dark appearances on the running Mac
- visually confirm that manual Refresh animates, settles on the correct result, and keeps the popover height fixed
- verify missing/outdated Codex recovery UI
- verify Launch at Login actually starts Codence after a logout/login or restart; registration alone is not enough
- after Apple Developer Program enrollment, Developer ID-sign and notarize a DMG, then test the exact downloaded binary on a clean Mac before offering it
