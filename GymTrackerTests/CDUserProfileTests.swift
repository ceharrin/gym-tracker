import XCTest
import CoreData
@testable import GymTracker

final class CDUserProfileTests: XCTestCase {

    var context: NSManagedObjectContext!

    override func setUp() {
        super.setUp()
        context = CoreDataTestHelper.makeContext()
    }

    // MARK: - Helpers

    private func makeProfile(name: String = "Test User") -> CDUserProfile {
        let p = CDUserProfile(context: context)
        p.createdAt = Date()
        p.name = name
        return p
    }

    @discardableResult
    private func addMeasurement(to profile: CDUserProfile, weightKg: Double, daysAgo: Int = 0) -> CDBodyMeasurement {
        let m = CDBodyMeasurement(context: context)
        m.date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
        m.weightKg = weightKg
        m.profile = profile
        return m
    }

    // MARK: - latestWeight

    func test_latestWeight_returnsNewestMeasurement() {
        let p = makeProfile()
        addMeasurement(to: p, weightKg: 80, daysAgo: 10)
        addMeasurement(to: p, weightKg: 78, daysAgo: 5)
        addMeasurement(to: p, weightKg: 76, daysAgo: 0)
        XCTAssertEqual(p.latestWeight?.weightKg, 76)
    }

    func test_latestWeight_nilWhenNoMeasurements() {
        let p = makeProfile()
        XCTAssertNil(p.latestWeight)
    }

    func test_latestWeight_singleMeasurement() {
        let p = makeProfile()
        addMeasurement(to: p, weightKg: 75)
        XCTAssertEqual(p.latestWeight?.weightKg, 75)
    }

    // MARK: - sortedMeasurements

    func test_sortedMeasurements_chronologicalOrder() {
        let p = makeProfile()
        addMeasurement(to: p, weightKg: 80, daysAgo: 10)
        addMeasurement(to: p, weightKg: 78, daysAgo: 5)
        addMeasurement(to: p, weightKg: 76, daysAgo: 0)
        let sorted = p.sortedMeasurements
        XCTAssertEqual(sorted[0].weightKg, 80)
        XCTAssertEqual(sorted[1].weightKg, 78)
        XCTAssertEqual(sorted[2].weightKg, 76)
    }

    func test_sortedMeasurements_emptyWhenNone() {
        let p = makeProfile()
        XCTAssertTrue(p.sortedMeasurements.isEmpty)
    }

    // MARK: - age

    func test_age_thirtyYearsAgo() {
        let p = makeProfile()
        p.birthDate = Calendar.current.date(byAdding: .year, value: -30, to: Date())
        XCTAssertEqual(p.age, 30)
    }

    func test_age_nilWhenNoBirthDate() {
        let p = makeProfile()
        p.birthDate = nil
        XCTAssertNil(p.age)
    }

    func test_age_twentyFiveYearsAgo() {
        let p = makeProfile()
        p.birthDate = Calendar.current.date(byAdding: .year, value: -25, to: Date())
        XCTAssertEqual(p.age, 25)
    }

    // MARK: - photoData

    func test_photoData_isNilByDefault() {
        let p = makeProfile()
        XCTAssertNil(p.photoData)
    }

    func test_photoData_canBeSetAndRetrieved() {
        let p = makeProfile()
        let data = Data([0x89, 0x50, 0x4E, 0x47]) // PNG header bytes
        p.photoData = data
        try? context.save()

        let fetched = try? context.fetch(CDUserProfile.fetchRequest()).first
        XCTAssertEqual(fetched?.photoData, data)
    }

    func test_photoData_canBeCleared() {
        let p = makeProfile()
        p.photoData = Data([0x01, 0x02])
        try? context.save()
        p.photoData = nil
        try? context.save()
        XCTAssertNil(p.photoData)
    }

    // MARK: - weightTrend

    func test_weightTrend_noMeasurements_isNone() {
        let p = makeProfile()
        XCTAssertEqual(p.weightTrend, .none)
    }

    func test_weightTrend_oneMeasurement_isNone() {
        let p = makeProfile()
        addMeasurement(to: p, weightKg: 80)
        XCTAssertEqual(p.weightTrend, .none)
    }

    func test_weightTrend_increasingWeight_isUp() {
        let p = makeProfile()
        addMeasurement(to: p, weightKg: 78, daysAgo: 7)
        addMeasurement(to: p, weightKg: 80, daysAgo: 0)
        XCTAssertEqual(p.weightTrend, .up)
    }

    func test_weightTrend_decreasingWeight_isDown() {
        let p = makeProfile()
        addMeasurement(to: p, weightKg: 82, daysAgo: 7)
        addMeasurement(to: p, weightKg: 80, daysAgo: 0)
        XCTAssertEqual(p.weightTrend, .down)
    }

    func test_weightTrend_equalWeight_isFlat() {
        let p = makeProfile()
        addMeasurement(to: p, weightKg: 80, daysAgo: 7)
        addMeasurement(to: p, weightKg: 80, daysAgo: 0)
        XCTAssertEqual(p.weightTrend, .flat)
    }

    func test_weightTrend_usesOnlyLastTwo_notFirst() {
        let p = makeProfile()
        addMeasurement(to: p, weightKg: 90, daysAgo: 30) // should be ignored
        addMeasurement(to: p, weightKg: 83, daysAgo: 7)
        addMeasurement(to: p, weightKg: 80, daysAgo: 0)
        XCTAssertEqual(p.weightTrend, .down, "Trend must be computed from the last two measurements only")
    }
}
