import Foundation
import CoreData
import SwiftUI

enum ActivityCategory: String, CaseIterable, Identifiable {
    case strength = "strength"
    case cardio = "cardio"
    case swimming = "swimming"
    case cycling = "cycling"
    case yoga = "yoga"
    case hiit = "hiit"
    case custom = "custom"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .strength: return "Strength"
        case .cardio:   return "Cardio"
        case .swimming: return "Swimming"
        case .cycling:  return "Cycling"
        case .yoga:     return "Yoga & Flexibility"
        case .hiit:     return "HIIT"
        case .custom:   return "Custom"
        }
    }

    var icon: String {
        switch self {
        case .strength: return "dumbbell.fill"
        case .cardio:   return "figure.run"
        case .swimming: return "figure.pool.swim"
        case .cycling:  return "bicycle"
        case .yoga:     return "figure.yoga"
        case .hiit:     return "bolt.heart.fill"
        case .custom:   return "star.fill"
        }
    }

    var color: Color {
        switch self {
        case .strength: return .blue
        case .cardio:   return .orange
        case .swimming: return .cyan
        case .cycling:  return .purple
        case .yoga:     return .mint
        case .hiit:     return .red
        case .custom:   return .gray
        }
    }

    var defaultMetric: PrimaryMetric {
        switch self {
        case .strength: return .weightReps
        case .cardio:   return .distanceTime
        case .swimming: return .lapsTime
        case .cycling:  return .distanceTime
        case .yoga:     return .duration
        case .hiit:     return .duration
        case .custom:   return .custom
        }
    }
}

enum PrimaryMetric: String, CaseIterable, Identifiable {
    case weightReps   = "weight_reps"
    case distanceTime = "distance_time"
    case lapsTime     = "laps_time"
    case duration     = "duration"
    case custom       = "custom"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .weightReps:   return "Weight & Reps"
        case .distanceTime: return "Distance & Time"
        case .lapsTime:     return "Laps & Time"
        case .duration:     return "Duration Only"
        case .custom:       return "Custom"
        }
    }

    var primaryLabel: String {
        switch self {
        case .weightReps:   return "Weight (kg)"
        case .distanceTime: return "Distance (km)"
        case .lapsTime:     return "Laps"
        case .duration:     return "Duration"
        case .custom:       return "Value"
        }
    }

    var secondaryLabel: String? {
        switch self {
        case .weightReps:   return "Reps"
        case .distanceTime: return "Time"
        case .lapsTime:     return "Time"
        case .duration:     return nil
        case .custom:       return nil
        }
    }

    // MARK: - Progress chart helpers

    /// Y-axis label used in progress charts and exported reports.
    var chartYLabel: String {
        switch self {
        case .weightReps:   return Units.weightUnit
        case .distanceTime: return Units.distanceUnit
        case .lapsTime:     return "laps"
        case .duration:     return "min"
        case .custom:       return "value"
        }
    }

    /// Extracts the single representative value from a set for charting
    /// (best set, converted to display units).
    func chartValue(from set: CDEntrySet) -> Double {
        switch self {
        case .weightReps:   return Units.weightValue(fromKg: set.weightKg)
        case .distanceTime: return Units.distanceValue(fromMeters: set.distanceMeters)
        case .lapsTime:     return Double(set.laps)
        case .duration:     return Double(set.durationSeconds) / 60
        case .custom:       return set.customValue
        }
    }

    /// Formats a chart value for annotation labels.
    func formattedChartValue(_ value: Double) -> String {
        switch self {
        case .lapsTime, .duration: return String(format: "%.0f", value)
        default:                   return String(format: "%.1f", value)
        }
    }

    func personalRecords(from sets: [CDEntrySet]) -> [ProgressPersonalRecord] {
        switch self {
        case .weightReps:
            var records: [ProgressPersonalRecord] = []
            if let best = sets.max(by: { $0.weightKg < $1.weightKg }) {
                records.append(
                    ProgressPersonalRecord(
                        label: "Heaviest Weight",
                        value: "\(Units.displayWeight(kg: best.weightKg)) × \(best.reps) reps"
                    )
                )
            }
            if let most = sets.max(by: { $0.reps < $1.reps }) {
                records.append(
                    ProgressPersonalRecord(
                        label: "Most Reps",
                        value: "\(most.reps) @ \(Units.displayWeight(kg: most.weightKg))"
                    )
                )
            }
            return records
        case .distanceTime:
            var records: [ProgressPersonalRecord] = []
            if let longest = sets.max(by: { $0.distanceMeters < $1.distanceMeters }) {
                records.append(
                    ProgressPersonalRecord(
                        label: "Longest Distance",
                        value: Units.displayDistance(meters: longest.distanceMeters)
                    )
                )
            }
            if let fastest = sets.filter({ $0.distanceMeters > 0 }).min(by: {
                Double($0.durationSeconds) / $0.distanceMeters < Double($1.durationSeconds) / $1.distanceMeters
            }), let pace = fastest.pacePerUnit {
                records.append(
                    ProgressPersonalRecord(
                        label: "Best Pace",
                        value: pace
                    )
                )
            }
            return records
        case .lapsTime:
            guard let most = sets.max(by: { $0.laps < $1.laps }) else { return [] }
            return [ProgressPersonalRecord(label: "Most Laps", value: "\(most.laps) laps")]
        case .duration:
            guard let longest = sets.max(by: { $0.durationSeconds < $1.durationSeconds }) else { return [] }
            return [ProgressPersonalRecord(label: "Longest Session", value: longest.formattedDuration)]
        case .custom:
            guard let best = sets.max(by: { $0.customValue < $1.customValue }) else { return [] }
            return [
                ProgressPersonalRecord(
                    label: "Best",
                    value: String(format: "%.1f %@", best.customValue, best.customLabel ?? "")
                )
            ]
        }
    }

    func primaryRecordSummary(from sets: [CDEntrySet]) -> String? {
        personalRecords(from: sets).first?.value
    }
}

struct ProgressChartPoint {
    let date: Date
    let value: Double
}

struct ProgressPersonalRecord: Identifiable {
    let label: String
    let value: String

    var id: String { label }
}

extension CDActivity {
    func progressEntries(cutoffDate: Date?) -> [CDWorkoutEntry] {
        sortedEntries.filter { entry in
            guard let date = entry.workout?.date else { return false }
            if let cutoffDate { return date >= cutoffDate }
            return true
        }
    }

    func progressChartPoints(cutoffDate: Date?) -> [ProgressChartPoint] {
        progressEntries(cutoffDate: cutoffDate)
            .compactMap { entry -> ProgressChartPoint? in
                guard let date = entry.workout?.date, let set = entry.bestSet else { return nil }
                return ProgressChartPoint(date: date, value: metric.chartValue(from: set))
            }
            .sorted { $0.date < $1.date }
    }

    func progressSets(cutoffDate: Date?) -> [CDEntrySet] {
        progressEntries(cutoffDate: cutoffDate).flatMap { $0.sortedSets }
    }

    func progressPersonalRecords(cutoffDate: Date?) -> [ProgressPersonalRecord] {
        metric.personalRecords(from: progressSets(cutoffDate: cutoffDate))
    }

    func progressPrimaryRecordSummary(cutoffDate: Date?) -> String? {
        metric.primaryRecordSummary(from: progressSets(cutoffDate: cutoffDate))
    }
}
