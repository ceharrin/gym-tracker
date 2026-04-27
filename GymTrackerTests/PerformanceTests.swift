import XCTest
import CoreData
@testable import GymTracker

// Benchmarks for the three hottest Core Data paths.
// Dataset: 500 workouts × 5 activities × 4 sets = 10,000 CDEntrySet rows.
// Each measure{} block runs the operation 10 times; Xcode reports mean ± stddev.
final class PerformanceTests: XCTestCase {

    private var context: NSManagedObjectContext!
    private var activities: [CDActivity] = []

    // Seed once per test — setUp runs before every measure{} invocation but
    // the context is re-created each time so the store starts fresh.
    override func setUp() {
        super.setUp()
        context = CoreDataTestHelper.makeContext()
        activities = seedActivities(count: 5)
        seedWorkouts(count: 500, activities: activities, setsPerEntry: 4)
    }

    // MARK: - 1. Fetch all workouts (WorkoutListView path)

    func test_performance_fetchAllWorkouts() {
        let request = CDWorkout.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDWorkout.date, ascending: false)]

        measure {
            _ = try? context.fetch(request)
        }
    }

    // MARK: - 2. Save one workout (LogWorkoutView.save path)

    func test_performance_saveWorkout() {
        measure {
            let workout = CDWorkout(context: context)
            workout.id = UUID()
            workout.title = "Perf Workout"
            workout.date = Date()
            workout.durationMinutes = 60
            workout.energyLevel = 7

            for (idx, activity) in activities.enumerated() {
                let entry = CDWorkoutEntry(context: context)
                entry.id = UUID()
                entry.orderIndex = Int16(idx)
                entry.activity = activity
                entry.workout = workout

                for setNum in 1...4 {
                    let set = CDEntrySet(context: context)
                    set.id = UUID()
                    set.setNumber = Int16(setNum)
                    set.weightKg = Double(60 + setNum * 5)
                    set.reps = 8
                    set.entry = entry
                }
            }

            try? context.save()
        }
    }

    // MARK: - 3. PR history fetch (LogWorkoutView.historicalSets path)

    // Mirrors historicalSets(for:excludingWorkout:) in LogWorkoutView exactly:
    // fetches all CDWorkoutEntry rows for an activity then flatMaps to sets.
    func test_performance_prHistoryFetch() {
        guard let activity = activities.first else { return }

        measure {
            let request = CDWorkoutEntry.fetchRequest()
            request.predicate = NSPredicate(format: "activity == %@", activity)
            let entries = (try? context.fetch(request)) ?? []
            _ = entries.flatMap { entry -> [CDEntrySet] in
                (entry.sets as? Set<CDEntrySet> ?? []).sorted { $0.setNumber < $1.setNumber }
            }
        }
    }

    // MARK: - Seed helpers

    @discardableResult
    private func seedActivities(count: Int) -> [CDActivity] {
        (1...count).map { i in
            let a = CDActivity(context: context)
            a.id = UUID()
            a.name = "Exercise \(i)"
            a.category = ActivityCategory.strength.rawValue
            a.primaryMetric = PrimaryMetric.weightReps.rawValue
            a.isPreset = false
            return a
        }
    }

    private func seedWorkouts(count: Int, activities: [CDActivity], setsPerEntry: Int) {
        let base = Date(timeIntervalSince1970: 0)
        for day in 0..<count {
            let workout = CDWorkout(context: context)
            workout.id = UUID()
            workout.title = "Workout \(day)"
            workout.date = Calendar.current.date(byAdding: .day, value: day, to: base)!
            workout.durationMinutes = 60
            workout.energyLevel = 7

            for (idx, activity) in activities.enumerated() {
                let entry = CDWorkoutEntry(context: context)
                entry.id = UUID()
                entry.orderIndex = Int16(idx)
                entry.activity = activity
                entry.workout = workout

                for setNum in 1...setsPerEntry {
                    let set = CDEntrySet(context: context)
                    set.id = UUID()
                    set.setNumber = Int16(setNum)
                    set.weightKg = Double(60 + setNum * 5)
                    set.reps = 8
                    set.entry = entry
                }
            }
        }
        try! context.save()
    }
}
