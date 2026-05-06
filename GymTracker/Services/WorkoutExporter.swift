import Foundation
import UIKit

/// Produces shareable file artifacts from workout data.
/// Keeping file creation here (not in views) makes the logic independently
/// testable and keeps views free of I/O concerns.
enum WorkoutExporter {
    static let exportDirectoryName = "ShareExports"

    struct ExportDateRange: Equatable {
        let startDate: Date
        let endDate: Date

        func normalized(calendar: Calendar = .current) -> ExportDateRange {
            let lowerBound = min(startDate, endDate)
            let upperBound = max(startDate, endDate)
            return ExportDateRange(startDate: lowerBound, endDate: upperBound)
        }

        func contains(_ date: Date, calendar: Calendar = .current) -> Bool {
            let normalized = normalized(calendar: calendar)
            let lowerBound = calendar.startOfDay(for: normalized.startDate)
            guard let upperExclusive = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: normalized.endDate)) else {
                return date >= lowerBound
            }
            return date >= lowerBound && date < upperExclusive
        }
    }

    enum ExportDateRangePreset: String, CaseIterable, Identifiable {
        case allTime
        case last7Days
        case last30Days
        case thisMonth

        var id: String { rawValue }

        var title: String {
            switch self {
            case .allTime: return "All Time"
            case .last7Days: return "Last 7 Days"
            case .last30Days: return "Last 30 Days"
            case .thisMonth: return "This Month"
            }
        }

        func resolve(within bounds: ClosedRange<Date>, now: Date = Date(), calendar: Calendar = .current) -> ExportDateRange {
            let boundedNow = min(max(now, bounds.lowerBound), bounds.upperBound)

            switch self {
            case .allTime:
                return ExportDateRange(startDate: bounds.lowerBound, endDate: bounds.upperBound)
            case .last7Days:
                let start = calendar.date(byAdding: .day, value: -6, to: boundedNow) ?? boundedNow
                return ExportDateRange(startDate: max(start, bounds.lowerBound), endDate: boundedNow)
            case .last30Days:
                let start = calendar.date(byAdding: .day, value: -29, to: boundedNow) ?? boundedNow
                return ExportDateRange(startDate: max(start, bounds.lowerBound), endDate: boundedNow)
            case .thisMonth:
                let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: boundedNow)) ?? boundedNow
                return ExportDateRange(startDate: max(monthStart, bounds.lowerBound), endDate: boundedNow)
            }
        }
    }

    enum ExportError: LocalizedError {
        case renderFailure
        case directoryCreationFailure(Error)
        case writeFailure(Error)

        var errorDescription: String? {
            switch self {
            case .renderFailure:
                return "Could not create a shareable PDF for this workout."
            case .directoryCreationFailure(let underlying):
                return "Could not prepare the export folder: \(underlying.localizedDescription)"
            case .writeFailure(let underlying):
                return "Could not create the export file: \(underlying.localizedDescription)"
            }
        }
    }

    /// Renders the workout to a PDF file in the temporary directory and returns its URL.
    /// The filename is derived from the workout title so share sheets show a meaningful name.
    /// Throws `ExportError.renderFailure` if PDF rendering fails.
    /// Throws `ExportError.writeFailure` if the resulting file cannot be moved into place.
    @MainActor
    static func exportHTML(for workout: CDWorkout, directory: URL? = nil) throws -> URL {
        let html = WorkoutHTMLFormatter.singleWorkoutHTML(workout: workout)
        let filename = uniqueFilename(from: workout.title)
        let dir = try directory ?? defaultExportDirectory()
        guard let data = PrintCoordinator.htmlToPDFData(html) else {
            throw ExportError.renderFailure
        }
        let destinationURL = dir.appendingPathComponent(filename)
        do {
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            try data.write(to: destinationURL, options: .atomic)
            return destinationURL
        } catch {
            throw ExportError.writeFailure(error)
        }
    }

    // MARK: CSV export

    /// Produces a CSV file containing every set from every supplied workout and returns its URL.
    static func exportCSV(for workouts: [CDWorkout], in range: ExportDateRange? = nil, directory: URL? = nil) throws -> URL {
        let dir = try directory ?? defaultExportDirectory()
        let filename = csvFilename(for: range)
        let destinationURL = dir.appendingPathComponent(filename)

        let csv = buildCSV(for: workouts, in: range)
        do {
            try csv.write(to: destinationURL, atomically: true, encoding: .utf8)
            return destinationURL
        } catch {
            throw ExportError.writeFailure(error)
        }
    }

    static func buildCSV(for workouts: [CDWorkout], in range: ExportDateRange? = nil) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none

        var rows: [String] = [
            "Date,Workout,Exercise,Category,Set,\(Units.weightUnit),Reps,\(Units.distanceUnit),Duration,Laps,Custom Value,Custom Label,PR Attempt"
        ]

        let sorted = self.workouts(workouts, in: range).sorted { $0.date > $1.date }
        for workout in sorted {
            let date = csvEscape(dateFormatter.string(from: workout.date))
            let workoutTitle = csvEscape(workout.title)
            for entry in workout.sortedEntries {
                guard let activity = entry.activity else { continue }
                let exercise = csvEscape(activity.name)
                let category = csvEscape(activity.activityCategory.rawValue)
                for set in entry.sortedSets {
                    let weight = set.weightKg > 0 ? String(format: "%.2f", Units.weightValue(fromKg: set.weightKg)) : ""
                    let reps   = set.reps > 0 ? "\(set.reps)" : ""
                    let dist   = set.distanceMeters > 0 ? String(format: "%.2f", Units.distanceValue(fromMeters: set.distanceMeters)) : ""
                    let dur    = set.durationSeconds > 0 ? set.formattedDuration : ""
                    let laps   = set.laps > 0 ? "\(set.laps)" : ""
                    let cv     = set.customValue > 0 ? String(format: "%.2f", set.customValue) : ""
                    let cl     = csvEscape(set.customLabel ?? "")
                    let pr     = set.isPRAttempt ? "true" : ""
                    rows.append("\(date),\(workoutTitle),\(exercise),\(category),\(set.setNumber),\(weight),\(reps),\(dist),\(dur),\(laps),\(cv),\(cl),\(pr)")
                }
            }
        }
        return rows.joined(separator: "\n")
    }

    static func workouts(_ workouts: [CDWorkout], in range: ExportDateRange?, calendar: Calendar = .current) -> [CDWorkout] {
        guard let range else { return workouts }
        return workouts.filter { range.contains($0.date, calendar: calendar) }
    }

    static func csvFilename(
        for range: ExportDateRange?,
        exportedAt: Date = Date(),
        token: String = String(UUID().uuidString.prefix(6))
    ) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"

        let baseName: String
        if let range {
            let normalized = range.normalized(calendar: formatter.calendar)
            let start = formatter.string(from: normalized.startDate)
            let end = formatter.string(from: normalized.endDate)
            baseName = "GymTracker Workouts \(start) to \(end)"
        } else {
            baseName = "GymTracker Workouts \(formatter.string(from: exportedAt))"
        }

        return "\(baseName) \(token.uppercased()).csv"
    }

    private static func csvEscape(_ value: String) -> String {
        let needsQuoting = value.contains(",") || value.contains("\"") || value.contains("\n")
        guard needsQuoting else { return value }
        return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
    }

    // MARK: Private

    /// Converts a workout title to a safe filename with a `.pdf` extension.
    /// Strips filesystem-reserved characters; falls back to a default name if
    /// the result would be empty.
    static func sanitizedFilename(from title: String) -> String {
        sanitizedFilenameStem(from: title) + ".pdf"
    }

    static func uniqueFilename(from title: String) -> String {
        "\(sanitizedFilenameStem(from: title))-\(UUID().uuidString).pdf"
    }

    static func defaultExportDirectory(fileManager: FileManager = .default) throws -> URL {
        do {
            let base = try fileManager.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            let exports = base.appendingPathComponent(exportDirectoryName, isDirectory: true)
            try fileManager.createDirectory(at: exports, withIntermediateDirectories: true)
            return exports
        } catch {
            throw ExportError.directoryCreationFailure(error)
        }
    }

    private static func sanitizedFilenameStem(from title: String) -> String {
        let reservedCharacters = CharacterSet(charactersIn: "/\\:*?\"<>|")
        let safe = title
            .components(separatedBy: reservedCharacters)
            .joined(separator: "-")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return safe.isEmpty ? "GymTracker-Workout" : safe
    }
}
