import CoreData
import Foundation

struct LocalBackupImportWarning: Equatable {
    let workoutCount: Int
    let measurementCount: Int
    let customActivityCount: Int
    let hasProfileDetails: Bool

    var requiresConfirmation: Bool {
        workoutCount > 0 || measurementCount > 0 || customActivityCount > 0 || hasProfileDetails
    }

    var message: String {
        guard requiresConfirmation else { return "" }

        var parts: [String] = []
        if workoutCount > 0 {
            parts.append("\(workoutCount) workout\(workoutCount == 1 ? "" : "s")")
        }
        if measurementCount > 0 {
            parts.append("\(measurementCount) measurement\(measurementCount == 1 ? "" : "s")")
        }
        if customActivityCount > 0 {
            parts.append("\(customActivityCount) custom activit\(customActivityCount == 1 ? "y" : "ies")")
        }
        if hasProfileDetails {
            parts.append("profile details")
        }

        let joined = ListFormatter.localizedString(byJoining: parts)
        return "Importing a backup will replace the current local \(joined) on this device."
    }
}

enum LocalBackupExporter {
    static let exportDirectoryName = "LocalBackups"

    struct BackupSnapshot: Codable {
        let app: String
        let exportedAt: Date
        let profiles: [ProfileSnapshot]
        let measurements: [MeasurementSnapshot]
        let activities: [ActivitySnapshot]
        let workouts: [WorkoutSnapshot]
    }

    struct ProfileSnapshot: Codable {
        let id: UUID?
        let name: String
        let createdAt: Date
        let birthDate: Date?
        let goals: String?
        let heightCm: Double
        let photoDataBase64: String?
    }

    struct MeasurementSnapshot: Codable {
        let id: UUID?
        let date: Date
        let weightKg: Double
        let bodyFatPercent: Double
        let notes: String?
    }

    struct ActivitySnapshot: Codable {
        let id: UUID?
        let name: String
        let category: String
        let icon: String
        let primaryMetric: String
        let isPreset: Bool
        let instructions: String?
        let muscleGroups: String?
        let createdAt: Date
    }

    struct WorkoutSnapshot: Codable {
        let id: UUID?
        let title: String
        let date: Date
        let startedAt: Date?
        let durationMinutes: Int32
        let energyLevel: Int16
        let isCompleted: Bool
        let notes: String?
        let entries: [WorkoutEntrySnapshot]
    }

    struct WorkoutEntrySnapshot: Codable {
        let id: UUID?
        let activityID: UUID?
        let activityName: String?
        let notes: String?
        let orderIndex: Int16
        let sets: [WorkoutSetSnapshot]
    }

    struct WorkoutSetSnapshot: Codable {
        let id: UUID?
        let setNumber: Int16
        let weightKg: Double
        let reps: Int32
        let distanceMeters: Double
        let durationSeconds: Int32
        let laps: Int32
        let customValue: Double
        let customLabel: String?
        let notes: String?
        let isPRAttempt: Bool
    }

    enum ExportError: LocalizedError {
        case noMeaningfulData
        case directoryCreationFailure(Error)
        case writeFailure(Error)

        var errorDescription: String? {
            switch self {
            case .noMeaningfulData:
                return "There isn't any workout, measurement, custom activity, or filled-in profile data to back up yet."
            case .directoryCreationFailure(let error):
                return "Could not prepare the backup folder: \(error.localizedDescription)"
            case .writeFailure(let error):
                return "Could not create the backup file: \(error.localizedDescription)"
            }
        }
    }

    enum ImportError: LocalizedError {
        case unreadableData(Error)
        case invalidBackup(Error)
        case missingProfile
        case writeFailure(Error)

        var errorDescription: String? {
            switch self {
            case .unreadableData(let error):
                return "Could not read the selected backup file: \(error.localizedDescription)"
            case .invalidBackup(let error):
                return "The selected file isn't a valid GymTracker backup: \(error.localizedDescription)"
            case .missingProfile:
                return "The backup file doesn't include a profile to restore."
            case .writeFailure(let error):
                return "Could not restore the backup: \(error.localizedDescription)"
            }
        }
    }

