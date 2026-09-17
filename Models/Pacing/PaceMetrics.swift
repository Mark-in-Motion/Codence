import Foundation

/// Pacing output for weekly projection and risk messaging.
struct PaceMetrics: Equatable, Codable {
    let weeklyTargetByNow: Double
    let weeklyPaceDelta: Double
    let projectedWeeklyEndUsage: Double
    let riskLevel: PaceRiskLevel
    let recommendationState: RecommendationState
    let forecastedExhaustionDate: Date?
    let dailySafeUsageRemaining: Double
    let recommendation: String
    let forecastSummary: String
}
