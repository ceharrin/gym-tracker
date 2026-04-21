import Foundation
import CoreData

extension CDBodyMeasurement {
    var weightLbs: Double { weightKg * 2.20462 }
}
