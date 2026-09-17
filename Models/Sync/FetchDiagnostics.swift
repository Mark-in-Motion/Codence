import Foundation

/// Records the latest operational facts about sync health and recovery attempts.
struct FetchDiagnostics: Equatable, Codable {
    var lastSuccessfulFetchAt: Date?
    var lastFailedFetchAt: Date?
    var retryCount: Int
    var nextRetryAt: Date?
    var lastError: FetchError?
    var isShowingRecoveredCache: Bool

    init(
        lastSuccessfulFetchAt: Date? = nil,
        lastFailedFetchAt: Date? = nil,
        retryCount: Int = 0,
        nextRetryAt: Date? = nil,
        lastError: FetchError? = nil,
        isShowingRecoveredCache: Bool = false
    ) {
        self.lastSuccessfulFetchAt = lastSuccessfulFetchAt
        self.lastFailedFetchAt = lastFailedFetchAt
        self.retryCount = retryCount
        self.nextRetryAt = nextRetryAt
        self.lastError = lastError
        self.isShowingRecoveredCache = isShowingRecoveredCache
    }
}
