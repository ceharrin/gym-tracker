import XCTest
import CoreData
@testable import GymTracker

final class CDBodyMeasurementTests: XCTestCase {

    var context: NSManagedObjectContext!

    override func setUp() {
        super.setUp()
        context = CoreDataTestHelper.makeContext()
    }

    // MARK: - Helpers

    private func makeMeasurement(weightKg: Double) -> CDBodyMeasurement {
        let m = CDBodyMeasurement(context: context)
        m.date = Date()
        m.weightKg = weightKg
        return m
    }

    // MARK: - weightLbs

    func test_weightLbs_100kg_is220lbs() {
        let m = makeMeasurement(weightKg: 100)
        XCTAssertEqual(m.weightLbs, 220.462, accuracy: 0.001)
    }

    func test_weightLbs_0kg_is0() {
        let m = makeMeasurement(weightKg: 0)
        XCTAssertEqual(m.weightLbs, 0)
    }

    func test_weightLbs_70kg() {
        let m = makeMeasurement(weightKg: 70)
        XCTAssertEqual(m.weightLbs, 70 * 2.20462, accuracy: 0.001)
    }

    func test_weightLbs_roundTrip() {
        let original = 85.0
        let m = makeMeasurement(weightKg: original)
        let backToKg = m.weightLbs / 2.20462
        XCTAssertEqual(backToKg, original, accuracy: 0.001)
    }

    // MARK: - Persistence round-trip

    func test_weightKg_persistsAfterSave() throws {
        let profile = CDUserProfile(context: context)
        profile.name = "Test"
        profile.createdAt = Date()
        let m = makeMeasurement(weightKg: 75.5)
        m.profile = profile
        try context.save()

        let fetched = try context.fetch(CDBodyMeasurement.fetchRequest())
        XCTAssertEqual(fetched.first?.weightKg ?? 0, 75.5, accuracy: 0.001)
    }
}
