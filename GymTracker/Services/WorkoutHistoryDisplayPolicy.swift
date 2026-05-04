import Foundation

struct WorkoutHistoryDisplayPolicy {
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

    static func nextVisibleCount(
        currentVisibleCount: Int,
        totalCount: Int
    ) -> Int {
        min(currentVisibleCount + pageSize, totalCount)
    }
}
