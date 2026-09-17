import Foundation

/// Lifecycle coordinator for startup sync, timer refreshes, and retry orchestration.
@MainActor
protocol SyncCoordinating {
    func start() async -> StartupSyncState
}

/// Typed startup sync outcome so launch behavior is driven by structured state, not string literals.
struct StartupSyncState {
    let snapshot: UsageSnapshot?
    let syncStatus: SyncStatus
    let detailText: String
    let diagnostics: FetchDiagnostics
    let authState: AuthState
}

@MainActor
struct SyncCoordinator: SyncCoordinating {
    let container: DependencyContainer

    func start() async -> StartupSyncState {
        let cachedSnapshot = loadCachedSnapshot()
        var diagnostics = loadDiagnostics()

        do {
            if let liveSnapshot = try await container.usageFetchService?.fetchLatestSnapshot() {
                try container.usageSnapshotRepository?.saveCurrentSnapshot(liveSnapshot)
                diagnostics.lastSuccessfulFetchAt = liveSnapshot.fetchedAt
                diagnostics.lastFailedFetchAt = nil
                diagnostics.retryCount = 0
                diagnostics.nextRetryAt = nil
                diagnostics.lastError = nil
                diagnostics.isShowingRecoveredCache = false
                persistDiagnostics(diagnostics)

                return StartupSyncState(
                    snapshot: liveSnapshot,
                    syncStatus: .live,
                    detailText: "Short \(formatPercent(liveSnapshot.sessionRemainingPercent)) remaining • Long \(formatPercent(liveSnapshot.weeklyRemainingPercent)) remaining",
                    diagnostics: diagnostics,
                    authState: .valid
                )
            }
        } catch let fetchError as FetchError {
            diagnostics.lastFailedFetchAt = Date()
            diagnostics.lastError = fetchError
            diagnostics.isShowingRecoveredCache = cachedSnapshot != nil
            persistDiagnostics(diagnostics)

            if let cachedSnapshot {
                return StartupSyncState(
                    snapshot: recover(snapshot: cachedSnapshot),
                    syncStatus: .stale,
                    detailText: fallbackDetail(for: fetchError, hasSnapshot: true),
                    diagnostics: diagnostics,
                    authState: authState(for: fetchError)
                )
            }

            return StartupSyncState(
                snapshot: nil,
                syncStatus: .error,
                detailText: fallbackDetail(for: fetchError, hasSnapshot: false),
                diagnostics: diagnostics,
                authState: authState(for: fetchError)
            )
        } catch {
            let unknownError = FetchError(
                kind: .unknown(message: error.localizedDescription),
                isRetryable: false,
                suggestedAction: .inspectDiagnostics,
                originLayer: .app,
                capturedAt: Date()
            )
            diagnostics.lastFailedFetchAt = Date()
            diagnostics.lastError = unknownError
            diagnostics.isShowingRecoveredCache = cachedSnapshot != nil
            persistDiagnostics(diagnostics)

            if let cachedSnapshot {
                return StartupSyncState(
                    snapshot: recover(snapshot: cachedSnapshot),
                    syncStatus: .stale,
                    detailText: "Live refresh failed. Showing cached snapshot.",
                    diagnostics: diagnostics,
                    authState: .unknown
                )
            }

            return StartupSyncState(
                snapshot: nil,
                syncStatus: .error,
                detailText: "Unable to fetch Codex usage yet.",
                diagnostics: diagnostics,
                authState: .unknown
            )
        }

        if let cachedSnapshot {
            return StartupSyncState(
                snapshot: recover(snapshot: cachedSnapshot),
                syncStatus: .stale,
                detailText: "Usage service is not configured. Showing cached snapshot.",
                diagnostics: diagnostics,
                authState: .unknown
            )
        }

        return StartupSyncState(
            snapshot: nil,
            syncStatus: .error,
            detailText: "Usage service is not configured yet.",
            diagnostics: diagnostics,
            authState: .unknown
        )
    }

