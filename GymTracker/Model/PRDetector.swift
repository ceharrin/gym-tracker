import Foundation

/// Returns true if `liveSet` is a new personal record compared to `history`.
/// - Zero / empty values are never considered PRs.
/// - Empty history counts as an automatic PR (first time doing the activity).
func isNewPersonalRecord(liveSet: LiveSet, metric: PrimaryMetric, against history: [CDEntrySet]) -> Bool {
    switch metric {
    case .weightReps:
        let val = Double(liveSet.weightKg) ?? 0
        guard val > 0 else { return false }
        guard !history.isEmpty else { return true }
        return val > (history.map(\.weightKg).max() ?? 0)

    case .distanceTime:
        let val = Units.metersFromInput(Double(liveSet.distanceKm) ?? 0)
        guard val > 0 else { return false }
        guard !history.isEmpty else { return true }
        return val > (history.map(\.distanceMeters).max() ?? 0)

    case .lapsTime:
        let val = Int32(liveSet.laps) ?? 0
        guard val > 0 else { return false }
        guard !history.isEmpty else { return true }
        return val > (history.map(\.laps).max() ?? 0)

    case .duration:
        let m = Int32(liveSet.durationMinutes) ?? 0
        let s = Int32(liveSet.durationSeconds) ?? 0
        let secs = m * 60 + s
        guard secs > 0 else { return false }
        guard !history.isEmpty else { return true }
        return secs > (history.map(\.durationSeconds).max() ?? 0)

    case .reps:
        let val = Int32(liveSet.reps) ?? 0
        guard val > 0 else { return false }
        guard !history.isEmpty else { return true }
        return val > (history.map(\.reps).max() ?? 0)

    case .custom:
        let val = Double(liveSet.customValue) ?? 0
        guard val > 0 else { return false }
        guard !history.isEmpty else { return true }
        return val > (history.map(\.customValue).max() ?? 0)
    }
}
