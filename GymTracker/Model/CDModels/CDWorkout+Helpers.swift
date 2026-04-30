import Foundation
import CoreData
import SwiftUI

extension CDWorkout {
    var canRenderInUI: Bool {
        !isDeleted && managedObjectContext != nil
    }

    var sessionStartDate: Date {
        startedAt ?? date
    }

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

    var formattedDuration: String? {
        guard isCompleted || durationMinutes > 0 else { return nil }
        return "\(durationMinutes) min"
    }

    var statusLabel: String? {
        isCompleted ? nil : "In Progress"
    }

    /// True if any set in this workout was flagged as a PR attempt.
    var hasPersonalBest: Bool {
        sortedEntries.contains { entry in
            entry.sortedSets.contains { $0.isPRAttempt }
        }
    }

    /// SF Symbol name for the first activity's category (or a fallback dumbbell).
    var primaryCategoryIcon: String {
        sortedEntries.first?.activity?.activityCategory.icon ?? "dumbbell.fill"
    }

    /// Accent color for the first activity's category (or the app accent color).
    var primaryCategoryColor: Color {
        sortedEntries.first?.activity?.activityCategory.color ?? Color.accentColor
    }
}
