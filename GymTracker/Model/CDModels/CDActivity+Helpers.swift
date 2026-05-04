import Foundation
import CoreData

enum StrengthEquipmentGroup: String, CaseIterable, Identifiable {
    case barbell
    case dumbbell
    case machine
    case cable
    case bodyweightCore
    case customStrength

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .barbell: return "Barbell"
        case .dumbbell: return "Dumbbell"
        case .machine: return "Machines"
        case .cable: return "Cable"
        case .bodyweightCore: return "Bodyweight & Core"
        case .customStrength: return "Custom Strength"
        }
    }
}

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

    var strengthEquipmentGroup: StrengthEquipmentGroup {
        guard activityCategory == .strength else { return .customStrength }
        guard isPreset else { return .customStrength }

        switch name {
        case "Back Squat", "Front Squat", "Box Squat", "Deadlift", "Romanian Deadlift",
             "Sumo Deadlift", "Good Morning", "Hip Thrust", "Barbell Lunge",
             "Barbell Split Squat", "Bench Press", "Incline Bench Press",
             "Close-Grip Bench Press", "Overhead Press", "Push Press",
             "Barbell Row", "Pendlay Row", "Shrug":
            return .barbell

        case "Goblet Squat", "Dumbbell Bench Press", "Incline Dumbbell Press",
             "Dumbbell Floor Press", "Dumbbell Fly", "Dumbbell Shoulder Press",
             "Arnold Press", "Lateral Raise", "Front Raise", "Rear Delt Fly",
             "One-Arm Dumbbell Row", "Chest-Supported Dumbbell Row", "Dumbbell Shrug",
             "Dumbbell Romanian Deadlift", "Dumbbell Walking Lunge",
             "Dumbbell Split Squat", "Step-Up", "Dumbbell Curl",
             "Hammer Curl", "Overhead Triceps Extension":
            return .dumbbell

        case "Leg Press", "Hack Squat", "Smith Machine Squat", "Smith Machine Bench Press",
             "Smith Machine Incline Press", "Leg Curl", "Leg Extension", "Chest Press",
             "Incline Chest Press", "Pec Deck", "Rear Delt Machine", "Lat Pulldown",
             "Seated Cable Row", "High Row Machine", "Assisted Pull-Up",
             "Shoulder Press", "Bicep Curl", "Triceps Pushdown", "Hip Abduction",
             "Hip Adduction", "Calf Raise Machine":
            return .machine

        case "Cable Chest Fly", "Cable Row", "Face Pull", "Straight-Arm Pulldown",
             "Cable Lateral Raise", "Cable Curl", "Rope Hammer Curl",
             "Overhead Cable Triceps Extension", "Cable Crunch", "Pallof Press",
             "Glute Cable Kickback":
            return .cable

        case "Pull-Up", "Chin-Up", "Push-Up", "Dip", "Bodyweight Squat",
             "Bulgarian Split Squat", "Glute Bridge", "Plank", "Hanging Leg Raise":
            return .bodyweightCore

        default:
            return .customStrength
        }
    }
}
