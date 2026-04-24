import XCTest
import CoreData
@testable import GymTracker

// Tests for in-memory LiveEntry model operations that back EntrySection's
// swipe-to-delete and activity-removal behaviour.
final class LiveEntryTests: XCTestCase {

    var context: NSManagedObjectContext!

    override func setUp() {
        super.setUp()
        context = CoreDataTestHelper.makeContext()
    }

    private func makeActivity(name: String = "Squat") -> CDActivity {
        let a = CDActivity(context: context)
        a.id = UUID()
        a.name = name
        a.category = ActivityCategory.strength.rawValue
        a.primaryMetric = PrimaryMetric.weightReps.rawValue
        return a
    }

    // MARK: - Set deletion guard (mirrors EntrySection.onDelete)

    func test_removeSet_removesSetWhenMultipleExist() {
        var entry = LiveEntry(activity: makeActivity(), sets: [LiveSet(), LiveSet(), LiveSet()])
        let indices = IndexSet([1])
        if entry.sets.count > indices.count {
            entry.sets.remove(atOffsets: indices)
        }
        XCTAssertEqual(entry.sets.count, 2)
    }

    func test_removeSet_removesCorrectSetByPosition() {
        var s1 = LiveSet(); s1.weightKg = "100"
        var s2 = LiveSet(); s2.weightKg = "200"
        var s3 = LiveSet(); s3.weightKg = "300"
        var entry = LiveEntry(activity: makeActivity(), sets: [s1, s2, s3])
        let indices = IndexSet([1])
        if entry.sets.count > indices.count {
            entry.sets.remove(atOffsets: indices)
        }
        XCTAssertEqual(entry.sets.count, 2)
        XCTAssertEqual(entry.sets[0].weightKg, "100")
        XCTAssertEqual(entry.sets[1].weightKg, "300")
    }

    func test_removeSet_guardBlocksLastSetRemoval() {
        var entry = LiveEntry(activity: makeActivity(), sets: [LiveSet()])
        let indices = IndexSet([0])
        if entry.sets.count > indices.count {
            entry.sets.remove(atOffsets: indices)
        }
        XCTAssertEqual(entry.sets.count, 1, "Last set must not be removed")
    }

    func test_removeSet_guardBlocksRemovingAllSetsAtOnce() {
        var entry = LiveEntry(activity: makeActivity(), sets: [LiveSet(), LiveSet()])
        let indices = IndexSet([0, 1])
        if entry.sets.count > indices.count {
            entry.sets.remove(atOffsets: indices)
        }
        XCTAssertEqual(entry.sets.count, 2, "Cannot remove all sets at once")
    }

    func test_removeFirstSet_remainingSetsPresent() {
        var entry = LiveEntry(activity: makeActivity(), sets: [LiveSet(), LiveSet(), LiveSet()])
        let indices = IndexSet([0])
        if entry.sets.count > indices.count {
            entry.sets.remove(atOffsets: indices)
        }
        XCTAssertEqual(entry.sets.count, 2)
    }

    func test_removeLastSet_remainingSetsPresent() {
        var entry = LiveEntry(activity: makeActivity(), sets: [LiveSet(), LiveSet(), LiveSet()])
        let indices = IndexSet([2])
        if entry.sets.count > indices.count {
            entry.sets.remove(atOffsets: indices)
        }
        XCTAssertEqual(entry.sets.count, 2)
    }

    // MARK: - Activity (entry) deletion (mirrors entries.removeAll in LogWorkoutView)

    func test_removeEntry_removesCorrectEntry() {
        let a1 = makeActivity(name: "Squat")
        let a2 = makeActivity(name: "Bench")
        var entries = [LiveEntry(activity: a1), LiveEntry(activity: a2)]
        let toRemove = entries[0]
        entries.removeAll { $0.id == toRemove.id }
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries[0].activity.name, "Bench")
    }

    func test_removeEntry_byID_doesNotRemoveSibling() {
        let a1 = makeActivity(name: "Squat")
        let a2 = makeActivity(name: "Bench")
        let a3 = makeActivity(name: "Deadlift")
        var entries = [LiveEntry(activity: a1), LiveEntry(activity: a2), LiveEntry(activity: a3)]
        let toRemove = entries[1]
        entries.removeAll { $0.id == toRemove.id }
        XCTAssertEqual(entries.count, 2)
        XCTAssertEqual(entries[0].activity.name, "Squat")
        XCTAssertEqual(entries[1].activity.name, "Deadlift")
    }

    func test_removeEntry_onlyMatchingIDIsRemoved() {
        let activities = (0..<5).map { makeActivity(name: "Ex\($0)") }
        var entries = activities.map { LiveEntry(activity: $0) }
        let toRemove = entries[2]
        entries.removeAll { $0.id == toRemove.id }
        XCTAssertEqual(entries.count, 4)
        XCTAssertFalse(entries.contains(where: { $0.id == toRemove.id }))
    }

    func test_removeEntry_doesNotMatchOnDifferentID() {
        let a1 = makeActivity(name: "Squat")
        let a2 = makeActivity(name: "Bench")
        var entries = [LiveEntry(activity: a1), LiveEntry(activity: a2)]
        let unrelatedID = UUID()
        entries.removeAll { $0.id == unrelatedID }
        XCTAssertEqual(entries.count, 2, "No entry should be removed when ID does not match")
    }

    // MARK: - LiveEntry default state

    func test_liveEntry_defaultsToOneLiveSet() {
        let entry = LiveEntry(activity: makeActivity())
        XCTAssertEqual(entry.sets.count, 1)
    }

    func test_liveEntry_hasUniqueID() {
        let a = makeActivity()
        let e1 = LiveEntry(activity: a)
        let e2 = LiveEntry(activity: a)
        XCTAssertNotEqual(e1.id, e2.id)
    }
}
