import SwiftUI
import CoreData

struct WorkoutListView: View {
    @Environment(\.managedObjectContext) private var context
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \CDWorkout.date, ascending: false)],
        animation: .default
    ) private var workouts: FetchedResults<CDWorkout>

    @State private var startDestination: WorkoutStartDestination? = nil
    @State private var showingPrintSummary = false
    @State private var searchText = ""
    @State private var persistenceAlert: PersistenceAlertState? = nil

    private var filtered: [CDWorkout] {
        guard !searchText.isEmpty else { return Array(workouts) }
        return workouts.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.activitySummary.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var grouped: [(String, [CDWorkout])] {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMMM yyyy"
        let dict = Dictionary(grouping: filtered) { fmt.string(from: $0.date) }
        return dict.sorted { $0.key > $1.key }.map { ($0.key, $0.value.sorted { $0.date > $1.date }) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if workouts.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(grouped, id: \.0) { month, items in
                            Section(month) {
                                ForEach(items) { workout in
                                    NavigationLink {
                                        WorkoutNavigationDestination(workout: workout)
                                    } label: {
                                        WorkoutSummaryRow(workout: workout, style: .list)
                                    }
                                }
                                .onDelete { delete(items: items, offsets: $0) }
                            }
                        }
                    }
                    .searchable(text: $searchText, prompt: "Search workouts")
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if !workouts.isEmpty {
                        Button {
                            showingPrintSummary = true
                        } label: {
                            Image(systemName: "printer")
                        }
                    }
                }
            }
            .sheet(item: $startDestination) { destination in
                if let workout = destination.workout {
                    LogWorkoutView(workout: workout)
                } else {
                    LogWorkoutView()
                }
            }
            .sheet(isPresented: $showingPrintSummary) {
                PrintSummaryView(allWorkouts: Array(workouts))
            }
            .persistenceErrorAlert($persistenceAlert)
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Workouts Yet", systemImage: "dumbbell")
        } description: {
            Text("Log your first workout to see it here.")
        } actions: {
            Button("Start Workout") {
                startDestination = WorkoutStartCoordinator.startDestination(from: Array(workouts))
            }
                .buttonStyle(.borderedProminent)
        }
    }

    private func delete(items: [CDWorkout], offsets: IndexSet) {
        for idx in offsets {
            context.delete(items[idx])
        }
        do {
            try context.saveIfChanged()
        } catch {
            context.rollback()
            persistenceAlert = PersistenceAlertState(title: "Couldn't Delete Workout", error: error)
        }
    }
}

enum WorkoutSummaryRowStyle {
    case card
    case list
}

struct WorkoutNavigationDestination: View {
    @ObservedObject var workout: CDWorkout

    var body: some View {
        if !workout.canRenderInUI {
            Color.clear
        } else if workout.isCompleted {
            WorkoutDetailView(workout: workout)
        } else {
            LogWorkoutView(workout: workout)
        }
    }
}

struct WorkoutSummaryRow: View {
    @ObservedObject var workout: CDWorkout
    let style: WorkoutSummaryRowStyle

    var body: some View {
        Group {
            if workout.canRenderInUI {
                HStack(spacing: style == .card ? 14 : 12) {
                    iconBadge

                    VStack(alignment: .leading, spacing: 2) {
                        Text(workout.title)
                            .font(.subheadline)
                            .fontWeight(style == .card ? .semibold : .medium)
                        if let statusLabel = workout.statusLabel {
                            Text(statusLabel)
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.accentColor)
                        }
                        Text(workout.activitySummary)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(workout.formattedDate)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if let durationText = workout.formattedDuration {
                            Text(compactDurationText(from: durationText))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(style == .card ? 14 : 0)
                .padding(.vertical, style == .list ? 2 : 0)
                .background(style == .card ? Color(.secondarySystemBackground) : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    @ViewBuilder
    private var iconBadge: some View {
        if style == .card {
            RoundedRectangle(cornerRadius: 10)
                .fill(categoryColor.opacity(0.15))
                .frame(width: 48, height: 48)
                .overlay {
                    Image(systemName: categoryIcon)
                        .foregroundStyle(categoryColor)
                }
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(categoryColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: categoryIcon)
                    .foregroundStyle(categoryColor)
                    .font(.subheadline)
            }
        }
    }

    private func compactDurationText(from formattedDuration: String) -> String {
        style == .card
            ? formattedDuration
            : formattedDuration.replacingOccurrences(of: " min", with: "m")
    }

    private var categoryIcon: String { workout.primaryCategoryIcon }
    private var categoryColor: Color  { workout.primaryCategoryColor }
}
