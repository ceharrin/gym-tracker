import XCTest
import CoreData
@testable import GymTracker

/// Tests for HTML metric variants (lapsTime, duration, custom) and HTML escaping —
/// gaps not covered by the existing WorkoutHTMLFormatterTests.
final class WorkoutHTMLFormatterExtendedTests: XCTestCase {

    var context: NSManagedObjectContext!

    override func setUp() {
        super.setUp()
        context = CoreDataTestHelper.makeContext()
        Units._testOverrideIsMetric = true
    }

    override func tearDown() {
        Units._testOverrideIsMetric = nil
        super.tearDown()
    }

    // MARK: - Helpers

    private func makeWorkout(title: String = "Test", notes: String? = nil,
                              energyLevel: Int16 = 0, durationMinutes: Int32 = 0) -> CDWorkout {
        let w = CDWorkout(context: context)
        w.id = UUID()
        w.title = title
        w.date = Date()
        w.durationMinutes = durationMinutes
        w.energyLevel = energyLevel
        w.notes = notes
        return w
    }

    private func makeActivity(name: String, metric: PrimaryMetric) -> CDActivity {
        let a = CDActivity(context: context)
        a.id = UUID()
        a.name = name
        a.category = ActivityCategory.strength.rawValue
        a.primaryMetric = metric.rawValue
        return a
    }

    private func makeEntry(workout: CDWorkout, activity: CDActivity) -> CDWorkoutEntry {
        let e = CDWorkoutEntry(context: context)
        e.id = UUID()
        e.orderIndex = 0
        e.workout = workout
        e.activity = activity
        return e
    }

    @discardableResult
    private func addSet(
        to entry: CDWorkoutEntry,
        number: Int16 = 1,
        weightKg: Double = 0,
        reps: Int32 = 0,
        distanceMeters: Double = 0,
        durationSeconds: Int32 = 0,
        laps: Int32 = 0,
        customValue: Double = 0,
        customLabel: String? = nil
    ) -> CDEntrySet {
        let s = CDEntrySet(context: context)
        s.id = UUID()
        s.setNumber = number
        s.weightKg = weightKg
        s.reps = reps
        s.distanceMeters = distanceMeters
        s.durationSeconds = durationSeconds
        s.laps = laps
        s.customValue = customValue
        s.customLabel = customLabel
        s.entry = entry
        return s
    }

    // MARK: - lapsTime metric

    func test_lapsTime_headerContainsLaps() {
        let workout = makeWorkout()
        let activity = makeActivity(name: "Swimming", metric: .lapsTime)
        let entry = makeEntry(workout: workout, activity: activity)
        addSet(to: entry, number: 1, durationSeconds: 600, laps: 20)
        let html = WorkoutHTMLFormatter.singleWorkoutHTML(workout: workout)
        XCTAssertTrue(html.contains("Laps"), "HTML should contain Laps header for lapsTime metric")
    }

    func test_lapsTime_containsLapCount() {
        let workout = makeWorkout()
        let activity = makeActivity(name: "Swimming", metric: .lapsTime)
        let entry = makeEntry(workout: workout, activity: activity)
        addSet(to: entry, number: 1, durationSeconds: 600, laps: 25)
        let html = WorkoutHTMLFormatter.singleWorkoutHTML(workout: workout)
        XCTAssertTrue(html.contains("25"), "HTML should show lap count")
    }

    func test_lapsTime_containsFormattedTime() {
        let workout = makeWorkout()
        let activity = makeActivity(name: "Swimming", metric: .lapsTime)
        let entry = makeEntry(workout: workout, activity: activity)
        addSet(to: entry, number: 1, durationSeconds: 600, laps: 20) // 10:00
        let html = WorkoutHTMLFormatter.singleWorkoutHTML(workout: workout)
        XCTAssertTrue(html.contains("10:00"), "HTML should show formatted duration for lapsTime")
    }

    func test_lapsTime_zeroLaps_showsDash() {
        let workout = makeWorkout()
        let activity = makeActivity(name: "Swimming", metric: .lapsTime)
        let entry = makeEntry(workout: workout, activity: activity)
        addSet(to: entry, number: 1, durationSeconds: 0, laps: 0)
        let html = WorkoutHTMLFormatter.singleWorkoutHTML(workout: workout)
        XCTAssertTrue(html.contains("—"), "Zero laps should display as dash")
    }

    // MARK: - duration metric

    func test_duration_headerContainsDuration() {
        let workout = makeWorkout()
        let activity = makeActivity(name: "Plank", metric: .duration)
        let entry = makeEntry(workout: workout, activity: activity)
        addSet(to: entry, number: 1, durationSeconds: 120)
        let html = WorkoutHTMLFormatter.singleWorkoutHTML(workout: workout)
        XCTAssertTrue(html.contains("Duration"), "HTML should contain Duration header")
    }

    func test_duration_containsFormattedTime() {
        let workout = makeWorkout()
        let activity = makeActivity(name: "Plank", metric: .duration)
        let entry = makeEntry(workout: workout, activity: activity)
        addSet(to: entry, number: 1, durationSeconds: 125) // 2:05
        let html = WorkoutHTMLFormatter.singleWorkoutHTML(workout: workout)
        XCTAssertTrue(html.contains("2:05"), "HTML should show formatted duration")
    }

