import Foundation

struct TreadmillData {
    var instantaneousSpeed: Double = 0 // km/h
    var averageSpeed: Double? // km/h
    var totalDistance: Double? // meters
    var inclination: Double? // percent
    var rampAngle: Double? // degree
    var positiveElevationGain: Double? // meters
    var negativeElevationGain: Double? // meters
    var instantaneousPace: Double? // km/min
    var averagePace: Double? // km/min
    var totalEnergy: Int? // kcal
    var energyPerHour: Int? // kcal
    var energyPerMinute: Int? // kcal
    var heartRate: Int? // bpm
    var metabolicEquivalent: Double?
    var elapsedTime: Int? // seconds
    var remainingTime: Int? // seconds
    var forceOnBelt: Double? // newton
    var powerOutput: Double? // watt

    var isMoving: Bool { instantaneousSpeed > 0 }
}

struct SupportedSpeedRange {
    let minimum: Double // km/h
    let maximum: Double // km/h
    let increment: Double // km/h
}
