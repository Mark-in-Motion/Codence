# Codex Entrypoint

This file is the secondary operating entrypoint for Codex work in this repo.

## Read This First

1. Read [docs/INDEX.md](docs/INDEX.md) for the documentation layout.
2. Read [docs/HANDOFF.md](docs/HANDOFF.md) for the current resume point.
3. Read [docs/PROJECT_BRIEF.md](docs/PROJECT_BRIEF.md) for project scope and current status.
4. Read [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) before refactors.
5. Read [docs/PRODUCT_RULES.md](docs/PRODUCT_RULES.md) before UX or feature changes.
6. Check [docs/DECISIONS.md](docs/DECISIONS.md) before overturning earlier decisions.

## Current Reality

- The app is runnable.
- The core live fetch and cached fallback path exists.
- Live Codex limits, cached fallback, diagnostics, pacing, history, and browser sign-in are implemented.
- Some views and services are placeholders and should be treated as planned work, not shipped behavior.

## Session Expectations

- Use [docs/ROADMAP.md](docs/ROADMAP.md) to choose the next meaningful slice of work.
- Record meaningful implementation progress in `docs/WORKLOG/`.
- Keep [docs/HANDOFF.md](docs/HANDOFF.md) current so the next session can resume without re-discovery.
- Add durable rationale to [docs/DECISIONS.md](docs/DECISIONS.md).

## Code Landmarks

- App shell: [App/](App)
- UI: [UI/](UI)
- Services: [Services/](Services)
- Models: [Models/](Models)
- Repositories: [Repositories/](Repositories)
- Diagnostics helpers: [Diagnostics/](Diagnostics)
