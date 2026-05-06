import XCTest
import CoreData
@testable import GymTracker

final class WorkoutStartCoordinatorTests: XCTestCase {

    var context: NSManagedObjectContext!

    override func setUp() {
        super.setUp()
        context = CoreDataTestHelper.makeContext()
    }

    private func makeWorkout(
        title: String,
        date: Date,
        startedAt: Date? = nil,
        isCompleted: Bool
    ) -> CDWorkout {
        let workout = CDWorkout(context: context)
        workout.id = UUID()
        workout.title = title
        workout.date = date
        workout.startedAt = startedAt ?? date
        workout.isCompleted = isCompleted
        workout.durationMinutes = 0
        workout.energyLevel = 7
        return workout
    }

    func test_startDestination_returnsCreateNew_whenNoWorkoutsExist() {
        XCTAssertEqual(WorkoutStartCoordinator.startDestination(from: []).mode, .newWorkout)
    }

    func test_startDestination_returnsCreateNew_whenAllWorkoutsAreCompleted() {
        let completed = makeWorkout(
            title: "Completed",
            date: Date(timeIntervalSinceReferenceDate: 100),
            isCompleted: true
        )

        let destination = WorkoutStartCoordinator.startDestination(from: [completed])

        XCTAssertEqual(destination.mode, .newWorkout)
        XCTAssertNil(destination.workout)
    }

    func test_startDestination_returnsExistingInProgressWorkout() {
        let inProgress = makeWorkout(
            title: "In Progress",
            date: Date(timeIntervalSinceReferenceDate: 100),
            isCompleted: false
        )
        let completed = makeWorkout(
            title: "Completed",
            date: Date(timeIntervalSinceReferenceDate: 200),
            isCompleted: true
        )

        let destination = WorkoutStartCoordinator.startDestination(from: [completed, inProgress])

        XCTAssertEqual(destination.mode, .resumeExisting)
        XCTAssertEqual(destination.workout?.objectID, inProgress.objectID)
    }

    func test_startDestination_prefersMostRecentInProgressWorkout() {
        let older = makeWorkout(
            title: "Older In Progress",
            date: Date(timeIntervalSinceReferenceDate: 100),
            isCompleted: false
        )
        let newer = makeWorkout(
            title: "Newer In Progress",
            date: Date(timeIntervalSinceReferenceDate: 200),
            isCompleted: false
        )

        let destination = WorkoutStartCoordinator.startDestination(from: [older, newer])

        XCTAssertEqual(destination.mode, .resumeExisting)
        XCTAssertEqual(destination.workout?.objectID, newer.objectID)
    }

    func test_completionState_marksExistingWorkoutCompletedWhenSessionJustCompleted() {
        let workout = makeWorkout(
            title: "In Progress",
            date: Date(timeIntervalSinceReferenceDate: 100),
            isCompleted: false
        )

        XCTAssertTrue(
            LogWorkoutView.isWorkoutCompleted(
                existingWorkout: workout,
                isDuplicate: false,
                completedDuringSession: true
            )
        )
    }

    func test_completionState_keepsDuplicateWorkoutEditable() {
        let workout = makeWorkout(
            title: "Completed Source",
            date: Date(timeIntervalSinceReferenceDate: 100),
            isCompleted: true
        )

        XCTAssertFalse(
            LogWorkoutView.isWorkoutCompleted(
                existingWorkout: workout,
                isDuplicate: true,
                completedDuringSession: false
            )
        )
    }

    func test_completionConfirmation_requiredForInProgressWorkout() {
        let workout = makeWorkout(
            title: "In Progress",
            date: Date(timeIntervalSinceReferenceDate: 100),
            isCompleted: false
        )

        XCTAssertTrue(
            LogWorkoutView.shouldConfirmCompletion(
                existingWorkout: workout,
                isDuplicate: false,
                completedDuringSession: false
            )
        )
    }

    func test_completionConfirmation_notRequiredForCompletedWorkoutEdits() {
        let workout = makeWorkout(
            title: "Completed",
            date: Date(timeIntervalSinceReferenceDate: 100),
            isCompleted: true
        )

        XCTAssertFalse(
            LogWorkoutView.shouldConfirmCompletion(
                existingWorkout: workout,
                isDuplicate: false,
                completedDuringSession: false
            )
        )
    }

    func test_navigationDestination_initialMode_usesEditForInProgressWorkout() {
        let workout = makeWorkout(
            title: "In Progress",
            date: Date(timeIntervalSinceReferenceDate: 100),
            isCompleted: false
        )

        XCTAssertEqual(WorkoutNavigationDestination.initialMode(for: workout), .edit)
    }

    func test_navigationDestination_initialMode_usesDetailForCompletedWorkout() {
        let workout = makeWorkout(
            title: "Completed",
            date: Date(timeIntervalSinceReferenceDate: 100),
            isCompleted: true
        )

        XCTAssertEqual(WorkoutNavigationDestination.initialMode(for: workout), .detail)
    }

    func test_navigationRoute_createdForCompletedWorkout_usesDetailMode() {
        let workout = makeWorkout(
            title: "Completed",
            date: Date(timeIntervalSinceReferenceDate: 100),
            isCompleted: true
        )

        let route = WorkoutNavigationRoute(workout: workout)

        XCTAssertEqual(route.mode, .detail)
        XCTAssertEqual(route.workoutObjectID, workout.objectID)
    }

    func test_navigationRoute_createdAfterInProgressWorkoutCompletes_usesDetailMode() {
        let workout = makeWorkout(
            title: "Completed Later",
            date: Date(timeIntervalSinceReferenceDate: 100),
            isCompleted: false
        )
        let staleRoute = WorkoutNavigationRoute(workout: workout)

        workout.isCompleted = true
        let routeAfterCompletion = WorkoutNavigationRoute(workout: workout)

        XCTAssertEqual(staleRoute.mode, .edit)
        XCTAssertEqual(routeAfterCompletion.mode, .detail)
        XCTAssertEqual(routeAfterCompletion.workoutObjectID, workout.objectID)
    }
}
