import Foundation

/// Protocol boundary for weekly pacing calculations derived from snapshots and history.
protocol PaceEngine {
    func makeMetrics(from snapshot: UsageSnapshot, history: [UsageHistoryEntry]) -> PaceMetrics
}
