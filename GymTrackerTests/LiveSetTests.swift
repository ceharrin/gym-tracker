import XCTest
@testable import GymTracker

final class LiveSetTests: XCTestCase {

    // MARK: - filterNumericInput

    func test_filter_digitsOnly_passThrough() {
        XCTAssertEqual(filterNumericInput("123", allowDecimal: false), "123")
    }

    func test_filter_removesAlphaCharacters() {
        XCTAssertEqual(filterNumericInput("12abc34", allowDecimal: false), "1234")
    }

    func test_filter_removesAllAlpha() {
        XCTAssertEqual(filterNumericInput("abc", allowDecimal: false), "")
    }

    func test_filter_emptyStringReturnsEmpty() {
        XCTAssertEqual(filterNumericInput("", allowDecimal: false), "")
    }

    func test_filter_allowsDecimalWhenEnabled() {
        XCTAssertEqual(filterNumericInput("12.5", allowDecimal: true), "12.5")
    }

    func test_filter_stripsDecimalWhenDisabled() {
        XCTAssertEqual(filterNumericInput("12.5", allowDecimal: false), "125")
    }

    func test_filter_allowsOnlyOneDecimalPoint() {
        XCTAssertEqual(filterNumericInput("12.3.4", allowDecimal: true), "12.34")
    }

    func test_filter_leadingDecimalAllowed() {
        XCTAssertEqual(filterNumericInput(".5", allowDecimal: true), ".5")
    }

    func test_filter_trailingDecimalAllowed() {
        XCTAssertEqual(filterNumericInput("12.", allowDecimal: true), "12.")
    }

    func test_filter_stripsSpacesAndSpecialChars() {
        XCTAssertEqual(filterNumericInput("1 0 0", allowDecimal: false), "100")
    }

    func test_filter_mixedAlphaAndDecimal() {
        XCTAssertEqual(filterNumericInput("8kg", allowDecimal: false), "8")
    }

    func test_filter_pastedTextWithDecimalDisabled() {
        XCTAssertEqual(filterNumericInput("22.5 lbs", allowDecimal: false), "225")
    }

    // MARK: - LiveSet.copying

    func test_copying_hasNewID() {
        let original = LiveSet()
        let copy = LiveSet.copying(original)
        XCTAssertNotEqual(copy.id, original.id)
    }

    func test_copying_copiesWeightAndReps() {
        var original = LiveSet()
        original.weightKg = "100"
        original.reps = "5"
        let copy = LiveSet.copying(original)
        XCTAssertEqual(copy.weightKg, "100")
        XCTAssertEqual(copy.reps, "5")
    }

    func test_copying_copiesDistanceAndDuration() {
        var original = LiveSet()
        original.distanceKm = "5.0"
        original.durationMinutes = "25"
        original.durationSeconds = "30"
        let copy = LiveSet.copying(original)
        XCTAssertEqual(copy.distanceKm, "5.0")
        XCTAssertEqual(copy.durationMinutes, "25")
        XCTAssertEqual(copy.durationSeconds, "30")
    }

    func test_copying_copiesLaps() {
        var original = LiveSet()
        original.laps = "20"
        let copy = LiveSet.copying(original)
        XCTAssertEqual(copy.laps, "20")
    }

    func test_copying_copiesCustomFields() {
        var original = LiveSet()
        original.customValue = "42.5"
        original.customLabel = "km/h"
        let copy = LiveSet.copying(original)
        XCTAssertEqual(copy.customValue, "42.5")
        XCTAssertEqual(copy.customLabel, "km/h")
    }

    func test_copying_doesNotCopyNotes() {
        var original = LiveSet()
        original.notes = "felt heavy"
        let copy = LiveSet.copying(original)
        XCTAssertEqual(copy.notes, "")
    }

    func test_copying_emptySetProducesEmptySet() {
        let original = LiveSet()
        let copy = LiveSet.copying(original)
        XCTAssertEqual(copy.weightKg, "")
        XCTAssertEqual(copy.reps, "")
    }

    // MARK: - isPRAttempt

    func test_isPRAttempt_defaultsFalse() {
        let s = LiveSet()
        XCTAssertFalse(s.isPRAttempt)
    }

    func test_copying_doesNotCopyIsPRAttempt() {
        var original = LiveSet()
        original.isPRAttempt = true
        let copy = LiveSet.copying(original)
        XCTAssertFalse(copy.isPRAttempt)
    }

    // MARK: - Duration field filtering

    func test_filter_durationMinutes_stripsDecimal() {
        // User pastes "2.5" into duration minutes — decimal must be removed
        XCTAssertEqual(filterNumericInput("2.5", allowDecimal: false), "25")
    }

    func test_filter_durationMinutes_stripsNonNumeric() {
        XCTAssertEqual(filterNumericInput("5min", allowDecimal: false), "5")
    }

    func test_filter_workoutDuration_stripsLetterAndDecimal() {
        XCTAssertEqual(filterNumericInput("45.0 min", allowDecimal: false), "450")
    }

}
