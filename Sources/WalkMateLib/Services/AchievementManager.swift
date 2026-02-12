import Foundation
import Observation

@Observable
final class AchievementManager {
    static let shared = AchievementManager()

    private(set) var recentlyUnlocked: Achievement?
    private let store = DataStore.shared

    private init() {}

    func configure() {
        ensureAchievementsExist()
    }

    // MARK: - Public

    func checkAchievements(after workout: Workout) {
        let totalDistance = fetchTotalDistance()
        let totalWorkouts = fetchTotalWorkoutCount()
        let streak = GoalsManager.shared.currentStreak
        let seasonalDistance = fetchSeasonalDistance()

        let locked = store.achievements.filter { !$0.isUnlocked }

        for var achievement in locked {
            var shouldUnlock = false

            switch achievement.category {
            case "distance":
                if achievement.achievementID == "first_workout" {
                    shouldUnlock = true
                } else {
                    shouldUnlock = totalDistance >= achievement.threshold
                }
            case "streak":
                shouldUnlock = Double(streak) >= achievement.threshold
            case "speed":
                shouldUnlock = workout.averageSpeed > achievement.threshold
            case "sessions":
                shouldUnlock = Double(totalWorkouts) >= achievement.threshold
            case "seasonal":
                shouldUnlock = seasonalDistance >= achievement.threshold
            default:
                break
            }

            if shouldUnlock {
                achievement.unlockedDate = Date()
                store.updateAchievement(achievement)
                recentlyUnlocked = achievement

                NotificationManager.shared.sendAchievementNotification(
                    name: achievement.name,
                    description: achievement.achievementDescription
                )
                SoundManager.shared.play(.achievementUnlocked)
            }
        }
    }

    func fetchAllAchievements() -> [Achievement] {
        store.achievements.sorted { a, b in
            if a.category != b.category { return a.category < b.category }
            return a.threshold < b.threshold
        }
    }

    func clearRecentUnlock() {
        recentlyUnlocked = nil
    }

    // MARK: - Private

    private func ensureAchievementsExist() {
        let existingIDs = Set(store.achievements.map(\.achievementID))
        var updated = store.achievements

        for def in AchievementDefinitions.all where !existingIDs.contains(def.id) {
            let achievement = Achievement(
                achievementID: def.id,
                name: def.name,
                description: def.description,
                iconName: def.icon,
                threshold: def.threshold,
                category: def.category
            )
            updated.append(achievement)
        }

        if updated.count != store.achievements.count {
            store.setAchievements(updated)
        }
    }

    private func fetchTotalDistance() -> Double {
        store.completedWorkouts().reduce(0.0) { $0 + $1.distance }
    }

    private func fetchTotalWorkoutCount() -> Int {
        store.completedWorkouts().count
    }

    /// Distance walked in the current meteorological season.
    private func fetchSeasonalDistance() -> Double {
        let calendar = Calendar.current
        let now = Date()
        let month = calendar.component(.month, from: now)

        // Season ranges: winter XII-II, spring III-V, summer VI-VIII, autumn IX-XI
        let seasonMonths: [Int]
        switch month {
        case 12, 1, 2: seasonMonths = [12, 1, 2]
        case 3, 4, 5: seasonMonths = [3, 4, 5]
        case 6, 7, 8: seasonMonths = [6, 7, 8]
        default: seasonMonths = [9, 10, 11]
        }

        return store.completedWorkouts()
            .filter { seasonMonths.contains(calendar.component(.month, from: $0.startDate)) }
            .reduce(0.0) { $0 + $1.distance }
    }
}
