import XCTest
import CoreData
@testable import GymTracker

final class CDEntrySetTests: XCTestCase {

    var context: NSManagedObjectContext!

    override func setUp() {
        super.setUp()
        context = CoreDataTestHelper.makeContext()
    }

    override func tearDown() {
        Units._testOverrideIsMetric = nil
        super.tearDown()
    }

    private func makeSet(
        weightKg: Double = 0,
        reps: Int32 = 0,
        distanceMeters: Double = 0,
        durationSeconds: Int32 = 0,
        laps: Int32 = 0
    ) -> CDEntrySet {
        let s = CDEntrySet(context: context)
        s.id = UUID()
        s.setNumber = 1
        s.weightKg = weightKg
        s.reps = reps
        s.distanceMeters = distanceMeters
        s.durationSeconds = durationSeconds
        s.laps = laps
        return s
    }

    // MARK: - Computed properties

    func test_weightLbs_conversion() {
        let s = makeSet(weightKg: 100)
        XCTAssertEqual(s.weightLbs, 220.462, accuracy: 0.001)
    }

    func test_distanceKm() {
        let s = makeSet(distanceMeters: 5000)
        XCTAssertEqual(s.distanceKm, 5.0)
    }

    func test_distanceMiles() {
        let s = makeSet(distanceMeters: 1609.34)
        XCTAssertEqual(s.distanceMiles, 1.0, accuracy: 0.001)
    }

    // MARK: - formattedDuration

    func test_formattedDuration_minutesAndSeconds() {
        let s = makeSet(durationSeconds: 125) // 2:05
        XCTAssertEqual(s.formattedDuration, "2:05")
    }

    func test_formattedDuration_withHours() {
        let s = makeSet(durationSeconds: 3661) // 1:01:01
        XCTAssertEqual(s.formattedDuration, "1:01:01")
    }

    func test_formattedDuration_exactMinutes() {
        let s = makeSet(durationSeconds: 60) // 1:00
        XCTAssertEqual(s.formattedDuration, "1:00")
    }

    func test_formattedDuration_zero() {
        let s = makeSet(durationSeconds: 0)
        XCTAssertEqual(s.formattedDuration, "0:00")
    }

    func test_formattedDuration_paddedSeconds() {
        let s = makeSet(durationSeconds: 65) // 1:05
        XCTAssertEqual(s.formattedDuration, "1:05")
    }

    // MARK: - pacePerUnit

    func test_pacePerUnit_metric_fiveKmInTwentyFiveMin() {
        Units._testOverrideIsMetric = true
        // 5 km in 25 min = 5:00/km
        let s = makeSet(distanceMeters: 5000, durationSeconds: 1500)
        XCTAssertEqual(s.pacePerUnit, "5:00 /km")
    }

    func test_pacePerUnit_metric_tenKmInFortyMin() {
        Units._testOverrideIsMetric = true
        // 10 km in 40 min = 4:00/km
        let s = makeSet(distanceMeters: 10000, durationSeconds: 2400)
        XCTAssertEqual(s.pacePerUnit, "4:00 /km")
    }

    func test_pacePerUnit_imperial_oneMileInEightMin() {
        Units._testOverrideIsMetric = false
        let s = makeSet(distanceMeters: 1609.344, durationSeconds: 480)
        XCTAssertEqual(s.pacePerUnit, "8:00 /mi")
    }

    func test_pacePerUnit_nilWhenNoDistance() {
        Units._testOverrideIsMetric = true
        let s = makeSet(durationSeconds: 300)
        XCTAssertNil(s.pacePerUnit)
    }

    func test_pacePerUnit_nilWhenNoDuration() {
        Units._testOverrideIsMetric = true
        let s = makeSet(distanceMeters: 5000)
        XCTAssertNil(s.pacePerUnit)
    }
}
