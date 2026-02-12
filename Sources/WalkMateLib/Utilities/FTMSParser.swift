import Foundation

enum FTMSParser {

    /// Parse Treadmill Data characteristic (0x2ACD) per Bluetooth SIG FTMS spec.
    /// Fields are variable-length based on flags — parsed sequentially.
    static func parseTreadmillData(_ data: Data) -> TreadmillData? {
        guard data.count >= 2 else { return nil } // minimum: 2 bytes for flags

        var result = TreadmillData()
        var offset = 0

        // Flags (uint16, little-endian)
        let flags = readUInt16(data, offset: &offset)

        // Bit 0: More Data — 0 = complete reading (speed present), 1 = continuation (skip)
        // Per FTMS spec, Instantaneous Speed is mandatory only when bit 0 = 0.
        // Some treadmills send alternating packets: full data (bit0=0) + status (bit0=1).
        if flags & 1 != 0 {
            return nil
        }

        guard offset + 2 <= data.count else { return nil }
        let rawSpeed = readUInt16(data, offset: &offset)
        result.instantaneousSpeed = Double(rawSpeed) * 0.01 // resolution 0.01 km/h

        // Bit 1: Average Speed present
        if flags & (1 << 1) != 0 {
            guard offset + 2 <= data.count else { return result }
            let avgSpeed = readUInt16(data, offset: &offset)
            result.averageSpeed = Double(avgSpeed) * 0.01
        }

        // Bit 2: Total Distance present (uint24, 1 meter)
        if flags & (1 << 2) != 0 {
            guard offset + 3 <= data.count else { return result }
            let dist = readUInt24(data, offset: &offset)
            result.totalDistance = Double(dist)
        }

        // Bit 3: Inclination (sint16) + Ramp Angle (sint16)
        if flags & (1 << 3) != 0 {
            guard offset + 4 <= data.count else { return result }
            let incl = readSInt16(data, offset: &offset)
            let ramp = readSInt16(data, offset: &offset)
            result.inclination = Double(incl) * 0.1
            result.rampAngle = Double(ramp) * 0.1
        }

        // Bit 4: Positive Elevation Gain (uint16) + Negative Elevation Gain (uint16)
        if flags & (1 << 4) != 0 {
            guard offset + 4 <= data.count else { return result }
            let posGain = readUInt16(data, offset: &offset)
            let negGain = readUInt16(data, offset: &offset)
            result.positiveElevationGain = Double(posGain) * 0.1
            result.negativeElevationGain = Double(negGain) * 0.1
        }

        // Bit 5: Instantaneous Pace (uint8, 0.1 km/min resolution)
        if flags & (1 << 5) != 0 {
            guard offset + 1 <= data.count else { return result }
            let pace = readUInt8(data, offset: &offset)
            result.instantaneousPace = Double(pace) * 0.1
        }

        // Bit 6: Average Pace (uint8)
        if flags & (1 << 6) != 0 {
            guard offset + 1 <= data.count else { return result }
            let avgPace = readUInt8(data, offset: &offset)
            result.averagePace = Double(avgPace) * 0.1
        }

        // Bit 7: Expended Energy — Total (uint16) + Per Hour (uint16) + Per Minute (uint8)
        if flags & (1 << 7) != 0 {
            guard offset + 5 <= data.count else { return result }
            let total = readUInt16(data, offset: &offset)
            let perHour = readUInt16(data, offset: &offset)
            let perMin = readUInt8(data, offset: &offset)
            result.totalEnergy = Int(total)
            result.energyPerHour = Int(perHour)
            result.energyPerMinute = Int(perMin)
        }

        // Bit 8: Heart Rate (uint8)
        if flags & (1 << 8) != 0 {
            guard offset + 1 <= data.count else { return result }
            let hr = readUInt8(data, offset: &offset)
            result.heartRate = Int(hr)
        }

        // Bit 9: Metabolic Equivalent (uint8, 0.1 resolution)
        if flags & (1 << 9) != 0 {
            guard offset + 1 <= data.count else { return result }
            let met = readUInt8(data, offset: &offset)
            result.metabolicEquivalent = Double(met) * 0.1
        }

        // Bit 10: Elapsed Time (uint16, seconds)
        if flags & (1 << 10) != 0 {
            guard offset + 2 <= data.count else { return result }
            let elapsed = readUInt16(data, offset: &offset)
            result.elapsedTime = Int(elapsed)
        }

        // Bit 11: Remaining Time (uint16)
        if flags & (1 << 11) != 0 {
            guard offset + 2 <= data.count else { return result }
            let remaining = readUInt16(data, offset: &offset)
            result.remainingTime = Int(remaining)
        }

        // Bit 12: Force on Belt (sint16) + Power Output (sint16)
        if flags & (1 << 12) != 0 {
            guard offset + 4 <= data.count else { return result }
            let force = readSInt16(data, offset: &offset)
            let power = readSInt16(data, offset: &offset)
            result.forceOnBelt = Double(force)
            result.powerOutput = Double(power)
        }

        return result
    }

    /// Parse Supported Speed Range characteristic (0x2AD4)
    static func parseSupportedSpeedRange(_ data: Data) -> SupportedSpeedRange? {
        guard data.count >= 6 else { return nil }
        var offset = 0
        let min = readUInt16(data, offset: &offset)
        let max = readUInt16(data, offset: &offset)
        let inc = readUInt16(data, offset: &offset)
        return SupportedSpeedRange(
            minimum: Double(min) * 0.01,
            maximum: Double(max) * 0.01,
            increment: Double(inc) * 0.01
        )
    }

    // MARK: - Binary Helpers

    private static func readUInt8(_ data: Data, offset: inout Int) -> UInt8 {
        let value = data[offset]
        offset += 1
        return value
    }

    private static func readUInt16(_ data: Data, offset: inout Int) -> UInt16 {
        let value = UInt16(data[offset]) | (UInt16(data[offset + 1]) << 8)
        offset += 2
        return value
    }

    private static func readSInt16(_ data: Data, offset: inout Int) -> Int16 {
        let raw = readUInt16(data, offset: &offset)
        return Int16(bitPattern: raw)
    }

    private static func readUInt24(_ data: Data, offset: inout Int) -> UInt32 {
        let value = UInt32(data[offset])
            | (UInt32(data[offset + 1]) << 8)
            | (UInt32(data[offset + 2]) << 16)
        offset += 3
        return value
    }
}
