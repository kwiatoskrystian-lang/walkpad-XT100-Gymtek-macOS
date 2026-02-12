import CoreBluetooth
import Foundation
import Observation

@Observable
final class BLEManager: NSObject {
    static let shared = BLEManager()

    // MARK: - Published State

    // Writable from delegate extensions in BLECentralDelegate/BLEPeripheralDelegate
    var connectionState: ConnectionState = .disconnected
    var treadmillData = TreadmillData()
    var deviceName: String?
    var supportedSpeedRange: SupportedSpeedRange?
    var bluetoothState: CBManagerState = .unknown

    // MARK: - Internal (accessed by delegate extensions)

    var centralManager: CBCentralManager!
    var peripheral: CBPeripheral?
    let bleQueue = DispatchQueue(label: "com.walkmate.ble", qos: .userInitiated)
    var reconnectDelay: TimeInterval = BLEConstants.initialReconnectDelay
    var reconnectTimer: Timer?
    var shouldReconnect = true

    var onTreadmillDataUpdate: ((TreadmillData) -> Void)?
    var onDisconnectDuringWorkout: (() -> Void)?
    var onReconnectDuringWorkout: (() -> Void)?
    var onHeartRateUpdate: ((Int) -> Void)?

    /// FTMS Control Point characteristic (for sending commands to treadmill)
    var controlPointCharacteristic: CBCharacteristic?
    var hasControl: Bool = false
    var targetSpeed: Double = 0 // km/h — last set target

    // MARK: - Init

    private override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: bleQueue)
    }

    // MARK: - Public Methods

    func startScanning() {
        guard centralManager.state == .poweredOn else { return }
        guard connectionState == .disconnected else { return }

        connectionState = .scanning
        centralManager.scanForPeripherals(
            withServices: [BLEConstants.ftmsServiceUUID],
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        )
    }

    func stopScanning() {
        centralManager.stopScan()
    }

    func disconnect() {
        shouldReconnect = false
        reconnectTimer?.invalidate()
        reconnectTimer = nil
        if let peripheral {
            centralManager.cancelPeripheralConnection(peripheral)
        }
        connectionState = .disconnected
    }

    func forgetDevice() {
        disconnect()
        peripheral = nil
        deviceName = nil
        treadmillData = TreadmillData()
        controlPointCharacteristic = nil
        hasControl = false
        targetSpeed = 0
    }

    func setWorkoutActive(_ active: Bool) {
        if active && connectionState == .connected {
            connectionState = .workoutActive
        } else if !active && connectionState == .workoutActive {
            connectionState = .connected
        }
    }

    // MARK: - Internal Helpers

    func connectToPeripheral(_ discovered: CBPeripheral) {
        self.peripheral = discovered
        discovered.delegate = self
        connectionState = .connecting
        centralManager.stopScan()
        centralManager.connect(discovered, options: nil)
    }

    func scheduleReconnect() {
        guard shouldReconnect else { return }

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.reconnectTimer?.invalidate()
            self.reconnectTimer = Timer.scheduledTimer(
                withTimeInterval: self.reconnectDelay,
                repeats: false
            ) { [weak self] _ in
                self?.startScanning()
            }
            self.reconnectDelay = min(
                self.reconnectDelay * BLEConstants.reconnectMultiplier,
                BLEConstants.maxReconnectDelay
            )
        }
    }

    func resetReconnectDelay() {
        reconnectDelay = BLEConstants.initialReconnectDelay
    }

    func discoverServices() {
        peripheral?.discoverServices([
            BLEConstants.ftmsServiceUUID,
            BLEConstants.heartRateServiceUUID
        ])
    }

    // MARK: - FTMS Treadmill Control

    /// Request control of the treadmill (must be called before other commands)
    func requestControl() {
        writeControlPoint(Data([0x00]))
    }

    /// Start or resume the treadmill belt
    func startTreadmill() {
        if !hasControl { requestControl() }
        // Small delay to let request control complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.writeControlPoint(Data([0x07]))
        }
    }

    /// Stop the treadmill belt
    func stopTreadmill() {
        writeControlPoint(Data([0x08, 0x01])) // 0x01 = stop
    }

    /// Pause the treadmill belt
    func pauseTreadmill() {
        writeControlPoint(Data([0x08, 0x02])) // 0x02 = pause
    }

    /// Set target speed in km/h. FTMS uses 0.01 km/h resolution.
    func setTargetSpeed(_ speedKmh: Double) {
        guard speedKmh >= 0 else { return }

        // Clamp to supported range
        let clamped: Double
        if let range = supportedSpeedRange {
            clamped = min(max(speedKmh, range.minimum), range.maximum)
        } else {
            clamped = min(max(speedKmh, 0), 10.0)
        }

        // FTMS speed unit: 0.01 km/h
        let rawSpeed = UInt16(clamped * 100)
        var data = Data([0x02])
        data.append(UInt8(rawSpeed & 0xFF))
        data.append(UInt8(rawSpeed >> 8))
        writeControlPoint(data)

        DispatchQueue.main.async { [weak self] in
            self?.targetSpeed = clamped
        }

        #if DEBUG
        print("[BLE] Set target speed: \(clamped) km/h (raw: \(rawSpeed))")
        #endif
    }

    /// Increase speed by increment (default from supported range or 0.5 km/h)
    func increaseSpeed() {
        let increment = supportedSpeedRange?.increment ?? 0.5
        let newSpeed = targetSpeed + increment
        if !hasControl { requestControl() }
        DispatchQueue.main.asyncAfter(deadline: .now() + (hasControl ? 0 : 0.3)) { [weak self] in
            self?.setTargetSpeed(newSpeed)
        }
    }

    /// Decrease speed by increment
    func decreaseSpeed() {
        let increment = supportedSpeedRange?.increment ?? 0.5
        let newSpeed = max(0, targetSpeed - increment)
        setTargetSpeed(newSpeed)
    }

    /// Whether the treadmill supports control commands
    var canControl: Bool {
        controlPointCharacteristic != nil && connectionState != .disconnected
    }

    private func writeControlPoint(_ data: Data) {
        guard let peripheral, let cp = controlPointCharacteristic else {
            #if DEBUG
            print("[BLE] Control Point not available")
            #endif
            return
        }
        peripheral.writeValue(data, for: cp, type: .withResponse)
        #if DEBUG
        print("[BLE] → CP write: \(data.map { String(format: "%02X", $0) }.joined(separator: " "))")
        #endif
    }
}
