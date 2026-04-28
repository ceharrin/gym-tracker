import SwiftUI

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
    @State private var isRetryingHealthSync = false
    @State private var heartRateSummary: WorkoutHeartRateSummary? = nil
    @State private var persistenceAlert: PersistenceAlertState? = nil

    var body: some View {
        Group {
            if isDeleting {
                Color.clear
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        metaCard
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
        .navigationTitle(workout.title)
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
                    if workout.healthKitCanRetrySync {
                        Button {
                            Task { @MainActor in
                                guard !isRetryingHealthSync else { return }
                                isRetryingHealthSync = true
                                defer { isRetryingHealthSync = false }
                                await WorkoutHealthKitManager.shared.retryWorkoutSync(workout)
                            }
                        } label: {
                            Label("Retry Apple Health Sync", systemImage: "arrow.clockwise")
                        }
                    }
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
        .alert("Couldn't Export Workout", isPresented: Binding(
            get: { shareError != nil },
            set: { if !$0 { shareError = nil } }
        )) {
            Button("OK", role: .cancel) { shareError = nil }
        } message: {
            Text(shareError ?? "An unknown error occurred.")
        }
        .persistenceErrorAlert($persistenceAlert)
        .task(id: workout.objectID) {
            heartRateSummary = await WorkoutHealthKitManager.shared.loadHeartRateSummary(for: workout)
        }
    }

    private var metaCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 0) {
                metaStat(label: "Date", value: workout.date, style: .date)
                Divider().frame(height: 40)
                metaDurationStat
                Divider().frame(height: 40)
                metaEnergyStat
            }

            Label {
                Text(workout.healthKitSyncState.displayText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } icon: {
                Image(systemName: workout.healthKitSyncState.symbolName)
                    .foregroundStyle(workout.healthKitSyncState.tint)
            }

            if let heartRateSummary {
                HStack(spacing: 16) {
                    Label("\(heartRateSummary.averageBPM) avg", systemImage: "heart.fill")
                    Label("\(heartRateSummary.maxBPM) max", systemImage: "bolt.heart.fill")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func metaStat(label: String, value: Date, style: Text.DateStyle) -> some View {
        VStack(spacing: 4) {
            Text(value, style: style)
                .font(.subheadline)
                .fontWeight(.semibold)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var metaDurationStat: some View {
        VStack(spacing: 4) {
            Text(workout.durationMinutes > 0 ? "\(workout.durationMinutes) min" : "—")
                .font(.subheadline)
                .fontWeight(.semibold)
            Text("Duration")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var metaEnergyStat: some View {
        VStack(spacing: 4) {
            HStack(spacing: 2) {
                ForEach(0..<5) { i in
                    Image(systemName: i < workout.energyLevel / 2 ? "bolt.fill" : "bolt")
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
