# Changelog

## Unreleased - 2026-09-17

### Changed

- Replace the opaque menu-bar image with a transparent monochrome mark.
- Add a local Release build/install script, GitHub build checks, and clearer public setup and release documentation.
- Show remaining allowance and reset times in the menu-bar quota views, matching the Codex usage site.
- Keep used percentages for local pace calculations while clearly labeling those calculations as estimates.
- Show connected account status instead of a redundant sign-in action.
- Use Codex app server's local browser success page to avoid opening the ChatGPT desktop app.

## 0.1.0 - 2026-09-16

### Added

- Independent macOS menu-bar app for monitoring Codex subscription usage.
- Codex app-server integration for ChatGPT account sign-in, rate limits, credits, plan metadata, and token activity.
- Dynamic primary, secondary, and model-specific usage windows.
- Live, cached, retrying, authentication-required, and CLI-missing trust states.
- Local usage history, pacing guidance, diagnostics, and configurable refresh behavior.
- Settings for locating the Codex executable and starting ChatGPT sign-in.

### Safety

- Codence remains read-only and never logs out Codex, redeems credits, or exposes account owner email addresses.
- Authentication remains owned by the installed Codex CLI and its app server.
