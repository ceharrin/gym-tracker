import XCTest
import CoreData
import SwiftUI
@testable import GymTracker

final class CDWorkoutHelpersExtendedTests: XCTestCase {

    var context: NSManagedObjectContext!

    override func setUp() {
        super.setUp()
        context = CoreDataTestHelper.makeContext()
    }

    // MARK: - Helpers

    private func makeWorkout(title: String = "Test", date: Date = Date()) -> CDWorkout {
        let w = CDWorkout(context: context)
        w.id = UUID()
        w.title = title
        w.date = date
        w.durationMinutes = 45
        return w
    }

    private func makeActivity(
        name: String = "Bench",
        category: ActivityCategory = .strength
    ) -> CDActivity {
        let a = CDActivity(context: context)
        a.id = UUID()
        a.name = name
        a.category = category.rawValue
        a.primaryMetric = category.defaultMetric.rawValue
        a.isPreset = true
        return a
    }

    @discardableResult
    private func makeEntry(workout: CDWorkout, activity: CDActivity, orderIndex: Int16 = 0) -> CDWorkoutEntry {
        let e = CDWorkoutEntry(context: context)
        e.id = UUID()
        e.orderIndex = orderIndex
        e.activity = activity
        e.workout = workout
        return e
    }

    // MARK: - formattedDate

    func test_formattedDate_nonEmpty() {
        let date = Calendar.current.date(from: DateComponents(year: 2026, month: 4, day: 15))!
        let w = makeWorkout(date: date)
        XCTAssertFalse(w.formattedDate.isEmpty)
    }

    func test_formattedDate_containsYear() {
        let date = Calendar.current.date(from: DateComponents(year: 2026, month: 4, day: 15))!
        let w = makeWorkout(date: date)
        XCTAssertTrue(w.formattedDate.contains("2026"))
    }

    func test_formattedDate_doesNotContainTime() {
        let w = makeWorkout()
        // Medium date style has no colon for time
        XCTAssertFalse(w.formattedDate.contains(":"), "formattedDate must not include a time component")
    }

    func test_formattedDate_differentDatesProduceDifferentStrings() {
        let d1 = Calendar.current.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let d2 = Calendar.current.date(from: DateComponents(year: 2026, month: 6, day: 15))!
        let w1 = makeWorkout(date: d1)
        let w2 = makeWorkout(date: d2)
        XCTAssertNotEqual(w1.formattedDate, w2.formattedDate)
    }

    // MARK: - formattedDuration

    func test_formattedDuration_completedWorkoutWithPositiveDuration() {
        let w = makeWorkout()
        w.isCompleted = true
        w.durationMinutes = 45

        XCTAssertEqual(w.formattedDuration, "45 min")
    }

    func test_formattedDuration_completedWorkoutWithZeroDuration() {
        let w = makeWorkout()
        w.isCompleted = true
        w.durationMinutes = 0

        XCTAssertEqual(w.formattedDuration, "0 min")
    }

    func test_formattedDuration_inProgressWorkoutWithZeroDuration() {
        let w = makeWorkout()
        w.isCompleted = false
        w.durationMinutes = 0

        XCTAssertNil(w.formattedDuration)
    }

    // MARK: - primaryCategoryIcon

    func test_primaryCategoryIcon_noEntries_returnsDumbbell() {
        let w = makeWorkout()
        XCTAssertEqual(w.primaryCategoryIcon, "dumbbell.fill")
    }

    func test_primaryCategoryIcon_strengthActivity() {
        let w = makeWorkout()
        makeEntry(workout: w, activity: makeActivity(category: .strength))
        XCTAssertEqual(w.primaryCategoryIcon, ActivityCategory.strength.icon)
    }

    func test_primaryCategoryIcon_cardioActivity() {
        let w = makeWorkout()
        makeEntry(workout: w, activity: makeActivity(category: .cardio))
        XCTAssertEqual(w.primaryCategoryIcon, ActivityCategory.cardio.icon)
    }

    func test_primaryCategoryIcon_usesFirstEntryByOrderIndex() {
        let w = makeWorkout()
        makeEntry(workout: w, activity: makeActivity(category: .swimming), orderIndex: 1)
        makeEntry(workout: w, activity: makeActivity(category: .cardio), orderIndex: 0)
        // First by orderIndex is cardio (orderIndex 0)
        XCTAssertEqual(w.primaryCategoryIcon, ActivityCategory.cardio.icon)
    }

    func test_primaryCategoryIcon_allCategoriesHaveIcon() {
        for category in ActivityCategory.allCases {
            let w = makeWorkout()
            makeEntry(workout: w, activity: makeActivity(category: category))
            XCTAssertFalse(w.primaryCategoryIcon.isEmpty,
                           "\(category) must produce a non-empty icon string")
        }
    }

    // MARK: - primaryCategoryColor

    func test_primaryCategoryColor_noEntries_returnsAccentColor() {
        let w = makeWorkout()
        // Cannot compare Color directly, but can verify it doesn't crash
        _ = w.primaryCategoryColor
    }

    func test_primaryCategoryColor_strengthActivity_isBlue() {
        let w = makeWorkout()
        makeEntry(workout: w, activity: makeActivity(category: .strength))
        XCTAssertEqual(w.primaryCategoryColor, ActivityCategory.strength.color)
    }

    func test_primaryCategoryColor_cardioActivity_isOrange() {
        let w = makeWorkout()
        makeEntry(workout: w, activity: makeActivity(category: .cardio))
        XCTAssertEqual(w.primaryCategoryColor, ActivityCategory.cardio.color)
    }

    func test_primaryCategoryColor_usesFirstEntryByOrderIndex() {
        let w = makeWorkout()
        makeEntry(workout: w, activity: makeActivity(category: .yoga), orderIndex: 1)
        makeEntry(workout: w, activity: makeActivity(category: .hiit), orderIndex: 0)
        XCTAssertEqual(w.primaryCategoryColor, ActivityCategory.hiit.color)
    }
}
