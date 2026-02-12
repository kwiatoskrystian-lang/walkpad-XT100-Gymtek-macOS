import Foundation

struct PetTrick: Identifiable {
    let id: String
    let name: String
    let emoji: String
    let levelRequired: Int

    static let all: [PetTrick] = [
        PetTrick(id: "wave", name: "Machanie", emoji: "👋", levelRequired: 1),
        PetTrick(id: "heart", name: "Serduszko", emoji: "❤️", levelRequired: 2),
        PetTrick(id: "dance", name: "Taniec", emoji: "💃", levelRequired: 3),
        PetTrick(id: "jump", name: "Skok", emoji: "⬆️", levelRequired: 4),
        PetTrick(id: "spin", name: "Obrót", emoji: "🔄", levelRequired: 5),
        PetTrick(id: "sparkle", name: "Iskierki", emoji: "✨", levelRequired: 6),
        PetTrick(id: "rainbow", name: "Tęcza", emoji: "🌈", levelRequired: 7),
        PetTrick(id: "fire", name: "Ogień", emoji: "🔥", levelRequired: 8),
        PetTrick(id: "crown", name: "Koronacja", emoji: "👑", levelRequired: 9),
        PetTrick(id: "diamond", name: "Diament", emoji: "💎", levelRequired: 10),
    ]

    static func unlocked(for level: Int) -> [PetTrick] {
        all.filter { $0.levelRequired <= level }
    }
}
