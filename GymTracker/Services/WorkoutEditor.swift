import Foundation
import CoreData

// MARK: - In-memory session models

struct LiveSet: Identifiable {
    var id = UUID()
    var reps: String = ""
    var weightKg: String = ""
    var durationMinutes: String = ""
    var durationSeconds: String = ""
    var distanceKm: String = ""
    var laps: String = ""
    var customValue: String = ""
    var customLabel: String = ""
    var notes: String = ""
    var isPRAttempt: Bool = false

    static func copying(_ other: LiveSet) -> LiveSet {
        var s = LiveSet()
        s.weightKg = other.weightKg
        s.reps = other.reps
        s.distanceKm = other.distanceKm
        s.durationMinutes = other.durationMinutes
        s.durationSeconds = other.durationSeconds
        s.laps = other.laps
        s.customValue = other.customValue
        s.customLabel = other.customLabel
        return s
    }
}

struct LiveEntry: Identifiable {
    var id = UUID()
    var activity: CDActivity
    var sets: [LiveSet] = [LiveSet()]
    var notes: String = ""
}

// MARK: - WorkoutEditor

/// Owns the load/save/PR-detection logic for creating and editing workouts.
/// Free of SwiftUI dependencies so it can be tested without a view host.
enum WorkoutEditor {
    enum SaveIntent {
        case saveProgress
        case complete
    }

    struct WorkoutData {
        var title: String
        var date: Date
        var energyLevel: Int
        var notes: String
        var entries: [LiveEntry]

        init(
            title: String,
            date: Date,
            durationMinutes: String = "",
            energyLevel: Int,
            notes: String,
            entries: [LiveEntry]
        ) {
            self.title = title
            self.date = date
            self.durationMinutes = durationMinutes
            self.energyLevel = energyLevel
            self.notes = notes
            self.entries = entries
        }

        var durationMinutes: String
    }

    struct SaveResult {
        let savedWorkout: CDWorkout
        let newPRNames: [String]
    }

    static func initialData(existingWorkout: CDWorkout?, isDuplicate: Bool, now: Date) -> WorkoutData {
        guard let workout = existingWorkout else {
            return WorkoutData(
                title: defaultWorkoutTitle(on: now),
                date: now,
                durationMinutes: "",
                energyLevel: 7,
                notes: "",
                entries: []
            )
        }

        var data = load(from: workout)
        if isDuplicate {
            data.date = now
            data.durationMinutes = ""
        }
        return data
    }

    // MARK: Load

    /// Maps a persisted CDWorkout into an editable WorkoutData value.
    static func load(from workout: CDWorkout) -> WorkoutData {
        let liveSetsFor: (CDWorkoutEntry) -> [LiveSet] = { entry in
            let mapped: [LiveSet] = entry.sortedSets.map { set in
                var s = LiveSet()
                s.weightKg   = set.weightKg > 0      ? String(format: "%.1f", Units.weightValue(fromKg: set.weightKg)) : ""
                s.reps       = set.reps > 0           ? "\(set.reps)"                                                   : ""
                s.distanceKm = set.distanceMeters > 0 ? String(format: "%.2f", Units.distanceValue(fromMeters: set.distanceMeters)) : ""
                if set.durationSeconds > 0 {
                    s.durationMinutes = "\(set.durationSeconds / 60)"
                    s.durationSeconds = String(format: "%02d", set.durationSeconds % 60)
                }
                s.laps        = set.laps > 0        ? "\(set.laps)"                            : ""
                s.customValue = set.customValue > 0 ? String(format: "%.1f", set.customValue) : ""
                s.customLabel = set.customLabel ?? ""
                s.notes       = set.notes ?? ""
                return s
            }
            return mapped.isEmpty ? [LiveSet()] : mapped
        }

        let entries = workout.sortedEntries.compactMap { entry -> LiveEntry? in
            guard let activity = entry.activity else { return nil }
            return LiveEntry(activity: activity, sets: liveSetsFor(entry), notes: entry.notes ?? "")
        }

        return WorkoutData(
            title: workout.title,
            date: workout.date,
            durationMinutes: workout.durationMinutes > 0 ? "\(workout.durationMinutes)" : "",
            energyLevel: Int(workout.energyLevel),
            notes: workout.notes ?? "",
            entries: entries
        )
    }

    // MARK: Save

