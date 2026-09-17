import Foundation

/// Applies a small set of priority rules to produce one plain-language recommendation.
struct DefaultRecommendationEngine: RecommendationEngine {
    private let nearResetThreshold: TimeInterval = 2 * 60 * 60
    private let significantDeltaThreshold: Double = 8

    func makeRecommendation(
        weeklyUsagePercent: Double,
        targetPercentForToday: Double,
        sessionUsagePercent: Double,
        weeklyTimeRemaining: TimeInterval?,
        sessionTimeRemaining: TimeInterval?
    ) -> (state: RecommendationState, message: String) {
        let delta = weeklyUsagePercent - targetPercentForToday

        if isNearReset(weeklyTimeRemaining) || isNearReset(sessionTimeRemaining) {
            return (.nearReset, "Reset soon, use remaining quota")
        }

        if delta >= significantDeltaThreshold {
            return (.overuseRisk, "You're using fast")
        }

        if delta <= -significantDeltaThreshold {
            return (.underuseRisk, "You may not use your full quota")
        }

        if sessionUsagePercent <= 0, isSessionActive(sessionTimeRemaining) {
            return (.idleSession, "Session is idle")
        }

        return (.onTrack, "You're on track")
    }

    private func isNearReset(_ remaining: TimeInterval?) -> Bool {
        guard let remaining else {
            return false
        }

        return remaining > 0 && remaining < nearResetThreshold
    }

    private func isSessionActive(_ remaining: TimeInterval?) -> Bool {
        guard let remaining else {
            return false
        }

        return remaining > 0
    }
}
