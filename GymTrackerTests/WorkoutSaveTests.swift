import XCTest
import CoreData
@testable import GymTracker

/// Tests for WorkoutEditor.save() — the single source of truth for creating/editing workouts.
/// All tests go through the real service so any logic change in WorkoutEditor is caught here.
final class WorkoutSaveTests: XCTestCase {

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

    // MARK: - Factories

    private func makeActivity(name: String = "Squat", metric: PrimaryMetric = .weightReps) -> CDActivity {
        let a = CDActivity(context: context)
        a.id = UUID()
        a.name = name
        a.category = ActivityCategory.strength.rawValue
        a.primaryMetric = metric.rawValue
        a.isPreset = false
        return a
    }

    private func liveSet(
        weightKg: String = "",
        reps: String = "",
        distanceKm: String = "",
        durationMinutes: String = "",
        durationSeconds: String = "",
        laps: String = "",
        customValue: String = "",
        customLabel: String = "",
        notes: String = ""
    ) -> LiveSet {
        var s = LiveSet()
        s.weightKg = weightKg
        s.reps = reps
        s.distanceKm = distanceKm
        s.durationMinutes = durationMinutes
        s.durationSeconds = durationSeconds
        s.laps = laps
        s.customValue = customValue
        s.customLabel = customLabel
        s.notes = notes
        return s
    }

    /// Convenience: saves a new workout via the real WorkoutEditor and returns it.
    @discardableResult
    private func saveNew(
        title: String = "Test",
        date: Date = Date(),
        energyLevel: Int = 7,
        notes: String = "",
        entries: [(CDActivity, [LiveSet], String)] = [],
        intent: WorkoutEditor.SaveIntent = .complete,
        completedAt: Date? = nil
    ) throws -> CDWorkout {
        let data = WorkoutEditor.WorkoutData(
            title: title,
            date: date,
            energyLevel: energyLevel,
            notes: notes,
            entries: entries.map { LiveEntry(activity: $0.0, sets: $0.1, notes: $0.2) }
        )
        return try WorkoutEditor.save(
            data: data,
            context: context,
            existingWorkout: nil,
            isDuplicate: false,
            startTime: date,
            intent: intent,
            completedAt: completedAt ?? date
        ).savedWorkout
    }

    /// Convenience: edits an existing workout via the real WorkoutEditor.
    private func saveEdit(
        existing: CDWorkout,
        title: String = "Test",
        date: Date = Date(),
        energyLevel: Int = 7,
        notes: String = "",
        entries: [(CDActivity, [LiveSet], String)] = [],
        intent: WorkoutEditor.SaveIntent = .complete,
        completedAt: Date? = nil
    ) throws {
        let data = WorkoutEditor.WorkoutData(
            title: title,
            date: date,
            energyLevel: energyLevel,
            notes: notes,
            entries: entries.map { LiveEntry(activity: $0.0, sets: $0.1, notes: $0.2) }
        )
        try WorkoutEditor.save(
            data: data,
            context: context,
            existingWorkout: existing,
            isDuplicate: false,
            startTime: date,
            intent: intent,
            completedAt: completedAt ?? date
        )
    }

    // MARK: - Workout metadata

    func test_save_workout_storesTitle() throws {
        let w = try saveNew(title: "Monday Push")
        XCTAssertEqual(w.title, "Monday Push")
    }

    func test_save_workout_emptyTitle_fallsBackToWorkout() throws {
        let w = try saveNew(title: "")
        XCTAssertEqual(w.title, "Workout")
    }

    func test_save_workout_storesCalculatedDurationFromStartAndCompletionTimes() throws {
        let start = Date(timeIntervalSinceReferenceDate: 1_000)
        let completedAt = start.addingTimeInterval(45 * 60)
        let w = try saveNew(title: "Test", date: start, completedAt: completedAt)
        XCTAssertEqual(w.durationMinutes, 45)
    }

    func test_save_progress_marksWorkoutInProgress() throws {
        let start = Date(timeIntervalSinceReferenceDate: 1_000)
        let savedAt = start.addingTimeInterval(15 * 60)
        let workout = try saveNew(
            title: "Leg Day",
            date: start,
            intent: .saveProgress,
            completedAt: savedAt
        )

        XCTAssertFalse(workout.isCompleted)
        XCTAssertEqual(workout.startedAt, start)
        XCTAssertEqual(workout.durationMinutes, 15)
    }

