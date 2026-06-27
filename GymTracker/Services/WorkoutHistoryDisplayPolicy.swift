import Foundation

struct WorkoutHistoryMonthGroup: Identifiable {
    let monthStart: Date
    let title: String
    let workouts: [CDWorkout]

    var id: Date { monthStart }
}

struct WorkoutHistoryDisplayPolicy {
    enum ContentState: Equatable {
        case empty
        case noSearchResults
        case list
    }

    static let initialVisibleCount = 100
    static let pageSize = 100

    static func visibleWorkouts(
        from workouts: [CDWorkout],
        searchText: String,
        visibleCount: Int
    ) -> [CDWorkout] {
        let normalizedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !normalizedSearch.isEmpty else {
            return Array(workouts.prefix(max(visibleCount, initialVisibleCount)))
        }

        return workouts.filter {
            $0.title.localizedCaseInsensitiveContains(normalizedSearch) ||
            $0.activitySummary.localizedCaseInsensitiveContains(normalizedSearch)
        }
    }

    static func shouldShowLoadMore(
        totalCount: Int,
        visibleCount: Int,
        searchText: String
    ) -> Bool {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && visibleCount < totalCount
    }

    static func contentState(
        totalWorkoutCount: Int,
        visibleWorkoutCount: Int,
        searchText: String
    ) -> ContentState {
        if totalWorkoutCount == 0 {
            return .empty
        }

        if visibleWorkoutCount == 0 && !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return .noSearchResults
        }

        return .list
    }

    static func nextVisibleCount(
        currentVisibleCount: Int,
        totalCount: Int
    ) -> Int {
        min(currentVisibleCount + pageSize, totalCount)
    }

    static func groupedByMonth(
        workouts: [CDWorkout],
        calendar: Calendar = .current,
        locale: Locale = .current
    ) -> [WorkoutHistoryMonthGroup] {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = locale
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "MMMM yyyy"

        let grouped = Dictionary(grouping: workouts) { workout in
            calendar.date(from: calendar.dateComponents([.year, .month], from: workout.date)) ?? workout.date
        }

        return grouped
            .map { monthStart, workouts in
                WorkoutHistoryMonthGroup(
                    monthStart: monthStart,
                    title: formatter.string(from: monthStart),
                    workouts: workouts.sorted { $0.date > $1.date }
                )
            }
            .sorted { $0.monthStart > $1.monthStart }
    }
}
