import Foundation
import CoreData

@objc(CDWorkoutEntry)
public class CDWorkoutEntry: NSManagedObject {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDWorkoutEntry> {
        NSFetchRequest<CDWorkoutEntry>(entityName: "CDWorkoutEntry")
    }
    @NSManaged public var id: UUID?
    @NSManaged public var notes: String?
    @NSManaged public var orderIndex: Int16
    @NSManaged public var activity: CDActivity?
    @NSManaged public var sets: NSSet?
    @NSManaged public var workout: CDWorkout?
}
extension CDWorkoutEntry: Identifiable {}
