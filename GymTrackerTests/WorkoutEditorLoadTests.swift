import XCTest
import CoreData
@testable import GymTracker

final class WorkoutEditorLoadTests: XCTestCase {

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

    private func makeActivity(
        name: String = "Bench Press",
        metric: PrimaryMetric = .weightReps
    ) -> CDActivity {
        let a = CDActivity(context: context)
        a.id = UUID()
        a.name = name
        a.category = ActivityCategory.strength.rawValue
        a.primaryMetric = metric.rawValue
        a.isPreset = false
        return a
    }

    /// Saves a workout via WorkoutEditor and reloads it.
    private func saveAndLoad(
        title: String = "Test",
        date: Date = Date(),
        energyLevel: Int = 7,
        notes: String = "",
        entries: [(CDActivity, [LiveSet])] = [],
        completedAt: Date? = nil
    ) throws -> WorkoutEditor.WorkoutData {
        let data = WorkoutEditor.WorkoutData(
            title: title,
            date: date,
            energyLevel: energyLevel,
            notes: notes,
            entries: entries.map { LiveEntry(activity: $0.0, sets: $0.1) }
        )
        let result = try WorkoutEditor.save(
            data: data,
            context: context,
            existingWorkout: nil,
            isDuplicate: false,
            startTime: date,
            completedAt: completedAt ?? date
        )
        return WorkoutEditor.load(from: result.savedWorkout)
    }

    private func liveSet(
        weightKg: String = "",
        reps: String = "",
        distanceKm: String = "",
        durationMinutes: String = "",
        durationSeconds: String = "",
        laps: String = "",
        customValue: String = "",
        customLabel: String = ""
    ) -> LiveSet {
        var s = LiveSet()
        s.weightKg = weightKg
        s.reps = reps
        s.distanceKm = distanceKm
        s.durationMinutes = durationMinutes
        s.durationSeconds = durationSeconds
        s.laps = laps
        s.customValue = customValue
        s.customLabel = customLabel
        return s
    }

    // MARK: - Workout metadata round-trips

    func test_load_title() throws {
        let loaded = try saveAndLoad(title: "Heavy Leg Day")
        XCTAssertEqual(loaded.title, "Heavy Leg Day")
    }

    func test_load_date() throws {
        let date = Calendar.current.date(from: DateComponents(year: 2026, month: 4, day: 20))!
        let loaded = try saveAndLoad(date: date)
        XCTAssertEqual(loaded.date, date)
    }

    func test_load_durationMinutes() throws {
        let start = Date(timeIntervalSinceReferenceDate: 1_000)
        let loaded = try saveAndLoad(date: start, completedAt: start.addingTimeInterval(60 * 60))
        XCTAssertEqual(loaded.durationMinutes, "60")
    }

    func test_load_durationMinutes_zeroReturnedAsEmpty() throws {
        let loaded = try saveAndLoad()
        XCTAssertEqual(loaded.durationMinutes, "",
                       "Zero durationMinutes must be loaded as empty string")
    }

    func test_load_energyLevel() throws {
        let loaded = try saveAndLoad(energyLevel: 8)
        XCTAssertEqual(loaded.energyLevel, 8)
    }

    func test_load_notes() throws {
        let loaded = try saveAndLoad(notes: "Felt great today")
        XCTAssertEqual(loaded.notes, "Felt great today")
    }

    func test_load_emptyNotes_returnsEmptyString() throws {
        let loaded = try saveAndLoad(notes: "")
        XCTAssertEqual(loaded.notes, "")
    }

    // MARK: - Entries round-trip

    func test_load_entryCount_matchesSaved() throws {
        let a1 = makeActivity(name: "Squat")
        let a2 = makeActivity(name: "Deadlift")
        let loaded = try saveAndLoad(entries: [
            (a1, [liveSet(weightKg: "100", reps: "5")]),
            (a2, [liveSet(weightKg: "150", reps: "3")])
        ])
        XCTAssertEqual(loaded.entries.count, 2)
    }

    func test_load_entryActivity_preserved() throws {
        let a = makeActivity(name: "Overhead Press")
        let loaded = try saveAndLoad(entries: [(a, [liveSet(weightKg: "50", reps: "8")])])
        XCTAssertEqual(loaded.entries.first?.activity.name, "Overhead Press")
    }

