import XCTest
@testable import GymTracker

final class ActivityCategoryTests: XCTestCase {

    // MARK: - ActivityCategory

    func test_allCases_count() {
        XCTAssertEqual(ActivityCategory.allCases.count, 7)
    }

    func test_rawValue_roundTrip() {
        for cat in ActivityCategory.allCases {
            XCTAssertEqual(ActivityCategory(rawValue: cat.rawValue), cat,
                           "Round-trip failed for \(cat.rawValue)")
        }
    }

    func test_defaultMetric_strength() {
        XCTAssertEqual(ActivityCategory.strength.defaultMetric, .weightReps)
    }

    func test_defaultMetric_cardio() {
        XCTAssertEqual(ActivityCategory.cardio.defaultMetric, .distanceTime)
    }

    func test_defaultMetric_swimming() {
        XCTAssertEqual(ActivityCategory.swimming.defaultMetric, .lapsTime)
    }

    func test_defaultMetric_cycling() {
        XCTAssertEqual(ActivityCategory.cycling.defaultMetric, .distanceTime)
    }

    func test_defaultMetric_yoga() {
        XCTAssertEqual(ActivityCategory.yoga.defaultMetric, .duration)
    }

    func test_defaultMetric_hiit() {
        XCTAssertEqual(ActivityCategory.hiit.defaultMetric, .duration)
    }

    func test_defaultMetric_custom() {
        XCTAssertEqual(ActivityCategory.custom.defaultMetric, .custom)
    }

    func test_displayName_nonEmpty_allCases() {
        for cat in ActivityCategory.allCases {
            XCTAssertFalse(cat.displayName.isEmpty, "\(cat.rawValue) has empty displayName")
        }
    }

    func test_icon_nonEmpty_allCases() {
        for cat in ActivityCategory.allCases {
            XCTAssertFalse(cat.icon.isEmpty, "\(cat.rawValue) has empty icon")
        }
    }

    // MARK: - PrimaryMetric

    func test_primaryMetric_allCases_count() {
        XCTAssertEqual(PrimaryMetric.allCases.count, 5)
    }

    func test_primaryMetric_rawValue_roundTrip() {
        for metric in PrimaryMetric.allCases {
            XCTAssertEqual(PrimaryMetric(rawValue: metric.rawValue), metric,
                           "Round-trip failed for \(metric.rawValue)")
        }
    }

    func test_primaryMetric_displayName_nonEmpty() {
        for metric in PrimaryMetric.allCases {
            XCTAssertFalse(metric.displayName.isEmpty, "\(metric.rawValue) has empty displayName")
        }
    }

    func test_primaryMetric_weightReps_hasSecondaryLabel() {
        XCTAssertNotNil(PrimaryMetric.weightReps.secondaryLabel)
    }

    func test_primaryMetric_duration_noSecondaryLabel() {
        XCTAssertNil(PrimaryMetric.duration.secondaryLabel)
    }

    func test_primaryMetric_custom_noSecondaryLabel() {
        XCTAssertNil(PrimaryMetric.custom.secondaryLabel)
    }
}
