# Refresh feedback

- Added typed refresh feedback distinct from live/cached sync trust state.
- The Refresh button displays an activity spinner while a check is running; a fixed-height row always displays the result or a sensible resting message.
- Successful checks compare quota values, reset times, and relevant limit metadata while ignoring fetch timestamps; unchanged data is labeled as such, and cached fallback is never called an update.
- Covered updated, unchanged, failed, and in-flight states in automated tests.
- Verification: 28 Swift tests passed; unsigned Debug and Release Xcode builds passed.
- Manual visual check of the fixed-height popover states remains open.