    func test_load_entryOrder_preserved() throws {
        let a1 = makeActivity(name: "A")
        let a2 = makeActivity(name: "B")
        let a3 = makeActivity(name: "C")
        let loaded = try saveAndLoad(entries: [
            (a1, [liveSet()]),
            (a2, [liveSet()]),
            (a3, [liveSet()])
        ])
        XCTAssertEqual(loaded.entries.map { $0.activity.name }, ["A", "B", "C"])
    }

    // MARK: - Sets round-trip

    func test_load_setCount_matchesSaved() throws {
        let a = makeActivity()
        let loaded = try saveAndLoad(entries: [(a, [liveSet(), liveSet(), liveSet()])])
        XCTAssertEqual(loaded.entries.first?.sets.count, 3)
    }

    func test_load_weightKg_roundTrip_metric() throws {
        let a = makeActivity()
        let loaded = try saveAndLoad(entries: [(a, [liveSet(weightKg: "80")])])
        XCTAssertEqual(loaded.entries.first?.sets.first?.weightKg, "80.0")
    }

    func test_load_reps_roundTrip() throws {
        let a = makeActivity()
        let loaded = try saveAndLoad(entries: [(a, [liveSet(reps: "12")])])
        XCTAssertEqual(loaded.entries.first?.sets.first?.reps, "12")
    }

    func test_load_distanceKm_roundTrip_metric() throws {
        let a = makeActivity(metric: .distanceTime)
        let loaded = try saveAndLoad(entries: [(a, [liveSet(distanceKm: "5")])])
        XCTAssertEqual(loaded.entries.first?.sets.first?.distanceKm, "5.00")
    }

    func test_load_duration_roundTrip() throws {
        let a = makeActivity(metric: .duration)
        let loaded = try saveAndLoad(entries: [(a, [liveSet(durationMinutes: "10", durationSeconds: "30")])])
        let set = loaded.entries.first?.sets.first
        XCTAssertEqual(set?.durationMinutes, "10")
        XCTAssertEqual(set?.durationSeconds, "30")
    }

    func test_load_laps_roundTrip() throws {
        let a = makeActivity(metric: .lapsTime)
        let loaded = try saveAndLoad(entries: [(a, [liveSet(laps: "25")])])
        XCTAssertEqual(loaded.entries.first?.sets.first?.laps, "25")
    }

    func test_load_customValue_roundTrip() throws {
        let a = makeActivity(metric: .custom)
        let loaded = try saveAndLoad(entries: [(a, [liveSet(customValue: "15", customLabel: "kg")])])
        let set = loaded.entries.first?.sets.first
        XCTAssertEqual(set?.customValue, "15.0")
        XCTAssertEqual(set?.customLabel, "kg")
    }

    func test_load_zeroWeight_loadsAsEmptyString() throws {
        let a = makeActivity()
        let loaded = try saveAndLoad(entries: [(a, [liveSet(weightKg: "")])])
        XCTAssertEqual(loaded.entries.first?.sets.first?.weightKg, "")
    }

    func test_load_zeroReps_loadsAsEmptyString() throws {
        let a = makeActivity()
        let loaded = try saveAndLoad(entries: [(a, [liveSet(reps: "")])])
        XCTAssertEqual(loaded.entries.first?.sets.first?.reps, "")
    }

    func test_load_emptyEntries_returnsEmptyList() throws {
        let loaded = try saveAndLoad(entries: [])
        XCTAssertTrue(loaded.entries.isEmpty)
    }

    // MARK: - Imperial unit round-trip

    func test_load_weightKg_imperial_roundTrip() throws {
        Units._testOverrideIsMetric = false
        let a = makeActivity()
        // User enters "200" lbs → saved as ~90.7 kg → loaded back as "200.0" lbs
        let loaded = try saveAndLoad(entries: [(a, [liveSet(weightKg: "200")])])
        let loadedWeight = Double(loaded.entries.first?.sets.first?.weightKg ?? "") ?? 0
        XCTAssertEqual(loadedWeight, 200.0, accuracy: 0.5)
    }

    func test_load_distance_imperial_roundTrip() throws {
        Units._testOverrideIsMetric = false
        let a = makeActivity(metric: .distanceTime)
        // User enters "3" miles → saved as meters → loaded back as ~"3.00"
        let loaded = try saveAndLoad(entries: [(a, [liveSet(distanceKm: "3")])])
        let loadedDist = Double(loaded.entries.first?.sets.first?.distanceKm ?? "") ?? 0
        XCTAssertEqual(loadedDist, 3.0, accuracy: 0.01)
    }
}
