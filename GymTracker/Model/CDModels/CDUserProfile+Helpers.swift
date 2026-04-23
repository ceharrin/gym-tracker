import Foundation
import CoreData

enum WeightTrend: Equatable {
    case up, down, flat, none
}

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

    var weightTrend: WeightTrend {
        let m = sortedMeasurements
        guard m.count >= 2 else { return .none }
        let diff = m[m.count - 1].weightKg - m[m.count - 2].weightKg
        if diff > 0.01 { return .up }
        if diff < -0.01 { return .down }
        return .flat
    }
}
