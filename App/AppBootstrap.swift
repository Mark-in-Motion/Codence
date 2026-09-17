import Foundation

/// Coordinates the first app-state wiring step during launch.
@MainActor
final class AppBootstrap {
    let container: DependencyContainer
    let syncCoordinator: any SyncCoordinating
    let backoffPolicy: BackoffPolicy

    private weak var appState: AppState?
    private var scheduledRefreshTask: Task<Void, Never>?
    private var retryTask: Task<Void, Never>?
    private var isRefreshing = false

    init(
        container: DependencyContainer,
        syncCoordinator: any SyncCoordinating,
        backoffPolicy: BackoffPolicy = ExponentialBackoffPolicy()
    ) {
        self.container = container
        self.syncCoordinator = syncCoordinator
        self.backoffPolicy = backoffPolicy
    }

    func start(appState: AppState) async {
        self.appState = appState
        container.appServer?.setRateLimitUpdateHandler { [weak self] in
            Task { @MainActor in
                await self?.performRefresh(trigger: .scheduled)
            }
        }
        appState.applyLaunchState()
        reloadLocalState(into: appState)
        await performRefresh(trigger: .startup)
    }

    func refreshNow() {
        Task { @MainActor in
            await performRefresh(trigger: .manual)
        }
    }

    func refreshScheduleDidChange() {
        guard let appState else {
            return
        }

        reloadLocalState(into: appState)
        scheduleRegularRefresh()
    }

    func signInWithChatGPT() {
        guard let appState, appState.isSigningIn == false else { return }
        appState.isSigningIn = true
        appState.signInMessage = "Complete sign in in your browser."
        Task { @MainActor in
            do {
                try await container.accountService?.signInWithChatGPT()
                appState.isSigningIn = false
                appState.signInMessage = "Signed in. Refreshing usage…"
                await performRefresh(trigger: .manual)
                appState.signInMessage = nil
            } catch {
                appState.isSigningIn = false
                appState.signInMessage = "Sign in failed: \(error.localizedDescription)"
            }
        }
    }

    private func performRefresh(trigger: RefreshTrigger) async {
        guard let appState, isRefreshing == false else {
            return
        }

        isRefreshing = true
        defer { isRefreshing = false }

        scheduledRefreshTask?.cancel()
        scheduledRefreshTask = nil

        if trigger != .retry {
            cancelRetry(resetDiagnostics: true)
        }

        reloadLocalState(into: appState)

        let syncState = await syncCoordinator.start()
        persistHistoryIfNeeded(from: syncState.snapshot, syncStatus: syncState.syncStatus)
        let history = loadHistory()
        appState.applySyncState(syncState)
        appState.applyUsageHistory(history)
        appState.applyPaceMetrics(makePaceMetrics(from: syncState.snapshot, history: history))
        handlePostSync(syncState, trigger: trigger)
        scheduleRegularRefresh()
    }

    private func reloadLocalState(into appState: AppState) {
        do {
            let settings = try container.settingsRepository?.loadSettings() ?? .defaultValue
            appState.applySettings(settings)
        } catch {
            appState.applySettings(.defaultValue)
        }

        appState.applyCodexAvailability(container.appServer?.detectedExecutable() != nil)
        appState.applyAccountActivity(try? container.activityRepository?.loadActivity())

        appState.applyUsageHistory(loadHistory())
    }

    private func handlePostSync(_ syncState: StartupSyncState, trigger: RefreshTrigger) {
        guard let appState else {
            return
        }

        var diagnostics = syncState.diagnostics

        guard let lastError = diagnostics.lastError else {
            retryTask?.cancel()
            retryTask = nil
            diagnostics.retryCount = 0
            diagnostics.nextRetryAt = nil
            persistDiagnostics(diagnostics)
            appState.diagnostics = diagnostics
            return
        }

        guard lastError.isRetryable, appState.isCodexAvailable else {
            retryTask?.cancel()
            retryTask = nil
            diagnostics.retryCount = 0
            diagnostics.nextRetryAt = nil
            persistDiagnostics(diagnostics)
            appState.diagnostics = diagnostics
            return
        }

        let nextAttempt = max(diagnostics.retryCount, trigger == .retry ? diagnostics.retryCount : 0) + 1
        let delay = backoffPolicy.delay(forAttempt: nextAttempt)
        diagnostics.retryCount = nextAttempt
        diagnostics.nextRetryAt = Date().addingTimeInterval(delay)
        persistDiagnostics(diagnostics)
        appState.applyRetrySchedule(
            diagnostics: diagnostics,
            detailText: retryStatusText(error: lastError, nextRetryAt: diagnostics.nextRetryAt, attempt: nextAttempt)
        )
        scheduleRetry(after: delay)
    }

