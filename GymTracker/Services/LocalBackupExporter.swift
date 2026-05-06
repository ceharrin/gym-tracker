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

        let joined = ListFormatter.localizedString(byJoining: parts) ?? parts.joined(separator: ", ")
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
        if workouts > 0 { return true }

        let measurements = try context.count(for: CDBodyMeasurement.fetchRequest())
        if measurements > 0 { return true }

        let customActivitiesRequest = CDActivity.fetchRequest()
        customActivitiesRequest.predicate = NSPredicate(format: "isPreset == NO")
        let customActivities = try context.count(for: customActivitiesRequest)
        if customActivities > 0 { return true }

        let profiles = try context.fetch(CDUserProfile.fetchRequest())
        return profiles.contains { profile in
            !profile.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
            profile.heightCm > 0 ||
            profile.birthDate != nil ||
            !(profile.goals?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true) ||
            profile.photoData != nil
        }
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
            for workout in try context.fetch(CDWorkout.fetchRequest()) {
                context.delete(workout)
            }
            for activity in try context.fetch(CDActivity.fetchRequest()) {
                context.delete(activity)
            }
            for profile in try context.fetch(CDUserProfile.fetchRequest()) {
                context.delete(profile)
            }

            let profile = CDUserProfile(context: context)
            profile.name = profileSnapshot.name
            profile.createdAt = profileSnapshot.createdAt
            profile.birthDate = profileSnapshot.birthDate
            profile.goals = profileSnapshot.goals
            profile.heightCm = profileSnapshot.heightCm
            if let base64 = profileSnapshot.photoDataBase64 {
                profile.photoData = Data(base64Encoded: base64)
            } else {
                profile.photoData = nil
            }

            for measurementSnapshot in snapshot.measurements {
                let measurement = CDBodyMeasurement(context: context)
                measurement.id = measurementSnapshot.id
                measurement.date = measurementSnapshot.date
                measurement.weightKg = measurementSnapshot.weightKg
                measurement.bodyFatPercent = measurementSnapshot.bodyFatPercent
                measurement.notes = measurementSnapshot.notes
                measurement.profile = profile
            }

            var activitiesByID: [UUID: CDActivity] = [:]
            for activitySnapshot in snapshot.activities {
                let activity = CDActivity(context: context)
                activity.id = activitySnapshot.id
                activity.name = activitySnapshot.name
                activity.category = activitySnapshot.category
                activity.icon = activitySnapshot.icon
                activity.primaryMetric = activitySnapshot.primaryMetric
                activity.isPreset = activitySnapshot.isPreset
                activity.instructions = activitySnapshot.instructions
                activity.muscleGroups = activitySnapshot.muscleGroups
                activity.createdAt = activitySnapshot.createdAt

                if let id = activitySnapshot.id {
                    activitiesByID[id] = activity
                }
            }

            for workoutSnapshot in snapshot.workouts {
                let workout = CDWorkout(context: context)
                workout.id = workoutSnapshot.id
                workout.title = workoutSnapshot.title
                workout.date = workoutSnapshot.date
                workout.startedAt = workoutSnapshot.startedAt
                workout.durationMinutes = workoutSnapshot.durationMinutes
                workout.energyLevel = workoutSnapshot.energyLevel
                workout.isCompleted = workoutSnapshot.isCompleted
                workout.notes = workoutSnapshot.notes

                for entrySnapshot in workoutSnapshot.entries {
                    let entry = CDWorkoutEntry(context: context)
                    entry.id = entrySnapshot.id
                    entry.orderIndex = entrySnapshot.orderIndex
                    entry.notes = entrySnapshot.notes
                    entry.workout = workout

                    if let activityID = entrySnapshot.activityID,
                       let activity = activitiesByID[activityID] {
                        entry.activity = activity
                    } else if let activityName = entrySnapshot.activityName,
                              let fallback = activitiesByID.values.first(where: { $0.name == activityName }) {
                        entry.activity = fallback
                    }

                    for setSnapshot in entrySnapshot.sets {
                        let set = CDEntrySet(context: context)
                        set.id = setSnapshot.id
                        set.setNumber = setSnapshot.setNumber
                        set.weightKg = setSnapshot.weightKg
                        set.reps = setSnapshot.reps
                        set.distanceMeters = setSnapshot.distanceMeters
                        set.durationSeconds = setSnapshot.durationSeconds
                        set.laps = setSnapshot.laps
                        set.customValue = setSnapshot.customValue
                        set.customLabel = setSnapshot.customLabel
                        set.notes = setSnapshot.notes
                        set.isPRAttempt = setSnapshot.isPRAttempt
                        set.entry = entry
                    }
                }
            }

            try context.saveIfChanged()
        } catch let error as ImportError {
            context.rollback()
            throw error
        } catch {
            context.rollback()
            throw ImportError.writeFailure(error)
        }
    }
}
