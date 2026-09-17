import Foundation

/// Protocol boundary for retaining timestamped usage snapshots for pacing and analytics.
protocol UsageHistoryStore: Sendable {
    func loadHistory() throws -> [UsageHistoryEntry]
    func append(_ entry: UsageHistoryEntry) throws
}
