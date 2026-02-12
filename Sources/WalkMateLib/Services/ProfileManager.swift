import Foundation
import Observation

@Observable
final class ProfileManager {
    static let shared = ProfileManager()

    private(set) var profiles: [UserProfile] = []
    private(set) var activeProfile: UserProfile

    private let baseDir: URL
    private let profilesFileURL: URL

    private init() {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first!
        baseDir = appSupport.appendingPathComponent("WalkMate", isDirectory: true)
        profilesFileURL = baseDir.appendingPathComponent("profiles.json")

        // Temporary — will be overwritten below
        activeProfile = UserProfile(id: "default", displayName: "Krystian", petType: .mops)

        loadOrCreateProfiles()
        migrateRootFilesIfNeeded()
    }

    // MARK: - Public

    var activeStorageDir: URL {
        storageDirectory(for: activeProfile)
    }

    func storageDirectory(for profile: UserProfile) -> URL {
        let dir = baseDir
            .appendingPathComponent("profiles", isDirectory: true)
            .appendingPathComponent(profile.id, isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    func switchProfile(to profile: UserProfile) {
        guard profile.id != activeProfile.id else { return }
        activeProfile = profile

        let dir = activeStorageDir
        let prefix = profile.id

        DataStore.shared.reload(storageDir: dir)
        AppSettings.shared.reloadForProfile(prefix: prefix)
        GoalsManager.shared.reloadForProfile()
        AchievementManager.shared.configure()

        #if DEBUG
        print("[Profile] Switched to \(profile.displayName) (\(profile.id))")
        #endif
    }

    /// Called once at app launch to set up DataStore/AppSettings for the active profile.
    func configureActiveProfile() {
        let dir = activeStorageDir
        let prefix = activeProfile.id
        DataStore.shared.reload(storageDir: dir)
        AppSettings.shared.reloadForProfile(prefix: prefix)
    }

    // MARK: - Private

    private func loadOrCreateProfiles() {
        if let data = try? Data(contentsOf: profilesFileURL),
           let loaded = try? JSONDecoder().decode([UserProfile].self, from: data),
           !loaded.isEmpty {
            profiles = loaded
            activeProfile = loaded[0]
        } else {
            let defaultProfiles = [
                UserProfile(id: "default", displayName: "Krystian", petType: .mops),
                UserProfile(id: "natalia", displayName: "Natalia", petType: .raccoon),
            ]
            profiles = defaultProfiles
            activeProfile = defaultProfiles[0]
            saveProfiles()
        }
    }

    private func saveProfiles() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        if let data = try? encoder.encode(profiles) {
            try? data.write(to: profilesFileURL, options: .atomic)
        }
    }

    private func migrateRootFilesIfNeeded() {
        let defaultDir = baseDir
            .appendingPathComponent("profiles", isDirectory: true)
            .appendingPathComponent("default", isDirectory: true)

        // If default profile dir already has workouts.json, migration done
        let migratedMarker = defaultDir.appendingPathComponent("workouts.json")
        if FileManager.default.fileExists(atPath: migratedMarker.path) { return }

        let filesToMigrate = ["workouts.json", "daily_goals.json", "achievements.json", "workout_in_progress.json"]
        var anyMigrated = false

        try? FileManager.default.createDirectory(at: defaultDir, withIntermediateDirectories: true)

        for file in filesToMigrate {
            let src = baseDir.appendingPathComponent(file)
            let dst = defaultDir.appendingPathComponent(file)
            if FileManager.default.fileExists(atPath: src.path) {
                try? FileManager.default.copyItem(at: src, to: dst)
                anyMigrated = true
            }
        }

        if anyMigrated {
            // Remove originals after successful copy
            for file in filesToMigrate {
                let src = baseDir.appendingPathComponent(file)
                try? FileManager.default.removeItem(at: src)
            }
            #if DEBUG
            print("[Profile] Migrated root files to profiles/default/")
            #endif
        }
    }
}
