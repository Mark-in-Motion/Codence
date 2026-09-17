# Bundled artwork

`codence-about.png` is the full-color icon used in the About view. The macOS app icon lives in `Resources/Assets.xcassets/AppIcon.appiconset/`.

The menu-bar icon is drawn as a transparent monochrome template in `UI/CodenceMarkIcon.swift`. Do not use the full-color square app icon as a menu-bar template: macOS tints every opaque pixel and displays a solid block.
