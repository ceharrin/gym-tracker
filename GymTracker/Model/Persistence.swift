import CoreData
import Foundation
import SwiftUI

struct PersistenceController {
    static let shared: PersistenceController = {
        // Use an in-memory store when running under XCTest so the test host app
        // does not open the simulator's on-disk store (avoiding migration conflicts).
        let isTests = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
        return PersistenceController(inMemory: isTests)
    }()

    /// Reuse one managed object model instance across containers so tests do not
    /// accumulate duplicate entity descriptions for the same NSManagedObject subclasses.
    static let managedObjectModel: NSManagedObjectModel = {
        let bundle = Bundle(for: ModelBundleToken.self)

        guard let modelURL = bundle.url(forResource: "GymTracker", withExtension: "momd"),
              let model = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Unable to load GymTracker.momd from bundle \(bundle.bundlePath)")
        }

        return model
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(
            name: "GymTracker",
            managedObjectModel: Self.managedObjectModel
        )

        if inMemory {
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
            ActivitySeeder.deduplicatePresets(context: container.viewContext)
        }
    }

    static func configureProductionStore(_ description: NSPersistentStoreDescription) {
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true
        // Keep history tracking enabled so existing stores created under the
        // prior CloudKit-backed configuration continue to open read-write.
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
    }

    var context: NSManagedObjectContext { container.viewContext }

    func save() {
        guard context.hasChanges else { return }
        do { try context.save() } catch {
            // Failures here come from seeding/profile creation at launch.
            // A fatalError would crash in production; logging is the safest response.
            print("PersistenceController.save: \(error)")
        }
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

private final class ModelBundleToken {}

// MARK: - Convenience save

extension NSManagedObjectContext {
    /// Saves only when there are pending changes. Throws on failure so callers
    /// can roll back and surface errors rather than silently discarding data.
    func saveIfChanged() throws {
        guard hasChanges else { return }
        try save()
    }
}

struct PersistenceAlertState: Identifiable {
    let id = UUID()
    let title: String
    let message: String

    init(title: String, message: String) {
        self.title = title
        self.message = message
    }

    init(title: String, error: Error, fallbackMessage: String = "An unknown error occurred.") {
        self.title = title
        let description = error.localizedDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        self.message = description.isEmpty ? fallbackMessage : description
    }
}

extension View {
    func persistenceErrorAlert(_ alert: Binding<PersistenceAlertState?>) -> some View {
        self.alert(item: alert) { state in
            Alert(
                title: Text(state.title),
                message: Text(state.message),
                dismissButton: .cancel(Text("OK"))
            )
        }
    }
}
