# Codex Entrypoint

This file is the operating entrypoint for Codex work in this repo.

## Read This First

1. Read [docs/INDEX.md](docs/INDEX.md) for the documentation map.
2. Read [docs/HANDOFF.md](docs/HANDOFF.md) to see where work should resume.
3. Read [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) before changing app structure.
4. Read [docs/PRODUCT_RULES.md](docs/PRODUCT_RULES.md) before changing UX or feature behavior.
5. Check [docs/DECISIONS.md](docs/DECISIONS.md) before revisiting prior choices.
6. Append the session summary to `docs/WORKLOG/` when the work is done.

## Repo Intent

Codence is a macOS menu bar app for monitoring Codex usage with explicit trust state, cached fallback, and a foundation for pacing guidance.

## Working Rules

- Keep the app menu-bar-first unless the docs explicitly change that direction.
- Preserve the typed state and protocol-boundary approach already present in the codebase.
- Prefer improving clarity of trust, auth, and recovery states over adding decorative UI.
- Update docs in the same change when architecture, product behavior, or priorities shift.
- Do not treat placeholders as complete features. Several surfaces exist only as shells.
- Only include a suggested commit title and commit body summary in the final response when the turn actually included code edits.
- Format the commit body summary as a flat list, for example:
- like this
- and that
- and so

## Key Files

- App entry: [App/CodenceApp.swift](App/CodenceApp.swift)
- Startup flow: [App/AppBootstrap.swift](App/AppBootstrap.swift)
- Sync orchestration: [App/SyncCoordinator.swift](App/SyncCoordinator.swift)
- Dependency wiring: [App/DependencyContainer.swift](App/DependencyContainer.swift)
- Menu UI: [UI/MenuBar/MenuBarRootView.swift](UI/MenuBar/MenuBarRootView.swift)
- Settings UI: [UI/Settings/SettingsView.swift](UI/Settings/SettingsView.swift)

## End Of Session

- Update [docs/HANDOFF.md](docs/HANDOFF.md).
- Add or extend a session note in `docs/WORKLOG/`.
- Update [docs/DECISIONS.md](docs/DECISIONS.md) if a durable choice was made.
- Update [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) or [docs/PRODUCT_RULES.md](docs/PRODUCT_RULES.md) if behavior changed.
