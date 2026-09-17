import SwiftUI

struct SetupView: View {
    @Environment(\.openURL) private var openURL

    let authState: AuthState
    let isCodexAvailable: Bool
    let isSigningIn: Bool
    let message: String?
    let signInAction: () -> Void
    let openSettingsAction: () -> Void

    private let installURL = URL(string: "https://developers.openai.com/codex/cli")!

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(isCodexAvailable ? "Connect ChatGPT" : "Codex is required")
                .font(.system(size: 17, weight: .semibold))

            Text(isCodexAvailable
                 ? "Codence uses Codex’s own sign-in and never reads or copies your tokens."
                 : "Install Codex CLI, or choose its executable in Settings, before refreshing usage.")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.primary.opacity(0.82))

            if let message {
                Text(message)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 10) {
                Button(isCodexAvailable ? "Sign in with ChatGPT" : "Install Codex") {
                    if isCodexAvailable { signInAction() } else { openURL(installURL) }
                }
                .buttonStyle(.plain)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(Color.blue.opacity(0.16), in: RoundedRectangle(cornerRadius: 10))
                .disabled(isSigningIn)

                Button("Settings", action: openSettingsAction)
                    .buttonStyle(.plain)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary.opacity(0.84))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.white.opacity(0.09), in: RoundedRectangle(cornerRadius: 14))
    }
}
