import Foundation

struct Workout: Codable, Identifiable {
    var id: UUID
    var startDate: Date
    var endDate: Date?
    var duration: TimeInterval
    var distance: Double // km
    var averageSpeed: Double // km/h
    var maxSpeed: Double // km/h
    var steps: Int?
    var calories: Int?
    var speedSamplesData: Data?

    init(
        startDate: Date = .now,
        endDate: Date? = nil,
        duration: TimeInterval = 0,
        distance: Double = 0,
        averageSpeed: Double = 0,
        maxSpeed: Double = 0,
        steps: Int? = nil,
        calories: Int? = nil,
        speedSamples: [SpeedSample] = []
    ) {
        self.id = UUID()
        self.startDate = startDate
        self.endDate = endDate
        self.duration = duration
        self.distance = distance
        self.averageSpeed = averageSpeed
        self.maxSpeed = maxSpeed
        self.steps = steps
        self.calories = calories
        self.speedSamplesData = try? JSONEncoder().encode(speedSamples)
    }

    var speedSamples: [SpeedSample] {
        get {
            guard let data = speedSamplesData else { return [] }
            return (try? JSONDecoder().decode([SpeedSample].self, from: data)) ?? []
        }
        set {
            speedSamplesData = try? JSONEncoder().encode(newValue)
        }
    }
}
