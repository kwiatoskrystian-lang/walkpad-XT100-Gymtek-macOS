import Foundation
import Observation

@Observable
final class StatsViewModel {
    private let store = DataStore.shared

    // Monthly
    private(set) var monthlyTotalDistance: Double = 0
    private(set) var monthlyAvgPerDay: Double = 0
    private(set) var monthlyTotalTime: TimeInterval = 0
    private(set) var monthlyWorkoutCount: Int = 0
    private(set) var monthlyTotalCalories: Int = 0
    private(set) var bestWorkoutDistance: Double = 0
    private(set) var dailyDistances: [(day: Int, distance: Double)] = []
    private(set) var currentStreak: Int = 0
    private(set) var monthlyActiveDays: Int = 0
    private(set) var monthlyGoalCompletionRate: Double = 0
    private(set) var monthlyAvgWorkoutDuration: TimeInterval = 0
    private(set) var monthlyAvgSpeed: Double = 0
    private(set) var monthVsLastMonthPct: Double? = nil // nil means no data

    // Last 7 days
    private(set) var last7DaysDistance: Double = 0
    private(set) var last7DaysCalories: Int = 0

    // Personal records
    private(set) var longestWorkoutDistance: Double = 0
    private(set) var longestWorkoutDuration: TimeInterval = 0
    private(set) var fastestAvgSpeed: Double = 0
    private(set) var longestStreak: Int = 0
    private(set) var totalLifetimeKm: Double = 0
    private(set) var totalLifetimeWorkouts: Int = 0
    private(set) var totalLifetimeCalories: Int = 0
    private(set) var totalLifetimeSteps: Int = 0
    private(set) var totalLifetimeHours: Double = 0
    private(set) var monthlyTotalSteps: Int = 0

    // Insights
    private(set) var bestWeekEverKm: Double = 0
    private(set) var avgWorkoutsPerWeek: Double = 0
    private(set) var favoriteDayOfWeek: String? = nil
    private(set) var favoriteTimeOfDay: String? = nil

    // Activity heatmap (last 35 days)
    private(set) var activityHeatmap: [HeatmapDay] = []

    // Speed trend (last 10 workouts avg speed)
    private(set) var speedTrend: [(index: Int, speed: Double)] = []

    struct HeatmapDay: Identifiable {
        let id = UUID()
        let date: Date
        let distance: Double
        let hasWorkout: Bool
        let goalAchieved: Bool
    }

    func refresh() {
        let calendar = Calendar.current
        let now = Date()

        let allWorkouts = store.completedWorkouts()

        // Current month
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart)!
        let workouts = allWorkouts.filter {
            $0.startDate >= monthStart && $0.startDate < monthEnd
        }

        monthlyWorkoutCount = workouts.count
        monthlyTotalDistance = workouts.reduce(0.0) { $0 + $1.distance }
        monthlyTotalTime = workouts.reduce(0.0) { $0 + $1.duration }
        monthlyTotalCalories = workouts.reduce(0) { $0 + ($1.calories ?? 0) }
        bestWorkoutDistance = workouts.map(\.distance).max() ?? 0
        let heightCm = AppSettings.shared.userHeight
        monthlyTotalSteps = workouts.reduce(0) { total, w in
            total + (w.steps ?? CalorieCalculator.estimateSteps(distanceKm: w.distance, heightCm: heightCm, avgSpeedKmh: w.averageSpeed))
        }

        let dayOfMonth = calendar.component(.day, from: now)
        monthlyAvgPerDay = dayOfMonth > 0 ? monthlyTotalDistance / Double(dayOfMonth) : 0

        // Monthly avg speed
        let totalDist = workouts.reduce(0.0) { $0 + $1.distance }
        let totalTime = workouts.reduce(0.0) { $0 + $1.duration }
        monthlyAvgSpeed = totalTime > 0 ? (totalDist / totalTime) * 3600 : 0

        // Monthly avg workout duration
        monthlyAvgWorkoutDuration = workouts.isEmpty ? 0 : totalTime / Double(workouts.count)

        // Active days this month
        var activeDaySet = Set<Int>()
        for w in workouts {
            activeDaySet.insert(calendar.component(.day, from: w.startDate))
        }
        monthlyActiveDays = activeDaySet.count

