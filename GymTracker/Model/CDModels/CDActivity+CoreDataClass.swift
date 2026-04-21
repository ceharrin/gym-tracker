import Foundation
import CoreData

@objc(CDActivity)
public class CDActivity: NSManagedObject {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDActivity> {
        NSFetchRequest<CDActivity>(entityName: "CDActivity")
    }
    @NSManaged public var category: String
    @NSManaged public var createdAt: Date
    @NSManaged public var icon: String
    @NSManaged public var id: UUID?
    @NSManaged public var instructions: String?
    @NSManaged public var isPreset: Bool
    @NSManaged public var muscleGroups: String?
    @NSManaged public var name: String
    @NSManaged public var primaryMetric: String
    @NSManaged public var entries: NSSet?
}
extension CDActivity: Identifiable {}
