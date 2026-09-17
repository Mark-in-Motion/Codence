import Foundation

/// Lightweight file-backed snapshot store used to preserve startup trust state across app relaunches.
final class FileBackedUsageSnapshotRepository: UsageSnapshotRepository, @unchecked Sendable {
    private let fileManager: FileManager
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    func loadCurrentSnapshot() throws -> UsageSnapshot? {
        try loadSnapshot(at: currentSnapshotURL)
    }

    func loadLastKnownGoodSnapshot() throws -> UsageSnapshot? {
        try loadSnapshot(at: lastKnownGoodSnapshotURL)
    }

    func saveCurrentSnapshot(_ snapshot: UsageSnapshot) throws {
        try ensureStoreDirectoryExists()
        try save(snapshot, to: currentSnapshotURL)

        if snapshot.isLastKnownGood {
            try save(snapshot, to: lastKnownGoodSnapshotURL)
        }
    }

    private var storeDirectoryURL: URL {
        fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Codence", isDirectory: true)
            .appendingPathComponent("Snapshots", isDirectory: true)
    }

    private var currentSnapshotURL: URL {
        storeDirectoryURL.appendingPathComponent("current_snapshot.json")
    }

    private var lastKnownGoodSnapshotURL: URL {
        storeDirectoryURL.appendingPathComponent("last_known_good_snapshot.json")
    }

    private func ensureStoreDirectoryExists() throws {
        try fileManager.createDirectory(at: storeDirectoryURL, withIntermediateDirectories: true)
    }

    private func loadSnapshot(at url: URL) throws -> UsageSnapshot? {
        guard fileManager.fileExists(atPath: url.path) else {
            return nil
        }

        let data = try Data(contentsOf: url)
        return try decoder.decode(UsageSnapshot.self, from: data)
    }

    private func save(_ snapshot: UsageSnapshot, to url: URL) throws {
        let data = try encoder.encode(snapshot)
        try data.write(to: url, options: .atomic)
    }
}
