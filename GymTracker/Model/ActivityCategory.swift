import Foundation
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
}
