import XCTest
import CoreData
@testable import GymTracker

final class ManagedFetchRequestsTests: XCTestCase {
    func test_activitiesByName_hasEntityAndSortDescriptor() {
        let request = ManagedFetchRequests.activitiesByName()

        XCTAssertEqual(request.entityName, "CDActivity")
        XCTAssertEqual(request.sortDescriptors?.first?.key, "name")
        XCTAssertTrue(request.sortDescriptors?.first?.ascending == true)
    }

    func test_customActivitiesByName_hasEntitySortDescriptorAndPredicate() {
        let request = ManagedFetchRequests.customActivitiesByName()

        XCTAssertEqual(request.entityName, "CDActivity")
        XCTAssertEqual(request.sortDescriptors?.first?.key, "name")
        XCTAssertEqual(request.predicate?.predicateFormat, "isPreset == 0")
    }

    func test_profilesByCreatedAt_hasEntityAndSortDescriptor() {
        let request = ManagedFetchRequests.profilesByCreatedAt()

        XCTAssertEqual(request.entityName, "CDUserProfile")
        XCTAssertEqual(request.sortDescriptors?.first?.key, "createdAt")
    }

    func test_workoutsByDate_hasEntityAndSortDirection() {
        let descendingRequest = ManagedFetchRequests.workoutsByDate(ascending: false)
        let ascendingRequest = ManagedFetchRequests.workoutsByDate(ascending: true)

        XCTAssertEqual(descendingRequest.entityName, "CDWorkout")
        XCTAssertEqual(descendingRequest.sortDescriptors?.first?.key, "date")
        XCTAssertTrue(descendingRequest.sortDescriptors?.first?.ascending == false)
        XCTAssertTrue(ascendingRequest.sortDescriptors?.first?.ascending == true)
    }

    func test_measurementsByDateDescending_hasEntityAndSortDescriptor() {
        let request = ManagedFetchRequests.measurementsByDateDescending()

        XCTAssertEqual(request.entityName, "CDBodyMeasurement")
        XCTAssertEqual(request.sortDescriptors?.first?.key, "date")
        XCTAssertTrue(request.sortDescriptors?.first?.ascending == false)
    }
}
