import Foundation

struct ProgressSelectionPolicy {
    enum SectionState: Equatable {
        case noData
        case needsSelection
        case ready
    }

    static func updatedMetricSelection(
        current: Set<WorkoutTotalMetric>,
        available: [WorkoutTotalMetric]
    ) -> Set<WorkoutTotalMetric> {
        let availableSet = Set(available)
        let retained = current.intersection(availableSet)

        if !retained.isEmpty {
            return retained
        }

        return available.first.map { [$0] } ?? []
    }

    static func updatedActivitySelection<ID: Hashable>(
        currentIDs: Set<ID>,
        availableIDs: [ID]
    ) -> Set<ID> {
        let availableSet = Set(availableIDs)
        let retained = currentIDs.intersection(availableSet)

        if !retained.isEmpty {
            return retained
        }

        return availableIDs.first.map { [$0] } ?? []
    }

    static func sectionState(availableItemCount: Int, selectedItemCount: Int) -> SectionState {
        guard availableItemCount > 0 else { return .noData }
        return selectedItemCount > 0 ? .ready : .needsSelection
    }

    static func activityMatchesFilters(
        name: String,
        category: ActivityCategory,
        searchText: String,
        selectedCategory: ActivityCategory?
    ) -> Bool {
        let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let matchesSearch = trimmedSearch.isEmpty || name.localizedCaseInsensitiveContains(trimmedSearch)
        let matchesCategory = selectedCategory.map { $0 == category } ?? true
        return matchesSearch && matchesCategory
    }
}
