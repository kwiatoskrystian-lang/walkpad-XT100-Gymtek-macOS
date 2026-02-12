import Foundation
import Observation

@Observable
final class AchievementsViewModel {
    private(set) var achievements: [Achievement] = []
    var showingCelebration = false

    func refresh() {
        achievements = AchievementManager.shared.fetchAllAchievements()
    }

    var unlockedCount: Int {
        achievements.filter(\.isUnlocked).count
    }

    var totalCount: Int {
        achievements.count
    }

    func formattedDate(_ date: Date?) -> String {
        guard let date else { return "" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pl_PL")
        formatter.dateFormat = "d MMM yyyy"
        return formatter.string(from: date)
    }
}
