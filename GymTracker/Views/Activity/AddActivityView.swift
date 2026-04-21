import SwiftUI

struct AddActivityView: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var category: ActivityCategory = .strength
    @State private var metric: PrimaryMetric = .weightReps
    @State private var muscleGroups: String = ""
    @State private var instructions: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Activity Details") {
                    TextField("Name", text: $name)

                    Picker("Category", selection: $category) {
                        ForEach(ActivityCategory.allCases) { cat in
                            Label(cat.displayName, systemImage: cat.icon)
                                .tag(cat)
                        }
                    }
                    .onChange(of: category) { _, newValue in
                        metric = newValue.defaultMetric
                    }

                    Picker("Tracking Metric", selection: $metric) {
                        ForEach(PrimaryMetric.allCases) { m in
                            Text(m.displayName).tag(m)
                        }
                    }
                }

                Section("Optional Info") {
                    TextField("Muscle Groups (e.g. Chest, Triceps)", text: $muscleGroups)
                    TextField("Instructions or notes", text: $instructions, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section {
                    HStack {
                        Text("Preview")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        HStack(spacing: 8) {
                            Image(systemName: category.icon)
                                .foregroundStyle(category.color)
                            Text(name.isEmpty ? "Activity Name" : name)
                                .fontWeight(.medium)
                        }
                    }
                }
            }
            .navigationTitle("New Activity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { save() }
                        .fontWeight(.semibold)
                        .disabled(name.isEmpty)
                }
            }
        }
    }

    private func save() {
        let activity = CDActivity(context: context)
        activity.id = UUID()
        activity.name = name.trimmingCharacters(in: .whitespaces)
        activity.category = category.rawValue
        activity.icon = category.icon
        activity.primaryMetric = metric.rawValue
        activity.muscleGroups = muscleGroups.isEmpty ? nil : muscleGroups
        activity.instructions = instructions.isEmpty ? nil : instructions
        activity.isPreset = false
        activity.createdAt = Date()
        try? context.save()
        dismiss()
    }
}
