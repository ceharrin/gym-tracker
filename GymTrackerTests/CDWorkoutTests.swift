import XCTest
import CoreData
@testable import GymTracker

final class CDWorkoutTests: XCTestCase {

    var context: NSManagedObjectContext!

    override func setUp() {
        super.setUp()
        context = CoreDataTestHelper.makeContext()
    }

    // MARK: - Helpers

    private func makeWorkout(title: String = "Test", durationMinutes: Int32 = 45) -> CDWorkout {
        let w = CDWorkout(context: context)
        w.id = UUID()
        w.title = title
        w.date = Date()
        w.durationMinutes = durationMinutes
        w.energyLevel = 7
        return w
    }

    private func makeActivity(name: String, category: ActivityCategory = .strength) -> CDActivity {
        let a = CDActivity(context: context)
        a.id = UUID()
        a.name = name
        a.category = category.rawValue
        a.primaryMetric = category.defaultMetric.rawValue
        a.isPreset = true
        return a
    }

    @discardableResult
    private func makeEntry(workout: CDWorkout, activity: CDActivity, orderIndex: Int16 = 0) -> CDWorkoutEntry {
        let e = CDWorkoutEntry(context: context)
        e.id = UUID()
        e.orderIndex = orderIndex
        e.activity = activity
        e.workout = workout
        return e
    }

    // MARK: - activitySummary

    func test_activitySummary_noEntries() {
        let w = makeWorkout()
        XCTAssertEqual(w.activitySummary, "No exercises")
    }

    func test_activitySummary_oneEntry() {
        let w = makeWorkout()
        makeEntry(workout: w, activity: makeActivity(name: "Bench Press"))
        XCTAssertEqual(w.activitySummary, "Bench Press")
    }

    func test_activitySummary_twoEntries() {
        let w = makeWorkout()
        makeEntry(workout: w, activity: makeActivity(name: "Squat"), orderIndex: 0)
        makeEntry(workout: w, activity: makeActivity(name: "Deadlift"), orderIndex: 1)
        XCTAssertEqual(w.activitySummary, "Squat, Deadlift")
    }

    func test_activitySummary_threeEntries_showsMoreCount() {
        let w = makeWorkout()
        makeEntry(workout: w, activity: makeActivity(name: "Squat"), orderIndex: 0)
        makeEntry(workout: w, activity: makeActivity(name: "Deadlift"), orderIndex: 1)
        makeEntry(workout: w, activity: makeActivity(name: "Press"), orderIndex: 2)
        XCTAssertEqual(w.activitySummary, "Squat, Deadlift +1 more")
    }

    func test_activitySummary_fourEntries_showsCorrectMoreCount() {
        let w = makeWorkout()
        for (i, name) in ["A", "B", "C", "D"].enumerated() {
            makeEntry(workout: w, activity: makeActivity(name: name), orderIndex: Int16(i))
        }
        XCTAssertTrue(w.activitySummary.hasSuffix("+2 more"))
    }

    // MARK: - sortedEntries

    func test_sortedEntries_byOrderIndex() {
        let w = makeWorkout()
        let e2 = makeEntry(workout: w, activity: makeActivity(name: "B"), orderIndex: 1)
        let e1 = makeEntry(workout: w, activity: makeActivity(name: "A"), orderIndex: 0)
        let sorted = w.sortedEntries
        XCTAssertEqual(sorted.first?.id, e1.id)
        XCTAssertEqual(sorted.last?.id, e2.id)
    }

    func test_sortedEntries_emptyWhenNoEntries() {
        let w = makeWorkout()
        XCTAssertTrue(w.sortedEntries.isEmpty)
    }

    // MARK: - totalSets

    func test_totalSets_singleEntry() {
        let w = makeWorkout()
        let e = makeEntry(workout: w, activity: makeActivity(name: "Curl"))
        for i in 1...3 {
            let s = CDEntrySet(context: context)
            s.id = UUID()
            s.setNumber = Int16(i)
            s.entry = e
        }
        XCTAssertEqual(w.totalSets, 3)
    }

    func test_totalSets_multipleEntries() {
        let w = makeWorkout()
        let e1 = makeEntry(workout: w, activity: makeActivity(name: "A"), orderIndex: 0)
        let e2 = makeEntry(workout: w, activity: makeActivity(name: "B"), orderIndex: 1)
        for i in 1...2 {
            let s = CDEntrySet(context: context); s.id = UUID(); s.setNumber = Int16(i); s.entry = e1
        }
        for i in 1...4 {
            let s = CDEntrySet(context: context); s.id = UUID(); s.setNumber = Int16(i); s.entry = e2
        }
        XCTAssertEqual(w.totalSets, 6)
    }

    func test_totalSets_zeroWhenNoEntries() {
        let w = makeWorkout()
        XCTAssertEqual(w.totalSets, 0)
    }
}
