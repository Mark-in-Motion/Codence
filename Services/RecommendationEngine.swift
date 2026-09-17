import Foundation

/// Produces one short user-facing recommendation from current usage and timing context.
protocol RecommendationEngine {
    func makeRecommendation(
        weeklyUsagePercent: Double,
        targetPercentForToday: Double,
        sessionUsagePercent: Double,
        weeklyTimeRemaining: TimeInterval?,
        sessionTimeRemaining: TimeInterval?
    ) -> (state: RecommendationState, message: String)
}
