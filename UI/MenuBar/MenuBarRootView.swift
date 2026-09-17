import AppKit
import SwiftUI

/// Main menu bar surface for usage, pace, trust, and recovery guidance.
struct MenuBarRootView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openWindow) private var openWindow
    @ObservedObject var appState: AppState
    let refreshAction: () -> Void
    let signInAction: () -> Void

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            VStack(alignment: .leading, spacing: 16) {
                headerSection

                if appState.requiresSetup {
                    setupSection
                } else if let snapshot = appState.currentSnapshot {
                    if let paceMetrics = appState.paceMetrics {
                        summaryStrip(snapshot: snapshot, paceMetrics: paceMetrics)
                    }

                    usageSection(snapshot: snapshot, paceMetrics: appState.paceMetrics, now: context.date)
                } else {
                    emptyStateSection
                }

                Divider()
                    .overlay(Color.white.opacity(0.08))

                actionsSection
            }
        }
        .padding(18)
        .frame(width: isCompact ? 368 : 420)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(nsColor: .windowBackgroundColor))
        )
    }

    private var isCompact: Bool {
        appState.settings.popoverDisplayMode == .compact
    }

    private var setupSection: some View {
        SetupView(
            authState: appState.authState,
            isCodexAvailable: appState.isCodexAvailable,
            isSigningIn: appState.isSigningIn,
            message: appState.signInMessage,
            signInAction: signInAction,
            openSettingsAction: { presentWindow(id: "settings") }
        )
    }

    private var headerSection: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Codence")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
            }

            Spacer()

            Label(appState.statusLabel, systemImage: statusSymbol)
                .font(.system(size: 15, weight: .semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(statusTint.opacity(0.18), in: Capsule())
                .foregroundColor(statusTint)
        }
    }

    private func summaryStrip(snapshot: UsageSnapshot, paceMetrics: PaceMetrics) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                paceBadge(for: paceMetrics)

                Text(summaryLine(snapshot: snapshot))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary.opacity(0.92))

                Spacer(minLength: 0)
            }

            Text(paceSummary(for: paceMetrics))
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.primary.opacity(0.72))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(summaryBackground(for: paceMetrics))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(weeklyTint(for: paceMetrics).opacity(0.14), lineWidth: 1)
        )
    }

    private func usageSection(snapshot: UsageSnapshot, paceMetrics: PaceMetrics?, now: Date) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                quotaCard(
                    title: snapshot.sessionLimitTitle,
                    remainingPercent: snapshot.sessionRemainingPercent,
                    resetsAt: snapshot.sessionResetsAt,
                    now: now,
                    missingResetLabel: "Starts on use"
                )
                quotaCard(
                    title: snapshot.weeklyLimitTitle,
                    remainingPercent: snapshot.weeklyRemainingPercent,
                    resetsAt: snapshot.weeklyResetsAt,
                    now: now,
                    missingResetLabel: "Not available"
                )
            }

            if snapshot.modelWeeklyLimits.isEmpty == false {
                ForEach(snapshot.modelWeeklyLimits, id: \.displayName) { limit in
                    modelLimitRow(limit, now: now)
                }

                Text("Additional Codex quota windows")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary.opacity(0.62))
            }

            if isCompact == false, let paceMetrics {
                expandedDetailsSection(snapshot: snapshot, paceMetrics: paceMetrics)
            }
        }
    }

    private func quotaCard(
        title: String,
        remainingPercent: Double,
        resetsAt: Date?,
        now: Date,
        missingResetLabel: String
    ) -> some View {
        usageCardContainer {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.primary.opacity(0.92))

            Text(formatPercent(remainingPercent))
                .font(.system(size: 30, weight: .semibold, design: .rounded))
                .foregroundColor(remainingTint(for: remainingPercent))

            Text("remaining")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.primary.opacity(0.72))
                .lineLimit(1)

            progressBar(percentage: remainingPercent, tint: remainingTint(for: remainingPercent))

            Spacer(minLength: 0)

            resetFooter(resetsAt: resetsAt, now: now, missingResetLabel: missingResetLabel)
        }
    }

    private func resetFooter(resetsAt: Date?, now: Date, missingResetLabel: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Until reset")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.primary.opacity(0.58))

            Text(resetsAt.map { ResetCountdown.label(until: $0, now: now) } ?? missingResetLabel)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary.opacity(0.88))
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity, minHeight: 38, alignment: .topLeading)
        .help(resetsAt.map { resetScheduleLabel(for: $0) } ?? missingResetLabel)
    }

    private func modelLimitRow(_ limit: ModelWeeklyLimit, now: Date) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(modelLimitTitle(for: limit))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary.opacity(0.92))
                Spacer()
                Text("\(formatPercent(limit.remainingPercent)) remaining")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(remainingTint(for: limit.remainingPercent))
            }
            progressBar(percentage: limit.remainingPercent, tint: remainingTint(for: limit.remainingPercent))

            if let resetsAt = limit.resetsAt {
                Text("Reset: \(ResetCountdown.label(until: resetsAt, now: now))")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary.opacity(0.82))
                    .help(resetScheduleLabel(for: resetsAt))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.075))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }

    private func modelLimitTitle(for limit: ModelWeeklyLimit) -> String {
        limit.displayName
    }

    private func expandedDetailsSection(snapshot: UsageSnapshot, paceMetrics: PaceMetrics) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Divider()
                .overlay(Color.white.opacity(0.08))

            detailSection("Codence pace estimate") {
                detailRow("Used this week", value: formatPercent(snapshot.weeklyUsagePercent))
                detailRow("Even pace now", value: formatPercent(paceMetrics.weeklyTargetByNow))
            }
        }
    }

    private var emptyStateSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Usage")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.primary.opacity(0.82))

            Text(appState.statusText)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.primary.opacity(0.88))
        }
    }

    private var actionsSection: some View {
        VStack(spacing: 8) {
            primaryActionButton("Refresh", systemImage: "arrow.clockwise", tint: .blue) {
                refreshAction()
            }

            HStack(spacing: 10) {
                tertiaryActionButton("Settings", systemImage: "gearshape", foreground: .secondary, alignment: .leading) {
                    presentWindow(id: "settings")
                }

                tertiaryActionButton("Quit", systemImage: "xmark.circle", foreground: .red, alignment: .trailing) {
                    NSApplication.shared.terminate(nil)
                }
            }
        }
    }

    private func usageCardContainer<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            content()
        }
        .frame(maxWidth: .infinity, minHeight: 188, alignment: .topLeading)
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.075))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }

    private func progressBar(percentage: Double, tint: Color) -> some View {
        Gauge(value: percentage, in: 0 ... 100) {
            EmptyView()
        }
        .gaugeStyle(.accessoryLinearCapacity)
        .tint(tint)
    }

    private func primaryActionButton(
        _ title: String,
        systemImage: String,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(tint)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(tint.opacity(0.14))
                )
                .labelStyle(.titleAndIcon)
        }
        .buttonStyle(.plain)
    }

    private func tertiaryActionButton(
        _ title: String,
        systemImage: String,
        foreground: Color = .secondary,
        alignment: Alignment,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if alignment == .leading {
                    Image(systemName: systemImage)
                    Text(title)
                    Spacer(minLength: 0)
                } else {
                    Spacer(minLength: 0)
                    Image(systemName: systemImage)
                    Text(title)
                }
            }
            .font(.system(size: 15, weight: .medium))
            .foregroundColor(foreground)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: alignment)
        .padding(.vertical, 2)
    }

    private func presentWindow(id: String) {
        dismiss()

        DispatchQueue.main.async {
            NSApplication.shared.activate(ignoringOtherApps: true)
            openWindow(id: id)

            DispatchQueue.main.async {
                NSApplication.shared.activate(ignoringOtherApps: true)
                let window = NSApplication.shared.windows.first { $0.identifier?.rawValue == id }
                window?.makeKeyAndOrderFront(nil)
            }
        }
    }

    private var shouldShowStatusDetail: Bool {
        switch appState.syncStatus {
        case .live:
            return false
        default:
            return appState.statusText != appState.statusLabel
        }
    }

    private var statusTint: Color {
        if appState.requiresSetup {
            return .orange
        }

        switch appState.syncStatus {
        case .live:
            return Color(red: 0.16, green: 0.62, blue: 0.37)
        case .retrying:
            return .orange
        case .error:
            return Color(red: 0.85, green: 0.24, blue: 0.20)
        case .loading, .stale:
            return Color(nsColor: .secondaryLabelColor)
        }
    }

    private var statusSymbol: String {
        if appState.requiresSetup {
            return "exclamationmark.triangle.fill"
        }

        switch appState.syncStatus {
        case .live:
            return "checkmark.circle.fill"
        case .retrying:
            return "arrow.clockwise.circle.fill"
        case .error:
            return "xmark.octagon.fill"
        case .loading, .stale:
            return "clock.fill"
        }
    }

    private func summaryLine(snapshot: UsageSnapshot) -> String {
        let weekly = formatPercent(snapshot.weeklyRemainingPercent)
        return "\(weekly) left this week"
    }

    private func paceBadge(for paceMetrics: PaceMetrics) -> some View {
        Text(paceLabel(for: paceMetrics.riskLevel))
            .font(.system(size: 15, weight: .semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(weeklyTint(for: paceMetrics).opacity(0.16), in: Capsule())
            .foregroundColor(weeklyTint(for: paceMetrics))
    }

    private func paceLabel(for riskLevel: PaceRiskLevel) -> String {
        switch riskLevel {
        case .underuseRisk:
            return "Using slowly"
        case .onTrack:
            return "On track"
        case .exhaustionRisk:
            return "Using fast"
        }
    }

    private func weeklyTint(for paceMetrics: PaceMetrics?) -> Color {
        guard let paceMetrics else {
            return .primary
        }

        switch paceMetrics.riskLevel {
        case .underuseRisk:
            return Color(red: 0.15, green: 0.45, blue: 0.82)
        case .onTrack:
            return Color(red: 0.16, green: 0.62, blue: 0.37)
        case .exhaustionRisk:
            return Color(red: 0.78, green: 0.30, blue: 0.24)
        }
    }

    private func remainingTint(for percentage: Double) -> Color {
        switch percentage {
        case ..<40:
            return Color(red: 0.85, green: 0.24, blue: 0.20)
        case ..<60:
            return Color(red: 0.88, green: 0.54, blue: 0.12)
        default:
            return Color(red: 0.16, green: 0.62, blue: 0.37)
        }
    }

    private func summaryBackground(for paceMetrics: PaceMetrics) -> Color {
        weeklyTint(for: paceMetrics).opacity(0.075)
    }

    private func paceSummary(for paceMetrics: PaceMetrics) -> String {
        switch paceMetrics.riskLevel {
        case .underuseRisk:
            return "You have room to use more before reset."
        case .onTrack:
            return "Your weekly usage is on track."
        case .exhaustionRisk:
            return "At this pace, you may run out before reset."
        }
    }

    private func detailSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.primary.opacity(0.62))

            VStack(alignment: .leading, spacing: 4) {
                content()
            }
        }
    }

    private func detailRow(_ title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text("\(title):")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.primary.opacity(0.68))
                .frame(width: 128, alignment: .leading)

            Text(value)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.primary.opacity(0.88))
                .lineLimit(1)
        }
    }

    private var dynamicHelperHintColor: Color {
        guard let paceMetrics = appState.paceMetrics else {
            return .primary.opacity(0.72)
        }

        switch paceMetrics.riskLevel {
        case .underuseRisk:
            return Color(red: 0.15, green: 0.45, blue: 0.82)
        case .onTrack:
            return .primary.opacity(0.72)
        case .exhaustionRisk:
            return Color(red: 0.70, green: 0.34, blue: 0.14)
        }
    }

    private func formatPercent(_ value: Double) -> String {
        "\(Int(value.rounded()))%"
    }

    private func resetScheduleLabel(for resetDate: Date) -> String {
        "Resets \(formattedResetSchedule(resetDate))"
    }

    private func formattedResetSchedule(_ resetDate: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: resetDate)
    }
}

enum ResetCountdown {
    static func label(until resetDate: Date, now: Date) -> String {
        let seconds = resetDate.timeIntervalSince(now)
        guard seconds > 0 else { return "Reset due now" }

        if seconds >= 86_400 {
            let days = Int(seconds / 86_400)
            return "\(days) \(days == 1 ? "day" : "days") left"
        }

        let minutes = max(Int(ceil(seconds / 60)), 1)
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        if hours > 0 {
            return remainingMinutes == 0 ? "\(hours)h left" : "\(hours)h \(remainingMinutes)m left"
        }

        return "\(minutes)m left"
    }
}
