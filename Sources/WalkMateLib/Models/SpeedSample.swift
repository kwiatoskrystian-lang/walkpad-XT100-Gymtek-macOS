import Foundation

struct SpeedSample: Codable, Identifiable {
    var id = UUID()
    let timestamp: TimeInterval // seconds since workout start
    let speed: Double // km/h
}
