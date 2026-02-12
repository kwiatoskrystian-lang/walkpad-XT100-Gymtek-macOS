import AppKit
import Foundation
import Observation
import UniformTypeIdentifiers

@Observable
final class SettingsViewModel {
    private let settings = AppSettings.shared

    var dailyGoalDistance: Double {
        didSet { settings.dailyGoalDistance = dailyGoalDistance }
    }

    var weeklySessionsTarget: Int {
        didSet { settings.weeklySessionsTarget = weeklySessionsTarget }
    }

    var reminderHour: Int {
        didSet {
            settings.reminderHour = reminderHour
            NotificationManager.shared.scheduleDailyReminder()
        }
    }

    var reminderMinute: Int {
        didSet {
            settings.reminderMinute = reminderMinute
            NotificationManager.shared.scheduleDailyReminder()
        }
    }

    var notificationsEnabled: Bool {
        didSet {
            settings.notificationsEnabled = notificationsEnabled
            if notificationsEnabled {
                NotificationManager.shared.scheduleDailyReminder()
            } else {
                NotificationManager.shared.scheduleDailyReminder() // removes it
            }
        }
    }

    var launchAtLogin: Bool {
        didSet {
            LaunchAtLoginManager.shared.setEnabled(launchAtLogin)
        }
    }

    var userWeight: Double {
        didSet { settings.userWeight = userWeight }
    }

    var userHeight: Double {
        didSet { settings.userHeight = userHeight }
    }

    var healthKitEnabled: Bool {
        didSet {
            settings.healthKitEnabled = healthKitEnabled
            if healthKitEnabled {
                let hk = HealthKitManager.shared
                if !hk.isAuthorized {
                    hk.requestAuthorization()
                }
            }
        }
    }

    init() {
        self.dailyGoalDistance = settings.dailyGoalDistance
        self.weeklySessionsTarget = settings.weeklySessionsTarget
        self.reminderHour = settings.reminderHour
        self.reminderMinute = settings.reminderMinute
        self.notificationsEnabled = settings.notificationsEnabled
        self.launchAtLogin = LaunchAtLoginManager.shared.isEnabled
        self.userWeight = settings.userWeight
        self.userHeight = settings.userHeight
        self.healthKitEnabled = settings.healthKitEnabled
    }

    var reminderTime: Date {
        get {
            var comps = DateComponents()
            comps.hour = reminderHour
            comps.minute = reminderMinute
            return Calendar.current.date(from: comps) ?? Date()
        }
        set {
            let comps = Calendar.current.dateComponents([.hour, .minute], from: newValue)
            reminderHour = comps.hour ?? 18
            reminderMinute = comps.minute ?? 0
        }
    }

    func reloadFromSettings() {
        dailyGoalDistance = settings.dailyGoalDistance
        weeklySessionsTarget = settings.weeklySessionsTarget
        userWeight = settings.userWeight
        userHeight = settings.userHeight
        healthKitEnabled = settings.healthKitEnabled
    }

    func manualScan() {
        BLEManager.shared.forgetDevice()
        BLEManager.shared.startScanning()
    }

    func forgetDevice() {
        BLEManager.shared.forgetDevice()
    }

    func exportCSV() {
        let workouts = DataStore.shared.completedWorkouts()
            .sorted { $0.startDate < $1.startDate }
        guard !workouts.isEmpty else { return }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        dateFormatter.locale = Locale(identifier: "pl_PL")

        var csv = "Data,Czas trwania (min),Dystans (km),Średnia prędkość (km/h),Max prędkość (km/h),Kalorie\n"
        for w in workouts {
            let date = dateFormatter.string(from: w.startDate)
            let duration = String(format: "%.1f", w.duration / 60)
            let distance = String(format: "%.2f", w.distance)
            let avgSpeed = String(format: "%.1f", w.averageSpeed)
            let maxSpeed = String(format: "%.1f", w.maxSpeed)
            let calories = w.calories.map { String($0) } ?? ""
            csv += "\(date),\(duration),\(distance),\(avgSpeed),\(maxSpeed),\(calories)\n"
        }

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.commaSeparatedText]
        panel.nameFieldStringValue = "WalkMate_treningi.csv"
        panel.title = "Eksportuj treningi"

        if panel.runModal() == .OK, let url = panel.url {
            try? csv.write(to: url, atomically: true, encoding: .utf8)
        }
    }
}
