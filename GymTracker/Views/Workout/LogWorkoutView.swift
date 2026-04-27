import SwiftUI
import CoreData

// MARK: - Main View

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
    @State private var durationMinutes: String = ""
    @State private var workoutDate: Date = Date()
    @State private var showingPicker = false
    @State private var startTime: Date = Date()
    @State private var confirmedPRs: [String] = []
    @State private var showingCelebration = false
    @State private var saveError: String? = nil

    var body: some View {
        NavigationStack {
            List {
                // Workout metadata
                Section {
                    metaSection
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                }
                .listRowBackground(Color.clear)

                // One section per activity
                ForEach($entries) { $entry in
                    EntrySection(entry: $entry, onDeleteEntry: {
                        entries.removeAll { $0.id == $entry.wrappedValue.id }
                    })
                }

                // Energy + Notes (only once there are entries)
                if !entries.isEmpty {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Energy Level: \(energyLevel)/10")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Slider(value: Binding(
                                get: { Double(energyLevel) },
                                set: { energyLevel = Int($0) }
                            ), in: 1...10, step: 1)
                            .tint(.orange)
                        }
                        .listRowBackground(Color(.secondarySystemBackground))

                        TextField("Workout notes (optional)", text: $notes, axis: .vertical)
                            .lineLimit(2...4)
                            .listRowBackground(Color(.secondarySystemBackground))
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(isDuplicate ? "Duplicate Workout" : (existingWorkout == nil ? "Log Workout" : "Edit Workout"))
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
                        Button(action: save) {
                            Text("Complete Workout")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(16)
                                .background(Color.accentColor)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
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
                startTime = Date()
                if let w = existingWorkout {
                    loadWorkout(w)
                    if isDuplicate {
                        workoutDate = Date()
                        durationMinutes = ""
                    }
                } else {
                    let fmt = DateFormatter()
                    fmt.dateFormat = "EEEE"
                    title = "\(fmt.string(from: Date())) Workout"
                }
            }
        }
    }

    // MARK: Meta section

    private var metaSection: some View {
        VStack(spacing: 12) {
            TextField("Workout Name", text: $title)
                .font(.headline)
                .padding(12)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            HStack(spacing: 12) {
                DatePicker("Workout date", selection: $workoutDate, displayedComponents: .date)
                    .labelsHidden()
                    .accessibilityLabel("Workout date")
                    .padding(12)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                HStack {
                    Image(systemName: "timer")
                        .foregroundStyle(.secondary)
                    TextField("Duration (min)", text: $durationMinutes)
                        .keyboardType(.numberPad)
                        .onChange(of: durationMinutes) { _, v in
                            let f = filterNumericInput(v, allowDecimal: false)
                            if f != v { durationMinutes = f }
                        }
                }
                .padding(12)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(.bottom, 4)
    }

    // MARK: Load (edit mode)

    private func loadWorkout(_ w: CDWorkout) {
        let data = WorkoutEditor.load(from: w)
        title = data.title
        workoutDate = data.date
        durationMinutes = data.durationMinutes
        energyLevel = data.energyLevel
        notes = data.notes
        entries = data.entries
    }

    // MARK: Save

    private func save() {
        let data = WorkoutEditor.WorkoutData(
            title: title,
            date: workoutDate,
            durationMinutes: durationMinutes,
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
                startTime: startTime
            )
        } catch {
            context.rollback()
            saveError = error.localizedDescription
            return
        }

        let isNew = existingWorkout == nil || isDuplicate
        Task {
            await WorkoutHealthKitManager.shared.syncWorkout(result.savedWorkout, isNew: isNew)
        }

        if result.newPRNames.isEmpty {
            dismiss()
        } else {
            confirmedPRs = result.newPRNames
            showingCelebration = true
        }
    }
}

// MARK: - Entry Section

struct EntrySection: View {
    @Binding var entry: LiveEntry
    let onDeleteEntry: () -> Void

