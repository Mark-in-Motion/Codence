import AppKit
import SwiftUI

/// Structured settings window with macOS-style sidebar navigation.
struct SettingsView: View {
    @Environment(\.openURL) private var openURL
    @Environment(\.openWindow) private var openWindow

    @ObservedObject var appState: AppState
    let container: DependencyContainer
    let refreshAction: () -> Void
    let scheduleRefreshAction: () -> Void
    let signInAction: () -> Void

    @State private var selectedPane: SettingsPane? = .general
    @State private var executablePathDraft = ""
    @State private var selectedRefreshInterval: TimeInterval = AppSettings.defaultValue.refreshInterval
    @State private var selectedLaunchAtLoginEnabled = AppSettings.defaultValue.launchAtLoginEnabled
    @State private var selectedMenuBarDisplayMode: MenuBarDisplayMode = AppSettings.defaultValue.menuBarDisplayMode
    @State private var selectedPopoverDisplayMode: PopoverDisplayMode = AppSettings.defaultValue.popoverDisplayMode
    @State private var authMessage: String?
    @State private var generalSettingsMessage: String?
    @State private var startupMessage: String?

    private let diagnosticsPresenter = DiagnosticsPresenter()
    private let githubURL = URL(string: "https://github.com/Mark-in-Motion/Codence")!
    private let uninstallURL = URL(string: "https://github.com/Mark-in-Motion/Codence#uninstall")!

    var body: some View {
        NavigationSplitView {
            List(SettingsPane.allCases, selection: $selectedPane) { pane in
                Label(pane.title, systemImage: pane.symbolName)
                    .font(.system(size: 15, weight: .medium))
                    .tag(pane)
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 190)
            .listStyle(.sidebar)
        } detail: {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    detailContent
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color(nsColor: .windowBackgroundColor))
        }
        .frame(minWidth: 760, minHeight: 520)
        .onAppear {
            syncDraftsFromSettings()
        }
        .onChange(of: selectedMenuBarDisplayMode) { newValue in
            guard newValue != appState.settings.menuBarDisplayMode else {
                return
            }

            saveDisplaySettings(menuBarDisplayMode: newValue)
        }
        .onChange(of: selectedPopoverDisplayMode) { newValue in
            guard newValue != appState.settings.popoverDisplayMode else {
                return
            }

            saveDisplaySettings(popoverDisplayMode: newValue)
        }
        .onChange(of: selectedLaunchAtLoginEnabled) { newValue in
            guard newValue != appState.settings.launchAtLoginEnabled else {
                return
            }

            saveStartupSettings(launchAtLoginEnabled: newValue)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(activePane.title)
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)

