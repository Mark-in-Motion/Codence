import SwiftUI

/// Feedback for a completed quota check. Fetch metadata alone is not a data change.
enum RefreshFeedback: Equatable {
    case idle
    case checking
    case updated
    case unchanged
    case failed

    static func outcome(
        previousSnapshot: UsageSnapshot?,
        previousStatus: SyncStatus,
        result: StartupSyncState
    ) -> RefreshFeedback {
        guard result.syncStatus == .live, let latest = result.snapshot else {
            return .failed
        }
        guard previousStatus == .live, let previousSnapshot else {
            return .updated
        }
        return previousSnapshot.hasSameQuotaData(as: latest) ? .unchanged : .updated
    }
}

private extension UsageSnapshot {
    func hasSameQuotaData(as other: UsageSnapshot) -> Bool {
        sessionUsagePercent == other.sessionUsagePercent &&
        weeklyUsagePercent == other.weeklyUsagePercent &&
        modelWeeklyLimits == other.modelWeeklyLimits &&
        sessionResetsAt == other.sessionResetsAt &&
        weeklyResetsAt == other.weeklyResetsAt &&
        shortWindowDurationMinutes == other.shortWindowDurationMinutes &&
        longWindowDurationMinutes == other.longWindowDurationMinutes &&
        ordinaryUsageAllowed == other.ordinaryUsageAllowed &&
        planType == other.planType &&
        creditBalance == other.creditBalance &&
        resetCreditCount == other.resetCreditCount
    }
}

/// Single app-level state owner for UI-facing sync, auth, and snapshot state.
@MainActor
final class AppState: ObservableObject {
    @Published var currentSnapshot: UsageSnapshot?
    @Published var syncStatus: SyncStatus
    @Published var statusText: String
    @Published var diagnostics: FetchDiagnostics
    @Published var authState: AuthState
    @Published var settings: AppSettings
    @Published var isCodexAvailable: Bool
    @Published var paceMetrics: PaceMetrics?
    @Published var usageHistory: [UsageHistoryEntry]
    @Published var accountActivity: CodexAccountActivity?
    @Published var isSigningIn: Bool
    @Published var signInMessage: String?
    @Published var refreshFeedback: RefreshFeedback

    init(
        currentSnapshot: UsageSnapshot? = nil,
        syncStatus: SyncStatus = .loading,
        statusText: String = "Starting",
        diagnostics: FetchDiagnostics = FetchDiagnostics(),
        authState: AuthState = .unknown,
        settings: AppSettings = .defaultValue,
        isCodexAvailable: Bool = false,
        paceMetrics: PaceMetrics? = nil,
        usageHistory: [UsageHistoryEntry] = [],
        accountActivity: CodexAccountActivity? = nil,
        isSigningIn: Bool = false,
        signInMessage: String? = nil,
        refreshFeedback: RefreshFeedback = .idle
    ) {
        self.currentSnapshot = currentSnapshot
        self.syncStatus = syncStatus
        self.statusText = statusText
        self.diagnostics = diagnostics
        self.authState = authState
        self.settings = settings
        self.isCodexAvailable = isCodexAvailable
        self.paceMetrics = paceMetrics
        self.usageHistory = usageHistory
        self.accountActivity = accountActivity
        self.isSigningIn = isSigningIn
        self.signInMessage = signInMessage
        self.refreshFeedback = refreshFeedback
    }

    /// Applies the initial launch state before the app has any resolved sync outcome.
    func applyLaunchState() {
        syncStatus = .loading
        statusText = "Starting"
        authState = .unknown
        diagnostics = FetchDiagnostics()
        settings = .defaultValue
        isCodexAvailable = false
        paceMetrics = nil
        usageHistory = []
        refreshFeedback = .idle
    }

    /// Applies the typed startup outcome produced by the coordinator.
    func applyStartupState(_ startupState: StartupSyncState) {
        applySyncState(startupState)
    }

    /// Applies any sync outcome produced by the coordinator.
    func applySyncState(_ syncState: StartupSyncState) {
        currentSnapshot = syncState.snapshot
        syncStatus = syncState.syncStatus
        statusText = syncState.detailText
        diagnostics = syncState.diagnostics
        authState = syncState.authState
    }

    /// Updates app-level settings once a repository-backed load or save completes.
    func applySettings(_ settings: AppSettings) {
        self.settings = settings
    }

    /// Reflects whether a compatible Codex executable is available.
    func applyCodexAvailability(_ isCodexAvailable: Bool) {
        self.isCodexAvailable = isCodexAvailable
    }

    func applyAccountActivity(_ accountActivity: CodexAccountActivity?) {
        self.accountActivity = accountActivity
    }

    /// Applies retry scheduling state without losing the latest snapshot or auth resolution.
    func applyRetrySchedule(diagnostics: FetchDiagnostics, detailText: String) {
        self.diagnostics = diagnostics
        syncStatus = .retrying
        statusText = detailText
    }

    func applyPaceMetrics(_ paceMetrics: PaceMetrics?) {
        self.paceMetrics = paceMetrics
    }

    func applyUsageHistory(_ usageHistory: [UsageHistoryEntry]) {
        self.usageHistory = usageHistory.sorted { $0.recordedAt < $1.recordedAt }
    }

    /// Setup is required when the app cannot operate because auth is absent or unusable and no snapshot is available.
    var requiresSetup: Bool {
        guard currentSnapshot == nil else {
            return false
        }

        if isCodexAvailable == false {
            return true
        }

        switch authState {
        case .invalid, .expired:
            return true
        case .unknown, .valid:
            return false
        }
    }

    /// Primary menu-facing label derived from typed sync state instead of raw freeform text.
    var statusLabel: String {
        if requiresSetup {
            return "Setup"
        }

        switch syncStatus {
        case .loading:
            return "Starting"
        case .live:
            return "Live"
        case .stale:
            return currentSnapshot == nil ? "Ready" : "Saved"
        case .retrying:
            return "Retrying"
        case .error:
            return "Check App"
        }
    }

    var menuBarDisplayText: String? {
        switch settings.menuBarDisplayMode {
        case .iconOnly:
            return nil
        case .weeklyPercent:
            guard let snapshot = currentSnapshot else { return nil }
            return "W \(Int(snapshot.weeklyRemainingPercent.rounded()))% left"
        case .sessionPercent:
            guard let snapshot = currentSnapshot else { return nil }
            return "S \(Int(snapshot.sessionRemainingPercent.rounded()))% left"
        case .compactBoth:
            guard let snapshot = currentSnapshot else { return nil }
            return "S\(Int(snapshot.sessionRemainingPercent.rounded()))% W\(Int(snapshot.weeklyRemainingPercent.rounded()))% left"
        case .paceStatus:
            guard let paceMetrics else { return nil }
            switch paceMetrics.riskLevel {
            case .underuseRisk:
                return "Slow"
            case .onTrack:
                return "Track"
            case .exhaustionRisk:
                return "Fast"
            }
        }
    }
}