    @MainActor
    static func exportBackup(from context: NSManagedObjectContext, directory: URL? = nil) throws -> URL {
        guard try hasMeaningfulData(in: context) else {
            throw ExportError.noMeaningfulData
        }

        let dir = try directory ?? defaultExportDirectory()
        let snapshot = try snapshot(from: context)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        let data: Data
        do {
            data = try encoder.encode(snapshot)
        } catch {
            throw ExportError.writeFailure(error)
        }

        let filename = backupFilename()
        let destinationURL = dir.appendingPathComponent(filename)
        do {
            try data.write(to: destinationURL, options: .atomic)
            return destinationURL
        } catch {
            throw ExportError.writeFailure(error)
        }
    }

    @MainActor
    static func importBackup(from fileURL: URL, into context: NSManagedObjectContext) throws {
        let didAccess = fileURL.startAccessingSecurityScopedResource()
        defer {
            if didAccess {
                fileURL.stopAccessingSecurityScopedResource()
            }
        }

        let data: Data
        do {
            data = try Data(contentsOf: fileURL)
        } catch {
            throw ImportError.unreadableData(error)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let snapshot: BackupSnapshot
        do {
            snapshot = try decoder.decode(BackupSnapshot.self, from: data)
        } catch {
            throw ImportError.invalidBackup(error)
        }

        try restore(snapshot: snapshot, into: context)
    }

    static func snapshot(from context: NSManagedObjectContext) throws -> BackupSnapshot {
        let profileRequest = CDUserProfile.fetchRequest()
        let activityRequest = CDActivity.fetchRequest()
        let workoutRequest = CDWorkout.fetchRequest()
        let measurementRequest = CDBodyMeasurement.fetchRequest()

        let profiles = try context.fetch(profileRequest)
        let activities = try context.fetch(activityRequest)
        let workouts = try context.fetch(workoutRequest)
        let measurements = try context.fetch(measurementRequest)

        return BackupSnapshot(
            app: "GymTracker",
            exportedAt: Date(),
            profiles: profiles.map {
                ProfileSnapshot(
                    id: nil,
                    name: $0.name,
                    createdAt: $0.createdAt,
                    birthDate: $0.birthDate,
                    goals: $0.goals,
                    heightCm: $0.heightCm,
                    photoDataBase64: $0.photoData?.base64EncodedString()
                )
            },
            measurements: measurements.sorted { $0.date < $1.date }.map {
                MeasurementSnapshot(
                    id: $0.id,
                    date: $0.date,
                    weightKg: $0.weightKg,
                    bodyFatPercent: $0.bodyFatPercent,
                    notes: $0.notes
                )
            },
            activities: activities.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }.map {
                ActivitySnapshot(
                    id: $0.id,
                    name: $0.name,
                    category: $0.category,
                    icon: $0.icon,
                    primaryMetric: $0.primaryMetric,
                    isPreset: $0.isPreset,
                    instructions: $0.instructions,
                    muscleGroups: $0.muscleGroups,
                    createdAt: $0.createdAt
                )
            },
            workouts: workouts.sorted { $0.date > $1.date }.map { workout in
                WorkoutSnapshot(
                    id: workout.id,
                    title: workout.title,
                    date: workout.date,
                    startedAt: workout.startedAt,
                    durationMinutes: workout.durationMinutes,
                    energyLevel: workout.energyLevel,
                    isCompleted: workout.isCompleted,
                    notes: workout.notes,
                    entries: workout.sortedEntries.map { entry in
                        WorkoutEntrySnapshot(
                            id: entry.id,
                            activityID: entry.activity?.id,
                            activityName: entry.activity?.name,
                            notes: entry.notes,
                            orderIndex: entry.orderIndex,
                            sets: entry.sortedSets.map { set in
                                WorkoutSetSnapshot(
                                    id: set.id,
                                    setNumber: set.setNumber,
                                    weightKg: set.weightKg,
                                    reps: set.reps,
                                    distanceMeters: set.distanceMeters,
                                    durationSeconds: set.durationSeconds,
                                    laps: set.laps,
                                    customValue: set.customValue,
                                    customLabel: set.customLabel,
                                    notes: set.notes,
                                    isPRAttempt: set.isPRAttempt
                                )
                            }
                        )
                    }
                )
            }
        )
    }

