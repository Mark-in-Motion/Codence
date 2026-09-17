import AppKit
import SwiftUI

/// Diagnostics view for sync-state and retry visibility.
struct DiagnosticsView: View {
    let diagnostics: FetchDiagnostics
    private let presenter = DiagnosticsPresenter()
    private let reportBuilder = DebugReportBuilder()

    @State private var copyMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Diagnostics")
                    .font(.title2.weight(.semibold))

                VStack(alignment: .leading, spacing: 8) {
                    Text(presenter.statusLine(from: diagnostics))
                        .font(.headline)

                    if let detail = presenter.detailLine(from: diagnostics) {
                        Text(detail)
                            .foregroundStyle(.secondary)
                    }

                    if let suggestedAction = presenter.suggestedActionLine(from: diagnostics) {
                        Text(suggestedAction)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.primary)
                    }
                }

                section("Timeline") {
                    diagnosticRow("Last successful fetch", value: formattedTimestamp(diagnostics.lastSuccessfulFetchAt))
                    diagnosticRow("Last failed fetch", value: formattedTimestamp(diagnostics.lastFailedFetchAt))
                    diagnosticRow("Retry count", value: "\(diagnostics.retryCount)")
                    diagnosticRow("Next retry", value: formattedTimestamp(diagnostics.nextRetryAt))
                    diagnosticRow("Recovered cache", value: diagnostics.isShowingRecoveredCache ? "Yes" : "No")
                }

                if let error = diagnostics.lastError {
                    section("Last Error") {
                        diagnosticRow("Summary", value: presenter.errorTitle(for: error))
                        diagnosticRow("Detail", value: presenter.errorDetail(for: error))
                        diagnosticRow("Origin", value: error.originLayer.rawValue)
                        diagnosticRow("Retryable", value: error.isRetryable ? "Yes" : "No")
                        diagnosticRow("Suggested action", value: error.suggestedAction.rawValue)
                        diagnosticRow("Captured at", value: formattedTimestamp(error.capturedAt))
                    }
                }

                section("Debug Report") {
                    Text(reportBuilder.buildReport(from: diagnostics))
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color(nsColor: .textBackgroundColor))
                        )

                    HStack(spacing: 12) {
                        Button("Copy Report") {
                            copyReport()
                        }

                        if let copyMessage {
                            Text(copyMessage)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding(20)
        }
        .frame(minWidth: 520, minHeight: 420)
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)

            content()
        }
    }

    private func diagnosticRow(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(value)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func formattedTimestamp(_ date: Date?) -> String {
        guard let date else {
            return "Not available"
        }

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }

    private func copyReport() {
        let report = reportBuilder.buildReport(from: diagnostics)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(report, forType: .string)
        copyMessage = "Copied."
    }
}
