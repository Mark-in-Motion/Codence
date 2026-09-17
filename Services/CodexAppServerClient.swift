import Foundation

final class CodexAppServerClient: CodexAppServerServing, @unchecked Sendable {
    private let locator: CodexExecutableLocator
    private let executableOverride: @Sendable () -> String?
    private let lock = NSLock()
    private var process: Process?
    private var inputHandle: FileHandle?
    private var outputBuffer = Data()
    private var nextID = 1
    private var initialized = false
    private var pending: [Int: CheckedContinuation<JSONValue, Error>] = [:]
    private var loginWaiters: [String: CheckedContinuation<Void, Error>] = [:]
    private var completedLogins: [String: Result<Void, Error>] = [:]
    private var rateLimitUpdateHandler: (@Sendable () -> Void)?

    init(
        locator: CodexExecutableLocator = CodexExecutableLocator(),
        executableOverride: @escaping @Sendable () -> String? = { nil }
    ) {
        self.locator = locator
        self.executableOverride = executableOverride
    }

    deinit { process?.terminate() }

    func detectedExecutable() -> URL? {
        locator.locate(overridePath: executableOverride())
    }

    func readAccount() async throws -> CodexAccountResponse {
        try await request("account/read", params: .object(["refreshToken": .bool(false)]))
    }

    func readRateLimits() async throws -> CodexRateLimitsResponse {
        try await request(
            "account/rateLimits/read",
            params: .object(["excludeResetCreditDetails": .bool(true)])
        )
    }

    func readTokenUsage() async throws -> CodexTokenUsageResponse {
        try await request("account/usage/read", params: .object([:]))
    }

    func startChatGPTLogin() async throws -> CodexLoginStartResponse {
        try await request(
            "account/login/start",
            params: Self.chatGPTLoginParameters
        )
    }

    static let chatGPTLoginParameters: JSONValue = .object([
        "type": .string("chatgpt"),
        "useHostedLoginSuccessPage": .bool(false)
    ])

    func waitForLoginCompletion(loginID: String) async throws {
        try await withCheckedThrowingContinuation { continuation in
            let completed = lock.withLock { () -> Result<Void, Error>? in
                if let result = completedLogins.removeValue(forKey: loginID) {
                    return result
                }
                loginWaiters[loginID] = continuation
                return nil
            }
            if let completed {
                continuation.resume(with: completed)
            }
        }
    }

    func setRateLimitUpdateHandler(_ handler: (@Sendable () -> Void)?) {
        lock.withLock { rateLimitUpdateHandler = handler }
    }

    private func request<T: Decodable>(_ method: String, params: JSONValue?) async throws -> T {
        try await ensureInitialized()
        let value = try await send(method: method, params: params)
        do {
            return try value.decode(T.self)
        } catch {
            throw CodexAppServerFailure.invalidResponse("Could not decode \(method) response.")
        }
    }

    private func ensureInitialized() async throws {
        if lock.withLock({ process == nil }) { try startProcess() }
        guard lock.withLock({ initialized == false }) else { return }

        _ = try await send(
            method: "initialize",
            params: .object([
                "clientInfo": .object([
                    "name": .string("codence"),
                    "title": .string("Codence"),
                    "version": .string("1.0.0")
                ]),
                "capabilities": .object([:])
            ])
        )
        try write(message: .object(["method": .string("initialized")]))
        lock.withLock { initialized = true }
    }

    private func startProcess() throws {
        guard let executable = detectedExecutable() else {
            throw CodexAppServerFailure.executableMissing
        }
        let process = Process()
        let input = Pipe()
        let output = Pipe()
        let errors = Pipe()
        process.executableURL = executable
        process.arguments = ["app-server", "--stdio"]
        process.environment = Self.launchEnvironment(
            for: executable,
            inheriting: ProcessInfo.processInfo.environment
        )
        process.standardInput = input
        process.standardOutput = output
        process.standardError = errors

        output.fileHandleForReading.readabilityHandler = { [weak self] handle in
            self?.receive(handle.availableData)
        }
        errors.fileHandleForReading.readabilityHandler = { handle in
            _ = handle.availableData
        }
        process.terminationHandler = { [weak self] _ in
            self?.failAll(with: CodexAppServerFailure.processExited)
        }

        do { try process.run() }
        catch { throw CodexAppServerFailure.processLaunch(error.localizedDescription) }

        lock.withLock {
            self.process = process
            inputHandle = input.fileHandleForWriting
        }
    }

