import SwiftUI
import CoreData

struct LogWorkoutView: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss

    let existingWorkout: CDWorkout?
    let isDuplicate: Bool

    init(workout: CDWorkout? = nil, isDuplicate: Bool = false) {
        self.existingWorkout = workout
        self.isDuplicate = isDuplicate
    }

    @State private var title: String = ""
    @State private var entries: [LiveEntry] = []
    @State private var notes: String = ""
    @State private var energyLevel: Int = 7
    @State private var workoutDate: Date = Date()
    @State private var showingPicker = false
    @State private var startTime: Date = Date()
    @State private var confirmedPRs: [String] = []
    @State private var showingCelebration = false
    @State private var saveError: String? = nil

    var body: some View {
        NavigationStack {
            List {
                Section {
                    WorkoutMetaSection(
                        title: $title,
                        workoutDate: $workoutDate,
                        durationText: durationText,
                        statusText: workoutStatusText
                    )
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                }
                .listRowBackground(Color.clear)

                ForEach($entries) { $entry in
                    EntrySection(entry: $entry, onDeleteEntry: {
                        entries.removeAll { $0.id == $entry.wrappedValue.id }
                    })
                }

                if !entries.isEmpty {
                    WorkoutFinishingSection(notes: $notes, energyLevel: $energyLevel)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 8) {
                    Button {
                        showingPicker = true
                    } label: {
                        Label("Add Exercise / Activity", systemImage: "plus.circle.fill")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(14)
                            .background(Color.accentColor)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)

                    if !entries.isEmpty {
                        HStack(spacing: 10) {
                            if showsSaveProgressButton {
                                Button {
                                    save(intent: .saveProgress)
                                } label: {
                                    Text("Save Progress")
                                        .font(.headline)
                                        .frame(maxWidth: .infinity)
                                        .padding(16)
                                        .background(Color(.secondarySystemBackground))
                                        .foregroundStyle(Color.accentColor)
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                }
                            }

                            Button {
                                save(intent: .complete)
                            } label: {
                                Text(primarySaveButtonTitle)
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding(16)
                                    .background(Color.accentColor)
                                    .foregroundStyle(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
                .background(.regularMaterial)
            }
            .sheet(isPresented: $showingPicker) {
                ExercisePickerView { activity in
                    entries.append(LiveEntry(activity: activity))
                }
            }
            .fullScreenCover(isPresented: $showingCelebration) {
                PRCelebrationView(activityNames: confirmedPRs) {
                    showingCelebration = false
                    dismiss()
                }
            }
            .alert("Couldn't Save Workout", isPresented: Binding(
                get: { saveError != nil },
                set: { if !$0 { saveError = nil } }
            )) {
                Button("OK", role: .cancel) { saveError = nil }
            } message: {
                Text(saveError ?? "An unknown error occurred. Your workout was not saved.")
            }
            .onAppear {
                configureInitialState(now: Date())
            }
        }
    }

    // MARK: Save

    private func save(intent: WorkoutEditor.SaveIntent) {
        let completedAt = Date()
        let data = WorkoutEditor.WorkoutData(
            title: title,
            date: workoutDate,
            energyLevel: energyLevel,
            notes: notes,
            entries: entries
        )
        let result: WorkoutEditor.SaveResult
        do {
            result = try WorkoutEditor.save(
                data: data,
                context: context,
                existingWorkout: existingWorkout,
                isDuplicate: isDuplicate,
                startTime: startTime,
                intent: intent,
                completedAt: completedAt
            )
        } catch {
            context.rollback()
            saveError = error.localizedDescription
            return
        }

        if intent == .saveProgress || result.newPRNames.isEmpty {
            dismiss()
        } else {
            confirmedPRs = result.newPRNames
            showingCelebration = true
        }
    }

    private var navigationTitle: String {
        if isDuplicate { return "Duplicate Workout" }
        return existingWorkout == nil ? "Log Workout" : "Edit Workout"
    }

    private func configureInitialState(now: Date) {
        startTime = now
        let initialData = WorkoutEditor.initialData(
            existingWorkout: existingWorkout,
            isDuplicate: isDuplicate,
            now: now
        )
        startTime = resolvedStartTime(now: now)
        title = initialData.title
        workoutDate = initialData.date
        energyLevel = initialData.energyLevel
        notes = initialData.notes
        entries = initialData.entries
    }

    private var durationText: String {
        if let existingWorkout, existingWorkout.isCompleted, !isDuplicate {
            return existingWorkout.durationMinutes > 0 ? "\(existingWorkout.durationMinutes) min" : "0 min"
        }
        let elapsed = max(0, Int(Date().timeIntervalSince(startTime) / 60))
        return "\(elapsed) min"
    }

    private var workoutStatusText: String? {
        if let existingWorkout, !existingWorkout.isCompleted, !isDuplicate {
            return "Workout in progress"
        }
        return nil
    }

    private func resolvedStartTime(now: Date) -> Date {
        guard let existingWorkout else { return now }
        if isDuplicate { return now }
        return existingWorkout.startedAt ?? now
    }

    private var showsSaveProgressButton: Bool {
        existingWorkout?.isCompleted != true || isDuplicate
    }

    private var primarySaveButtonTitle: String {
        existingWorkout?.isCompleted == true && !isDuplicate ? "Save Changes" : "Complete Workout"
    }
}
