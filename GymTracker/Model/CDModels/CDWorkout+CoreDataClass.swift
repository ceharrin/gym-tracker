import Foundation
import CoreData

@objc(CDWorkout)
public class CDWorkout: NSManagedObject {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDWorkout> {
        NSFetchRequest<CDWorkout>(entityName: "CDWorkout")
    }
    @NSManaged public var date: Date
    @NSManaged public var durationMinutes: Int32
    @NSManaged public var energyLevel: Int16
    @NSManaged public var id: UUID?
    @NSManaged public var isCompleted: Bool
    @NSManaged public var notes: String?
    @NSManaged public var startedAt: Date?
    @NSManaged public var title: String
    @NSManaged public var entries: NSSet?
}
extension CDWorkout: Identifiable {}
