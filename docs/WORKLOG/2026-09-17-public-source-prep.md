# Public source preparation

- Audited the source and documentation for personal paths, token material, copied credentials, and stale setup claims; no committed auth material was found in the working tree under review.
- Replaced the opaque menu-bar image with transparent monochrome paths and added an image-alpha regression test.
- Made app-server login completion lookup and waiter registration atomic, preventing a callback that arrives between those steps from leaving sign-in waiting indefinitely.
- Added a non-overwriting local Release installer and GitHub CI for tests plus unsigned Debug and Release builds.
- Lowered the Swift Package manifest tools version to 5.9 so SwiftPM tests do not require Swift 6 solely for package parsing.
- Rewrote the README and setup guide around the actual source-install path and current OpenAI Codex CLI documentation.
- Separated source availability from signed/notarized downloadable release gates; the latter remain open.
- Verification: 27 Swift tests passed; unsigned Debug and Release Xcode builds passed; the installer produced a runnable arm64 app in a temporary directory and refused a second overwrite; `plutil` accepted the project and plist.
- A fresh-checkout second-Mac walkthrough, icon visual check, live sign-in/usage comparison, signing, notarization, and clean-Mac binary acceptance remain open in `HANDOFF.md`.
