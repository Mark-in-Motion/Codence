import XCTest
@testable import Codence

final class DefaultRecommendationEngineTests: XCTestCase {
    private let engine = DefaultRecommendationEngine()

    func testNearResetTakesPriorityOverOtherStates() {
        let result = engine.makeRecommendation(
            weeklyUsagePercent: 92,
            targetPercentForToday: 40,
            sessionUsagePercent: 80,
            weeklyTimeRemaining: 90 * 60,
            sessionTimeRemaining: 5 * 60 * 60
        )

        XCTAssertEqual(result.state, .nearReset)
        XCTAssertEqual(result.message, "Reset soon, use remaining quota")
    }

    func testOveruseRiskReturnsUsingFast() {
        let result = engine.makeRecommendation(
            weeklyUsagePercent: 60,
            targetPercentForToday: 40,
            sessionUsagePercent: 20,
            weeklyTimeRemaining: 24 * 60 * 60,
            sessionTimeRemaining: 3 * 60 * 60
        )

        XCTAssertEqual(result.state, .overuseRisk)
        XCTAssertEqual(result.message, "You're using fast")
    }

    func testUnderuseRiskReturnsQuotaMessage() {
        let result = engine.makeRecommendation(
            weeklyUsagePercent: 18,
            targetPercentForToday: 40,
            sessionUsagePercent: 10,
            weeklyTimeRemaining: 24 * 60 * 60,
            sessionTimeRemaining: 3 * 60 * 60
        )

        XCTAssertEqual(result.state, .underuseRisk)
        XCTAssertEqual(result.message, "You may not use your full quota")
    }

    func testIdleSessionReturnsIdleMessage() {
        let result = engine.makeRecommendation(
            weeklyUsagePercent: 38,
            targetPercentForToday: 40,
            sessionUsagePercent: 0,
            weeklyTimeRemaining: 24 * 60 * 60,
            sessionTimeRemaining: 3 * 60 * 60
        )

        XCTAssertEqual(result.state, .idleSession)
        XCTAssertEqual(result.message, "Session is idle")
    }

    func testOnTrackReturnsOnTrackMessage() {
        let result = engine.makeRecommendation(
            weeklyUsagePercent: 42,
            targetPercentForToday: 40,
            sessionUsagePercent: 15,
            weeklyTimeRemaining: 24 * 60 * 60,
            sessionTimeRemaining: 3 * 60 * 60
        )

        XCTAssertEqual(result.state, .onTrack)
        XCTAssertEqual(result.message, "You're on track")
    }
}
