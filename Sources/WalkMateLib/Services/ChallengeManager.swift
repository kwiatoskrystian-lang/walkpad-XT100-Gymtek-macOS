import Foundation
import Observation

@Observable
final class ChallengeManager {
    static let shared = ChallengeManager()

    private(set) var currentChallenges: [WeeklyChallenge] = []
    private let store = DataStore.shared

    private var challengesFileURL: URL {
        ProfileManager.shared.activeStorageDir
            .appendingPathComponent("weekly_challenges.json")
    }

    private init() {}

    func configure() {
        loadChallenges()
        ensureCurrentWeek()
    }

    // MARK: - Check after workout

    func checkChallenges(after workout: Workout) {
        let calendar = Calendar.current
        let weekStart = currentWeekStart(calendar: calendar)
        let weekWorkouts = store.completedWorkouts().filter { $0.startDate >= weekStart }

        for i in currentChallenges.indices {
            guard !currentChallenges[i].isCompleted else { continue }

            switch currentChallenges[i].type {
            case .distanceSingle:
                currentChallenges[i].progress = max(currentChallenges[i].progress, workout.distance)
                if workout.distance >= currentChallenges[i].target {
                    currentChallenges[i].isCompleted = true
                }

            case .distanceTotal:
                let totalKm = weekWorkouts.reduce(0.0) { $0 + $1.distance }
                currentChallenges[i].progress = totalKm
                if totalKm >= currentChallenges[i].target {
                    currentChallenges[i].isCompleted = true
                }

            case .speed:
                currentChallenges[i].progress = max(currentChallenges[i].progress, workout.averageSpeed)
                if workout.averageSpeed >= currentChallenges[i].target {
                    currentChallenges[i].isCompleted = true
                }

            case .sessions:
                let count = Double(weekWorkouts.count)
                currentChallenges[i].progress = count
                if count >= currentChallenges[i].target {
                    currentChallenges[i].isCompleted = true
                }

            case .duration:
                let mins = workout.duration / 60.0
                currentChallenges[i].progress = max(currentChallenges[i].progress, mins)
                if mins >= currentChallenges[i].target {
                    currentChallenges[i].isCompleted = true
                }
            }
        }

        saveChallenges()
    }

    var completedCount: Int {
        currentChallenges.filter(\.isCompleted).count
    }

    var totalBonusXP: Int {
        currentChallenges.filter(\.isCompleted).reduce(0) { $0 + $1.xpReward }
    }

    // MARK: - Week management

    private func ensureCurrentWeek() {
        let calendar = Calendar.current
        let weekStart = currentWeekStart(calendar: calendar)

        if currentChallenges.isEmpty || !calendar.isDate(currentChallenges[0].weekStart, inSameDayAs: weekStart) {
            generateNewChallenges(weekStart: weekStart)
        }
    }

    private func generateNewChallenges(weekStart: Date) {
        let templates = WeeklyChallengeDefinitions.all.shuffled()
        var selected: [WeeklyChallengeDefinitions.Template] = []
        var usedTypes = Set<WeeklyChallenge.ChallengeType>()

        // Pick 3 challenges with different types
        for t in templates {
            guard selected.count < 3 else { break }
            if !usedTypes.contains(t.type) {
                selected.append(t)
                usedTypes.insert(t.type)
            }
        }

        // If we don't have 3 unique types, fill remaining
        if selected.count < 3 {
            for t in templates where selected.count < 3 {
                if !selected.contains(where: { $0.name == t.name }) {
                    selected.append(t)
                }
            }
        }

        currentChallenges = selected.enumerated().map { idx, template in
            WeeklyChallenge(
                challengeID: "week_\(Int(weekStart.timeIntervalSince1970))_\(idx)",
                type: template.type,
                name: template.name,
                challengeDescription: template.description,
                iconName: template.icon,
                target: template.target,
                progress: 0,
                isCompleted: false,
                weekStart: weekStart,
                xpReward: template.xp
            )
        }

        saveChallenges()
    }

    private func currentWeekStart(calendar: Calendar) -> Date {
        var d = calendar.startOfDay(for: .now)
        while calendar.component(.weekday, from: d) != 2 { // Monday
            d = calendar.date(byAdding: .day, value: -1, to: d)!
        }
        return d
    }

    // MARK: - Persistence

    private func loadChallenges() {
        guard let data = try? Data(contentsOf: challengesFileURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        currentChallenges = (try? decoder.decode([WeeklyChallenge].self, from: data)) ?? []
    }

    private func saveChallenges() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        if let data = try? encoder.encode(currentChallenges) {
            try? data.write(to: challengesFileURL, options: .atomic)
        }
    }
}
