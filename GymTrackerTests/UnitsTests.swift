import XCTest
@testable import GymTracker

final class UnitsTests: XCTestCase {

    override func tearDown() {
        Units._testOverrideIsMetric = nil
        super.tearDown()
    }

    // MARK: - Weight (metric)

    func test_weightUnit_metric() {
        Units._testOverrideIsMetric = true
        XCTAssertEqual(Units.weightUnit, "kg")
    }

    func test_weightUnit_imperial() {
        Units._testOverrideIsMetric = false
        XCTAssertEqual(Units.weightUnit, "lbs")
    }

    func test_weightValue_metric_returnsKgUnchanged() {
        Units._testOverrideIsMetric = true
        XCTAssertEqual(Units.weightValue(fromKg: 80), 80)
    }

    func test_weightValue_imperial_convertsToLbs() {
        Units._testOverrideIsMetric = false
        XCTAssertEqual(Units.weightValue(fromKg: 1), 2.20462, accuracy: 0.0001)
    }

    func test_kgFromInput_metric_returnsUnchanged() {
        Units._testOverrideIsMetric = true
        XCTAssertEqual(Units.kgFromInput(80), 80)
    }

    func test_kgFromInput_imperial_convertsFromLbs() {
        Units._testOverrideIsMetric = false
        XCTAssertEqual(Units.kgFromInput(220.462), 100.0, accuracy: 0.01)
    }

    func test_weight_roundTrip_metric() {
        Units._testOverrideIsMetric = true
        let original = 75.5
        XCTAssertEqual(Units.kgFromInput(Units.weightValue(fromKg: original)), original, accuracy: 0.001)
    }

    func test_weight_roundTrip_imperial() {
        Units._testOverrideIsMetric = false
        let original = 75.5
        XCTAssertEqual(Units.kgFromInput(Units.weightValue(fromKg: original)), original, accuracy: 0.001)
    }

    func test_displayWeight_metric() {
        Units._testOverrideIsMetric = true
        XCTAssertEqual(Units.displayWeight(kg: 80), "80.0 kg")
    }

    func test_displayWeight_imperial() {
        Units._testOverrideIsMetric = false
        XCTAssertEqual(Units.displayWeight(kg: 100), "220.5 lbs")
    }

    // MARK: - Height

    func test_heightFeet_fiveTen() {
        XCTAssertEqual(Units.heightFeet(fromCm: 177.8), 5)
    }

    func test_heightInches_fiveTen() {
        XCTAssertEqual(Units.heightInches(fromCm: 177.8), 10)
    }

    func test_heightFeet_sixFoot() {
        XCTAssertEqual(Units.heightFeet(fromCm: 182.88), 6)
    }

    func test_heightInches_sixFoot() {
        XCTAssertEqual(Units.heightInches(fromCm: 182.88), 0)
    }

    func test_cmFromFeetInches_fiveTen() {
        XCTAssertEqual(Units.cmFromFeetInches(feet: 5, inches: 10), 177.8, accuracy: 0.1)
    }

    func test_cmFromFeetInches_sixFoot() {
        XCTAssertEqual(Units.cmFromFeetInches(feet: 6, inches: 0), 182.88, accuracy: 0.1)
    }

    func test_height_roundTrip() {
        let originalCm = 175.0
        let feet = Units.heightFeet(fromCm: originalCm)
        let inches = Units.heightInches(fromCm: originalCm)
        let result = Units.cmFromFeetInches(feet: feet, inches: inches)
        XCTAssertEqual(result, originalCm, accuracy: 2.54) // within 1 inch
    }

    func test_displayHeight_metric() {
        Units._testOverrideIsMetric = true
        XCTAssertEqual(Units.displayHeight(cm: 180), "180 cm")
    }

    func test_displayHeight_imperial() {
        Units._testOverrideIsMetric = false
        XCTAssertEqual(Units.displayHeight(cm: 177.8), "5' 10\"")
    }

    func test_displayHeight_zero_returnsDash() {
        Units._testOverrideIsMetric = true
        XCTAssertEqual(Units.displayHeight(cm: 0), "—")
    }

    func test_displayHeight_zero_imperial_returnsDash() {
        Units._testOverrideIsMetric = false
        XCTAssertEqual(Units.displayHeight(cm: 0), "—")
    }

    // MARK: - Distance

    func test_distanceUnit_metric() {
        Units._testOverrideIsMetric = true
        XCTAssertEqual(Units.distanceUnit, "km")
    }

    func test_distanceUnit_imperial() {
        Units._testOverrideIsMetric = false
        XCTAssertEqual(Units.distanceUnit, "mi")
    }

    func test_distanceValue_metric_returnsKm() {
        Units._testOverrideIsMetric = true
        XCTAssertEqual(Units.distanceValue(fromMeters: 5000), 5.0)
    }

    func test_distanceValue_imperial_returnsMiles() {
        Units._testOverrideIsMetric = false
        XCTAssertEqual(Units.distanceValue(fromMeters: 1609.344), 1.0, accuracy: 0.001)
    }

    func test_metersFromInput_metric() {
        Units._testOverrideIsMetric = true
        XCTAssertEqual(Units.metersFromInput(5.0), 5000.0)
    }

    func test_metersFromInput_imperial() {
        Units._testOverrideIsMetric = false
        XCTAssertEqual(Units.metersFromInput(1.0), 1609.344, accuracy: 0.001)
    }

    func test_distance_roundTrip_metric() {
        Units._testOverrideIsMetric = true
        let meters = 12345.0
        XCTAssertEqual(Units.metersFromInput(Units.distanceValue(fromMeters: meters)), meters, accuracy: 0.001)
    }

    func test_distance_roundTrip_imperial() {
        Units._testOverrideIsMetric = false
        let meters = 12345.0
        XCTAssertEqual(Units.metersFromInput(Units.distanceValue(fromMeters: meters)), meters, accuracy: 0.001)
    }

    func test_displayDistance_metric() {
        Units._testOverrideIsMetric = true
        XCTAssertEqual(Units.displayDistance(meters: 5000), "5.00 km")
    }

    func test_displayDistance_imperial() {
        Units._testOverrideIsMetric = false
        XCTAssertEqual(Units.displayDistance(meters: 1609.344), "1.00 mi")
    }
}
