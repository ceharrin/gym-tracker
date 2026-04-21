import Foundation
import CoreData

@objc(CDUserProfile)
public class CDUserProfile: NSManagedObject {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDUserProfile> {
        NSFetchRequest<CDUserProfile>(entityName: "CDUserProfile")
    }
    @NSManaged public var birthDate: Date?
    @NSManaged public var createdAt: Date
    @NSManaged public var goals: String?
    @NSManaged public var heightCm: Double
    @NSManaged public var name: String
    @NSManaged public var photoData: Data?
    @NSManaged public var measurements: NSSet?
}
extension CDUserProfile: Identifiable {}