        // Goal completion rate this month
        var goalsHit = 0
        var goalsDefined = 0
        for day in 1...dayOfMonth {
            var comps = calendar.dateComponents([.year, .month], from: now)
            comps.day = day
            guard let dayDate = calendar.date(from: comps) else { continue }
            if let goal = store.goalForDate(dayDate) {
                goalsDefined += 1
                if goal.isAchieved { goalsHit += 1 }
            }
        }
        monthlyGoalCompletionRate = goalsDefined > 0 ? Double(goalsHit) / Double(goalsDefined) : 0

        // Month vs last month
        let lastMonthStart = calendar.date(byAdding: .month, value: -1, to: monthStart)!
        let lastMonthWorkouts = allWorkouts.filter {
            $0.startDate >= lastMonthStart && $0.startDate < monthStart
        }
        let lastMonthDist = lastMonthWorkouts.reduce(0.0) { $0 + $1.distance }
        if lastMonthDist > 0 {
            monthVsLastMonthPct = ((monthlyTotalDistance - lastMonthDist) / lastMonthDist) * 100
        } else {
            monthVsLastMonthPct = nil
        }

        // Daily distances for chart
        let daysInMonth = calendar.range(of: .day, in: .month, for: now)?.count ?? 30
        var daily: [(Int, Double)] = []
        for day in 1...daysInMonth {
            var comps = calendar.dateComponents([.year, .month], from: now)
            comps.day = day
            guard let dayStart = calendar.date(from: comps) else { continue }
            guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else { continue }

            let dist = workouts
                .filter { $0.startDate >= dayStart && $0.startDate < dayEnd }
                .reduce(0.0) { $0 + $1.distance }
            daily.append((day, dist))
        }
        dailyDistances = daily

