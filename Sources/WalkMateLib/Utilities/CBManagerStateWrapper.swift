import CoreBluetooth

struct CBManagerStateWrapper {
    let state: CBManagerState
    init(_ state: CBManagerState) { self.state = state }

    var isBluetoothOff: Bool { state == .poweredOff }
    var isUnauthorized: Bool { state == .unauthorized }
    var isUnsupported: Bool { state == .unsupported }

    var statusMessage: String? {
        switch state {
        case .poweredOff: "Bluetooth jest wyłączony"
        case .unauthorized: "Brak uprawnień Bluetooth"
        case .unsupported: "Bluetooth nie jest obsługiwany"
        default: nil
        }
    }
}