    var body: some View {
        Section {
            setColumnHeader
                .deleteDisabled(true)
                .listRowBackground(Color(.secondarySystemBackground))

            ForEach(Array(entry.sets.enumerated()), id: \.element.id) { idx, _ in
                LiveSetRow(
                    set: $entry.sets[idx],
                    metric: entry.activity.metric,
                    setNumber: idx + 1
                )
                .listRowBackground(Color(.secondarySystemBackground))
            }
            .onDelete { indices in
                guard entry.sets.count > indices.count else { return }
                entry.sets.remove(atOffsets: indices)
            }

            Button {
                let newSet = entry.sets.last.map { LiveSet.copying($0) } ?? LiveSet()
                entry.sets.append(newSet)
            } label: {
                Label("Add Set", systemImage: "plus")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.accentColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(Color.accentColor.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .deleteDisabled(true)
            .listRowBackground(Color(.secondarySystemBackground))
        } header: {
            HStack {
                Image(systemName: entry.activity.activityCategory.icon)
                    .foregroundStyle(entry.activity.activityCategory.color)
                Text(entry.activity.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .textCase(nil)
                    .foregroundStyle(.primary)
                Spacer()
                Button(role: .destructive, action: onDeleteEntry) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.body)
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 4)
        }
    }

    @ViewBuilder
    private var setColumnHeader: some View {
        HStack {
            Text("Set")
                .frame(width: 36, alignment: .leading)
            Spacer()
            switch entry.activity.metric {
            case .weightReps:
                Text(Units.weightUnit).frame(maxWidth: .infinity, alignment: .center)
                Text("Reps").frame(maxWidth: .infinity, alignment: .center)
            case .distanceTime:
                Text(Units.distanceUnit).frame(maxWidth: .infinity, alignment: .center)
                Text("min : sec").frame(maxWidth: .infinity, alignment: .center)
            case .lapsTime:
                Text("Laps").frame(maxWidth: .infinity, alignment: .center)
                Text("min : sec").frame(maxWidth: .infinity, alignment: .center)
            case .duration:
                Text("min").frame(maxWidth: .infinity, alignment: .center)
                Text("sec").frame(maxWidth: .infinity, alignment: .center)
            case .custom:
                Text("Value").frame(maxWidth: .infinity, alignment: .center)
            }
            Image(systemName: "trophy")
                .frame(width: 36)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .fontWeight(.medium)
    }
}

// MARK: - Live Set Row

struct LiveSetRow: View {
    @Binding var set: LiveSet
    let metric: PrimaryMetric
    let setNumber: Int

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Text("\(setNumber)")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .frame(width: 36, alignment: .leading)

            switch metric {
            case .weightReps:
                inputField($set.weightKg, placeholder: "0", keyboard: .decimalPad)
                inputField($set.reps, placeholder: "0", keyboard: .numberPad)
            case .distanceTime:
                inputField($set.distanceKm, placeholder: "0.0", keyboard: .decimalPad)
                HStack(spacing: 4) {
                    inputField($set.durationMinutes, placeholder: "00", keyboard: .numberPad)
                    Text(":").foregroundStyle(.secondary)
                    inputField($set.durationSeconds, placeholder: "00", keyboard: .numberPad)
                }
            case .lapsTime:
                inputField($set.laps, placeholder: "0", keyboard: .numberPad)
                HStack(spacing: 4) {
                    inputField($set.durationMinutes, placeholder: "00", keyboard: .numberPad)
                    Text(":").foregroundStyle(.secondary)
                    inputField($set.durationSeconds, placeholder: "00", keyboard: .numberPad)
                }
            case .duration:
                inputField($set.durationMinutes, placeholder: "00", keyboard: .numberPad)
                inputField($set.durationSeconds, placeholder: "00", keyboard: .numberPad)
            case .custom:
                inputField($set.customValue, placeholder: "0", keyboard: .decimalPad)
                inputField($set.customLabel, placeholder: "unit", keyboard: .default)
            }

            Button {
                set.isPRAttempt.toggle()
            } label: {
                Image(systemName: set.isPRAttempt ? "trophy.fill" : "trophy")
                    .foregroundStyle(set.isPRAttempt ? .yellow : .secondary)
                    .font(.subheadline)
                    .frame(width: 36)
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.plain)
        }
    }

    private func inputField(_ binding: Binding<String>, placeholder: String, keyboard: UIKeyboardType) -> some View {
        let allowDecimal = keyboard == .decimalPad
        let shouldFilter = keyboard == .numberPad || keyboard == .decimalPad
        return TextField(placeholder, text: binding)
            .keyboardType(keyboard)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Color(.tertiarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .onChange(of: binding.wrappedValue) { _, newValue in
                guard shouldFilter else { return }
                let filtered = filterNumericInput(newValue, allowDecimal: allowDecimal)
                if filtered != newValue { binding.wrappedValue = filtered }
            }
    }
}
