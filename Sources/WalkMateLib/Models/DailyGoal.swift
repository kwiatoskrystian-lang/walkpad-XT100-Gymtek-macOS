import Foundation

struct DailyGoal: Codable, Identifiable {
    var id: UUID
    var date: Date // day only, no time
    var targetDistance: Double // km
    var completedDistance: Double // km
    var isAchieved: Bool

    init(
        date: Date = Calendar.current.startOfDay(for: .now),
        targetDistance: Double = 10.0,
        completedDistance: Double = 0,
        isAchieved: Bool = false
    ) {
        self.id = UUID()
        self.date = date
        self.targetDistance = targetDistance
        self.completedDistance = completedDistance
        self.isAchieved = isAchieved
    }
}
