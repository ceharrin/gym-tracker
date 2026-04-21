import Foundation
import CoreData

extension CDUserProfile {
    var age: Int? {
        guard let birthDate else { return nil }
        return Calendar.current.dateComponents([.year], from: birthDate, to: Date()).year
    }

    var heightFeetInches: String {
        let totalInches = heightCm / 2.54
        let feet = Int(totalInches) / 12
        let inches = Int(totalInches) % 12
        return "\(feet)'\(inches)\""
    }

    var sortedMeasurements: [CDBodyMeasurement] {
        let set = measurements as? Set<CDBodyMeasurement> ?? []
        return set.sorted { $0.date < $1.date }
    }

    var latestWeight: CDBodyMeasurement? {
        sortedMeasurements.last
    }
}
