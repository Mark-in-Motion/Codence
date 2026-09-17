import Foundation

/// Limit container for session and weekly ceilings.
struct UsageLimits: Equatable, Codable {
    let sessionLimit: Double
    let weeklyLimit: Double
}
