import XCTest
import CoreData
@testable import GymTracker

final class CDActivityHelpersTests: XCTestCase {

    var context: NSManagedObjectContext!

    override func setUp() {
        super.setUp()
        context = CoreDataTestHelper.makeContext()
    }

    // MARK: - Helpers

    private func makeActivity(
        category: ActivityCategory = .strength,
        metric: PrimaryMetric = .weightReps
    ) -> CDActivity {
        let a = CDActivity(context: context)
        a.id = UUID()
        a.name = "Test Activity"
        a.category = category.rawValue
        a.primaryMetric = metric.rawValue
        a.isPreset = false
        return a
    }

    private func makeWorkout(daysAgo: Int = 0) -> CDWorkout {
        let w = CDWorkout(context: context)
        w.id = UUID()
        w.title = "Workout"
        w.date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
        w.durationMinutes = 60
        return w
    }

    private func makeEntry(activity: CDActivity, workout: CDWorkout, orderIndex: Int16 = 0) -> CDWorkoutEntry {
        let e = CDWorkoutEntry(context: context)
        e.id = UUID()
        e.orderIndex = orderIndex
        e.activity = activity
        e.workout = workout
        return e
    }

    // MARK: - activityCategory

    func test_activityCategory_strength() {
        let a = makeActivity(category: .strength)
        XCTAssertEqual(a.activityCategory, .strength)
    }

    func test_activityCategory_cardio() {
        let a = makeActivity(category: .cardio)
        XCTAssertEqual(a.activityCategory, .cardio)
    }

    func test_activityCategory_swimming() {
        let a = makeActivity(category: .swimming)
        XCTAssertEqual(a.activityCategory, .swimming)
    }

    func test_activityCategory_cycling() {
        let a = makeActivity(category: .cycling)
        XCTAssertEqual(a.activityCategory, .cycling)
    }

    func test_activityCategory_yoga() {
        let a = makeActivity(category: .yoga)
        XCTAssertEqual(a.activityCategory, .yoga)
    }

    func test_activityCategory_hiit() {
        let a = makeActivity(category: .hiit)
        XCTAssertEqual(a.activityCategory, .hiit)
    }

    func test_activityCategory_custom() {
        let a = makeActivity(category: .custom)
        XCTAssertEqual(a.activityCategory, .custom)
    }

    func test_activityCategory_invalidRawValue_fallsBackToCustom() {
        let a = makeActivity()
        a.category = "not_a_real_category"
        XCTAssertEqual(a.activityCategory, .custom)
    }

    // MARK: - strengthEquipmentGroup

    func test_strengthEquipmentGroup_barbellPreset() {
        let a = makeActivity()
        a.name = "Back Squat"
        a.isPreset = true

        XCTAssertEqual(a.strengthEquipmentGroup, .barbell)
    }

    func test_strengthEquipmentGroup_dumbbellPreset() {
        let a = makeActivity()
        a.name = "Dumbbell Bench Press"
        a.isPreset = true

        XCTAssertEqual(a.strengthEquipmentGroup, .dumbbell)
    }

    func test_strengthEquipmentGroup_machinePreset() {
        let a = makeActivity()
        a.name = "Leg Press"
        a.isPreset = true

        XCTAssertEqual(a.strengthEquipmentGroup, .machine)
    }

    func test_strengthEquipmentGroup_cablePreset() {
        let a = makeActivity()
        a.name = "Cable Row"
        a.isPreset = true

        XCTAssertEqual(a.strengthEquipmentGroup, .cable)
    }

    func test_strengthEquipmentGroup_bodyweightPreset() {
        let a = makeActivity(metric: .reps)
        a.name = "Push-Up"
        a.isPreset = true

        XCTAssertEqual(a.strengthEquipmentGroup, .bodyweightCore)
    }

    func test_strengthEquipmentGroup_customStrengthFallsIntoCustomBucket() {
        let a = makeActivity(metric: .reps)
        a.name = "My Strength Move"
        a.isPreset = false

        XCTAssertEqual(a.strengthEquipmentGroup, .customStrength)
    }

    // MARK: - metric

    func test_metric_weightReps() {
        let a = makeActivity(metric: .weightReps)
        XCTAssertEqual(a.metric, .weightReps)
    }

    func test_metric_distanceTime() {
        let a = makeActivity(metric: .distanceTime)
        XCTAssertEqual(a.metric, .distanceTime)
    }

    func test_metric_lapsTime() {
        let a = makeActivity(metric: .lapsTime)
        XCTAssertEqual(a.metric, .lapsTime)
    }

    func test_metric_duration() {
        let a = makeActivity(metric: .duration)
        XCTAssertEqual(a.metric, .duration)
    }

    func test_metric_custom() {
        let a = makeActivity(metric: .custom)
        XCTAssertEqual(a.metric, .custom)
    }

    func test_metric_invalidRawValue_fallsBackToWeightReps() {
        let a = makeActivity()
        a.primaryMetric = "unknown_metric"
        XCTAssertEqual(a.metric, .weightReps)
    }

    // MARK: - sortedEntries

    func test_sortedEntries_emptyWhenNoWorkouts() {
        let a = makeActivity()
        XCTAssertTrue(a.sortedEntries.isEmpty)
    }

    func test_sortedEntries_mostRecentFirst() {
        let a = makeActivity()
        let w1 = makeWorkout(daysAgo: 10)
        let w2 = makeWorkout(daysAgo: 5)
        let w3 = makeWorkout(daysAgo: 0)
        let e1 = makeEntry(activity: a, workout: w1)
        let e2 = makeEntry(activity: a, workout: w2)
        let e3 = makeEntry(activity: a, workout: w3)

        let sorted = a.sortedEntries
        XCTAssertEqual(sorted.count, 3)
        XCTAssertEqual(sorted[0].id, e3.id, "Most recent entry should be first")
        XCTAssertEqual(sorted[1].id, e2.id)
        XCTAssertEqual(sorted[2].id, e1.id)
    }

    func test_sortedEntries_singleEntry() {
        let a = makeActivity()
        let w = makeWorkout()
        let e = makeEntry(activity: a, workout: w)
        XCTAssertEqual(a.sortedEntries.count, 1)
        XCTAssertEqual(a.sortedEntries.first?.id, e.id)
    }

    func test_sortedEntries_onlyIncludesOwnEntries() {
        let a1 = makeActivity()
        let a2 = makeActivity()
        let w = makeWorkout()
        _ = makeEntry(activity: a1, workout: w)
        _ = makeEntry(activity: a2, workout: w)

        XCTAssertEqual(a1.sortedEntries.count, 1)
        XCTAssertEqual(a2.sortedEntries.count, 1)
    }
}
