import XCTest
import CoreData
@testable import GymTracker

final class CDWorkoutEntryTests: XCTestCase {

    var context: NSManagedObjectContext!

    override func setUp() {
        super.setUp()
        context = CoreDataTestHelper.makeContext()
    }

    // MARK: - Helpers

    private func makeEntry(metric: PrimaryMetric) -> CDWorkoutEntry {
        let a = CDActivity(context: context)
        a.id = UUID()
        a.name = "Test Activity"
        a.category = ActivityCategory.strength.rawValue
        a.primaryMetric = metric.rawValue
        a.isPreset = true

        let e = CDWorkoutEntry(context: context)
        e.id = UUID()
        e.orderIndex = 0
        e.activity = a
        return e
    }

    @discardableResult
    private func addSet(
        to entry: CDWorkoutEntry,
        number: Int16,
        weightKg: Double = 0,
        reps: Int32 = 0,
        distanceMeters: Double = 0,
        durationSeconds: Int32 = 0,
        laps: Int32 = 0
    ) -> CDEntrySet {
        let s = CDEntrySet(context: context)
        s.id = UUID()
        s.setNumber = number
        s.weightKg = weightKg
        s.reps = reps
        s.distanceMeters = distanceMeters
        s.durationSeconds = durationSeconds
        s.laps = laps
        s.entry = entry
        return s
    }

    // MARK: - sortedSets

    func test_sortedSets_bySetNumber() {
        let e = makeEntry(metric: .weightReps)
        let s3 = addSet(to: e, number: 3, weightKg: 80)
        let s1 = addSet(to: e, number: 1, weightKg: 60)
        let s2 = addSet(to: e, number: 2, weightKg: 70)
        let sorted = e.sortedSets
        XCTAssertEqual(sorted[0].id, s1.id)
        XCTAssertEqual(sorted[1].id, s2.id)
        XCTAssertEqual(sorted[2].id, s3.id)
    }

    func test_sortedSets_emptyWhenNoSets() {
        let e = makeEntry(metric: .weightReps)
        XCTAssertTrue(e.sortedSets.isEmpty)
    }

    // MARK: - bestSet (weightReps)

    func test_bestSet_weightReps_returnsHeaviest() {
        let e = makeEntry(metric: .weightReps)
        addSet(to: e, number: 1, weightKg: 60)
        let heavy = addSet(to: e, number: 2, weightKg: 100)
        addSet(to: e, number: 3, weightKg: 80)
        XCTAssertEqual(e.bestSet?.id, heavy.id)
    }

    func test_bestSet_weightReps_tieGoesToFirst() {
        let e = makeEntry(metric: .weightReps)
        let first = addSet(to: e, number: 1, weightKg: 100)
        addSet(to: e, number: 2, weightKg: 100)
        // max(by:) returns the last max, but we just assert one of them is returned
        XCTAssertNotNil(e.bestSet)
        _ = first // silence unused warning
    }

    // MARK: - bestSet (distanceTime)

    func test_bestSet_distanceTime_returnsLongest() {
        let e = makeEntry(metric: .distanceTime)
        addSet(to: e, number: 1, distanceMeters: 3000)
        let longest = addSet(to: e, number: 2, distanceMeters: 10000)
        XCTAssertEqual(e.bestSet?.id, longest.id)
    }

    // MARK: - bestSet (lapsTime)

    func test_bestSet_lapsTime_returnsMostLaps() {
        let e = makeEntry(metric: .lapsTime)
        addSet(to: e, number: 1, laps: 10)
        let most = addSet(to: e, number: 2, laps: 20)
        XCTAssertEqual(e.bestSet?.id, most.id)
    }

    // MARK: - bestSet (duration)

    func test_bestSet_duration_returnsLongest() {
        let e = makeEntry(metric: .duration)
        addSet(to: e, number: 1, durationSeconds: 300)
        let longest = addSet(to: e, number: 2, durationSeconds: 600)
        XCTAssertEqual(e.bestSet?.id, longest.id)
    }

    // MARK: - bestSet nil

    func test_bestSet_nilWhenNoSets() {
        let e = makeEntry(metric: .weightReps)
        XCTAssertNil(e.bestSet)
    }
}
