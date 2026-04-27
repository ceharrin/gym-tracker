import Foundation
@testable import GymTracker

final class MockHealthKitService: HealthKitServiceProtocol {
    var isAvailable: Bool
    var authorizationScopes: [HealthKitAuthorizationScope] = []
    var savedWorkoutPayloads: [HealthKitWorkoutPayload] = []
    var savedBodyWeightPayloads: [HealthKitBodyWeightPayload] = []
    var bodyWeightSamples: [HealthKitBodyWeightSample] = []
    var heartRateSamples: [HealthKitHeartRateSample] = []
    var authorizationError: Error? = nil
    var workoutSaveError: Error? = nil
    var bodyWeightSaveError: Error? = nil
    var heartRateError: Error? = nil

    init(isAvailable: Bool = true) {
        self.isAvailable = isAvailable
    }

    func requestAuthorization(for scope: HealthKitAuthorizationScope) async throws {
        if let error = authorizationError { throw error }
        authorizationScopes.append(scope)
    }

    func saveWorkout(_ payload: HealthKitWorkoutPayload) async throws -> HealthKitWorkoutSyncResult {
        if let error = workoutSaveError { throw error }
        savedWorkoutPayloads.append(payload)
        return HealthKitWorkoutSyncResult(workoutUUID: UUID())
    }

    func saveBodyWeight(_ payload: HealthKitBodyWeightPayload) async throws -> UUID {
        if let error = bodyWeightSaveError { throw error }
        savedBodyWeightPayloads.append(payload)
        return UUID()
    }

    func fetchBodyWeightSamples(since: Date?) async throws -> [HealthKitBodyWeightSample] {
        bodyWeightSamples
    }

    func fetchHeartRateSamples(from: Date, to: Date) async throws -> [HealthKitHeartRateSample] {
        if let error = heartRateError { throw error }
        return heartRateSamples
    }
}
