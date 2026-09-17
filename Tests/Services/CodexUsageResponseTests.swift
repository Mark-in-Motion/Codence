import XCTest
@testable import Codence

final class CodexUsageResponseTests: XCTestCase {
    func testMapsCanonicalQuotaWindowsAndActivity() async throws {
        let appServer = MockCodexAppServer()
        let activity = InMemoryAccountActivityRepository()
        let service = CodexUsageFetchService(appServer: appServer, activityRepository: activity)

        let snapshot = try await service.fetchLatestSnapshot()

        XCTAssertEqual(snapshot.sessionUsagePercent, 20)
        XCTAssertEqual(snapshot.weeklyUsagePercent, 40)
        XCTAssertEqual(snapshot.sessionRemainingPercent, 80)
        XCTAssertEqual(snapshot.weeklyRemainingPercent, 60)
        XCTAssertEqual(snapshot.shortWindowDurationMinutes, 300)
        XCTAssertEqual(snapshot.longWindowDurationMinutes, 10_080)
        XCTAssertEqual(snapshot.sessionLimitTitle, "5-hour limit")
        XCTAssertEqual(snapshot.weeklyLimitTitle, "7-day limit")
        XCTAssertEqual(snapshot.planType, "plus")
        XCTAssertEqual(activity.activity?.lifetimeTokens, 1_000)
    }

    func testMapsAdditionalServerDefinedBuckets() async throws {
        let canonical = MockCodexAppServer().limits.rateLimits
        let extra = CodexRateLimitsResponse.RateLimitSnapshot(
            limitId: "codex_spark",
            limitName: "Codex Spark",
            planType: "plus",
            primary: .init(usedPercent: 35, windowDurationMins: 1_440, resetsAt: 1_800_000_000),
            secondary: nil,
            rateLimitReachedType: nil,
            spendControlReached: false,
            credits: nil
        )
        let response = CodexRateLimitsResponse(
            rateLimits: canonical,
            rateLimitsByLimitId: ["codex": canonical, "codex_spark": extra],
            accountId: nil,
            ordinaryUsageAllowed: true,
            rateLimitResetCredits: .init(availableCount: 2)
        )
        let appServer = MockCodexAppServer(limits: response)
        let service = CodexUsageFetchService(
            appServer: appServer,
            activityRepository: InMemoryAccountActivityRepository()
        )

        let snapshot = try await service.fetchLatestSnapshot()

        XCTAssertEqual(snapshot.modelWeeklyLimits.count, 1)
        XCTAssertEqual(snapshot.modelWeeklyLimits.first?.displayName, "Codex Spark • 1d")
        XCTAssertEqual(snapshot.modelWeeklyLimits.first?.usagePercent, 35)
        XCTAssertEqual(snapshot.modelWeeklyLimits.first?.remainingPercent, 65)
        XCTAssertEqual(snapshot.resetCreditCount, 2)
    }

    func testRejectsApiKeyAuthenticationForSubscriptionUsage() async {
        let appServer = MockCodexAppServer()
        appServer.account = .init(account: .init(type: "apiKey", email: nil, planType: nil), requiresOpenaiAuth: true)
        let service = CodexUsageFetchService(
            appServer: appServer,
            activityRepository: InMemoryAccountActivityRepository()
        )

        do {
            _ = try await service.fetchLatestSnapshot()
            XCTFail("Expected ChatGPT login failure")
        } catch let error as FetchError {
            XCTAssertEqual(error.kind, .chatGPTLoginRequired)
            XCTAssertFalse(error.isRetryable)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
