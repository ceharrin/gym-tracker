import Foundation
import CoreData

@objc(CDBodyMeasurement)
public class CDBodyMeasurement: NSManagedObject {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDBodyMeasurement> {
        NSFetchRequest<CDBodyMeasurement>(entityName: "CDBodyMeasurement")
    }
    @NSManaged public var bodyFatPercent: Double
    @NSManaged public var date: Date
    @NSManaged public var id: UUID?
    @NSManaged public var notes: String?
    @NSManaged public var weightKg: Double
    @NSManaged public var profile: CDUserProfile?
}
extension CDBodyMeasurement: Identifiable {}
