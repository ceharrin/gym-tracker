import SwiftUI
import CoreData

private struct PRCelebrationPayload: Identifiable {
    let id = UUID()
    let activityNames: [String]
}

struct LogWorkoutView: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss

    let existingWorkout: CDWorkout?
    let isDuplicate: Bool
    private let wrapsInNavigationStack: Bool

    init(workout: CDWorkout? = nil, isDuplicate: Bool = false, wrapsInNavigationStack: Bool = true) {
        self.existingWorkout = workout
        self.isDuplicate = isDuplicate
        self.wrapsInNavigationStack = wrapsInNavigationStack
    }

    @State private var title: String = ""
    @State private var entries: [LiveEntry] = []
    @State private var notes: String = ""
    @State private var energyLevel: Int = 7
    @State private var workoutDate: Date = Date()
    @State private var showingPicker = false
    @State private var startTime: Date = Date()
    @State private var celebrationPayload: PRCelebrationPayload?
    @State private var showingCompleteConfirmation = false
    @State private var pendingConfirmedCompletion = false
    @State private var saveError: String? = nil
    @State private var completedDuringSession = false
    @State private var completedDurationMinutes: Int32? = nil

    var body: some View {
        if wrapsInNavigationStack {
            NavigationStack {
                content
            }
        } else {
            content
        }
    }

    private var content: some View {
        Group {
            editorContent
        }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
        }
        .safeAreaInset(edge: .bottom) {
            bottomActions
        }
        .sheet(isPresented: $showingPicker) {
            ExercisePickerView { activity in
                entries.insert(LiveEntry(activity: activity), at: 0)
            }
        }
        .fullScreenCover(item: $celebrationPayload) { payload in
            PRCelebrationView(activityNames: payload.activityNames) {
                celebrationPayload = nil
                DispatchQueue.main.async {
                    dismiss()
                }
            }
        }
        .alert("Complete Workout?", isPresented: $showingCompleteConfirmation) {
            Button("Cancel", role: .cancel) {
                pendingConfirmedCompletion = false
                showingCompleteConfirmation = false
            }
            Button("Complete", role: .destructive) {
                pendingConfirmedCompletion = true
            }
        } message: {
            Text("This will mark the workout as finished.")
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
        .onChange(of: showingCompleteConfirmation) { _, isShowing in
            guard !isShowing, pendingConfirmedCompletion else { return }
            pendingConfirmedCompletion = false
            save(intent: .complete)
        }
    }

    private var editorContent: some View {
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
    }

    private var bottomActions: some View {
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
                        if shouldConfirmCompletion {
                            showingCompleteConfirmation = true
                        } else {
                            save(intent: .complete)
                        }
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

        if intent == .complete {
            completedDuringSession = true
            completedDurationMinutes = result.savedWorkout.durationMinutes
        }

        if intent == .saveProgress || result.newPRNames.isEmpty {
            dismiss()
        } else {
            celebrationPayload = PRCelebrationPayload(activityNames: result.newPRNames)
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
        if isEffectivelyCompleted {
            let minutes = Int(completedDurationMinutes ?? existingWorkout?.durationMinutes ?? 0)
            return "\(minutes) min"
        }
        let elapsed = max(0, Int(Date().timeIntervalSince(startTime) / 60))
        return "\(elapsed) min"
    }

    private var workoutStatusText: String? {
        isEffectivelyCompleted ? nil : "Workout in progress"
    }

    private func resolvedStartTime(now: Date) -> Date {
        guard let existingWorkout else { return now }
        if isDuplicate { return now }
        return existingWorkout.startedAt ?? now
    }

    private var showsSaveProgressButton: Bool {
        !isEffectivelyCompleted
    }

    private var primarySaveButtonTitle: String {
        isEffectivelyCompleted && !isDuplicate ? "Save Changes" : "Complete Workout"
    }

    private var isEffectivelyCompleted: Bool {
        Self.isWorkoutCompleted(
            existingWorkout: existingWorkout,
            isDuplicate: isDuplicate,
            completedDuringSession: completedDuringSession
        )
    }

    private var shouldConfirmCompletion: Bool {
        Self.shouldConfirmCompletion(
            existingWorkout: existingWorkout,
            isDuplicate: isDuplicate,
            completedDuringSession: completedDuringSession
        )
    }

    static func isWorkoutCompleted(
        existingWorkout: CDWorkout?,
        isDuplicate: Bool,
        completedDuringSession: Bool
    ) -> Bool {
        guard !isDuplicate else { return false }
        return completedDuringSession || existingWorkout?.isCompleted == true
    }

    static func shouldConfirmCompletion(
        existingWorkout: CDWorkout?,
        isDuplicate: Bool,
        completedDuringSession: Bool
    ) -> Bool {
        !isWorkoutCompleted(
            existingWorkout: existingWorkout,
            isDuplicate: isDuplicate,
            completedDuringSession: completedDuringSession
        )
    }
}
