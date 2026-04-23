import XCTest
import CoreData
@testable import GymTracker

final class SetDeletionTests: XCTestCase {

    var context: NSManagedObjectContext!

    override func setUp() {
        super.setUp()
        context = CoreDataTestHelper.makeContext()
    }

    // MARK: - Helpers

    private func makeWorkout() -> CDWorkout {
        let w = CDWorkout(context: context)
        w.id = UUID()
        w.title = "Test"
        w.date = Date()
        return w
    }

    private func makeEntry(workout: CDWorkout) -> CDWorkoutEntry {
        let e = CDWorkoutEntry(context: context)
        e.id = UUID()
        e.orderIndex = 0
        let a = CDActivity(context: context)
        a.id = UUID()
        a.name = "Squat"
        a.category = ActivityCategory.strength.rawValue
        a.primaryMetric = PrimaryMetric.weightReps.rawValue
        e.activity = a
        e.workout = workout
        return e
    }

    private func addSet(to entry: CDWorkoutEntry, number: Int16, weightKg: Double = 100, reps: Int32 = 5) -> CDEntrySet {
        let s = CDEntrySet(context: context)
        s.id = UUID()
        s.setNumber = number
        s.weightKg = weightKg
        s.reps = reps
        s.entry = entry
        return s
    }

    // Mirrors the logic in EntryDetailCard.deleteSet(_:)
    private func deleteSet(_ set: CDEntrySet, from entry: CDWorkoutEntry) {
        context.delete(set)
        for (i, s) in entry.sortedSets.filter({ !$0.isDeleted }).enumerated() {
            s.setNumber = Int16(i + 1)
        }
        try? context.save()
    }

    // MARK: - Set count

    func test_deleteSet_decreasesSetCount() throws {
        let workout = makeWorkout()
        let entry = makeEntry(workout: workout)
        addSet(to: entry, number: 1)
        addSet(to: entry, number: 2)
        addSet(to: entry, number: 3)
        try context.save()

        let toDelete = entry.sortedSets[1]
        deleteSet(toDelete, from: entry)

        XCTAssertEqual(entry.sortedSets.count, 2)
    }

    func test_deleteSet_persistsCountAfterSave() throws {
        let workout = makeWorkout()
        let entry = makeEntry(workout: workout)
        addSet(to: entry, number: 1)
        addSet(to: entry, number: 2)
        try context.save()

        let toDelete = entry.sortedSets[0]
        deleteSet(toDelete, from: entry)

        let fetched = try context.fetch(CDEntrySet.fetchRequest())
        XCTAssertEqual(fetched.count, 1)
        _ = workout
    }

    // MARK: - Renumbering

    func test_deleteMiddleSet_renumbersRemainingSetsFrom1() throws {
        let workout = makeWorkout()
        let entry = makeEntry(workout: workout)
        addSet(to: entry, number: 1, weightKg: 60)
        addSet(to: entry, number: 2, weightKg: 70)
        addSet(to: entry, number: 3, weightKg: 80)
        try context.save()

        let middle = entry.sortedSets.first { $0.weightKg == 70 }!
        deleteSet(middle, from: entry)

        let remaining = entry.sortedSets
        XCTAssertEqual(remaining.count, 2)
        XCTAssertEqual(remaining[0].setNumber, 1)
        XCTAssertEqual(remaining[1].setNumber, 2)
        _ = workout
    }

    func test_deleteFirstSet_renumbersRemainingSetsFrom1() throws {
        let workout = makeWorkout()
        let entry = makeEntry(workout: workout)
        addSet(to: entry, number: 1, weightKg: 60)
        addSet(to: entry, number: 2, weightKg: 70)
        addSet(to: entry, number: 3, weightKg: 80)
        try context.save()

        let first = entry.sortedSets.first!
        deleteSet(first, from: entry)

        let remaining = entry.sortedSets
        XCTAssertEqual(remaining[0].setNumber, 1)
        XCTAssertEqual(remaining[1].setNumber, 2)
        _ = workout
    }

    func test_deleteLastSet_remainingSetsKeepCorrectNumbers() throws {
        let workout = makeWorkout()
        let entry = makeEntry(workout: workout)
        addSet(to: entry, number: 1, weightKg: 60)
        addSet(to: entry, number: 2, weightKg: 70)
        try context.save()

        let last = entry.sortedSets.last!
        deleteSet(last, from: entry)

        let remaining = entry.sortedSets
        XCTAssertEqual(remaining.count, 1)
        XCTAssertEqual(remaining[0].setNumber, 1)
        _ = workout
    }

    func test_deleteOnlySet_leavesEntryWithNoSets() throws {
        let workout = makeWorkout()
        let entry = makeEntry(workout: workout)
        let only = addSet(to: entry, number: 1)
        try context.save()

        deleteSet(only, from: entry)

        XCTAssertTrue(entry.sortedSets.isEmpty)
        _ = workout
    }

    // MARK: - Isolation

    func test_deleteSet_doesNotAffectOtherEntries() throws {
        let workout = makeWorkout()
        let entryA = makeEntry(workout: workout)
        let entryB = makeEntry(workout: workout)
        entryB.orderIndex = 1

        addSet(to: entryA, number: 1, weightKg: 100)
        addSet(to: entryA, number: 2, weightKg: 110)
        addSet(to: entryB, number: 1, weightKg: 50)
        try context.save()

        let toDelete = entryA.sortedSets.last!
        deleteSet(toDelete, from: entryA)

        XCTAssertEqual(entryA.sortedSets.count, 1)
        XCTAssertEqual(entryB.sortedSets.count, 1, "Deleting from entryA must not affect entryB")
        _ = workout
    }

    func test_deleteSet_setNumbersInSiblingEntryUnchanged() throws {
        let workout = makeWorkout()
        let entryA = makeEntry(workout: workout)
        let entryB = makeEntry(workout: workout)
        entryB.orderIndex = 1

        addSet(to: entryA, number: 1)
        addSet(to: entryA, number: 2)
        let siblingSet = addSet(to: entryB, number: 1, weightKg: 200)
        try context.save()

        deleteSet(entryA.sortedSets.last!, from: entryA)

        context.refresh(siblingSet, mergeChanges: true)
        XCTAssertEqual(siblingSet.setNumber, 1, "Sibling entry's set numbers must not be renumbered")
        _ = workout
    }

    // MARK: - Delete workout

    func test_deleteWorkout_removesWorkoutFromContext() throws {
        let workout = makeWorkout()
        try context.save()

        context.delete(workout)
        try context.save()

        XCTAssertTrue(try context.fetch(CDWorkout.fetchRequest()).isEmpty)
    }

    func test_deleteWorkout_cascadesEntriesAndSets() throws {
        let workout = makeWorkout()
        let entry = makeEntry(workout: workout)
        addSet(to: entry, number: 1)
        addSet(to: entry, number: 2)
        try context.save()

        context.delete(workout)
        try context.save()

        XCTAssertTrue(try context.fetch(CDWorkoutEntry.fetchRequest()).isEmpty)
        XCTAssertTrue(try context.fetch(CDEntrySet.fetchRequest()).isEmpty)
    }

    func test_deleteWorkout_doesNotAffectOtherWorkouts() throws {
        let w1 = makeWorkout()
        let w2 = makeWorkout()
        w2.title = "Keep"
        try context.save()

        context.delete(w1)
        try context.save()

        let remaining = try context.fetch(CDWorkout.fetchRequest())
        XCTAssertEqual(remaining.count, 1)
        XCTAssertEqual(remaining[0].title, "Keep")
    }
}
