import Foundation
import CoreData

@objc(CDEntrySet)
public class CDEntrySet: NSManagedObject {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDEntrySet> {
        NSFetchRequest<CDEntrySet>(entityName: "CDEntrySet")
    }
    @NSManaged public var customLabel: String?
    @NSManaged public var customValue: Double
    @NSManaged public var distanceMeters: Double
    @NSManaged public var durationSeconds: Int32
    @NSManaged public var id: UUID?
    @NSManaged public var laps: Int32
    @NSManaged public var notes: String?
    @NSManaged public var reps: Int32
    @NSManaged public var setNumber: Int16
    @NSManaged public var weightKg: Double
    @NSManaged public var isPRAttempt: Bool
    @NSManaged public var entry: CDWorkoutEntry?
}
extension CDEntrySet: Identifiable {}
