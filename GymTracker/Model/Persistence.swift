import CoreData
import CloudKit
import Foundation

struct PersistenceController {
    static let shared: PersistenceController = {
        // Use an in-memory store when running under XCTest so the test host app
        // does not open the simulator's on-disk store (avoiding migration conflicts).
        let isTests = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
        return PersistenceController(inMemory: isTests)
    }()

    // Must match the iCloud container configured in the Apple Developer portal
    // and the app's entitlements.
    static let iCloudContainerIdentifier = "iCloud.com.ceharrin.GymTracker"

    let container: NSPersistentCloudKitContainer

    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "GymTracker")

        if inMemory {
            // Use a proper in-memory store description rather than /dev/null.
            // NSPersistentCloudKitContainer requires this to avoid migration checks
            // against any existing on-disk store.
            let description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
            container.persistentStoreDescriptions = [description]
        } else if let description = container.persistentStoreDescriptions.first {
            PersistenceController.configureProductionStore(description)
        }

        container.loadPersistentStores { _, error in
            if let error {
                fatalError("Core Data store failed: \(error)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        if !inMemory {
            ensureProfileExists()
            ActivitySeeder.seedIfNeeded(context: container.viewContext)
        }
    }

    /// Applies all options required for CloudKit sync to a persistent store description.
    /// Extracted so the configuration can be tested independently of a loaded store.
    static func configureProductionStore(_ description: NSPersistentStoreDescription) {
        // Allows Core Data to migrate existing stores automatically when the model
        // changes (e.g. removing allowsExternalBinaryDataStorage from photoData).
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true
        // Required by CloudKit and by existing on-disk stores (removing this causes
        // a "permission" save error on stores that were created with it enabled).
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        // Tells the view context to merge remote changes as they arrive.
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
            containerIdentifier: iCloudContainerIdentifier
        )
    }

    var context: NSManagedObjectContext { container.viewContext }

    func save() {
        guard context.hasChanges else { return }
        try? context.save()
    }

    private func ensureProfileExists() {
        let req = CDUserProfile.fetchRequest()
        let count = (try? context.count(for: req)) ?? 0
        guard count == 0 else { return }
        let profile = CDUserProfile(context: context)
        profile.name = ""
        profile.createdAt = Date()
        profile.heightCm = 0
        save()
    }
}
