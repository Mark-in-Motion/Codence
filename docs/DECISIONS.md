# Decisions

## 2026-09-17

### Keep source installation separate from a public binary release

The repository includes a non-overwriting local source installer for people with Xcode. No unsigned app is advertised as a downloadable release. A public binary remains gated on Developer ID signing, notarization, Gatekeeper verification, and clean-Mac acceptance.

### Draw the menu-bar mark as a true template

The earlier full-color PNG had an opaque background; setting `isTemplate` caused macOS to tint that background into a gray block. The menu-bar mark is now drawn with transparent monochrome paths, while the full-color icon remains available for About and the app bundle.

### Make the popover reset and pace language glanceable

Both main quota cards use the same two-line reset footer with a relative countdown. Exact reset timestamps remain available on hover. The pace strip says whether usage is fast, slow, or on track; expanded details compare used percentage with an even-time pace. The popover no longer displays projections above 100% usage, which looked like an official quota value rather than a local estimate.

### Show remaining allowance in user-facing quota views

The Codex app server reports `usedPercent`, while the Codex usage site displays remaining allowance. Codence keeps consumed percentages in persisted snapshots and pacing calculations, and derives `100 - usedPercent` for quota cards, progress bars, menu-bar labels, and Settings history. Pace and projection remain explicitly labeled as Codence estimates.

### Use the local browser sign-in success page

Codence requests the app server's local success page instead of the optional hosted page, which could prompt the browser to open the ChatGPT desktop app. When the account is already connected, Settings shows connection status rather than inviting another sign-in.

## 2026-09-16

### Use the Codex app-server protocol

Codence integrates with `codex app-server --stdio` instead of scraping browser cookies, parsing rollout files, or calling undocumented web endpoints.

### Require an installed Codex

Codence discovers the user's Codex executable and supports a manual override. It does not bundle or redistribute an OpenAI binary.

### Let Codex own authentication

Codence reuses Codex authentication and can initiate its browser login flow. It never reads `~/.codex/auth.json` or stores OpenAI tokens.

### Monitor ChatGPT subscription usage only

API organization usage and costs require a different admin-key product and are outside v1.

### Keep account actions read-only

Credits and reached-limit state may be displayed, but Codence does not redeem credits, sign out, or send owner notifications.
