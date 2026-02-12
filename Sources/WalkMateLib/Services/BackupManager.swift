import Foundation

final class BackupManager {
    static let shared = BackupManager()

    private let maxBackups = 7
    private let fileManager = FileManager.default
    private var backupTimer: Timer?

    private var backupsDir: URL {
        let appSupport = fileManager.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first!
        return appSupport
            .appendingPathComponent("WalkMate", isDirectory: true)
            .appendingPathComponent("backups", isDirectory: true)
    }

    private init() {}

    /// Start the daily backup scheduler. Call once on app launch.
    func configure() {
        scheduleNextBackup()
        // Also do an immediate backup if none today
        if !hasBackupToday() {
            performBackup()
        }
    }

    // MARK: - Scheduling

    private func scheduleNextBackup() {
        let calendar = Calendar.current
        var components = DateComponents()
        components.hour = 19
        components.minute = 0

        guard var nextFire = calendar.nextDate(
            after: Date(),
            matching: components,
            matchingPolicy: .nextTime
        ) else { return }

        // If 19:00 already passed today and we haven't backed up, fire soon
        if hasBackupToday() {
            // Schedule for tomorrow 19:00
            nextFire = calendar.date(byAdding: .day, value: 1, to: nextFire) ?? nextFire
        }

        let interval = nextFire.timeIntervalSinceNow
        guard interval > 0 else { return }

        DispatchQueue.main.async { [weak self] in
            self?.backupTimer?.invalidate()
            self?.backupTimer = Timer.scheduledTimer(
                withTimeInterval: interval,
                repeats: false
            ) { [weak self] _ in
                self?.performBackup()
                self?.scheduleNextBackup()
            }
        }

        #if DEBUG
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        print("[Backup] Następny backup zaplanowany na \(formatter.string(from: nextFire))")
        #endif
    }

    // MARK: - Backup

    func performBackup() {
        let storageDir = ProfileManager.shared.activeStorageDir

        // Create backups directory
        try? fileManager.createDirectory(at: backupsDir, withIntermediateDirectories: true)

        // Create timestamped backup folder
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        let backupName = "backup_\(formatter.string(from: Date()))"
        let backupDir = backupsDir.appendingPathComponent(backupName, isDirectory: true)

        do {
            try fileManager.createDirectory(at: backupDir, withIntermediateDirectories: true)

            // Copy all JSON files from storage
            let jsonFiles = ["workouts.json", "daily_goals.json", "achievements.json", "weight_entries.json"]
            for file in jsonFiles {
                let src = storageDir.appendingPathComponent(file)
                let dst = backupDir.appendingPathComponent(file)
                if fileManager.fileExists(atPath: src.path) {
                    try fileManager.copyItem(at: src, to: dst)
                }
            }

            // Also backup other profiles
            let profilesDir = storageDir.deletingLastPathComponent()
            if let profiles = try? fileManager.contentsOfDirectory(atPath: profilesDir.path) {
                for profile in profiles where profile != storageDir.lastPathComponent {
                    let profileSrc = profilesDir.appendingPathComponent(profile)
                    let profileDst = backupDir.appendingPathComponent(profile, isDirectory: true)
                    var isDir: ObjCBool = false
                    if fileManager.fileExists(atPath: profileSrc.path, isDirectory: &isDir), isDir.boolValue {
                        try fileManager.copyItem(at: profileSrc, to: profileDst)
                    }
                }
            }

            #if DEBUG
            print("[Backup] Backup utworzony: \(backupName)")
            #endif
        } catch {
            #if DEBUG
            print("[Backup] Błąd: \(error.localizedDescription)")
            #endif
        }

        // Cleanup old backups
        cleanupOldBackups()
    }

    // MARK: - Cleanup

    private func cleanupOldBackups() {
        guard let contents = try? fileManager.contentsOfDirectory(
            at: backupsDir,
            includingPropertiesForKeys: [.creationDateKey],
            options: .skipsHiddenFiles
        ) else { return }

        let sorted = contents
            .filter { $0.lastPathComponent.hasPrefix("backup_") }
            .sorted { a, b in
                let dateA = (try? a.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? .distantPast
                let dateB = (try? b.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? .distantPast
                return dateA > dateB // newest first
            }

        // Keep only maxBackups
        if sorted.count > maxBackups {
            for old in sorted.dropFirst(maxBackups) {
                try? fileManager.removeItem(at: old)
                #if DEBUG
                print("[Backup] Usunięto stary backup: \(old.lastPathComponent)")
                #endif
            }
        }
    }

    // MARK: - Helpers

    private func hasBackupToday() -> Bool {
        guard let contents = try? fileManager.contentsOfDirectory(atPath: backupsDir.path) else {
            return false
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let todayPrefix = "backup_\(formatter.string(from: Date()))"

        return contents.contains { $0.hasPrefix(todayPrefix) }
    }

    /// Number of existing backups
    var backupCount: Int {
        (try? fileManager.contentsOfDirectory(atPath: backupsDir.path))?
            .filter { $0.hasPrefix("backup_") }
            .count ?? 0
    }

    /// List available backups sorted newest first
    func availableBackups() -> [(name: String, date: Date, url: URL)] {
        guard let contents = try? fileManager.contentsOfDirectory(
            at: backupsDir,
            includingPropertiesForKeys: [.creationDateKey],
            options: .skipsHiddenFiles
        ) else { return [] }

        return contents
            .filter { $0.lastPathComponent.hasPrefix("backup_") }
            .compactMap { url -> (String, Date, URL)? in
                let date = (try? url.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? .distantPast
                return (url.lastPathComponent, date, url)
            }
            .sorted { $0.1 > $1.1 }
    }

    /// Restore a backup by copying its files into the active profile storage dir
    func restoreBackup(from backupURL: URL) -> Bool {
        let storageDir = ProfileManager.shared.activeStorageDir
        let jsonFiles = ["workouts.json", "daily_goals.json", "achievements.json", "weight_entries.json"]

        // First, make a safety backup of current state
        performBackup()

        do {
            for file in jsonFiles {
                let src = backupURL.appendingPathComponent(file)
                let dst = storageDir.appendingPathComponent(file)
                if fileManager.fileExists(atPath: src.path) {
                    if fileManager.fileExists(atPath: dst.path) {
                        try fileManager.removeItem(at: dst)
                    }
                    try fileManager.copyItem(at: src, to: dst)
                }
            }

            // Reload data
            DataStore.shared.reload(storageDir: storageDir)
            GoalsManager.shared.configure()
            AchievementManager.shared.configure()

            #if DEBUG
            print("[Backup] Przywrócono kopię: \(backupURL.lastPathComponent)")
            #endif
            return true
        } catch {
            #if DEBUG
            print("[Backup] Błąd przywracania: \(error.localizedDescription)")
            #endif
            return false
        }
    }

    /// Date of the latest backup
    var lastBackupDate: Date? {
        guard let contents = try? fileManager.contentsOfDirectory(
            at: backupsDir,
            includingPropertiesForKeys: [.creationDateKey],
            options: .skipsHiddenFiles
        ) else { return nil }

        return contents
            .filter { $0.lastPathComponent.hasPrefix("backup_") }
            .compactMap { try? $0.resourceValues(forKeys: [.creationDateKey]).creationDate }
            .max()
    }
}
