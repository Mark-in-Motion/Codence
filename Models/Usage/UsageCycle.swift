import Foundation

/// Cycle metadata for pacing and reset calculations.
struct UsageCycle: Equatable, Codable {
    let startedAt: Date
    let endsAt: Date
}
