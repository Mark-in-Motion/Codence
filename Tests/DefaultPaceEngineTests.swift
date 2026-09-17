import XCTest
@testable import Codence

final class DefaultPaceEngineTests: XCTestCase {
    private let engine = DefaultPaceEngine(
        recommendationEngine: DefaultRecommendationEngine()
    )

    func testMakeMetricsMarksUnderuseRiskWhenWeeklyUsageIsFarBehindTarget() {
        let now = Date(timeIntervalSince1970: 1_710_000_000)
        let weeklyReset = now.addingTimeInterval(3 * 24 * 60 * 60)
        let snapshot = SnapshotFactory.make(
            sessionUsagePercent: 0,
            weeklyUsagePercent: 10,
            weeklyResetsAt: weeklyReset,
            fetchedAt: now,
            displayedAt: now
        )

        let metrics = engine.makeMetrics(from: snapshot, history: [])

        XCTAssertEqual(metrics.riskLevel, .underuseRisk)
        XCTAssertEqual(metrics.recommendationState, .underuseRisk)
        XCTAssertNil(metrics.forecastedExhaustionDate)
        XCTAssertTrue(metrics.weeklyPaceDelta < 0)
        XCTAssertTrue(metrics.forecastSummary.contains("unused") || metrics.forecastSummary.contains("below"))
    }

    func testMakeMetricsMarksOnTrackWhenUsageIsNearWeeklyTarget() {
        let now = Date(timeIntervalSince1970: 1_710_000_000)
        let weeklyReset = now.addingTimeInterval(2 * 24 * 60 * 60)
        let progress = 5.0 / 7.0
        let snapshot = SnapshotFactory.make(
            sessionUsagePercent: 25,
            weeklyUsagePercent: progress * 100,
            sessionResetsAt: now.addingTimeInterval(2 * 60 * 60),
            weeklyResetsAt: weeklyReset,
            fetchedAt: now,
            displayedAt: now
        )

        let metrics = engine.makeMetrics(from: snapshot, history: [])

        XCTAssertEqual(metrics.riskLevel, .onTrack)
        XCTAssertEqual(metrics.recommendationState, .onTrack)
        XCTAssertNil(metrics.forecastedExhaustionDate)
        XCTAssertEqual(metrics.projectedWeeklyEndUsage, 100, accuracy: 1.0)
        XCTAssertTrue(metrics.forecastSummary.contains("land near"))
    }

    func testMakeMetricsMarksExhaustionRiskWhenProjectedUsageRunsPastWeekEnd() {
        let now = Date(timeIntervalSince1970: 1_710_000_000)
        let weeklyReset = now.addingTimeInterval(5 * 24 * 60 * 60)
        let snapshot = SnapshotFactory.make(
            sessionUsagePercent: 55,
            weeklyUsagePercent: 70,
            sessionResetsAt: now.addingTimeInterval(3 * 60 * 60),
            weeklyResetsAt: weeklyReset,
            fetchedAt: now,
            displayedAt: now
        )

        let metrics = engine.makeMetrics(from: snapshot, history: [])

        XCTAssertEqual(metrics.riskLevel, .exhaustionRisk)
        XCTAssertEqual(metrics.recommendationState, .overuseRisk)
        XCTAssertNotNil(metrics.forecastedExhaustionDate)
        XCTAssertTrue(metrics.projectedWeeklyEndUsage > 100)
        XCTAssertTrue(metrics.forecastSummary.contains("100%") || metrics.forecastSummary.contains("roughly"))
    }
}
