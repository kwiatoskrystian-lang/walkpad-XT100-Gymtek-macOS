import Foundation
import HealthKit
import Observation

@Observable
final class HealthKitManager {
    static let shared = HealthKitManager()

    private let healthStore = HKHealthStore()

    private(set) var isAvailable: Bool
    private(set) var isAuthorized: Bool = false
    private(set) var lastError: String?
    private(set) var isSyncing: Bool = false

    private let workoutType = HKWorkoutType.workoutType()
    private let energyType = HKQuantityType(.activeEnergyBurned)
    private let distanceType = HKQuantityType(.distanceWalkingRunning)

    private init() {
        isAvailable = HKHealthStore.isHealthDataAvailable()
    }

    // MARK: - Authorization

    func requestAuthorization() {
        guard isAvailable else {
            lastError = "HealthKit niedostępny na tym urządzeniu"
            return
        }

        let typesToShare: Set<HKSampleType> = [workoutType, energyType, distanceType]

        healthStore.requestAuthorization(toShare: typesToShare, read: nil) { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    self?.isAuthorized = true
                    self?.lastError = nil
                    #if DEBUG
                    print("[HealthKit] Autoryzacja przyznana")
                    #endif
                } else {
                    self?.isAuthorized = false
                    self?.lastError = error?.localizedDescription ?? "Odmowa autoryzacji HealthKit"
                    #if DEBUG
                    print("[HealthKit] Autoryzacja odrzucona: \(error?.localizedDescription ?? "unknown")")
                    #endif
                }
            }
        }
    }

    // MARK: - Save Workout

    func saveWorkout(_ workout: Workout) {
        guard isAvailable, isAuthorized else { return }

        let start = workout.startDate
        let end = workout.endDate ?? Date()
        let distance = HKQuantity(unit: .meterUnit(with: .kilo), doubleValue: workout.distance)
        let energy = HKQuantity(unit: .kilocalorie(), doubleValue: Double(workout.calories ?? 0))

        let config = HKWorkoutConfiguration()
        config.activityType = .walking
        config.locationType = .indoor

        let builder = HKWorkoutBuilder(healthStore: healthStore, configuration: config, device: nil)

        builder.beginCollection(withStart: start) { [weak self] success, error in
            guard success else {
                DispatchQueue.main.async {
                    self?.lastError = "Błąd rozpoczęcia zapisu: \(error?.localizedDescription ?? "")"
                }
                return
            }

            var samples: [HKSample] = []

            // Distance sample
            if workout.distance > 0 {
                let distanceSample = HKQuantitySample(
                    type: self!.distanceType,
                    quantity: distance,
                    start: start,
                    end: end
                )
                samples.append(distanceSample)
            }

            // Energy sample
            if let cal = workout.calories, cal > 0 {
                let energySample = HKQuantitySample(
                    type: self!.energyType,
                    quantity: energy,
                    start: start,
                    end: end
                )
                samples.append(energySample)
            }

            let addSamplesAndFinish = { [weak self] in
                if !samples.isEmpty {
                    builder.add(samples) { _, _ in }
                }

                builder.endCollection(withEnd: end) { success, _ in
                    guard success else { return }

                    let metadata: [String: Any] = [
                        "WalkMateID": workout.id.uuidString,
                        HKMetadataKeyIndoorWorkout: true
                    ]

                    builder.addMetadata(metadata) { _, _ in
                        builder.finishWorkout { hkWorkout, error in
                            DispatchQueue.main.async {
                                if let hkWorkout {
                                    self?.lastError = nil
                                    #if DEBUG
                                    print("[HealthKit] Trening zapisany: \(hkWorkout.totalDistance?.doubleValue(for: .meterUnit(with: .kilo)) ?? 0) km")
                                    #endif
                                } else {
                                    self?.lastError = "Błąd zapisu: \(error?.localizedDescription ?? "")"
                                    #if DEBUG
                                    print("[HealthKit] Błąd zapisu: \(error?.localizedDescription ?? "unknown")")
                                    #endif
                                }
                            }
                        }
                    }
                }
            }

            addSamplesAndFinish()
        }
    }

    // MARK: - Historical Sync

    func syncHistoricalWorkouts() {
        guard isAvailable, isAuthorized else { return }

        isSyncing = true
        lastError = nil

        let workouts = DataStore.shared.completedWorkouts()
        let group = DispatchGroup()
        var syncedCount = 0
        var errorCount = 0

        // Check which workouts already exist in HealthKit by WalkMateID
        let predicate = HKQuery.predicateForObjects(from: HKSource.default())
        let query = HKSampleQuery(
            sampleType: workoutType,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: nil
        ) { [weak self] _, results, error in
            guard let self else { return }

            // Collect existing WalkMateIDs
            var existingIDs = Set<String>()
            if let hkWorkouts = results as? [HKWorkout] {
                for hkWorkout in hkWorkouts {
                    if let wmID = hkWorkout.metadata?["WalkMateID"] as? String {
                        existingIDs.insert(wmID)
                    }
                }
            }

            // Filter workouts not yet synced
            let toSync = workouts.filter { !existingIDs.contains($0.id.uuidString) }

            if toSync.isEmpty {
                DispatchQueue.main.async {
                    self.isSyncing = false
                    self.lastError = nil
                    #if DEBUG
                    print("[HealthKit] Wszystkie treningi już zsynchronizowane")
                    #endif
                }
                return
            }

            #if DEBUG
            print("[HealthKit] Synchronizuję \(toSync.count) treningów...")
            #endif

            for workout in toSync {
                group.enter()
                self.saveWorkoutSync(workout) { success in
                    if success {
                        syncedCount += 1
                    } else {
                        errorCount += 1
                    }
                    group.leave()
                }
            }

            group.notify(queue: .main) {
                self.isSyncing = false
                if errorCount > 0 {
                    self.lastError = "Zsynchronizowano \(syncedCount), błędy: \(errorCount)"
                } else {
                    self.lastError = nil
                }
                #if DEBUG
                print("[HealthKit] Synchronizacja zakończona: \(syncedCount) ok, \(errorCount) błędów")
                #endif
            }
        }

        healthStore.execute(query)
    }

    private func saveWorkoutSync(_ workout: Workout, completion: @escaping (Bool) -> Void) {
        let start = workout.startDate
        let end = workout.endDate ?? Date()

        let config = HKWorkoutConfiguration()
        config.activityType = .walking
        config.locationType = .indoor

        let builder = HKWorkoutBuilder(healthStore: healthStore, configuration: config, device: nil)

        builder.beginCollection(withStart: start) { [weak self] success, _ in
            guard success, let self else {
                completion(false)
                return
            }

            var samples: [HKSample] = []

            if workout.distance > 0 {
                let distanceSample = HKQuantitySample(
                    type: self.distanceType,
                    quantity: HKQuantity(unit: .meterUnit(with: .kilo), doubleValue: workout.distance),
                    start: start,
                    end: end
                )
                samples.append(distanceSample)
            }

            if let cal = workout.calories, cal > 0 {
                let energySample = HKQuantitySample(
                    type: self.energyType,
                    quantity: HKQuantity(unit: .kilocalorie(), doubleValue: Double(cal)),
                    start: start,
                    end: end
                )
                samples.append(energySample)
            }

            if !samples.isEmpty {
                builder.add(samples) { _, _ in }
            }

            builder.endCollection(withEnd: end) { success, _ in
                guard success else {
                    completion(false)
                    return
                }

                let metadata: [String: Any] = [
                    "WalkMateID": workout.id.uuidString,
                    HKMetadataKeyIndoorWorkout: true
                ]

                builder.addMetadata(metadata) { _, _ in
                    builder.finishWorkout { hkWorkout, _ in
                        completion(hkWorkout != nil)
                    }
                }
            }
        }
    }
}
