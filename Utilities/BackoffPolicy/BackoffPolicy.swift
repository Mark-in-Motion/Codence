import Foundation

/// Backoff abstraction for retry scheduling logic.
protocol BackoffPolicy {
    func delay(forAttempt attempt: Int) -> TimeInterval
}

/// Small exponential backoff used for transient refresh failures.
struct ExponentialBackoffPolicy: BackoffPolicy {
    let baseDelay: TimeInterval
    let maximumDelay: TimeInterval

    init(baseDelay: TimeInterval = 30, maximumDelay: TimeInterval = 300) {
        self.baseDelay = baseDelay
        self.maximumDelay = maximumDelay
    }

    func delay(forAttempt attempt: Int) -> TimeInterval {
        guard attempt > 1 else {
            return baseDelay
        }

        let delay = baseDelay * pow(2, Double(attempt - 1))
        return min(delay, maximumDelay)
    }
}
