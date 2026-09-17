import XCTest
@testable import Codence

@MainActor
final class AppBootstrapTests: XCTestCase {
    func testStartAppendsLiveSnapshotToHistoryAndPublishesItToAppState() async {
        let snapshot = SnapshotFactory.make(
            sessionUsagePercent: 18,
            weeklyUsagePercent: 26,
            sessionResetsAt: Date(timeIntervalSince1970: 1_700_300_000).addingTimeInterval(3 * 60 * 60),
            weeklyResetsAt: Date(timeIntervalSince1970: 1_700_300_000).addingTimeInterval(4 * 24 * 60 * 60),
            fetchedAt: Date(timeIntervalSince1970: 1_700_300_000)
        )
        let historyStore = InMemoryUsageHistoryStore()
        let appState = AppState()
        let bootstrap = AppBootstrap(
            container: DependencyContainer(
                paceEngine: DefaultPaceEngine(),
                appServer: MockCodexAppServer(),
                settingsRepository: InMemorySettingsRepository(),
                usageSnapshotRepository: InMemoryUsageSnapshotRepository(),
                usageHistoryStore: historyStore,
                diagnosticsRepository: InMemoryDiagnosticsRepository()
            ),
            syncCoordinator: StubSyncCoordinator(
                result: StartupSyncState(
                    snapshot: snapshot,
                    syncStatus: .live,
                    detailText: "ok",
                    diagnostics: FetchDiagnostics(),
                    authState: .valid
                )
            ),
            backoffPolicy: StaticBackoffPolicy(delayValue: 5)
        )

        await bootstrap.start(appState: appState)

        XCTAssertEqual(historyStore.history.count, 1)
        XCTAssertEqual(historyStore.history.first?.snapshot, snapshot)
        XCTAssertEqual(appState.usageHistory.count, 1)
        XCTAssertEqual(appState.currentSnapshot, snapshot)
        XCTAssertNotNil(appState.paceMetrics)
    }

    func testStartSchedulesRetryStateForRetryableFailures() async {
        let retryableError = FetchErrorFactory.make(
            kind: .networkUnavailable,
            isRetryable: true,
            suggestedAction: .retry
        )
        let appState = AppState()
        let bootstrap = AppBootstrap(
            container: DependencyContainer(
                paceEngine: DefaultPaceEngine(),
                appServer: MockCodexAppServer(),
                settingsRepository: InMemorySettingsRepository(),
                usageSnapshotRepository: InMemoryUsageSnapshotRepository(),
                usageHistoryStore: InMemoryUsageHistoryStore(),
                diagnosticsRepository: InMemoryDiagnosticsRepository()
            ),
            syncCoordinator: StubSyncCoordinator(
                result: StartupSyncState(
                    snapshot: nil,
                    syncStatus: .error,
                    detailText: "failed",
                    diagnostics: FetchDiagnostics(lastError: retryableError),
                    authState: .unknown
                )
            ),
            backoffPolicy: StaticBackoffPolicy(delayValue: 5)
        )

        await bootstrap.start(appState: appState)

        XCTAssertEqual(appState.syncStatus, .retrying)
        XCTAssertEqual(appState.diagnostics.retryCount, 1)
        XCTAssertNotNil(appState.diagnostics.nextRetryAt)
        XCTAssertNil(appState.currentSnapshot)
        XCTAssertEqual(appState.refreshFeedback, .failed)
    }

    func testRefreshFeedbackDistinguishesFreshDataFromAnUnchangedCheck() async {
        let first = SnapshotFactory.make(
            sessionUsagePercent: 2,
            weeklyUsagePercent: 80,
            sessionResetsAt: Date(timeIntervalSince1970: 1_800_010_000),
            weeklyResetsAt: Date(timeIntervalSince1970: 1_800_500_000),
            fetchedAt: Date(timeIntervalSince1970: 1_800_000_000)
        )
        let unchanged = SnapshotFactory.make(
            sessionUsagePercent: 2,
            weeklyUsagePercent: 80,
            sessionResetsAt: first.sessionResetsAt,
            weeklyResetsAt: first.weeklyResetsAt,
            fetchedAt: first.fetchedAt.addingTimeInterval(60)
        )
        let changed = SnapshotFactory.make(
            sessionUsagePercent: 3,
            weeklyUsagePercent: 81,
            sessionResetsAt: first.sessionResetsAt,
            weeklyResetsAt: first.weeklyResetsAt,
            fetchedAt: first.fetchedAt.addingTimeInterval(120)
        )
        let appState = AppState()
        let coordinator = StubSyncCoordinator(result: liveState(first))
        var statesDuringFetch: [RefreshFeedback] = []
        coordinator.onStart = { statesDuringFetch.append(appState.refreshFeedback) }
        let bootstrap = AppBootstrap(
            container: DependencyContainer(
                paceEngine: DefaultPaceEngine(),
                appServer: MockCodexAppServer(),
                settingsRepository: InMemorySettingsRepository(),
                usageSnapshotRepository: InMemoryUsageSnapshotRepository(),
                usageHistoryStore: InMemoryUsageHistoryStore(),
                diagnosticsRepository: InMemoryDiagnosticsRepository()
            ),
            syncCoordinator: coordinator
        )

        await bootstrap.start(appState: appState)
        XCTAssertEqual(appState.refreshFeedback, .updated)

        coordinator.result = liveState(unchanged)
        await bootstrap.refreshNowAndWait()
        XCTAssertEqual(appState.refreshFeedback, .unchanged)

        coordinator.result = liveState(changed)
        await bootstrap.refreshNowAndWait()
        XCTAssertEqual(appState.refreshFeedback, .updated)

        coordinator.result = StartupSyncState(
            snapshot: changed,
            syncStatus: .stale,
            detailText: "Showing saved data",
            diagnostics: FetchDiagnostics(lastError: FetchErrorFactory.make(kind: .networkUnavailable, isRetryable: false)),
            authState: .unknown
        )
        await bootstrap.refreshNowAndWait()
        XCTAssertEqual(appState.refreshFeedback, .failed)
        XCTAssertEqual(statesDuringFetch, [.checking, .checking, .checking, .checking])
    }

    private func liveState(_ snapshot: UsageSnapshot) -> StartupSyncState {
        StartupSyncState(
            snapshot: snapshot,
            syncStatus: .live,
            detailText: "Live",
            diagnostics: FetchDiagnostics(),
            authState: .valid
        )
    }
}