    static func hasMeaningfulData(in context: NSManagedObjectContext) throws -> Bool {
        let workouts = try context.count(for: CDWorkout.fetchRequest())
        let measurements = try context.count(for: CDBodyMeasurement.fetchRequest())

        let customActivitiesRequest = CDActivity.fetchRequest()
        customActivitiesRequest.predicate = NSPredicate(format: "isPreset == NO")
        let customActivities = try context.count(for: customActivitiesRequest)

        let profiles = try context.fetch(CDUserProfile.fetchRequest())
        return hasMeaningfulData(
            workoutCount: workouts,
            measurementCount: measurements,
            customActivityCount: customActivities,
            hasProfileDetails: profiles.contains(where: hasMeaningfulProfileDetails)
        )
    }

    static func hasMeaningfulData(
        workoutCount: Int,
        measurementCount: Int,
        customActivityCount: Int,
        hasProfileDetails: Bool
    ) -> Bool {
        workoutCount > 0 || measurementCount > 0 || customActivityCount > 0 || hasProfileDetails
    }

    static func hasMeaningfulProfileDetails(_ profile: CDUserProfile) -> Bool {
        !profile.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        profile.heightCm > 0 ||
        profile.birthDate != nil ||
        !(profile.goals?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true) ||
        profile.photoData != nil
    }

    static func importWarning(
        workoutCount: Int,
        measurementCount: Int,
        customActivityCount: Int,
        hasProfileDetails: Bool
    ) -> LocalBackupImportWarning {
        LocalBackupImportWarning(
            workoutCount: workoutCount,
            measurementCount: measurementCount,
            customActivityCount: customActivityCount,
            hasProfileDetails: hasProfileDetails
        )
    }

    static func defaultExportDirectory(fileManager: FileManager = .default) throws -> URL {
        do {
            let base = try fileManager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let exports = base.appendingPathComponent(exportDirectoryName, isDirectory: true)
            try fileManager.createDirectory(at: exports, withIntermediateDirectories: true)
            return exports
        } catch {
            throw ExportError.directoryCreationFailure(error)
        }
    }

