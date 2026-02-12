import Foundation

struct DailyBonus: Codable {
    let date: Date
    let multiplier: Double // 1.5, 2.0, or 3.0
    let baseXP: Int
    var bonusXP: Int { Int(Double(baseXP) * multiplier) - baseXP }

    static let multipliers: [(value: Double, label: String, weight: Int)] = [
        (1.5, "×1.5", 50),  // 50% chance
        (2.0, "×2", 35),    // 35% chance
        (3.0, "×3", 15),    // 15% chance
    ]

    static func randomMultiplier() -> Double {
        let total = multipliers.reduce(0) { $0 + $1.weight }
        let roll = Int.random(in: 0..<total)
        var sum = 0
        for m in multipliers {
            sum += m.weight
            if roll < sum { return m.value }
        }
        return 1.5
    }
}
