import Foundation
import CoreData

extension CDEntrySet {
    var weightLbs: Double { weightKg * 2.20462 }
    var distanceKm: Double { distanceMeters / 1000 }
    var distanceMiles: Double { distanceMeters / 1609.34 }

    var formattedDuration: String {
        let h = durationSeconds / 3600
        let m = (durationSeconds % 3600) / 60
        let s = durationSeconds % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, s) }
        return String(format: "%d:%02d", m, s)
    }

    var pacePerUnit: String? {
        guard distanceMeters > 0, durationSeconds > 0 else { return nil }
        let unitDist = Units.distanceValue(fromMeters: distanceMeters)
        let secsPerUnit = Double(durationSeconds) / unitDist
        let m = Int(secsPerUnit) / 60
        let s = Int(secsPerUnit) % 60
        return String(format: "%d:%02d /\(Units.distanceUnit)", m, s)
    }
}
