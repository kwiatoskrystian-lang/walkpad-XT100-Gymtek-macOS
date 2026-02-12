import Foundation

/// Manages Launch at Login via LaunchAgent plist.
/// Works with SPM-built .app bundles (no SMAppService needed).
final class LaunchAtLoginManager {
    static let shared = LaunchAtLoginManager()

    private let agentLabel = "com.walkmate.app.launcher"

    private var agentDir: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents", isDirectory: true)
    }

    private var agentPlistURL: URL {
        agentDir.appendingPathComponent("\(agentLabel).plist")
    }

    var isEnabled: Bool {
        FileManager.default.fileExists(atPath: agentPlistURL.path)
    }

    func setEnabled(_ enabled: Bool) {
        if enabled {
            install()
        } else {
            uninstall()
        }
    }

    private func install() {
        let appPath = Bundle.main.bundlePath

        // Fallback: if running as bare executable (not .app), skip
        guard appPath.hasSuffix(".app") else { return }

        let plist: [String: Any] = [
            "Label": agentLabel,
            "ProgramArguments": ["/usr/bin/open", "-a", appPath],
            "RunAtLoad": true,
            "KeepAlive": false,
        ]

        do {
            try FileManager.default.createDirectory(at: agentDir, withIntermediateDirectories: true)
            let data = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
            try data.write(to: agentPlistURL, options: .atomic)
        } catch {
            print("[LaunchAtLogin] Failed to install: \(error)")
        }
    }

    private func uninstall() {
        try? FileManager.default.removeItem(at: agentPlistURL)
    }

    private init() {}
}
