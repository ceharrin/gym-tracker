import XCTest
import CoreData
@testable import GymTracker

final class WorkoutHistoryDisplayPolicyTests: XCTestCase {

    var context: NSManagedObjectContext!

    override func setUp() {
        super.setUp()
        context = CoreDataTestHelper.makeContext()
    }

    private func makeWorkout(title: String, summary: String = "", index: Int) -> CDWorkout {
        let workout = CDWorkout(context: context)
        workout.id = UUID()
        workout.title = title
        workout.date = Date(timeIntervalSinceReferenceDate: TimeInterval(index))
        workout.startedAt = workout.date
        workout.isCompleted = true
        workout.durationMinutes = 30
        workout.energyLevel = 5
        workout.notes = nil

        if !summary.isEmpty {
            let activity = CDActivity(context: context)
            activity.id = UUID()
            activity.name = summary
            activity.category = ActivityCategory.strength.rawValue
            activity.icon = "dumbbell.fill"
            activity.primaryMetric = PrimaryMetric.weightReps.rawValue
            activity.isPreset = false

            let entry = CDWorkoutEntry(context: context)
            entry.id = UUID()
            entry.workout = workout
            entry.activity = activity
            entry.orderIndex = 0
        }

        return workout
    }

    func test_visibleWorkouts_withoutSearch_limitsToInitialVisibleCount() {
        let workouts = (0..<150).map { makeWorkout(title: "Workout \($0)", index: $0) }

        let visible = WorkoutHistoryDisplayPolicy.visibleWorkouts(
            from: workouts,
            searchText: "",
            visibleCount: WorkoutHistoryDisplayPolicy.initialVisibleCount
        )

        XCTAssertEqual(visible.count, WorkoutHistoryDisplayPolicy.initialVisibleCount)
        XCTAssertEqual(visible.first?.title, "Workout 0")
        XCTAssertEqual(visible.last?.title, "Workout 99")
    }

    func test_visibleWorkouts_withSearch_returnsAllMatchesBeyondVisibleCount() {
        let workouts = [
            makeWorkout(title: "Monday Workout", summary: "Bench Press", index: 0),
            makeWorkout(title: "Tuesday Workout", summary: "Bench Press", index: 1),
            makeWorkout(title: "Wednesday Workout", summary: "Row", index: 2)
        ]

        let visible = WorkoutHistoryDisplayPolicy.visibleWorkouts(
            from: workouts,
            searchText: "bench",
            visibleCount: 1
        )

        XCTAssertEqual(visible.map(\.title), ["Monday Workout", "Tuesday Workout"])
    }

    func test_shouldShowLoadMore_onlyWhenNotSearchingAndMoreRemain() {
        XCTAssertTrue(
            WorkoutHistoryDisplayPolicy.shouldShowLoadMore(
                totalCount: 150,
                visibleCount: 100,
                searchText: ""
            )
        )

        XCTAssertFalse(
            WorkoutHistoryDisplayPolicy.shouldShowLoadMore(
                totalCount: 150,
                visibleCount: 100,
                searchText: "legs"
            )
        )

        XCTAssertFalse(
            WorkoutHistoryDisplayPolicy.shouldShowLoadMore(
                totalCount: 100,
                visibleCount: 100,
                searchText: ""
            )
        )
    }

    func test_nextVisibleCount_capsAtTotalCount() {
        XCTAssertEqual(
            WorkoutHistoryDisplayPolicy.nextVisibleCount(currentVisibleCount: 100, totalCount: 250),
            200
        )
        XCTAssertEqual(
            WorkoutHistoryDisplayPolicy.nextVisibleCount(currentVisibleCount: 200, totalCount: 250),
            250
        )
    }
}
