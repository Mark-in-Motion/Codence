# Project Brief

Codence is a macOS menu-bar monitor for ChatGPT-backed Codex usage.

## Implemented

- dynamic Codex short/long quota windows and reset times
- additional server-defined quota buckets
- Codex-owned ChatGPT browser login
- local cached fallback with explicit trust state
- refresh scheduling, retry backoff, diagnostics, pacing, and history
- account plan, credits, token totals, streaks, and activity summaries in Settings
- Codex executable discovery plus a manual executable override

## Boundary

Codence is read-only. It does not redeem reset credits, log users out, modify Codex configuration, send workspace-owner messages, read raw auth files, or monitor API-organization costs.
