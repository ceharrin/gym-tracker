import XCTest
import CoreData
@testable import GymTracker

final class PRDetectionTests: XCTestCase {

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

    // MARK: - Helpers

    private func makeSet(weightKg: Double = 0, reps: Int32 = 0,
                         distanceMeters: Double = 0, durationSeconds: Int32 = 0,
                         laps: Int32 = 0, customValue: Double = 0) -> CDEntrySet {
        let s = CDEntrySet(context: context)
        s.id = UUID()
        s.weightKg = weightKg
        s.reps = reps
        s.distanceMeters = distanceMeters
        s.durationSeconds = durationSeconds
        s.laps = laps
        s.customValue = customValue
        return s
    }

    private func makeLiveSet(weightKg: String = "", reps: String = "",
                              distanceKm: String = "", durationMinutes: String = "",
                              durationSeconds: String = "", laps: String = "",
                              customValue: String = "") -> LiveSet {
        var s = LiveSet()
        s.weightKg = weightKg
        s.reps = reps
        s.distanceKm = distanceKm
        s.durationMinutes = durationMinutes
        s.durationSeconds = durationSeconds
        s.laps = laps
        s.customValue = customValue
        return s
    }

    // MARK: - Empty history → always a PR

    func test_emptyHistory_weightReps_isPR() {
        let live = makeLiveSet(weightKg: "100")
        XCTAssertTrue(isNewPersonalRecord(liveSet: live, metric: .weightReps, against: []))
    }

    func test_emptyHistory_distanceTime_isPR() {
        let live = makeLiveSet(distanceKm: "5.0")
        XCTAssertTrue(isNewPersonalRecord(liveSet: live, metric: .distanceTime, against: []))
    }

    func test_emptyHistory_lapsTime_isPR() {
        let live = makeLiveSet(laps: "20")
        XCTAssertTrue(isNewPersonalRecord(liveSet: live, metric: .lapsTime, against: []))
    }

    func test_emptyHistory_duration_isPR() {
        let live = makeLiveSet(durationMinutes: "30", durationSeconds: "00")
        XCTAssertTrue(isNewPersonalRecord(liveSet: live, metric: .duration, against: []))
    }

    func test_emptyHistory_custom_isPR() {
        let live = makeLiveSet(customValue: "42")
        XCTAssertTrue(isNewPersonalRecord(liveSet: live, metric: .custom, against: []))
    }

    // MARK: - weightReps

    func test_weightReps_beatsHistory_isPR() {
        let history = [makeSet(weightKg: 80), makeSet(weightKg: 90)]
        let live = makeLiveSet(weightKg: "100")
        XCTAssertTrue(isNewPersonalRecord(liveSet: live, metric: .weightReps, against: history))
    }

    func test_weightReps_tiesHistory_notPR() {
        let history = [makeSet(weightKg: 100)]
        let live = makeLiveSet(weightKg: "100")
        XCTAssertFalse(isNewPersonalRecord(liveSet: live, metric: .weightReps, against: history))
    }

    func test_weightReps_belowHistory_notPR() {
        let history = [makeSet(weightKg: 100)]
        let live = makeLiveSet(weightKg: "90")
        XCTAssertFalse(isNewPersonalRecord(liveSet: live, metric: .weightReps, against: history))
    }

    func test_weightReps_zeroValue_notPR() {
        let history: [CDEntrySet] = []
        let live = makeLiveSet(weightKg: "0")
        XCTAssertFalse(isNewPersonalRecord(liveSet: live, metric: .weightReps, against: history))
    }

    func test_weightReps_emptyString_notPR() {
        let history: [CDEntrySet] = []
        let live = makeLiveSet(weightKg: "")
        XCTAssertFalse(isNewPersonalRecord(liveSet: live, metric: .weightReps, against: history))
    }

    // MARK: - distanceTime

    func test_distanceTime_beatsHistory_isPR() {
        let history = [makeSet(distanceMeters: 5000)]
        let live = makeLiveSet(distanceKm: "6.0") // metric: 6000m
        XCTAssertTrue(isNewPersonalRecord(liveSet: live, metric: .distanceTime, against: history))
    }

