import XCTest
import CoreData
@testable import GymTracker

final class WorkoutHistoryDisplayPolicyTests: XCTestCase {

    var context: NSManagedObjectContext!

    override func setUp() {
        super.setUp()
        context = CoreDataTestHelper.makeContext()
    }

    private func makeWorkout(title: String, summary: String = "", notes: String? = nil, index: Int, date: Date? = nil) -> CDWorkout {
        let workout = CDWorkout(context: context)
        workout.id = UUID()
        workout.title = title
        workout.date = date ?? Date(timeIntervalSinceReferenceDate: TimeInterval(index))
        workout.startedAt = workout.date
        workout.isCompleted = true
        workout.durationMinutes = 30
        workout.energyLevel = 5
        workout.notes = notes

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

    func test_visibleWorkouts_withSearch_matchesWorkoutNotes() {
        let workouts = [
            makeWorkout(title: "Monday Workout", notes: "Felt strong on squats", index: 0),
            makeWorkout(title: "Tuesday Workout", notes: "Easy recovery session", index: 1),
            makeWorkout(title: "Wednesday Workout", notes: nil, index: 2)
        ]

        let visible = WorkoutHistoryDisplayPolicy.visibleWorkouts(
            from: workouts,
            searchText: "squats",
            visibleCount: 1
        )

        XCTAssertEqual(visible.map(\.title), ["Monday Workout"])
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

    func test_contentState_emptyWhenNoWorkoutsExist() {
        XCTAssertEqual(
            WorkoutHistoryDisplayPolicy.contentState(
                totalWorkoutCount: 0,
                visibleWorkoutCount: 0,
                searchText: ""
            ),
            .empty
        )
    }

    func test_contentState_noSearchResultsWhenSearchingWithNoVisibleWorkouts() {
        XCTAssertEqual(
            WorkoutHistoryDisplayPolicy.contentState(
                totalWorkoutCount: 4,
                visibleWorkoutCount: 0,
                searchText: "bench"
            ),
            .noSearchResults
        )
    }

    func test_contentState_listWhenWorkoutsAreVisible() {
        XCTAssertEqual(
            WorkoutHistoryDisplayPolicy.contentState(
                totalWorkoutCount: 4,
                visibleWorkoutCount: 1,
                searchText: "bench"
            ),
            .list
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

    func test_groupedByMonth_sortsByMonthDateNotDisplayString() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let locale = Locale(identifier: "en_US_POSIX")

        let september = makeWorkout(
            title: "September",
            index: 0,
            date: calendar.date(from: DateComponents(year: 2026, month: 9, day: 10))!
        )
        let octoberLate = makeWorkout(
            title: "October Late",
            index: 1,
            date: calendar.date(from: DateComponents(year: 2026, month: 10, day: 20))!
        )
        let octoberEarly = makeWorkout(
            title: "October Early",
            index: 2,
            date: calendar.date(from: DateComponents(year: 2026, month: 10, day: 1))!
        )

        let groups = WorkoutHistoryDisplayPolicy.groupedByMonth(
            workouts: [september, octoberEarly, octoberLate],
            calendar: calendar,
            locale: locale
        )

        XCTAssertEqual(groups.map(\.title), ["October 2026", "September 2026"])
        XCTAssertEqual(groups.first?.workouts.map(\.title), ["October Late", "October Early"])
    }
}
