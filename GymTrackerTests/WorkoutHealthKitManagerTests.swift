import CoreData
import XCTest
@testable import GymTracker

@MainActor
final class WorkoutHealthKitManagerTests: XCTestCase {

    private let fixedDate = Date(timeIntervalSince1970: 1_000_000)
    private var context: NSManagedObjectContext!

    override func setUp() {
        super.setUp()
        context = CoreDataTestHelper.makeContext()
    }

    func test_syncWorkout_doesNothingWhenUnavailable() async {
        let workout = makeWorkout()
        let mock = MockHealthKitService(isAvailable: false)
        let manager = WorkoutHealthKitManager(service: mock)

        await manager.syncWorkout(workout)

        XCTAssertTrue(mock.authorizationScopes.isEmpty)
        XCTAssertTrue(mock.savedWorkoutPayloads.isEmpty)
        XCTAssertEqual(workout.healthKitSyncState, .notSynced)
    }

    func test_syncWorkout_requestsWorkoutAuthorizationBeforeSaving() async {
        let workout = makeWorkout()
        let mock = MockHealthKitService()
        let manager = WorkoutHealthKitManager(service: mock)

        await manager.syncWorkout(workout)

        XCTAssertEqual(mock.authorizationScopes.first, .workoutsWrite)
        XCTAssertEqual(mock.savedWorkoutPayloads.count, 1)
    }

    func test_syncWorkout_savesWorkoutPayloadWithCorrectDates() async {
        let workout = makeWorkout(durationMinutes: 45)
        let mock = MockHealthKitService()
        let manager = WorkoutHealthKitManager(service: mock)

        await manager.syncWorkout(workout)

        XCTAssertEqual(mock.savedWorkoutPayloads.first?.startDate, fixedDate)
        XCTAssertEqual(mock.savedWorkoutPayloads.first?.endDate, fixedDate.addingTimeInterval(45 * 60))
    }

    func test_syncWorkout_marksSyncedOnSuccess() async {
        let workout = makeWorkout()
        let mock = MockHealthKitService()
        let manager = WorkoutHealthKitManager(service: mock)

        await manager.syncWorkout(workout)

        XCTAssertEqual(workout.healthKitSyncState, .synced)
        XCTAssertNotNil(workout.healthKitWorkoutUUID)
        XCTAssertNotNil(workout.healthKitLastSyncAt)
        XCTAssertNil(workout.healthKitLastError)
    }

    func test_syncWorkout_marksFailedOnAuthorizationError() async {
        let workout = makeWorkout()
        let mock = MockHealthKitService()
        mock.authorizationError = NSError(domain: "HKErrorDomain", code: 1)
        let manager = WorkoutHealthKitManager(service: mock)

        await manager.syncWorkout(workout)

        XCTAssertEqual(workout.healthKitSyncState, .failed)
        XCTAssertNil(workout.healthKitWorkoutUUID)
        XCTAssertNotNil(workout.healthKitLastError)
    }

    func test_syncWorkout_marksFailedOnSaveError() async {
        let workout = makeWorkout()
        let mock = MockHealthKitService()
        mock.workoutSaveError = NSError(domain: "HKErrorDomain", code: 2)
        let manager = WorkoutHealthKitManager(service: mock)

        await manager.syncWorkout(workout)

        XCTAssertEqual(workout.healthKitSyncState, .failed)
        XCTAssertNil(workout.healthKitWorkoutUUID)
    }

    func test_syncWorkout_doesNotSyncEditedWorkout() async {
        let workout = makeWorkout()
        let mock = MockHealthKitService()
        let manager = WorkoutHealthKitManager(service: mock)

        await manager.syncWorkout(workout, isNew: false)

        XCTAssertTrue(mock.savedWorkoutPayloads.isEmpty)
        XCTAssertEqual(workout.healthKitSyncState, .notSynced)
    }

