import AppKit
import SwiftUI

/// SwiftUI entry point for the Codence menu-bar app.
@main
struct CodenceApp: App {
    @StateObject private var appState: AppState

    private let bootstrap: AppBootstrap

    init() {
        let appState = AppState()
        let container = DependencyContainer()
        let syncCoordinator = SyncCoordinator(container: container)
        let bootstrap = AppBootstrap(container: container, syncCoordinator: syncCoordinator)
        self.bootstrap = bootstrap
        NSApplication.shared.setActivationPolicy(.accessory)
        _appState = StateObject(wrappedValue: appState)

        Task { @MainActor in
            await bootstrap.start(appState: appState)
        }
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarRootView(appState: appState) {
                bootstrap.refreshNow()
            } signInAction: {
                bootstrap.signInWithChatGPT()
            }
        } label: {
            MenuBarLabelView(appState: appState)
        }
        .menuBarExtraStyle(.window)

        Window("Settings", id: "settings") {
            SettingsView(
                appState: appState,
                container: bootstrap.container,
                refreshAction: {
                    bootstrap.refreshNow()
                },
                scheduleRefreshAction: {
                    bootstrap.refreshScheduleDidChange()
                },
                signInAction: {
                    bootstrap.signInWithChatGPT()
                }
            )
        }

        Window("Diagnostics", id: "diagnostics") {
            DiagnosticsView(diagnostics: appState.diagnostics)
        }
    }
}

private struct MenuBarLabelView: View {
    @ObservedObject var appState: AppState

    var body: some View {
        HStack(spacing: 5) {
            CodenceMarkIcon(style: .menuBar)
                .frame(width: 16, height: 16)

            if let label = appState.menuBarDisplayText {
                Text(label)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .lineLimit(1)
                    .frame(minWidth: minimumWidth(for: appState.settings.menuBarDisplayMode), alignment: .trailing)
            }
        }
    }

    private func minimumWidth(for mode: MenuBarDisplayMode) -> CGFloat {
        switch mode {
        case .iconOnly:
            return 0
        case .weeklyPercent, .sessionPercent:
            return 72
        case .compactBoth:
            return 114
        case .paceStatus:
            return 44
        }
    }
}
