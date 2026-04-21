import CoreData
import CloudKit
import Foundation

struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentCloudKitContainer

    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "GymTracker")

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        } else {
            guard let description = container.persistentStoreDescriptions.first else {
                fatalError("No persistent store descriptions found")
            }
            description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
                containerIdentifier: "iCloud.com.chrisharrington.GymTracker"
            )
            // Required for CloudKit sync to track and propagate changes
            description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            description.setOption(true as NSNumber,
                                  forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
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
