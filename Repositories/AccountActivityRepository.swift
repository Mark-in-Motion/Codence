import Foundation
import os

protocol AccountActivityRepository: Sendable {
    func loadActivity() throws -> CodexAccountActivity?
    func saveActivity(_ activity: CodexAccountActivity) throws
}

final class FileBackedAccountActivityRepository: AccountActivityRepository, @unchecked Sendable {
    private let fileManager: FileManager
    private let lock = OSAllocatedUnfairLock()

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func loadActivity() throws -> CodexAccountActivity? {
        try lock.withLock {
            guard fileManager.fileExists(atPath: fileURL.path) else { return nil }
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(CodexAccountActivity.self, from: Data(contentsOf: fileURL))
        }
    }

    func saveActivity(_ activity: CodexAccountActivity) throws {
        try lock.withLock {
            try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            try encoder.encode(activity).write(to: fileURL, options: .atomic)
        }
    }

    private var directoryURL: URL {
        fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Codence", isDirectory: true)
    }

    private var fileURL: URL { directoryURL.appendingPathComponent("account_activity.json") }
}
