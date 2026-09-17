# Public Release Checklist

- [x] independent Codence identity and application-support directory
- [x] no copied OpenAI credentials or auth-file access in reviewed source
- [x] explicit live-versus-cached trust state
- [x] transparent menu-bar template artwork and regression test
- [x] source build/install instructions and non-overwriting installer
- [x] manual uninstall guidance in the README, linked from Settings → About
- [x] automated tests plus unsigned Debug and Release build checks
- [x] public repository exists at https://github.com/Mark-in-Motion/Codence
- [x] public repository description, topics, and project metadata set
- [x] v0.1.0 published as a source-only GitHub pre-release, with no app or DMG asset
- [x] fresh public clone succeeded (reported 2026-09-17)
- [x] `install-local.sh` built and installed the Release app from that clone (reported 2026-09-17)
- [x] installed app launched from Finder (reported 2026-09-17)
- [x] live Codex account connection and manual refresh succeeded (reported 2026-09-17)
- [x] Launch at Login registration succeeded (reported 2026-09-17)
- [x] Codence-specific popover and Settings screenshots added to the README
- [x] Apple account status checked: free developer account with an Apple Development identity, but no Developer ID Application certificate (reported 2026-09-17)

## Still open

- [ ] verify actual automatic launch after a macOS logout/login or restart
- [ ] validate the browser sign-in flow from a signed-out Codex account

## Deferred downloadable release — requires Apple Developer Program membership

- [ ] obtain a Developer ID Application certificate and sign the Release app for outside-the-Mac-App-Store distribution
- [ ] notarize the distribution artifact, staple the ticket, and verify Gatekeeper acceptance
- [ ] package and distribute a signed, notarized DMG with release checksums
- [ ] test the exact downloaded binary on a clean Mac, including install, login, launch at login, refresh, update, and uninstall
