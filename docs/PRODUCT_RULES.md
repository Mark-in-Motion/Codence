# Product Rules

- Remain menu-bar-first.
- Keep the menu-bar icon transparent and monochrome so macOS can tint it in light and dark appearances; do not use an opaque app-icon background as a template.
- Preserve the established Claudence layout density and interaction model.
- Treat live, cached, missing, and failed data as distinct trust states.
- Derive quota labels from server-reported durations; never assume every account has five-hour and seven-day windows.
- Present quota percentages as remaining allowance, matching the Codex usage site. Preserve the server's used percentages in snapshots and pacing calculations.
- Show relative time until each quota reset in the popover, with matching footer layout for the two main limits. Keep the exact reset date and time available on hover.
- Label Codence pace and projection as local estimates, distinct from official quota figures.
- Describe pace risk in plain language; do not show projected usage above 100% as if it were an attainable quota value.
- Treat explicit backend blocked/spend-control state as authoritative.
- Show additional limit buckets dynamically.
- Hide pacing when no window of at least one day exists.
- Keep account statistics in Settings rather than crowding the popover.
- Show connected status instead of a sign-in action when ChatGPT authentication is valid.
- Keep v1 read-only.
- Never read, copy, log, or persist OpenAI credentials.
- Never claim Codence is an official OpenAI product.
- Do not present a local unsigned build as a friction-free downloadable release; public binaries need signing, notarization, and clean-Mac verification.
