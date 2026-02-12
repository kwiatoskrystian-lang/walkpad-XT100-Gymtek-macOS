import Foundation
import Observation

// MARK: - Workout Session State Machine

enum WorkoutSessionState: Equatable {
    case idle
    case active
    case disconnectedGracePeriod(since: Date)
    case saving

    var isActive: Bool {
        switch self {
        case .active, .disconnectedGracePeriod: return true
        case .idle, .saving: return false
        }
    }
}

@Observable
final class WorkoutManager {
    static let shared = WorkoutManager()

    // MARK: - Public State

    private(set) var sessionState: WorkoutSessionState = .idle
    private(set) var currentSpeed: Double = 0
    private(set) var currentDistance: Double = 0 // km
    private(set) var currentDuration: TimeInterval = 0
    private(set) var maxSpeed: Double = 0
    private(set) var speedSamples: [SpeedSample] = []
    private(set) var calories: Int?
    private(set) var heartRate: Int?
    private(set) var steps: Int = 0

    var isWorkoutActive: Bool { sessionState.isActive }

    // MARK: - Private

    private var workoutStartDate: Date?
    private var zeroSpeedTimestamp: Date?
    private var lastSampleTime: Date?
    private var speedAccumulator: Double = 0
    private var speedCount: Int = 0
    private var elapsedTimer: Timer?
    private var autoSaveTimer: Timer?
    private var gracePeriodTimer: Timer?
    private var lastTotalDistance: Double?
    private var accumulatedDistance: Double = 0 // meters
    private var elapsedSeconds: Int = 0
    private var lastMilestoneKm: Int = 0
    private var calorieAccumulator: Double = 0
    private var stepAccumulator: Double = 0
    private var lastCalorieTime: Date?
    private var lastStepTime: Date?
    private var lastCoachingTime: Date?
    private var coachingMessageCount: Int = 0

    private let zeroSpeedTimeout: TimeInterval = 15
    private let gracePeriodTimeout: TimeInterval = 60
    private let autoSaveInterval: TimeInterval = 30
    private let sampleInterval: TimeInterval = 10
    private let minimumDistance: Double = 0.005 // km (5 meters)
    private let store = DataStore.shared

    var onWorkoutEnded: ((Workout) -> Void)?

    // MARK: - Init

    private init() {}

    func configure() {
        setupBLECallback()
        recoverInProgressWorkout()
    }

    // MARK: - BLE Integration

    private func setupBLECallback() {
        BLEManager.shared.onTreadmillDataUpdate = { [weak self] data in
            self?.handleTreadmillData(data)
        }
        BLEManager.shared.onDisconnectDuringWorkout = { [weak self] in
            self?.handleBLEDisconnect()
        }
        BLEManager.shared.onReconnectDuringWorkout = { [weak self] in
            self?.handleBLEReconnect()
        }
        BLEManager.shared.onHeartRateUpdate = { [weak self] hr in
            self?.heartRate = hr
        }
    }

