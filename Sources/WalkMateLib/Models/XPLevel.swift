import Foundation

struct XPLevel {
    let level: Int
    let title: String
    let xpRequired: Int
    let skinReward: String? // emoji accessory unlocked at this level

    static let all: [XPLevel] = [
        XPLevel(level: 1, title: "Nowicjusz", xpRequired: 0, skinReward: nil),
        XPLevel(level: 2, title: "Spacerowicz", xpRequired: 200, skinReward: nil),
        XPLevel(level: 3, title: "Wędrowiec", xpRequired: 500, skinReward: "🧣"),
        XPLevel(level: 4, title: "Maszerowiec", xpRequired: 1000, skinReward: nil),
        XPLevel(level: 5, title: "Podróżnik", xpRequired: 2000, skinReward: "🕶️"),
        XPLevel(level: 6, title: "Odkrywca", xpRequired: 3500, skinReward: nil),
        XPLevel(level: 7, title: "Twardziel", xpRequired: 5500, skinReward: "⚡"),
        XPLevel(level: 8, title: "Weteran", xpRequired: 8000, skinReward: nil),
        XPLevel(level: 9, title: "Mistrz", xpRequired: 12000, skinReward: "🔥"),
        XPLevel(level: 10, title: "Legenda", xpRequired: 18000, skinReward: "💎"),
    ]

    static func current(for xp: Int) -> XPLevel {
        for level in all.reversed() {
            if xp >= level.xpRequired { return level }
        }
        return all[0]
    }

    static func next(after current: XPLevel) -> XPLevel? {
        guard let idx = all.firstIndex(where: { $0.level == current.level }),
              idx + 1 < all.count else { return nil }
        return all[idx + 1]
    }

    static func unlockedSkins(for xp: Int) -> [String] {
        all.filter { $0.xpRequired <= xp }
            .compactMap(\.skinReward)
    }

    static func progressToNext(xp: Int) -> Double {
        let current = self.current(for: xp)
        guard let next = self.next(after: current) else { return 1.0 }
        let range = next.xpRequired - current.xpRequired
        guard range > 0 else { return 1.0 }
        return Double(xp - current.xpRequired) / Double(range)
    }
}
