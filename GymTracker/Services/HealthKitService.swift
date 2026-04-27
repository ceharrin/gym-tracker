import Foundation
import HealthKit

enum HealthKitAuthorizationScope: Equatable {
    case workoutsWrite
    case bodyWeightWrite
    case enrichmentRead
}

struct HealthKitWorkoutPayload {
    let localWorkoutID: UUID
    let title: String
    let startDate: Date
    let endDate: Date
    let activityType: HKWorkoutActivityType
    let notes: String?
    let activitySummary: String
    let energyLevel: Int
}

struct HealthKitWorkoutSyncResult {
    let workoutUUID: UUID
}

struct HealthKitBodyWeightPayload {
    let localMeasurementID: UUID
    let date: Date
    let weightKg: Double
}

struct HealthKitBodyWeightSample {
    let uuid: UUID
    let date: Date
    let weightKg: Double
}

struct HealthKitHeartRateSample {
    let date: Date
    let beatsPerMinute: Double
}

struct WorkoutHeartRateSummary: Equatable {
    let averageBPM: Int
    let maxBPM: Int
    let sampleCount: Int
}

protocol HealthKitServiceProtocol {
    var isAvailable: Bool { get }
    func requestAuthorization(for scope: HealthKitAuthorizationScope) async throws
    func saveWorkout(_ payload: HealthKitWorkoutPayload) async throws -> HealthKitWorkoutSyncResult
    func saveBodyWeight(_ payload: HealthKitBodyWeightPayload) async throws -> UUID
    func fetchBodyWeightSamples(since: Date?) async throws -> [HealthKitBodyWeightSample]
    func fetchHeartRateSamples(from: Date, to: Date) async throws -> [HealthKitHeartRateSample]
}

final class LiveHealthKitService: HealthKitServiceProtocol {
    private let store = HKHealthStore()

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    func requestAuthorization(for scope: HealthKitAuthorizationScope) async throws {
        let sets = authorizationSets(for: scope)
        try await store.requestAuthorization(toShare: sets.share, read: sets.read)
    }

    func saveWorkout(_ payload: HealthKitWorkoutPayload) async throws -> HealthKitWorkoutSyncResult {
        let workout = HKWorkout(
            activityType: payload.activityType,
            start: payload.startDate,
            end: payload.endDate,
            duration: payload.endDate.timeIntervalSince(payload.startDate),
            totalEnergyBurned: nil,
            totalDistance: nil,
            metadata: workoutMetadata(for: payload)
        )

        try await store.save(workout)
        return HealthKitWorkoutSyncResult(workoutUUID: workout.uuid)
    }

    func saveBodyWeight(_ payload: HealthKitBodyWeightPayload) async throws -> UUID {
        let bodyMassType = HKQuantityType.quantityType(forIdentifier: .bodyMass)!
        let quantity = HKQuantity(unit: .gramUnit(with: .kilo), doubleValue: payload.weightKg)
        let sample = HKQuantitySample(
            type: bodyMassType,
            quantity: quantity,
            start: payload.date,
            end: payload.date,
            metadata: [
                HKMetadataKeyExternalUUID: payload.localMeasurementID.uuidString,
                "GymTrackerSampleType": "body_mass"
            ]
        )

        try await store.save(sample)
        return sample.uuid
    }

    func fetchBodyWeightSamples(since: Date?) async throws -> [HealthKitBodyWeightSample] {
        let type = HKQuantityType.quantityType(forIdentifier: .bodyMass)!
        let predicate = since.map { HKQuery.predicateForSamples(withStart: $0, end: nil) }
        let sort = [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: true)]

        let samples = try await querySamples(of: type, predicate: predicate, sortDescriptors: sort)
        return samples.compactMap { sample in
            guard let quantitySample = sample as? HKQuantitySample else { return nil }
            return HealthKitBodyWeightSample(
                uuid: quantitySample.uuid,
                date: quantitySample.endDate,
                weightKg: quantitySample.quantity.doubleValue(for: .gramUnit(with: .kilo))
            )
        }
    }

    func fetchHeartRateSamples(from: Date, to: Date) async throws -> [HealthKitHeartRateSample] {
        let type = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let predicate = HKQuery.predicateForSamples(withStart: from, end: to)
        let sort = [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]

        let samples = try await querySamples(of: type, predicate: predicate, sortDescriptors: sort)
        let unit = HKUnit.count().unitDivided(by: .minute())
        return samples.compactMap { sample in
            guard let quantitySample = sample as? HKQuantitySample else { return nil }
            return HealthKitHeartRateSample(
                date: quantitySample.startDate,
                beatsPerMinute: quantitySample.quantity.doubleValue(for: unit)
            )
        }
    }

    private func authorizationSets(
        for scope: HealthKitAuthorizationScope
    ) -> (share: Set<HKSampleType>, read: Set<HKObjectType>) {
        let workoutType = HKObjectType.workoutType()
        let bodyMassType = HKQuantityType.quantityType(forIdentifier: .bodyMass)!
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!

        switch scope {
        case .workoutsWrite:
            return (share: [workoutType], read: [])
        case .bodyWeightWrite:
            return (share: [bodyMassType], read: [])
        case .enrichmentRead:
            return (share: [], read: [workoutType, bodyMassType, heartRateType])
        }
    }

    private func workoutMetadata(for payload: HealthKitWorkoutPayload) -> [String: Any] {
        var metadata: [String: Any] = [
            HKMetadataKeyExternalUUID: payload.localWorkoutID.uuidString,
            HKMetadataKeyWorkoutBrandName: "GymTracker",
            "GymTrackerWorkoutTitle": payload.title,
            "GymTrackerActivitySummary": payload.activitySummary,
            "GymTrackerEnergyLevel": payload.energyLevel
        ]
        if let notes = payload.notes, !notes.isEmpty {
            metadata["GymTrackerWorkoutNotes"] = notes
        }
        return metadata
    }

    private func querySamples(
        of type: HKSampleType,
        predicate: NSPredicate?,
        sortDescriptors: [NSSortDescriptor]
    ) async throws -> [HKSample] {
        try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: sortDescriptors
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: samples ?? [])
                }
            }
            store.execute(query)
        }
    }
}
