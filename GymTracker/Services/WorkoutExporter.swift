import Foundation

/// Produces shareable file artifacts from workout data.
/// Keeping file creation here (not in views) makes the logic independently
/// testable and keeps views free of I/O concerns.
enum WorkoutExporter {

    enum ExportError: LocalizedError {
        case writeFailure(Error)

        var errorDescription: String? {
            switch self {
            case .writeFailure(let underlying):
                return "Could not create the export file: \(underlying.localizedDescription)"
            }
        }
    }

    /// Writes the workout as an HTML file to the temporary directory and returns its URL.
    /// The filename is derived from the workout title so share sheets show a meaningful name.
    /// Throws `ExportError.writeFailure` if the file cannot be written.
    static func exportHTML(for workout: CDWorkout, directory: URL? = nil) throws -> URL {
        let html = WorkoutHTMLFormatter.singleWorkoutHTML(workout: workout)
        let filename = sanitizedFilename(from: workout.title)
        let dir = directory ?? FileManager.default.temporaryDirectory
        let url = dir.appendingPathComponent(filename)
        do {
            try html.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            throw ExportError.writeFailure(error)
        }
        return url
    }

    // MARK: Private

    /// Converts a workout title to a safe filename with a `.html` extension.
    /// Strips filesystem-reserved characters; falls back to a default name if
    /// the result would be empty.
    static func sanitizedFilename(from title: String) -> String {
        let reservedCharacters = CharacterSet(charactersIn: "/\\:*?\"<>|")
        let safe = title
            .components(separatedBy: reservedCharacters)
            .joined(separator: "-")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return (safe.isEmpty ? "GymTracker-Workout" : safe) + ".html"
    }
}