    /// Normalizes cached snapshots into an explicit recovered-cache state before showing them again.
    private func recover(snapshot: UsageSnapshot, now: Date = Date()) -> UsageSnapshot {
        UsageSnapshot(
            sessionUsagePercent: snapshot.sessionUsagePercent,
            weeklyUsagePercent: snapshot.weeklyUsagePercent,
            modelWeeklyLimits: snapshot.modelWeeklyLimits,
            sessionResetsAt: snapshot.sessionResetsAt,
            weeklyResetsAt: snapshot.weeklyResetsAt,
            fetchedAt: snapshot.fetchedAt,
            displayedAt: now,
            source: .recoveredCache,
            syncStatus: .stale,
            isLastKnownGood: snapshot.isLastKnownGood,
            shortWindowDurationMinutes: snapshot.shortWindowDurationMinutes,
            longWindowDurationMinutes: snapshot.longWindowDurationMinutes,
            ordinaryUsageAllowed: snapshot.ordinaryUsageAllowed,
            planType: snapshot.planType,
            creditBalance: snapshot.creditBalance,
            resetCreditCount: snapshot.resetCreditCount
        )
    }

    private func loadCachedSnapshot() -> UsageSnapshot? {
        do {
            if let currentSnapshot = try container.usageSnapshotRepository?.loadCurrentSnapshot() {
                return currentSnapshot
            }

            if let lastKnownGoodSnapshot = try container.usageSnapshotRepository?.loadLastKnownGoodSnapshot() {
                return lastKnownGoodSnapshot
            }
        } catch {
            return nil
        }

        return nil
    }

    private func loadDiagnostics() -> FetchDiagnostics {
        do {
            return try container.diagnosticsRepository?.loadDiagnostics() ?? FetchDiagnostics()
        } catch {
            return FetchDiagnostics()
        }
    }

    private func persistDiagnostics(_ diagnostics: FetchDiagnostics) {
        do {
            try container.diagnosticsRepository?.saveDiagnostics(diagnostics)
        } catch {
            // Diagnostics persistence should not block the startup sync outcome.
        }
    }

    private func authState(for error: FetchError) -> AuthState {
        switch error.kind {
        case .authInvalid:
            return .invalid
        case .authExpired:
            return .expired
        case .chatGPTLoginRequired:
            return .invalid
        default:
            return .unknown
        }
    }

    private func fallbackDetail(for error: FetchError, hasSnapshot: Bool) -> String {
        switch error.kind {
        case .authInvalid:
            return hasSnapshot ? "ChatGPT sign-in is unavailable. Showing cached snapshot." : "Sign in with ChatGPT to read Codex usage."
        case .authExpired:
            return hasSnapshot ? "Codex sign-in expired. Showing cached snapshot." : "Sign in with ChatGPT again."
        case .networkUnavailable:
            return hasSnapshot ? "Network unavailable. Showing cached snapshot." : "Network unavailable. No cached snapshot available."
        case .networkTimeout:
            return hasSnapshot ? "Codex request timed out. Showing cached snapshot." : "Codex request timed out before any snapshot was saved."
        case .serverError:
            return hasSnapshot ? "Codex server error. Showing cached snapshot." : "Codex server returned an error before startup sync completed."
        case .rateLimited:
            return hasSnapshot ? "Codex rate limited the app. Showing cached snapshot." : "Codex rate limited the app before a live snapshot was fetched."
        case .invalidPayload:
            return hasSnapshot ? "Codex returned an unexpected payload. Showing cached snapshot." : "Codex returned an unexpected payload."
        case .organizationResolutionFailed:
            return hasSnapshot ? "Could not resolve Codex organization. Showing cached snapshot." : "Could not resolve Codex organization for this session."
        case .codexExecutableMissing:
            return hasSnapshot ? "Codex is not installed. Showing cached snapshot." : "Install Codex or choose its executable in Settings."
        case .codexIncompatible:
            return hasSnapshot ? "Codex needs an update. Showing cached snapshot." : "Update Codex to use account usage monitoring."
        case .codexProcessFailed:
            return hasSnapshot ? "Codex app server stopped. Showing cached snapshot." : "Codex app server could not be started."
        case .chatGPTLoginRequired:
            return hasSnapshot ? "ChatGPT sign-in is required. Showing cached snapshot." : "Sign in with ChatGPT; API-key login cannot read subscription limits."
        case .cacheReadFailed, .cacheWriteFailed, .unknown:
            return hasSnapshot ? "Live refresh failed. Showing cached snapshot." : "Unable to fetch Codex usage yet."
        }
    }

    private func formatPercent(_ value: Double) -> String {
        String(format: "%.1f%%", value)
    }
}
