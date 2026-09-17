# Release Process

## Current distribution status

The [public repository](https://github.com/Mark-in-Motion/Codence) has a [v0.1.0 source-only pre-release](https://github.com/Mark-in-Motion/Codence/releases/tag/v0.1.0) with no app or DMG asset. Users currently build and install Codence from source with the full Xcode app and an installed Codex CLI; see the README. The public repository, metadata, screenshots, source-install test, Finder launch, live Codex connection, manual refresh, and Launch at Login registration are complete. Automatic launch after a login or restart has not been tested.

The current Apple account is a free developer account with an **Apple Development** signing identity, but no **Developer ID Application** certificate. Developer ID signing and notarization for normal outside-the-Mac-App-Store distribution require [Apple Developer Program membership](https://developer.apple.com/developer-id/). A development identity does not satisfy [Apple's notarization requirements](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution).

## Public source repository

1. Review `git status` and the exact files being published. Never upload `.env`, signing keys, local caches, logs, or a copied Codex auth file.
2. Run `swift test`, then unsigned Debug and Release Xcode builds. CI repeats these checks for public pushes and pull requests.
3. Test `./scripts/install-local.sh` into a temporary install directory. The script must not overwrite an existing app.
4. Check the source-only install steps in `README.md` on a fresh checkout. A local source build requires the full Xcode app.
5. Confirm the MIT license, independent-product notice, and privacy description remain accurate.
6. Confirm the public repository URL, metadata, and release notes still describe a source-only download accurately.

## Downloadable macOS release

A source checkout is not a public binary release. This work is deferred until Apple Developer Program membership provides a Developer ID Application certificate. Before attaching an app or DMG to GitHub Releases:

1. Complete the manual gates in [HANDOFF.md](HANDOFF.md), including live quota comparison, sign-in, the menu-bar icon in both appearances, and failure/recovery states.
2. Sign the Release app with a Developer ID Application identity. Verify the signature and bundle identifier.
3. Package a DMG, notarize the final distribution artifact with Apple's notary service, staple the ticket, and verify Gatekeeper accepts the downloaded copy.
4. Install the exact uploaded binary on a clean Mac. Test Codex absent, installed/signed-out, and installed/signed-in, plus launch-at-login after a login or restart, refresh, update, and uninstall.
5. Publish checksums with the release notes. The Codence-specific README screenshots are already complete.

Do not describe green automation or a local unsigned build as proof of browser login, live-account parity, notarization, Gatekeeper acceptance, or clean-device installation.
