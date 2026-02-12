import Foundation
import UserNotifications

final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()

    private let settings = AppSettings.shared

    /// Lazily accessed — UNUserNotificationCenter.current() crashes
    /// if called before the app bundle is fully set up.
    private var center: UNUserNotificationCenter? {
        guard Bundle.main.bundleIdentifier != nil else { return nil }
        return UNUserNotificationCenter.current()
    }

    private override init() {
        super.init()
    }

    // MARK: - Foreground notification display

    /// Called when a notification arrives while the app is in the foreground.
    /// Menu bar apps are always "foreground", so without this, notifications are silently suppressed.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .list])
    }

    // MARK: - Permission

    func requestPermissionIfNeeded() {
        guard let center else {
            #if DEBUG
            print("[Notifications] ⚠️ center is nil — cannot request permission")
            #endif
            return
        }

        // Set ourselves as delegate so foreground notifications show
        center.delegate = self

        center.getNotificationSettings { notifSettings in
            #if DEBUG
            print("[Notifications] authorizationStatus: \(notifSettings.authorizationStatus.rawValue) (0=notDetermined, 1=denied, 2=authorized, 3=provisional)")
            #endif

            if notifSettings.authorizationStatus == .notDetermined {
                center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                    #if DEBUG
                    print("[Notifications] Authorization: granted=\(granted), error=\(error?.localizedDescription ?? "none")")
                    #endif
                }
            }
        }
    }

    // MARK: - Test

    func sendTestNotification() {
        guard let center else {
            #if DEBUG
            print("[Notifications] ⚠️ center is nil")
            #endif
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "WalkMate działa! 🐕"
        content.body = "Powiadomienia są skonfigurowane poprawnie. Czas na spacer!"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "test_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )
        center.add(request) { error in
            #if DEBUG
            if let error {
                print("[Notifications] ❌ Test failed: \(error.localizedDescription)")
            } else {
                print("[Notifications] ✅ Test notification sent")
            }
            #endif
        }
    }

    // MARK: - Daily Reminder

    func scheduleDailyReminder() {
        guard let center else { return }
        guard settings.notificationsEnabled else {
            center.removePendingNotificationRequests(withIdentifiers: ["daily_reminder"])
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "Czas na spacer! \u{1F6B6}"
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = settings.reminderHour
        dateComponents.minute = settings.reminderMinute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "daily_reminder", content: content, trigger: trigger)

        center.removePendingNotificationRequests(withIdentifiers: ["daily_reminder"])
        center.add(request)
    }

    func updateDailyReminderBody(remainingKm: Double) {
        guard let center, settings.notificationsEnabled else { return }

        let content = UNMutableNotificationContent()
        content.title = "Czas na spacer! \u{1F6B6}"
        content.body = String(
            format: "Brakuje Ci jeszcze %.1f km do dzisiejszego celu. Dasz rad\u{0119}!",
            remainingKm
        )
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = settings.reminderHour
        dateComponents.minute = settings.reminderMinute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "daily_reminder", content: content, trigger: trigger)

        center.removePendingNotificationRequests(withIdentifiers: ["daily_reminder"])
        center.add(request)
    }

    // MARK: - Goal Achieved

    func sendGoalAchievedNotification(distance: Double) {
        guard let center, settings.notificationsEnabled else { return }

        let content = UNMutableNotificationContent()
        content.title = "Cel osi\u{0105}gni\u{0119}ty! \u{1F389}"
        content.body = String(
            format: "Przeszed\u{0142}e\u{015B} dzi\u{015B} %.1f km. \u{015A}wietna robota!",
            distance
        )
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "goal_achieved_\(Date().timeIntervalSince1970)",
            content: content, trigger: nil
        )
        center.add(request)
    }

    // MARK: - Weekly Warning (Saturday)

    func scheduleWeeklyWarning(completedSessions: Int, target: Int) {
        guard let center, settings.notificationsEnabled else { return }
        guard completedSessions < target - 1 else { return }

        let content = UNMutableNotificationContent()
        content.title = "Weekend to szansa! \u{1F4AA}"
        content.body = String(
            format: "W tym tygodniu masz %d/%d sesji. Jeszcze %d do celu tygodniowego.",
            completedSessions, target, target - completedSessions
        )
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.weekday = 7
        dateComponents.hour = 10

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "weekly_warning", content: content, trigger: trigger)

        center.removePendingNotificationRequests(withIdentifiers: ["weekly_warning"])
        center.add(request)
    }

    // MARK: - Weekly Summary (Sunday 20:00)

    func scheduleWeeklySummary(totalKm: Double, sessionCount: Int, bestWorkoutKm: Double, streak: Int) {
        guard let center, settings.notificationsEnabled else { return }

        let content = UNMutableNotificationContent()
        content.title = "Podsumowanie tygodnia \u{1F4CA}"
        content.body = String(
            format: "Ten tydzie\u{0144}: %.1f km w %d sesjach. Najlepszy: %.1f km. Passa: %d dni.",
            totalKm, sessionCount, bestWorkoutKm, streak
        )
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.weekday = 1 // Sunday
        dateComponents.hour = 20

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "weekly_summary", content: content, trigger: trigger)

        center.removePendingNotificationRequests(withIdentifiers: ["weekly_summary"])
        center.add(request)
    }

    // MARK: - Workout Ended by Disconnect

    func sendWorkoutEndedByDisconnect() {
        guard let center, settings.notificationsEnabled else { return }

        let content = UNMutableNotificationContent()
        content.title = "Trening zako\u{0144}czony"
        content.body = "Bie\u{017C}nia zosta\u{0142}a roz\u{0142}\u{0105}czona. Trening zosta\u{0142} zapisany."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "workout_disconnect_\(Date().timeIntervalSince1970)",
            content: content, trigger: nil
        )
        center.add(request)
    }

    // MARK: - Distance Milestone

    func sendDistanceMilestone(km: Int, elapsedSeconds: Int) {
        guard let center, settings.notificationsEnabled else { return }

        let minutes = elapsedSeconds / 60
        let seconds = elapsedSeconds % 60

        let content = UNMutableNotificationContent()
        content.title = "\(km) km!"
        content.body = String(
            format: "Przeszed\u{0142}e\u{015B} %d km w %d:%02d. Tak trzymaj!",
            km, minutes, seconds
        )
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "milestone_\(km)km",
            content: content, trigger: nil
        )
        center.add(request)
    }

    // MARK: - Live Coaching

    func sendCoachingTip(_ message: String) {
        guard let center, settings.notificationsEnabled else { return }

        let content = UNMutableNotificationContent()
        content.title = "Trener 💪"
        content.body = message
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "coaching_\(Date().timeIntervalSince1970)",
            content: content, trigger: nil
        )
        center.add(request)
    }

    // MARK: - Daily Summary (21:00)

    func scheduleDailySummary(distanceKm: Double, calories: Int, goalAchieved: Bool, streak: Int) {
        guard let center, settings.notificationsEnabled else { return }

        let content = UNMutableNotificationContent()
        content.title = "Podsumowanie dnia 📊"

        var body = String(format: "Dziś: %.1f km", distanceKm)
        if calories > 0 {
            body += ", \(calories) kcal"
        }
        if goalAchieved {
            body += ". Cel osiągnięty! ✅"
        } else {
            body += ". Jutro dasz radę! 💪"
        }
        if streak > 1 {
            body += " Passa: \(streak) dni 🔥"
        }

        content.body = body
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = 21
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "daily_summary", content: content, trigger: trigger)

        center.removePendingNotificationRequests(withIdentifiers: ["daily_summary"])
        center.add(request)
    }

    // MARK: - Challenge Completed

    func sendChallengeCompletedNotification(name: String, xp: Int) {
        guard let center, settings.notificationsEnabled else { return }

        let content = UNMutableNotificationContent()
        content.title = "Wyzwanie ukończone! 🎯"
        content.body = "\(name) — +\(xp) XP"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "challenge_\(Date().timeIntervalSince1970)",
            content: content, trigger: nil
        )
        center.add(request)
    }

    // MARK: - Daily Bonus

    func sendDailyBonusNotification(multiplier: Double, bonusXP: Int) {
        guard let center, settings.notificationsEnabled else { return }

        let content = UNMutableNotificationContent()
        content.title = "Bonus dnia! 🎰"
        content.body = String(format: "Mnożnik ×%.1f — +%d XP!", multiplier, bonusXP)
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "daily_bonus_\(Date().timeIntervalSince1970)",
            content: content, trigger: nil
        )
        center.add(request)
    }

    // MARK: - Streak at Risk (19:00)

    func scheduleStreakAtRisk(streak: Int, remainingKm: Double) {
        guard let center, settings.notificationsEnabled else { return }
        guard streak > 0, remainingKm > 0 else {
            center.removePendingNotificationRequests(withIdentifiers: ["streak_at_risk"])
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "Seria zagrożona! 🔥"
        content.body = String(
            format: "Twoja passa %d dni jest zagrożona! Zostało %.1f km do celu. Dasz radę!",
            streak, remainingKm
        )
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = 19
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "streak_at_risk", content: content, trigger: trigger)

        center.removePendingNotificationRequests(withIdentifiers: ["streak_at_risk"])
        center.add(request)
    }

    // MARK: - Streak Shield Used

    func sendStreakShieldUsed(streak: Int, shieldsRemaining: Int) {
        guard let center, settings.notificationsEnabled else { return }

        let content = UNMutableNotificationContent()
        content.title = "Tarcza użyta! 🛡️"
        content.body = String(
            format: "Tarcza uratowała Twoją passę %d dni! Pozostało tarcz: %d",
            streak, shieldsRemaining
        )
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "streak_shield_\(Date().timeIntervalSince1970)",
            content: content, trigger: nil
        )
        center.add(request)
    }

    // MARK: - Streak Shield Earned

    func sendStreakShieldEarned(streak: Int, totalShields: Int) {
        guard let center, settings.notificationsEnabled else { return }

        let content = UNMutableNotificationContent()
        content.title = "Nowa tarcza! 🛡️🎉"
        content.body = String(
            format: "Passa %d dni — zdobyłeś tarczę streaka! Łącznie: %d",
            streak, totalShields
        )
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "streak_shield_earned_\(Date().timeIntervalSince1970)",
            content: content, trigger: nil
        )
        center.add(request)
    }

    // MARK: - Treadmill Maintenance

    func sendMaintenanceReminder(kmSinceLast: Double) {
        guard let center, settings.notificationsEnabled else { return }

        let content = UNMutableNotificationContent()
        content.title = "Konserwacja bieżni 🔧"
        content.body = String(
            format: "Przeszedłeś %.0f km od ostatniego olejowania taśmy. Czas na konserwację!",
            kmSinceLast
        )
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "maintenance_\(Date().timeIntervalSince1970)",
            content: content, trigger: nil
        )
        center.add(request)
    }

    // MARK: - Achievement

    func sendAchievementNotification(name: String, description: String) {
        guard let center, settings.notificationsEnabled else { return }

        let content = UNMutableNotificationContent()
        content.title = "Nowe osi\u{0105}gni\u{0119}cie! \u{1F3C6}"
        content.body = "\(name) — \(description)"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "achievement_\(Date().timeIntervalSince1970)",
            content: content, trigger: nil
        )
        center.add(request)
    }
}
