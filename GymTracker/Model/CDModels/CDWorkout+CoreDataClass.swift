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
    @NSManaged public var healthKitLastError: String?
    @NSManaged public var healthKitLastSyncAt: Date?
    @NSManaged public var healthKitSyncStateRaw: String
    @NSManaged public var healthKitWorkoutUUID: UUID?
    @NSManaged public var id: UUID?
    @NSManaged public var notes: String?
    @NSManaged public var title: String
    @NSManaged public var entries: NSSet?
}
extension CDWorkout: Identifiable {}