        // Last 7 days
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: calendar.startOfDay(for: now))!
        let recent7 = allWorkouts.filter { $0.startDate >= sevenDaysAgo }
        last7DaysDistance = recent7.reduce(0.0) { $0 + $1.distance }
        last7DaysCalories = recent7.reduce(0) { $0 + ($1.calories ?? 0) }

        currentStreak = GoalsManager.shared.currentStreak

        // Personal records — all-time
        totalLifetimeKm = allWorkouts.reduce(0.0) { $0 + $1.distance }
        totalLifetimeWorkouts = allWorkouts.count
        totalLifetimeCalories = allWorkouts.reduce(0) { $0 + ($1.calories ?? 0) }
        totalLifetimeSteps = allWorkouts.reduce(0) { total, w in
            total + (w.steps ?? CalorieCalculator.estimateSteps(distanceKm: w.distance, heightCm: heightCm, avgSpeedKmh: w.averageSpeed))
        }
        totalLifetimeHours = allWorkouts.reduce(0.0) { $0 + $1.duration } / 3600
        longestWorkoutDistance = allWorkouts.map(\.distance).max() ?? 0
        longestWorkoutDuration = allWorkouts.map(\.duration).max() ?? 0
        fastestAvgSpeed = allWorkouts
            .filter { $0.duration > 0 }
            .map { ($0.distance / $0.duration) * 3600 }
            .max() ?? 0
        longestStreak = calculateLongestStreak()

        // Best week ever
        bestWeekEverKm = calculateBestWeek(allWorkouts: allWorkouts, calendar: calendar)

        // Avg workouts per week
        if let earliest = allWorkouts.map(\.startDate).min() {
            let weeksSinceStart = max(1, calendar.dateComponents([.weekOfYear], from: earliest, to: now).weekOfYear ?? 1)
            avgWorkoutsPerWeek = Double(allWorkouts.count) / Double(weeksSinceStart)
        } else {
            avgWorkoutsPerWeek = 0
        }

        // Favorite day of week
        favoriteDayOfWeek = calculateFavoriteDay(allWorkouts: allWorkouts, calendar: calendar)

        // Favorite time of day
        favoriteTimeOfDay = calculateFavoriteTime(allWorkouts: allWorkouts, calendar: calendar)

        // Activity heatmap (last 35 days for 5 full weeks)
        activityHeatmap = buildHeatmap(allWorkouts: allWorkouts, calendar: calendar, now: now)

        // Speed trend (last 10 workouts)
        let lastWorkouts = allWorkouts
            .sorted { $0.startDate < $1.startDate }
            .suffix(10)
        speedTrend = Array(lastWorkouts.enumerated().map { (idx, w) in
            (index: idx, speed: w.averageSpeed)
        })
    }

    var formattedTotalTime: String {
        let hours = Int(monthlyTotalTime) / 3600
        let mins = (Int(monthlyTotalTime) % 3600) / 60
        return "\(hours)h \(mins)m"
    }

    var formattedAvgWorkoutDuration: String {
        let mins = Int(monthlyAvgWorkoutDuration) / 60
        return "\(mins) min"
    }

    var formattedLongestDuration: String {
        let hours = Int(longestWorkoutDuration) / 3600
        let mins = (Int(longestWorkoutDuration) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(mins)m"
        }
        return "\(mins)m"
    }

    var formattedLifetimeHours: String {
        if totalLifetimeHours >= 10 {
            return String(format: "%.0fh", totalLifetimeHours)
        }
        return String(format: "%.1fh", totalLifetimeHours)
    }

    // MARK: - Private

    private func calculateLongestStreak() -> Int {
        let calendar = Calendar.current
        let goals = store.dailyGoals
            .filter { $0.isAchieved }
            .sorted { $0.date < $1.date }

        guard !goals.isEmpty else { return 0 }

        var best = 1
        var current = 1
        var restDaysUsed: [Int: Int] = [:]

        for i in 1..<goals.count {
            let prevDay = calendar.startOfDay(for: goals[i - 1].date)
            let thisDay = calendar.startOfDay(for: goals[i].date)
            let gap = calendar.dateComponents([.day], from: prevDay, to: thisDay).day ?? 0

            if gap == 1 {
                current += 1
            } else if gap == 2 {
                let gapDay = calendar.date(byAdding: .day, value: 1, to: prevDay)!
                let isoWeek = calendar.component(.weekOfYear, from: gapDay)
                let used = restDaysUsed[isoWeek, default: 0]
                if used < 1 {
                    restDaysUsed[isoWeek] = used + 1
                    current += 1
                } else {
                    current = 1
                    restDaysUsed = [:]
                }
            } else {
                current = 1
                restDaysUsed = [:]
            }
            best = max(best, current)
        }

        return best
    }

    private func calculateBestWeek(allWorkouts: [Workout], calendar: Calendar) -> Double {
        guard let earliest = allWorkouts.map(\.startDate).min() else { return 0 }
        var ws = earliest
        while calendar.component(.weekday, from: ws) != 2 {
            ws = calendar.date(byAdding: .day, value: -1, to: ws)!
        }
        ws = calendar.startOfDay(for: ws)

        let now = Date()
        var best = 0.0
        while ws <= now {
            let we = calendar.date(byAdding: .day, value: 7, to: ws)!
            let km = allWorkouts
                .filter { $0.startDate >= ws && $0.startDate < we }
                .reduce(0.0) { $0 + $1.distance }
            best = max(best, km)
            ws = we
        }
        return best
    }

    private func calculateFavoriteDay(allWorkouts: [Workout], calendar: Calendar) -> String? {
        guard !allWorkouts.isEmpty else { return nil }
        var counts = [Int: Int]()
        for w in allWorkouts {
            let weekday = calendar.component(.weekday, from: w.startDate)
            counts[weekday, default: 0] += 1
        }
        guard let best = counts.max(by: { $0.value < $1.value }) else { return nil }
        let names = ["", "Nd", "Pn", "Wt", "Śr", "Cz", "Pt", "Sb"]
        return best.key < names.count ? names[best.key] : nil
    }

    private func calculateFavoriteTime(allWorkouts: [Workout], calendar: Calendar) -> String? {
        guard !allWorkouts.isEmpty else { return nil }
        var morning = 0, afternoon = 0, evening = 0
        for w in allWorkouts {
            let hour = calendar.component(.hour, from: w.startDate)
            switch hour {
            case 5..<12: morning += 1
            case 12..<17: afternoon += 1
            default: evening += 1
            }
        }
        let best = max(morning, afternoon, evening)
        if best == morning { return "Rano" }
        if best == afternoon { return "Popołudnie" }
        return "Wieczór"
    }

    private func buildHeatmap(allWorkouts: [Workout], calendar: Calendar, now: Date) -> [HeatmapDay] {
        var days: [HeatmapDay] = []
        for offset in (0..<35).reversed() {
            let day = calendar.date(byAdding: .day, value: -offset, to: calendar.startOfDay(for: now))!
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: day)!
            let dist = allWorkouts
                .filter { $0.startDate >= day && $0.startDate < dayEnd }
                .reduce(0.0) { $0 + $1.distance }
            let goal = store.goalForDate(day)
            days.append(HeatmapDay(
                date: day,
                distance: dist,
                hasWorkout: dist > 0,
                goalAchieved: goal?.isAchieved ?? false
            ))
        }
        return days
    }
}