    /// Persists WorkoutData to Core Data and returns the saved workout plus any new PR names.
    /// Throws if the context save fails — the caller is responsible for rolling back on error.
    @discardableResult
    static func save(
        data: WorkoutData,
        context: NSManagedObjectContext,
        existingWorkout: CDWorkout?,
        isDuplicate: Bool,
        startTime: Date,
        intent: SaveIntent = .complete,
        completedAt: Date = Date()
    ) throws -> SaveResult {
        let newPRNames = intent == .complete
            ? detectPRs(entries: data.entries, context: context, excludingWorkout: existingWorkout)
            : []

        let workout: CDWorkout
        if let existing = existingWorkout, !isDuplicate {
            workout = existing
            for entry in existing.sortedEntries {
                entry.sortedSets.forEach { context.delete($0) }
                context.delete(entry)
            }
        } else {
            workout = CDWorkout(context: context)
            workout.id = UUID()
        }

        workout.date = data.date
        workout.startedAt = resolvedStartTime(existingWorkout: existingWorkout, isDuplicate: isDuplicate, fallback: startTime)
        workout.title = data.title.isEmpty ? "Workout" : data.title
        workout.durationMinutes = resolvedDurationMinutes(
            existingWorkout: existingWorkout,
            isDuplicate: isDuplicate,
            startTime: workout.sessionStartDate,
            completedAt: completedAt,
            intent: intent
        )
        workout.isCompleted = (intent == .complete)
        workout.energyLevel = Int16(data.energyLevel)
        workout.notes = data.notes.isEmpty ? nil : data.notes

        for (idx, liveEntry) in data.entries.enumerated() {
            let entry = CDWorkoutEntry(context: context)
            entry.id = UUID()
            entry.orderIndex = Int16(idx)
            entry.activity = liveEntry.activity
            entry.notes = liveEntry.notes.isEmpty ? nil : liveEntry.notes
            entry.workout = workout

            for (setIdx, liveSet) in liveEntry.sets.enumerated() {
                let set = CDEntrySet(context: context)
                set.id = UUID()
                set.setNumber = Int16(setIdx + 1)
                set.weightKg = Units.kgFromInput(Double(liveSet.weightKg) ?? 0)
                set.reps = Int32(liveSet.reps) ?? 0
                set.distanceMeters = Units.metersFromInput(Double(liveSet.distanceKm) ?? 0)
                set.durationSeconds = durationToSeconds(liveSet)
                set.laps = Int32(liveSet.laps) ?? 0
                set.customValue = Double(liveSet.customValue) ?? 0
                set.customLabel = liveSet.customLabel.isEmpty ? nil : liveSet.customLabel
                set.notes = liveSet.notes.isEmpty ? nil : liveSet.notes
                set.entry = entry
            }
        }

        try context.save()
        return SaveResult(savedWorkout: workout, newPRNames: newPRNames)
    }

    // MARK: Private helpers

    private static func detectPRs(
        entries: [LiveEntry],
        context: NSManagedObjectContext,
        excludingWorkout: CDWorkout?
    ) -> [String] {
        var names: [String] = []
        for liveEntry in entries {
            let prSets = liveEntry.sets.filter(\.isPRAttempt)
            guard !prSets.isEmpty else { continue }
            let history = historicalSets(for: liveEntry.activity, excludingWorkout: excludingWorkout, context: context)
            let hasNewPR = prSets.contains {
                isNewPersonalRecord(liveSet: $0, metric: liveEntry.activity.metric, against: history)
            }
            if hasNewPR, !names.contains(liveEntry.activity.name) {
                names.append(liveEntry.activity.name)
            }
        }
        return names
    }

    private static func historicalSets(
        for activity: CDActivity,
        excludingWorkout: CDWorkout?,
        context: NSManagedObjectContext
    ) -> [CDEntrySet] {
        let request = CDWorkoutEntry.fetchRequest()
        request.predicate = NSPredicate(format: "activity == %@", activity)
        let entries = (try? context.fetch(request)) ?? []
        return entries
            .filter { excludingWorkout == nil || $0.workout != excludingWorkout }
            .flatMap(\.sortedSets)
    }

    private static func durationToSeconds(_ set: LiveSet) -> Int32 {
        let m = Int32(set.durationMinutes) ?? 0
        let s = Int32(set.durationSeconds) ?? 0
        return m * 60 + s
    }

    private static func resolvedStartTime(existingWorkout: CDWorkout?, isDuplicate: Bool, fallback: Date) -> Date {
        guard let existingWorkout, !isDuplicate else { return fallback }
        return existingWorkout.startedAt ?? fallback
    }

    private static func resolvedDurationMinutes(
        existingWorkout: CDWorkout?,
        isDuplicate: Bool,
        startTime: Date,
        completedAt: Date,
        intent: SaveIntent
    ) -> Int32 {
        if let existingWorkout, !isDuplicate, existingWorkout.isCompleted {
            return existingWorkout.durationMinutes
        }

        let elapsedMinutes = max(0, Int32(completedAt.timeIntervalSince(startTime) / 60))
        switch intent {
        case .saveProgress, .complete:
            return elapsedMinutes
        }
    }

    private static func defaultWorkoutTitle(on date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return "\(formatter.string(from: date)) Workout"
    }
}
