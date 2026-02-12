import CoreBluetooth
import Foundation
import Observation

@Observable
final class DashboardViewModel {
    private let bleManager = BLEManager.shared
    private let workoutManager = WorkoutManager.shared
    private let goalsManager = GoalsManager.shared

    // MARK: - Connection

    var connectionState: ConnectionState { bleManager.connectionState }
    var deviceName: String? { bleManager.deviceName }
    var bluetoothState: CBManagerStateWrapper { .init(bleManager.bluetoothState) }

    // MARK: - Live Workout

    var isWorkoutActive: Bool { workoutManager.isWorkoutActive }
    var currentSpeed: Double { workoutManager.currentSpeed }
    var currentDistance: Double { workoutManager.currentDistance }
    var currentDuration: TimeInterval { workoutManager.currentDuration }
    var maxSpeed: Double { workoutManager.maxSpeed }
    var averageSpeed: Double { workoutManager.averageSpeed }
    var recentSpeedSamples: [SpeedSample] { workoutManager.recentSpeedSamples }
    var calories: Int? { workoutManager.calories }
    var heartRate: Int? { workoutManager.heartRate }
    var estimatedSteps: Int { workoutManager.steps }

    // MARK: - Goals

    var dailyProgress: Double { goalsManager.dailyProgress }
    var remainingDistance: Double { goalsManager.remainingDistance }
    var todayDistance: Double { goalsManager.todayGoal?.completedDistance ?? 0 }
    var targetDistance: Double {
        goalsManager.todayGoal?.targetDistance ?? AppSettings.shared.dailyGoalDistance
    }

    // MARK: - Weekly

    var weeklyDayStatus: [Bool] { goalsManager.weeklyDayStatus }
    var weeklyCompletedSessions: Int { goalsManager.weeklyCompletedSessions }
    var weeklyTarget: Int { AppSettings.shared.weeklySessionsTarget }
    var currentStreak: Int { goalsManager.currentStreak }
    var streakShields: Int { goalsManager.streakShields }

    // MARK: - Treadmill Control

    var canControlTreadmill: Bool { bleManager.canControl }
    var targetSpeed: Double { bleManager.targetSpeed }
    var supportedSpeedRange: SupportedSpeedRange? { bleManager.supportedSpeedRange }

    func startTreadmill() { bleManager.startTreadmill() }
    func stopTreadmill() { bleManager.stopTreadmill() }
    func increaseSpeed() { bleManager.increaseSpeed() }
    func decreaseSpeed() { bleManager.decreaseSpeed() }
    func setTargetSpeed(_ speed: Double) { bleManager.setTargetSpeed(speed) }

    // MARK: - Formatted

    var formattedDuration: String {
        let mins = Int(currentDuration) / 60
        let secs = Int(currentDuration) % 60
        return String(format: "%02d:%02d", mins, secs)
    }

    var formattedSpeed: String {
        String(format: "%.1f", currentSpeed)
    }

    var formattedDistance: String {
        String(format: "%.2f", currentDistance)
    }
}