    private func handleTreadmillData(_ data: TreadmillData) {
        currentSpeed = data.instantaneousSpeed
        heartRate = data.heartRate

        if let totalDist = data.totalDistance, sessionState.isActive {
            // Incremental distance: only add when counter increases.
            // Treadmill resets totalDistance to 0 when belt stops — this handles that.
            if let lastDist = lastTotalDistance, totalDist > lastDist {
                accumulatedDistance += (totalDist - lastDist)
                currentDistance = accumulatedDistance / 1000.0
                GoalsManager.shared.updateTodayDistance(currentDistance)
                checkDistanceMilestone()
            }
            lastTotalDistance = totalDist
        }

        // Bug 1 fix: IGNORE FTMS elapsed time for display — local timer is the single source of truth
        // FTMS elapsedTime arrives at irregular intervals causing jumps

        // Calorie & step calculation
        if data.isMoving, sessionState.isActive {
            let now = Date()
            if let lastTime = lastCalorieTime {
                let interval = now.timeIntervalSince(lastTime)
                if interval > 0, interval < 5 { // skip unreasonable gaps
                    let kcal = CalorieCalculator.calories(
                        speedKmh: data.instantaneousSpeed,
                        weightKg: AppSettings.shared.userWeight,
                        seconds: interval
                    )
                    calorieAccumulator += kcal
                    calories = Int(calorieAccumulator)
                }
            }
            lastCalorieTime = now

            // Steps: accumulate fractionally from speed each tick
            if let lastTime = lastStepTime {
                let interval = now.timeIntervalSince(lastTime)
                if interval > 0, interval < 5 {
                    let speedMs = data.instantaneousSpeed * 1000.0 / 3600.0
                    let heightCm = AppSettings.shared.userHeight
                    let speedFactor: Double
                    switch data.instantaneousSpeed {
                    case ..<2.0: speedFactor = 0.35
                    case ..<3.0: speedFactor = 0.35 + (data.instantaneousSpeed - 2.0) * 0.03
                    case ..<4.0: speedFactor = 0.38 + (data.instantaneousSpeed - 3.0) * 0.03
                    case ..<5.0: speedFactor = 0.41 + (data.instantaneousSpeed - 4.0) * 0.02
                    default:     speedFactor = 0.45
                    }
                    let stepLength = max(heightCm * speedFactor / 100.0, 0.4)
                    let stepsInInterval = speedMs * interval / stepLength
                    stepAccumulator += stepsInInterval
                    steps = Int(stepAccumulator)
                }
            }
            lastStepTime = now
        }

        if data.isMoving {
            zeroSpeedTimestamp = nil

            if sessionState == .idle {
                startWorkout()
            }

            if data.instantaneousSpeed > maxSpeed {
                maxSpeed = data.instantaneousSpeed
            }
            speedAccumulator += data.instantaneousSpeed
            speedCount += 1

            recordSpeedSampleIfNeeded()
            checkCoachingTip()

        } else if sessionState == .active {
            // Speed == 0 while connected
            if zeroSpeedTimestamp == nil {
                zeroSpeedTimestamp = Date()
                #if DEBUG
                print("[Workout] Speed dropped to 0, starting \(Int(zeroSpeedTimeout))s timeout")
                #endif
            } else if let zeroTime = zeroSpeedTimestamp,
                      Date().timeIntervalSince(zeroTime) > zeroSpeedTimeout {
                #if DEBUG
                print("[Workout] Speed == 0 for \(Int(zeroSpeedTimeout))s → ending workout")
                #endif
                endWorkout(reason: "speed_zero_timeout")
            }
        }
    }

    // MARK: - BLE Disconnect/Reconnect Handling (Bug 2 fix)

