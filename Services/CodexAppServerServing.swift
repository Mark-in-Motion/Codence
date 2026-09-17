import Foundation

protocol CodexAppServerServing: Sendable {
    func readAccount() async throws -> CodexAccountResponse
    func readRateLimits() async throws -> CodexRateLimitsResponse
    func readTokenUsage() async throws -> CodexTokenUsageResponse
    func startChatGPTLogin() async throws -> CodexLoginStartResponse
    func waitForLoginCompletion(loginID: String) async throws
    func setRateLimitUpdateHandler(_ handler: (@Sendable () -> Void)?)
    func detectedExecutable() -> URL?
}
