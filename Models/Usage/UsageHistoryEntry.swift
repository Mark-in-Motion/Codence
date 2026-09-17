import Foundation

/// History record for the pace engine and charts.
struct UsageHistoryEntry: Equatable, Codable {
    let snapshot: UsageSnapshot
    let recordedAt: Date
}
