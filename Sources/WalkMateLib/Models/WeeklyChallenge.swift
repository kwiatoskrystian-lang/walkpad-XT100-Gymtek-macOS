import Foundation

struct WeeklyChallenge: Codable, Identifiable {
    var id: String { challengeID }
    let challengeID: String
    let type: ChallengeType
    let name: String
    let challengeDescription: String
    let iconName: String
    let target: Double
    var progress: Double
    var isCompleted: Bool
    let weekStart: Date
    let xpReward: Int

    enum ChallengeType: String, Codable {
        case distanceSingle   // X km in one session
        case distanceTotal    // X km total this week
        case speed            // reach X km/h avg in a session
        case sessions         // complete X sessions this week
        case duration         // walk X minutes in one session
    }
}

enum WeeklyChallengeDefinitions {
    struct Template {
        let type: WeeklyChallenge.ChallengeType
        let name: String
        let description: String
        let icon: String
        let target: Double
        let xp: Int
    }

    static let all: [Template] = [
        // Distance single
        Template(type: .distanceSingle, name: "Długi marsz", description: "Przejdź 2 km w jednej sesji", icon: "arrow.right.circle.fill", target: 2, xp: 75),
        Template(type: .distanceSingle, name: "Piątka", description: "Przejdź 5 km w jednej sesji", icon: "star.circle.fill", target: 5, xp: 150),
        Template(type: .distanceSingle, name: "Mini maraton", description: "Przejdź 3 km w jednej sesji", icon: "figure.walk.circle.fill", target: 3, xp: 100),

        // Distance total
        Template(type: .distanceTotal, name: "Tygodniowa piątka", description: "Przejdź łącznie 5 km w tym tygodniu", icon: "calendar.circle.fill", target: 5, xp: 80),
        Template(type: .distanceTotal, name: "Tygodniowa dziesiątka", description: "Przejdź łącznie 10 km w tym tygodniu", icon: "calendar.badge.checkmark", target: 10, xp: 120),
        Template(type: .distanceTotal, name: "Tygodniowy maraton", description: "Przejdź łącznie 15 km w tym tygodniu", icon: "trophy.circle.fill", target: 15, xp: 200),

        // Speed
        Template(type: .speed, name: "Szybkie nogi", description: "Osiągnij średnio 4.5 km/h w sesji", icon: "bolt.circle.fill", target: 4.5, xp: 60),
        Template(type: .speed, name: "Ekspres", description: "Osiągnij średnio 5.5 km/h w sesji", icon: "bolt.fill", target: 5.5, xp: 120),

        // Sessions
        Template(type: .sessions, name: "Regularność", description: "Ukończ 3 treningi w tym tygodniu", icon: "checkmark.circle.fill", target: 3, xp: 80),
        Template(type: .sessions, name: "Wytrwałość", description: "Ukończ 5 treningów w tym tygodniu", icon: "flame.circle.fill", target: 5, xp: 150),
        Template(type: .sessions, name: "Codziennie!", description: "Ukończ 7 treningów w tym tygodniu", icon: "star.fill", target: 7, xp: 250),

        // Duration
        Template(type: .duration, name: "Półgodzinka", description: "Chodź 30 minut w jednej sesji", icon: "clock.fill", target: 30, xp: 60),
        Template(type: .duration, name: "Godzinka", description: "Chodź 60 minut w jednej sesji", icon: "clock.badge.checkmark", target: 60, xp: 150),
    ]
}
