import CloudKit
import SwiftUI

@MainActor
final class CloudSyncMonitor: ObservableObject {
    static let shared = CloudSyncMonitor()

    @Published private(set) var accountStatus: CKAccountStatus = .couldNotDetermine

    private let containerID = "iCloud.com.chrisharrington.GymTracker"

    init() {
        Task { await refresh() }
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(accountChanged),
            name: .CKAccountChanged,
            object: nil
        )
    }

    func refresh() async {
        do {
            let status = try await CKContainer(identifier: containerID).accountStatus()
            accountStatus = status
        } catch {
            accountStatus = .couldNotDetermine
        }
    }

    @objc private func accountChanged() {
        Task { await refresh() }
    }

    var isSyncing: Bool { accountStatus == .available }

    var statusLabel: String {
        switch accountStatus {
        case .available:             return "Syncing with iCloud"
        case .noAccount:             return "Sign in to iCloud to sync"
        case .restricted:            return "iCloud access restricted"
        case .temporarilyUnavailable: return "iCloud temporarily unavailable"
        case .couldNotDetermine:     return "Checking iCloud…"
        @unknown default:            return "iCloud status unknown"
        }
    }

    var statusIcon: String {
        switch accountStatus {
        case .available:             return "checkmark.icloud"
        case .noAccount:             return "icloud.slash"
        case .restricted:            return "exclamationmark.icloud"
        case .temporarilyUnavailable: return "icloud.and.arrow.up"
        case .couldNotDetermine:     return "icloud"
        @unknown default:            return "icloud"
        }
    }
}
