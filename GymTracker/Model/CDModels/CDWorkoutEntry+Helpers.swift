import Foundation
import CoreData

extension CDWorkoutEntry {
    var sortedSets: [CDEntrySet] {
        let set = sets as? Set<CDEntrySet> ?? []
        return set.sorted { $0.setNumber < $1.setNumber }
    }

    var bestSet: CDEntrySet? {
        let s = sortedSets
        guard !s.isEmpty else { return nil }
        switch activity?.metric {
        case .weightReps:   return s.max { $0.weightKg < $1.weightKg }
        case .distanceTime: return s.max { $0.distanceMeters < $1.distanceMeters }
        case .lapsTime:     return s.max { $0.laps < $1.laps }
        case .duration:     return s.max { $0.durationSeconds < $1.durationSeconds }
        case .reps:         return s.max { $0.reps < $1.reps }
        default:            return s.first
        }
    }
}
