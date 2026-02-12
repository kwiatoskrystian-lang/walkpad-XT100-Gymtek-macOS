import Foundation

enum MopsMood {
    case walking    // workout active
    case ecstatic   // daily goal achieved
    case happy      // 50%+ of goal
    case content    // walked some today
    case waiting    // haven't walked today yet
    case sad        // missed yesterday's goal

    /// Computed from live app state. Call from SwiftUI body so
    /// observation tracks the underlying @Observable managers.
    static var current: MopsMood {
        if WorkoutManager.shared.isWorkoutActive { return .walking }

        let goal = GoalsManager.shared.todayGoal
        let todayKm = goal?.completedDistance ?? 0
        let targetKm = goal?.targetDistance ?? AppSettings.shared.dailyGoalDistance

        if todayKm >= targetKm { return .ecstatic }
        if todayKm >= targetKm * 0.5 { return .happy }
        if todayKm > 0 { return .content }

        let yesterday = Calendar.current.date(
            byAdding: .day, value: -1,
            to: Calendar.current.startOfDay(for: .now)
        )!
        if let yGoal = DataStore.shared.goalForDate(yesterday), !yGoal.isAchieved {
            return .sad
        }

        return .waiting
    }

    private static var petType: PetType {
        ProfileManager.shared.activeProfile.petType
    }

    var icon: String {
        let pet = MopsMood.petType
        switch self {
        case .walking, .ecstatic, .happy, .content:
            return pet.icon
        case .waiting, .sad:
            return pet.iconOutline
        }
    }

    var bubble: String {
        MopsMood.petType.bubble(for: self)
    }

    var moodEmoji: String {
        switch self {
        case .walking:  "🏃"
        case .ecstatic: "⭐"
        case .happy:    "❤️"
        case .content:  "😊"
        case .waiting:  "👀"
        case .sad:      "💤"
        }
    }

    /// Total lifetime distance across all workouts + active workout.
    static var lifetimeDistance: Double {
        let completed = DataStore.shared.completedWorkouts()
            .reduce(0.0) { $0 + $1.distance }
        let active = WorkoutManager.shared.isWorkoutActive
            ? WorkoutManager.shared.currentDistance : 0
        return completed + active
    }
}
