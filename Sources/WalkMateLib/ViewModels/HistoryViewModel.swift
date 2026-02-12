import Foundation
import Observation

@Observable
final class HistoryViewModel {
    private let store = DataStore.shared
    private(set) var workouts: [Workout] = []
    var expandedWorkoutID: UUID?

    func refresh() {
        workouts = store.completedWorkouts().sorted { $0.startDate > $1.startDate }
    }

    func toggleExpanded(_ id: UUID) {
        if expandedWorkoutID == id {
            expandedWorkoutID = nil
        } else {
            expandedWorkoutID = id
        }
    }

    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pl_PL")
        formatter.dateFormat = "d MMM yyyy, HH:mm"
        return formatter.string(from: date)
    }

    func formattedDuration(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
