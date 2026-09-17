import Foundation

/// Structured fetch failure model used by sync logic and diagnostics surfaces.
struct FetchError: Error, Equatable, Codable {
    let kind: Kind
    let isRetryable: Bool
    let suggestedAction: SuggestedAction
    let originLayer: OriginLayer
    let capturedAt: Date

    enum Kind: Equatable, Codable {
        case authInvalid
        case authExpired
        case networkUnavailable
        case networkTimeout
        case serverError(statusCode: Int)
        case rateLimited(retryAfter: TimeInterval?)
        case invalidPayload(reason: String)
        case organizationResolutionFailed
        case codexExecutableMissing
        case codexIncompatible
        case codexProcessFailed
        case chatGPTLoginRequired
        case cacheReadFailed
        case cacheWriteFailed
        case unknown(message: String)
    }

    enum SuggestedAction: String, Equatable, Codable {
        case retry
        case reauthenticate
        case inspectDiagnostics
        case none
    }

    enum OriginLayer: String, Equatable, Codable {
        case app
        case service
        case repository
        case network
    }
}
