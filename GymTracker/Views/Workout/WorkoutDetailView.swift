import SwiftUI

struct WorkoutDetailMetadataPresentation {
    let date: Date
    let statusLabel: String?
    let durationText: String
    let filledEnergyBoltCount: Int
    let totalEnergyBoltCount = 5

    init(workout: CDWorkout) {
        date = workout.date
        statusLabel = workout.statusLabel
        durationText = workout.formattedDuration ?? "—"
        filledEnergyBoltCount = Int(workout.energyLevel) / 2
    }
}

struct WorkoutDetailView: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var workout: CDWorkout

    @State private var showingEdit = false
    @State private var showingDuplicate = false
    @State private var showingDeleteAlert = false
    @State private var isDeleting = false
    @State private var shareURL: URL? = nil
    @State private var showingShareSheet = false
    @State private var shareError: String? = nil
    @State private var isExportingShare = false
    @State private var persistenceAlert: PersistenceAlertState? = nil
    @State private var showingWorkoutTotals = false

    var body: some View {
        Group {
            if isDeleting || !workout.canRenderInUI {
                Color.clear
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        metaCard
                        workoutTotalsButton
                        ForEach(workout.sortedEntries) { entry in
                            EntryDetailCard(entry: entry)
                        }
                        if let notes = workout.notes, !notes.isEmpty {
                            notesCard(notes)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle(workout.canRenderInUI ? workout.title : "")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Edit") { showingEdit = true }
                    Button("Duplicate") { showingDuplicate = true }
                    Button {
                        Task { @MainActor in
                            guard !isExportingShare else { return }
                            isExportingShare = true
                            // Let the menu dismiss before presenting the share sheet.
                            await Task.yield()
                            defer { isExportingShare = false }

                            do {
                                shareURL = try WorkoutExporter.exportHTML(for: workout)
                                showingShareSheet = true
                            } catch {
                                shareError = error.localizedDescription
                            }
                        }
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    .disabled(isExportingShare)
                    Divider()
                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .alert("Delete Workout?", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                context.delete(workout)
                do {
                    try context.saveIfChanged()
                    isDeleting = true
                    dismiss()
                } catch {
                    context.rollback()
                    persistenceAlert = PersistenceAlertState(title: "Couldn't Delete Workout", error: error)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This workout and all its sets will be permanently deleted.")
        }
        .sheet(isPresented: $showingEdit) {
            LogWorkoutView(workout: workout)
        }
        .sheet(isPresented: $showingDuplicate) {
            LogWorkoutView(workout: workout, isDuplicate: true)
        }
        .sheet(isPresented: $showingShareSheet, onDismiss: {
            shareURL = nil
        }) {
            if let url = shareURL {
                ShareSheet(items: [url])
            }
        }
        .sheet(isPresented: $showingWorkoutTotals) {
            WorkoutTotalsDetailSheet(workout: workout)
                .presentationDetents([.medium, .large])
        }
        .alert("Couldn't Export Workout", isPresented: Binding(
            get: { shareError != nil },
            set: { if !$0 { shareError = nil } }
        )) {
            Button("OK", role: .cancel) { shareError = nil }
        } message: {
            Text(shareError ?? "An unknown error occurred.")
        }
        .persistenceErrorAlert($persistenceAlert)
    }

    private var metaCard: some View {
        WorkoutDetailMetadataCard(presentation: WorkoutDetailMetadataPresentation(workout: workout))
    }

    @ViewBuilder
    private var workoutTotalsButton: some View {
        let presentation = WorkoutTotalsPresentation(workout: workout)
        if presentation.hasTotals {
            Button {
                showingWorkoutTotals = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "sum")
                        .font(.subheadline)
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 32, height: 32)
                        .background(Color.accentColor.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(presentation.buttonTitle)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                        Text(presentation.buttonSubtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.tertiary)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
            .accessibilityHint("Shows workout total details")
        }
    }

    private func notesCard(_ notes: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Notes", systemImage: "note.text")
                .font(.subheadline)
                .fontWeight(.semibold)
            Text(notes)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Metadata

private struct WorkoutDetailMetadataCard: View {
    let presentation: WorkoutDetailMetadataPresentation

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let statusLabel = presentation.statusLabel {
                Text(statusLabel)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.accentColor.opacity(0.12))
                    .foregroundStyle(Color.accentColor)
                    .clipShape(Capsule())
            }

            HStack(spacing: 0) {
                metaDateStat
                Divider().frame(height: 40)
                metaTextStat(label: "Duration", value: presentation.durationText)
                Divider().frame(height: 40)
                metaEnergyStat
            }
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var metaDateStat: some View {
        VStack(spacing: 4) {
            Text(presentation.date, style: .date)
                .font(.subheadline)
                .fontWeight(.semibold)
            Text("Date")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func metaTextStat(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var metaEnergyStat: some View {
        VStack(spacing: 4) {
            HStack(spacing: 2) {
                ForEach(0..<presentation.totalEnergyBoltCount, id: \.self) { index in
                    Image(systemName: index < presentation.filledEnergyBoltCount ? "bolt.fill" : "bolt")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
            Text("Energy")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Workout Totals

private struct WorkoutTotalsDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var workout: CDWorkout
    @State private var showingMuscleCoverageDetails = false

    private var presentation: WorkoutTotalsPresentation {
        WorkoutTotalsPresentation(workout: workout)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(presentation.metrics) { metric in
                        if metric == .muscleCoverage {
                            Button {
                                showingMuscleCoverageDetails = true
                            } label: {
                                WorkoutTotalDetailRow(metric: metric, workout: workout)
                            }
                            .buttonStyle(.plain)
                            .accessibilityHint("Shows muscle coverage details")
                        } else {
                            WorkoutTotalDetailRow(metric: metric, workout: workout)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingMuscleCoverageDetails) {
                MuscleCoverageDetailSheet(workout: workout)
                    .presentationDetents([.medium, .large])
            }
            .navigationTitle(presentation.buttonTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

private struct WorkoutTotalDetailRow: View {
    let metric: WorkoutTotalMetric
    @ObservedObject var workout: CDWorkout

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: metric.icon)
                .font(.subheadline)
                .foregroundStyle(Color.accentColor)
                .frame(width: 32, height: 32)
                .background(Color.accentColor.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 3) {
                Text(metric.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                if metric == .muscleCoverage {
                    Text(workout.muscleCoverage.detailText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Text(metric.formattedValue(from: workout))
                .font(.headline)
                .monospacedDigit()
                .foregroundStyle(.primary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Muscle Coverage

private struct MuscleCoverageDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var workout: CDWorkout

    private var coverage: MuscleCoverage {
        workout.muscleCoverage
    }

    private var contributingEntries: [CDWorkoutEntry] {
        workout.sortedEntries.filter { entry in
            guard entry.activity?.activityCategory == .strength else { return false }
            guard !entry.sortedSets.isEmpty else { return false }
            return !(entry.activity?.muscleGroups ?? "").isEmpty
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(coverage.displayText)
                                .font(.system(size: 42, weight: .bold, design: .rounded))
                                .monospacedDigit()
                            Text("of major muscle groups")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        SwiftUI.ProgressView(value: Double(coverage.targetedCount), total: Double(coverage.totalCount))
                            .tint(Color.accentColor)

                        Text(coverage.detailText)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                Section("Targeted") {
                    if coverage.targetedGroups.isEmpty {
                        Text("No strength muscle groups were logged for this workout.")
                            .foregroundStyle(.secondary)
                    } else {
                        MuscleGroupGrid(groups: coverage.targetedGroups, isTargeted: true)
                    }
                }

                Section("Not Targeted") {
                    MuscleGroupGrid(groups: coverage.untargetedGroups, isTargeted: false)
                }

                if !contributingEntries.isEmpty {
                    Section("Exercises Counted") {
                        ForEach(contributingEntries) { entry in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(entry.activity?.name ?? "Unknown")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                Text(entry.activity?.muscleGroups ?? "")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
            }
            .navigationTitle("Muscles Targeted")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

private struct MuscleGroupGrid: View {
    let groups: [String]
    let isTargeted: Bool

    private let columns = [
        GridItem(.adaptive(minimum: 92), spacing: 8)
    ]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
            ForEach(groups, id: \.self) { group in
                Label(group, systemImage: isTargeted ? "checkmark.circle.fill" : "circle")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(isTargeted ? Color.accentColor : .secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(isTargeted ? Color.accentColor.opacity(0.12) : Color(.tertiarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Entry Card

struct EntryDetailCard: View {
    @ObservedObject var entry: CDWorkoutEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                if let cat = entry.activity?.activityCategory {
                    Image(systemName: cat.icon)
                        .foregroundStyle(cat.color)
                }
                Text(entry.activity?.name ?? "Unknown")
                    .font(.headline)
                Spacer()
                if let muscles = entry.activity?.muscleGroups, !muscles.isEmpty {
                    Text(muscles)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Divider()

            let sets = entry.sortedSets
            if sets.isEmpty {
                Text("No sets logged")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 6) {
                    setHeaderRow(metric: entry.activity?.metric ?? .weightReps)
                    ForEach(sets) { set in
                        SetDisplayRow(
                            set: set,
                            metric: entry.activity?.metric ?? .weightReps
                        )
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder
    private func setHeaderRow(metric: PrimaryMetric) -> some View {
        HStack {
            Text("Set")
                .frame(width: 36, alignment: .leading)
            Spacer()
            switch metric {
            case .weightReps:
                Text("Weight").frame(maxWidth: .infinity, alignment: .center)
                Text("Reps").frame(maxWidth: .infinity, alignment: .center)
            case .distanceTime:
                Text("Distance").frame(maxWidth: .infinity, alignment: .center)
                Text("Time").frame(maxWidth: .infinity, alignment: .center)
            case .lapsTime:
                Text("Laps").frame(maxWidth: .infinity, alignment: .center)
                Text("Time").frame(maxWidth: .infinity, alignment: .center)
            case .duration:
                Text("Duration").frame(maxWidth: .infinity, alignment: .center)
            case .reps:
                Text("Reps").frame(maxWidth: .infinity, alignment: .center)
            case .custom:
                Text("Value").frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .fontWeight(.medium)
    }
}

// MARK: - Set Row

struct SetDisplayRow: View {
    let set: CDEntrySet
    let metric: PrimaryMetric
    var onDelete: (() -> Void)? = nil

    var body: some View {
        HStack {
            Text("\(set.setNumber)")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .frame(width: 36, alignment: .leading)
            Spacer()
            switch metric {
            case .weightReps:
                Text(set.weightKg > 0 ? Units.displayWeight(kg: set.weightKg) : "—")
                    .frame(maxWidth: .infinity, alignment: .center)
                Text(set.reps > 0 ? "\(set.reps)" : "—")
                    .frame(maxWidth: .infinity, alignment: .center)
            case .distanceTime:
                Text(set.distanceMeters > 0 ? Units.displayDistance(meters: set.distanceMeters) : "—")
                    .frame(maxWidth: .infinity, alignment: .center)
                Text(set.durationSeconds > 0 ? set.formattedDuration : "—")
                    .frame(maxWidth: .infinity, alignment: .center)
            case .lapsTime:
                Text(set.laps > 0 ? "\(set.laps)" : "—")
                    .frame(maxWidth: .infinity, alignment: .center)
                Text(set.durationSeconds > 0 ? set.formattedDuration : "—")
                    .frame(maxWidth: .infinity, alignment: .center)
            case .duration:
                Text(set.durationSeconds > 0 ? set.formattedDuration : "—")
                    .frame(maxWidth: .infinity, alignment: .center)
            case .reps:
                Text(set.reps > 0 ? "\(set.reps)" : "—")
                    .frame(maxWidth: .infinity, alignment: .center)
            case .custom:
                Text(set.customValue > 0 ? String(format: "%.1f %@", set.customValue, set.customLabel ?? "") : "—")
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            if set.isPRAttempt {
                Image(systemName: "trophy.fill")
                    .foregroundStyle(.yellow)
                    .font(.caption)
                    .frame(width: 20)
            }
            if let onDelete {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundStyle(.red.opacity(0.7))
                        .frame(width: 28)
                }
                .buttonStyle(.plain)
            }
        }
        .font(.subheadline)
    }
}
