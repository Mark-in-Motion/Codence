import Foundation

/// Assembles human-readable debug output from typed diagnostics state.
struct DebugReportBuilder {
    func buildReport(from diagnostics: FetchDiagnostics) -> String {
        let presenter = DiagnosticsPresenter()

        return [
            "Codence Diagnostics Report",
            "Status: \(presenter.statusLine(from: diagnostics))",
            "Last successful fetch: \(formatDate(diagnostics.lastSuccessfulFetchAt))",
            "Last failed fetch: \(formatDate(diagnostics.lastFailedFetchAt))",
            "Retry count: \(diagnostics.retryCount)",
            "Next retry: \(formatDate(diagnostics.nextRetryAt))",
            "Showing recovered cache: \(diagnostics.isShowingRecoveredCache ? "yes" : "no")",
            "Last error: \(diagnostics.lastError.map(presenter.errorTitle(for:)) ?? "none")",
            "Last error detail: \(diagnostics.lastError.map(presenter.errorDetail(for:)) ?? "none")",
            "Suggested action: \(diagnostics.lastError.flatMap { presenter.suggestedActionLine(from: FetchDiagnostics(lastSuccessfulFetchAt: diagnostics.lastSuccessfulFetchAt, lastFailedFetchAt: diagnostics.lastFailedFetchAt, retryCount: diagnostics.retryCount, nextRetryAt: diagnostics.nextRetryAt, lastError: $0, isShowingRecoveredCache: diagnostics.isShowingRecoveredCache)) } ?? "none")"
        ]
        .joined(separator: "\n")
    }

    private func formatDate(_ date: Date?) -> String {
        guard let date else {
            return "none"
        }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: date)
    }
}
