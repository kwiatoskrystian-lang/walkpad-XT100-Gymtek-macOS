import Foundation
import Observation

/// Calculates XP from workouts, streaks, and achievements.
/// XP is computed on-the-fly from DataStore — no separate persistence needed.
@Observable
final class XPManager {
    static let shared = XPManager()

    private let store = DataStore.shared
    private let goals = GoalsManager.shared

    private init() {}

    // MARK: - XP Calculation

    /// Total XP from all sources.
    var totalXP: Int {
        workoutXP + streakXP + achievementXP + challengeXP + dailyBonusXP
    }

    /// XP from completed weekly challenges.
    var challengeXP: Int {
        ChallengeManager.shared.totalBonusXP
    }

    /// XP from daily spin bonuses.
    var dailyBonusXP: Int {
        DailyBonusManager.shared.totalBonusXP
    }

    /// XP from workout distance: 100 XP per km.
    var workoutXP: Int {
        let totalKm = store.completedWorkouts().reduce(0.0) { $0 + $1.distance }
        return Int(totalKm * 100)
    }

    /// XP bonus from current streak: streak * 15.
    var streakXP: Int {
        goals.currentStreak * 15
    }

    /// XP from unlocked achievements: 50 XP each.
    var achievementXP: Int {
        store.achievements.filter(\.isUnlocked).count * 50
    }

    var currentLevel: XPLevel {
        XPLevel.current(for: totalXP)
    }

    var nextLevel: XPLevel? {
        XPLevel.next(after: currentLevel)
    }

    var progressToNext: Double {
        XPLevel.progressToNext(xp: totalXP)
    }

    var unlockedSkins: [String] {
        XPLevel.unlockedSkins(for: totalXP)
    }
}
