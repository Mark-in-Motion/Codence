import Foundation

/// Represents the usage values currently shown in the app, along with provenance and freshness metadata.
struct UsageSnapshot: Equatable, Codable {
    let sessionUsagePercent: Double
    let weeklyUsagePercent: Double
    let modelWeeklyLimits: [ModelWeeklyLimit]
    let sessionResetsAt: Date?
    let weeklyResetsAt: Date?
    let fetchedAt: Date
    let displayedAt: Date
    let source: SnapshotSource
    let syncStatus: SyncStatus
    let isLastKnownGood: Bool
    let shortWindowDurationMinutes: Int?
    let longWindowDurationMinutes: Int?
    let ordinaryUsageAllowed: Bool?
    let planType: String?
    let creditBalance: String?
    let resetCreditCount: Int?

    init(
        sessionUsagePercent: Double,
        weeklyUsagePercent: Double,
        modelWeeklyLimits: [ModelWeeklyLimit] = [],
        sessionResetsAt: Date?,
        weeklyResetsAt: Date?,
        fetchedAt: Date,
        displayedAt: Date,
        source: SnapshotSource,
        syncStatus: SyncStatus,
        isLastKnownGood: Bool,
        shortWindowDurationMinutes: Int? = nil,
        longWindowDurationMinutes: Int? = nil,
        ordinaryUsageAllowed: Bool? = nil,
        planType: String? = nil,
        creditBalance: String? = nil,
        resetCreditCount: Int? = nil
    ) {
        self.sessionUsagePercent = sessionUsagePercent
        self.weeklyUsagePercent = weeklyUsagePercent
        self.modelWeeklyLimits = modelWeeklyLimits
        self.sessionResetsAt = sessionResetsAt
        self.weeklyResetsAt = weeklyResetsAt
        self.fetchedAt = fetchedAt
        self.displayedAt = displayedAt
        self.source = source
        self.syncStatus = syncStatus
        self.isLastKnownGood = isLastKnownGood
        self.shortWindowDurationMinutes = shortWindowDurationMinutes
        self.longWindowDurationMinutes = longWindowDurationMinutes
        self.ordinaryUsageAllowed = ordinaryUsageAllowed
        self.planType = planType
        self.creditBalance = creditBalance
        self.resetCreditCount = resetCreditCount
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        sessionUsagePercent = try container.decode(Double.self, forKey: .sessionUsagePercent)
        weeklyUsagePercent = try container.decode(Double.self, forKey: .weeklyUsagePercent)
        modelWeeklyLimits = try container.decodeIfPresent([ModelWeeklyLimit].self, forKey: .modelWeeklyLimits) ?? []
        sessionResetsAt = try container.decodeIfPresent(Date.self, forKey: .sessionResetsAt)
        weeklyResetsAt = try container.decodeIfPresent(Date.self, forKey: .weeklyResetsAt)
        fetchedAt = try container.decode(Date.self, forKey: .fetchedAt)
        displayedAt = try container.decode(Date.self, forKey: .displayedAt)
        source = try container.decode(SnapshotSource.self, forKey: .source)
        syncStatus = try container.decode(SyncStatus.self, forKey: .syncStatus)
        isLastKnownGood = try container.decode(Bool.self, forKey: .isLastKnownGood)
        shortWindowDurationMinutes = try container.decodeIfPresent(Int.self, forKey: .shortWindowDurationMinutes)
        longWindowDurationMinutes = try container.decodeIfPresent(Int.self, forKey: .longWindowDurationMinutes)
        ordinaryUsageAllowed = try container.decodeIfPresent(Bool.self, forKey: .ordinaryUsageAllowed)
        planType = try container.decodeIfPresent(String.self, forKey: .planType)
        creditBalance = try container.decodeIfPresent(String.self, forKey: .creditBalance)
        resetCreditCount = try container.decodeIfPresent(Int.self, forKey: .resetCreditCount)
    }

    var sessionLimitTitle: String { Self.windowTitle(minutes: shortWindowDurationMinutes, fallback: "Primary limit") }
    var weeklyLimitTitle: String { Self.windowTitle(minutes: longWindowDurationMinutes, fallback: "Secondary limit") }
    var sessionRemainingPercent: Double { Self.remainingPercent(from: sessionUsagePercent) }
    var weeklyRemainingPercent: Double { Self.remainingPercent(from: weeklyUsagePercent) }

    static func remainingPercent(from usedPercent: Double) -> Double {
        min(max(100 - usedPercent, 0), 100)
    }

    private static func windowTitle(minutes: Int?, fallback: String) -> String {
        guard let minutes else { return fallback }
        if minutes % 1_440 == 0 { return "\(minutes / 1_440)-day limit" }
        if minutes % 60 == 0 { return "\(minutes / 60)-hour limit" }
        return "\(minutes)-minute limit"
    }
}

/// A per-model weekly limit reported by the usage API's scoped `limits` array.
/// These draw from the shared weekly allowance with their own cap; the set of
/// models can change server-side at any time, so the app renders whatever is present.
struct ModelWeeklyLimit: Equatable, Codable {
    let displayName: String
    let usagePercent: Double
    let resetsAt: Date?
    let durationMinutes: Int?

    init(displayName: String, usagePercent: Double, resetsAt: Date?, durationMinutes: Int? = nil) {
        self.displayName = displayName
        self.usagePercent = usagePercent
        self.resetsAt = resetsAt
        self.durationMinutes = durationMinutes
    }

    var remainingPercent: Double { UsageSnapshot.remainingPercent(from: usagePercent) }
}

enum SnapshotSource: String, Equatable, Codable {
    case liveFetch
    case startupCache
    case recoveredCache
    case historyReplay
}
