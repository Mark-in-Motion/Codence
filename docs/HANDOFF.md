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
- 26 Swift tests pass after the popover readability change
- the unsigned Debug Xcode app build succeeds after the popover readability change
- the nvm Codex launcher requires its sibling Node directory on PATH when started by the GUI app; this is now injected into the child process environment
- menu-bar artwork is now transparent monochrome code-drawn template art; the opaque square PNG was removed
- `./scripts/install-local.sh` builds Release and installs to `~/Applications` without overwriting an existing app; source setup and recovery are documented in the README
- GitHub CI is configured for Swift tests and unsigned Debug/Release builds
- 27 Swift tests pass, including menu-bar icon transparency; unsigned Debug and Release Xcode builds pass
- the local installer created a runnable arm64 `Codence.app` in a temporary install directory, and a second run correctly refused to overwrite it

## Open manual gates

- validate the local browser success page in a signed-out account
- compare remaining percentages and reset times in the rebuilt app with the current Codex usage site
- visually confirm the revised popover and new menu-bar icon in light and dark appearances on the running Mac
- verify missing/outdated Codex recovery UI
- walk through source installation from a fresh checkout on another Mac
- create the intended public `Mark-in-Motion/codence` GitHub repository, or update the Settings → About GitHub link if the final URL differs; the current link does not resolve yet
- capture Codence screenshots before any downloadable release
- sign, notarize, package, and test the exact public artifact on a clean Mac before offering a binary download
