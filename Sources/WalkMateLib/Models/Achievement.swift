import Foundation

struct Achievement: Codable, Identifiable {
    var id: String { achievementID }
    var achievementID: String
    var name: String
    var achievementDescription: String
    var iconName: String
    var unlockedDate: Date?
    var threshold: Double
    var category: String // "distance", "streak", "speed", "sessions"

    var isUnlocked: Bool { unlockedDate != nil }

    init(
        achievementID: String,
        name: String,
        description: String,
        iconName: String,
        threshold: Double,
        category: String,
        unlockedDate: Date? = nil
    ) {
        self.achievementID = achievementID
        self.name = name
        self.achievementDescription = description
        self.iconName = iconName
        self.threshold = threshold
        self.category = category
        self.unlockedDate = unlockedDate
    }
}

enum AchievementDefinitions {
    static let all: [(id: String, name: String, description: String, icon: String, threshold: Double, category: String)] = [
        // Distance
        ("first_workout", "Pierwszy krok", "Ukończ pierwszy trening", "figure.walk", 0, "distance"),
        ("5km", "5 km", "Przejdź łącznie 5 km", "mappin.circle.fill", 5, "distance"),
        ("10km", "10 km", "Przejdź łącznie 10 km", "map.fill", 10, "distance"),
        ("marathon", "Maratończyk", "Przejdź łącznie 42.195 km", "medal.fill", 42.195, "distance"),
        ("50km", "Półsetka", "Przejdź łącznie 50 km", "star.circle.fill", 50, "distance"),
        ("100km", "Setka", "Przejdź łącznie 100 km", "globe.europe.africa.fill", 100, "distance"),
        ("250km", "250 km", "Przejdź łącznie 250 km", "rocket.fill", 250, "distance"),
        ("500km", "500 km", "Przejdź łącznie 500 km", "star.fill", 500, "distance"),
        ("1000km", "Tysiącznik", "Przejdź łącznie 1000 km", "trophy.fill", 1000, "distance"),
        // Pet Evolution
        ("pet_tier_1", "Pierwsza ozdoba", "Twój zwierzak dostał bandanę!", "tshirt.fill", 50, "distance"),
        ("pet_tier_2", "Podróżnik", "Twój zwierzak dostał plecak!", "backpack.fill", 150, "distance"),
        ("pet_tier_3", "Bohater", "Twój zwierzak dostał pelerynę!", "shield.fill", 500, "distance"),
        ("pet_tier_4", "Legenda", "Twój zwierzak dostał koronę!", "crown.fill", 1000, "distance"),
        // Streak
        ("streak_7", "Tydzień z rzędu", "Utrzymaj passę 7 dni (1 dzień odpoczynku/tydzień)", "flame.fill", 7, "streak"),
        ("streak_30", "Miesiąc z rzędu", "Utrzymaj passę 30 dni (1 dzień odpoczynku/tydzień)", "flame.fill", 30, "streak"),
        ("streak_100", "100 dni z rzędu", "Utrzymaj passę 100 dni (1 dzień odpoczynku/tydzień)", "diamond.fill", 100, "streak"),
        // Speed
        ("speed_5", "Szybki marsz", "Średnia prędkość > 5 km/h w sesji", "bolt.fill", 5, "speed"),
        ("speed_6", "Trucht", "Średnia prędkość > 6 km/h w sesji", "bolt.fill", 6, "speed"),
        // Sessions
        ("sessions_10", "10 treningów", "Ukończ 10 treningów", "target", 10, "sessions"),
        ("sessions_50", "50 treningów", "Ukończ 50 treningów", "target", 50, "sessions"),
        ("sessions_100", "100 treningów", "Ukończ 100 treningów", "target", 100, "sessions"),
        // Route completion
        ("tour_polska", "Tour de Polska", "Ukończyłeś Tour de Polska! 🇵🇱", "flag.checkered", 1600, "distance"),
        ("tour_camino", "Camino de Santiago", "Ukończyłeś Camino de Santiago! 🐚", "flag.checkered", 2400, "distance"),
        ("tour_alpina", "Via Alpina", "Ukończyłeś Via Alpina! 🏔️", "flag.checkered", 3000, "distance"),
        // Seasonal
        ("seasonal_winter", "Zimowy maratończyk", "Przejdź 42 km w zimie (XII–II) ❄️", "snowflake", 42, "seasonal"),
        ("seasonal_spring", "Wiosenny sprint", "Przejdź 50 km wiosną (III–V) 🌸", "leaf.fill", 50, "seasonal"),
        ("seasonal_summer", "Letni wędrowiec", "Przejdź 60 km latem (VI–VIII) ☀️", "sun.max.fill", 60, "seasonal"),
        ("seasonal_autumn", "Jesienny łowca", "Przejdź 50 km jesienią (IX–XI) 🍂", "leaf.arrow.triangle.circlepath", 50, "seasonal"),
    ]
}
