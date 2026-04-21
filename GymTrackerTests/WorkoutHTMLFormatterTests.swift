import XCTest
import CoreData
@testable import GymTracker

final class WorkoutHTMLFormatterTests: XCTestCase {

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

    private func makeWorkout(title: String = "Test Workout",
                              durationMinutes: Int32 = 60,
                              energyLevel: Int16 = 7,
                              notes: String? = nil,
                              date: Date = Date()) -> CDWorkout {
        let w = CDWorkout(context: context)
        w.id = UUID()
        w.title = title
        w.date = date
        w.durationMinutes = durationMinutes
        w.energyLevel = energyLevel
        w.notes = notes
        return w
    }

    private func makeActivity(name: String, category: ActivityCategory = .strength,
                               metric: PrimaryMetric = .weightReps) -> CDActivity {
        let a = CDActivity(context: context)
        a.id = UUID()
        a.name = name
        a.category = category.rawValue
        a.primaryMetric = metric.rawValue
        a.icon = category.icon
        return a
    }

    private func makeEntry(workout: CDWorkout, activity: CDActivity,
                            orderIndex: Int16 = 0) -> CDWorkoutEntry {
        let e = CDWorkoutEntry(context: context)
        e.id = UUID()
        e.orderIndex = orderIndex
        e.workout = workout
        e.activity = activity
        return e
    }

    private func makeSet(entry: CDWorkoutEntry, setNumber: Int16 = 1,
                          weightKg: Double = 100, reps: Int32 = 8) -> CDEntrySet {
        let s = CDEntrySet(context: context)
        s.id = UUID()
        s.setNumber = setNumber
        s.weightKg = weightKg
        s.reps = reps
        s.entry = entry
        return s
    }

    // MARK: - Single workout: structure

    func test_singleWorkout_containsTitle() {
        let workout = makeWorkout(title: "Heavy Leg Day")
        let html = WorkoutHTMLFormatter.singleWorkoutHTML(workout: workout)
        XCTAssertTrue(html.contains("Heavy Leg Day"), "HTML should contain workout title")
    }

    func test_singleWorkout_containsDate() {
        let date = Calendar.current.date(from: DateComponents(year: 2026, month: 4, day: 15))!
        let workout = makeWorkout(date: date)
        let html = WorkoutHTMLFormatter.singleWorkoutHTML(workout: workout)
        XCTAssertTrue(html.contains("2026"), "HTML should contain the workout year")
    }

    func test_singleWorkout_containsDuration() {
        let workout = makeWorkout(durationMinutes: 75)
        let html = WorkoutHTMLFormatter.singleWorkoutHTML(workout: workout)
        XCTAssertTrue(html.contains("75"), "HTML should contain duration")
    }

    func test_singleWorkout_containsNotes() {
        let workout = makeWorkout(notes: "Felt really strong today")
        let html = WorkoutHTMLFormatter.singleWorkoutHTML(workout: workout)
        XCTAssertTrue(html.contains("Felt really strong today"), "HTML should contain notes")
    }

    func test_singleWorkout_noNotesSection_whenNil() {
        let workout = makeWorkout(notes: nil)
        let html = WorkoutHTMLFormatter.singleWorkoutHTML(workout: workout)
        XCTAssertFalse(html.contains("Notes"), "HTML should not have Notes section when nil")
    }

    // MARK: - Single workout: exercise content

    func test_singleWorkout_containsActivityName() {
        let workout = makeWorkout()
        let activity = makeActivity(name: "Back Squat")
        _ = makeEntry(workout: workout, activity: activity)
        let html = WorkoutHTMLFormatter.singleWorkoutHTML(workout: workout)
        XCTAssertTrue(html.contains("Back Squat"), "HTML should contain activity name")
    }

