import Foundation
import CoreData
@testable import GymTracker

enum CoreDataTestHelper {
    /// Returns an in-memory managed object context backed by the same
    /// NSPersistentCloudKitContainer the production app uses. This ensures
    /// tests exercise the real stack (merge policies, model version, etc.)
    /// rather than a plain NSPersistentContainer that can silently diverge.
    static func makeContext() -> NSManagedObjectContext {
        PersistenceController(inMemory: true).context
    }
}
