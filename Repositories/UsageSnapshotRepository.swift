import Foundation

/// Protocol boundary for current-snapshot and last-known-good usage persistence.
protocol UsageSnapshotRepository {
    func loadCurrentSnapshot() throws -> UsageSnapshot?
    func loadLastKnownGoodSnapshot() throws -> UsageSnapshot?
    func saveCurrentSnapshot(_ snapshot: UsageSnapshot) throws
}
