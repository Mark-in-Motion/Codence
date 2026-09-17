import Foundation

/// Protocol boundary for turning authenticated upstream responses into usage snapshots.
protocol UsageFetchService: Sendable {
    func fetchLatestSnapshot() async throws -> UsageSnapshot
}
