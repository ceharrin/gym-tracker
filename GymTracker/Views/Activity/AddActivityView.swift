import SwiftUI

struct AddActivityView: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss

    let existingActivity: CDActivity?

    init(activity: CDActivity? = nil) {
        self.existingActivity = activity
    }

    @State private var name: String = ""
    @State private var category: ActivityCategory = .strength
    @State private var metric: PrimaryMetric = .weightReps
    @State private var muscleGroups: String = ""
    @State private var instructions: String = ""
    @State private var persistenceAlert: PersistenceAlertState? = nil
    @State private var showingDeleteAlert = false

    private var availableMetrics: [PrimaryMetric] {
        ActivityEditor.availableMetrics(for: category)
    }

    private var isEditing: Bool {
        existingActivity != nil
    }

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
                        let allowed = ActivityEditor.availableMetrics(for: newValue)
                        if !allowed.contains(metric) {
                            metric = allowed.contains(newValue.defaultMetric) ? newValue.defaultMetric : (allowed.first ?? .weightReps)
                        }
                    }

                    Picker("Tracking Metric", selection: $metric) {
                        ForEach(availableMetrics) { m in
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

                if isEditing {
                    Section {
                        Button("Delete Activity", role: .destructive) {
                            showingDeleteAlert = true
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Activity" : "New Activity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Add") { save() }
                        .fontWeight(.semibold)
                        .disabled(name.isEmpty)
                }
            }
            .alert("Delete Activity?", isPresented: $showingDeleteAlert) {
                Button("Delete", role: .destructive) { delete() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This custom activity will be permanently deleted.")
            }
            .persistenceErrorAlert($persistenceAlert)
            .onAppear(perform: loadExistingActivity)
        }
    }

    private func save() {
        do {
            _ = try ActivityEditor.save(
                data: .init(
                    name: name,
                    category: category,
                    metric: metric,
                    muscleGroups: muscleGroups,
                    instructions: instructions
                ),
                context: context,
                existingActivity: existingActivity
            )
            dismiss()
        } catch {
            context.rollback()
            persistenceAlert = PersistenceAlertState(title: "Couldn't Save Activity", error: error)
        }
    }

    private func delete() {
        guard let existingActivity else { return }
        do {
            try ActivityEditor.delete(existingActivity, from: context)
            dismiss()
        } catch {
            context.rollback()
            persistenceAlert = PersistenceAlertState(title: "Couldn't Delete Activity", error: error)
        }
    }

    private func loadExistingActivity() {
        guard let existingActivity else { return }
        name = existingActivity.name
        category = existingActivity.activityCategory
        metric = existingActivity.metric
        muscleGroups = existingActivity.muscleGroups ?? ""
        instructions = existingActivity.instructions ?? ""
    }
}
