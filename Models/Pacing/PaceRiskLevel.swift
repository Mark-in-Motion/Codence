import Foundation

/// Pacing classification for trust and pacing surfaces.
enum PaceRiskLevel: String, Equatable, Codable {
    case underuseRisk
    case onTrack
    case exhaustionRisk
}
