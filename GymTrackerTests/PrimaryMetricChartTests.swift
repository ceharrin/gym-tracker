import XCTest
import CoreData
@testable import GymTracker

final class PrimaryMetricChartTests: XCTestCase {

    var context: NSManagedObjectContext!

    override func setUp() {
        super.setUp()
        context = CoreDataTestHelper.makeContext()
        Units._testOverrideIsMetric = true
    }

    override func tearDown() {
        Units._testOverrideIsMetric = nil
        super.tearDown()
    }

    // MARK: - chartYLabel

    func test_chartYLabel_weightReps_isKgMetric() {
        Units._testOverrideIsMetric = true
        XCTAssertEqual(PrimaryMetric.weightReps.chartYLabel, "kg")
    }

    func test_chartYLabel_weightReps_isLbsImperial() {
        Units._testOverrideIsMetric = false
        XCTAssertEqual(PrimaryMetric.weightReps.chartYLabel, "lbs")
    }

    func test_chartYLabel_distanceTime_isKmMetric() {
        Units._testOverrideIsMetric = true
        XCTAssertEqual(PrimaryMetric.distanceTime.chartYLabel, "km")
    }

    func test_chartYLabel_distanceTime_isMiImperial() {
        Units._testOverrideIsMetric = false
        XCTAssertEqual(PrimaryMetric.distanceTime.chartYLabel, "mi")
    }

    func test_chartYLabel_lapsTime_isLaps() {
        XCTAssertEqual(PrimaryMetric.lapsTime.chartYLabel, "laps")
    }

    func test_chartYLabel_duration_isMin() {
        XCTAssertEqual(PrimaryMetric.duration.chartYLabel, "min")
    }

    func test_chartYLabel_custom_isValue() {
        XCTAssertEqual(PrimaryMetric.custom.chartYLabel, "value")
    }

    // MARK: - chartValue(from:)

    private func makeSet(
        weightKg: Double = 0,
        distanceMeters: Double = 0,
        durationSeconds: Int32 = 0,
        laps: Int32 = 0,
        customValue: Double = 0
    ) -> CDEntrySet {
        let s = CDEntrySet(context: context)
        s.id = UUID()
        s.setNumber = 1
        s.weightKg = weightKg
        s.distanceMeters = distanceMeters
        s.durationSeconds = durationSeconds
        s.laps = laps
        s.customValue = customValue
        return s
    }

    func test_chartValue_weightReps_returnsKgMetric() {
        Units._testOverrideIsMetric = true
        let s = makeSet(weightKg: 100)
        XCTAssertEqual(PrimaryMetric.weightReps.chartValue(from: s), 100, accuracy: 0.001)
    }

    func test_chartValue_weightReps_returnsLbsImperial() {
        Units._testOverrideIsMetric = false
        let s = makeSet(weightKg: 100)
        XCTAssertEqual(PrimaryMetric.weightReps.chartValue(from: s), 220.462, accuracy: 0.01)
    }

    func test_chartValue_distanceTime_returnsKmMetric() {
        Units._testOverrideIsMetric = true
        let s = makeSet(distanceMeters: 5000)
        XCTAssertEqual(PrimaryMetric.distanceTime.chartValue(from: s), 5.0, accuracy: 0.001)
    }

    func test_chartValue_distanceTime_returnsMilesImperial() {
        Units._testOverrideIsMetric = false
        let s = makeSet(distanceMeters: 1609.344)
        XCTAssertEqual(PrimaryMetric.distanceTime.chartValue(from: s), 1.0, accuracy: 0.001)
    }

    func test_chartValue_lapsTime_returnsLapCount() {
        let s = makeSet(laps: 20)
        XCTAssertEqual(PrimaryMetric.lapsTime.chartValue(from: s), 20, accuracy: 0.001)
    }

    func test_chartValue_duration_returnsMinutes() {
        let s = makeSet(durationSeconds: 1800) // 30 min
        XCTAssertEqual(PrimaryMetric.duration.chartValue(from: s), 30.0, accuracy: 0.001)
    }

    func test_chartValue_duration_fractionalMinutes() {
        let s = makeSet(durationSeconds: 90) // 1.5 min
        XCTAssertEqual(PrimaryMetric.duration.chartValue(from: s), 1.5, accuracy: 0.001)
    }

    func test_chartValue_custom_returnsRawValue() {
        let s = makeSet(customValue: 42.5)
        XCTAssertEqual(PrimaryMetric.custom.chartValue(from: s), 42.5, accuracy: 0.001)
    }

    // MARK: - formattedChartValue(_:)

    func test_formattedChartValue_weightReps_oneDecimalPlace() {
        XCTAssertEqual(PrimaryMetric.weightReps.formattedChartValue(80.5), "80.5")
    }

    func test_formattedChartValue_distanceTime_oneDecimalPlace() {
        XCTAssertEqual(PrimaryMetric.distanceTime.formattedChartValue(5.2), "5.2")
    }

    func test_formattedChartValue_lapsTime_noDecimal() {
        XCTAssertEqual(PrimaryMetric.lapsTime.formattedChartValue(20.0), "20")
    }

    func test_formattedChartValue_duration_noDecimal() {
        XCTAssertEqual(PrimaryMetric.duration.formattedChartValue(30.0), "30")
    }

    func test_formattedChartValue_custom_oneDecimalPlace() {
        XCTAssertEqual(PrimaryMetric.custom.formattedChartValue(12.3), "12.3")
    }

    func test_formattedChartValue_weightReps_roundsCorrectly() {
        XCTAssertEqual(PrimaryMetric.weightReps.formattedChartValue(100.0), "100.0")
    }

    func test_formattedChartValue_duration_roundsDown() {
        // 30.7 min → "31" (%.0f rounds to nearest)
        XCTAssertEqual(PrimaryMetric.duration.formattedChartValue(30.7), "31")
    }
}
