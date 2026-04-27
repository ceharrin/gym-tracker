import Foundation

enum ProgressDateRange: String, CaseIterable {
    case oneMonth    = "1M"
    case threeMonths = "3M"
    case sixMonths   = "6M"
    case oneYear     = "1Y"
    case allTime     = "All"

    var days: Int? {
        switch self {
        case .oneMonth:    return 30
        case .threeMonths: return 90
        case .sixMonths:   return 180
        case .oneYear:     return 365
        case .allTime:     return nil
        }
    }

    var cutoffDate: Date? {
        guard let days else { return nil }
        return Calendar.current.date(byAdding: .day, value: -days, to: Date())
    }

    var displayLabel: String { rawValue }
}
