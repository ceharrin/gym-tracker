import XCTest
@testable import GymTracker

final class ProgressSelectionPolicyTests: XCTestCase {
    func test_updatedMetricSelection_keepsExistingAvailableSelection() {
        let selection: Set<WorkoutTotalMetric> = [.duration]

        let updated = ProgressSelectionPolicy.updatedMetricSelection(
            current: selection,
            available: [.duration, .reps]
        )

        XCTAssertEqual(updated, [.duration])
    }

    func test_updatedMetricSelection_removesUnavailableSelections() {
        let selection: Set<WorkoutTotalMetric> = [.duration, .laps]

        let updated = ProgressSelectionPolicy.updatedMetricSelection(
            current: selection,
            available: [.reps, .duration]
        )

        XCTAssertEqual(updated, [.duration])
    }

    func test_updatedMetricSelection_selectsFirstAvailableWhenSelectionIsEmpty() {
        let updated = ProgressSelectionPolicy.updatedMetricSelection(
            current: [],
            available: [.reps, .duration]
        )

        XCTAssertEqual(updated, [.reps])
    }

    func test_updatedMetricSelection_returnsEmptyWhenNoMetricsAreAvailable() {
        let updated = ProgressSelectionPolicy.updatedMetricSelection(
            current: [.duration],
            available: []
        )

        XCTAssertTrue(updated.isEmpty)
    }

    func test_updatedActivitySelection_keepsExistingAvailableSelection() {
        let updated = ProgressSelectionPolicy.updatedActivitySelection(
            currentIDs: ["bench"],
            availableIDs: ["bench", "row"]
        )

        XCTAssertEqual(updated, ["bench"])
    }

    func test_updatedActivitySelection_removesUnavailableSelections() {
        let updated = ProgressSelectionPolicy.updatedActivitySelection(
            currentIDs: ["bench", "run"],
            availableIDs: ["bench", "row"]
        )

        XCTAssertEqual(updated, ["bench"])
    }

    func test_updatedActivitySelection_selectsFirstAvailableWhenSelectionIsEmpty() {
        let updated = ProgressSelectionPolicy.updatedActivitySelection(
            currentIDs: [],
            availableIDs: ["bench", "row"]
        )

        XCTAssertEqual(updated, ["bench"])
    }

    func test_updatedActivitySelection_returnsEmptyWhenNoActivitiesAreAvailable() {
        let updated = ProgressSelectionPolicy.updatedActivitySelection(
            currentIDs: ["bench"],
            availableIDs: []
        )

        XCTAssertTrue(updated.isEmpty)
    }

    func test_sectionState_returnsNoDataWhenNothingIsAvailable() {
        let state = ProgressSelectionPolicy.sectionState(
            availableItemCount: 0,
            selectedItemCount: 0
        )

        XCTAssertEqual(state, .noData)
    }

    func test_sectionState_returnsNeedsSelectionWhenDataIsAvailableButNothingIsSelected() {
        let state = ProgressSelectionPolicy.sectionState(
            availableItemCount: 2,
            selectedItemCount: 0
        )

        XCTAssertEqual(state, .needsSelection)
    }

    func test_sectionState_returnsReadyWhenDataIsAvailableAndSelected() {
        let state = ProgressSelectionPolicy.sectionState(
            availableItemCount: 2,
            selectedItemCount: 1
        )

        XCTAssertEqual(state, .ready)
    }

    func test_sectionState_treatsNegativeCountsAsNoData() {
        let state = ProgressSelectionPolicy.sectionState(
            availableItemCount: -1,
            selectedItemCount: -1
        )

        XCTAssertEqual(state, .noData)
    }
}
