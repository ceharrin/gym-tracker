import XCTest
import CoreData
@testable import GymTracker

final class ActivityEditorTests: XCTestCase {

    var context: NSManagedObjectContext!

    override func setUp() {
        super.setUp()
        context = CoreDataTestHelper.makeContext()
    }

    private func makePresetActivity(name: String = "Bench") -> CDActivity {
        let activity = CDActivity(context: context)
        activity.id = UUID()
        activity.name = name
        activity.category = ActivityCategory.strength.rawValue
        activity.icon = ActivityCategory.strength.icon
        activity.primaryMetric = PrimaryMetric.weightReps.rawValue
        activity.isPreset = true
        activity.createdAt = Date()
        return activity
    }

    private func makeCustomActivity(name: String = "Band Pull Apart", metric: PrimaryMetric = .custom) -> CDActivity {
        let activity = CDActivity(context: context)
        activity.id = UUID()
        activity.name = name
        activity.category = ActivityCategory.custom.rawValue
        activity.icon = ActivityCategory.custom.icon
        activity.primaryMetric = metric.rawValue
        activity.isPreset = false
        activity.createdAt = Date()
        return activity
    }

    func test_saveCustomActivity_persistsRepsOnlyMetric() throws {
        let activity = try ActivityEditor.save(
            data: .init(
                name: "Push Ups",
                category: .custom,
                metric: .reps,
                muscleGroups: "Chest, Triceps",
                instructions: "AMRAP"
            ),
            context: context
        )

        XCTAssertEqual(activity.metric, .reps)
        XCTAssertEqual(activity.category, ActivityCategory.custom.rawValue)
        XCTAssertFalse(activity.isPreset)
    }

    func test_saveCustomActivity_trimsAndPersistsFields() throws {
        let activity = try ActivityEditor.save(
            data: .init(
                name: "  Push Ups  ",
                category: .custom,
                metric: .reps,
                muscleGroups: "Chest",
                instructions: "Go slow"
            ),
            context: context
        )

        XCTAssertEqual(activity.name, "Push Ups")
        XCTAssertEqual(activity.muscleGroups, "Chest")
        XCTAssertEqual(activity.instructions, "Go slow")
    }

    func test_editCustomActivity_updatesExistingRecord() throws {
        let existing = makeCustomActivity()

        let updated = try ActivityEditor.save(
            data: .init(
                name: "Ring Rows",
                category: .custom,
                metric: .reps,
                muscleGroups: "Back",
                instructions: "Pause at the top"
            ),
            context: context,
            existingActivity: existing
        )

        XCTAssertEqual(updated.objectID, existing.objectID)
        XCTAssertEqual(updated.name, "Ring Rows")
        XCTAssertEqual(updated.metric, .reps)
        XCTAssertEqual(updated.muscleGroups, "Back")
    }

    func test_editPresetActivity_throws() throws {
        let preset = makePresetActivity()

        XCTAssertThrowsError(
            try ActivityEditor.save(
                data: .init(
                    name: "Edited Bench",
                    category: .strength,
                    metric: .weightReps,
                    muscleGroups: "",
                    instructions: ""
                ),
                context: context,
                existingActivity: preset
            )
        )
    }

    func test_deleteCustomActivity_removesRecord() throws {
        let custom = makeCustomActivity()
        try context.save()

        try ActivityEditor.delete(custom, from: context)

        XCTAssertTrue(try context.fetch(CDActivity.fetchRequest()).isEmpty)
    }

    func test_deletePresetActivity_throws() throws {
        let preset = makePresetActivity()
        try context.save()

        XCTAssertThrowsError(try ActivityEditor.delete(preset, from: context))
    }

    func test_nonCustomActivityCannotPersistRepsMetric() throws {
        XCTAssertThrowsError(
            try ActivityEditor.save(
                data: .init(
                    name: "Rowing",
                    category: .cardio,
                    metric: .reps,
                    muscleGroups: "",
                    instructions: ""
                ),
                context: context
            )
        )
    }
}
