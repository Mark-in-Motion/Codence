import Foundation

final class CodexUsageFetchService: UsageFetchService, Sendable {
    private let appServer: CodexAppServerServing
    private let activityRepository: AccountActivityRepository

    init(appServer: CodexAppServerServing, activityRepository: AccountActivityRepository) {
        self.appServer = appServer
        self.activityRepository = activityRepository
    }

    func fetchLatestSnapshot() async throws -> UsageSnapshot {
        do {
            guard appServer.detectedExecutable() != nil else {
                throw CodexAppServerFailure.executableMissing
            }
            let account = try await appServer.readAccount()
            guard let activeAccount = account.account else {
                throw CodexAppServerFailure.notSignedIn
            }
            guard activeAccount.type == "chatgpt" else {
                throw CodexAppServerFailure.chatGPTLoginRequired
            }

            let limits = try await appServer.readRateLimits()
            let canonical = limits.rateLimitsByLimitId?["codex"] ?? limits.rateLimits
            let windows = [canonical.primary, canonical.secondary].compactMap { $0 }
            guard let short = windows.min(by: { ($0.windowDurationMins ?? .max) < ($1.windowDurationMins ?? .max) }) else {
                throw CodexAppServerFailure.invalidResponse("Codex did not return a quota window.")
            }
            let long = windows.max(by: { ($0.windowDurationMins ?? 0) < ($1.windowDurationMins ?? 0) }) ?? short

            let additional = additionalLimits(from: limits, excluding: canonical.limitId ?? "codex")
            let now = Date()
            let snapshot = UsageSnapshot(
                sessionUsagePercent: clamp(short.usedPercent),
                weeklyUsagePercent: clamp(long.usedPercent),
                modelWeeklyLimits: additional,
                sessionResetsAt: date(short.resetsAt),
                weeklyResetsAt: date(long.resetsAt),
                fetchedAt: now,
                displayedAt: now,
                source: .liveFetch,
                syncStatus: .live,
                isLastKnownGood: true,
                shortWindowDurationMinutes: short.windowDurationMins,
                longWindowDurationMinutes: long.windowDurationMins,
                ordinaryUsageAllowed: limits.ordinaryUsageAllowed,
                planType: canonical.planType ?? activeAccount.planType,
                creditBalance: canonical.credits?.balance,
                resetCreditCount: limits.rateLimitResetCredits?.availableCount
            )

            await refreshActivity(planType: snapshot.planType)
            return snapshot
        } catch let error as FetchError {
            throw error
        } catch let failure as CodexAppServerFailure {
            throw map(failure)
        } catch {
            throw FetchError(
                kind: .unknown(message: error.localizedDescription),
                isRetryable: true,
                suggestedAction: .inspectDiagnostics,
                originLayer: .service,
                capturedAt: Date()
            )
        }
    }

    private func refreshActivity(planType: String?) async {
        guard let usage = try? await appServer.readTokenUsage() else { return }
        let activity = CodexAccountActivity(
            planType: planType,
            lifetimeTokens: usage.summary.lifetimeTokens,
            peakDailyTokens: usage.summary.peakDailyTokens,
            longestRunningTurnSeconds: usage.summary.longestRunningTurnSec,
            currentStreakDays: usage.summary.currentStreakDays,
            longestStreakDays: usage.summary.longestStreakDays,
            dailyBuckets: (usage.dailyUsageBuckets ?? []).map {
                .init(startDate: $0.startDate, tokens: $0.tokens)
            },
            fetchedAt: Date()
        )
        try? activityRepository.saveActivity(activity)
    }

    private func additionalLimits(
        from response: CodexRateLimitsResponse,
        excluding canonicalID: String
    ) -> [ModelWeeklyLimit] {
        (response.rateLimitsByLimitId ?? [:])
            .filter { $0.key != canonicalID && $0.key != "codex" }
            .sorted { $0.key < $1.key }
            .flatMap { id, bucket -> [ModelWeeklyLimit] in
                [bucket.primary, bucket.secondary].compactMap { window in
                    guard let window else { return nil }
                    let suffix = windowLabel(window.windowDurationMins)
                    let name = bucket.limitName ?? readable(id)
                    return ModelWeeklyLimit(
                        displayName: suffix.map { "\(name) • \($0)" } ?? name,
                        usagePercent: clamp(window.usedPercent),
                        resetsAt: date(window.resetsAt),
                        durationMinutes: window.windowDurationMins
                    )
                }
            }
    }

    private func windowLabel(_ minutes: Int?) -> String? {
        guard let minutes else { return nil }
        if minutes % 1_440 == 0 { return "\(minutes / 1_440)d" }
        if minutes % 60 == 0 { return "\(minutes / 60)h" }
        return "\(minutes)m"
    }

    private func readable(_ id: String) -> String {
        id.replacingOccurrences(of: "_", with: " ")
            .split(separator: " ")
            .map { $0.capitalized }
            .joined(separator: " ")
    }

    private func date(_ timestamp: Int?) -> Date? {
        timestamp.map { Date(timeIntervalSince1970: TimeInterval($0)) }
    }

    private func clamp(_ percent: Int) -> Double {
        min(max(Double(percent), 0), 100)
    }

    private func map(_ failure: CodexAppServerFailure) -> FetchError {
        let kind: FetchError.Kind
        let retryable: Bool
        let action: FetchError.SuggestedAction
        switch failure {
        case .executableMissing:
            kind = .codexExecutableMissing
            retryable = false
            action = .inspectDiagnostics
        case .notSignedIn:
            kind = .authInvalid
            retryable = false
            action = .reauthenticate
        case .chatGPTLoginRequired:
            kind = .chatGPTLoginRequired
            retryable = false
            action = .reauthenticate
        case .incompatible, .rpc:
            kind = .codexIncompatible
            retryable = false
            action = .inspectDiagnostics
        case .loginFailed:
            kind = .authInvalid
            retryable = false
            action = .reauthenticate
        case .processExited, .processLaunch:
            kind = .codexProcessFailed
            retryable = true
            action = .retry
        case .invalidResponse(let message):
            kind = .invalidPayload(reason: message)
            retryable = false
            action = .inspectDiagnostics
        }
        return FetchError(
            kind: kind,
            isRetryable: retryable,
            suggestedAction: action,
            originLayer: .service,
            capturedAt: Date()
        )
    }
}