    static func launchEnvironment(
        for executable: URL,
        inheriting environment: [String: String]
    ) -> [String: String] {
        var result = environment
        let executableDirectory = executable.deletingLastPathComponent().path
        let inheritedPath = environment["PATH"] ?? ""
        let entries = inheritedPath.split(separator: ":").map(String.init)
        result["PATH"] = ([executableDirectory] + entries.filter { $0 != executableDirectory })
            .joined(separator: ":")
        return result
    }

    private func send(method: String, params: JSONValue?) async throws -> JSONValue {
        let requestID = lock.withLock { () -> Int in
            defer { nextID += 1 }
            return nextID
        }
        return try await withCheckedThrowingContinuation { continuation in
            lock.withLock { pending[requestID] = continuation }
            var payload: [String: JSONValue] = [
                "id": .number(Double(requestID)),
                "method": .string(method)
            ]
            if let params { payload["params"] = params }
            do { try write(message: .object(payload)) }
            catch {
                let saved = lock.withLock { pending.removeValue(forKey: requestID) }
                saved?.resume(throwing: error)
            }
        }
    }

    private func write(message: JSONValue) throws {
        guard let handle = lock.withLock({ inputHandle }) else {
            throw CodexAppServerFailure.processExited
        }
        var data = try JSONEncoder().encode(message)
        data.append(0x0A)
        try handle.write(contentsOf: data)
    }

    private func receive(_ data: Data) {
        guard data.isEmpty == false else { return }
        let lines: [Data] = lock.withLock {
            outputBuffer.append(data)
            var lines: [Data] = []
            while let newline = outputBuffer.firstIndex(of: 0x0A) {
                lines.append(outputBuffer.prefix(upTo: newline))
                outputBuffer.removeSubrange(...newline)
            }
            return lines
        }
        for line in lines where line.isEmpty == false {
            guard let envelope = try? JSONDecoder().decode(AppServerEnvelope.self, from: line) else { continue }
            handle(envelope)
        }
    }

    private func handle(_ envelope: AppServerEnvelope) {
        if let id = envelope.id {
            let continuation = lock.withLock { pending.removeValue(forKey: id) }
            if let error = envelope.error {
                continuation?.resume(throwing: CodexAppServerFailure.rpc(error.code, error.message))
            } else if let result = envelope.result {
                continuation?.resume(returning: result)
            } else {
                continuation?.resume(throwing: CodexAppServerFailure.invalidResponse("Missing RPC result."))
            }
            return
        }
        if envelope.method == "account/rateLimits/updated" {
            lock.withLock { rateLimitUpdateHandler }?()
            return
        }

        if envelope.method == "account/login/completed",
           let params = envelope.params,
           let completion = try? params.decode(CodexLoginCompletedNotification.self),
           let loginID = completion.loginId {
            let result: Result<Void, Error> = completion.success
                ? .success(())
                : .failure(CodexAppServerFailure.loginFailed(completion.error ?? "Sign in was not completed."))
            let continuation = lock.withLock { () -> CheckedContinuation<Void, Error>? in
                if let waiter = loginWaiters.removeValue(forKey: loginID) {
                    return waiter
                }
                completedLogins[loginID] = result
                return nil
            }
            continuation?.resume(with: result)
        }
    }

    private func failAll(with error: Error) {
        let continuations = lock.withLock {
            let requests = Array(pending.values)
            let logins = Array(loginWaiters.values)
            pending.removeAll()
            loginWaiters.removeAll()
            completedLogins.removeAll()
            process = nil
            inputHandle = nil
            initialized = false
            return (requests, logins)
        }
        continuations.0.forEach { $0.resume(throwing: error) }
        continuations.1.forEach { $0.resume(throwing: error) }
    }
}

private extension NSLock {
    func withLock<T>(_ body: () throws -> T) rethrows -> T {
        lock()
        defer { unlock() }
        return try body()
    }
}