    func test_duration_zeroDuration_showsDash() {
        let workout = makeWorkout()
        let activity = makeActivity(name: "Plank", metric: .duration)
        let entry = makeEntry(workout: workout, activity: activity)
        addSet(to: entry, number: 1, durationSeconds: 0)
        let html = WorkoutHTMLFormatter.singleWorkoutHTML(workout: workout)
        XCTAssertTrue(html.contains("—"), "Zero duration should display as dash")
    }

    // MARK: - custom metric

    func test_custom_headerContainsValue() {
        let workout = makeWorkout()
        let activity = makeActivity(name: "Custom Move", metric: .custom)
        let entry = makeEntry(workout: workout, activity: activity)
        addSet(to: entry, number: 1, customValue: 50, customLabel: "reps")
        let html = WorkoutHTMLFormatter.singleWorkoutHTML(workout: workout)
        XCTAssertTrue(html.contains("Value"), "HTML should contain Value header for custom metric")
    }

    func test_custom_containsValueAndLabel() {
        let workout = makeWorkout()
        let activity = makeActivity(name: "Cable Fly", metric: .custom)
        let entry = makeEntry(workout: workout, activity: activity)
        addSet(to: entry, number: 1, customValue: 42.5, customLabel: "kg")
        let html = WorkoutHTMLFormatter.singleWorkoutHTML(workout: workout)
        XCTAssertTrue(html.contains("42.5"), "HTML should show custom value")
        XCTAssertTrue(html.contains("kg"), "HTML should show custom label")
    }

    func test_custom_zeroValue_showsDash() {
        let workout = makeWorkout()
        let activity = makeActivity(name: "Custom", metric: .custom)
        let entry = makeEntry(workout: workout, activity: activity)
        addSet(to: entry, number: 1, customValue: 0)
        let html = WorkoutHTMLFormatter.singleWorkoutHTML(workout: workout)
        XCTAssertTrue(html.contains("—"), "Zero custom value should display as dash")
    }

    // MARK: - HTML escaping

    func test_escape_ampersandInTitle() {
        let workout = makeWorkout(title: "Chest & Triceps")
        let html = WorkoutHTMLFormatter.singleWorkoutHTML(workout: workout)
        XCTAssertTrue(html.contains("&amp;"), "Ampersand must be HTML-escaped in title")
        XCTAssertFalse(html.contains("Chest & Triceps"), "Raw ampersand must not appear in HTML")
    }

    func test_escape_lessThanInTitle() {
        let workout = makeWorkout(title: "Level <1>")
        let html = WorkoutHTMLFormatter.singleWorkoutHTML(workout: workout)
        XCTAssertTrue(html.contains("&lt;"), "< must be HTML-escaped")
    }

    func test_escape_greaterThanInTitle() {
        let workout = makeWorkout(title: "Score > 10")
        let html = WorkoutHTMLFormatter.singleWorkoutHTML(workout: workout)
        XCTAssertTrue(html.contains("&gt;"), "> must be HTML-escaped")
    }

    func test_escape_quoteInTitle() {
        let workout = makeWorkout(title: "Day \"A\"")
        let html = WorkoutHTMLFormatter.singleWorkoutHTML(workout: workout)
        XCTAssertTrue(html.contains("&quot;"), "Double quote must be HTML-escaped")
    }

    func test_escape_ampersandInNotes() {
        let workout = makeWorkout(notes: "Foam roll & stretch")
        let html = WorkoutHTMLFormatter.singleWorkoutHTML(workout: workout)
        XCTAssertTrue(html.contains("&amp;"), "Ampersand in notes must be HTML-escaped")
    }

    func test_escape_ampersandInActivityName() {
        let workout = makeWorkout()
        let activity = makeActivity(name: "Push & Pull", metric: .weightReps)
        _ = makeEntry(workout: workout, activity: activity)
        let html = WorkoutHTMLFormatter.singleWorkoutHTML(workout: workout)
        XCTAssertTrue(html.contains("&amp;"), "Ampersand in activity name must be HTML-escaped")
    }

    // MARK: - Energy level in single workout HTML

    func test_energyLevel_nonZero_appearsInHTML() {
        let workout = makeWorkout(energyLevel: 8)
        let html = WorkoutHTMLFormatter.singleWorkoutHTML(workout: workout)
        XCTAssertTrue(html.contains("8"), "Energy level must appear in workout HTML when > 0")
    }

    func test_energyLevel_zero_doesNotAppear() {
        let workout = makeWorkout(energyLevel: 0)
        let html = WorkoutHTMLFormatter.singleWorkoutHTML(workout: workout)
        XCTAssertFalse(html.contains("Energy"), "Energy section must be hidden when level is 0")
    }

    // MARK: - Summary: no total duration when all zero

    func test_summary_noDurationSection_whenAllZero() {
        let w = makeWorkout(durationMinutes: 0)
        let html = WorkoutHTMLFormatter.summaryHTML(workouts: [w], from: Date(), to: Date())
        XCTAssertFalse(html.contains("min total"),
                       "Summary must not show 'min total' when all durations are zero")
    }

    // MARK: - No sets logged message

    func test_noSets_showsMessage() {
        let workout = makeWorkout()
        let activity = makeActivity(name: "Empty Exercise", metric: .weightReps)
        _ = makeEntry(workout: workout, activity: activity)
        let html = WorkoutHTMLFormatter.singleWorkoutHTML(workout: workout)
        XCTAssertTrue(html.contains("No sets"), "HTML should say 'No sets' when entry has no sets")
    }
}
