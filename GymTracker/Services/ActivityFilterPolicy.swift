import Foundation

struct ActivityFilterPolicy {
    enum ContentState: Equatable {
        case empty
        case noResults
        case list
    }

    static func filteredActivities(
        from activities: [CDActivity],
        searchText: String,
        selectedCategory: ActivityCategory?
    ) -> [CDActivity] {
        let normalizedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        return activities.filter { activity in
            let matchesCategory = selectedCategory == nil || activity.category == selectedCategory?.rawValue
            let matchesSearch = normalizedSearch.isEmpty ||
                activity.name.localizedCaseInsensitiveContains(normalizedSearch) ||
                (activity.muscleGroups?.localizedCaseInsensitiveContains(normalizedSearch) ?? false) ||
                (activity.instructions?.localizedCaseInsensitiveContains(normalizedSearch) ?? false)
            return matchesCategory && matchesSearch
        }
    }

    static func contentState(
        totalActivityCount: Int,
        filteredActivityCount: Int
    ) -> ContentState {
        if totalActivityCount == 0 {
            return .empty
        }

        if filteredActivityCount == 0 {
            return .noResults
        }

        return .list
    }
}
