import XCTest
import CoreData
@testable import GymTracker

final class PersistenceTests: XCTestCase {

    var controller: PersistenceController!
    var context: NSManagedObjectContext!

    override func setUp() {
        super.setUp()
        controller = PersistenceController(inMemory: true)
        context = controller.context
    }

    func test_inMemoryController_usesInMemoryStoreType() {
        XCTAssertEqual(
            controller.container.persistentStoreDescriptions.first?.type,
            NSInMemoryStoreType
        )
    }

    func test_managedObjectModel_containsExpectedEntities() {
        let entityNames = Set(PersistenceController.managedObjectModel.entities.compactMap(\.name))

        XCTAssertTrue(entityNames.contains("CDWorkout"))
        XCTAssertTrue(entityNames.contains("CDWorkoutEntry"))
        XCTAssertTrue(entityNames.contains("CDEntrySet"))
        XCTAssertTrue(entityNames.contains("CDActivity"))
        XCTAssertTrue(entityNames.contains("CDUserProfile"))
        XCTAssertTrue(entityNames.contains("CDBodyMeasurement"))
    }

    func test_saveIfChanged_persistsInsertedObject() throws {
        let activity = CDActivity(context: context)
        activity.id = UUID()
        activity.name = "Saved Activity"
        activity.category = ActivityCategory.custom.rawValue
        activity.icon = "star.fill"
        activity.primaryMetric = PrimaryMetric.custom.rawValue
        activity.isPreset = false

        try context.saveIfChanged()

        let request = CDActivity.fetchRequest()
        request.predicate = NSPredicate(format: "name == %@", "Saved Activity")
        let results = try context.fetch(request)
        XCTAssertEqual(results.count, 1)
    }

    func test_saveIfChanged_throwsOnValidationFailure() {
        _ = CDActivity(context: context)

        XCTAssertThrowsError(try context.saveIfChanged())
    }

    func test_persistenceAlertState_usesErrorDescription() {
        let error = NSError(
            domain: "PersistenceTests",
            code: 7,
            userInfo: [NSLocalizedDescriptionKey: "Disk full"]
        )

        let state = PersistenceAlertState(title: "Save Failed", error: error)

        XCTAssertEqual(state.title, "Save Failed")
        XCTAssertEqual(state.message, "Disk full")
    }

    func test_persistenceAlertState_usesFallbackForBlankDescription() {
        let state = PersistenceAlertState(
            title: "Save Failed",
            error: BlankDescriptionError(),
            fallbackMessage: "Fallback message"
        )

        XCTAssertEqual(state.message, "Fallback message")
    }
}

private struct BlankDescriptionError: LocalizedError {
    var errorDescription: String? { "   " }
}
