import CoreData

enum ManagedFetchRequests {
    static func activitiesByName() -> NSFetchRequest<CDActivity> {
        let request = CDActivity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDActivity.name, ascending: true)]
        return request
    }

    static func customActivitiesByName() -> NSFetchRequest<CDActivity> {
        let request = activitiesByName()
        request.predicate = NSPredicate(format: "isPreset == NO")
        return request
    }

    static func profilesByCreatedAt() -> NSFetchRequest<CDUserProfile> {
        let request = CDUserProfile.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDUserProfile.createdAt, ascending: true)]
        return request
    }

    static func workoutsByDate(ascending: Bool) -> NSFetchRequest<CDWorkout> {
        let request = CDWorkout.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDWorkout.date, ascending: ascending)]
        return request
    }

    static func measurementsByDateDescending() -> NSFetchRequest<CDBodyMeasurement> {
        let request = CDBodyMeasurement.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDBodyMeasurement.date, ascending: false)]
        return request
    }
}