    private func scheduleRegularRefresh() {
        guard let appState, appState.isCodexAvailable else {
            scheduledRefreshTask?.cancel()
            scheduledRefreshTask = nil
            return
        }

        let interval = max(appState.settings.refreshInterval, 60)
        scheduledRefreshTask?.cancel()
        scheduledRefreshTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
            await self?.runScheduledRefresh()
        }
    }

    private func runScheduledRefresh() async {
        scheduledRefreshTask = nil
        await performRefresh(trigger: .scheduled)
    }

    private func scheduleRetry(after delay: TimeInterval) {
        retryTask?.cancel()
        retryTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            await self?.runRetryRefresh()
        }
    }

    private func runRetryRefresh() async {
        retryTask = nil
        await performRefresh(trigger: .retry)
    }

    private func cancelRetry(resetDiagnostics: Bool) {
        retryTask?.cancel()
        retryTask = nil

        guard resetDiagnostics, let appState else {
            return
        }

        var diagnostics = appState.diagnostics
        if diagnostics.nextRetryAt == nil, diagnostics.retryCount == 0 {
            return
        }

        diagnostics.nextRetryAt = nil
        diagnostics.retryCount = 0
        persistDiagnostics(diagnostics)
        appState.diagnostics = diagnostics
    }

    private func persistDiagnostics(_ diagnostics: FetchDiagnostics) {
        do {
            try container.diagnosticsRepository?.saveDiagnostics(diagnostics)
        } catch {
            // Diagnostics persistence should not block refresh scheduling.
        }
    }

    private func makePaceMetrics(from snapshot: UsageSnapshot?, history: [UsageHistoryEntry]) -> PaceMetrics? {
        guard let snapshot,
              (snapshot.longWindowDurationMinutes ?? 10_080) >= 1_440,
              let paceEngine = container.paceEngine else {
            return nil
        }

        return paceEngine.makeMetrics(from: snapshot, history: history)
    }

    private func loadHistory() -> [UsageHistoryEntry] {
        do {
            return try container.usageHistoryStore?.loadHistory() ?? []
        } catch {
            return []
        }
    }

    private func persistHistoryIfNeeded(from snapshot: UsageSnapshot?, syncStatus: SyncStatus) {
        guard syncStatus == .live, let snapshot else {
            return
        }

        do {
            try container.usageHistoryStore?.append(
                UsageHistoryEntry(snapshot: snapshot, recordedAt: snapshot.fetchedAt)
            )
        } catch {
            // History persistence should not block the app from showing the latest snapshot.
        }
    }

    private func retryStatusText(error: FetchError, nextRetryAt: Date?, attempt: Int) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        let retryLabel = nextRetryAt.map { formatter.localizedString(for: $0, relativeTo: Date()) } ?? "soon"

        switch error.kind {
        case .networkUnavailable:
            return "Network unavailable. Retrying \(retryLabel)."
        case .networkTimeout:
            return "Codex request timed out. Retrying \(retryLabel)."
        case .serverError:
            return "Codex server error. Retrying \(retryLabel)."
        case .rateLimited:
            return "Codex rate limited the app. Retrying \(retryLabel)."
        case .codexProcessFailed:
            return "Codex app server stopped. Retrying \(retryLabel)."
        default:
            return "Retry attempt \(attempt) scheduled \(retryLabel)."
        }
    }
}

private enum RefreshTrigger {
    case startup
    case manual
    case scheduled
    case retry
}
