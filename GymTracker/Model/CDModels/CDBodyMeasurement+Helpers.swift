import Foundation
import CoreData

enum HealthDataSource: String, CaseIterable {
    case local
    case healthKitImported = "healthkit_imported"
}

extension CDBodyMeasurement {
    var healthKitSyncState: HealthKitSyncState {
        get { HealthKitSyncState(rawValue: healthKitSyncStateRaw) ?? .notSynced }
        set { healthKitSyncStateRaw = newValue.rawValue }
    }

    var healthDataSource: HealthDataSource {
        get { HealthDataSource(rawValue: healthKitSourceRaw) ?? .local }
        set { healthKitSourceRaw = newValue.rawValue }
    }

    var weightLbs: Double { weightKg * 2.20462 }
}
