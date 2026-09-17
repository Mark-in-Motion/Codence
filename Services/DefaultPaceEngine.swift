import Foundation

/// Derives a practical pacing view from the current weekly usage snapshot.
struct DefaultPaceEngine: PaceEngine {
    private let recommendationEngine: RecommendationEngine

    init(recommendationEngine: RecommendationEngine = DefaultRecommendationEngine()) {
        self.recommendationEngine = recommendationEngine
    }

    func makeMetrics(from snapshot: UsageSnapshot, history _: [UsageHistoryEntry]) -> PaceMetrics {
        let now = snapshot.displayedAt
        let duration = TimeInterval(snapshot.longWindowDurationMinutes ?? 10_080) * 60
        let weeklyReset = snapshot.weeklyResetsAt ?? now.addingTimeInterval(duration)
        let weeklyStart = weeklyReset.addingTimeInterval(-duration)
        let elapsed = max(now.timeIntervalSince(weeklyStart), 60)
        let totalDuration = weeklyReset.timeIntervalSince(weeklyStart)
        let progress = min(max(elapsed / max(totalDuration, 1), 0.02), 1)

        let weeklyTargetByNow = min(max(progress * 100, 0), 100)
        let weeklyPaceDelta = snapshot.weeklyUsagePercent - weeklyTargetByNow
        let projectedWeeklyEndUsage = min(max(snapshot.weeklyUsagePercent / progress, 0), 250)

        let remainingPercent = max(100 - snapshot.weeklyUsagePercent, 0)
        let remainingDays = max(weeklyReset.timeIntervalSince(now) / (24 * 60 * 60), 0.25)
        let dailySafeUsageRemaining = remainingPercent / remainingDays
        let weeklyTimeRemaining = max(weeklyReset.timeIntervalSince(now), 0)
        let sessionTimeRemaining = snapshot.sessionResetsAt.map { max($0.timeIntervalSince(now), 0) }

        let exhaustionDate = forecastedExhaustionDate(
            currentWeeklyUsage: snapshot.weeklyUsagePercent,
            elapsed: elapsed,
            now: now,
            weeklyReset: weeklyReset
        )

        let riskLevel: PaceRiskLevel
        if weeklyPaceDelta <= -8 {
            riskLevel = .underuseRisk
        } else if projectedWeeklyEndUsage >= 108 || exhaustionDate != nil {
            riskLevel = .exhaustionRisk
        } else {
            riskLevel = .onTrack
        }

        let recommendationOutput = recommendationEngine.makeRecommendation(
            weeklyUsagePercent: snapshot.weeklyUsagePercent,
            targetPercentForToday: weeklyTargetByNow,
            sessionUsagePercent: snapshot.sessionUsagePercent,
            weeklyTimeRemaining: weeklyTimeRemaining,
            sessionTimeRemaining: sessionTimeRemaining
        )

        let forecastSummary: String
        switch riskLevel {
        case .underuseRisk:
            forecastSummary = projectedWeeklyEndUsage < 92
                ? "At this pace you may leave roughly \(Int(max(100 - projectedWeeklyEndUsage, 0).rounded()))% unused by reset."
                : "You are below the ideal weekly pace right now."
        case .onTrack:
            forecastSummary = "If you keep this pace, you should land near \(Int(projectedWeeklyEndUsage.rounded()))% by weekly reset."
        case .exhaustionRisk:
            if let exhaustionDate {
                forecastSummary = "At this pace you may hit 100% around \(formattedForecastDate(exhaustionDate))."
            } else {
                forecastSummary = "Current pace projects to roughly \(Int(projectedWeeklyEndUsage.rounded()))% by weekly reset."
            }
        }

        return PaceMetrics(
            weeklyTargetByNow: weeklyTargetByNow,
            weeklyPaceDelta: weeklyPaceDelta,
            projectedWeeklyEndUsage: projectedWeeklyEndUsage,
            riskLevel: riskLevel,
            recommendationState: recommendationOutput.state,
            forecastedExhaustionDate: exhaustionDate,
            dailySafeUsageRemaining: dailySafeUsageRemaining,
            recommendation: recommendationOutput.message,
            forecastSummary: forecastSummary
        )
    }

    private func forecastedExhaustionDate(
        currentWeeklyUsage: Double,
        elapsed: TimeInterval,
        now: Date,
        weeklyReset: Date
    ) -> Date? {
        guard currentWeeklyUsage > 0 else {
            return nil
        }

        let usagePerSecond = currentWeeklyUsage / elapsed
        guard usagePerSecond > 0 else {
            return nil
        }

        let secondsToExhaustion = max((100 - currentWeeklyUsage) / usagePerSecond, 0)
        let exhaustionDate = now.addingTimeInterval(secondsToExhaustion)
        return exhaustionDate < weeklyReset ? exhaustionDate : nil
    }

    private func formattedForecastDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
