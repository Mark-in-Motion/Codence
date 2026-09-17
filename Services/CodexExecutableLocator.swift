import Foundation

struct CodexExecutableLocator: @unchecked Sendable {
    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func locate(overridePath: String? = nil) -> URL? {
        if let overridePath, let url = validated(path: overridePath) {
            return url
        }

        let pathCandidates = (ProcessInfo.processInfo.environment["PATH"] ?? "")
            .split(separator: ":")
            .map { String($0) + "/codex" }
        let home = fileManager.homeDirectoryForCurrentUser.path
        let fixedCandidates = [
            "/opt/homebrew/bin/codex",
            "/usr/local/bin/codex",
            home + "/.local/bin/codex"
        ]
        for path in pathCandidates + fixedCandidates {
            if let url = validated(path: path) { return url }
        }

        let nvmRoot = fileManager.homeDirectoryForCurrentUser.appendingPathComponent(".nvm/versions/node")
        if let versions = try? fileManager.contentsOfDirectory(
            at: nvmRoot,
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles
        ) {
            for version in versions.sorted(by: { $0.lastPathComponent > $1.lastPathComponent }) {
                if let url = validated(path: version.appendingPathComponent("bin/codex").path) {
                    return url
                }
            }
        }
        return nil
    }

    private func validated(path: String) -> URL? {
        let expanded = NSString(string: path).expandingTildeInPath
        guard fileManager.isExecutableFile(atPath: expanded) else { return nil }
        return URL(fileURLWithPath: expanded)
    }
}
