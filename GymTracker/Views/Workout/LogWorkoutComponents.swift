import SwiftUI

struct WorkoutMetaSection: View {
    @Binding var title: String
    @Binding var workoutDate: Date
    let durationText: String
    let statusText: String?

    var body: some View {
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

                VStack(alignment: .leading, spacing: 4) {
                    Label(durationText, systemImage: "timer")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text(statusText ?? "Calculated automatically")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(12)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(.bottom, 4)
    }
}

struct WorkoutFinishingSection: View {
    @Binding var notes: String
    @Binding var energyLevel: Int

    var body: some View {
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

struct EntrySection: View {
    @Binding var entry: LiveEntry
    let onDeleteEntry: () -> Void
    @State private var showingTutorial = false
    @State private var restTimerRestartToken = UUID()

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
                restTimerRestartToken = UUID()
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

            RestTimerView(restartToken: restTimerRestartToken)
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
                Button {
                    showingTutorial = true
                } label: {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.secondary)
                        .font(.body)
                }
                .buttonStyle(.plain)
                Button(role: .destructive, action: onDeleteEntry) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.body)
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 4)
        }
        .sheet(isPresented: $showingTutorial) {
            ActivityTutorialView(activity: entry.activity)
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
            case .reps:
                Text("Reps").frame(maxWidth: .infinity, alignment: .center)
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

enum RestTimerFormatter {
    static func string(for elapsedSeconds: Int) -> String {
        let clamped = max(elapsedSeconds, 0)
        let hours = clamped / 3600
        let minutes = (clamped % 3600) / 60
        let seconds = clamped % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }
}

private struct RestTimerView: View {
    let restartToken: UUID

    @State private var startedAt: Date?
    @State private var accumulatedSeconds: TimeInterval = 0

    var body: some View {
        TimelineView(.periodic(from: Date(), by: 1)) { context in
            HStack(spacing: 10) {
                Label(displayText(now: context.date), systemImage: "timer")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .monospacedDigit()
                    .frame(minWidth: 78, alignment: .leading)

                Spacer()

                Button {
                    toggle(now: context.date)
                } label: {
                    Label(isRunning ? "Pause" : "Start Rest", systemImage: isRunning ? "pause.fill" : "play.fill")
                        .labelStyle(.titleAndIcon)
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .buttonStyle(.bordered)

                Button {
                    reset()
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("Reset rest timer")
            }
            .padding(.vertical, 6)
        }
        .onChange(of: restartToken) { _, _ in
            startFresh()
        }
    }

    private var isRunning: Bool {
        startedAt != nil
    }

    private func displayText(now: Date) -> String {
        RestTimerFormatter.string(for: Int(elapsedSeconds(now: now).rounded(.down)))
    }

    private func elapsedSeconds(now: Date) -> TimeInterval {
        accumulatedSeconds + (startedAt.map { now.timeIntervalSince($0) } ?? 0)
    }

    private func toggle(now: Date) {
        if let startedAt {
            accumulatedSeconds += now.timeIntervalSince(startedAt)
            self.startedAt = nil
        } else {
            startedAt = now
        }
    }

    private func reset() {
        accumulatedSeconds = 0
        startedAt = nil
    }

    private func startFresh() {
        accumulatedSeconds = 0
        startedAt = Date()
    }
}

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
            case .reps:
                inputField($set.reps, placeholder: "0", keyboard: .numberPad)
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