    private func handleBLEDisconnect() {
        guard sessionState == .active else { return }

        let now = Date()
        sessionState = .disconnectedGracePeriod(since: now)

        // Pause elapsed timer (don't invalidate — we may resume)
        elapsedTimer?.invalidate()
        elapsedTimer = nil

        #if DEBUG
        print("[Workout] BLE disconnected during workout → grace period \(Int(gracePeriodTimeout))s started")
        #endif

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.gracePeriodTimer?.invalidate()
            self.gracePeriodTimer = Timer.scheduledTimer(
                withTimeInterval: self.gracePeriodTimeout,
                repeats: false
            ) { [weak self] _ in
                guard let self else { return }
                guard case .disconnectedGracePeriod = self.sessionState else { return }
                #if DEBUG
                print("[Workout] Grace period expired → ending workout")
                #endif
                self.endWorkout(reason: "disconnect_grace_expired")
                NotificationManager.shared.sendWorkoutEndedByDisconnect()
            }
        }
    }

    private func handleBLEReconnect() {
        guard case .disconnectedGracePeriod = sessionState else { return }

        #if DEBUG
        print("[Workout] BLE reconnected during grace period → resuming workout")
        #endif

        gracePeriodTimer?.invalidate()
        gracePeriodTimer = nil
        sessionState = .active

        // Resume elapsed timer
        startElapsedTimer()
    }

    // MARK: - Workout Lifecycle

    private func startWorkout() {
        guard sessionState == .idle else { return }

        sessionState = .active
        workoutStartDate = Date()
        zeroSpeedTimestamp = nil
        maxSpeed = 0
        speedAccumulator = 0
        speedCount = 0
        speedSamples = []
        currentDistance = 0
        currentDuration = 0
        elapsedSeconds = 0
        accumulatedDistance = 0
        lastTotalDistance = BLEManager.shared.treadmillData.totalDistance
        calories = nil
        calorieAccumulator = 0
        lastCalorieTime = nil
        steps = 0
        stepAccumulator = 0
        lastStepTime = nil
        lastMilestoneKm = 0
        lastSampleTime = Date()
        lastCoachingTime = Date()
        coachingMessageCount = 0

        BLEManager.shared.setWorkoutActive(true)

        startElapsedTimer()
        startAutoSaveTimer()
        SoundManager.shared.play(.workoutStarted)

        #if DEBUG
        print("[Workout] Started at \(workoutStartDate!)")
        #endif
    }

    private func endWorkout(reason: String) {
        guard sessionState.isActive, let startDate = workoutStartDate else { return }

        sessionState = .saving

        #if DEBUG
        print("[Workout] Ending (reason: \(reason)) — distance: \(String(format: "%.3f", currentDistance)) km, duration: \(elapsedSeconds)s")
        #endif

        elapsedTimer?.invalidate()
        elapsedTimer = nil
        autoSaveTimer?.invalidate()
        autoSaveTimer = nil
        gracePeriodTimer?.invalidate()
        gracePeriodTimer = nil

        BLEManager.shared.setWorkoutActive(false)

        guard currentDistance >= minimumDistance else {
            #if DEBUG
            print("[Workout] Distance \(String(format: "%.4f", currentDistance)) km below minimum \(minimumDistance) km — discarding")
            #endif
            deleteInProgressFile()
            resetState()
            return
        }

        let avgSpeed = speedCount > 0 ? speedAccumulator / Double(speedCount) : 0

        let workout = Workout(
            startDate: startDate,
            endDate: Date(),
            duration: currentDuration,
            distance: currentDistance,
            averageSpeed: avgSpeed,
            maxSpeed: maxSpeed,
            steps: steps > 0 ? steps : nil,
            calories: calories,
            speedSamples: speedSamples
        )

        store.addWorkout(workout)
        SoundManager.shared.play(.workoutEnded)

        if AppSettings.shared.healthKitEnabled, HealthKitManager.shared.isAuthorized {
            HealthKitManager.shared.saveWorkout(workout)
        }

        #if DEBUG
        let count = store.completedWorkouts().count
        print("[Workout] ✅ Saved: \(String(format: "%.3f", workout.distance)) km, \(Int(workout.duration))s — total workouts: \(count)")
        #endif

        deleteInProgressFile()
        onWorkoutEnded?(workout)
        resetState()
    }

    private func resetState() {
        sessionState = .idle
        zeroSpeedTimestamp = nil
        workoutStartDate = nil
        lastTotalDistance = nil
        accumulatedDistance = 0
        currentSpeed = 0
        currentDistance = 0
        currentDuration = 0
        elapsedSeconds = 0
        maxSpeed = 0
        speedAccumulator = 0
        speedCount = 0
        speedSamples = []
        calories = nil
        calorieAccumulator = 0
        lastCalorieTime = nil
        steps = 0
        stepAccumulator = 0
        lastStepTime = nil
        heartRate = nil
        lastMilestoneKm = 0
        lastCoachingTime = nil
        coachingMessageCount = 0
    }

    // MARK: - Elapsed Timer (Bug 1 fix: single source of truth)

    private func startElapsedTimer() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.elapsedTimer?.invalidate()
            self.elapsedTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
                guard let self, self.sessionState == .active else { return }
                self.elapsedSeconds += 1
                self.currentDuration = TimeInterval(self.elapsedSeconds)
            }
        }
    }

    // MARK: - Auto-Save (Bug 3 fix: crash-safe persistence)

    private func startAutoSaveTimer() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.autoSaveTimer?.invalidate()
            self.autoSaveTimer = Timer.scheduledTimer(withTimeInterval: self.autoSaveInterval, repeats: true) { [weak self] _ in
                self?.saveInProgressWorkout()
            }
        }
    }

    private var inProgressFileURL: URL {
        ProfileManager.shared.activeStorageDir
            .appendingPathComponent("workout_in_progress.json")
    }

    private func saveInProgressWorkout() {
        guard sessionState.isActive, let startDate = workoutStartDate else { return }

        let avgSpeed = speedCount > 0 ? speedAccumulator / Double(speedCount) : 0
        let workout = Workout(
            startDate: startDate,
            endDate: Date(),
            duration: currentDuration,
            distance: currentDistance,
            averageSpeed: avgSpeed,
            maxSpeed: maxSpeed,
            steps: steps > 0 ? steps : nil,
            calories: calories,
            speedSamples: speedSamples
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(workout) {
            try? data.write(to: inProgressFileURL, options: .atomic)
            #if DEBUG
            print("[Workout] Auto-saved in-progress: \(String(format: "%.3f", currentDistance)) km, \(elapsedSeconds)s")
            #endif
        }
    }

    private func deleteInProgressFile() {
        try? FileManager.default.removeItem(at: inProgressFileURL)
    }

    func recoverInProgressWorkout() {
        let url = inProgressFileURL
        guard FileManager.default.fileExists(atPath: url.path) else { return }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        guard let data = try? Data(contentsOf: url),
              let recovered = try? decoder.decode(Workout.self, from: data) else {
            // Corrupted file — delete silently
            deleteInProgressFile()
            #if DEBUG
            print("[Workout] ⚠️ Found corrupted workout_in_progress.json — deleted")
            #endif
            return
        }

        guard recovered.distance >= minimumDistance else {
            deleteInProgressFile()
            #if DEBUG
            print("[Workout] Recovered workout below minimum distance — discarded")
            #endif
            return
        }

        store.addWorkout(recovered)
        deleteInProgressFile()

        #if DEBUG
        print("[Workout] ✅ Recovered crashed workout: \(String(format: "%.3f", recovered.distance)) km, \(Int(recovered.duration))s")
        #endif
    }

    // MARK: - Distance Milestones

    private func checkDistanceMilestone() {
        let km = Int(currentDistance)
        guard km > lastMilestoneKm, km >= 1, km <= 20 else { return }
        lastMilestoneKm = km
        NotificationManager.shared.sendDistanceMilestone(km: km, elapsedSeconds: elapsedSeconds)
        #if DEBUG
        print("[Workout] Milestone: \(km) km reached at \(elapsedSeconds)s")
        #endif
    }

    // MARK: - Speed Samples

    private func recordSpeedSampleIfNeeded() {
        guard let lastSample = lastSampleTime,
              Date().timeIntervalSince(lastSample) >= sampleInterval else { return }

        let sample = SpeedSample(timestamp: TimeInterval(elapsedSeconds), speed: currentSpeed)
        speedSamples.append(sample)
        lastSampleTime = Date()
    }

    var recentSpeedSamples: [SpeedSample] {
        Array(speedSamples.suffix(60))
    }

    var averageSpeed: Double {
        speedCount > 0 ? speedAccumulator / Double(speedCount) : 0
    }

    // MARK: - Live Coaching

    private func checkCoachingTip() {
        guard let lastCoaching = lastCoachingTime,
              Date().timeIntervalSince(lastCoaching) >= 300, // every 5 minutes
              coachingMessageCount < 6 // max 6 tips per workout
        else { return }

        let tip = coachingTip()
        guard let tip else { return }

        lastCoachingTime = Date()
        coachingMessageCount += 1
        NotificationManager.shared.sendCoachingTip(tip)
    }

    private func coachingTip() -> String? {
        let avgSpeed = averageSpeed
        let mins = Int(currentDuration) / 60

        // Time-based tips
        if mins == 5 { return "5 minut za tobą! Rozgrzewka zaliczona 🔥" }
        if mins == 15 { return "15 minut! Świetnie się trzymasz 💪" }
        if mins == 30 { return "Pół godziny! Jesteś maszyną 🏆" }
        if mins == 45 { return "45 minut! Prawie godzina — niesamowite!" }
        if mins == 60 { return "Godzina marszu! Legenda! 🎉" }

        // Speed-based tips
        if currentSpeed > 5.5 && avgSpeed < 5.0 {
            return "Szybkie tempo! Utrzymaj je jeszcze chwilę ⚡"
        }
        if currentSpeed < 3.0 && avgSpeed > 4.0 && currentDistance > 0.5 {
            return "Trochę zwolniłeś — daj gazu! 🚀"
        }
        if avgSpeed >= 5.0 {
            return String(format: "Średnia %.1f km/h — imponujące tempo! 🏃", avgSpeed)
        }

        // Distance-based tips
        if currentDistance > 1.0 && currentDistance < 1.1 {
            return "Pierwszy kilometr za tobą! Tak trzymaj 👏"
        }

        return nil
    }
}
