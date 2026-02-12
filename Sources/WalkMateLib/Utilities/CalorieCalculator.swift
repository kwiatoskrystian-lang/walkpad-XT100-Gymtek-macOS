import Foundation

enum CalorieCalculator {

    // MARK: - MET for Walkpad (desk walking)

    /// MET values calibrated for under-desk walkpad walking.
    /// Lower than regular walking due to: no arm swing, flat surface, desk posture.
    /// Based on Compendium of Physical Activities with ~0.3 MET desk-walking offset.
    static func metForWalkpadSpeed(_ kmh: Double) -> Double {
        switch kmh {
        case ..<0.5:  return 1.3   // barely shuffling
        case ..<1.0:  return 1.8
        case ..<2.0:  return 2.0 + (kmh - 1.0) * 0.3   // 2.0 → 2.3
        case ..<3.0:  return 2.3 + (kmh - 2.0) * 0.5   // 2.3 → 2.8
        case ..<4.0:  return 2.8 + (kmh - 3.0) * 0.5   // 2.8 → 3.3
        case ..<5.0:  return 3.3 + (kmh - 4.0) * 0.5   // 3.3 → 3.8
        case ..<6.0:  return 3.8 + (kmh - 5.0) * 0.7   // 3.8 → 4.5
        default:      return 5.0   // fast walk / light jog
        }
    }

    // MARK: - Calorie Formulas

    /// MET-based calories per second.
    /// Formula: kcal/min = MET × weight(kg) × 3.5 / 200
    static func caloriesPerSecond(met: Double, weightKg: Double) -> Double {
        met * weightKg * 3.5 / 200.0 / 60.0
    }

    /// Convenience: calories for a given speed, weight, and time interval.
    static func calories(speedKmh: Double, weightKg: Double, seconds: Double) -> Double {
        let met = metForWalkpadSpeed(speedKmh)
        return caloriesPerSecond(met: met, weightKg: weightKg) * seconds
    }

    // MARK: - Step Estimation

    /// Estimate steps from distance, height, and average speed.
    /// Step length varies with walking speed — shorter steps at walkpad speeds (2-4 km/h).
    /// Factor: 0.35 at 2 km/h → 0.45 at 6+ km/h (interpolated).
    static func estimateSteps(distanceKm: Double, heightCm: Double, avgSpeedKmh: Double = 3.5) -> Int {
        let speedFactor: Double
        switch avgSpeedKmh {
        case ..<2.0: speedFactor = 0.35
        case ..<3.0: speedFactor = 0.35 + (avgSpeedKmh - 2.0) * 0.03  // 0.35 → 0.38
        case ..<4.0: speedFactor = 0.38 + (avgSpeedKmh - 3.0) * 0.03  // 0.38 → 0.41
        case ..<5.0: speedFactor = 0.41 + (avgSpeedKmh - 4.0) * 0.02  // 0.41 → 0.43
        default:     speedFactor = 0.45
        }
        let stepLengthM = max(heightCm * speedFactor / 100.0, 0.4)
        return Int(distanceKm * 1000.0 / stepLengthM)
    }

    // MARK: - BLE Heart Rate Parsing

    /// Parse BLE Heart Rate Measurement characteristic (UUID 0x2A37).
    /// Handles both UINT8 and UINT16 HR formats per Bluetooth SIG spec.
    static func parseHeartRate(_ data: Data) -> Int? {
        guard data.count >= 2 else { return nil }
        let flags = data[0]

        let hr: Int
        if flags & 1 == 0 {
            // UINT8 format
            hr = Int(data[1])
        } else {
            // UINT16 format
            guard data.count >= 3 else { return nil }
            hr = Int(data[1]) | (Int(data[2]) << 8)
        }

        // Sanity check: valid HR range
        guard hr > 30 && hr < 250 else { return nil }
        return hr
    }
}
