import Foundation

enum ConnectionState: Equatable {
    case disconnected
    case scanning
    case connecting
    case connected
    case workoutActive

    var label: String {
        switch self {
        case .disconnected: "Rozłączono"
        case .scanning: "Szukam..."
        case .connecting: "Łączenie..."
        case .connected: "Połączono"
        case .workoutActive: "Trening aktywny"
        }
    }

    var color: String {
        switch self {
        case .disconnected: "red"
        case .scanning: "orange"
        case .connecting: "orange"
        case .connected: "green"
        case .workoutActive: "green"
        }
    }

    var isConnected: Bool {
        self == .connected || self == .workoutActive
    }
}
