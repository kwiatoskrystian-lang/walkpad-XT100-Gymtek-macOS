import Foundation
import Observation

/// JSON file-based persistence replacing SwiftData.
/// Stores data in ~/Library/Application Support/WalkMate/
@Observable
final class DataStore {
    static let shared = DataStore()

    private(set) var workouts: [Workout] = []
    private(set) var dailyGoals: [DailyGoal] = []
    private(set) var achievements: [Achievement] = []
    private(set) var weightEntries: [WeightEntry] = []

    private var storageDir: URL
    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = .prettyPrinted
        return e
    }()
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    private init() {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first!
        storageDir = appSupport.appendingPathComponent("WalkMate", isDirectory: true)
        try? FileManager.default.createDirectory(at: storageDir, withIntermediateDirectories: true)
        // Don't load yet — ProfileManager.configureActiveProfile() will call reload()
    }

    func reload(storageDir: URL) {
        self.storageDir = storageDir
        try? FileManager.default.createDirectory(at: storageDir, withIntermediateDirectories: true)
        workouts = []
        dailyGoals = []
        achievements = []
        weightEntries = []
        load()
    }

    // MARK: - Workouts

    func addWorkout(_ workout: Workout) {
        workouts.append(workout)
        saveWorkouts()
    }

    func completedWorkouts() -> [Workout] {
        workouts.filter { $0.endDate != nil }
    }

    // MARK: - Daily Goals

    func goalForDate(_ date: Date) -> DailyGoal? {
        let day = Calendar.current.startOfDay(for: date)
        return dailyGoals.first { Calendar.current.isDate($0.date, inSameDayAs: day) }
    }

    func addOrUpdateGoal(_ goal: DailyGoal) {
        if let idx = dailyGoals.firstIndex(where: {
            Calendar.current.isDate($0.date, inSameDayAs: goal.date)
        }) {
            dailyGoals[idx] = goal
        } else {
            dailyGoals.append(goal)
        }
        saveDailyGoals()
    }

    func saveGoals() { saveDailyGoals() }

    // MARK: - Achievements

    func updateAchievement(_ achievement: Achievement) {
        if let idx = achievements.firstIndex(where: { $0.achievementID == achievement.achievementID }) {
            achievements[idx] = achievement
        }
        saveAchievements()
    }

    func setAchievements(_ list: [Achievement]) {
        achievements = list
        saveAchievements()
    }

    // MARK: - Weight

    func addWeightEntry(_ entry: WeightEntry) {
        weightEntries.append(entry)
        saveWeightEntries()
    }

    func sortedWeightEntries() -> [WeightEntry] {
        weightEntries.sorted { $0.date < $1.date }
    }

    // MARK: - Static helpers

    /// Load workouts from an arbitrary storage directory without affecting the shared instance.
    static func loadWorkouts(from storageDir: URL) -> [Workout] {
        let url = storageDir.appendingPathComponent("workouts.json")
        guard let data = try? Data(contentsOf: url) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([Workout].self, from: data)) ?? []
    }

    // MARK: - Persistence

    private func load() {
        workouts = loadFile("workouts.json") ?? []
        dailyGoals = loadFile("daily_goals.json") ?? []
        achievements = loadFile("achievements.json") ?? []
        weightEntries = loadFile("weight_entries.json") ?? []
    }

    func saveWorkouts() { saveFile(workouts, name: "workouts.json") }
    private func saveDailyGoals() { saveFile(dailyGoals, name: "daily_goals.json") }
    private func saveAchievements() { saveFile(achievements, name: "achievements.json") }
    private func saveWeightEntries() { saveFile(weightEntries, name: "weight_entries.json") }

    private func saveFile<T: Encodable>(_ value: T, name: String) {
        let url = storageDir.appendingPathComponent(name)
        if let data = try? encoder.encode(value) {
            try? data.write(to: url, options: .atomic)
        }
    }

    private func loadFile<T: Decodable>(_ name: String) -> T? {
        let url = storageDir.appendingPathComponent(name)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? decoder.decode(T.self, from: data)
    }
}
