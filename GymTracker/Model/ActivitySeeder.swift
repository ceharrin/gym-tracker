import CoreData
import Foundation

struct ActivitySeeder {
    struct Preset {
        let name: String
        let category: ActivityCategory
        let icon: String
        let metric: PrimaryMetric
        let muscles: String?
    }

    static let presets: [Preset] = [
        // Strength
        Preset(name: "Squat",               category: .strength, icon: "figure.strengthtraining.traditional", metric: .weightReps, muscles: "Quads, Glutes, Hamstrings"),
        Preset(name: "Deadlift",            category: .strength, icon: "figure.strengthtraining.traditional", metric: .weightReps, muscles: "Hamstrings, Glutes, Lower Back"),
        Preset(name: "Bench Press",         category: .strength, icon: "figure.strengthtraining.traditional", metric: .weightReps, muscles: "Chest, Triceps, Front Delts"),
        Preset(name: "Overhead Press",      category: .strength, icon: "figure.strengthtraining.traditional", metric: .weightReps, muscles: "Shoulders, Triceps"),
        Preset(name: "Barbell Row",         category: .strength, icon: "figure.strengthtraining.traditional", metric: .weightReps, muscles: "Back, Biceps"),
        Preset(name: "Pull-Up",             category: .strength, icon: "figure.strengthtraining.traditional", metric: .weightReps, muscles: "Lats, Biceps"),
        Preset(name: "Chin-Up",             category: .strength, icon: "figure.strengthtraining.traditional", metric: .weightReps, muscles: "Lats, Biceps"),
        Preset(name: "Leg Press",           category: .strength, icon: "figure.strengthtraining.traditional", metric: .weightReps, muscles: "Quads, Glutes"),
        Preset(name: "Leg Curl",            category: .strength, icon: "figure.strengthtraining.traditional", metric: .weightReps, muscles: "Hamstrings"),
        Preset(name: "Leg Extension",       category: .strength, icon: "figure.strengthtraining.traditional", metric: .weightReps, muscles: "Quads"),
        Preset(name: "Chest Press",         category: .strength, icon: "figure.strengthtraining.traditional", metric: .weightReps, muscles: "Chest, Triceps"),
        Preset(name: "Lat Pulldown",        category: .strength, icon: "figure.strengthtraining.traditional", metric: .weightReps, muscles: "Lats, Biceps"),
        Preset(name: "Seated Row",          category: .strength, icon: "figure.strengthtraining.traditional", metric: .weightReps, muscles: "Back, Biceps"),
        Preset(name: "Shoulder Press",      category: .strength, icon: "figure.strengthtraining.traditional", metric: .weightReps, muscles: "Shoulders, Triceps"),
        Preset(name: "Bicep Curl",          category: .strength, icon: "figure.strengthtraining.traditional", metric: .weightReps, muscles: "Biceps"),
        Preset(name: "Triceps Pushdown",    category: .strength, icon: "figure.strengthtraining.traditional", metric: .weightReps, muscles: "Triceps"),
        Preset(name: "Dumbbell Curl",       category: .strength, icon: "dumbbell.fill",                       metric: .weightReps, muscles: "Biceps"),
        Preset(name: "Lateral Raise",       category: .strength, icon: "dumbbell.fill",                       metric: .weightReps, muscles: "Lateral Delts"),
        Preset(name: "Face Pull",           category: .strength, icon: "dumbbell.fill",                       metric: .weightReps, muscles: "Rear Delts, Rotator Cuff"),
        Preset(name: "Romanian Deadlift",   category: .strength, icon: "figure.strengthtraining.traditional", metric: .weightReps, muscles: "Hamstrings, Glutes"),
        Preset(name: "Hip Thrust",          category: .strength, icon: "figure.strengthtraining.traditional", metric: .weightReps, muscles: "Glutes, Hamstrings"),
        Preset(name: "Plank",               category: .strength, icon: "figure.core.training",                metric: .duration,   muscles: "Core"),
        Preset(name: "Push-Up",             category: .strength, icon: "figure.strengthtraining.traditional", metric: .weightReps, muscles: "Chest, Triceps"),
        Preset(name: "Dip",                 category: .strength, icon: "figure.strengthtraining.traditional", metric: .weightReps, muscles: "Chest, Triceps"),
        Preset(name: "Cable Fly",           category: .strength, icon: "dumbbell.fill",                       metric: .weightReps, muscles: "Chest"),
        Preset(name: "Incline Bench Press", category: .strength, icon: "figure.strengthtraining.traditional", metric: .weightReps, muscles: "Upper Chest, Triceps"),

        // Cardio
        Preset(name: "Running",         category: .cardio, icon: "figure.run",             metric: .distanceTime, muscles: nil),
        Preset(name: "Walking",         category: .cardio, icon: "figure.walk",            metric: .distanceTime, muscles: nil),
        Preset(name: "Treadmill",       category: .cardio, icon: "figure.run",             metric: .distanceTime, muscles: nil),
        Preset(name: "Elliptical",      category: .cardio, icon: "figure.elliptical",      metric: .distanceTime, muscles: nil),
        Preset(name: "Rowing Machine",  category: .cardio, icon: "oar.2.crossed",          metric: .distanceTime, muscles: "Back, Arms, Core"),
        Preset(name: "Jump Rope",       category: .cardio, icon: "figure.jumprope",        metric: .duration,     muscles: nil),
        Preset(name: "Stair Climber",   category: .cardio, icon: "figure.stair.stepper",  metric: .duration,     muscles: "Quads, Glutes"),

        // Swimming
        Preset(name: "Freestyle",       category: .swimming, icon: "figure.pool.swim", metric: .lapsTime, muscles: "Full Body"),
        Preset(name: "Backstroke",      category: .swimming, icon: "figure.pool.swim", metric: .lapsTime, muscles: "Back, Shoulders"),
        Preset(name: "Breaststroke",    category: .swimming, icon: "figure.pool.swim", metric: .lapsTime, muscles: "Chest, Legs"),
        Preset(name: "Butterfly",       category: .swimming, icon: "figure.pool.swim", metric: .lapsTime, muscles: "Shoulders, Back"),
        Preset(name: "Mixed Strokes",   category: .swimming, icon: "figure.pool.swim", metric: .lapsTime, muscles: "Full Body"),
        Preset(name: "Open Water Swim", category: .swimming, icon: "figure.open.water.swim", metric: .distanceTime, muscles: "Full Body"),

        // Cycling
        Preset(name: "Road Cycling",      category: .cycling, icon: "bicycle",         metric: .distanceTime, muscles: "Quads, Glutes, Calves"),
        Preset(name: "Stationary Bike",   category: .cycling, icon: "bicycle",         metric: .distanceTime, muscles: "Quads, Glutes"),
        Preset(name: "Mountain Biking",   category: .cycling, icon: "bicycle",         metric: .distanceTime, muscles: "Full Body"),
        Preset(name: "Spin Class",        category: .cycling, icon: "bicycle",         metric: .duration,     muscles: "Quads, Glutes"),

        // Yoga & Flexibility
        Preset(name: "Yoga",             category: .yoga, icon: "figure.yoga",           metric: .duration, muscles: "Full Body"),
        Preset(name: "Pilates",          category: .yoga, icon: "figure.pilates",        metric: .duration, muscles: "Core, Full Body"),
        Preset(name: "Stretching",       category: .yoga, icon: "figure.flexibility",    metric: .duration, muscles: "Full Body"),
        Preset(name: "Foam Rolling",     category: .yoga, icon: "figure.flexibility",    metric: .duration, muscles: "Full Body"),

        // HIIT
        Preset(name: "HIIT",             category: .hiit, icon: "bolt.heart.fill",       metric: .duration, muscles: "Full Body"),
        Preset(name: "Tabata",           category: .hiit, icon: "bolt.heart.fill",       metric: .duration, muscles: "Full Body"),
        Preset(name: "Circuit Training", category: .hiit, icon: "arrow.triangle.2.circlepath", metric: .duration, muscles: "Full Body"),
        Preset(name: "CrossFit",         category: .hiit, icon: "bolt.heart.fill",       metric: .duration, muscles: "Full Body"),
        Preset(name: "Burpees",          category: .hiit, icon: "bolt.heart.fill",       metric: .weightReps, muscles: "Full Body"),
    ]

    static func seedIfNeeded(context: NSManagedObjectContext) {
        let req = CDActivity.fetchRequest()
        req.predicate = NSPredicate(format: "isPreset == true")
        guard (try? context.count(for: req)) == 0 else { return }

        for preset in presets {
            let activity = CDActivity(context: context)
            activity.id = UUID()
            activity.name = preset.name
            activity.category = preset.category.rawValue
            activity.icon = preset.icon
            activity.primaryMetric = preset.metric.rawValue
            activity.muscleGroups = preset.muscles
            activity.isPreset = true
            activity.createdAt = Date()
        }

        try? context.save()
    }
}
