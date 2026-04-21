import SwiftUI
import CoreData

struct WorkoutListView: View {
    @Environment(\.managedObjectContext) private var context
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \CDWorkout.date, ascending: false)],
        animation: .default
    ) private var workouts: FetchedResults<CDWorkout>

    @State private var showingLogWorkout = false
    @State private var showingPrintSummary = false
    @State private var searchText = ""

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
                                        WorkoutDetailView(workout: workout)
                                    } label: {
                                        WorkoutListRow(workout: workout)
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
                    HStack(spacing: 16) {
                        if !workouts.isEmpty {
                            Button {
                                showingPrintSummary = true
                            } label: {
                                Image(systemName: "printer")
                            }
                        }
                        Button {
                            showingLogWorkout = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingLogWorkout) {
                LogWorkoutView()
            }
            .sheet(isPresented: $showingPrintSummary) {
                PrintSummaryView(allWorkouts: Array(workouts))
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Workouts Yet", systemImage: "dumbbell")
        } description: {
            Text("Tap + to log your first workout.")
        } actions: {
            Button("Start Workout") { showingLogWorkout = true }
                .buttonStyle(.borderedProminent)
        }
    }

    private func delete(items: [CDWorkout], offsets: IndexSet) {
        for idx in offsets {
            context.delete(items[idx])
        }
        try? context.save()
    }
}

struct WorkoutListRow: View {
    let workout: CDWorkout

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(categoryColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: categoryIcon)
                    .foregroundStyle(categoryColor)
                    .font(.subheadline)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(workout.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(workout.activitySummary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(workout.date, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if workout.durationMinutes > 0 {
                    Text("\(workout.durationMinutes)m")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 2)
    }

    private var categoryIcon: String {
        workout.sortedEntries.first?.activity?.activityCategory.icon ?? "dumbbell.fill"
    }

    private var categoryColor: Color {
        workout.sortedEntries.first?.activity?.activityCategory.color ?? Color.accentColor
    }
}
