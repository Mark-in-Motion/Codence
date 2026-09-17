import AppKit
import Foundation

protocol CodexAccountServicing: Sendable {
    func signInWithChatGPT() async throws
}

final class CodexAccountService: CodexAccountServicing, Sendable {
    private let appServer: CodexAppServerServing

    init(appServer: CodexAppServerServing) {
        self.appServer = appServer
    }

    func signInWithChatGPT() async throws {
        let login = try await appServer.startChatGPTLogin()
        guard let url = URL(string: login.authUrl) else {
            throw CodexAppServerFailure.invalidResponse("Codex returned an invalid sign-in URL.")
        }
        _ = await MainActor.run { NSWorkspace.shared.open(url) }
        try await appServer.waitForLoginCompletion(loginID: login.loginId)
    }
}
