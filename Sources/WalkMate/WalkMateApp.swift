import AppKit
import SwiftUI
@testable import WalkMateLib

@main
struct WalkMateApp: App {

    init() {
        // Disable stdout buffering so print() shows immediately when piped
        setbuf(stdout, nil)

        // Guarantee no dock icon — menu bar only
        NSApplication.shared.setActivationPolicy(.accessory)

        // Configure profiles first — sets up DataStore and AppSettings for active profile
        AppSettings.shared.migrateUnprefixedKeys()
        ProfileManager.shared.configureActiveProfile()

        // Configure services
        GoalsManager.shared.configure()
        AchievementManager.shared.configure()
        WorkoutManager.shared.configure()
        ChallengeManager.shared.configure()
        DailyBonusManager.shared.configure()

        // Setup notifications
        NotificationManager.shared.requestPermissionIfNeeded()
        NotificationManager.shared.scheduleDailyReminder()

        // Start daily backup scheduler (19:00)
        BackupManager.shared.configure()

        // Schedule daily summary notification
        scheduleDailySummary()

        // Schedule streak-at-risk notification (19:00)
        scheduleStreakAtRisk()

        // Workout ended callback
        WorkoutManager.shared.onWorkoutEnded = { workout in
            GoalsManager.shared.refreshGoals()
            AchievementManager.shared.checkAchievements(after: workout)
            ChallengeManager.shared.checkChallenges(after: workout)

            // Check for completed challenges and notify
            let challenges = ChallengeManager.shared.currentChallenges
            for challenge in challenges where challenge.isCompleted {
                // Only notify if just completed (check by progress matching target)
                NotificationManager.shared.sendChallengeCompletedNotification(
                    name: challenge.name,
                    xp: challenge.xpReward
                )
            }

            // Daily bonus — first workout of the day
            let workoutXP = Int(workout.distance * 100)
            if let bonus = DailyBonusManager.shared.checkDailyBonus(workoutXP: workoutXP) {
                NotificationManager.shared.sendDailyBonusNotification(
                    multiplier: bonus.multiplier,
                    bonusXP: bonus.bonusXP
                )
            }

            let remaining = GoalsManager.shared.remainingDistance
            if remaining > 0 {
                NotificationManager.shared.updateDailyReminderBody(remainingKm: remaining)
            }

            NotificationManager.shared.scheduleWeeklyWarning(
                completedSessions: GoalsManager.shared.weeklyCompletedSessions,
                target: AppSettings.shared.weeklySessionsTarget
            )

            let stats = GoalsManager.shared.weeklyStats()
            NotificationManager.shared.scheduleWeeklySummary(
                totalKm: stats.totalKm,
                sessionCount: stats.sessions,
                bestWorkoutKm: stats.bestKm,
                streak: GoalsManager.shared.currentStreak
            )

            // Update daily summary with latest data
            scheduleDailySummaryAfterWorkout()

            // Update streak-at-risk notification
            scheduleStreakAtRiskAfterWorkout()

            // Check treadmill maintenance
            checkMaintenanceReminder()
        }
    }

    var body: some Scene {
        MenuBarExtra {
            ContentView()
        } label: {
            MenuBarLabel()
        }
        .menuBarExtraStyle(.window)
    }

    private func scheduleStreakAtRisk() {
        let goals = GoalsManager.shared
        NotificationManager.shared.scheduleStreakAtRisk(
            streak: goals.currentStreak,
            remainingKm: goals.remainingDistance
        )
    }

    private func scheduleDailySummary() {
        let goals = GoalsManager.shared
        let todayKm = goals.todayGoal?.completedDistance ?? 0
        let todayCal = DataStore.shared.completedWorkouts()
            .filter { Calendar.current.isDateInToday($0.startDate) }
            .reduce(0) { $0 + ($1.calories ?? 0) }
        let goalAchieved = goals.dailyProgress >= 1.0

        NotificationManager.shared.scheduleDailySummary(
            distanceKm: todayKm,
            calories: todayCal,
            goalAchieved: goalAchieved,
            streak: goals.currentStreak
        )
    }
}

private func checkMaintenanceReminder() {
    let settings = AppSettings.shared
    let totalKm = DataStore.shared.completedWorkouts().reduce(0.0) { $0 + $1.distance }
    let kmSinceMaintenance = totalKm - settings.lastMaintenanceKm
    if kmSinceMaintenance >= settings.maintenanceIntervalKm {
        NotificationManager.shared.sendMaintenanceReminder(kmSinceLast: kmSinceMaintenance)
    }
}

private func scheduleStreakAtRiskAfterWorkout() {
    let goals = GoalsManager.shared
    NotificationManager.shared.scheduleStreakAtRisk(
        streak: goals.currentStreak,
        remainingKm: goals.remainingDistance
    )
}

private func scheduleDailySummaryAfterWorkout() {
    let goals = GoalsManager.shared
    let todayKm = goals.todayGoal?.completedDistance ?? 0
    let todayCal = DataStore.shared.completedWorkouts()
        .filter { Calendar.current.isDateInToday($0.startDate) }
        .reduce(0) { $0 + ($1.calories ?? 0) }
    let goalAchieved = goals.dailyProgress >= 1.0

    NotificationManager.shared.scheduleDailySummary(
        distanceKm: todayKm,
        calories: todayCal,
        goalAchieved: goalAchieved,
        streak: goals.currentStreak
    )
}
