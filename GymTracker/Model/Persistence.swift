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
        let initialContainer = NSPersistentContainer(
            name: "GymTracker",
            managedObjectModel: Self.managedObjectModel
        )

        if inMemory {
            let description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
            initialContainer.persistentStoreDescriptions = [description]
        } else if let description = initialContainer.persistentStoreDescriptions.first {
            PersistenceController.configureProductionStore(description)
        }

        container = Self.loadedContainer(from: initialContainer, inMemory: inMemory)

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

    static func storeFileURLs(for storeURL: URL) -> [URL] {
        [
            storeURL,
            URL(fileURLWithPath: storeURL.path + "-shm"),
            URL(fileURLWithPath: storeURL.path + "-wal")
        ]
    }

    @discardableResult
    static func quarantineStoreFiles(
        at storeURL: URL,
        fileManager: FileManager = .default
    ) throws -> URL? {
        let existingFiles = storeFileURLs(for: storeURL).filter { fileManager.fileExists(atPath: $0.path) }
        guard !existingFiles.isEmpty else { return nil }

        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        let quarantineDirectory = storeURL
            .deletingLastPathComponent()
            .appendingPathComponent("FailedStore-\(formatter.string(from: Date()))-\(UUID().uuidString.prefix(6))", isDirectory: true)

        try fileManager.createDirectory(at: quarantineDirectory, withIntermediateDirectories: true)
        for fileURL in existingFiles {
            try fileManager.moveItem(
                at: fileURL,
                to: quarantineDirectory.appendingPathComponent(fileURL.lastPathComponent)
            )
        }

        return quarantineDirectory
    }

    var context: NSManagedObjectContext { container.viewContext }

    private static func loadedContainer(
        from initialContainer: NSPersistentContainer,
        inMemory: Bool
    ) -> NSPersistentContainer {
        var loadError: Error?
        initialContainer.loadPersistentStores { _, error in
            loadError = error
        }

        guard let loadError else { return initialContainer }
        guard !inMemory, recoverProductionStoreAfterLoadFailure(loadError, container: initialContainer) else {
            fatalError("Core Data store failed: \(loadError)")
        }

        let recoveredContainer = NSPersistentContainer(
            name: "GymTracker",
            managedObjectModel: Self.managedObjectModel
        )
        if let description = recoveredContainer.persistentStoreDescriptions.first {
            configureProductionStore(description)
        }

        var retryError: Error?
        recoveredContainer.loadPersistentStores { _, error in
            retryError = error
        }

        if let retryError {
            fatalError("Core Data store failed after recovery: \(retryError)")
        }

        return recoveredContainer
    }

    private static func recoverProductionStoreAfterLoadFailure(
        _ error: Error,
        container: NSPersistentContainer
    ) -> Bool {
        guard let storeURL = container.persistentStoreDescriptions.first?.url else {
            print("Core Data store failed without a store URL: \(error)")
            return false
        }

        do {
            guard let quarantineDirectory = try Self.quarantineStoreFiles(at: storeURL) else {
                print("Core Data store failed with no store files to recover: \(error)")
                return false
            }
            print("Core Data store failed and was moved to \(quarantineDirectory.path): \(error)")
            return true
        } catch {
            print("Core Data store recovery failed: \(error)")
            return false
        }
    }

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
