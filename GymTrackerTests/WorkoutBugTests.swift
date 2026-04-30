import XCTest
import CoreData
@testable import GymTracker

final class WorkoutBugTests: XCTestCase {

    var context: NSManagedObjectContext!

    override func setUp() {
        super.setUp()
        context = CoreDataTestHelper.makeContext()
    }

    // MARK: - Helpers

    private func makeWorkout() -> CDWorkout {
        let w = CDWorkout(context: context)
        w.id = UUID()
        w.title = "Test Workout"
        w.date = Date()
        return w
    }

    private func makeActivity() -> CDActivity {
        let a = CDActivity(context: context)
        a.id = UUID()
        a.name = "Squat"
        a.category = ActivityCategory.strength.rawValue
        a.primaryMetric = PrimaryMetric.weightReps.rawValue
        a.icon = "dumbbell.fill"
        return a
    }

    private func makeEntry(workout: CDWorkout, activity: CDActivity, orderIndex: Int16 = 0) -> CDWorkoutEntry {
        let e = CDWorkoutEntry(context: context)
        e.id = UUID()
        e.orderIndex = orderIndex
        e.workout = workout
        e.activity = activity
        return e
    }

    private func makeSet(entry: CDWorkoutEntry, isPRAttempt: Bool = false) -> CDEntrySet {
        let s = CDEntrySet(context: context)
        s.id = UUID()
        s.setNumber = 1
        s.weightKg = 100
        s.reps = 5
        s.isPRAttempt = isPRAttempt
        s.entry = entry
        return s
    }

    // MARK: - isPRAttempt persistence

    func test_isPRAttempt_defaultIsFalse() {
        let s = CDEntrySet(context: context)
        XCTAssertFalse(s.isPRAttempt, "isPRAttempt should default to false")
    }

    func test_isPRAttempt_trueIsSavedAndFetched() throws {
        let workout = makeWorkout()
        let entry = makeEntry(workout: workout, activity: makeActivity())
        let set = makeSet(entry: entry, isPRAttempt: true)

        try context.save()

        let fetched = try context.fetch(CDEntrySet.fetchRequest())
        XCTAssertEqual(fetched.count, 1)
        XCTAssertTrue(fetched[0].isPRAttempt, "isPRAttempt=true must round-trip through Core Data")
        _ = set // silence unused warning
    }

    func test_isPRAttempt_falseIsSavedAndFetched() throws {
        let workout = makeWorkout()
        let entry = makeEntry(workout: workout, activity: makeActivity())
        let set = makeSet(entry: entry, isPRAttempt: false)

        try context.save()

        let fetched = try context.fetch(CDEntrySet.fetchRequest())
        XCTAssertFalse(fetched[0].isPRAttempt, "isPRAttempt=false must round-trip through Core Data")
        _ = set
    }

    func test_isPRAttempt_canBeToggledAndPersisted() throws {
        let workout = makeWorkout()
        let entry = makeEntry(workout: workout, activity: makeActivity())
        let set = makeSet(entry: entry, isPRAttempt: false)
        try context.save()

        set.isPRAttempt = true
        try context.save()

        context.refresh(set, mergeChanges: true)
        XCTAssertTrue(set.isPRAttempt, "isPRAttempt should reflect the updated value after re-save")
    }

    func test_isPRAttempt_multipleSetsMixedValues() throws {
        let workout = makeWorkout()
        let entry = makeEntry(workout: workout, activity: makeActivity())
        let prSet = makeSet(entry: entry, isPRAttempt: true)
        let normalSet = CDEntrySet(context: context)
        normalSet.id = UUID()
        normalSet.setNumber = 2
        normalSet.weightKg = 80
        normalSet.reps = 8
        normalSet.isPRAttempt = false
        normalSet.entry = entry
        try context.save()

        let fetched = try context.fetch(CDEntrySet.fetchRequest())
            .sorted { $0.setNumber < $1.setNumber }
        XCTAssertTrue(fetched[0].isPRAttempt)
        XCTAssertFalse(fetched[1].isPRAttempt)
        _ = prSet
    }

    func test_isPRAttempt_persistedThroughWorkoutEditorSave() throws {
        let activity = makeActivity()
        var liveSet = LiveSet()
        liveSet.weightKg = "100"
        liveSet.reps = "5"
        liveSet.isPRAttempt = true

        let data = WorkoutEditor.WorkoutData(
            title: "Test",
            date: Date(),
            energyLevel: 7,
            notes: "",
            entries: [LiveEntry(activity: activity, sets: [liveSet])]
        )

        let result = try WorkoutEditor.save(
            data: data,
            context: context,
            existingWorkout: nil,
            isDuplicate: false,
            startTime: Date(),
            intent: .complete
        )

        let savedSet = try XCTUnwrap(result.savedWorkout.sortedEntries.first?.sortedSets.first)
        XCTAssertTrue(savedSet.isPRAttempt, "isPRAttempt must be persisted through WorkoutEditor.save()")
    }

    // MARK: - Workout deletion

    func test_deleteWorkout_removesItFromContext() throws {
        let workout = makeWorkout()
        try context.save()

        context.delete(workout)
        try context.save()

        let remaining = try context.fetch(CDWorkout.fetchRequest())
        XCTAssertTrue(remaining.isEmpty, "Deleted workout should not appear in subsequent fetch")
    }

    func test_deleteWorkout_cascadesEntries() throws {
        let workout = makeWorkout()
        _ = makeEntry(workout: workout, activity: makeActivity())
        try context.save()

        context.delete(workout)
        try context.save()

        let entries = try context.fetch(CDWorkoutEntry.fetchRequest())
        XCTAssertTrue(entries.isEmpty, "Entries should be cascade-deleted with the workout")
    }

    func test_deleteWorkout_cascadesSets() throws {
        let workout = makeWorkout()
        let entry = makeEntry(workout: workout, activity: makeActivity())
        _ = makeSet(entry: entry)
        try context.save()

        context.delete(workout)
        try context.save()

        let sets = try context.fetch(CDEntrySet.fetchRequest())
        XCTAssertTrue(sets.isEmpty, "Sets should be cascade-deleted with the workout")
    }

    func test_deleteOneWorkout_leavesOthersIntact() throws {
        let w1 = makeWorkout()
        let w2 = makeWorkout()
        w2.title = "Keep Me"
        try context.save()

        context.delete(w1)
        try context.save()

        let remaining = try context.fetch(CDWorkout.fetchRequest())
        XCTAssertEqual(remaining.count, 1)
        XCTAssertEqual(remaining[0].title, "Keep Me")
    }

    // MARK: - Workout reactivity (Core Data update propagation)

    func test_addEntryToSavedWorkout_sortedEntriesReflectsAddition() throws {
        let workout = makeWorkout()
        try context.save()

        XCTAssertEqual(workout.sortedEntries.count, 0)

        let entry = makeEntry(workout: workout, activity: makeActivity())
        try context.save()

        XCTAssertEqual(workout.sortedEntries.count, 1,
            "sortedEntries must include the newly added entry without re-fetching the workout")
        _ = entry
    }

    func test_deleteEntryFromWorkout_sortedEntriesReflectsDeletion() throws {
        let workout = makeWorkout()
        let entry = makeEntry(workout: workout, activity: makeActivity())
        try context.save()

        XCTAssertEqual(workout.sortedEntries.count, 1)

        context.delete(entry)
        try context.save()

        XCTAssertEqual(workout.sortedEntries.count, 0,
            "sortedEntries must drop removed entries without re-fetching the workout")
    }
}
