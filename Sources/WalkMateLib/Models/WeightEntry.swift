import Foundation

struct WeightEntry: Codable, Identifiable {
    var id: UUID
    var date: Date
    var weight: Double // kg

    init(date: Date = .now, weight: Double) {
        self.id = UUID()
        self.date = date
        self.weight = weight
    }
}
