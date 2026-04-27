import Foundation
import HealthKit

protocol HealthKitServiceProtocol {
    var isAvailable: Bool { get }
    func requestAuthorization() async throws
    func saveStrengthWorkout(start: Date, end: Date) async throws
}

final class LiveHealthKitService: HealthKitServiceProtocol {
    private let store = HKHealthStore()
    private let shareTypes: Set<HKSampleType> = [HKObjectType.workoutType()]

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    func requestAuthorization() async throws {
        try await store.requestAuthorization(toShare: shareTypes, read: [])
    }

    func saveStrengthWorkout(start: Date, end: Date) async throws {
        let config = HKWorkoutConfiguration()
        config.activityType = .traditionalStrengthTraining

        let builder = HKWorkoutBuilder(healthStore: store, configuration: config, device: .local())
        try await builder.beginCollection(at: start)
        try await builder.endCollection(at: end)
        try await builder.finishWorkout()
    }
}
