import CoreData
import Foundation
import HealthKit

@MainActor
final class WorkoutHealthKitManager {
    static let shared = WorkoutHealthKitManager()

    private let service: HealthKitServiceProtocol

    init(service: HealthKitServiceProtocol = LiveHealthKitService()) {
        self.service = service
    }

    func requestWorkoutAuthorizationIfNeeded() async {
        guard service.isAvailable else { return }
        try? await service.requestAuthorization(for: .workoutsWrite)
    }

    func requestBodyWeightAuthorizationIfNeeded() async {
        guard service.isAvailable else { return }
        try? await service.requestAuthorization(for: .bodyWeightWrite)
    }

    func requestReadAuthorizationIfNeeded() async {
        guard service.isAvailable else { return }
        try? await service.requestAuthorization(for: .enrichmentRead)
    }

    func syncWorkout(_ workout: CDWorkout, isNew: Bool = true) async {
        guard service.isAvailable, isNew, workout.healthKitWorkoutUUID == nil else { return }

        workout.healthKitSyncState = .pending
        workout.healthKitLastError = nil
        persistContext(for: workout)

        do {
            try await service.requestAuthorization(for: .workoutsWrite)
            let result = try await service.saveWorkout(makeWorkoutPayload(from: workout))
            workout.healthKitWorkoutUUID = result.workoutUUID
            workout.healthKitLastSyncAt = Date()
            workout.healthKitLastError = nil
            workout.healthKitSyncState = .synced
        } catch {
            workout.healthKitLastError = error.localizedDescription
            workout.healthKitSyncState = .failed
        }

        persistContext(for: workout)
    }

    func retryWorkoutSync(_ workout: CDWorkout) async {
        guard workout.healthKitCanRetrySync else { return }
        await syncWorkout(workout, isNew: true)
    }

    func syncBodyMeasurement(_ measurement: CDBodyMeasurement) async {
        guard service.isAvailable else { return }
        guard measurement.healthDataSource == .local else { return }
        guard measurement.healthKitSampleUUID == nil else { return }

        measurement.healthKitSyncState = .pending
        persistContext(for: measurement)

        do {
            try await service.requestAuthorization(for: .bodyWeightWrite)
            let sampleUUID = try await service.saveBodyWeight(makeBodyWeightPayload(from: measurement))
            measurement.healthKitSampleUUID = sampleUUID
            measurement.healthKitSyncState = .synced
        } catch {
            measurement.healthKitSyncState = .failed
        }

        persistContext(for: measurement)
    }

    func loadHeartRateSummary(for workout: CDWorkout) async -> WorkoutHeartRateSummary? {
        guard service.isAvailable else { return nil }
        do {
            try await service.requestAuthorization(for: .enrichmentRead)
            let samples = try await service.fetchHeartRateSamples(from: workout.date, to: workout.healthKitWorkoutEndDate)
            guard !samples.isEmpty else { return nil }
            let average = Int(samples.map(\.beatsPerMinute).reduce(0, +) / Double(samples.count))
            let maxBPM = Int(samples.map(\.beatsPerMinute).max() ?? 0)
            return WorkoutHeartRateSummary(averageBPM: average, maxBPM: maxBPM, sampleCount: samples.count)
        } catch {
            return nil
        }
    }

    private func makeWorkoutPayload(from workout: CDWorkout) -> HealthKitWorkoutPayload {
        HealthKitWorkoutPayload(
            localWorkoutID: workout.id ?? UUID(),
            title: workout.title,
            startDate: workout.date,
            endDate: workout.healthKitWorkoutEndDate,
            activityType: .traditionalStrengthTraining,
            notes: workout.notes,
            activitySummary: workout.activitySummary,
            energyLevel: Int(workout.energyLevel)
        )
    }

    private func makeBodyWeightPayload(from measurement: CDBodyMeasurement) -> HealthKitBodyWeightPayload {
        HealthKitBodyWeightPayload(
            localMeasurementID: measurement.id ?? UUID(),
            date: measurement.date,
            weightKg: measurement.weightKg
        )
    }

    private func persistContext(for object: NSManagedObject) {
        guard let context = object.managedObjectContext else { return }
        do {
            try context.saveIfChanged()
        } catch {
            context.rollback()
        }
    }
}
