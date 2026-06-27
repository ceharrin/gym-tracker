import XCTest
import CoreData
@testable import GymTracker

final class ActivityFilterPolicyTests: XCTestCase {
    var context: NSManagedObjectContext!

    override func setUp() {
        super.setUp()
        context = CoreDataTestHelper.makeContext()
    }

    private func makeActivity(
        name: String,
        category: ActivityCategory,
        muscleGroups: String? = nil
    ) -> CDActivity {
        let activity = CDActivity(context: context)
        activity.id = UUID()
        activity.name = name
        activity.category = category.rawValue
        activity.icon = category.icon
        activity.primaryMetric = category.defaultMetric.rawValue
        activity.muscleGroups = muscleGroups
        activity.isPreset = true
        return activity
    }

    func test_filteredActivities_matchesNameSearch() {
        let bench = makeActivity(name: "Bench Press", category: .strength)
        let run = makeActivity(name: "Treadmill Run", category: .cardio)

        let filtered = ActivityFilterPolicy.filteredActivities(
            from: [bench, run],
            searchText: "bench",
            selectedCategory: nil
        )

        XCTAssertEqual(filtered.map(\.name), ["Bench Press"])
    }

    func test_filteredActivities_matchesMuscleGroupSearch() {
        let row = makeActivity(name: "Cable Row", category: .strength, muscleGroups: "Back")
        let run = makeActivity(name: "Treadmill Run", category: .cardio, muscleGroups: "Legs")

        let filtered = ActivityFilterPolicy.filteredActivities(
            from: [row, run],
            searchText: "back",
            selectedCategory: nil
        )

        XCTAssertEqual(filtered.map(\.name), ["Cable Row"])
    }

    func test_filteredActivities_appliesSelectedCategory() {
        let squat = makeActivity(name: "Squat", category: .strength)
        let swim = makeActivity(name: "Pool Laps", category: .swimming)

        let filtered = ActivityFilterPolicy.filteredActivities(
            from: [squat, swim],
            searchText: "",
            selectedCategory: .swimming
        )

        XCTAssertEqual(filtered.map(\.name), ["Pool Laps"])
    }

    func test_filteredActivities_treatsWhitespaceSearchAsEmpty() {
        let squat = makeActivity(name: "Squat", category: .strength)

        let filtered = ActivityFilterPolicy.filteredActivities(
            from: [squat],
            searchText: "   ",
            selectedCategory: nil
        )

        XCTAssertEqual(filtered.map(\.name), ["Squat"])
    }

    func test_contentState_returnsEmptyWhenNoActivitiesExist() {
        XCTAssertEqual(
            ActivityFilterPolicy.contentState(totalActivityCount: 0, filteredActivityCount: 0),
            .empty
        )
    }

    func test_contentState_returnsNoResultsWhenActivitiesExistButFilterHasNoMatches() {
        XCTAssertEqual(
            ActivityFilterPolicy.contentState(totalActivityCount: 3, filteredActivityCount: 0),
            .noResults
        )
    }

    func test_contentState_returnsListWhenFilteredActivitiesExist() {
        XCTAssertEqual(
            ActivityFilterPolicy.contentState(totalActivityCount: 3, filteredActivityCount: 1),
            .list
        )
    }
}
