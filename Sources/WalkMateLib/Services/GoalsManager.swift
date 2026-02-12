import Foundation
import Observation

@Observable
final class GoalsManager {
    static let shared = GoalsManager()

    private(set) var todayGoal: DailyGoal?
    private(set) var currentStreak: Int = 0
    private(set) var weeklyCompletedSessions: Int = 0
    private(set) var weeklyDayStatus: [Bool] = Array(repeating: false, count: 7)

    private(set) var streakShields: Int = 0
    private(set) var shieldUsedToday: Bool = false

    private let store = DataStore.shared
    private let settings = AppSettings.shared

    /// Streak milestones that award a shield
    private let shieldMilestones = [7, 30, 60, 100, 150, 200]

    private init() {}

    func configure() {
        streakShields = settings.streakShields
        refreshGoals()
    }

    func reloadForProfile() {
        todayGoal = nil
        currentStreak = 0
        weeklyCompletedSessions = 0
        weeklyDayStatus = Array(repeating: false, count: 7)
        streakShields = settings.streakShields
        shieldUsedToday = false
        refreshGoals()
    }

    // MARK: - Public

    func refreshGoals() {
        fetchOrCreateTodayGoal()
        calculateStreak()
        calculateWeeklyStatus()
        checkShieldMilestones()
    }

    func updateTodayDistance(_ activeWorkoutKm: Double) {
        guard var goal = todayGoal else { return }

        let existingDistance = todayCompletedWorkoutsDistance()
        goal.completedDistance = existingDistance + activeWorkoutKm

        if goal.completedDistance >= goal.targetDistance && !goal.isAchieved {
            goal.isAchieved = true
            NotificationManager.shared.sendGoalAchievedNotification(
                distance: goal.completedDistance
            )
            SoundManager.shared.play(.goalAchieved)
        }

        todayGoal = goal
        store.addOrUpdateGoal(goal)
    }

    var dailyProgress: Double {
        guard let goal = todayGoal, goal.targetDistance > 0 else { return 0 }
        return min(goal.completedDistance / goal.targetDistance, 1.0)
    }

    var remainingDistance: Double {
        guard let goal = todayGoal else { return settings.dailyGoalDistance }
        return max(goal.targetDistance - goal.completedDistance, 0)
    }

    // MARK: - Private

    private func fetchOrCreateTodayGoal() {
        let today = Calendar.current.startOfDay(for: .now)

        if let existing = store.goalForDate(today) {
            todayGoal = existing
        } else {
            let newGoal = DailyGoal(
                date: today,
                targetDistance: settings.dailyGoalDistance
            )
            store.addOrUpdateGoal(newGoal)
            todayGoal = newGoal
        }
    }

    private func todayCompletedWorkoutsDistance() -> Double {
        let todayStart = Calendar.current.startOfDay(for: .now)
        let todayEnd = Calendar.current.date(byAdding: .day, value: 1, to: todayStart)!

        return store.completedWorkouts()
            .filter { $0.startDate >= todayStart && $0.startDate < todayEnd }
            .reduce(0.0) { $0 + $1.distance }
    }

    func weeklyStats() -> (totalKm: Double, sessions: Int, bestKm: Double) {
        let calendar = Calendar.current
        var weekStart = calendar.startOfDay(for: .now)
        while calendar.component(.weekday, from: weekStart) != 2 {
            weekStart = calendar.date(byAdding: .day, value: -1, to: weekStart)!
        }

        let workouts = store.completedWorkouts().filter { $0.startDate >= weekStart }
        let totalKm = workouts.reduce(0.0) { $0 + $1.distance }
        let bestKm = workouts.map(\.distance).max() ?? 0
        return (totalKm, workouts.count, bestKm)
    }

    private func calculateStreak() {
        let calendar = Calendar.current
        var streak = 0
        var checkDate = calendar.startOfDay(for: .now)
        var restDaysUsed: [Int: Int] = [:] // ISO week number → rest days used
        shieldUsedToday = false

        // If today not yet achieved, start from yesterday
        if let goal = store.goalForDate(checkDate), goal.isAchieved {
            // today counts
        } else {
            guard let prevDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else {
                currentStreak = 0
                return
            }
            checkDate = prevDay
        }

        while true {
            if let goal = store.goalForDate(checkDate), goal.isAchieved {
                streak += 1
                guard let prevDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                checkDate = prevDay
            } else {
                // Check if we can use a rest day for this ISO week
                let isoWeek = calendar.component(.weekOfYear, from: checkDate)
                let used = restDaysUsed[isoWeek, default: 0]
                if used < 1 {
                    // Use rest day — skip this day without adding to streak
                    restDaysUsed[isoWeek] = used + 1
                    guard let prevDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                    checkDate = prevDay
                } else {
                    break
                }
            }
        }

        currentStreak = streak
    }

    /// Award shields at streak milestones (7, 30, 60, 100, 150, 200 days)
    private func checkShieldMilestones() {
        let lastMilestone = settings.lastShieldMilestone
        for milestone in shieldMilestones where milestone > lastMilestone && currentStreak >= milestone {
            settings.streakShields += 1
            settings.lastShieldMilestone = milestone
            streakShields = settings.streakShields

            NotificationManager.shared.sendStreakShieldEarned(
                streak: milestone,
                totalShields: streakShields
            )
            SoundManager.shared.play(.shieldEarned)

            #if DEBUG
            print("[Goals] Shield earned at \(milestone)-day streak! Total shields: \(streakShields)")
            #endif
        }
    }

    /// Use a shield to protect the streak. Called externally when streak would break.
    func useStreakShield() -> Bool {
        guard streakShields > 0 else { return false }

        settings.streakShields -= 1
        streakShields = settings.streakShields
        shieldUsedToday = true

        NotificationManager.shared.sendStreakShieldUsed(
            streak: currentStreak,
            shieldsRemaining: streakShields
        )

        #if DEBUG
        print("[Goals] Shield used! Remaining: \(streakShields)")
        #endif
        return true
    }

    private func calculateWeeklyStatus() {
        let calendar = Calendar.current

        // Find Monday of current week
        var weekStart = calendar.startOfDay(for: .now)
        while calendar.component(.weekday, from: weekStart) != 2 { // Monday = 2
            weekStart = calendar.date(byAdding: .day, value: -1, to: weekStart)!
        }

        var status = [Bool](repeating: false, count: 7)
        var completedCount = 0

        for dayOffset in 0..<7 {
            let dayDate = calendar.date(byAdding: .day, value: dayOffset, to: weekStart)!
            if let goal = store.goalForDate(dayDate), goal.isAchieved {
                status[dayOffset] = true
                completedCount += 1
            }
        }

        weeklyDayStatus = status
        weeklyCompletedSessions = completedCount
    }
}
