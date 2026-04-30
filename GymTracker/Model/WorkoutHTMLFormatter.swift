import Foundation

enum WorkoutHTMLFormatter {

    // MARK: - Single Workout

    static func singleWorkoutHTML(workout: CDWorkout) -> String {
        let dateStr = mediumDate(workout.date)
        let entries = workout.sortedEntries

        var body = """
        <h1>\(escape(workout.title))</h1>
        <p class="meta">
            \(dateStr)
            \(workout.durationMinutes > 0 ? " &bull; \(workout.durationMinutes) min" : "")
            \(workout.energyLevel > 0 ? " &bull; Energy \(workout.energyLevel)/10" : "")
        </p>
        """

        if entries.isEmpty {
            body += "<p class=\"empty\">No exercises logged.</p>"
        } else {
            for entry in entries {
                body += exerciseBlock(entry: entry)
            }
        }

        if let notes = workout.notes, !notes.isEmpty {
            body += "<div class=\"notes\"><strong>Notes</strong><br>\(escape(notes))</div>"
        }

        return wrap(body)
    }

    // MARK: - Summary

    static func summaryHTML(workouts: [CDWorkout], from: Date, to: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        let rangeStr = "\(fmt.string(from: from)) – \(fmt.string(from: to))"
        let totalDuration = workouts.reduce(0) { $0 + Int($1.durationMinutes) }

        var body = """
        <h1>Workout Summary</h1>
        <p class="meta">\(rangeStr)</p>
        <div class="stats">
            <span class="stat"><strong>\(workouts.count)</strong> workouts</span>
            \(totalDuration > 0 ? "<span class=\"stat\"><strong>\(totalDuration)</strong> min total</span>" : "")
        </div>
        """

        if workouts.isEmpty {
            body += "<p class=\"empty\">No workouts in this period.</p>"
        } else {
            let sorted = workouts.sorted { $0.date > $1.date }
            body += "<hr>"
            for workout in sorted {
                body += summaryWorkoutBlock(workout: workout)
            }
        }

        return wrap(body)
    }

    // MARK: - Private helpers

    private static func exerciseBlock(entry: CDWorkoutEntry) -> String {
        let name = entry.activity?.name ?? "Unknown"
        let metric = entry.activity?.metric ?? .weightReps
        let sets = entry.sortedSets

        var html = "<div class=\"exercise\"><h2>\(escape(name))</h2>"

        if sets.isEmpty {
            html += "<p class=\"empty\">No sets logged.</p>"
        } else {
            html += "<table><thead><tr><th>Set</th>\(setHeaders(metric: metric))</tr></thead><tbody>"
            for set in sets {
                html += "<tr><td>\(set.setNumber)</td>\(setCells(set: set, metric: metric))</tr>"
            }
            html += "</tbody></table>"
        }

        html += "</div>"
        return html
    }

    private static func summaryWorkoutBlock(workout: CDWorkout) -> String {
        let dateStr = mediumDate(workout.date)
        let activities = workout.activitySummary
        let html = """
        <div class="summary-workout">
            <strong>\(escape(workout.title))</strong>
            <span class="meta"> &mdash; \(dateStr)\(workout.durationMinutes > 0 ? " &bull; \(workout.durationMinutes) min" : "")</span>
            <br><span class="activities">\(escape(activities))</span>
        </div>
        """
        return html
    }

    private static func setHeaders(metric: PrimaryMetric) -> String {
        switch metric {
        case .weightReps:   return "<th>Weight (\(Units.weightUnit))</th><th>Reps</th>"
        case .distanceTime: return "<th>Distance (\(Units.distanceUnit))</th><th>Time</th>"
        case .lapsTime:     return "<th>Laps</th><th>Time</th>"
        case .duration:     return "<th>Duration</th>"
        case .reps:         return "<th>Reps</th>"
        case .custom:       return "<th>Value</th>"
        }
    }

    private static func setCells(set: CDEntrySet, metric: PrimaryMetric) -> String {
        switch metric {
        case .weightReps:
            let w = set.weightKg > 0 ? String(format: "%.1f", Units.weightValue(fromKg: set.weightKg)) : "—"
            let r = set.reps > 0 ? "\(set.reps)" : "—"
            return "<td>\(w)</td><td>\(r)</td>"
        case .distanceTime:
            let d = set.distanceMeters > 0 ? String(format: "%.2f", Units.distanceValue(fromMeters: set.distanceMeters)) : "—"
            let t = set.durationSeconds > 0 ? set.formattedDuration : "—"
            return "<td>\(d)</td><td>\(t)</td>"
        case .lapsTime:
            let l = set.laps > 0 ? "\(set.laps)" : "—"
            let t = set.durationSeconds > 0 ? set.formattedDuration : "—"
            return "<td>\(l)</td><td>\(t)</td>"
        case .duration:
            let t = set.durationSeconds > 0 ? set.formattedDuration : "—"
            return "<td>\(t)</td>"
        case .reps:
            let r = set.reps > 0 ? "\(set.reps)" : "—"
            return "<td>\(r)</td>"
        case .custom:
            let label = set.customLabel ?? ""
            let v = set.customValue > 0 ? String(format: "%.1f %@", set.customValue, label) : "—"
            return "<td>\(v)</td>"
        }
    }

    private static func mediumDate(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        fmt.timeStyle = .none
        return fmt.string(from: date)
    }

    private static func escape(_ text: String) -> String {
        text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }

    private static func wrap(_ body: String) -> String {
        """
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="UTF-8">
        <style>
          body { font-family: -apple-system, Helvetica Neue, Arial, sans-serif; font-size: 12pt; color: #111; margin: 0; padding: 24px; }
          h1 { font-size: 22pt; margin: 0 0 4px 0; }
          h2 { font-size: 13pt; margin: 0 0 8px 0; color: #222; }
          .meta { color: #666; font-size: 11pt; margin: 0 0 16px 0; }
          .stats { margin: 8px 0 16px 0; }
          .stat { display: inline-block; margin-right: 24px; font-size: 12pt; }
          .exercise { margin-bottom: 24px; page-break-inside: avoid; }
          .summary-workout { margin: 12px 0; page-break-inside: avoid; }
          .activities { color: #555; font-size: 10pt; }
          table { width: 100%; border-collapse: collapse; font-size: 11pt; margin-top: 4px; }
          th { text-align: left; border-bottom: 2px solid #333; padding: 4px 8px; font-size: 10pt; color: #555; font-weight: 600; }
          td { padding: 4px 8px; border-bottom: 1px solid #e0e0e0; }
          tr:last-child td { border-bottom: none; }
          .notes { background: #f5f5f5; padding: 12px 16px; border-left: 3px solid #ccc; font-size: 11pt; margin-top: 16px; }
          .empty { color: #999; font-style: italic; }
          hr { border: none; border-top: 1px solid #ddd; margin: 16px 0; }
        </style>
        </head>
        <body>
        \(body)
        </body>
        </html>
        """
    }
}
