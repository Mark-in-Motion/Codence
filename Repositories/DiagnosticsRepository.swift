import Foundation

/// Protocol boundary for persisting fetch diagnostics and operational events.
protocol DiagnosticsRepository: Sendable {
    func loadDiagnostics() throws -> FetchDiagnostics
    func saveDiagnostics(_ diagnostics: FetchDiagnostics) throws
}
