import XCTest
import CoreData
@testable import GymTracker

final class PersistenceCloudKitTests: XCTestCase {

    func test_container_isNSPersistentContainer() {
        let controller = PersistenceController(inMemory: true)
        XCTAssertTrue(
            controller.container is NSPersistentContainer,
            "Container must be a standard NSPersistentContainer for local-only persistence"
        )
    }

    func test_productionConfig_enablesAutomaticMigration() {
        let description = NSPersistentStoreDescription()
        PersistenceController.configureProductionStore(description)
        XCTAssertTrue(description.shouldMigrateStoreAutomatically)
    }

    func test_productionConfig_enablesInferredMappingModel() {
        let description = NSPersistentStoreDescription()
        PersistenceController.configureProductionStore(description)
        XCTAssertTrue(description.shouldInferMappingModelAutomatically)
    }

    func test_productionConfig_hasNoCloudKitContainerOptions() {
        let description = NSPersistentStoreDescription()
        PersistenceController.configureProductionStore(description)
        XCTAssertNil(
            description.cloudKitContainerOptions,
            "Local-only persistence should not configure CloudKit options"
        )
    }

    func test_productionConfig_keepsHistoryTrackingEnabledForExistingStores() {
        let description = NSPersistentStoreDescription()
        PersistenceController.configureProductionStore(description)
        let value = description.options[NSPersistentHistoryTrackingKey] as? NSNumber
        XCTAssertEqual(
            value,
            true,
            "History tracking should stay enabled so stores created under the old CloudKit configuration keep opening read-write."
        )
    }

    func test_inMemoryController_usesInMemoryStoreType() {
        let controller = PersistenceController(inMemory: true)
        XCTAssertEqual(controller.container.persistentStoreDescriptions.first?.type, NSInMemoryStoreType)
    }
}
