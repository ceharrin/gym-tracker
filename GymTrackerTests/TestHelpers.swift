import Foundation
import CoreData
@testable import GymTracker

enum CoreDataTestHelper {
    static func makeContext() -> NSManagedObjectContext {
        let container = NSPersistentContainer(name: "GymTracker")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores { _, error in
            if let error { fatalError(error.localizedDescription) }
        }
        return container.viewContext
    }
}
