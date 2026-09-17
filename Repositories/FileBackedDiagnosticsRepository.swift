import Foundation
import os

/// Persists the latest diagnostics snapshot as JSON for later recovery and inspection.
final class FileBackedDiagnosticsRepository: DiagnosticsRepository, Sendable {
    private let diagnosticsURL: URL
    private let storeDirectoryURL: URL
    private let lock = OSAllocatedUnfairLock()

    init(fileManager: FileManager = .default) {
        let storeDirectoryURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Codence", isDirectory: true)
        self.storeDirectoryURL = storeDirectoryURL
        self.diagnosticsURL = storeDirectoryURL.appendingPathComponent("diagnostics.json")
    }

    func loadDiagnostics() throws -> FetchDiagnostics {
        try lock.withLock {
            guard FileManager.default.fileExists(atPath: diagnosticsURL.path) else {
                return FetchDiagnostics()
            }

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let data = try Data(contentsOf: diagnosticsURL)
            return try decoder.decode(FetchDiagnostics.self, from: data)
        }
    }

    func saveDiagnostics(_ diagnostics: FetchDiagnostics) throws {
        try lock.withLock {
            try ensureStoreDirectoryExists()
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(diagnostics)
            try data.write(to: diagnosticsURL, options: .atomic)
        }
    }

    private func ensureStoreDirectoryExists() throws {
        try FileManager.default.createDirectory(at: storeDirectoryURL, withIntermediateDirectories: true)
    }
}
