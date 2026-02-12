import Foundation

enum PetEvolutionTier: Int, CaseIterable, Comparable {
    case base = 0
    case bandana = 1
    case backpack = 2
    case cape = 3
    case crown = 4

    var threshold: Double {
        switch self {
        case .base: 0
        case .bandana: 50
        case .backpack: 150
        case .cape: 500
        case .crown: 1000
        }
    }

    var accessoryName: String {
        switch self {
        case .base: ""
        case .bandana: "Bandana"
        case .backpack: "Plecak"
        case .cape: "Peleryna"
        case .crown: "Korona"
        }
    }

    var accessoryEmoji: String {
        switch self {
        case .base: ""
        case .bandana: "🎀"
        case .backpack: "🎒"
        case .cape: "🦸"
        case .crown: "👑"
        }
    }

    static func tier(for lifetimeKm: Double) -> PetEvolutionTier {
        for t in allCases.reversed() {
            if lifetimeKm >= t.threshold { return t }
        }
        return .base
    }

    static func nextTier(after current: PetEvolutionTier) -> PetEvolutionTier? {
        let all = allCases
        guard let idx = all.firstIndex(of: current), idx + 1 < all.count else { return nil }
        return all[idx + 1]
    }

    static func < (lhs: PetEvolutionTier, rhs: PetEvolutionTier) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

enum PetType: String, Codable, CaseIterable {
    case mops
    case raccoon

    var displayName: String {
        switch self {
        case .mops: "Mopsik"
        case .raccoon: "Szopik"
        }
    }

    var icon: String {
        switch self {
        case .mops: "dog.fill"
        case .raccoon: "cat.fill"
        }
    }

    var iconOutline: String {
        switch self {
        case .mops: "dog"
        case .raccoon: "cat"
        }
    }

    func bubble(for mood: MopsMood) -> String {
        switch self {
        case .mops:
            switch mood {
            case .walking:  return "Biegnę z tobą!"
            case .ecstatic: return "Cel osiągnięty! Jestem dumny!"
            case .happy:    return "Świetnie mi się spaceruje!"
            case .content:  return "Fajny spacer, daj jeszcze!"
            case .waiting:  return "Chodźmy na spacer..."
            case .sad:      return "Tęsknię za spacerem..."
            }
        case .raccoon:
            switch mood {
            case .walking:  return "Łapy w ruch!"
            case .ecstatic: return "Cel! Daj przekąskę!"
            case .happy:    return "Szopik zadowolony!"
            case .content:  return "Jeszcze trochę poszperamy!"
            case .waiting:  return "Nudzę się... chodźmy!"
            case .sad:      return "Szopik smutny bez spaceru..."
            }
        }
    }
}
