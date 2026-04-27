import XCTest
@testable import GymTracker

final class WorkoutHealthKitManagerTests: XCTestCase {

    private let fixedDate = Date(timeIntervalSince1970: 1_000_000)

    func test_syncWorkout_doesNothingWhenUnavailable() async {
        let mock = MockHealthKitService(isAvailable: false)
        let manager = WorkoutHealthKitManager(service: mock)
        await manager.syncWorkout(date: fixedDate, durationMinutes: 60)
        XCTAssertFalse(mock.authorizationRequested)
        XCTAssertTrue(mock.savedWorkouts.isEmpty)
    }

    func test_syncWorkout_requestsAuthorizationBeforeSaving() async {
        let mock = MockHealthKitService()
        let manager = WorkoutHealthKitManager(service: mock)
        await manager.syncWorkout(date: fixedDate, durationMinutes: 30)
        XCTAssertTrue(mock.authorizationRequested)
    }

    func test_syncWorkout_savesWorkoutAfterAuthorization() async {
        let mock = MockHealthKitService()
        let manager = WorkoutHealthKitManager(service: mock)
        await manager.syncWorkout(date: fixedDate, durationMinutes: 30)
        XCTAssertEqual(mock.savedWorkouts.count, 1)
    }

    func test_syncWorkout_passesCorrectStartDate() async {
        let mock = MockHealthKitService()
        let manager = WorkoutHealthKitManager(service: mock)
        await manager.syncWorkout(date: fixedDate, durationMinutes: 45)
        XCTAssertEqual(mock.savedWorkouts.first?.start, fixedDate)
    }

    func test_syncWorkout_passesCorrectEndDate() async {
        let mock = MockHealthKitService()
        let manager = WorkoutHealthKitManager(service: mock)
        await manager.syncWorkout(date: fixedDate, durationMinutes: 45)
        let expectedEnd = fixedDate.addingTimeInterval(45 * 60)
        XCTAssertEqual(mock.savedWorkouts.first?.end, expectedEnd)
    }

    func test_syncWorkout_doesNotSaveWhenAuthorizationFails() async {
        let mock = MockHealthKitService()
        mock.authorizationError = NSError(domain: "HKErrorDomain", code: 1)
        let manager = WorkoutHealthKitManager(service: mock)
        await manager.syncWorkout(date: fixedDate, durationMinutes: 30)
        XCTAssertTrue(mock.savedWorkouts.isEmpty)
    }

    func test_syncWorkout_silentlyHandlesAuthorizationError() async {
        let mock = MockHealthKitService()
        mock.authorizationError = NSError(domain: "HKErrorDomain", code: 1)
        let manager = WorkoutHealthKitManager(service: mock)
        // Must not crash or propagate the error
        await manager.syncWorkout(date: fixedDate, durationMinutes: 30)
    }

    func test_syncWorkout_silentlyHandlesSaveError() async {
        let mock = MockHealthKitService()
        mock.saveError = NSError(domain: "HKErrorDomain", code: 2)
        let manager = WorkoutHealthKitManager(service: mock)
        // Must not crash or propagate the error
        await manager.syncWorkout(date: fixedDate, durationMinutes: 30)
    }

    func test_syncWorkout_doesNotSyncEditedWorkout() async {
        let mock = MockHealthKitService()
        let manager = WorkoutHealthKitManager(service: mock)
        await manager.syncWorkout(date: fixedDate, durationMinutes: 30, isNew: false)
        XCTAssertTrue(mock.savedWorkouts.isEmpty)
    }

    func test_syncWorkout_doesSyncDuplicatedWorkout() async {
        let mock = MockHealthKitService()
        let manager = WorkoutHealthKitManager(service: mock)
        await manager.syncWorkout(date: fixedDate, durationMinutes: 30, isNew: true)
        XCTAssertEqual(mock.savedWorkouts.count, 1)
    }
}
