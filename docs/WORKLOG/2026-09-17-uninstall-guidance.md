# 2026-09-17 — Manual uninstall guidance

- Added a small Settings → About link to the public README's Uninstall section; no automated removal is performed by Codence.
- Documented quitting, disabling or removing Launch at Login, deleting the installed app, and the separate optional step of deleting local Application Support data.
- Updated the public-release checklist and handoff: the public repository exists, and the fresh-clone install, Finder launch, live account/refresh, and Launch at Login registration checks were reported successful. Actual post-login/restart launch and clean-Mac testing remain open, as do signing, notarization, and screenshots.
- Verification: `swift test` passed all 28 tests; the unsigned Release Xcode build succeeded; `git diff --check` passed. Live About-link navigation and uninstall remain manual acceptance checks.
