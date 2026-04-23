import XCTest
import CoreData
@testable import GymTracker

/// Tests for the save/edit/duplicate logic in LogWorkoutView.save().
/// Each helper mirrors the exact Core Data operations the view performs
/// so the tests stay in sync with any refactor of the save path.
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

    // MARK: - Helpers (mirrors LogWorkoutView.save)

    private func makeActivity(name: String = "Squat", metric: PrimaryMetric = .weightReps) -> CDActivity {
        let a = CDActivity(context: context)
        a.id = UUID()
        a.name = name
        a.category = ActivityCategory.strength.rawValue
        a.primaryMetric = metric.rawValue
        a.isPreset = false
        return a
    }

    /// Performs the same Core Data mutations as LogWorkoutView.save() for a new workout.
    @discardableResult
    private func saveNewWorkout(
        title: String,
        date: Date = Date(),
        durationMinutes: String = "",
        energyLevel: Int = 7,
        notes: String = "",
        entries: [(activity: CDActivity, sets: [LiveSet], notes: String)] = []
    ) throws -> CDWorkout {
        let workout = CDWorkout(context: context)
        workout.id = UUID()
        workout.date = date
        workout.title = title.isEmpty ? "Workout" : title
        workout.durationMinutes = Int32(durationMinutes) ?? 0
        workout.energyLevel = Int16(energyLevel)
        workout.notes = notes.isEmpty ? nil : notes

        for (idx, liveEntry) in entries.enumerated() {
            let entry = CDWorkoutEntry(context: context)
            entry.id = UUID()
            entry.orderIndex = Int16(idx)
            entry.activity = liveEntry.activity
            entry.notes = liveEntry.notes.isEmpty ? nil : liveEntry.notes
            entry.workout = workout

            for (setIdx, liveSet) in liveEntry.sets.enumerated() {
                let set = CDEntrySet(context: context)
                set.id = UUID()
                set.setNumber = Int16(setIdx + 1)
                set.weightKg = Units.kgFromInput(Double(liveSet.weightKg) ?? 0)
                set.reps = Int32(liveSet.reps) ?? 0
                set.distanceMeters = Units.metersFromInput(Double(liveSet.distanceKm) ?? 0)
                set.durationSeconds = durationToSeconds(liveSet)
                set.laps = Int32(liveSet.laps) ?? 0
                set.customValue = Double(liveSet.customValue) ?? 0
                set.customLabel = liveSet.customLabel.isEmpty ? nil : liveSet.customLabel
                set.notes = liveSet.notes.isEmpty ? nil : liveSet.notes
                set.entry = entry
            }
        }

        try context.save()
        return workout
    }

    /// Performs the same Core Data mutations as LogWorkoutView.save() for editing an existing workout.
    private func saveEditWorkout(
        existing: CDWorkout,
        title: String,
        date: Date = Date(),
        durationMinutes: String = "",
        energyLevel: Int = 7,
        notes: String = "",
        entries: [(activity: CDActivity, sets: [LiveSet], notes: String)] = []
    ) throws {
        for entry in existing.sortedEntries {
            entry.sortedSets.forEach { context.delete($0) }
            context.delete(entry)
        }

        existing.date = date
        existing.title = title.isEmpty ? "Workout" : title
        existing.durationMinutes = Int32(durationMinutes) ?? existing.durationMinutes
        existing.energyLevel = Int16(energyLevel)
        existing.notes = notes.isEmpty ? nil : notes

        for (idx, liveEntry) in entries.enumerated() {
            let entry = CDWorkoutEntry(context: context)
            entry.id = UUID()
            entry.orderIndex = Int16(idx)
            entry.activity = liveEntry.activity
            entry.notes = liveEntry.notes.isEmpty ? nil : liveEntry.notes
            entry.workout = existing

            for (setIdx, liveSet) in liveEntry.sets.enumerated() {
                let set = CDEntrySet(context: context)
                set.id = UUID()
                set.setNumber = Int16(setIdx + 1)
                set.weightKg = Units.kgFromInput(Double(liveSet.weightKg) ?? 0)
                set.reps = Int32(liveSet.reps) ?? 0
                set.distanceMeters = Units.metersFromInput(Double(liveSet.distanceKm) ?? 0)
                set.durationSeconds = durationToSeconds(liveSet)
                set.laps = Int32(liveSet.laps) ?? 0
                set.customValue = Double(liveSet.customValue) ?? 0
                set.customLabel = liveSet.customLabel.isEmpty ? nil : liveSet.customLabel
                set.notes = liveSet.notes.isEmpty ? nil : liveSet.notes
                set.entry = entry
            }
        }

        try context.save()
    }

    private func durationToSeconds(_ set: LiveSet) -> Int32 {
        let m = Int32(set.durationMinutes) ?? 0
        let s = Int32(set.durationSeconds) ?? 0
        return m * 60 + s
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

    // MARK: - Workout metadata

    func test_save_workout_storesTitle() throws {
        let w = try saveNewWorkout(title: "Monday Push")
        XCTAssertEqual(w.title, "Monday Push")
    }

    func test_save_workout_emptyTitle_fallsBackToWorkout() throws {
        let w = try saveNewWorkout(title: "")
        XCTAssertEqual(w.title, "Workout")
    }

    func test_save_workout_storesDuration() throws {
        let w = try saveNewWorkout(title: "Test", durationMinutes: "45")
        XCTAssertEqual(w.durationMinutes, 45)
    }

    func test_save_workout_storesEnergyLevel() throws {
        let w = try saveNewWorkout(title: "Test", energyLevel: 9)
        XCTAssertEqual(w.energyLevel, 9)
    }

    func test_save_workout_storesNotes() throws {
        let w = try saveNewWorkout(title: "Test", notes: "Felt strong today")
        XCTAssertEqual(w.notes, "Felt strong today")
    }

    func test_save_workout_emptyNotes_storesNil() throws {
        let w = try saveNewWorkout(title: "Test", notes: "")
        XCTAssertNil(w.notes)
    }

    func test_save_workout_assignsUUID() throws {
        let w = try saveNewWorkout(title: "Test")
        XCTAssertNotNil(w.id)
    }

    func test_save_workout_appearsInFetch() throws {
        try saveNewWorkout(title: "Leg Day")
        let results = try context.fetch(CDWorkout.fetchRequest())
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].title, "Leg Day")
    }

    // MARK: - Entries

    func test_save_entries_countMatchesInput() throws {
        let a1 = makeActivity(name: "Squat")
        let a2 = makeActivity(name: "Press")
        let w = try saveNewWorkout(title: "Test", entries: [
            (a1, [liveSet(weightKg: "100", reps: "5")], ""),
            (a2, [liveSet(weightKg: "60", reps: "8")], ""),
        ])
        XCTAssertEqual(w.sortedEntries.count, 2)
    }

    func test_save_entries_orderIndexIsSequential() throws {
        let a1 = makeActivity(name: "A")
        let a2 = makeActivity(name: "B")
        let a3 = makeActivity(name: "C")
        let w = try saveNewWorkout(title: "Test", entries: [
            (a1, [liveSet()], ""),
            (a2, [liveSet()], ""),
            (a3, [liveSet()], ""),
        ])
        let indices = w.sortedEntries.map(\.orderIndex)
        XCTAssertEqual(indices, [0, 1, 2])
    }

    func test_save_entries_linkedToCorrectActivity() throws {
        let activity = makeActivity(name: "Deadlift")
        let w = try saveNewWorkout(title: "Test", entries: [
            (activity, [liveSet(weightKg: "180", reps: "3")], ""),
        ])
        XCTAssertEqual(w.sortedEntries.first?.activity?.name, "Deadlift")
    }

    func test_save_entry_storesNotes() throws {
        let a = makeActivity()
        let w = try saveNewWorkout(title: "Test", entries: [(a, [liveSet()], "Felt great")])
        XCTAssertEqual(w.sortedEntries.first?.notes, "Felt great")
    }

    func test_save_entry_emptyNotes_storesNil() throws {
        let a = makeActivity()
        let w = try saveNewWorkout(title: "Test", entries: [(a, [liveSet()], "")])
        XCTAssertNil(w.sortedEntries.first?.notes)
    }

    // MARK: - Sets

    func test_save_sets_countMatchesInput() throws {
        let a = makeActivity()
        let w = try saveNewWorkout(title: "Test", entries: [(a, [liveSet(), liveSet(), liveSet()], "")])
        XCTAssertEqual(w.sortedEntries.first?.sortedSets.count, 3)
    }

    func test_save_sets_numberedFrom1() throws {
        let a = makeActivity()
        let w = try saveNewWorkout(title: "Test", entries: [(a, [liveSet(), liveSet()], "")])
        let numbers = w.sortedEntries.first?.sortedSets.map(\.setNumber)
        XCTAssertEqual(numbers, [1, 2])
    }

    func test_save_set_storesWeightKg_metric() throws {
        let a = makeActivity()
        let w = try saveNewWorkout(title: "Test", entries: [(a, [liveSet(weightKg: "100")], "")])
        XCTAssertEqual(w.sortedEntries.first?.sortedSets.first?.weightKg ?? 0, 100, accuracy: 0.01)
    }

    func test_save_set_storesReps() throws {
        let a = makeActivity()
        let w = try saveNewWorkout(title: "Test", entries: [(a, [liveSet(reps: "8")], "")])
        XCTAssertEqual(w.sortedEntries.first?.sortedSets.first?.reps, 8)
    }

    func test_save_set_storesDistanceMeters_metric() throws {
        let a = makeActivity(name: "Run", metric: .distanceTime)
        let w = try saveNewWorkout(title: "Test", entries: [(a, [liveSet(distanceKm: "5")], "")])
        XCTAssertEqual(w.sortedEntries.first?.sortedSets.first?.distanceMeters ?? 0, 5000, accuracy: 0.1)
    }

    func test_save_set_storesDurationSeconds() throws {
        let a = makeActivity(name: "Row", metric: .duration)
        let w = try saveNewWorkout(title: "Test", entries: [(a, [liveSet(durationMinutes: "2", durationSeconds: "30")], "")])
        XCTAssertEqual(w.sortedEntries.first?.sortedSets.first?.durationSeconds, 150)
    }

    func test_save_set_storesLaps() throws {
        let a = makeActivity(name: "Swim", metric: .lapsTime)
        let w = try saveNewWorkout(title: "Test", entries: [(a, [liveSet(laps: "20")], "")])
        XCTAssertEqual(w.sortedEntries.first?.sortedSets.first?.laps, 20)
    }

    func test_save_set_storesCustomValueAndLabel() throws {
        let a = makeActivity(name: "Stretch", metric: .custom)
        let w = try saveNewWorkout(title: "Test", entries: [(a, [liveSet(customValue: "12.5", customLabel: "reps")], "")])
        let set = w.sortedEntries.first?.sortedSets.first
        XCTAssertEqual(set?.customValue ?? 0, 12.5, accuracy: 0.001)
        XCTAssertEqual(set?.customLabel, "reps")
    }

    func test_save_set_emptyCustomLabel_storesNil() throws {
        let a = makeActivity(metric: .custom)
        let w = try saveNewWorkout(title: "Test", entries: [(a, [liveSet(customValue: "5", customLabel: "")], "")])
        XCTAssertNil(w.sortedEntries.first?.sortedSets.first?.customLabel)
    }

    func test_save_set_storesNotes() throws {
        let a = makeActivity()
        let w = try saveNewWorkout(title: "Test", entries: [(a, [liveSet(notes: "felt heavy")], "")])
        XCTAssertEqual(w.sortedEntries.first?.sortedSets.first?.notes, "felt heavy")
    }

    func test_save_set_emptyNotes_storesNil() throws {
        let a = makeActivity()
        let w = try saveNewWorkout(title: "Test", entries: [(a, [liveSet(notes: "")], "")])
        XCTAssertNil(w.sortedEntries.first?.sortedSets.first?.notes)
    }

    // MARK: - Edit existing workout

    func test_edit_replacesOldEntriesWithNew() throws {
        let a1 = makeActivity(name: "Old")
        let a2 = makeActivity(name: "New")
        let w = try saveNewWorkout(title: "Test", entries: [(a1, [liveSet(weightKg: "50", reps: "10")], "")])
        let originalEntryID = w.sortedEntries.first?.id

        try saveEditWorkout(existing: w, title: "Edited", entries: [(a2, [liveSet(weightKg: "80", reps: "5")], "")])

        XCTAssertEqual(w.sortedEntries.count, 1)
        XCTAssertNotEqual(w.sortedEntries.first?.id, originalEntryID, "Edit must create a new entry, not reuse the old one")
        XCTAssertEqual(w.sortedEntries.first?.activity?.name, "New")
    }

    func test_edit_removesOrphanedSets() throws {
        let a = makeActivity()
        let w = try saveNewWorkout(title: "Test", entries: [(a, [liveSet(), liveSet(), liveSet()], "")])
        XCTAssertEqual(try context.fetch(CDEntrySet.fetchRequest()).count, 3)

        try saveEditWorkout(existing: w, title: "Edited", entries: [(a, [liveSet()], "")])

        XCTAssertEqual(try context.fetch(CDEntrySet.fetchRequest()).count, 1, "Old sets must be deleted during edit")
    }

    func test_edit_removesOrphanedEntries() throws {
        let a1 = makeActivity(name: "A")
        let a2 = makeActivity(name: "B")
        let w = try saveNewWorkout(title: "Test", entries: [(a1, [liveSet()], ""), (a2, [liveSet()], "")])
        XCTAssertEqual(try context.fetch(CDWorkoutEntry.fetchRequest()).count, 2)

        try saveEditWorkout(existing: w, title: "Edited", entries: [(a1, [liveSet()], "")])

        XCTAssertEqual(try context.fetch(CDWorkoutEntry.fetchRequest()).count, 1, "Removed entries must be deleted during edit")
    }

    func test_edit_updatesWorkoutTitle() throws {
        let w = try saveNewWorkout(title: "Original")
        try saveEditWorkout(existing: w, title: "Updated")
        XCTAssertEqual(w.title, "Updated")
    }

    func test_edit_workoutCountRemainsOne() throws {
        let w = try saveNewWorkout(title: "Test")
        try saveEditWorkout(existing: w, title: "Edited")
        XCTAssertEqual(try context.fetch(CDWorkout.fetchRequest()).count, 1)
    }

    // MARK: - Duplicate workout

    func test_duplicate_createsNewWorkout() throws {
        let a = makeActivity()
        let original = try saveNewWorkout(title: "Push Day", entries: [(a, [liveSet(weightKg: "60", reps: "10")], "")])
        let originalID = original.id

        // Duplicate: same as new, does not touch existing
        let duplicate = try saveNewWorkout(title: "Push Day", entries: [(a, [liveSet(weightKg: "60", reps: "10")], "")])

        XCTAssertNotEqual(duplicate.id, originalID, "Duplicate must have a new UUID")
        XCTAssertEqual(try context.fetch(CDWorkout.fetchRequest()).count, 2)
    }

    func test_duplicate_originalUnchanged() throws {
        let a = makeActivity()
        let original = try saveNewWorkout(title: "Push Day", entries: [(a, [liveSet(weightKg: "60", reps: "10")], "")])
        let originalEntryID = original.sortedEntries.first?.id

        _ = try saveNewWorkout(title: "Push Day Copy", entries: [(a, [liveSet(weightKg: "70", reps: "8")], "")])

        XCTAssertEqual(original.sortedEntries.first?.id, originalEntryID)
        XCTAssertEqual(original.sortedEntries.first?.sortedSets.first?.weightKg ?? 0, 60, accuracy: 0.1)
    }

    // MARK: - Re-fetch from store (verifies actual persistence, not just in-memory state)

    func test_save_workout_persistsTitle_afterRefetch() throws {
        let saved = try saveNewWorkout(title: "Leg Day")
        let id = saved.id
        context.refresh(saved, mergeChanges: false)

        let fetched = try context.fetch(CDWorkout.fetchRequest())
        XCTAssertEqual(fetched.first(where: { $0.id == id })?.title, "Leg Day",
            "Title must survive a context refresh (confirms the store write succeeded)")
    }

    func test_save_set_weightKg_persistsAfterRefetch() throws {
        let a = makeActivity()
        let w = try saveNewWorkout(title: "Test", entries: [(a, [liveSet(weightKg: "100", reps: "5")], "")])
        let setID = w.sortedEntries.first?.sortedSets.first?.id
        context.refreshAllObjects()

        let sets = try context.fetch(CDEntrySet.fetchRequest())
        let refetched = sets.first(where: { $0.id == setID })
        XCTAssertEqual(refetched?.weightKg ?? 0, 100, accuracy: 0.01,
            "weightKg must survive a context refresh (confirms the store write succeeded)")
    }

    func test_save_entry_linkedToWorkout_persistsAfterRefetch() throws {
        let a = makeActivity()
        let w = try saveNewWorkout(title: "Test", entries: [(a, [liveSet()], "")])
        let wid = w.id
        context.refreshAllObjects()

        let workouts = try context.fetch(CDWorkout.fetchRequest())
        let refetched = workouts.first(where: { $0.id == wid })
        XCTAssertEqual(refetched?.sortedEntries.count, 1,
            "Entry→workout relationship must survive a context refresh")
    }

    func test_edit_changesPersistedAfterRefetch() throws {
        let a = makeActivity()
        let w = try saveNewWorkout(title: "Original", entries: [(a, [liveSet(weightKg: "50", reps: "5")], "")])
        let wid = w.id

        try saveEditWorkout(existing: w, title: "Updated", entries: [(a, [liveSet(weightKg: "60", reps: "8")], "")])
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

        // Simulate the rollback path in LogWorkoutView.save()
        context.rollback()

        let fetched = try context.fetch(CDWorkout.fetchRequest())
        XCTAssertTrue(fetched.isEmpty, "Rollback must discard all unsaved changes")
    }

    func test_rollback_doesNotAffectAlreadySavedWorkouts() throws {
        let existing = try saveNewWorkout(title: "Existing")

        // Add an unsaved object then roll back
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
        let w = try saveNewWorkout(title: "Test", entries: [(a, [liveSet(weightKg: "abc")], "")])
        XCTAssertEqual(w.sortedEntries.first?.sortedSets.first?.weightKg ?? -1, 0, accuracy: 0.001)
    }

    func test_save_set_invalidRepsInput_defaultsToZero() throws {
        let a = makeActivity()
        let w = try saveNewWorkout(title: "Test", entries: [(a, [liveSet(reps: "abc")], "")])
        XCTAssertEqual(w.sortedEntries.first?.sortedSets.first?.reps, 0)
    }

    func test_save_set_invalidDuration_defaultsToZero() throws {
        let a = makeActivity(name: "Plank", metric: .duration)
        let w = try saveNewWorkout(title: "Test", entries: [(a, [liveSet(durationMinutes: "x", durationSeconds: "y")], "")])
        XCTAssertEqual(w.sortedEntries.first?.sortedSets.first?.durationSeconds, 0)
    }

    // MARK: - Imperial unit conversion

    func test_save_set_weightConvertsFromLbs_imperial() throws {
        Units._testOverrideIsMetric = false
        let a = makeActivity()
        // User types "220" lbs — should store ~99.8 kg
        let w = try saveNewWorkout(title: "Test", entries: [(a, [liveSet(weightKg: "220")], "")])
        let stored = w.sortedEntries.first?.sortedSets.first?.weightKg ?? 0
        XCTAssertEqual(stored, Units.kgFromInput(220), accuracy: 0.01)
        XCTAssertLessThan(stored, 110, "220 lbs must be stored as ~99.8 kg, not 220 kg")
    }

    func test_save_set_distanceConvertsFromMiles_imperial() throws {
        Units._testOverrideIsMetric = false
        let a = makeActivity(name: "Run", metric: .distanceTime)
        // User types "1" mile — should store ~1609 meters
        let w = try saveNewWorkout(title: "Test", entries: [(a, [liveSet(distanceKm: "1")], "")])
        let stored = w.sortedEntries.first?.sortedSets.first?.distanceMeters ?? 0
        XCTAssertEqual(stored, Units.metersFromInput(1), accuracy: 1)
        XCTAssertGreaterThan(stored, 1600, "1 mile must be stored as ~1609 meters, not 1 meter")
    }
}