    func test_syncWorkout_doesNotResyncExistingHealthWorkout() async {
        let workout = makeWorkout()
        workout.healthKitWorkoutUUID = UUID()
        let mock = MockHealthKitService()
        let manager = WorkoutHealthKitManager(service: mock)

        await manager.syncWorkout(workout)

        XCTAssertTrue(mock.savedWorkoutPayloads.isEmpty)
    }

    func test_retryWorkoutSync_retriesFailedWorkout() async {
        let workout = makeWorkout()
        workout.healthKitSyncState = .failed
        let mock = MockHealthKitService()
        let manager = WorkoutHealthKitManager(service: mock)

        await manager.retryWorkoutSync(workout)

        XCTAssertEqual(mock.savedWorkoutPayloads.count, 1)
        XCTAssertEqual(workout.healthKitSyncState, .synced)
    }

    func test_syncBodyMeasurement_requestsAuthorizationAndSaves() async {
        let measurement = makeMeasurement()
        let mock = MockHealthKitService()
        let manager = WorkoutHealthKitManager(service: mock)

        await manager.syncBodyMeasurement(measurement)

        XCTAssertEqual(mock.authorizationScopes.first, .bodyWeightWrite)
        XCTAssertEqual(mock.savedBodyWeightPayloads.count, 1)
        XCTAssertEqual(measurement.healthKitSyncState, .synced)
        XCTAssertNotNil(measurement.healthKitSampleUUID)
    }

    func test_syncBodyMeasurement_doesNotSyncImportedMeasurement() async {
        let measurement = makeMeasurement()
        measurement.healthDataSource = .healthKitImported
        let mock = MockHealthKitService()
        let manager = WorkoutHealthKitManager(service: mock)

        await manager.syncBodyMeasurement(measurement)

        XCTAssertTrue(mock.savedBodyWeightPayloads.isEmpty)
    }

    func test_syncBodyMeasurement_marksFailedOnSaveError() async {
        let measurement = makeMeasurement()
        let mock = MockHealthKitService()
        mock.bodyWeightSaveError = NSError(domain: "HKErrorDomain", code: 3)
        let manager = WorkoutHealthKitManager(service: mock)

        await manager.syncBodyMeasurement(measurement)

        XCTAssertEqual(measurement.healthKitSyncState, .failed)
        XCTAssertNil(measurement.healthKitSampleUUID)
    }

    func test_loadHeartRateSummary_computesAverageAndMax() async {
        let workout = makeWorkout(durationMinutes: 30)
        let mock = MockHealthKitService()
        mock.heartRateSamples = [
            HealthKitHeartRateSample(date: fixedDate, beatsPerMinute: 120),
            HealthKitHeartRateSample(date: fixedDate.addingTimeInterval(60), beatsPerMinute: 150),
            HealthKitHeartRateSample(date: fixedDate.addingTimeInterval(120), beatsPerMinute: 90)
        ]
        let manager = WorkoutHealthKitManager(service: mock)

        let summary = await manager.loadHeartRateSummary(for: workout)

        XCTAssertEqual(mock.authorizationScopes.first, .enrichmentRead)
        XCTAssertEqual(summary, WorkoutHeartRateSummary(averageBPM: 120, maxBPM: 150, sampleCount: 3))
    }

    // MARK: Helpers

    private func makeWorkout(durationMinutes: Int32 = 30) -> CDWorkout {
        let workout = CDWorkout(context: context)
        workout.id = UUID()
        workout.title = "Test Workout"
        workout.date = fixedDate
        workout.durationMinutes = durationMinutes
        workout.energyLevel = 7
        workout.healthKitSyncState = .notSynced
        return workout
    }

    private func makeMeasurement() -> CDBodyMeasurement {
        let measurement = CDBodyMeasurement(context: context)
        measurement.id = UUID()
        measurement.date = fixedDate
        measurement.weightKg = 80
        measurement.healthDataSource = .local
        measurement.healthKitSyncState = .notSynced
        return measurement
    }
}
