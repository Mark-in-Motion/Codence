import Foundation

struct CodexAccountActivity: Equatable, Codable, Sendable {
    let planType: String?
    let lifetimeTokens: Int?
    let peakDailyTokens: Int?
    let longestRunningTurnSeconds: Int?
    let currentStreakDays: Int?
    let longestStreakDays: Int?
    let dailyBuckets: [DailyBucket]
    let fetchedAt: Date

    struct DailyBucket: Equatable, Codable, Sendable {
        let startDate: String
        let tokens: Int
    }
}
