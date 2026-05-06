import XCTest
import CoreData
@testable import GymTracker

final class LocalBackupExporterTests: XCTestCase {

    var context: NSManagedObjectContext!

    override func setUp() {
        super.setUp()
        context = CoreDataTestHelper.makeContext()
    }

    @MainActor
    func test_snapshot_includesProfileWorkoutsActivitiesAndMeasurements() throws {
        let profile = CDUserProfile(context: context)
        profile.name = "Chris"
        profile.createdAt = Date(timeIntervalSinceReferenceDate: 10)
        profile.heightCm = 180
        profile.goals = "Get stronger"

        let measurement = CDBodyMeasurement(context: context)
        measurement.id = UUID()
        measurement.date = Date(timeIntervalSinceReferenceDate: 20)
        measurement.weightKg = 95
        measurement.bodyFatPercent = 18
        measurement.profile = profile

        let activity = CDActivity(context: context)
        activity.id = UUID()
        activity.name = "Bench Press"
        activity.category = ActivityCategory.strength.rawValue
        activity.icon = "dumbbell.fill"
        activity.primaryMetric = PrimaryMetric.weightReps.rawValue
        activity.isPreset = true
        activity.createdAt = Date(timeIntervalSinceReferenceDate: 30)

        let workout = CDWorkout(context: context)
        workout.id = UUID()
        workout.title = "Push Day"
        workout.date = Date(timeIntervalSinceReferenceDate: 40)
        workout.startedAt = Date(timeIntervalSinceReferenceDate: 35)
        workout.durationMinutes = 45
        workout.energyLevel = 7
        workout.isCompleted = true

        let entry = CDWorkoutEntry(context: context)
        entry.id = UUID()
        entry.orderIndex = 0
        entry.workout = workout
        entry.activity = activity

        let set = CDEntrySet(context: context)
        set.id = UUID()
        set.setNumber = 1
        set.weightKg = 100
        set.reps = 8
        set.isPRAttempt = true
        set.entry = entry

        try context.saveIfChanged()

        let snapshot = try LocalBackupExporter.snapshot(from: context)

        XCTAssertEqual(snapshot.profiles.count, 1)
        XCTAssertEqual(snapshot.profiles.first?.name, "Chris")
        XCTAssertEqual(snapshot.measurements.count, 1)
        XCTAssertEqual(snapshot.measurements.first?.weightKg, 95)
        XCTAssertEqual(snapshot.activities.count, 1)
        XCTAssertEqual(snapshot.activities.first?.name, "Bench Press")
        XCTAssertEqual(snapshot.workouts.count, 1)
        XCTAssertEqual(snapshot.workouts.first?.entries.first?.sets.first?.reps, 8)
    }

    @MainActor
    func test_exportBackup_createsJSONFile() throws {
        let profile = CDUserProfile(context: context)
        profile.name = "Backup Tester"
        profile.createdAt = Date()
        profile.heightCm = 175

        try context.saveIfChanged()

        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let url = try LocalBackupExporter.exportBackup(from: context, directory: directory)

        XCTAssertEqual(url.pathExtension, "json")
        let data = try Data(contentsOf: url)
        XCTAssertFalse(data.isEmpty)

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertEqual(json?["app"] as? String, "GymTracker")
        XCTAssertEqual(json?["profiles"] as? [[String: Any]] != nil, true)
    }

    @MainActor
    func test_hasMeaningfulData_falseForPlaceholderProfileAndPresetActivitiesOnly() throws {
        let profile = CDUserProfile(context: context)
        profile.name = ""
        profile.createdAt = Date()
        profile.heightCm = 0

        let preset = CDActivity(context: context)
        preset.id = UUID()
        preset.name = "Bench Press"
        preset.category = ActivityCategory.strength.rawValue
        preset.icon = "dumbbell.fill"
        preset.primaryMetric = PrimaryMetric.weightReps.rawValue
        preset.isPreset = true
        preset.createdAt = Date()

        try context.saveIfChanged()

        XCTAssertFalse(try LocalBackupExporter.hasMeaningfulData(in: context))
    }

    @MainActor
    func test_exportBackup_throwsWhenNoMeaningfulDataExists() throws {
        let profile = CDUserProfile(context: context)
        profile.name = ""
        profile.createdAt = Date()
        profile.heightCm = 0
        try context.saveIfChanged()

        XCTAssertThrowsError(try LocalBackupExporter.exportBackup(from: context))
    }

    func test_importWarning_requiresConfirmationWhenExistingDataWouldBeReplaced() {
        let warning = LocalBackupImportWarning(
            workoutCount: 12,
            measurementCount: 3,
            customActivityCount: 2,
            hasProfileDetails: true
        )

        XCTAssertTrue(warning.requiresConfirmation)
        XCTAssertTrue(warning.message.contains("12 workouts"))
        XCTAssertTrue(warning.message.contains("3 measurements"))
        XCTAssertTrue(warning.message.contains("2 custom activities"))
        XCTAssertTrue(warning.message.contains("profile details"))
    }

