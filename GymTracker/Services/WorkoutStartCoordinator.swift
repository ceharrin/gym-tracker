import Foundation

struct WorkoutStartDestination: Identifiable, Equatable {
    enum Mode: Equatable {
        case newWorkout
        case resumeExisting
        case repeatCompleted
    }

    let id = UUID()
    let mode: Mode
    let workout: CDWorkout?
}

enum WorkoutStartCoordinator {
    static func startDestination(from workouts: [CDWorkout]) -> WorkoutStartDestination {
        if let inProgress = inProgressWorkout(from: workouts) {
            return WorkoutStartDestination(mode: .resumeExisting, workout: inProgress)
        }

        return newWorkoutDestination()
    }

    static func newWorkoutDestination() -> WorkoutStartDestination {
        WorkoutStartDestination(mode: .newWorkout, workout: nil)
    }

    static func inProgressWorkout(from workouts: [CDWorkout]) -> CDWorkout? {
        workouts
            .filter { !$0.isCompleted }
            .sorted(by: { $0.date > $1.date })
            .first
    }

    static func repeatDestination(from workouts: [CDWorkout]) -> WorkoutStartDestination? {
        workouts
            .filter(\.isCompleted)
            .sorted(by: { $0.date > $1.date })
            .first
            .map { WorkoutStartDestination(mode: .repeatCompleted, workout: $0) }
    }
}
