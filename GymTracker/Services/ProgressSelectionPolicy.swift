import Foundation

struct ProgressSelectionPolicy {
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
}
