import CoreBluetooth
import Foundation

// MARK: - CBPeripheralDelegate

extension BLEManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }

        for service in services {
            let characteristicUUIDs: [CBUUID]

            switch service.uuid {
            case BLEConstants.ftmsServiceUUID:
                characteristicUUIDs = [
                    BLEConstants.treadmillDataUUID,
                    BLEConstants.trainingStatusUUID,
                    BLEConstants.fitnessMachineFeatureUUID,
                    BLEConstants.supportedSpeedRangeUUID,
                    BLEConstants.fitnessMachineControlPointUUID,
                    BLEConstants.fitnessMachineStatusUUID,
                ]
            case BLEConstants.heartRateServiceUUID:
                characteristicUUIDs = [BLEConstants.heartRateMeasurementUUID]
            default:
                continue
            }

            peripheral.discoverCharacteristics(characteristicUUIDs, for: service)
        }
    }

    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverCharacteristicsFor service: CBService,
        error: Error?
    ) {
        guard let characteristics = service.characteristics else { return }

        for characteristic in characteristics {
            switch characteristic.uuid {
            case BLEConstants.treadmillDataUUID,
                 BLEConstants.trainingStatusUUID,
                 BLEConstants.fitnessMachineStatusUUID,
                 BLEConstants.heartRateMeasurementUUID:
                peripheral.setNotifyValue(true, for: characteristic)

            case BLEConstants.fitnessMachineFeatureUUID,
                 BLEConstants.supportedSpeedRangeUUID:
                peripheral.readValue(for: characteristic)

            case BLEConstants.fitnessMachineControlPointUUID:
                // Store reference for writing commands
                DispatchQueue.main.async { [weak self] in
                    self?.controlPointCharacteristic = characteristic
                    #if DEBUG
                    print("[BLE] Control Point characteristic discovered")
                    #endif
                }
                // Enable indications for response codes
                peripheral.setNotifyValue(true, for: characteristic)

            default:
                break
            }
        }
    }

    func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateValueFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        guard let data = characteristic.value else { return }

        switch characteristic.uuid {
        case BLEConstants.treadmillDataUUID:
            print("[BLE] Raw FTMS packet (\(data.count) bytes): \(data.map { String(format: "%02X", $0) }.joined(separator: " "))")
            if let parsed = FTMSParser.parseTreadmillData(data) {
                print("[BLE] Parsed: speed=\(parsed.instantaneousSpeed) km/h, dist=\(parsed.totalDistance.map { String(format: "%.0f", $0) } ?? "nil")m, elapsed=\(parsed.elapsedTime.map(String.init) ?? "nil")s, moving=\(parsed.isMoving)")
                DispatchQueue.main.async { [weak self] in
                    self?.treadmillData = parsed
                    self?.onTreadmillDataUpdate?(parsed)
                }
            } else {
                print("[BLE] ⚠️ Failed to parse FTMS packet")
            }

        case BLEConstants.supportedSpeedRangeUUID:
            if let range = FTMSParser.parseSupportedSpeedRange(data) {
                DispatchQueue.main.async { [weak self] in
                    self?.supportedSpeedRange = range
                }
            }

        case BLEConstants.heartRateMeasurementUUID:
            if let hr = CalorieCalculator.parseHeartRate(data) {
                #if DEBUG
                print("[BLE] Heart Rate: \(hr) bpm")
                #endif
                DispatchQueue.main.async { [weak self] in
                    self?.treadmillData.heartRate = hr
                    self?.onHeartRateUpdate?(hr)
                }
            }

        case BLEConstants.fitnessMachineControlPointUUID:
            // Response format: [0x80, requestOpCode, resultCode]
            if data.count >= 3, data[0] == 0x80 {
                let opCode = data[1]
                let result = data[2]
                let success = result == 0x01

                #if DEBUG
                let opNames: [UInt8: String] = [
                    0x00: "Request Control", 0x01: "Reset", 0x02: "Set Target Speed",
                    0x07: "Start/Resume", 0x08: "Stop/Pause"
                ]
                let resultNames: [UInt8: String] = [
                    0x01: "Success", 0x02: "Not Supported", 0x03: "Invalid Parameter",
                    0x04: "Operation Failed", 0x05: "Control Not Permitted"
                ]
                let opName = opNames[opCode] ?? String(format: "0x%02X", opCode)
                let resultName = resultNames[result] ?? String(format: "0x%02X", result)
                print("[BLE] ← CP response: \(opName) → \(resultName)")
                #endif

                if opCode == 0x00, success { // Request Control succeeded
                    DispatchQueue.main.async { [weak self] in
                        self?.hasControl = true
                    }
                }
            }

        default:
            break
        }
    }
}
