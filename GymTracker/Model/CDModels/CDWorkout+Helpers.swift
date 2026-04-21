import Foundation
import CoreData

extension CDWorkout {
    var sortedEntries: [CDWorkoutEntry] {
        let set = entries as? Set<CDWorkoutEntry> ?? []
        return set.sorted { $0.orderIndex < $1.orderIndex }
    }

    var totalSets: Int {
        sortedEntries.reduce(0) { $0 + $1.sortedSets.count }
    }

    var activitySummary: String {
        let names = sortedEntries.compactMap { $0.activity?.name }
        guard !names.isEmpty else { return "No exercises" }
        if names.count <= 2 { return names.joined(separator: ", ") }
        return "\(names[0]), \(names[1]) +\(names.count - 2) more"
    }

    var formattedDate: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f.string(from: date)
    }
}
