import XCTest
import CoreData
@testable import GymTracker

// Tests that drive the iCloud/CloudKit persistence implementation.
// Failures here indicate what needs to change in Persistence.swift.
final class PersistenceCloudKitTests: XCTestCase {

    // MARK: - Container type

    func test_container_isNSPersistentCloudKitContainer() {
        let controller = PersistenceController(inMemory: true)
        XCTAssertTrue(
            controller.container is NSPersistentCloudKitContainer,
            "Container must be NSPersistentCloudKitContainer for iCloud sync"
        )
    }

    // MARK: - iCloud container identifier

    func test_iCloudContainerIdentifier_hasCorrectPrefix() {
        XCTAssertTrue(
            PersistenceController.iCloudContainerIdentifier.hasPrefix("iCloud."),
            "iCloud container identifier must start with 'iCloud.'"
        )
    }

    func test_iCloudContainerIdentifier_isNotEmpty() {
        XCTAssertFalse(PersistenceController.iCloudContainerIdentifier.isEmpty)
    }

    // MARK: - Production store description configuration
    // These call the static configureProductionStore(_:) method that PersistenceController
    // must expose so the configuration can be tested without loading a real store.

    func test_productionConfig_enablesHistoryTracking() {
        let description = NSPersistentStoreDescription()
        PersistenceController.configureProductionStore(description)
        let value = description.options[NSPersistentHistoryTrackingKey] as? NSNumber
        XCTAssertEqual(value, true, "History tracking must be enabled — required by CloudKit and existing on-disk stores")
    }

    func test_productionConfig_enablesRemoteChangeNotifications() {
        let description = NSPersistentStoreDescription()
        PersistenceController.configureProductionStore(description)
        let value = description.options[NSPersistentStoreRemoteChangeNotificationPostOptionKey] as? NSNumber
        XCTAssertEqual(value, true, "Remote change notifications required for CloudKit to propagate remote writes to the view context")
    }

    func test_productionConfig_setsCloudKitContainerOptions() {
        let description = NSPersistentStoreDescription()
        PersistenceController.configureProductionStore(description)
        XCTAssertNotNil(
            description.cloudKitContainerOptions,
            "cloudKitContainerOptions must be set for NSPersistentCloudKitContainer to sync"
        )
    }

    func test_productionConfig_cloudKitContainerOptionsMatchIdentifier() {
        let description = NSPersistentStoreDescription()
        PersistenceController.configureProductionStore(description)
        XCTAssertEqual(
            description.cloudKitContainerOptions?.containerIdentifier,
            PersistenceController.iCloudContainerIdentifier
        )
    }

    // MARK: - In-memory store must not have CloudKit options
    // Applying CloudKit options to an in-memory store would crash at loadPersistentStores.

    func test_inMemoryController_storeURLIsDevNull() {
        let controller = PersistenceController(inMemory: true)
        let url = controller.container.persistentStoreDescriptions.first?.url
        XCTAssertEqual(url, URL(fileURLWithPath: "/dev/null"))
    }

    func test_inMemoryController_storeDescriptionHasNoCloudKitOptions() {
        let controller = PersistenceController(inMemory: true)
        XCTAssertNil(
            controller.container.persistentStoreDescriptions.first?.cloudKitContainerOptions,
            "In-memory stores must not have CloudKit options — they cannot sync"
        )
    }
}