    func test_complete_workout_marksWorkoutCompleted() throws {
        let start = Date(timeIntervalSinceReferenceDate: 1_000)
        let completedAt = start.addingTimeInterval(32 * 60)
        let workout = try saveNew(title: "Leg Day", date: start, completedAt: completedAt)

        XCTAssertTrue(workout.isCompleted)
        XCTAssertEqual(workout.startedAt, start)
        XCTAssertEqual(workout.durationMinutes, 32)
    }

    func test_completingInProgressWorkoutUpdatesDurationFromOriginalStartTime() throws {
        let start = Date(timeIntervalSinceReferenceDate: 1_000)
        let progressSavedAt = start.addingTimeInterval(10 * 60)
        let completedAt = start.addingTimeInterval(28 * 60)
        let workout = try saveNew(
            title: "Pull Day",
            date: start,
            intent: .saveProgress,
            completedAt: progressSavedAt
        )

        try saveEdit(
            existing: workout,
            title: "Pull Day",
            date: start,
            intent: .complete,
            completedAt: completedAt
        )

        XCTAssertTrue(workout.isCompleted)
        XCTAssertEqual(workout.durationMinutes, 28)
        XCTAssertEqual(workout.startedAt, start)
    }

    func test_editingCompletedWorkoutPreservesStoredDuration() throws {
        let start = Date(timeIntervalSinceReferenceDate: 1_000)
        let completedAt = start.addingTimeInterval(40 * 60)
        let workout = try saveNew(title: "Upper", date: start, completedAt: completedAt)

        try saveEdit(
            existing: workout,
            title: "Upper Updated",
            date: start.addingTimeInterval(86_400),
            intent: .complete,
            completedAt: completedAt.addingTimeInterval(999)
        )

        XCTAssertEqual(workout.durationMinutes, 40, "Editing a completed workout later should not recalculate duration from the current clock")
    }

    func test_save_workout_storesEnergyLevel() throws {
        let w = try saveNew(title: "Test", energyLevel: 9)
        XCTAssertEqual(w.energyLevel, 9)
    }

    func test_save_workout_storesNotes() throws {
        let w = try saveNew(title: "Test", notes: "Felt strong today")
        XCTAssertEqual(w.notes, "Felt strong today")
    }

    func test_save_workout_emptyNotes_storesNil() throws {
        let w = try saveNew(title: "Test", notes: "")
        XCTAssertNil(w.notes)
    }

    func test_save_workout_assignsUUID() throws {
        let w = try saveNew()
        XCTAssertNotNil(w.id)
    }

