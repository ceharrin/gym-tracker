import SwiftUI
import CoreData

// MARK: - In-memory models for live session

struct LiveSet: Identifiable {
    var id = UUID()
    var reps: String = ""
    var weightKg: String = ""
    var durationMinutes: String = ""
    var durationSeconds: String = ""
    var distanceKm: String = ""
    var laps: String = ""
    var customValue: String = ""
    var customLabel: String = ""
    var notes: String = ""
    var isPRAttempt: Bool = false
    var isWarmup: Bool = false

    static func copying(_ other: LiveSet) -> LiveSet {
        var s = LiveSet()
        s.weightKg = other.weightKg
        s.reps = other.reps
        s.distanceKm = other.distanceKm
        s.durationMinutes = other.durationMinutes
        s.durationSeconds = other.durationSeconds
        s.laps = other.laps
        s.customValue = other.customValue
        s.customLabel = other.customLabel
        // isPRAttempt and isWarmup intentionally NOT copied — each set earns its own state
        return s
    }
}

struct LiveEntry: Identifiable {
    var id = UUID()
    var activity: CDActivity
    var sets: [LiveSet] = [LiveSet()]
    var notes: String = ""
}

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
    @State private var showingFinish = false
    @State private var startTime: Date = Date()
    @State private var confirmedPRs: [String] = []
    @State private var showingCelebration = false
    @State private var saveError: String? = nil

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 16) {
                        metaSection
                        entriesList
                        addExerciseButton
                        if !entries.isEmpty {
                            finishSection
                                .id("finishSection")
                        }
                    }
                    .padding()
                }
                .onChange(of: entries.count) { _, count in
                    guard count > 0 else { return }
                    withAnimation {
                        proxy.scrollTo("finishSection", anchor: .bottom)
                    }
                }
            }
            .navigationTitle(isDuplicate ? "Duplicate Workout" : (existingWorkout == nil ? "Log Workout" : "Edit Workout"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
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

    // MARK: Sections

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
    }

    private var entriesList: some View {
        ForEach($entries) { $entry in
            LiveEntryCard(entry: $entry, onDelete: {
                entries.removeAll { $0.id == entry.id }
            })
        }
    }

    private var addExerciseButton: some View {
        Button {
            showingPicker = true
        } label: {
            Label("Add Exercise / Activity", systemImage: "plus")
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity)
                .padding(14)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    private var finishSection: some View {
        VStack(spacing: 12) {
            Divider()

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

            TextField("Workout notes (optional)", text: $notes, axis: .vertical)
                .lineLimit(2...4)
                .padding(12)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            Button {
                save()
            } label: {
                Text("Finish Workout")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(16)
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    // MARK: Load (edit mode)

    private func loadWorkout(_ w: CDWorkout) {
        title = w.title
        workoutDate = w.date
        durationMinutes = w.durationMinutes > 0 ? "\(w.durationMinutes)" : ""
        energyLevel = Int(w.energyLevel)
        notes = w.notes ?? ""
        entries = w.sortedEntries.compactMap { entry -> LiveEntry? in
            guard let activity = entry.activity else { return nil }
            let liveSets: [LiveSet] = entry.sortedSets.map { set in
                var s = LiveSet()
                s.weightKg   = set.weightKg > 0      ? String(format: "%.1f", Units.weightValue(fromKg: set.weightKg))       : ""
                s.reps       = set.reps > 0           ? "\(set.reps)"                                                         : ""
                s.distanceKm = set.distanceMeters > 0 ? String(format: "%.2f", Units.distanceValue(fromMeters: set.distanceMeters)) : ""
                if set.durationSeconds > 0 {
                    s.durationMinutes = "\(set.durationSeconds / 60)"
                    s.durationSeconds = String(format: "%02d", set.durationSeconds % 60)
                }
                s.laps        = set.laps > 0          ? "\(set.laps)"                                                         : ""
                s.customValue = set.customValue > 0   ? String(format: "%.1f", set.customValue)                               : ""
                s.customLabel = set.customLabel ?? ""
                s.notes       = set.notes ?? ""
                s.isWarmup    = set.isWarmup
                return s
            }
            return LiveEntry(activity: activity, sets: liveSets.isEmpty ? [LiveSet()] : liveSets, notes: entry.notes ?? "")
        }
    }

    // MARK: Save

    private func save() {
        // Detect PRs before any Core Data mutations (history must be intact).
        let newPRNames = detectPRs()

        let workout: CDWorkout
        if let existing = existingWorkout, !isDuplicate {
            workout = existing
            for entry in existing.sortedEntries {
                entry.sortedSets.forEach { context.delete($0) }
                context.delete(entry)
            }
        } else {
            workout = CDWorkout(context: context)
            workout.id = UUID()
        }

        workout.date = workoutDate
        workout.title = title.isEmpty ? "Workout" : title
        workout.durationMinutes = Int32(durationMinutes) ?? (existingWorkout == nil ? Int32(Date().timeIntervalSince(startTime) / 60) : workout.durationMinutes)
        workout.energyLevel = Int16(energyLevel)
        workout.notes = notes.isEmpty ? nil : notes

        for (idx, liveEntry) in entries.enumerated() {
            let entry = CDWorkoutEntry(context: context)
            entry.id = UUID()
            entry.orderIndex = Int16(idx)
            entry.activity = liveEntry.activity
            entry.notes = liveEntry.notes.isEmpty ? nil : liveEntry.notes
            entry.workout = workout

            for (setIdx, liveSet) in liveEntry.sets.enumerated() {
                let set = CDEntrySet(context: context)
                set.id = UUID()
                set.setNumber = Int16(setIdx + 1)
                set.weightKg = Units.kgFromInput(Double(liveSet.weightKg) ?? 0)
                set.reps = Int32(liveSet.reps) ?? 0
                set.distanceMeters = Units.metersFromInput(Double(liveSet.distanceKm) ?? 0)
                set.durationSeconds = durationToSeconds(liveSet)
                set.laps = Int32(liveSet.laps) ?? 0
                set.customValue = Double(liveSet.customValue) ?? 0
                set.customLabel = liveSet.customLabel.isEmpty ? nil : liveSet.customLabel
                set.notes = liveSet.notes.isEmpty ? nil : liveSet.notes
                set.isWarmup = liveSet.isWarmup
                set.entry = entry
            }
        }

        do {
            try context.save()
        } catch {
            context.rollback()
            saveError = error.localizedDescription
            return
        }

        if newPRNames.isEmpty {
            dismiss()
        } else {
            confirmedPRs = newPRNames
            showingCelebration = true
        }
    }

    /// Check each PR-attempt set against historical records.
    /// Returns the names of activities where a genuine new record was set.
    private func detectPRs() -> [String] {
        var names: [String] = []
        for liveEntry in entries {
            let prSets = liveEntry.sets.filter(\.isPRAttempt)
            guard !prSets.isEmpty else { continue }
            let history = historicalSets(for: liveEntry.activity, excludingWorkout: existingWorkout)
            let metric = liveEntry.activity.metric
            let hasNewPR = prSets.contains { isNewPersonalRecord(liveSet: $0, metric: metric, against: history) }
            if hasNewPR, !names.contains(liveEntry.activity.name) {
                names.append(liveEntry.activity.name)
            }
        }
        return names
    }

    /// Fetch all historical CDEntrySets for an activity, optionally excluding a specific workout.
    private func historicalSets(for activity: CDActivity, excludingWorkout: CDWorkout? = nil) -> [CDEntrySet] {
        let request = CDWorkoutEntry.fetchRequest()
        request.predicate = NSPredicate(format: "activity == %@", activity)
        let entries = (try? context.fetch(request)) ?? []
        return entries
            .filter { excludingWorkout == nil || $0.workout != excludingWorkout }
            .flatMap(\.sortedSets)
    }

    private func durationToSeconds(_ set: LiveSet) -> Int32 {
        let m = Int32(set.durationMinutes) ?? 0
        let s = Int32(set.durationSeconds) ?? 0
        return m * 60 + s
    }
}

// MARK: - Live Entry Card

struct LiveEntryCard: View {
    @Binding var entry: LiveEntry
    let onDelete: () -> Void

    @State private var isEditing = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            entryHeader
            Divider()
            setHeader
            ForEach(entry.sets.indices, id: \.self) { idx in
                LiveSetRow(
                    set: $entry.sets[idx],
                    metric: entry.activity.metric,
                    setNumber: idx + 1,
                    canDelete: isEditing,
                    onDelete: {
                        guard entry.sets.count > 1 else { return }
                        entry.sets.remove(at: idx)
                    }
                )
            }
            addSetButton
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var entryHeader: some View {
        HStack {
            Image(systemName: entry.activity.activityCategory.icon)
                .foregroundStyle(entry.activity.activityCategory.color)
            Text(entry.activity.name)
                .font(.headline)
            Spacer()
            Button(isEditing ? "Done" : "Edit") {
                isEditing.toggle()
            }
            .font(.subheadline)
            .foregroundStyle(isEditing ? Color.accentColor : .secondary)
            Button(role: .destructive, action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var setHeader: some View {
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
            Text("W")
                .frame(width: 28)
            Image(systemName: "trophy")
                .frame(width: 36)
            if isEditing {
                Color.clear.frame(width: 28)
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .fontWeight(.medium)
    }

    private var addSetButton: some View {
        Button {
            let newSet = entry.sets.last.map { LiveSet.copying($0) } ?? LiveSet()
            entry.sets.append(newSet)
        } label: {
            Label("Add Set", systemImage: "plus")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(Color.accentColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.accentColor.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

}

// MARK: - Live Set Row

struct LiveSetRow: View {
    @Binding var set: LiveSet
    let metric: PrimaryMetric
    let setNumber: Int
    var canDelete: Bool = false
    var onDelete: (() -> Void)? = nil

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

            // Warm-up toggle
            Button {
                set.isWarmup.toggle()
            } label: {
                Text("W")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(set.isWarmup ? .white : .secondary)
                    .frame(width: 24, height: 24)
                    .background(set.isWarmup ? Color.orange : Color.clear)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(set.isWarmup ? Color.clear : Color.secondary.opacity(0.4), lineWidth: 1))
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.plain)

            // PR attempt toggle
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

            if canDelete, let onDelete {
                Button(action: onDelete) {
                    Image(systemName: "minus.circle.fill")
                        .foregroundStyle(.red)
                        .font(.body)
                        .frame(width: 28)
                }
                .buttonStyle(.plain)
            }
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
