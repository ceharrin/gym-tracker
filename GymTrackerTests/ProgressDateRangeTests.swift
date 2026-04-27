import XCTest
@testable import GymTracker

final class ProgressDateRangeTests: XCTestCase {

    // MARK: - days

    func test_days_oneMonth_is30() {
        XCTAssertEqual(ProgressDateRange.oneMonth.days, 30)
    }

    func test_days_threeMonths_is90() {
        XCTAssertEqual(ProgressDateRange.threeMonths.days, 90)
    }

    func test_days_sixMonths_is180() {
        XCTAssertEqual(ProgressDateRange.sixMonths.days, 180)
    }

    func test_days_oneYear_is365() {
        XCTAssertEqual(ProgressDateRange.oneYear.days, 365)
    }

    func test_days_allTime_isNil() {
        XCTAssertNil(ProgressDateRange.allTime.days)
    }

    // MARK: - displayLabel

    func test_displayLabel_oneMonth() {
        XCTAssertEqual(ProgressDateRange.oneMonth.displayLabel, "1M")
    }

    func test_displayLabel_threeMonths() {
        XCTAssertEqual(ProgressDateRange.threeMonths.displayLabel, "3M")
    }

    func test_displayLabel_sixMonths() {
        XCTAssertEqual(ProgressDateRange.sixMonths.displayLabel, "6M")
    }

    func test_displayLabel_oneYear() {
        XCTAssertEqual(ProgressDateRange.oneYear.displayLabel, "1Y")
    }

    func test_displayLabel_allTime() {
        XCTAssertEqual(ProgressDateRange.allTime.displayLabel, "All")
    }

    func test_displayLabel_matchesRawValue() {
        for range in ProgressDateRange.allCases {
            XCTAssertEqual(range.displayLabel, range.rawValue)
        }
    }

    // MARK: - cutoffDate

    func test_cutoffDate_allTime_isNil() {
        XCTAssertNil(ProgressDateRange.allTime.cutoffDate)
    }

    func test_cutoffDate_oneMonth_isApproximately30DaysAgo() {
        let cutoff = ProgressDateRange.oneMonth.cutoffDate!
        let expected = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        XCTAssertEqual(cutoff.timeIntervalSince(expected), 0, accuracy: 5,
                       "oneMonth cutoff must be approximately 30 days ago")
    }

    func test_cutoffDate_threeMonths_isApproximately90DaysAgo() {
        let cutoff = ProgressDateRange.threeMonths.cutoffDate!
        let expected = Calendar.current.date(byAdding: .day, value: -90, to: Date())!
        XCTAssertEqual(cutoff.timeIntervalSince(expected), 0, accuracy: 5)
    }

    func test_cutoffDate_sixMonths_isApproximately180DaysAgo() {
        let cutoff = ProgressDateRange.sixMonths.cutoffDate!
        let expected = Calendar.current.date(byAdding: .day, value: -180, to: Date())!
        XCTAssertEqual(cutoff.timeIntervalSince(expected), 0, accuracy: 5)
    }

    func test_cutoffDate_oneYear_isApproximately365DaysAgo() {
        let cutoff = ProgressDateRange.oneYear.cutoffDate!
        let expected = Calendar.current.date(byAdding: .day, value: -365, to: Date())!
        XCTAssertEqual(cutoff.timeIntervalSince(expected), 0, accuracy: 5)
    }

    func test_cutoffDate_isInThePast() {
        for range in ProgressDateRange.allCases where range.days != nil {
            let cutoff = range.cutoffDate!
            XCTAssertLessThan(cutoff, Date(), "\(range) cutoff must be in the past")
        }
    }

    // MARK: - allCases

    func test_allCases_count() {
        XCTAssertEqual(ProgressDateRange.allCases.count, 5)
    }

    func test_rawValue_roundTrip() {
        for range in ProgressDateRange.allCases {
            XCTAssertEqual(ProgressDateRange(rawValue: range.rawValue), range)
        }
    }
}
