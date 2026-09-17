# Release Process

## Public source repository

1. Review `git status` and the exact files being published. Never upload `.env`, signing keys, local caches, logs, or a copied Codex auth file.
2. Run `swift test`, then unsigned Debug and Release Xcode builds. CI repeats these checks for public pushes and pull requests.
3. Test `./scripts/install-local.sh` into a temporary install directory. The script must not overwrite an existing app.
4. Check the source-only install steps in `README.md` on a fresh checkout. A local source build requires the full Xcode app.
5. Confirm the MIT license, independent-product notice, and privacy description remain accurate.
6. Create the public repository at the URL used by Settings → About, or update that link before publication.

## Downloadable macOS release

A source checkout is not a public binary release. Before attaching an app or DMG to GitHub Releases:

1. Complete the manual gates in [HANDOFF.md](HANDOFF.md), including live quota comparison, sign-in, the menu-bar icon in both appearances, and failure/recovery states.
2. Produce a Release archive with an Apple Developer ID Application identity. Verify the signature and bundle identifier.
3. Notarize the final distribution artifact with Apple's notary service, staple the ticket, and verify Gatekeeper accepts the downloaded copy.
4. Install the exact uploaded artifact on a clean Mac. Test Codex absent, installed/signed-out, and installed/signed-in, plus launch-at-login, refresh, update, and uninstall.
5. Capture Codence-specific screenshots and publish checksums with the release notes.

Do not describe green automation or a local unsigned build as proof of browser login, live-account parity, notarization, Gatekeeper acceptance, or clean-device installation.
