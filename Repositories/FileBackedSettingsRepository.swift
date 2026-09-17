import Foundation
import os

/// Persists app settings as JSON in Application Support, returning defaults when no file exists yet.
final class FileBackedSettingsRepository: SettingsRepository, Sendable {
    private let settingsURL: URL
    private let storeDirectoryURL: URL
    private let lock = OSAllocatedUnfairLock()

    init(fileManager: FileManager = .default) {
        let storeDirectoryURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Codence", isDirectory: true)
        self.storeDirectoryURL = storeDirectoryURL
        self.settingsURL = storeDirectoryURL.appendingPathComponent("settings.json")
    }

    func loadSettings() throws -> AppSettings {
        try lock.withLock {
            guard FileManager.default.fileExists(atPath: settingsURL.path) else {
                return .defaultValue
            }

            let data = try Data(contentsOf: settingsURL)
            return try JSONDecoder().decode(AppSettings.self, from: data)
        }
    }

    func saveSettings(_ settings: AppSettings) throws {
        try lock.withLock {
            try ensureStoreDirectoryExists()
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(settings)
            try data.write(to: settingsURL, options: .atomic)
        }
    }

    private func ensureStoreDirectoryExists() throws {
        try FileManager.default.createDirectory(at: storeDirectoryURL, withIntermediateDirectories: true)
    }
}
