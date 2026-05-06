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

    // MARK: - 4. Large backup export/import stress test

    @MainActor
    func test_stress_backupExportAndImport_with2500VaryingWorkouts() throws {
        let sourceContext = CoreDataTestHelper.makeContext()
        let targetContext = CoreDataTestHelper.makeContext()
        let dataset = BackupStressDataset(
            workoutCount: 2_500,
            activityCount: 48,
            measurementCount: 24
        )

        try seedBackupStressDataset(dataset, into: sourceContext)
        XCTAssertTrue(try LocalBackupExporter.hasMeaningfulData(in: sourceContext))

        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("BackupStress-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let exportStartedAt = Date()
        let exportURL = try LocalBackupExporter.exportBackup(from: sourceContext, directory: directory)
        let exportDuration = Date().timeIntervalSince(exportStartedAt)

        let exportedData = try Data(contentsOf: exportURL)
        XCTAssertGreaterThan(exportedData.count, 0)

        let importStartedAt = Date()
        try LocalBackupExporter.importBackup(from: exportURL, into: targetContext)
        let importDuration = Date().timeIntervalSince(importStartedAt)

        let sourceSnapshot = try LocalBackupExporter.snapshot(from: sourceContext)
        let importedSnapshot = try LocalBackupExporter.snapshot(from: targetContext)

        XCTAssertEqual(importedSnapshot.workouts.count, dataset.workoutCount)
        XCTAssertEqual(importedSnapshot.workouts.count, sourceSnapshot.workouts.count)
        XCTAssertEqual(importedSnapshot.activities.count, sourceSnapshot.activities.count)
        XCTAssertEqual(importedSnapshot.measurements.count, sourceSnapshot.measurements.count)
        XCTAssertEqual(importedSnapshot.profiles.first?.name, sourceSnapshot.profiles.first?.name)
        XCTAssertEqual(importedSnapshot.workouts.first?.entries.count, sourceSnapshot.workouts.first?.entries.count)
        XCTAssertEqual(
            importedSnapshot.workouts.last?.entries.last?.sets.last?.reps,
            sourceSnapshot.workouts.last?.entries.last?.sets.last?.reps
        )

        print(
            "Backup stress test: \(dataset.workoutCount) workouts, " +
            "\(exportedData.count / 1_048_576) MB JSON, " +
            String(format: "export %.2fs import %.2fs", exportDuration, importDuration)
        )
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

    @MainActor
    private func seedBackupStressDataset(
        _ dataset: BackupStressDataset,
        into context: NSManagedObjectContext
    ) throws {
        let profile = CDUserProfile(context: context)
        profile.name = "Stress Test User"
        profile.createdAt = Date(timeIntervalSinceReferenceDate: 100)
        profile.heightCm = 181
        profile.goals = "Test backup scaling"

        for measurementIndex in 0..<dataset.measurementCount {
            let measurement = CDBodyMeasurement(context: context)
            measurement.id = UUID()
            measurement.date = Date(timeIntervalSinceReferenceDate: Double(measurementIndex * 86_400))
            measurement.weightKg = 92 - Double(measurementIndex) * 0.1
            measurement.bodyFatPercent = 18 - Double(measurementIndex) * 0.05
            measurement.notes = measurementIndex.isMultiple(of: 3) ? "Check-in \(measurementIndex)" : nil
            measurement.profile = profile
        }

        let activities = (0..<dataset.activityCount).map { index -> CDActivity in
            let activity = CDActivity(context: context)
            activity.id = UUID()
            activity.name = "Stress Activity \(index + 1)"
            activity.category = ActivityCategory.strength.rawValue
            activity.icon = "dumbbell.fill"
            activity.primaryMetric = PrimaryMetric.weightReps.rawValue
            activity.isPreset = index < 12
            activity.instructions = index.isMultiple(of: 5) ? "Keep form tight" : nil
            activity.muscleGroups = ["Chest", "Back", "Legs", "Shoulders", "Arms"][index % 5]
            activity.createdAt = Date(timeIntervalSinceReferenceDate: Double(index))
            return activity
        }

        let baseDate = Date(timeIntervalSinceReferenceDate: 500_000)
        for workoutIndex in 0..<dataset.workoutCount {
            let workout = CDWorkout(context: context)
            workout.id = UUID()
            workout.title = "Workout \(workoutIndex + 1)"
            workout.date = Calendar.current.date(byAdding: .day, value: -workoutIndex, to: baseDate)!
            workout.startedAt = Calendar.current.date(byAdding: .minute, value: -((workoutIndex % 90) + 20), to: workout.date)!
            workout.durationMinutes = Int32((workoutIndex % 75) + 20)
            workout.energyLevel = Int16((workoutIndex % 10) + 1)
            workout.isCompleted = true
            workout.notes = workoutIndex.isMultiple(of: 7) ? "Felt strong on set \(workoutIndex % 4 + 1)" : nil

            let entryCount = (workoutIndex % 5) + 2
            for entryIndex in 0..<entryCount {
                let entry = CDWorkoutEntry(context: context)
                entry.id = UUID()
                entry.orderIndex = Int16(entryIndex)
                entry.workout = workout
                entry.activity = activities[(workoutIndex + entryIndex) % activities.count]
                entry.notes = entryIndex.isMultiple(of: 3) ? "Focus cue \(entryIndex)" : nil

                let setCount = (workoutIndex + entryIndex) % 6 + 1
                for setIndex in 0..<setCount {
                    let set = CDEntrySet(context: context)
                    set.id = UUID()
                    set.setNumber = Int16(setIndex + 1)
                    set.weightKg = Double(40 + ((workoutIndex + entryIndex + setIndex) % 140))
                    set.reps = Int32(4 + ((workoutIndex + setIndex) % 12))
                    set.distanceMeters = 0
                    set.durationSeconds = 0
                    set.laps = 0
                    set.customValue = 0
                    set.customLabel = nil
                    set.notes = setIndex.isMultiple(of: 4) ? "Set note \(setIndex)" : nil
                    set.isPRAttempt = (workoutIndex + entryIndex + setIndex).isMultiple(of: 19)
                    set.entry = entry
                }
            }
        }

        try context.saveIfChanged()
    }
}

private struct BackupStressDataset {
    let workoutCount: Int
    let activityCount: Int
    let measurementCount: Int
}
