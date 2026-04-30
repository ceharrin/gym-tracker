import XCTest
import CoreData
@testable import GymTracker

final class ActivitySeederTests: XCTestCase {

    var context: NSManagedObjectContext!

    override func setUp() {
        super.setUp()
        context = CoreDataTestHelper.makeContext()
    }

    func test_seedIfNeeded_insertsAllPresetsWhenEmpty() throws {
        ActivitySeeder.seedIfNeeded(context: context)

        let request = CDActivity.fetchRequest()
        request.predicate = NSPredicate(format: "isPreset == true")
        let results = try context.fetch(request)

        XCTAssertEqual(results.count, ActivitySeeder.presets.count)
    }

    func test_seedIfNeeded_isIdempotent() throws {
        ActivitySeeder.seedIfNeeded(context: context)
        ActivitySeeder.seedIfNeeded(context: context)

        let request = CDActivity.fetchRequest()
        request.predicate = NSPredicate(format: "isPreset == true")
        let results = try context.fetch(request)

        XCTAssertEqual(results.count, ActivitySeeder.presets.count)
    }

    func test_seedIfNeeded_seedsPresetsEvenWhenCustomActivitiesExist() throws {
        let custom = CDActivity(context: context)
        custom.id = UUID()
        custom.name = "My Custom Move"
        custom.category = ActivityCategory.custom.rawValue
        custom.icon = "star.fill"
        custom.primaryMetric = PrimaryMetric.custom.rawValue
        custom.isPreset = false
        try context.save()

        ActivitySeeder.seedIfNeeded(context: context)

        let allActivities = try context.fetch(CDActivity.fetchRequest())
        let presetCount = allActivities.filter(\.isPreset).count
        let customCount = allActivities.filter { !$0.isPreset }.count

        XCTAssertEqual(presetCount, ActivitySeeder.presets.count)
        XCTAssertEqual(customCount, 1)
    }

    func test_seedIfNeeded_populatesKnownPresetFields() throws {
        ActivitySeeder.seedIfNeeded(context: context)

        let request = CDActivity.fetchRequest()
        request.predicate = NSPredicate(format: "name == %@", "Squat")
        let squat = try XCTUnwrap(context.fetch(request).first)

        XCTAssertEqual(squat.category, ActivityCategory.strength.rawValue)
        XCTAssertEqual(squat.icon, "figure.strengthtraining.traditional")
        XCTAssertEqual(squat.primaryMetric, PrimaryMetric.weightReps.rawValue)
        XCTAssertEqual(squat.muscleGroups, "Quads, Glutes, Hamstrings")
        XCTAssertTrue(squat.isPreset)
        XCTAssertNotNil(squat.id)
        XCTAssertNotNil(squat.createdAt)
    }
}
