# 2026-09-17 Codex Usage Site Parity

## Report

The live Codence snapshot showed 11% and 73% used, while the Codex usage site showed 89% and 27% remaining. These are the same values presented from opposite sides of the quota. Settings also showed a sign-in button even when authenticated, and the hosted sign-in completion page prompted the browser to open ChatGPT.

## Changes

- derive remaining percentages for quota cards, progress bars, menu-bar modes, model-specific buckets, and Settings history
- keep persisted server values as used percentages so cache compatibility and pace calculations remain intact
- show reset clock times and label Codence pace/projections as estimates
- replace the sign-in button with connected status when authentication is valid
- request the app server's local browser success page
- add tests for percentage conversion, menu-bar labels, and login parameters

## Acceptance

All 25 Swift tests pass, and the unsigned Debug Xcode build succeeds. The rebuilt macOS UI still needs a visual comparison with the Codex usage site; the local browser success page needs a signed-out flow check.
