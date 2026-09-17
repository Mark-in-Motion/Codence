import Foundation
import os

/// File-backed local history store for recent usage snapshots used by pacing and trend views.
final class FileBackedUsageHistoryStore: UsageHistoryStore, Sendable {
    private let historyURL: URL
    private let storeDirectoryURL: URL
    private let maxEntries: Int
    private let lock = OSAllocatedUnfairLock()

    init(fileManager: FileManager = .default, maxEntries: Int = 500) {
        self.maxEntries = max(maxEntries, 1)
        let storeDirectoryURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Codence", isDirectory: true)
            .appendingPathComponent("History", isDirectory: true)
        self.storeDirectoryURL = storeDirectoryURL
        self.historyURL = storeDirectoryURL.appendingPathComponent("usage_history.json")
    }

    func loadHistory() throws -> [UsageHistoryEntry] {
        try lock.withLock {
            try loadHistoryWithoutLock()
        }
    }

    func append(_ entry: UsageHistoryEntry) throws {
        try lock.withLock {
            try ensureStoreDirectoryExists()

            var history = try loadHistoryWithoutLock()
            if let last = history.last,
               isDuplicate(entry, comparedTo: last)
            {
                return
            }

            history.append(entry)
            if history.count > maxEntries {
                history = Array(history.suffix(maxEntries))
            }

            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(history)
            try data.write(to: historyURL, options: .atomic)
        }
    }

    private func ensureStoreDirectoryExists() throws {
        try FileManager.default.createDirectory(at: storeDirectoryURL, withIntermediateDirectories: true)
    }

    private func loadHistoryWithoutLock() throws -> [UsageHistoryEntry] {
        guard FileManager.default.fileExists(atPath: historyURL.path) else {
            return []
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let data = try Data(contentsOf: historyURL)
        return try decoder.decode([UsageHistoryEntry].self, from: data)
            .sorted { $0.recordedAt < $1.recordedAt }
    }

    private func isDuplicate(_ newEntry: UsageHistoryEntry, comparedTo existingEntry: UsageHistoryEntry) -> Bool {
        newEntry.snapshot.fetchedAt == existingEntry.snapshot.fetchedAt ||
            (newEntry.snapshot.sessionUsagePercent == existingEntry.snapshot.sessionUsagePercent &&
                newEntry.snapshot.weeklyUsagePercent == existingEntry.snapshot.weeklyUsagePercent &&
                newEntry.recordedAt.timeIntervalSince(existingEntry.recordedAt) < 60)
    }
}
