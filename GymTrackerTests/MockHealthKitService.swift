import Foundation
@testable import GymTracker

final class MockHealthKitService: HealthKitServiceProtocol {
    var isAvailable: Bool
    var authorizationRequested = false
    var savedWorkouts: [(start: Date, end: Date)] = []
    var authorizationError: Error? = nil
    var saveError: Error? = nil

    init(isAvailable: Bool = true) {
        self.isAvailable = isAvailable
    }

    func requestAuthorization() async throws {
        if let error = authorizationError { throw error }
        authorizationRequested = true
    }

    func saveStrengthWorkout(start: Date, end: Date) async throws {
        if let error = saveError { throw error }
        savedWorkouts.append((start: start, end: end))
    }
}
