import CoreData
import Foundation

struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "GymTracker")

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        } else if let description = container.persistentStoreDescriptions.first {
            description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
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
