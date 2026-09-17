import XCTest
@testable import Codence

@MainActor
final class SyncCoordinatorTests: XCTestCase {
    func testStartReturnsLiveSnapshotAndPersistsSuccessDiagnostics() async {
        let snapshot = SnapshotFactory.make(
            sessionUsagePercent: 12,
            weeklyUsagePercent: 33,
            fetchedAt: Date(timeIntervalSince1970: 1_700_100_000)
        )
        let usageFetchService = MockUsageFetchService(result: .success(snapshot))
        let snapshotRepository = InMemoryUsageSnapshotRepository()
        let diagnosticsRepository = InMemoryDiagnosticsRepository()
        let coordinator = SyncCoordinator(
            container: DependencyContainer(
                usageFetchService: usageFetchService,

                settingsRepository: InMemorySettingsRepository(),
                usageSnapshotRepository: snapshotRepository,
                usageHistoryStore: InMemoryUsageHistoryStore(),
                diagnosticsRepository: diagnosticsRepository
            )
        )

        let result = await coordinator.start()

        XCTAssertEqual(result.syncStatus, .live)
        XCTAssertEqual(result.authState, .valid)
        XCTAssertEqual(result.snapshot, snapshot)
        XCTAssertEqual(snapshotRepository.currentSnapshot, snapshot)
        XCTAssertEqual(diagnosticsRepository.diagnostics.lastSuccessfulFetchAt, snapshot.fetchedAt)
        XCTAssertNil(diagnosticsRepository.diagnostics.lastError)
    }

    func testStartFallsBackToCachedSnapshotOnExpiredAuth() async {
        let cached = SnapshotFactory.make(
            sessionUsagePercent: 9,
            weeklyUsagePercent: 21,
            fetchedAt: Date(timeIntervalSince1970: 1_700_200_000),
            displayedAt: Date(timeIntervalSince1970: 1_700_200_000),
            source: .liveFetch,
            syncStatus: .live
        )
        let error = FetchErrorFactory.make(
            kind: .authExpired,
            isRetryable: false,
            suggestedAction: .reauthenticate
        )
        let usageFetchService = MockUsageFetchService(result: .failure(error))
        let snapshotRepository = InMemoryUsageSnapshotRepository()
        snapshotRepository.currentSnapshot = cached
        let diagnosticsRepository = InMemoryDiagnosticsRepository()
        let coordinator = SyncCoordinator(
            container: DependencyContainer(
                usageFetchService: usageFetchService,

                settingsRepository: InMemorySettingsRepository(),
                usageSnapshotRepository: snapshotRepository,
                usageHistoryStore: InMemoryUsageHistoryStore(),
                diagnosticsRepository: diagnosticsRepository
            )
        )

        let result = await coordinator.start()

        XCTAssertEqual(result.syncStatus, .stale)
        XCTAssertEqual(result.authState, .expired)
        XCTAssertEqual(result.snapshot?.source, .recoveredCache)
        XCTAssertEqual(result.snapshot?.weeklyUsagePercent, cached.weeklyUsagePercent)
        XCTAssertEqual(diagnosticsRepository.diagnostics.lastError, error)
        XCTAssertTrue(diagnosticsRepository.diagnostics.isShowingRecoveredCache)
    }

    func testStartReturnsErrorForInvalidAuthWithoutCache() async {
        let error = FetchErrorFactory.make(
            kind: .authInvalid,
            isRetryable: false,
            suggestedAction: .reauthenticate
        )
        let usageFetchService = MockUsageFetchService(result: .failure(error))
        let coordinator = SyncCoordinator(
            container: DependencyContainer(
                usageFetchService: usageFetchService,

                settingsRepository: InMemorySettingsRepository(),
                usageSnapshotRepository: InMemoryUsageSnapshotRepository(),
                usageHistoryStore: InMemoryUsageHistoryStore(),
                diagnosticsRepository: InMemoryDiagnosticsRepository()
            )
        )

        let result = await coordinator.start()

        XCTAssertEqual(result.syncStatus, .error)
        XCTAssertEqual(result.authState, .invalid)
        XCTAssertNil(result.snapshot)
        XCTAssertEqual(result.detailText, "Sign in with ChatGPT to read Codex usage.")
    }
}
