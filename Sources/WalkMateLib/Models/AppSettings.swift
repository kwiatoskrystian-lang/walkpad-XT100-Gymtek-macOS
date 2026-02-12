import Foundation

final class AppSettings {
    static let shared = AppSettings()

    private let defaults = UserDefaults.standard
    private var keyPrefix: String = "default"

    // Profile-scoped key names
    private enum ProfileKeys {
        static let dailyGoalDistance = "dailyGoalDistance"
        static let weeklySessionsTarget = "weeklySessionsTarget"
        static let userWeight = "userWeight"
        static let userHeight = "userHeight"
        static let streakShields = "streakShields"
        static let lastShieldMilestone = "lastShieldMilestone"
    }

    // App-wide key names (no prefix)
    private enum AppKeys {
        static let reminderHour = "reminderHour"
        static let reminderMinute = "reminderMinute"
        static let notificationsEnabled = "notificationsEnabled"
        static let hasRequestedNotifications = "hasRequestedNotifications"
        static let healthKitEnabled = "healthKitEnabled"
        static let lastMaintenanceKm = "lastMaintenanceKm"
        static let maintenanceIntervalKm = "maintenanceIntervalKm"
    }

    private func profileKey(_ key: String) -> String {
        "\(keyPrefix).\(key)"
    }

    func reloadForProfile(prefix: String) {
        keyPrefix = prefix
    }

    // MARK: - Profile-scoped settings

    var dailyGoalDistance: Double {
        get { defaults.double(forKey: profileKey(ProfileKeys.dailyGoalDistance)).nonZero ?? 10.0 }
        set { defaults.set(newValue, forKey: profileKey(ProfileKeys.dailyGoalDistance)) }
    }

    var weeklySessionsTarget: Int {
        get {
            let val = defaults.integer(forKey: profileKey(ProfileKeys.weeklySessionsTarget))
            return val > 0 ? val : 4
        }
        set { defaults.set(newValue, forKey: profileKey(ProfileKeys.weeklySessionsTarget)) }
    }

    var userWeight: Double {
        get { defaults.double(forKey: profileKey(ProfileKeys.userWeight)).nonZero ?? 70.0 }
        set { defaults.set(newValue, forKey: profileKey(ProfileKeys.userWeight)) }
    }

    var userHeight: Double {
        get { defaults.double(forKey: profileKey(ProfileKeys.userHeight)).nonZero ?? 170.0 }
        set { defaults.set(newValue, forKey: profileKey(ProfileKeys.userHeight)) }
    }

    var streakShields: Int {
        get { defaults.integer(forKey: profileKey(ProfileKeys.streakShields)) }
        set { defaults.set(newValue, forKey: profileKey(ProfileKeys.streakShields)) }
    }

    /// Highest streak milestone that already awarded a shield (7, 30, 60)
    var lastShieldMilestone: Int {
        get { defaults.integer(forKey: profileKey(ProfileKeys.lastShieldMilestone)) }
        set { defaults.set(newValue, forKey: profileKey(ProfileKeys.lastShieldMilestone)) }
    }

    // MARK: - App-wide settings (not profile-scoped)

    var reminderHour: Int {
        get {
            let val = defaults.integer(forKey: AppKeys.reminderHour)
            return defaults.object(forKey: AppKeys.reminderHour) != nil ? val : 18
        }
        set { defaults.set(newValue, forKey: AppKeys.reminderHour) }
    }

    var reminderMinute: Int {
        get { defaults.integer(forKey: AppKeys.reminderMinute) }
        set { defaults.set(newValue, forKey: AppKeys.reminderMinute) }
    }

    var notificationsEnabled: Bool {
        get {
            guard defaults.object(forKey: AppKeys.notificationsEnabled) != nil else { return true }
            return defaults.bool(forKey: AppKeys.notificationsEnabled)
        }
        set { defaults.set(newValue, forKey: AppKeys.notificationsEnabled) }
    }

    var hasRequestedNotifications: Bool {
        get { defaults.bool(forKey: AppKeys.hasRequestedNotifications) }
        set { defaults.set(newValue, forKey: AppKeys.hasRequestedNotifications) }
    }

    var healthKitEnabled: Bool {
        get { defaults.bool(forKey: AppKeys.healthKitEnabled) }
        set { defaults.set(newValue, forKey: AppKeys.healthKitEnabled) }
    }

    /// Total lifetime km when belt was last oiled
    var lastMaintenanceKm: Double {
        get { defaults.double(forKey: AppKeys.lastMaintenanceKm) }
        set { defaults.set(newValue, forKey: AppKeys.lastMaintenanceKm) }
    }

    /// How often to remind about belt maintenance (default 150 km)
    var maintenanceIntervalKm: Double {
        get { defaults.double(forKey: AppKeys.maintenanceIntervalKm).nonZero ?? 150.0 }
        set { defaults.set(newValue, forKey: AppKeys.maintenanceIntervalKm) }
    }

    /// Migrate old unprefixed keys to default profile on first launch with profiles.
    func migrateUnprefixedKeys() {
        let oldKeys = [
            ProfileKeys.dailyGoalDistance,
            ProfileKeys.weeklySessionsTarget,
            ProfileKeys.userWeight,
            ProfileKeys.userHeight,
        ]
        for key in oldKeys {
            let prefixed = "default.\(key)"
            if defaults.object(forKey: prefixed) == nil,
               defaults.object(forKey: key) != nil {
                defaults.set(defaults.object(forKey: key), forKey: prefixed)
            }
        }
    }

    private init() {}
}

private extension Double {
    var nonZero: Double? { self != 0 ? self : nil }
}
