import Foundation

struct DependencyContainer {
    let usageFetchService: UsageFetchService?
    let paceEngine: PaceEngine?
    let notificationService: NotificationService?
    let launchAtLoginController: LaunchAtLoginControlling?
    let accountService: CodexAccountServicing?
    let appServer: CodexAppServerServing?
    let settingsRepository: SettingsRepository?
    let usageSnapshotRepository: UsageSnapshotRepository?
    let usageHistoryStore: UsageHistoryStore?
    let diagnosticsRepository: DiagnosticsRepository?
    let activityRepository: AccountActivityRepository?

    init(
        usageFetchService: UsageFetchService? = nil,
        paceEngine: PaceEngine? = nil,
        notificationService: NotificationService? = nil,
        launchAtLoginController: LaunchAtLoginControlling? = DefaultLaunchAtLoginController(),
        accountService: CodexAccountServicing? = nil,
        appServer: CodexAppServerServing? = nil,
        settingsRepository: SettingsRepository? = FileBackedSettingsRepository(),
        usageSnapshotRepository: UsageSnapshotRepository? = FileBackedUsageSnapshotRepository(),
        usageHistoryStore: UsageHistoryStore? = FileBackedUsageHistoryStore(),
        diagnosticsRepository: DiagnosticsRepository? = FileBackedDiagnosticsRepository(),
        activityRepository: AccountActivityRepository? = FileBackedAccountActivityRepository()
    ) {
        let resolvedSettings = settingsRepository
        let resolvedActivity = activityRepository ?? FileBackedAccountActivityRepository()
        let resolvedAppServer = appServer ?? CodexAppServerClient(executableOverride: {
            try? resolvedSettings?.loadSettings().codexExecutablePath
        })
        self.usageFetchService = usageFetchService
            ?? CodexUsageFetchService(appServer: resolvedAppServer, activityRepository: resolvedActivity)
        self.paceEngine = paceEngine ?? DefaultPaceEngine()
        self.notificationService = notificationService
        self.launchAtLoginController = launchAtLoginController
        self.accountService = accountService ?? CodexAccountService(appServer: resolvedAppServer)
        self.appServer = resolvedAppServer
        self.settingsRepository = resolvedSettings
        self.usageSnapshotRepository = usageSnapshotRepository
        self.usageHistoryStore = usageHistoryStore
        self.diagnosticsRepository = diagnosticsRepository
        self.activityRepository = resolvedActivity
    }
}
