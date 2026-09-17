import Foundation
import XCTest
@testable import Codence

final class CodexAppServerClientTests: XCTestCase {
    func testLaunchEnvironmentFindsNodeBesideNvmCodexLauncher() {
        let executable = URL(fileURLWithPath: "/Users/example/.nvm/versions/node/v22.14.0/bin/codex")
        let environment = CodexAppServerClient.launchEnvironment(
            for: executable,
            inheriting: ["PATH": "/usr/bin:/bin", "LANG": "en_US.UTF-8"]
        )

        XCTAssertEqual(
            environment["PATH"],
            "/Users/example/.nvm/versions/node/v22.14.0/bin:/usr/bin:/bin"
        )
        XCTAssertEqual(environment["LANG"], "en_US.UTF-8")
    }

    func testLaunchEnvironmentDoesNotDuplicateExecutableDirectory() {
        let executable = URL(fileURLWithPath: "/opt/homebrew/bin/codex")
        let environment = CodexAppServerClient.launchEnvironment(
            for: executable,
            inheriting: ["PATH": "/usr/bin:/opt/homebrew/bin:/bin"]
        )

        XCTAssertEqual(environment["PATH"], "/opt/homebrew/bin:/usr/bin:/bin")
    }

    func testProcessFailureHasActionableDescription() {
        XCTAssertTrue(
            CodexAppServerFailure.processExited.localizedDescription.contains("exited unexpectedly")
        )
    }

    func testChatGPTLoginUsesLocalSuccessPage() {
        XCTAssertEqual(
            CodexAppServerClient.chatGPTLoginParameters,
            .object([
                "type": .string("chatgpt"),
                "useHostedLoginSuccessPage": .bool(false)
            ])
        )
    }
}