    func test_importWarning_doesNotRequireConfirmationWhenNoMeaningfulDataExists() {
        let warning = LocalBackupImportWarning(
            workoutCount: 0,
            measurementCount: 0,
            customActivityCount: 0,
            hasProfileDetails: false
        )

        XCTAssertFalse(warning.requiresConfirmation)
        XCTAssertTrue(warning.message.isEmpty)
    }

    @MainActor
    func test_importBackup_replacesExistingDataWithImportedSnapshot() throws {
        let existingProfile = CDUserProfile(context: context)
        existingProfile.name = "Existing"
        existingProfile.createdAt = Date(timeIntervalSinceReferenceDate: 1)
        existingProfile.heightCm = 170

        let existingWorkout = CDWorkout(context: context)
        existingWorkout.id = UUID()
        existingWorkout.title = "Old Workout"
        existingWorkout.date = Date(timeIntervalSinceReferenceDate: 2)
        existingWorkout.durationMinutes = 20
        existingWorkout.energyLevel = 5
        existingWorkout.isCompleted = true

        try context.saveIfChanged()

        let importedActivityID = UUID()
        let snapshot = LocalBackupExporter.BackupSnapshot(
            app: "GymTracker",
            exportedAt: Date(timeIntervalSinceReferenceDate: 100),
            profiles: [
                .init(
                    id: UUID(),
                    name: "Imported Chris",
                    createdAt: Date(timeIntervalSinceReferenceDate: 10),
                    birthDate: nil,
                    goals: "Imported Goals",
                    heightCm: 182,
                    photoDataBase64: nil
                )
            ],
            measurements: [
                .init(
                    id: UUID(),
                    date: Date(timeIntervalSinceReferenceDate: 20),
                    weightKg: 90,
                    bodyFatPercent: 15,
                    notes: "Lean"
                )
            ],
            activities: [
                .init(
                    id: importedActivityID,
                    name: "Imported Row",
                    category: ActivityCategory.strength.rawValue,
                    icon: "dumbbell.fill",
                    primaryMetric: PrimaryMetric.weightReps.rawValue,
                    isPreset: false,
                    instructions: nil,
                    muscleGroups: "Back",
                    createdAt: Date(timeIntervalSinceReferenceDate: 30)
                )
            ],
            workouts: [
                .init(
                    id: UUID(),
                    title: "Imported Workout",
                    date: Date(timeIntervalSinceReferenceDate: 40),
                    startedAt: Date(timeIntervalSinceReferenceDate: 35),
                    durationMinutes: 45,
                    energyLevel: 8,
                    isCompleted: true,
                    notes: "Imported Notes",
                    entries: [
                        .init(
                            id: UUID(),
                            activityID: importedActivityID,
                            activityName: "Imported Row",
                            notes: "Entry Note",
                            orderIndex: 0,
                            sets: [
                                .init(
                                    id: UUID(),
                                    setNumber: 1,
                                    weightKg: 80,
                                    reps: 10,
                                    distanceMeters: 0,
                                    durationSeconds: 0,
                                    laps: 0,
                                    customValue: 0,
                                    customLabel: nil,
                                    notes: "Set Note",
                                    isPRAttempt: true
                                )
                            ]
                        )
                    ]
                )
            ]
        )

        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).json")
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        try encoder.encode(snapshot).write(to: fileURL)

        try LocalBackupExporter.importBackup(from: fileURL, into: context)

        let profiles = try context.fetch(CDUserProfile.fetchRequest())
        XCTAssertEqual(profiles.count, 1)
        XCTAssertEqual(profiles.first?.name, "Imported Chris")

        let activities = try context.fetch(CDActivity.fetchRequest())
        XCTAssertEqual(activities.count, 1)
        XCTAssertEqual(activities.first?.name, "Imported Row")

        let workouts = try context.fetch(CDWorkout.fetchRequest())
        XCTAssertEqual(workouts.count, 1)
        XCTAssertEqual(workouts.first?.title, "Imported Workout")
        XCTAssertEqual(workouts.first?.sortedEntries.first?.sortedSets.first?.reps, 10)
    }

    @MainActor
    func test_stress_exportAndImport_with2500VaryingWorkouts() throws {
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

        let sizeInMB = String(format: "%.2f", Double(exportedData.count) / 1_048_576.0)
        let timings = String(format: "export %.2fs import %.2fs", exportDuration, importDuration)
        print("Backup stress test: \(dataset.workoutCount) workouts, \(sizeInMB) MB JSON, \(timings)")
    }

    // MARK: - Stress helpers

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
