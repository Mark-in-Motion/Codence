import Foundation

/// Single prioritized recommendation state shown to the user.
enum RecommendationState: String, Equatable, Codable {
    case nearReset
    case overuseRisk
    case underuseRisk
    case idleSession
    case onTrack
}
