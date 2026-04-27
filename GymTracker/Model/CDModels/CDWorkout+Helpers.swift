import Foundation
import CoreData
import SwiftUI

enum HealthKitSyncState: String, CaseIterable {
    case notSynced = "not_synced"
    case pending
    case synced
    case failed

    var displayText: String {
        switch self {
        case .notSynced:
            return "Not synced to Apple Health"
        case .pending:
            return "Syncing to Apple Health"
        case .synced:
            return "Synced to Apple Health"
        case .failed:
            return "Apple Health sync failed"
        }
    }

    var symbolName: String {
        switch self {
        case .notSynced:
            return "heart.text.square"
        case .pending:
            return "arrow.triangle.2.circlepath"
        case .synced:
            return "checkmark.circle.fill"
        case .failed:
            return "exclamationmark.triangle.fill"
        }
    }

    var tint: Color {
        switch self {
        case .notSynced:
            return .secondary
        case .pending:
            return .orange
        case .synced:
            return .green
        case .failed:
            return .red
        }
    }
}

extension CDWorkout {
    var healthKitSyncState: HealthKitSyncState {
        get { HealthKitSyncState(rawValue: healthKitSyncStateRaw) ?? .notSynced }
        set { healthKitSyncStateRaw = newValue.rawValue }
    }

    var healthKitCanRetrySync: Bool {
        healthKitWorkoutUUID == nil && (healthKitSyncState == .failed || healthKitSyncState == .notSynced)
    }

    var healthKitWorkoutEndDate: Date {
        date.addingTimeInterval(TimeInterval(durationMinutes) * 60)
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

    /// SF Symbol name for the first activity's category (or a fallback dumbbell).
    var primaryCategoryIcon: String {
        sortedEntries.first?.activity?.activityCategory.icon ?? "dumbbell.fill"
    }

    /// Accent color for the first activity's category (or the app accent color).
    var primaryCategoryColor: Color {
        sortedEntries.first?.activity?.activityCategory.color ?? Color.accentColor
    }
}