    func test_singleWorkout_containsSetNumber() {
        let workout = makeWorkout()
        let activity = makeActivity(name: "Bench Press")
        let entry = makeEntry(workout: workout, activity: activity)
        _ = makeSet(entry: entry, setNumber: 3, weightKg: 80, reps: 5)
        let html = WorkoutHTMLFormatter.singleWorkoutHTML(workout: workout)
        XCTAssertTrue(html.contains("3"), "HTML should contain set number")
    }

    func test_singleWorkout_weightReps_containsWeight() {
        let workout = makeWorkout()
        let activity = makeActivity(name: "Deadlift", metric: .weightReps)
        let entry = makeEntry(workout: workout, activity: activity)
        _ = makeSet(entry: entry, weightKg: 140, reps: 3)
        let html = WorkoutHTMLFormatter.singleWorkoutHTML(workout: workout)
        XCTAssertTrue(html.contains("140"), "HTML should contain weight value")
    }

    func test_singleWorkout_distanceTime_containsDistance() {
        let workout = makeWorkout()
        let activity = makeActivity(name: "5K Run", category: .cardio, metric: .distanceTime)
        let entry = makeEntry(workout: workout, activity: activity)
        let s = CDEntrySet(context: context)
        s.id = UUID()
        s.setNumber = 1
        s.distanceMeters = 5000
        s.durationSeconds = 1500
        s.entry = entry
        let html = WorkoutHTMLFormatter.singleWorkoutHTML(workout: workout)
        XCTAssertTrue(html.contains("5.00"), "HTML should contain distance value")
    }

    func test_singleWorkout_noEntries_showsMessage() {
        let workout = makeWorkout()
        let html = WorkoutHTMLFormatter.singleWorkoutHTML(workout: workout)
        XCTAssertTrue(html.contains("No exercises"), "HTML should note empty workout")
    }

    // MARK: - Summary

    func test_summary_containsAllTitles() {
        let w1 = makeWorkout(title: "Push Day")
        let w2 = makeWorkout(title: "Pull Day")
        let from = Date().addingTimeInterval(-86400 * 7)
        let to = Date()
        let html = WorkoutHTMLFormatter.summaryHTML(workouts: [w1, w2], from: from, to: to)
        XCTAssertTrue(html.contains("Push Day"), "HTML should contain first workout title")
        XCTAssertTrue(html.contains("Pull Day"), "HTML should contain second workout title")
    }

    func test_summary_containsWorkoutCount() {
        let workouts = (0..<5).map { makeWorkout(title: "Workout \($0)") }
        let html = WorkoutHTMLFormatter.summaryHTML(workouts: workouts, from: Date(), to: Date())
        XCTAssertTrue(html.contains("5"), "HTML should contain total workout count")
    }

    func test_summary_empty_showsMessage() {
        let html = WorkoutHTMLFormatter.summaryHTML(workouts: [], from: Date(), to: Date())
        XCTAssertTrue(html.contains("No workouts"), "HTML should note empty period")
    }

    func test_summary_containsDateRange() {
        let from = Calendar.current.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let to = Calendar.current.date(from: DateComponents(year: 2026, month: 3, day: 31))!
        let html = WorkoutHTMLFormatter.summaryHTML(workouts: [], from: from, to: to)
        XCTAssertTrue(html.contains("2026"), "HTML should contain year from date range")
    }

    func test_summary_containsTotalDuration() {
        let w1 = makeWorkout(durationMinutes: 45)
        let w2 = makeWorkout(durationMinutes: 60)
        let html = WorkoutHTMLFormatter.summaryHTML(workouts: [w1, w2], from: Date(), to: Date())
        XCTAssertTrue(html.contains("105"), "HTML should contain total duration sum")
    }

    func test_summary_containsActivitySummary() {
        let workout = makeWorkout(title: "Chest Day")
        let activity = makeActivity(name: "Bench Press")
        _ = makeEntry(workout: workout, activity: activity)
        let html = WorkoutHTMLFormatter.summaryHTML(workouts: [workout], from: Date(), to: Date())
        XCTAssertTrue(html.contains("Bench Press"), "HTML should contain activity names in summary")
    }
}
