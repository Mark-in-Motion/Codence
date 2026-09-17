import Foundation

/// Logger surface for structured diagnostics events.
struct EventLogger {
    func record(_ message: String) {
        // Event persistence can be expanded later without changing call sites.
        _ = message
    }
}
