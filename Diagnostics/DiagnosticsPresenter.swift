import Foundation

/// Maps diagnostics data into view-ready status text.
struct DiagnosticsPresenter {
    func statusLine(from diagnostics: FetchDiagnostics) -> String {
        if diagnostics.isShowingRecoveredCache {
            return "Showing recovered cache after a live refresh failure."
        }

        if let lastError = diagnostics.lastError {
            return errorTitle(for: lastError)
        }

        if diagnostics.lastSuccessfulFetchAt != nil {
            return "Live refresh is healthy."
        }

        return "No diagnostics yet."
    }

    func detailLine(from diagnostics: FetchDiagnostics) -> String? {
        if let nextRetryAt = diagnostics.nextRetryAt {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .short
            return "Next retry \(formatter.localizedString(for: nextRetryAt, relativeTo: Date()))."
        }

        if let lastError = diagnostics.lastError {
            return errorDetail(for: lastError)
        }

        if diagnostics.retryCount > 0 {
            let attempts = diagnostics.retryCount == 1 ? "1 retry" : "\(diagnostics.retryCount) retries"
            return "Recent refreshes needed \(attempts)."
        }

        return nil
    }

    func suggestedActionLine(from diagnostics: FetchDiagnostics) -> String? {
        guard let lastError = diagnostics.lastError else {
            return nil
        }

        switch lastError.suggestedAction {
        case .retry:
            return "Suggested action: try refreshing again."
        case .reauthenticate:
            return "Suggested action: sign in with ChatGPT from Settings."
        case .inspectDiagnostics:
            return "Suggested action: inspect diagnostics details before retrying."
        case .none:
            return nil
        }
    }

    func errorTitle(for error: FetchError) -> String {
        switch error.kind {
        case .authInvalid:
            return "ChatGPT sign-in is missing or invalid."
        case .authExpired:
            return "Saved Codex session has expired."
        case .networkUnavailable:
            return "Network is unavailable."
        case .networkTimeout:
            return "Codex request timed out."
        case let .serverError(statusCode):
            return "Codex server returned HTTP \(statusCode)."
        case let .rateLimited(retryAfter):
            if let retryAfter {
                return "Codex rate limited requests for \(Int(retryAfter)) seconds."
            }
            return "Codex rate limited requests."
        case .invalidPayload:
            return "Codex returned an unexpected payload."
        case .organizationResolutionFailed:
            return "Could not resolve the Codex organization."
        case .codexExecutableMissing:
            return "Codex executable was not found."
        case .codexIncompatible:
            return "The installed Codex version is incompatible."
        case .codexProcessFailed:
            return "The Codex app server stopped unexpectedly."
        case .chatGPTLoginRequired:
            return "ChatGPT sign-in is required."
        case .cacheReadFailed:
            return "Cached usage could not be read."
        case .cacheWriteFailed:
            return "Fetched usage could not be saved locally."
        case .unknown:
            return "Refresh failed for an unknown reason."
        }
    }

    func errorDetail(for error: FetchError) -> String {
        switch error.kind {
        case .invalidPayload(let reason):
            return reason
        case .unknown(let message):
            return message
        case .serverError:
            return "The Codex backend returned a server error before usage data could be trusted."
        case .rateLimited:
            return "The app should wait before making another live usage request."
        case .authInvalid:
            return "Codence could not access a signed-in ChatGPT account through Codex."
        case .authExpired:
            return "The Codex-managed ChatGPT session is no longer valid."
        case .networkUnavailable:
            return "The request could not reach Codex because the network was unavailable."
        case .networkTimeout:
            return "The request took too long and timed out before a valid response arrived."
        case .organizationResolutionFailed:
            return "Codence could not identify the Codex organization needed for usage fetches."
        case .codexExecutableMissing:
            return "Install Codex CLI or choose the executable in Settings."
        case .codexIncompatible:
            return "Update Codex so its app server supports account and rate-limit reads."
        case .codexProcessFailed:
            return "Codence lost its local JSON-RPC connection to the Codex app server."
        case .chatGPTLoginRequired:
            return "API-key authentication cannot provide ChatGPT subscription quota data."
        case .cacheReadFailed:
            return "A saved local snapshot was expected but could not be loaded."
        case .cacheWriteFailed:
            return "Live usage was fetched but could not be persisted locally afterward."
        }
    }
}
