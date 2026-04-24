import XCTest
import CoreData
@testable import GymTracker

// Verifies the Core Data model is compatible with NSPersistentCloudKitContainer's
// schema requirements. Failures here indicate model changes needed before sync will work.
final class CloudKitCompatibilityTests: XCTestCase {

    // Load the model via the test context so we use the same model the app uses.
    private var model: NSManagedObjectModel {
        CoreDataTestHelper.makeContext().persistentStoreCoordinator!.managedObjectModel
    }

    // MARK: - External binary storage

    // CloudKit cannot sync binary data stored outside the SQLite file
    // (allowsExternalBinaryDataStorage). All binary attributes must be stored inline.
    func test_noBinaryAttributeUsesExternalStorage() {
        for entity in model.entities {
            for attr in entity.attributesByName.values where attr.attributeType == .binaryDataAttributeType {
                XCTAssertFalse(
                    attr.allowsExternalBinaryDataStorage,
                    "\(entity.name ?? "?").\(attr.name) uses external binary storage — " +
                    "CloudKit cannot sync these. Store inline or use CKAsset."
                )
            }
        }
    }

    // MARK: - Non-optional attributes must have defaults

    // CloudKit mirrors the Core Data schema as a CKRecord type. Any non-optional
    // attribute without a default value will fail schema initialisation.
    func test_allNonOptionalAttributesHaveDefaultValues() {
        for entity in model.entities {
            for attr in entity.attributesByName.values where !attr.isOptional {
                XCTAssertNotNil(
                    attr.defaultValue,
                    "\(entity.name ?? "?").\(attr.name) is non-optional but has no default — " +
                    "CloudKit schema initialisation will fail without a default value."
                )
            }
        }
    }

    // MARK: - Relationship delete rules

    // CloudKit does not support the Deny delete rule. All relationships must use
    // Nullify, Cascade, or No Action.
    func test_noRelationshipUsesDenyDeleteRule() {
        for entity in model.entities {
            for rel in entity.relationshipsByName.values {
                XCTAssertNotEqual(
                    rel.deleteRule,
                    .denyDeleteRule,
                    "\(entity.name ?? "?").\(rel.name) uses Deny delete rule — not supported by CloudKit"
                )
            }
        }
    }

    // MARK: - Entity and attribute names

    // CloudKit record field names are derived from Core Data attribute names.
    // Names must not start with an underscore (reserved by CloudKit).
    func test_noAttributeNameStartsWithUnderscore() {
        for entity in model.entities {
            for attr in entity.attributesByName.keys {
                XCTAssertFalse(
                    attr.hasPrefix("_"),
                    "\(entity.name ?? "?").\(attr) starts with underscore — reserved by CloudKit"
                )
            }
        }
    }
}
