import CoreBluetooth

// MARK: - CBCentralManagerDelegate

extension BLEManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        bluetoothState = central.state
        print("[BLE] Central state: \(central.state.rawValue)")

        switch central.state {
        case .poweredOn:
            print("[BLE] Bluetooth ON — scanning for FTMS...")
            startScanning()
        case .poweredOff, .unauthorized, .unsupported:
            print("[BLE] Bluetooth unavailable: \(central.state.rawValue)")
            connectionState = .disconnected
            peripheral = nil
        default:
            break
        }
    }

    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        let name = peripheral.name
            ?? advertisementData[CBAdvertisementDataLocalNameKey] as? String
            ?? ""

        guard name.hasPrefix(BLEConstants.deviceNamePrefix) else {
            print("[BLE] Skipping device: '\(name)' (not FS- prefix)")
            return
        }

        print("[BLE] Found treadmill: '\(name)' — connecting...")
        deviceName = name
        connectToPeripheral(peripheral)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("[BLE] ✅ Connected to \(peripheral.name ?? "unknown")")
        connectionState = .connected
        resetReconnectDelay()
        shouldReconnect = true
        discoverServices()

        DispatchQueue.main.async { [weak self] in
            self?.onReconnectDuringWorkout?()
        }
    }

    func centralManager(
        _ central: CBCentralManager,
        didFailToConnect peripheral: CBPeripheral,
        error: Error?
    ) {
        connectionState = .disconnected
        scheduleReconnect()
    }

    func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: Error?
    ) {
        let wasWorkoutActive = connectionState == .workoutActive
        connectionState = .disconnected

        if wasWorkoutActive {
            shouldReconnect = true
            DispatchQueue.main.async { [weak self] in
                self?.onDisconnectDuringWorkout?()
            }
        }

        scheduleReconnect()
    }
}
