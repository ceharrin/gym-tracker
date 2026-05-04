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

    func test_seedIfNeeded_addsMissingPresetsToExistingLibrary() throws {
        let existing = CDActivity(context: context)
        existing.id = UUID()
        existing.name = "Back Squat"
        existing.category = ActivityCategory.strength.rawValue
        existing.icon = "figure.strengthtraining.traditional"
        existing.primaryMetric = PrimaryMetric.weightReps.rawValue
        existing.isPreset = true
        existing.createdAt = Date()
        existing.instructions = "Existing instructions"
        try context.save()

        ActivitySeeder.seedIfNeeded(context: context)

        let request = CDActivity.fetchRequest()
        request.predicate = NSPredicate(format: "isPreset == true")
        let results = try context.fetch(request)

        XCTAssertEqual(results.count, ActivitySeeder.presets.count)
        XCTAssertEqual(results.filter { $0.name == "Back Squat" }.count, 1)
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
        request.predicate = NSPredicate(format: "name == %@", "Back Squat")
        let squat = try XCTUnwrap(context.fetch(request).first)

        XCTAssertEqual(squat.category, ActivityCategory.strength.rawValue)
        XCTAssertEqual(squat.icon, "figure.strengthtraining.traditional")
        XCTAssertEqual(squat.primaryMetric, PrimaryMetric.weightReps.rawValue)
        XCTAssertEqual(squat.muscleGroups, "Quads, Glutes, Hamstrings")
        XCTAssertTrue(squat.isPreset)
        XCTAssertNotNil(squat.id)
        XCTAssertNotNil(squat.createdAt)
    }

    func test_seedIfNeeded_populatesInstructions() throws {
        ActivitySeeder.seedIfNeeded(context: context)

        let request = CDActivity.fetchRequest()
        request.predicate = NSPredicate(format: "name == %@", "Back Squat")
        let squat = try XCTUnwrap(context.fetch(request).first)

        XCTAssertNotNil(squat.instructions)
        XCTAssertFalse(squat.instructions!.isEmpty)
    }

    func test_seedIfNeeded_allPresetsHaveInstructions() throws {
        ActivitySeeder.seedIfNeeded(context: context)

        let request = CDActivity.fetchRequest()
        request.predicate = NSPredicate(format: "isPreset == true AND (instructions == nil OR instructions == '')")
        let missing = try context.fetch(request)

        XCTAssertTrue(missing.isEmpty, "Presets missing instructions: \(missing.map(\.name).joined(separator: ", "))")
    }

    func test_seedIfNeeded_strengthCatalogCoversBarbellDumbbellMachineCableAndBodyweight() throws {
        ActivitySeeder.seedIfNeeded(context: context)

        let request = CDActivity.fetchRequest()
        request.predicate = NSPredicate(format: "isPreset == true AND category == %@", ActivityCategory.strength.rawValue)
        let names = Set(try context.fetch(request).map(\.name))

        XCTAssertTrue(names.contains("Back Squat"))
        XCTAssertTrue(names.contains("Dumbbell Bench Press"))
        XCTAssertTrue(names.contains("Leg Press"))
        XCTAssertTrue(names.contains("Cable Row"))
        XCTAssertTrue(names.contains("Push-Up"))
    }

    func test_updateInstructionsIfNeeded_fillsNilInstructions() throws {
        let activity = CDActivity(context: context)
        activity.id = UUID()
        activity.name = "Back Squat"
        activity.category = ActivityCategory.strength.rawValue
        activity.icon = "figure.strengthtraining.traditional"
        activity.primaryMetric = PrimaryMetric.weightReps.rawValue
        activity.isPreset = true
        activity.createdAt = Date()
        activity.instructions = nil
        try context.save()

        ActivitySeeder.updateInstructionsIfNeeded(context: context)

        let request = CDActivity.fetchRequest()
        request.predicate = NSPredicate(format: "name == %@", "Back Squat")
        let squat = try XCTUnwrap(context.fetch(request).first)

        XCTAssertNotNil(squat.instructions)
        XCTAssertFalse(squat.instructions!.isEmpty)
    }

    // MARK: - deduplicatePresets

    private func makePreset(name: String, createdAt: Date = Date()) -> CDActivity {
        let a = CDActivity(context: context)
        a.id = UUID()
        a.name = name
        a.category = ActivityCategory.strength.rawValue
        a.icon = "dumbbell.fill"
        a.primaryMetric = PrimaryMetric.weightReps.rawValue
        a.isPreset = true
        a.createdAt = createdAt
        return a
    }

    func test_deduplicatePresets_noDuplicates_noChanges() throws {
        makePreset(name: "Back Squat")
        makePreset(name: "Deadlift")
        try context.save()

        ActivitySeeder.deduplicatePresets(context: context)

        let count = try context.count(for: CDActivity.fetchRequest())
        XCTAssertEqual(count, 2)
    }

    func test_deduplicatePresets_removesExtraCopies() throws {
        let older = makePreset(name: "Back Squat", createdAt: Date(timeIntervalSinceReferenceDate: 1000))
        let newer = makePreset(name: "Back Squat", createdAt: Date(timeIntervalSinceReferenceDate: 2000))
        try context.save()
        _ = older; _ = newer

        ActivitySeeder.deduplicatePresets(context: context)

        let req = CDActivity.fetchRequest()
        req.predicate = NSPredicate(format: "name == %@", "Back Squat")
        let remaining = try context.fetch(req)
        XCTAssertEqual(remaining.count, 1, "Exactly one Back Squat should remain after deduplication")
    }

    func test_deduplicatePresets_keepsOldestByCreatedAt() throws {
        let older = makePreset(name: "Back Squat", createdAt: Date(timeIntervalSinceReferenceDate: 1000))
        makePreset(name: "Back Squat", createdAt: Date(timeIntervalSinceReferenceDate: 2000))
        try context.save()

        ActivitySeeder.deduplicatePresets(context: context)

        let req = CDActivity.fetchRequest()
        req.predicate = NSPredicate(format: "name == %@", "Back Squat")
        let remaining = try XCTUnwrap(try context.fetch(req).first)
        XCTAssertEqual(remaining.objectID, older.objectID, "The oldest preset should be the survivor")
    }

    func test_deduplicatePresets_migratesWorkoutEntriesToSurvivor() throws {
        let older = makePreset(name: "Back Squat", createdAt: Date(timeIntervalSinceReferenceDate: 1000))
        let newer = makePreset(name: "Back Squat", createdAt: Date(timeIntervalSinceReferenceDate: 2000))

        let workout = CDWorkout(context: context)
        workout.id = UUID()
        workout.title = "Test"
        workout.date = Date()

        let entry = CDWorkoutEntry(context: context)
        entry.id = UUID()
        entry.orderIndex = 0
        entry.workout = workout
        entry.activity = newer
        try context.save()
        _ = older

        ActivitySeeder.deduplicatePresets(context: context)

        XCTAssertEqual(entry.activity?.objectID, older.objectID,
                       "Workout entry must be remapped to the surviving (oldest) preset")
    }

    func test_deduplicatePresets_doesNotAffectCustomActivities() throws {
        let custom = CDActivity(context: context)
        custom.id = UUID()
        custom.name = "My Move"
        custom.category = ActivityCategory.custom.rawValue
        custom.icon = "star"
        custom.primaryMetric = PrimaryMetric.custom.rawValue
        custom.isPreset = false
        custom.createdAt = Date()
        try context.save()

        ActivitySeeder.deduplicatePresets(context: context)

        let remaining = try context.fetch(CDActivity.fetchRequest())
        XCTAssertEqual(remaining.count, 1)
        XCTAssertFalse(remaining[0].isPreset)
    }

    func test_deduplicatePresets_isIdempotent() throws {
        makePreset(name: "Back Squat", createdAt: Date(timeIntervalSinceReferenceDate: 1000))
        makePreset(name: "Back Squat", createdAt: Date(timeIntervalSinceReferenceDate: 2000))
        makePreset(name: "Deadlift")
        try context.save()

        ActivitySeeder.deduplicatePresets(context: context)
        ActivitySeeder.deduplicatePresets(context: context)

        let req = CDActivity.fetchRequest()
        req.predicate = NSPredicate(format: "isPreset == true")
        let count = try context.count(for: req)
        XCTAssertEqual(count, 2)
    }

    func test_updateInstructionsIfNeeded_doesNotOverwriteExistingInstructions() throws {
        let activity = CDActivity(context: context)
        activity.id = UUID()
        activity.name = "Back Squat"
        activity.category = ActivityCategory.strength.rawValue
        activity.icon = "figure.strengthtraining.traditional"
        activity.primaryMetric = PrimaryMetric.weightReps.rawValue
        activity.isPreset = true
        activity.createdAt = Date()
        activity.instructions = "My custom instructions"
        try context.save()

        ActivitySeeder.updateInstructionsIfNeeded(context: context)

        let request = CDActivity.fetchRequest()
        request.predicate = NSPredicate(format: "name == %@", "Back Squat")
        let squat = try XCTUnwrap(context.fetch(request).first)

        XCTAssertEqual(squat.instructions, "My custom instructions")
    }
}
