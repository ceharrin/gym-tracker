import Foundation
import CoreData

enum ActivityEditorError: LocalizedError {
    case presetActivitiesCannotBeModified
    case repsOnlyMetricRequiresCustomCategory
    case emptyName

    var errorDescription: String? {
        switch self {
        case .presetActivitiesCannotBeModified:
            return "Preset activities can't be edited or deleted."
        case .repsOnlyMetricRequiresCustomCategory:
            return "Reps Only is available only for custom activities."
        case .emptyName:
            return "Activity name can't be empty."
        }
    }
}

enum ActivityEditor {
    struct ActivityData {
        var name: String
        var category: ActivityCategory
        var metric: PrimaryMetric
        var muscleGroups: String
        var instructions: String
    }

    static func availableMetrics(for category: ActivityCategory) -> [PrimaryMetric] {
        if category == .custom {
            return PrimaryMetric.allCases
        }
        return PrimaryMetric.allCases.filter { $0 != .reps }
    }

    @discardableResult
    static func save(
        data: ActivityData,
        context: NSManagedObjectContext,
        existingActivity: CDActivity? = nil
    ) throws -> CDActivity {
        try validate(data: data, existingActivity: existingActivity)

        let activity = existingActivity ?? CDActivity(context: context)
        if activity.id == nil {
            activity.id = UUID()
        }
        if existingActivity == nil {
            activity.createdAt = Date()
        }

        activity.name = data.name.trimmingCharacters(in: .whitespacesAndNewlines)
        activity.category = data.category.rawValue
        activity.icon = data.category.icon
        activity.primaryMetric = data.metric.rawValue
        activity.muscleGroups = normalizedOptionalString(data.muscleGroups)
        activity.instructions = normalizedOptionalString(data.instructions)
        activity.isPreset = false

        try context.saveIfChanged()
        return activity
    }

    static func delete(_ activity: CDActivity, from context: NSManagedObjectContext) throws {
        guard !activity.isPreset else {
            throw ActivityEditorError.presetActivitiesCannotBeModified
        }
        context.delete(activity)
        try context.saveIfChanged()
    }

    private static func validate(data: ActivityData, existingActivity: CDActivity?) throws {
        if existingActivity?.isPreset == true {
            throw ActivityEditorError.presetActivitiesCannotBeModified
        }
        if data.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw ActivityEditorError.emptyName
        }
        if data.metric == .reps && data.category != .custom {
            throw ActivityEditorError.repsOnlyMetricRequiresCustomCategory
        }
    }

    private static func normalizedOptionalString(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