    static func backupFilename(exportedAt: Date = Date(), token: String = String(UUID().uuidString.prefix(6))) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return "GymTracker Backup \(formatter.string(from: exportedAt)) \(token.uppercased()).json"
    }

    private static func restore(snapshot: BackupSnapshot, into context: NSManagedObjectContext) throws {
        guard let profileSnapshot = snapshot.profiles.first else {
            throw ImportError.missingProfile
        }

        do {
            try deleteExistingData(in: context)

            let profile = restoreProfile(profileSnapshot, into: context)
            restoreMeasurements(snapshot.measurements, profile: profile, into: context)
            let activitiesByID = restoreActivities(snapshot.activities, into: context)
            restoreWorkouts(snapshot.workouts, activitiesByID: activitiesByID, into: context)

            try context.saveIfChanged()
        } catch let error as ImportError {
            context.rollback()
            throw error
        } catch {
            context.rollback()
            throw ImportError.writeFailure(error)
        }
    }

    private static func deleteExistingData(in context: NSManagedObjectContext) throws {
        for workout in try context.fetch(CDWorkout.fetchRequest()) {
            context.delete(workout)
        }
        for activity in try context.fetch(CDActivity.fetchRequest()) {
            context.delete(activity)
        }
        for profile in try context.fetch(CDUserProfile.fetchRequest()) {
            context.delete(profile)
        }
    }

    @discardableResult
    private static func restoreProfile(_ snapshot: ProfileSnapshot, into context: NSManagedObjectContext) -> CDUserProfile {
        let profile = CDUserProfile(context: context)
        profile.name = snapshot.name
        profile.createdAt = snapshot.createdAt
        profile.birthDate = snapshot.birthDate
        profile.goals = snapshot.goals
        profile.heightCm = snapshot.heightCm
        profile.photoData = snapshot.photoDataBase64.flatMap { Data(base64Encoded: $0) }
        return profile
    }

    private static func restoreMeasurements(
        _ snapshots: [MeasurementSnapshot],
        profile: CDUserProfile,
        into context: NSManagedObjectContext
    ) {
        for snapshot in snapshots {
            let measurement = CDBodyMeasurement(context: context)
            measurement.id = snapshot.id
            measurement.date = snapshot.date
            measurement.weightKg = snapshot.weightKg
            measurement.bodyFatPercent = snapshot.bodyFatPercent
            measurement.notes = snapshot.notes
            measurement.profile = profile
        }
    }

    private static func restoreActivities(
        _ snapshots: [ActivitySnapshot],
        into context: NSManagedObjectContext
    ) -> [UUID: CDActivity] {
        var activitiesByID: [UUID: CDActivity] = [:]

        for snapshot in snapshots {
            let activity = CDActivity(context: context)
            activity.id = snapshot.id
            activity.name = snapshot.name
            activity.category = snapshot.category
            activity.icon = snapshot.icon
            activity.primaryMetric = snapshot.primaryMetric
            activity.isPreset = snapshot.isPreset
            activity.instructions = snapshot.instructions
            activity.muscleGroups = snapshot.muscleGroups
            activity.createdAt = snapshot.createdAt

            if let id = snapshot.id {
                activitiesByID[id] = activity
            }
        }

        return activitiesByID
    }

    private static func restoreWorkouts(
        _ snapshots: [WorkoutSnapshot],
        activitiesByID: [UUID: CDActivity],
        into context: NSManagedObjectContext
    ) {
        for snapshot in snapshots {
            let workout = CDWorkout(context: context)
            workout.id = snapshot.id
            workout.title = snapshot.title
            workout.date = snapshot.date
            workout.startedAt = snapshot.startedAt
            workout.durationMinutes = snapshot.durationMinutes
            workout.energyLevel = snapshot.energyLevel
            workout.isCompleted = snapshot.isCompleted
            workout.notes = snapshot.notes

            restoreEntries(snapshot.entries, workout: workout, activitiesByID: activitiesByID, into: context)
        }
    }

    private static func restoreEntries(
        _ snapshots: [WorkoutEntrySnapshot],
        workout: CDWorkout,
        activitiesByID: [UUID: CDActivity],
        into context: NSManagedObjectContext
    ) {
        for snapshot in snapshots {
            let entry = CDWorkoutEntry(context: context)
            entry.id = snapshot.id
            entry.orderIndex = snapshot.orderIndex
            entry.notes = snapshot.notes
            entry.workout = workout
            entry.activity = resolvedActivity(for: snapshot, activitiesByID: activitiesByID)

            restoreSets(snapshot.sets, entry: entry, into: context)
        }
    }

    private static func resolvedActivity(
        for snapshot: WorkoutEntrySnapshot,
        activitiesByID: [UUID: CDActivity]
    ) -> CDActivity? {
        if let activityID = snapshot.activityID, let activity = activitiesByID[activityID] {
            return activity
        }
        guard let activityName = snapshot.activityName else { return nil }
        return activitiesByID.values.first { $0.name == activityName }
    }

    private static func restoreSets(
        _ snapshots: [WorkoutSetSnapshot],
        entry: CDWorkoutEntry,
        into context: NSManagedObjectContext
    ) {
        for snapshot in snapshots {
            let set = CDEntrySet(context: context)
            set.id = snapshot.id
            set.setNumber = snapshot.setNumber
            set.weightKg = snapshot.weightKg
            set.reps = snapshot.reps
            set.distanceMeters = snapshot.distanceMeters
            set.durationSeconds = snapshot.durationSeconds
            set.laps = snapshot.laps
            set.customValue = snapshot.customValue
            set.customLabel = snapshot.customLabel
            set.notes = snapshot.notes
            set.isPRAttempt = snapshot.isPRAttempt
            set.entry = entry
        }
    }
}