    func test_distanceTime_belowHistory_notPR() {
        let history = [makeSet(distanceMeters: 10000)]
        let live = makeLiveSet(distanceKm: "5.0")
        XCTAssertFalse(isNewPersonalRecord(liveSet: live, metric: .distanceTime, against: history))
    }

    func test_distanceTime_zeroValue_notPR() {
        let history: [CDEntrySet] = []
        let live = makeLiveSet(distanceKm: "0")
        XCTAssertFalse(isNewPersonalRecord(liveSet: live, metric: .distanceTime, against: history))
    }

    // MARK: - lapsTime

    func test_lapsTime_beatsHistory_isPR() {
        let history = [makeSet(laps: 10)]
        let live = makeLiveSet(laps: "15")
        XCTAssertTrue(isNewPersonalRecord(liveSet: live, metric: .lapsTime, against: history))
    }

    func test_lapsTime_belowHistory_notPR() {
        let history = [makeSet(laps: 20)]
        let live = makeLiveSet(laps: "10")
        XCTAssertFalse(isNewPersonalRecord(liveSet: live, metric: .lapsTime, against: history))
    }

    func test_lapsTime_zeroValue_notPR() {
        let history: [CDEntrySet] = []
        let live = makeLiveSet(laps: "0")
        XCTAssertFalse(isNewPersonalRecord(liveSet: live, metric: .lapsTime, against: history))
    }

    // MARK: - duration

    func test_duration_beatsHistory_isPR() {
        let history = [makeSet(durationSeconds: 1800)] // 30 min
        let live = makeLiveSet(durationMinutes: "35", durationSeconds: "00") // 2100s
        XCTAssertTrue(isNewPersonalRecord(liveSet: live, metric: .duration, against: history))
    }

    func test_duration_belowHistory_notPR() {
        let history = [makeSet(durationSeconds: 3600)]
        let live = makeLiveSet(durationMinutes: "30", durationSeconds: "00")
        XCTAssertFalse(isNewPersonalRecord(liveSet: live, metric: .duration, against: history))
    }

    func test_duration_zeroValue_notPR() {
        let history: [CDEntrySet] = []
        let live = makeLiveSet(durationMinutes: "0", durationSeconds: "0")
        XCTAssertFalse(isNewPersonalRecord(liveSet: live, metric: .duration, against: history))
    }

    func test_duration_minutesAndSecondsAdded() {
        let history = [makeSet(durationSeconds: 100)]
        let live = makeLiveSet(durationMinutes: "1", durationSeconds: "45") // 105s
        XCTAssertTrue(isNewPersonalRecord(liveSet: live, metric: .duration, against: history))
    }

    // MARK: - custom

    func test_custom_beatsHistory_isPR() {
        let history = [makeSet(customValue: 40)]
        let live = makeLiveSet(customValue: "50")
        XCTAssertTrue(isNewPersonalRecord(liveSet: live, metric: .custom, against: history))
    }

    func test_custom_belowHistory_notPR() {
        let history = [makeSet(customValue: 50)]
        let live = makeLiveSet(customValue: "40")
        XCTAssertFalse(isNewPersonalRecord(liveSet: live, metric: .custom, against: history))
    }

    func test_custom_zeroValue_notPR() {
        let history: [CDEntrySet] = []
        let live = makeLiveSet(customValue: "0")
        XCTAssertFalse(isNewPersonalRecord(liveSet: live, metric: .custom, against: history))
    }

    // MARK: - Multiple history entries

    func test_weightReps_beatsAllHistory_isPR() {
        let history = [makeSet(weightKg: 60), makeSet(weightKg: 80), makeSet(weightKg: 95)]
        let live = makeLiveSet(weightKg: "100")
        XCTAssertTrue(isNewPersonalRecord(liveSet: live, metric: .weightReps, against: history))
    }

    func test_weightReps_beatsOnlySome_notPR() {
        let history = [makeSet(weightKg: 60), makeSet(weightKg: 80), makeSet(weightKg: 110)]
        let live = makeLiveSet(weightKg: "100")
        XCTAssertFalse(isNewPersonalRecord(liveSet: live, metric: .weightReps, against: history))
    }
}
