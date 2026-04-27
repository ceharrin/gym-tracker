import Foundation

final class WorkoutHealthKitManager {
    static let shared = WorkoutHealthKitManager()

    private let service: HealthKitServiceProtocol

    init(service: HealthKitServiceProtocol = LiveHealthKitService()) {
        self.service = service
    }

    func requestAuthorization() async {
        guard service.isAvailable else { return }
        try? await service.requestAuthorization()
    }

    func syncWorkout(date: Date, durationMinutes: Int, isNew: Bool = true) async {
        guard isNew, service.isAvailable else { return }
        let end = date.addingTimeInterval(TimeInterval(durationMinutes * 60))
        do {
            try await service.requestAuthorization()
            try await service.saveStrengthWorkout(start: date, end: end)
        } catch {
            // Best-effort — HealthKit sync failure must never affect the workout save
        }
    }
}
