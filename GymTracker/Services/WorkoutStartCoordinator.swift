import Foundation

struct WorkoutStartDestination: Identifiable, Equatable {
    enum Mode: Equatable {
        case newWorkout
        case resumeExisting
    }

    let id = UUID()
    let mode: Mode
    let workout: CDWorkout?
}

enum WorkoutStartCoordinator {
    static func startDestination(from workouts: [CDWorkout]) -> WorkoutStartDestination {
        if let inProgress = workouts
            .filter({ !$0.isCompleted })
            .sorted(by: { $0.date > $1.date })
            .first {
            return WorkoutStartDestination(mode: .resumeExisting, workout: inProgress)
        }

        return WorkoutStartDestination(mode: .newWorkout, workout: nil)
    }
}