            Text(activePane.subtitle)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.primary.opacity(0.72))
        }
    }

    @ViewBuilder
    private var detailContent: some View {
        switch activePane {
        case .general:
            generalPane
        case .display:
            displayPane
        case .usage:
            usagePane
        case .diagnostics:
            diagnosticsPane
        case .about:
            aboutPane
        }
    }

    private var generalPane: some View {
        VStack(alignment: .leading, spacing: 18) {
            settingsCard("Codex Connection") {
                settingsStack {
                    settingsTextRow(
                        title: "Executable",
                        value: container.appServer?.detectedExecutable()?.path ?? "Not found"
                    )
                    settingsTextRow(
                        title: "Authentication",
                        value: authStatusSummary
                    )

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Custom executable path")
                            .font(.system(size: 15, weight: .semibold))

                        TextField("Automatic detection", text: $executablePathDraft)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 15, weight: .medium))
                    }

                    Text("Codence talks to the installed Codex app server. It never reads or stores your OpenAI tokens.")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.secondary)

                    HStack(spacing: 12) {
                        if appState.authState == .valid {
                            Label("Connected to ChatGPT", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        } else if appState.authState == .invalid || appState.authState == .expired {
                            Button("Sign in with ChatGPT") {
                                signInAction()
                            }
                            .disabled(appState.isSigningIn || appState.isCodexAvailable == false)
                        } else if appState.isCodexAvailable {
                            Button("Check Connection") {
                                refreshAction()
                            }
                        }

                        Button("Choose Executable…") {
                            chooseExecutable()
                        }

                        if let message = appState.signInMessage ?? authMessage {
                            Text(message)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            settingsCard("Refresh") {
                settingsStack {
                    settingsPickerRow("Refresh interval", selection: $selectedRefreshInterval) {
                        Text("1 minute").tag(TimeInterval(60))
                        Text("5 minutes").tag(TimeInterval(300))
                        Text("10 minutes").tag(TimeInterval(600))
                    }

                    HStack(spacing: 12) {
                        Button("Save Settings") {
                            saveSettings()
                        }

                        if let generalSettingsMessage {
                            Text(generalSettingsMessage)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            settingsCard("Startup") {
                settingsStack {
                    Toggle(isOn: $selectedLaunchAtLoginEnabled) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Launch at login")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(.primary)

                            Text("Open Codence automatically when you sign in to macOS.")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .toggleStyle(.switch)

                    if let startupMessage {
                        Text(startupMessage)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var displayPane: some View {
        VStack(alignment: .leading, spacing: 18) {
            settingsCard("Menu Bar") {
                settingsStack {
                    settingsPickerRow("Menu bar mode", selection: $selectedMenuBarDisplayMode) {
                        ForEach(MenuBarDisplayMode.allCases, id: \.self) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }

                    Text("Menu-bar quota percentages show remaining allowance, matching the Codex usage site.")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }

            settingsCard("Popover") {
                settingsStack {
                    settingsPickerRow("Popover mode", selection: $selectedPopoverDisplayMode) {
                        ForEach(PopoverDisplayMode.allCases, id: \.self) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }

                    Text("Compact keeps essentials only. Expanded keeps the fuller summary.")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var usagePane: some View {
        VStack(alignment: .leading, spacing: 18) {
            settingsCard("How Codence Reads Usage") {
                settingsStack {
                    Text("Codence shows remaining allowance like the Codex usage site. The app server reports used percentage, which Codence converts only for display.")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.primary)

                    Text("Additional server-defined quota buckets appear automatically. Authentication and token refresh remain owned by Codex.")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.primary)

                    Text("Pace and forecast messages use the longest reported window of at least one day.")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }

            settingsCard("Account Activity") {
                settingsStack {
                    settingsTextRow(title: "Plan", value: appState.currentSnapshot?.planType?.capitalized ?? appState.accountActivity?.planType?.capitalized ?? "Unavailable")
                    settingsTextRow(title: "Credit balance", value: appState.currentSnapshot?.creditBalance ?? "Unavailable")
                    settingsTextRow(title: "Reset credits", value: appState.currentSnapshot?.resetCreditCount.map(String.init) ?? "Unavailable")
                    settingsTextRow(title: "Lifetime tokens", value: appState.accountActivity?.lifetimeTokens?.formatted() ?? "Unavailable")
                    settingsTextRow(title: "Peak daily tokens", value: appState.accountActivity?.peakDailyTokens?.formatted() ?? "Unavailable")
                    settingsTextRow(title: "Current streak", value: appState.accountActivity?.currentStreakDays.map { "\($0) days" } ?? "Unavailable")
                    settingsTextRow(title: "Longest streak", value: appState.accountActivity?.longestStreakDays.map { "\($0) days" } ?? "Unavailable")
                }
            }

            settingsCard("History") {
                settingsStack {
                    settingsTextRow(
                        title: "Saved snapshots",
                        value: "\(appState.usageHistory.count)"
                    )
                    settingsTextRow(
                        title: "Latest snapshot",
                        value: appState.usageHistory.last.map { formattedTimestamp($0.recordedAt) } ?? "Not yet"
                    )
                    settingsTextRow(
                        title: "Weekly trend",
                        value: weeklyTrendSummary
                    )
                }
            }

            settingsCard("Recent Snapshots") {
                settingsStack {
                    if recentUsageHistory.isEmpty {
                        Text("History will appear here after a live refresh.")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(recentUsageHistory.indices, id: \.self) { index in
                            let entry = recentUsageHistory[index]
                            HStack(alignment: .firstTextBaseline, spacing: 16) {
                                Text(formattedTimestamp(entry.recordedAt))
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(.secondary)
                                    .frame(width: 170, alignment: .leading)

                                Text("Short \(roundedPercent(entry.snapshot.sessionRemainingPercent)) remaining • Long \(roundedPercent(entry.snapshot.weeklyRemainingPercent)) remaining")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(.primary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                }
            }

            settingsCard("Current Behavior") {
                settingsStack {
                    settingsTextRow(
                        title: "Menu bar label",
                        value: appState.settings.menuBarDisplayMode.title
                    )
                    settingsTextRow(
                        title: "Popover layout",
                        value: appState.settings.popoverDisplayMode.title
                    )
                    settingsTextRow(
                        title: "Helper hints",
                        value: "Shown in popover"
                    )
                }
            }
        }
    }

    private var diagnosticsPane: some View {
        VStack(alignment: .leading, spacing: 18) {
            if let snapshot = appState.currentSnapshot {
                settingsCard("Current Session") {
                    settingsStack {
                        settingsTextRow(title: "Status", value: snapshotStatusLabel(for: snapshot))
                        settingsTextRow(title: "Ends in", value: snapshotEndsInLabel(for: snapshot))
                        settingsTextRow(title: "Last updated", value: snapshotLastUpdatedLabel(for: snapshot))
                        settingsTextRow(title: "Data", value: snapshotDataSourceLabel(for: snapshot))
                    }
                }
            }

            settingsCard("Refresh Status") {
                settingsStack {
                    settingsTextRow(
                        title: "Status",
                        value: diagnosticsPresenter.statusLine(from: appState.diagnostics)
                    )

                    if let detail = diagnosticsPresenter.detailLine(from: appState.diagnostics) {
                        Text(detail)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            settingsCard("Sync Timeline") {
                settingsStack {
                    settingsTextRow(
                        title: "Last successful sync",
                        value: appState.diagnostics.lastSuccessfulFetchAt.map(formattedTimestamp) ?? "Not available"
                    )
                    settingsTextRow(
                        title: "Last failed sync",
                        value: appState.diagnostics.lastFailedFetchAt.map(formattedTimestamp) ?? "Not available"
                    )
                    settingsTextRow(
                        title: "Retry count",
                        value: "\(appState.diagnostics.retryCount)"
                    )
                }
            }

            settingsCard("Tools") {
                settingsStack {
                    Button("Open Full Diagnostics") {
                        presentWindow(id: "diagnostics")
                    }
                }
            }
        }
    }

    private var aboutPane: some View {
        VStack {
            Spacer(minLength: 0)

            VStack(alignment: .center, spacing: 14) {
                CodenceMarkIcon(style: .about)
                    .frame(width: 86, height: 68)

                Text("Codence")
                    .font(.system(size: 24, weight: .semibold, design: .rounded))

                Text("Codex usage monitor and pacing assistant")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Divider()
                    .frame(maxWidth: 240)

                VStack(spacing: 8) {
                    Text("Author: Mark")
                        .font(.system(size: 15, weight: .medium))
                    Button("GitHub") {
                        openURL(githubURL)
                    }
                    Link("Uninstall Codence", destination: uninstallURL)
                        .font(.system(size: 13))
                        .accessibilityHint("Opens uninstall instructions in the GitHub README")
                    Text("Version \(appVersion)")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: 360)
    }

    private func settingsCard<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.primary)

            content()
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }

    private func settingsStack<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            content()
        }
    }

    private func settingsTextRow(title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 16) {
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 160, alignment: .leading)

            Text(value)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func settingsPickerRow<SelectionValue: Hashable, Content: View>(
        _ title: String,
        selection: Binding<SelectionValue>,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(alignment: .center, spacing: 16) {
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 160, alignment: .leading)

            Picker(title, selection: selection) {
                content()
            }
            .labelsHidden()
            .frame(maxWidth: 220, alignment: .leading)
        }
    }

    private func settingsBullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Circle()
                .fill(Color.accentColor.opacity(0.85))
                .frame(width: 6, height: 6)
                .padding(.top, 6)

            Text(text)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.secondary)
        }
    }

    private var activePane: SettingsPane {
        selectedPane ?? .general
    }

    private var authStatusSummary: String {
        if let error = appState.diagnostics.lastError {
            switch error.kind {
            case .codexProcessFailed:
                return "Codex app server unavailable"
            case .codexIncompatible:
                return "Update Codex CLI"
            default:
                break
            }
        }
        switch appState.authState {
        case .unknown:
            return appState.isCodexAvailable ? "Checking Codex account" : "Codex not found"
        case .valid:
            return "Connected to ChatGPT"
        case .expired:
            return "Expired"
        case .invalid:
            return "Sign in required"
        }
    }

    private var recentUsageHistory: [UsageHistoryEntry] {
        Array(appState.usageHistory.suffix(8).reversed())
    }

    private var weeklyTrendSummary: String {
        guard let latest = appState.usageHistory.last else {
            return "Not enough history yet"
        }

        let comparisonPool = appState.usageHistory.filter {
            latest.recordedAt.timeIntervalSince($0.recordedAt) >= 6 * 60 * 60
        }

        guard let baseline = comparisonPool.last ?? appState.usageHistory.dropLast().last else {
            return "Not enough history yet"
        }

        let delta = latest.snapshot.weeklyRemainingPercent - baseline.snapshot.weeklyRemainingPercent
        let rounded = Int(abs(delta).rounded())

        if rounded == 0 {
            return "Remaining unchanged"
        }

        return delta > 0 ? "Up \(rounded)% remaining since earlier" : "Down \(rounded)% remaining since earlier"
    }

    private var appVersion: String {
        let shortVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(shortVersion) (\(build))"
    }

    private func syncDraftsFromSettings() {
        selectedRefreshInterval = appState.settings.refreshInterval
        selectedLaunchAtLoginEnabled = currentLaunchAtLoginEnabled()
        selectedMenuBarDisplayMode = appState.settings.menuBarDisplayMode
        selectedPopoverDisplayMode = appState.settings.popoverDisplayMode
        executablePathDraft = appState.settings.codexExecutablePath ?? ""
    }

    private func chooseExecutable() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = false
        panel.message = "Choose the Codex executable"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        executablePathDraft = url.path
        saveSettings()
    }

    private func saveSettings() {
        let settings = AppSettings(
            refreshInterval: selectedRefreshInterval,
            launchAtLoginEnabled: selectedLaunchAtLoginEnabled,
            menuBarDisplayMode: selectedMenuBarDisplayMode,
            popoverDisplayMode: selectedPopoverDisplayMode,
            codexExecutablePath: executablePathDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? nil : executablePathDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        do {
            try container.settingsRepository?.saveSettings(settings)
            appState.applySettings(settings)
            generalSettingsMessage = "Settings saved."
            scheduleRefreshAction()
        } catch {
            generalSettingsMessage = "Failed to save settings."
        }
    }

    private func saveDisplaySettings(
        menuBarDisplayMode: MenuBarDisplayMode? = nil,
        popoverDisplayMode: PopoverDisplayMode? = nil
    ) {
        let settings = AppSettings(
            refreshInterval: appState.settings.refreshInterval,
            launchAtLoginEnabled: appState.settings.launchAtLoginEnabled,
            menuBarDisplayMode: menuBarDisplayMode ?? appState.settings.menuBarDisplayMode,
            popoverDisplayMode: popoverDisplayMode ?? appState.settings.popoverDisplayMode,
            codexExecutablePath: appState.settings.codexExecutablePath
        )

        do {
            try container.settingsRepository?.saveSettings(settings)
            appState.applySettings(settings)
        } catch {
            selectedMenuBarDisplayMode = appState.settings.menuBarDisplayMode
            selectedPopoverDisplayMode = appState.settings.popoverDisplayMode
        }
    }

    private func saveStartupSettings(launchAtLoginEnabled: Bool) {
        do {
            try container.launchAtLoginController?.setEnabled(launchAtLoginEnabled)

            let settings = AppSettings(
                refreshInterval: appState.settings.refreshInterval,
                launchAtLoginEnabled: launchAtLoginEnabled,
                menuBarDisplayMode: appState.settings.menuBarDisplayMode,
                popoverDisplayMode: appState.settings.popoverDisplayMode,
                codexExecutablePath: appState.settings.codexExecutablePath
            )

            try container.settingsRepository?.saveSettings(settings)
            appState.applySettings(settings)
            startupMessage = launchAtLoginEnabled ? "Codence will now open at login." : "Codence will stay off at login."
        } catch {
            selectedLaunchAtLoginEnabled = appState.settings.launchAtLoginEnabled
            startupMessage = "Could not update Launch at Login. Open Codence from Applications and try again."
        }
    }

    private func currentLaunchAtLoginEnabled() -> Bool {
        container.launchAtLoginController?.currentStatus() ?? appState.settings.launchAtLoginEnabled
    }

    private func formattedTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func roundedPercent(_ value: Double) -> String {
        "\(Int(value.rounded()))%"
    }

    private func snapshotStatusLabel(for snapshot: UsageSnapshot) -> String {
        snapshot.sessionUsagePercent > 0 ? "Active" : "Idle"
    }

    private func snapshotEndsInLabel(for snapshot: UsageSnapshot) -> String {
        guard let resetDate = snapshot.sessionResetsAt, resetDate > Date() else {
            return snapshot.sessionResetsAt != nil ? "Reset now" : "Starts on first use"
        }
        let remaining = resetDate.timeIntervalSince(Date())
        let hours = Int(remaining) / 3_600
        let minutes = (Int(remaining) % 3_600) / 60
        if hours > 0 {
            return minutes > 0 ? "\(hours)h \(minutes)m left" : "\(hours)h left"
        }
        return "\(max(minutes, 1))m left"
    }

    private func snapshotLastUpdatedLabel(for snapshot: UsageSnapshot) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: snapshot.displayedAt, relativeTo: Date())
    }

    private func snapshotDataSourceLabel(for snapshot: UsageSnapshot) -> String {
        switch snapshot.source {
        case .liveFetch:
            return "Live"
        case .startupCache, .recoveredCache, .historyReplay:
            return "Saved"
        }
    }

    private func presentWindow(id: String) {
        NSApplication.shared.activate(ignoringOtherApps: true)
        openWindow(id: id)

        DispatchQueue.main.async {
            NSApplication.shared.activate(ignoringOtherApps: true)
            let window = NSApplication.shared.windows.first { $0.identifier?.rawValue == id }
            window?.makeKeyAndOrderFront(nil)
        }
    }
}

private enum SettingsPane: String, CaseIterable, Hashable, Identifiable {
    case general
    case display
    case usage
    case diagnostics
    case about

    var id: Self { self }

    var title: String {
        switch self {
        case .general:
            return "General"
        case .display:
            return "Display"
        case .usage:
            return "Usage"
        case .diagnostics:
            return "Diagnostics"
        case .about:
            return "About"
        }
    }

    var subtitle: String {
        switch self {
        case .general:
            return "Connection and refresh behavior."
        case .display:
            return "Menu bar and popover presentation."
        case .usage:
            return "How Codence interprets Codex limits."
        case .diagnostics:
            return "Refresh health and sync history."
        case .about:
            return "App details and project links."
        }
    }

    var symbolName: String {
        switch self {
        case .general:
            return "gearshape"
        case .display:
            return "rectangle.on.rectangle"
        case .usage:
            return "chart.bar"
        case .diagnostics:
            return "wrench.and.screwdriver"
        case .about:
            return "info.circle"
        }
    }
}