    func test_save_workout_appearsInFetch() throws {
        try saveNew(title: "Leg Day")
        let results = try context.fetch(CDWorkout.fetchRequest())
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].title, "Leg Day")
    }

    // MARK: - Entries

    func test_save_entries_countMatchesInput() throws {
        let a1 = makeActivity(name: "Squat")
        let a2 = makeActivity(name: "Press")
        let w = try saveNew(entries: [
            (a1, [liveSet(weightKg: "100", reps: "5")], ""),
            (a2, [liveSet(weightKg: "60",  reps: "8")], ""),
        ])
        XCTAssertEqual(w.sortedEntries.count, 2)
    }

    func test_save_entries_orderIndexIsSequential() throws {
        let a1 = makeActivity(name: "A")
        let a2 = makeActivity(name: "B")
        let a3 = makeActivity(name: "C")
        let w = try saveNew(entries: [(a1, [liveSet()], ""), (a2, [liveSet()], ""), (a3, [liveSet()], "")])
        XCTAssertEqual(w.sortedEntries.map(\.orderIndex), [0, 1, 2])
    }

    func test_save_entries_linkedToCorrectActivity() throws {
        let activity = makeActivity(name: "Deadlift")
        let w = try saveNew(entries: [(activity, [liveSet(weightKg: "180", reps: "3")], "")])
        XCTAssertEqual(w.sortedEntries.first?.activity?.name, "Deadlift")
    }

    func test_save_entry_storesNotes() throws {
        let a = makeActivity()
        let w = try saveNew(entries: [(a, [liveSet()], "Felt great")])
        XCTAssertEqual(w.sortedEntries.first?.notes, "Felt great")
    }

    func test_save_entry_emptyNotes_storesNil() throws {
        let a = makeActivity()
        let w = try saveNew(entries: [(a, [liveSet()], "")])
        XCTAssertNil(w.sortedEntries.first?.notes)
    }

    // MARK: - Sets

    func test_save_sets_countMatchesInput() throws {
        let a = makeActivity()
        let w = try saveNew(entries: [(a, [liveSet(), liveSet(), liveSet()], "")])
        XCTAssertEqual(w.sortedEntries.first?.sortedSets.count, 3)
    }

    func test_save_sets_numberedFrom1() throws {
        let a = makeActivity()
        let w = try saveNew(entries: [(a, [liveSet(), liveSet()], "")])
        XCTAssertEqual(w.sortedEntries.first?.sortedSets.map(\.setNumber), [1, 2])
    }

    func test_save_set_storesWeightKg_metric() throws {
        let a = makeActivity()
        let w = try saveNew(entries: [(a, [liveSet(weightKg: "100")], "")])
        XCTAssertEqual(w.sortedEntries.first?.sortedSets.first?.weightKg ?? 0, 100, accuracy: 0.01)
    }

    func test_save_set_storesReps() throws {
        let a = makeActivity()
        let w = try saveNew(entries: [(a, [liveSet(reps: "8")], "")])
        XCTAssertEqual(w.sortedEntries.first?.sortedSets.first?.reps, 8)
    }

    func test_save_set_storesDistanceMeters_metric() throws {
        let a = makeActivity(name: "Run", metric: .distanceTime)
        let w = try saveNew(entries: [(a, [liveSet(distanceKm: "5")], "")])
        XCTAssertEqual(w.sortedEntries.first?.sortedSets.first?.distanceMeters ?? 0, 5000, accuracy: 0.1)
    }

    func test_save_set_storesDurationSeconds() throws {
        let a = makeActivity(name: "Row", metric: .duration)
        let w = try saveNew(entries: [(a, [liveSet(durationMinutes: "2", durationSeconds: "30")], "")])
        XCTAssertEqual(w.sortedEntries.first?.sortedSets.first?.durationSeconds, 150)
    }

    func test_save_set_storesLaps() throws {
        let a = makeActivity(name: "Swim", metric: .lapsTime)
        let w = try saveNew(entries: [(a, [liveSet(laps: "20")], "")])
        XCTAssertEqual(w.sortedEntries.first?.sortedSets.first?.laps, 20)
    }

    func test_save_set_storesCustomValueAndLabel() throws {
        let a = makeActivity(name: "Stretch", metric: .custom)
        let w = try saveNew(entries: [(a, [liveSet(customValue: "12.5", customLabel: "reps")], "")])
        let set = w.sortedEntries.first?.sortedSets.first
        XCTAssertEqual(set?.customValue ?? 0, 12.5, accuracy: 0.001)
        XCTAssertEqual(set?.customLabel, "reps")
    }

    func test_save_set_emptyCustomLabel_storesNil() throws {
        let a = makeActivity(metric: .custom)
        let w = try saveNew(entries: [(a, [liveSet(customValue: "5", customLabel: "")], "")])
        XCTAssertNil(w.sortedEntries.first?.sortedSets.first?.customLabel)
    }

    func test_save_set_storesNotes() throws {
        let a = makeActivity()
        let w = try saveNew(entries: [(a, [liveSet(notes: "felt heavy")], "")])
        XCTAssertEqual(w.sortedEntries.first?.sortedSets.first?.notes, "felt heavy")
    }

    func test_save_set_emptyNotes_storesNil() throws {
        let a = makeActivity()
        let w = try saveNew(entries: [(a, [liveSet(notes: "")], "")])
        XCTAssertNil(w.sortedEntries.first?.sortedSets.first?.notes)
    }

    // MARK: - Edit existing workout

    func test_edit_replacesOldEntriesWithNew() throws {
        let a1 = makeActivity(name: "Old")
        let a2 = makeActivity(name: "New")
        let w = try saveNew(entries: [(a1, [liveSet(weightKg: "50", reps: "10")], "")])
        let originalEntryID = w.sortedEntries.first?.id

        try saveEdit(existing: w, title: "Edited", entries: [(a2, [liveSet(weightKg: "80", reps: "5")], "")])

        XCTAssertEqual(w.sortedEntries.count, 1)
        XCTAssertNotEqual(w.sortedEntries.first?.id, originalEntryID, "Edit must create a new entry, not reuse the old one")
        XCTAssertEqual(w.sortedEntries.first?.activity?.name, "New")
    }

    func test_edit_removesOrphanedSets() throws {
        let a = makeActivity()
        let w = try saveNew(entries: [(a, [liveSet(), liveSet(), liveSet()], "")])
        XCTAssertEqual(try context.fetch(CDEntrySet.fetchRequest()).count, 3)

        try saveEdit(existing: w, title: "Edited", entries: [(a, [liveSet()], "")])

        XCTAssertEqual(try context.fetch(CDEntrySet.fetchRequest()).count, 1, "Old sets must be deleted during edit")
    }

    func test_edit_removesOrphanedEntries() throws {
        let a1 = makeActivity(name: "A")
        let a2 = makeActivity(name: "B")
        let w = try saveNew(entries: [(a1, [liveSet()], ""), (a2, [liveSet()], "")])
        XCTAssertEqual(try context.fetch(CDWorkoutEntry.fetchRequest()).count, 2)

        try saveEdit(existing: w, title: "Edited", entries: [(a1, [liveSet()], "")])

        XCTAssertEqual(try context.fetch(CDWorkoutEntry.fetchRequest()).count, 1, "Removed entries must be deleted during edit")
    }

    func test_edit_updatesWorkoutTitle() throws {
        let w = try saveNew(title: "Original")
        try saveEdit(existing: w, title: "Updated")
        XCTAssertEqual(w.title, "Updated")
    }

    func test_edit_workoutCountRemainsOne() throws {
        let w = try saveNew()
        try saveEdit(existing: w, title: "Edited")
        XCTAssertEqual(try context.fetch(CDWorkout.fetchRequest()).count, 1)
    }

    // MARK: - Duplicate workout

    func test_duplicate_createsNewWorkout() throws {
        let a = makeActivity()
        let original = try saveNew(title: "Push Day", entries: [(a, [liveSet(weightKg: "60", reps: "10")], "")])
        let originalID = original.id

        let data = WorkoutEditor.WorkoutData(
            title: "Push Day", date: Date(), energyLevel: 7, notes: "",
            entries: [LiveEntry(activity: a, sets: [liveSet(weightKg: "60", reps: "10")], notes: "")]
        )
        let duplicate = try WorkoutEditor.save(
            data: data,
            context: context,
            existingWorkout: original,
            isDuplicate: true,
            startTime: Date(),
            intent: .complete,
            completedAt: Date()
        ).savedWorkout

        XCTAssertNotEqual(duplicate.id, originalID, "Duplicate must have a new UUID")
        XCTAssertEqual(try context.fetch(CDWorkout.fetchRequest()).count, 2)
    }

    func test_duplicate_originalUnchanged() throws {
        let a = makeActivity()
        let original = try saveNew(title: "Push Day", entries: [(a, [liveSet(weightKg: "60", reps: "10")], "")])
        let originalEntryID = original.sortedEntries.first?.id

        let data = WorkoutEditor.WorkoutData(
            title: "Push Day Copy", date: Date(), energyLevel: 7, notes: "",
            entries: [LiveEntry(activity: a, sets: [liveSet(weightKg: "70", reps: "8")], notes: "")]
        )
        try WorkoutEditor.save(
            data: data,
            context: context,
            existingWorkout: original,
            isDuplicate: true,
            startTime: Date(),
            intent: .complete,
            completedAt: Date()
        )

        XCTAssertEqual(original.sortedEntries.first?.id, originalEntryID)
        XCTAssertEqual(original.sortedEntries.first?.sortedSets.first?.weightKg ?? 0, 60, accuracy: 0.1)
    }

    // MARK: - Re-fetch from store

    func test_save_workout_persistsTitle_afterRefetch() throws {
        let saved = try saveNew(title: "Leg Day")
        let id = saved.id
        context.refresh(saved, mergeChanges: false)

        let fetched = try context.fetch(CDWorkout.fetchRequest())
        XCTAssertEqual(fetched.first(where: { $0.id == id })?.title, "Leg Day",
            "Title must survive a context refresh")
    }

    func test_save_set_weightKg_persistsAfterRefetch() throws {
        let a = makeActivity()
        let w = try saveNew(entries: [(a, [liveSet(weightKg: "100", reps: "5")], "")])
        let setID = w.sortedEntries.first?.sortedSets.first?.id
        context.refreshAllObjects()

        let sets = try context.fetch(CDEntrySet.fetchRequest())
        let refetched = sets.first(where: { $0.id == setID })
        XCTAssertEqual(refetched?.weightKg ?? 0, 100, accuracy: 0.01,
            "weightKg must survive a context refresh")
    }

    func test_save_entry_linkedToWorkout_persistsAfterRefetch() throws {
        let a = makeActivity()
        let w = try saveNew(entries: [(a, [liveSet()], "")])
        let wid = w.id
        context.refreshAllObjects()

        let workouts = try context.fetch(CDWorkout.fetchRequest())
        XCTAssertEqual(workouts.first(where: { $0.id == wid })?.sortedEntries.count, 1,
            "Entry→workout relationship must survive a context refresh")
    }

    func test_edit_changesPersistedAfterRefetch() throws {
        let a = makeActivity()
        let w = try saveNew(title: "Original", entries: [(a, [liveSet(weightKg: "50", reps: "5")], "")])
        let wid = w.id

        try saveEdit(existing: w, title: "Updated", entries: [(a, [liveSet(weightKg: "60", reps: "8")], "")])
        context.refreshAllObjects()

        let fetched = try context.fetch(CDWorkout.fetchRequest())
        let refetched = fetched.first(where: { $0.id == wid })
        XCTAssertEqual(refetched?.title, "Updated")
        XCTAssertEqual(refetched?.sortedEntries.first?.sortedSets.first?.weightKg ?? 0, 60, accuracy: 0.01)
    }

    // MARK: - Rollback on failure

    func test_rollback_discardsUnsavedWorkout() throws {
        let workout = CDWorkout(context: context)
        workout.id = UUID()
        workout.title = "Never Saved"
        workout.date = Date()
        context.rollback()

        XCTAssertTrue(try context.fetch(CDWorkout.fetchRequest()).isEmpty, "Rollback must discard all unsaved changes")
    }

    func test_rollback_doesNotAffectAlreadySavedWorkouts() throws {
        let existing = try saveNew(title: "Existing")
        let unsaved = CDWorkout(context: context)
        unsaved.id = UUID()
        unsaved.title = "Unsaved"
        unsaved.date = Date()
        context.rollback()

        let fetched = try context.fetch(CDWorkout.fetchRequest())
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched[0].id, existing.id, "Rollback must not affect previously committed workouts")
    }

    // MARK: - Invalid input defaults

    func test_save_set_invalidWeightInput_defaultsToZero() throws {
        let a = makeActivity()
        let w = try saveNew(entries: [(a, [liveSet(weightKg: "abc")], "")])
        XCTAssertEqual(w.sortedEntries.first?.sortedSets.first?.weightKg ?? -1, 0, accuracy: 0.001)
    }

    func test_save_set_invalidRepsInput_defaultsToZero() throws {
        let a = makeActivity()
        let w = try saveNew(entries: [(a, [liveSet(reps: "abc")], "")])
        XCTAssertEqual(w.sortedEntries.first?.sortedSets.first?.reps, 0)
    }

    func test_save_set_invalidDuration_defaultsToZero() throws {
        let a = makeActivity(name: "Plank", metric: .duration)
        let w = try saveNew(entries: [(a, [liveSet(durationMinutes: "x", durationSeconds: "y")], "")])
        XCTAssertEqual(w.sortedEntries.first?.sortedSets.first?.durationSeconds, 0)
    }

    // MARK: - Imperial unit conversion

    func test_save_set_weightConvertsFromLbs_imperial() throws {
        Units._testOverrideIsMetric = false
        let a = makeActivity()
        let w = try saveNew(entries: [(a, [liveSet(weightKg: "220")], "")])
        let stored = w.sortedEntries.first?.sortedSets.first?.weightKg ?? 0
        XCTAssertEqual(stored, Units.kgFromInput(220), accuracy: 0.01)
        XCTAssertLessThan(stored, 110, "220 lbs must be stored as ~99.8 kg, not 220 kg")
    }

    func test_save_set_distanceConvertsFromMiles_imperial() throws {
        Units._testOverrideIsMetric = false
        let a = makeActivity(name: "Run", metric: .distanceTime)
        let w = try saveNew(entries: [(a, [liveSet(distanceKm: "1")], "")])
        let stored = w.sortedEntries.first?.sortedSets.first?.distanceMeters ?? 0
        XCTAssertEqual(stored, Units.metersFromInput(1), accuracy: 1)
        XCTAssertGreaterThan(stored, 1600, "1 mile must be stored as ~1609 meters, not 1 meter")
    }
}
