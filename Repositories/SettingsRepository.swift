import Foundation

/// Protocol boundary for persisting user settings separately from usage and diagnostics data.
protocol SettingsRepository: Sendable {
    func loadSettings() throws -> AppSettings
    func saveSettings(_ settings: AppSettings) throws
}
