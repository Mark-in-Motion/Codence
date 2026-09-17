import Foundation

enum JSONValue: Codable, Equatable, Sendable {
    case object([String: JSONValue])
    case array([JSONValue])
    case string(String)
    case number(Double)
    case bool(Bool)
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() { self = .null }
        else if let value = try? container.decode(Bool.self) { self = .bool(value) }
        else if let value = try? container.decode(Double.self) { self = .number(value) }
        else if let value = try? container.decode(String.self) { self = .string(value) }
        else if let value = try? container.decode([JSONValue].self) { self = .array(value) }
        else { self = .object(try container.decode([String: JSONValue].self)) }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .object(let value): try container.encode(value)
        case .array(let value): try container.encode(value)
        case .string(let value): try container.encode(value)
        case .number(let value): try container.encode(value)
        case .bool(let value): try container.encode(value)
        case .null: try container.encodeNil()
        }
    }

    func decode<T: Decodable>(_ type: T.Type) throws -> T {
        try JSONDecoder().decode(type, from: JSONEncoder().encode(self))
    }
}

struct AppServerEnvelope: Decodable, Sendable {
    let id: Int?
    let method: String?
    let result: JSONValue?
    let params: JSONValue?
    let error: AppServerRPCError?
}

struct AppServerRPCError: Error, Decodable, Equatable, Sendable {
    let code: Int
    let message: String
}

struct CodexAccountResponse: Decodable, Equatable, Sendable {
    let account: Account?
    let requiresOpenaiAuth: Bool

    struct Account: Decodable, Equatable, Sendable {
        let type: String
        let email: String?
        let planType: String?
    }
}

struct CodexRateLimitsResponse: Decodable, Equatable, Sendable {
    let rateLimits: RateLimitSnapshot
    let rateLimitsByLimitId: [String: RateLimitSnapshot]?
    let accountId: String?
    let ordinaryUsageAllowed: Bool?
    let rateLimitResetCredits: ResetCredits?

    struct RateLimitSnapshot: Decodable, Equatable, Sendable {
        let limitId: String?
        let limitName: String?
        let planType: String?
        let primary: RateLimitWindow?
        let secondary: RateLimitWindow?
        let rateLimitReachedType: String?
        let spendControlReached: Bool?
        let credits: Credits?
    }

    struct RateLimitWindow: Decodable, Equatable, Sendable {
        let usedPercent: Int
        let windowDurationMins: Int?
        let resetsAt: Int?
    }

    struct Credits: Decodable, Equatable, Sendable {
        let balance: String?
        let hasCredits: Bool
        let unlimited: Bool
    }

    struct ResetCredits: Decodable, Equatable, Sendable {
        let availableCount: Int
    }
}

struct CodexTokenUsageResponse: Decodable, Equatable, Sendable {
    let summary: Summary
    let dailyUsageBuckets: [DailyBucket]?

    struct Summary: Decodable, Equatable, Sendable {
        let lifetimeTokens: Int?
        let peakDailyTokens: Int?
        let longestRunningTurnSec: Int?
        let currentStreakDays: Int?
        let longestStreakDays: Int?
    }

    struct DailyBucket: Decodable, Equatable, Sendable {
        let startDate: String
        let tokens: Int
    }
}

struct CodexLoginStartResponse: Decodable, Equatable, Sendable {
    let type: String
    let loginId: String
    let authUrl: String
}

struct CodexLoginCompletedNotification: Decodable, Equatable, Sendable {
    let loginId: String?
    let success: Bool
    let error: String?
}

enum CodexAppServerFailure: Error, Equatable, Sendable {
    case executableMissing
    case incompatible(String)
    case processLaunch(String)
    case processExited
    case invalidResponse(String)
    case rpc(Int, String)
    case notSignedIn
    case chatGPTLoginRequired
    case loginFailed(String)
}

extension CodexAppServerFailure: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .executableMissing:
            return "Codex CLI was not found. Install it or choose its executable in Settings."
        case .incompatible(let detail):
            return "This Codex CLI is incompatible with Codence: \(detail)"
        case .processLaunch(let detail):
            return "Codex app server could not start: \(detail)"
        case .processExited:
            return "Codex app server exited unexpectedly. Check the executable path or update Codex CLI."
        case .invalidResponse(let detail):
            return "Codex returned an unexpected response: \(detail)"
        case .rpc(let code, let message):
            return "Codex app server error \(code): \(message)"
        case .notSignedIn:
            return "Codex CLI is not signed in. Sign in with ChatGPT to view subscription usage."
        case .chatGPTLoginRequired:
            return "Codex CLI is using an API key. Sign in with ChatGPT to view subscription usage."
        case .loginFailed(let detail):
            return "ChatGPT sign-in failed: \(detail)"
        }
    }
}
