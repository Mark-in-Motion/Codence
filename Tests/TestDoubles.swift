import Foundation
@testable import Codence

struct SnapshotFactory {
    static func make(
        sessionUsagePercent: Double = 0,
        weeklyUsagePercent: Double = 0,
        sessionResetsAt: Date? = nil,
        weeklyResetsAt: Date? = nil,
        fetchedAt: Date = Date(timeIntervalSince1970: 1_710_000_000),
        displayedAt: Date? = nil,
        source: SnapshotSource = .liveFetch,
        syncStatus: SyncStatus = .live,
        isLastKnownGood: Bool = true
    ) -> UsageSnapshot {
        UsageSnapshot(
            sessionUsagePercent: sessionUsagePercent,
            weeklyUsagePercent: weeklyUsagePercent,
            sessionResetsAt: sessionResetsAt,
            weeklyResetsAt: weeklyResetsAt,
            fetchedAt: fetchedAt,
            displayedAt: displayedAt ?? fetchedAt,
            source: source,
            syncStatus: syncStatus,
            isLastKnownGood: isLastKnownGood
        )
    }
}

struct FetchErrorFactory {
    static func make(
        kind: FetchError.Kind,
        isRetryable: Bool,
        suggestedAction: FetchError.SuggestedAction = .retry,
        originLayer: FetchError.OriginLayer = .network,
        capturedAt: Date = Date(timeIntervalSince1970: 1_710_000_000)
    ) -> FetchError {
        FetchError(
            kind: kind,
            isRetryable: isRetryable,
            suggestedAction: suggestedAction,
            originLayer: originLayer,
            capturedAt: capturedAt
        )
    }
}

final class MockUsageFetchService: UsageFetchService, @unchecked Sendable {
    var result: Result<UsageSnapshot, Error>

    init(result: Result<UsageSnapshot, Error>) {
        self.result = result
    }

    func fetchLatestSnapshot() async throws -> UsageSnapshot {
        try result.get()
    }
}

final class InMemorySettingsRepository: SettingsRepository, @unchecked Sendable {
    var settings: AppSettings

    init(settings: AppSettings = .defaultValue) {
        self.settings = settings
    }

    func loadSettings() throws -> AppSettings {
        settings
    }

    func saveSettings(_ settings: AppSettings) throws {
        self.settings = settings
    }
}

final class InMemoryAccountActivityRepository: AccountActivityRepository, @unchecked Sendable {
    var activity: CodexAccountActivity?

    func loadActivity() throws -> CodexAccountActivity? { activity }
    func saveActivity(_ activity: CodexAccountActivity) throws { self.activity = activity }
}

final class MockCodexAppServer: CodexAppServerServing, @unchecked Sendable {
    var account = CodexAccountResponse(
        account: .init(type: "chatgpt", email: nil, planType: "plus"),
        requiresOpenaiAuth: true
    )
    var limits: CodexRateLimitsResponse
    var tokenUsage = CodexTokenUsageResponse(
        summary: .init(
            lifetimeTokens: 1_000,
            peakDailyTokens: 500,
            longestRunningTurnSec: 60,
            currentStreakDays: 2,
            longestStreakDays: 4
        ),
        dailyUsageBuckets: []
    )

    init(limits: CodexRateLimitsResponse = .init(
        rateLimits: .init(
            limitId: "codex",
            limitName: nil,
            planType: "plus",
            primary: .init(usedPercent: 20, windowDurationMins: 300, resetsAt: 1_800_000_000),
            secondary: .init(usedPercent: 40, windowDurationMins: 10_080, resetsAt: 1_800_500_000),
            rateLimitReachedType: nil,
            spendControlReached: false,
            credits: nil
        ),
        rateLimitsByLimitId: nil,
        accountId: nil,
        ordinaryUsageAllowed: true,
        rateLimitResetCredits: nil
    )) {
        self.limits = limits
    }

    func readAccount() async throws -> CodexAccountResponse { account }
    func readRateLimits() async throws -> CodexRateLimitsResponse { limits }
    func readTokenUsage() async throws -> CodexTokenUsageResponse { tokenUsage }
    func startChatGPTLogin() async throws -> CodexLoginStartResponse {
        .init(type: "chatgpt", loginId: "login", authUrl: "https://chatgpt.com")
    }
    func waitForLoginCompletion(loginID: String) async throws {}
    func setRateLimitUpdateHandler(_ handler: (@Sendable () -> Void)?) {}
    func detectedExecutable() -> URL? { URL(fileURLWithPath: "/usr/bin/true") }
}

final class InMemoryUsageSnapshotRepository: UsageSnapshotRepository {
    var currentSnapshot: UsageSnapshot?
    var lastKnownGoodSnapshot: UsageSnapshot?

    func loadCurrentSnapshot() throws -> UsageSnapshot? {
        currentSnapshot
    }

    func loadLastKnownGoodSnapshot() throws -> UsageSnapshot? {
        lastKnownGoodSnapshot
    }

    func saveCurrentSnapshot(_ snapshot: UsageSnapshot) throws {
        currentSnapshot = snapshot
        if snapshot.isLastKnownGood {
            lastKnownGoodSnapshot = snapshot
        }
    }
}

final class InMemoryUsageHistoryStore: UsageHistoryStore, @unchecked Sendable {
    var history: [UsageHistoryEntry]

    init(history: [UsageHistoryEntry] = []) {
        self.history = history
    }

    func loadHistory() throws -> [UsageHistoryEntry] {
        history
    }

    func append(_ entry: UsageHistoryEntry) throws {
        history.append(entry)
    }
}

final class InMemoryDiagnosticsRepository: DiagnosticsRepository, @unchecked Sendable {
    var diagnostics: FetchDiagnostics

    init(diagnostics: FetchDiagnostics = FetchDiagnostics()) {
        self.diagnostics = diagnostics
    }

    func loadDiagnostics() throws -> FetchDiagnostics {
        diagnostics
    }

    func saveDiagnostics(_ diagnostics: FetchDiagnostics) throws {
        self.diagnostics = diagnostics
    }
}

struct StaticBackoffPolicy: BackoffPolicy {
    let delayValue: TimeInterval

    func delay(forAttempt attempt: Int) -> TimeInterval {
        delayValue
    }
}

@MainActor
final class StubSyncCoordinator: SyncCoordinating {
    var result: StartupSyncState

    init(result: StartupSyncState) {
        self.result = result
    }

    func start() async -> StartupSyncState {
        result
    }
}
