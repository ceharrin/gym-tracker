import XCTest
import CoreData
@testable import GymTracker

final class WorkoutExporterTests: XCTestCase {

    var context: NSManagedObjectContext!
    var tempDirectory: URL!

    override func setUp() {
        super.setUp()
        context = CoreDataTestHelper.makeContext()
        // Use a dedicated temp subdirectory so tests are isolated from each other
        // and cleaned up reliably.
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("WorkoutExporterTests-\(UUID().uuidString)")
        try! FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDirectory)
        super.tearDown()
    }

    // MARK: - Helpers

    private func makeWorkout(title: String = "Monday Push",
                              date: Date = .init(),
                              notes: String? = nil) -> CDWorkout {
        let w = CDWorkout(context: context)
        w.id = UUID()
        w.title = title
        w.date = date
        w.durationMinutes = 45
        w.notes = notes
        return w
    }

    private func makeActivity(name: String = "Bench Press") -> CDActivity {
        let a = CDActivity(context: context)
        a.id = UUID()
        a.name = name
        a.category = ActivityCategory.strength.rawValue
        a.primaryMetric = PrimaryMetric.weightReps.rawValue
        return a
    }

    private func addEntry(to workout: CDWorkout, activity: CDActivity) {
        let e = CDWorkoutEntry(context: context)
        e.id = UUID()
        e.orderIndex = 0
        e.activity = activity
        e.workout = workout
        let s = CDEntrySet(context: context)
        s.id = UUID()
        s.setNumber = 1
        s.weightKg = 80
        s.reps = 10
        s.entry = e
    }

    // MARK: - File creation

    func test_exportHTML_createsFile() throws {
        let workout = makeWorkout()
        let url = try WorkoutExporter.exportHTML(for: workout, directory: tempDirectory)
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path),
                      "Export must create a file at the returned URL")
    }

    func test_exportHTML_fileIsNonEmpty() throws {
        let workout = makeWorkout()
        let url = try WorkoutExporter.exportHTML(for: workout, directory: tempDirectory)
        let size = try FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int ?? 0
        XCTAssertGreaterThan(size, 0, "Exported file must not be empty")
    }

    func test_exportHTML_hasHTMLExtension() throws {
        let workout = makeWorkout()
        let url = try WorkoutExporter.exportHTML(for: workout, directory: tempDirectory)
        XCTAssertEqual(url.pathExtension, "html", "Export must use the .html extension")
    }

    // MARK: - Filename

    func test_exportHTML_filenameContainsWorkoutTitle() throws {
        let workout = makeWorkout(title: "Heavy Leg Day")
        let url = try WorkoutExporter.exportHTML(for: workout, directory: tempDirectory)
        XCTAssertTrue(url.lastPathComponent.contains("Heavy Leg Day"),
                      "Filename should contain the workout title so share sheets show a meaningful name")
    }

    func test_sanitizedFilename_emptyTitle_usesDefault() {
        let name = WorkoutExporter.sanitizedFilename(from: "")
        XCTAssertEqual(name, "GymTracker-Workout.html",
                       "Empty title must fall back to the default filename")
    }

    func test_sanitizedFilename_specialCharacters_replaced() {
        let name = WorkoutExporter.sanitizedFilename(from: "Push/Pull:Day")
        XCTAssertFalse(name.contains("/"), "Slash must be removed from filename")
        XCTAssertFalse(name.contains(":"), "Colon must be removed from filename")
        XCTAssertTrue(name.hasSuffix(".html"), "Extension must be preserved after sanitisation")
    }

    func test_sanitizedFilename_normalTitle_preservedWithExtension() {
        let name = WorkoutExporter.sanitizedFilename(from: "Monday Push")
        XCTAssertEqual(name, "Monday Push.html")
    }

    // MARK: - HTML content

    func test_exportHTML_contentContainsTitle() throws {
        let workout = makeWorkout(title: "Chest and Triceps")
        let url = try WorkoutExporter.exportHTML(for: workout, directory: tempDirectory)
        let content = try String(contentsOf: url, encoding: .utf8)
        XCTAssertTrue(content.contains("Chest and Triceps"), "HTML must contain the workout title")
    }

    func test_exportHTML_contentContainsDate() throws {
        let date = Calendar.current.date(from: DateComponents(year: 2026, month: 4, day: 20))!
        let workout = makeWorkout(date: date)
        let url = try WorkoutExporter.exportHTML(for: workout, directory: tempDirectory)
        let content = try String(contentsOf: url, encoding: .utf8)
        XCTAssertTrue(content.contains("2026"), "HTML must contain the workout year")
    }

    func test_exportHTML_contentContainsActivityName() throws {
        let workout = makeWorkout()
        let activity = makeActivity(name: "Overhead Press")
        addEntry(to: workout, activity: activity)
        let url = try WorkoutExporter.exportHTML(for: workout, directory: tempDirectory)
        let content = try String(contentsOf: url, encoding: .utf8)
        XCTAssertTrue(content.contains("Overhead Press"), "HTML must contain exercise names")
    }

    func test_exportHTML_contentIsValidHTML() throws {
        let workout = makeWorkout()
        let url = try WorkoutExporter.exportHTML(for: workout, directory: tempDirectory)
        let content = try String(contentsOf: url, encoding: .utf8)
        XCTAssertTrue(content.hasPrefix("<!DOCTYPE html>"), "Export must produce a complete HTML document")
        XCTAssertTrue(content.contains("</html>"), "HTML document must be properly closed")
    }

    // MARK: - Failure handling

    func test_exportHTML_throwsWhenDirectoryDoesNotExist() {
        let workout = makeWorkout()
        let badDirectory = tempDirectory.appendingPathComponent("does-not-exist/nested")
        XCTAssertThrowsError(
            try WorkoutExporter.exportHTML(for: workout, directory: badDirectory),
            "Export must throw when the target directory does not exist"
        ) { error in
            XCTAssertTrue(error is WorkoutExporter.ExportError,
                          "Thrown error must be WorkoutExporter.ExportError")
        }
    }

    func test_exportError_hasLocalizedDescription() {
        let underlying = NSError(domain: "test", code: 1,
                                 userInfo: [NSLocalizedDescriptionKey: "disk full"])
        let exportError = WorkoutExporter.ExportError.writeFailure(underlying)
        XCTAssertFalse(exportError.errorDescription?.isEmpty ?? true,
                       "ExportError must provide a non-empty localized description")
        XCTAssertTrue(exportError.errorDescription?.contains("disk full") ?? false,
                      "ExportError description should include the underlying reason")
    }
}
