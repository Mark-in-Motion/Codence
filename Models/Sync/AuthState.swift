import Foundation

/// Explicit auth health state for startup, recovery, and settings flows.
enum AuthState: String, Equatable, Codable {
    case unknown
    case valid
    case expired
    case invalid
}
