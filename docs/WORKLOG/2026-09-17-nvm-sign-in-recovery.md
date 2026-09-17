# 2026-09-17 nvm Sign-in Recovery

## Report

The Codence Settings window found an nvm-installed Codex executable but displayed a generic sign-in failure. The Codex CLI itself was already signed in with ChatGPT. Diagnostics showed repeated `codexProcessFailed` retries.

## Cause and change

The npm Codex launcher uses `#!/usr/bin/env node`. Xcode-launched GUI apps may lack nvm's Node directory in PATH, so the app-server child exited before account reads or browser login could complete. Codence now prepends the selected executable's directory to the child PATH and preserves other environment variables. App-server errors now have actionable descriptions instead of numeric enum errors. Settings also distinguishes app-server failure from an actual sign-in requirement.

## Verification

All 21 Swift tests passed and an unsigned Debug Xcode build succeeded. A read-only app-server probe confirmed the installed Codex CLI reports a ChatGPT account. Relaunch Codence from Xcode and check that the existing ChatGPT login is detected and quota data loads. The actual GUI/account acceptance remains open until observed.
