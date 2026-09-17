import Foundation
import ServiceManagement

protocol LaunchAtLoginControlling {
    func currentStatus() -> Bool
    func setEnabled(_ isEnabled: Bool) throws
}

enum LaunchAtLoginError: LocalizedError {
    case unsupported

    var errorDescription: String? {
        switch self {
        case .unsupported:
            return "Launch at Login is only available from a bundled app."
        }
    }
}

final class DefaultLaunchAtLoginController: LaunchAtLoginControlling {
    func currentStatus() -> Bool {
        guard supportsLaunchAtLogin else {
            return false
        }

        return SMAppService.mainApp.status == .enabled
    }

    func setEnabled(_ isEnabled: Bool) throws {
        guard supportsLaunchAtLogin else {
            throw LaunchAtLoginError.unsupported
        }

        if isEnabled {
            try SMAppService.mainApp.register()
        } else {
            try SMAppService.mainApp.unregister()
        }
    }

    private var supportsLaunchAtLogin: Bool {
        Bundle.main.bundleIdentifier?.isEmpty == false
    }
}
