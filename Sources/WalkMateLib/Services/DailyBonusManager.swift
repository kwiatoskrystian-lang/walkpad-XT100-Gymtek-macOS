import Foundation
import Observation

@Observable
final class DailyBonusManager {
    static let shared = DailyBonusManager()

    private(set) var bonuses: [DailyBonus] = []
    private(set) var pendingBonus: DailyBonus?

    private var fileURL: URL {
        ProfileManager.shared.activeStorageDir
            .appendingPathComponent("daily_bonuses.json")
    }

    private init() {}

    func configure() {
        loadBonuses()
    }

    /// Check if the user has earned a daily bonus today (first workout of the day).
    /// Returns the bonus if newly awarded, nil otherwise.
    func checkDailyBonus(workoutXP: Int) -> DailyBonus? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)

        // Already claimed today?
        if bonuses.contains(where: { calendar.isDate($0.date, inSameDayAs: today) }) {
            return nil
        }

        let multiplier = DailyBonus.randomMultiplier()
        let bonus = DailyBonus(
            date: today,
            multiplier: multiplier,
            baseXP: workoutXP
        )

        bonuses.append(bonus)
        pendingBonus = bonus
        saveBonuses()
        return bonus
    }

    func clearPendingBonus() {
        pendingBonus = nil
    }

    /// Total bonus XP from all daily bonuses.
    var totalBonusXP: Int {
        bonuses.reduce(0) { $0 + $1.bonusXP }
    }

    // MARK: - Persistence

    private func loadBonuses() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        bonuses = (try? decoder.decode([DailyBonus].self, from: data)) ?? []
    }

    private func saveBonuses() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(bonuses) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }
}
