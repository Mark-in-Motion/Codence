# Codex Setup Guide

## Install Codex first

Follow [OpenAI's current Codex CLI installation instructions](https://learn.chatgpt.com/docs/codex/cli), then run `codex --version` in Terminal. Run `codex` and choose **Sign in with ChatGPT** if you have not already connected that account. Codence needs ChatGPT-backed Codex authentication to read subscription quota; API-key-only login is not enough.

Codence searches the app's PATH, common Homebrew paths, `~/.local/bin`, and installed nvm Node versions. If automatic discovery fails, open Codence → Settings → General and choose the `codex` executable. For nvm, Codence also puts the executable's sibling Node directory on the app-server child process PATH so the GUI app can launch it outside Terminal.

## Install Codence

The public `v0.1.0` pre-release is source-only. Use `./scripts/install-local.sh` from the repository root. This requires the full Xcode app and an installed Codex CLI, and creates `~/Applications/Codence.app`. Launch it with `open "$HOME/Applications/Codence.app"`. The script does not overwrite an existing installation.

A downloadable app or DMG has not been produced. Developer ID signing and notarization are deferred until Apple Developer Program membership; do not share the locally built unsigned app as if it were a finished public installer.

## Connect and check usage

1. Launch Codence and click its C-shaped icon in the menu bar.
2. If Settings says **Sign in required**, select **Sign in with ChatGPT** and complete the browser flow. If it says **Connected to ChatGPT**, no new login is needed.
3. Return to Codence and Refresh. The app server's browser flow ends on a local success page; it should not ask to open the ChatGPT desktop app.
4. Compare the short and long remaining percentages with Codex's usage page. Reset countdowns update over time; hover over a countdown for the exact local reset time.

Codence never asks you to paste a cookie, API key, access token, or refresh token.

## Recovery

| What you see | What to do |
| --- | --- |
| Codex not found | Install the current Codex CLI or choose its executable in Settings. |
| Sign in required | Complete ChatGPT sign-in through Codence or Codex, then Refresh. |
| Update Codex | Update the installed CLI; the app server must support account and rate-limit reads. |
| Saved data | The live read failed. Codence is showing a cached snapshot; check Diagnostics and retry. |
| No menu-bar icon | Check macOS's hidden/overflow menu-bar items, then confirm Codence is running. |

If the source build fails, run `xcodebuild -version` to confirm the full Xcode app is selected. Open Xcode once to accept its license and finish installing components.
