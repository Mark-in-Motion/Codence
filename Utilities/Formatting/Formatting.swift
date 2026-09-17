import Foundation

/// Formatting helpers for sync, usage, and pacing strings.
enum Formatting {
    static func syncLabel(for status: SyncStatus) -> String {
        status.rawValue.capitalized
    }
}
