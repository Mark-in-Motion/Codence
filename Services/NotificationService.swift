import Foundation

/// Protocol boundary for future notification decisions and delivery.
protocol NotificationService {
    func evaluateNotifications(for snapshot: UsageSnapshot, diagnostics: FetchDiagnostics) async
}
