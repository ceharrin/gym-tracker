import Foundation
import CoreData

extension CDActivity {
    var activityCategory: ActivityCategory {
        ActivityCategory(rawValue: category) ?? .custom
    }

    var metric: PrimaryMetric {
        PrimaryMetric(rawValue: primaryMetric) ?? .weightReps
    }

    var sortedEntries: [CDWorkoutEntry] {
        let set = entries as? Set<CDWorkoutEntry> ?? []
        return set.sorted { ($0.workout?.date ?? .distantPast) > ($1.workout?.date ?? .distantPast) }
    }
}
