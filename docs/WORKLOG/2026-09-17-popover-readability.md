# Popover readability pass

- Unified the two main limit cards so their reset information starts on the same line and uses compact relative time.
- Kept exact reset timestamps in hover help and applied relative reset labels to additional quota windows.
- Replaced ambiguous "Ahead of Pace" and impossible-looking 250% usage projection with direct risk language and an even-pace comparison.
- Added countdown boundary tests; `swift test --disable-sandbox` passes 26 tests.
- Unsigned Xcode Debug build passed with `CODE_SIGNING_ALLOWED=NO`.
- Manual visual acceptance on the running Mac remains open.
