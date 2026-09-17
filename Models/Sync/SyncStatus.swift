import Foundation

/// Explicit sync state so the UI never infers freshness from timestamps alone.
enum SyncStatus: String, Equatable, Codable {
    case loading
    case live
    case stale
    case retrying
    case error
}
