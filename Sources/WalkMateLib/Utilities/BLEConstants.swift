import CoreBluetooth

enum BLEConstants {
    // FTMS Service
    static let ftmsServiceUUID = CBUUID(string: "1826")

    // FTMS Characteristics
    static let treadmillDataUUID = CBUUID(string: "2ACD")
    static let trainingStatusUUID = CBUUID(string: "2AD3")
    static let fitnessMachineFeatureUUID = CBUUID(string: "2ACC")
    static let supportedSpeedRangeUUID = CBUUID(string: "2AD4")
    static let fitnessMachineControlPointUUID = CBUUID(string: "2AD9")
    static let fitnessMachineStatusUUID = CBUUID(string: "2ADA")

    // Heart Rate Service
    static let heartRateServiceUUID = CBUUID(string: "180D")
    static let heartRateMeasurementUUID = CBUUID(string: "2A37")

    // Device name prefix
    static let deviceNamePrefix = "FS-"

    // Reconnection
    static let initialReconnectDelay: TimeInterval = 1.0
    static let maxReconnectDelay: TimeInterval = 30.0
    static let reconnectMultiplier: Double = 2.0
}
