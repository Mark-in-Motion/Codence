import XCTest
@testable import Codence

final class FileBackedUsageHistoryStoreTests: XCTestCase {
    func testAppendAndLoadHistoryPersistsEntries() throws {
        let root = try makeTemporaryDirectory()
        let fileManager = FileManagerIsolatingApplicationSupport(rootURL: root)
        let store = FileBackedUsageHistoryStore(fileManager: fileManager, maxEntries: 10)
        let first = UsageHistoryEntry(
            snapshot: SnapshotFactory.make(
                sessionUsagePercent: 10,
                weeklyUsagePercent: 20,
                fetchedAt: Date(timeIntervalSince1970: 1_700_000_000)
            ),
            recordedAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
        let second = UsageHistoryEntry(
            snapshot: SnapshotFactory.make(
                sessionUsagePercent: 15,
                weeklyUsagePercent: 25,
                fetchedAt: Date(timeIntervalSince1970: 1_700_000_600)
            ),
            recordedAt: Date(timeIntervalSince1970: 1_700_000_600)
        )

        try store.append(first)
        try store.append(second)

        let loaded = try store.loadHistory()

        XCTAssertEqual(loaded, [first, second])
    }

    func testAppendSkipsNearDuplicateEntries() throws {
        let root = try makeTemporaryDirectory()
        let fileManager = FileManagerIsolatingApplicationSupport(rootURL: root)
        let store = FileBackedUsageHistoryStore(fileManager: fileManager, maxEntries: 10)
        let fetchedAt = Date(timeIntervalSince1970: 1_700_000_000)
        let first = UsageHistoryEntry(
            snapshot: SnapshotFactory.make(
                sessionUsagePercent: 10,
                weeklyUsagePercent: 20,
                fetchedAt: fetchedAt
            ),
            recordedAt: fetchedAt
        )
        let duplicate = UsageHistoryEntry(
            snapshot: SnapshotFactory.make(
                sessionUsagePercent: 10,
                weeklyUsagePercent: 20,
                fetchedAt: fetchedAt.addingTimeInterval(30)
            ),
            recordedAt: fetchedAt.addingTimeInterval(30)
        )

        try store.append(first)
        try store.append(duplicate)

        XCTAssertEqual(try store.loadHistory().count, 1)
    }

    private func makeTemporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}

private final class FileManagerIsolatingApplicationSupport: FileManager, @unchecked Sendable {
    private let rootURL: URL

    init(rootURL: URL) {
        self.rootURL = rootURL
        super.init()
    }

    override func urls(for directory: SearchPathDirectory, in domainMask: SearchPathDomainMask) -> [URL] {
        guard directory == .applicationSupportDirectory else {
            return super.urls(for: directory, in: domainMask)
        }

        return [rootURL]
    }
}
