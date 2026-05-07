import Foundation
import CoreData
import SwiftUI

struct WorkoutTotals {
    let totalWeightVolumeKg: Double
    let totalReps: Int32
    let totalDistanceMeters: Double
    let totalDurationSeconds: Int32
    let totalLaps: Int32
    let totalCustomValue: Double

    var hasAnyValue: Bool {
        totalWeightVolumeKg > 0 ||
        totalReps > 0 ||
        totalDistanceMeters > 0 ||
        totalDurationSeconds > 0 ||
        totalLaps > 0 ||
        totalCustomValue > 0
    }
}

enum WorkoutTotalMetric: String, CaseIterable, Identifiable {
    case weightVolume
    case reps
    case distance
    case duration
    case laps
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .weightVolume: return "Weight Lifted"
        case .reps: return "Reps"
        case .distance: return "Distance"
        case .duration: return "Duration"
        case .laps: return "Laps"
        case .custom: return "Custom"
        }
    }

    var icon: String {
        switch self {
        case .weightVolume: return "scalemass.fill"
        case .reps: return "number"
        case .distance: return "point.topleft.down.curvedto.point.bottomright.up"
        case .duration: return "timer"
        case .laps: return "oval"
        case .custom: return "star.fill"
        }
    }

    var chartLabel: String {
        switch self {
        case .weightVolume: return Units.weightUnit
        case .reps: return "reps"
        case .distance: return Units.distanceUnit
        case .duration: return "min"
        case .laps: return "laps"
        case .custom: return "value"
        }
    }

    func value(from workout: CDWorkout) -> Double {
        let totals = workout.totals
        switch self {
        case .weightVolume: return Units.weightValue(fromKg: totals.totalWeightVolumeKg)
        case .reps: return Double(totals.totalReps)
        case .distance: return Units.distanceValue(fromMeters: totals.totalDistanceMeters)
        case .duration: return Double(totals.totalDurationSeconds) / 60.0
        case .laps: return Double(totals.totalLaps)
        case .custom: return totals.totalCustomValue
        }
    }

    func formattedValue(from workout: CDWorkout) -> String {
        formattedValue(value(from: workout))
    }

    func formattedValue(_ value: Double) -> String {
        switch self {
        case .weightVolume:
            return String(format: "%.0f %@", value, Units.weightUnit)
        case .reps:
            return "\(Int(value.rounded())) reps"
        case .distance:
            return String(format: "%.2f %@", value, Units.distanceUnit)
        case .duration:
            return Self.formattedDuration(seconds: Int32((value * 60).rounded()))
        case .laps:
            return "\(Int(value.rounded())) laps"
        case .custom:
            return String(format: "%.1f", value)
        }
    }

    private static func formattedDuration(seconds: Int32) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        if hours > 0 {
            return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
        }
        return "\(minutes)m"
    }
}

struct WorkoutTotalChartPoint: Identifiable {
    let id: NSManagedObjectID
    let date: Date
    let title: String
    let value: Double
}

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

    var totals: WorkoutTotals {
        let allSets = sortedEntries.flatMap(\.sortedSets)
        return WorkoutTotals(
            totalWeightVolumeKg: allSets.reduce(0) { $0 + ($1.weightKg * Double($1.reps)) },
            totalReps: allSets.reduce(0) { $0 + $1.reps },
            totalDistanceMeters: allSets.reduce(0) { $0 + $1.distanceMeters },
            totalDurationSeconds: allSets.reduce(0) { $0 + $1.durationSeconds },
            totalLaps: allSets.reduce(0) { $0 + $1.laps },
            totalCustomValue: allSets.reduce(0) { $0 + $1.customValue }
        )
    }

    var displayableTotalMetrics: [WorkoutTotalMetric] {
        WorkoutTotalMetric.allCases.filter { $0.value(from: self) > 0 }
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

extension Array where Element == CDWorkout {
    func workoutTotalChartPoints(for metric: WorkoutTotalMetric, cutoffDate: Date?) -> [WorkoutTotalChartPoint] {
        compactMap { workout -> WorkoutTotalChartPoint? in
            guard workout.canRenderInUI else { return nil }
            if let cutoffDate, workout.date < cutoffDate { return nil }

            let value = metric.value(from: workout)
            guard value > 0 else { return nil }

            return WorkoutTotalChartPoint(
                id: workout.objectID,
                date: workout.date,
                title: workout.title,
                value: value
            )
        }
        .sorted { $0.date < $1.date }
    }
}
