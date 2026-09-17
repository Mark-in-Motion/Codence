import Foundation

enum MenuBarDisplayMode: String, Equatable, Codable, CaseIterable {
    case weeklyPercent
    case sessionPercent
    case compactBoth
    case paceStatus
    case iconOnly

    var title: String {
        switch self {
        case .weeklyPercent:
            return "Weekly Remaining"
        case .sessionPercent:
            return "Session Remaining"
        case .compactBoth:
            return "Both Remaining"
        case .paceStatus:
            return "Pace"
        case .iconOnly:
            return "Icon Only"
        }
    }
}

enum PopoverDisplayMode: String, Equatable, Codable, CaseIterable {
    case compact
    case expanded

    var title: String {
        switch self {
        case .compact:
            return "Compact"
        case .expanded:
            return "Expanded"
        }
    }
}

/// User-configurable app settings model for refresh behavior.
struct AppSettings: Equatable, Codable {
    let refreshInterval: TimeInterval
    let launchAtLoginEnabled: Bool
    let menuBarDisplayMode: MenuBarDisplayMode
    let popoverDisplayMode: PopoverDisplayMode
    let codexExecutablePath: String?

    static let defaultValue = AppSettings(
        refreshInterval: 300,
        launchAtLoginEnabled: false,
        menuBarDisplayMode: .weeklyPercent,
        popoverDisplayMode: .expanded,
        codexExecutablePath: nil
    )

    init(
        refreshInterval: TimeInterval,
        launchAtLoginEnabled: Bool = false,
        menuBarDisplayMode: MenuBarDisplayMode = .weeklyPercent,
        popoverDisplayMode: PopoverDisplayMode = .expanded,
        codexExecutablePath: String? = nil
    ) {
        self.refreshInterval = refreshInterval
        self.launchAtLoginEnabled = launchAtLoginEnabled
        self.menuBarDisplayMode = menuBarDisplayMode
        self.popoverDisplayMode = popoverDisplayMode
        self.codexExecutablePath = codexExecutablePath
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let refreshInterval = try container.decodeIfPresent(TimeInterval.self, forKey: .refreshInterval) ?? 300
        let launchAtLoginEnabled = try container.decodeIfPresent(Bool.self, forKey: .launchAtLoginEnabled) ?? false
        let menuBarDisplayMode = try container.decodeIfPresent(MenuBarDisplayMode.self, forKey: .menuBarDisplayMode) ?? .weeklyPercent
        let popoverDisplayMode = try container.decodeIfPresent(PopoverDisplayMode.self, forKey: .popoverDisplayMode) ?? .expanded
        let codexExecutablePath = try container.decodeIfPresent(String.self, forKey: .codexExecutablePath)
        self.init(
            refreshInterval: refreshInterval,
            launchAtLoginEnabled: launchAtLoginEnabled,
            menuBarDisplayMode: menuBarDisplayMode,
            popoverDisplayMode: popoverDisplayMode,
            codexExecutablePath: codexExecutablePath
        )
    }
}
