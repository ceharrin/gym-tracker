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
    @State private var csvShareURL: URL? = nil
    @State private var showingCSVShare = false
    @State private var isExportingCSV = false
    @State private var csvExportError: String? = nil
    @State private var showingCSVExportOptions = false
    @State private var csvExportStartDate = Date()
    @State private var csvExportEndDate = Date()
    @State private var visibleWorkoutCount = WorkoutHistoryDisplayPolicy.initialVisibleCount

    private var visibleWorkouts: [CDWorkout] {
        WorkoutHistoryDisplayPolicy.visibleWorkouts(
            from: Array(workouts),
            searchText: searchText,
            visibleCount: visibleWorkoutCount
        )
    }

    private var isSearching: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var shouldShowLoadMore: Bool {
        WorkoutHistoryDisplayPolicy.shouldShowLoadMore(
            totalCount: workouts.count,
            visibleCount: visibleWorkoutCount,
            searchText: searchText
        )
    }

    private var remainingWorkoutCount: Int {
        max(workouts.count - visibleWorkouts.count, 0)
    }

    private var grouped: [(String, [CDWorkout])] {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMMM yyyy"
        let dict = Dictionary(grouping: visibleWorkouts) { fmt.string(from: $0.date) }
        return dict.sorted { $0.key > $1.key }.map { ($0.key, $0.value.sorted { $0.date > $1.date }) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                GymTheme.appBackground.ignoresSafeArea()

                Group {
                    if workouts.isEmpty {
                        emptyState
                    } else {
                        List {
                            ForEach(grouped, id: \.0) { month, items in
                                Section {
                                    ForEach(items) { workout in
                                        NavigationLink {
                                            WorkoutNavigationDestination(workout: workout)
                                        } label: {
                                            WorkoutSummaryRow(workout: workout, style: .list)
                                        }
                                    }
                                    .onDelete { delete(items: items, offsets: $0) }
                                } header: {
                                    Text(month)
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .tracking(1.2)
                                        .foregroundStyle(GymTheme.steel)
                                }
                            }

                            if shouldShowLoadMore {
                                Section {
                                    Button {
                                        visibleWorkoutCount = WorkoutHistoryDisplayPolicy.nextVisibleCount(
                                            currentVisibleCount: visibleWorkoutCount,
                                            totalCount: workouts.count
                                        )
                                    } label: {
                                        HStack {
                                            Spacer()
                                            Text("Show Older Workouts (\(remainingWorkoutCount) more)")
                                                .fontWeight(.semibold)
                                            Spacer()
                                        }
                                    }
                                    .foregroundStyle(GymTheme.electricBlue)
                                }
                            }
                        }
                        .scrollContentBackground(.hidden)
                        .listStyle(.insetGrouped)
                        .listRowSpacing(10)
                        .searchable(text: $searchText, prompt: "Search workouts")
                    }
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.white.opacity(0.92), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .safeAreaInset(edge: .top) {
                if !workouts.isEmpty && !isSearching {
                    historyStatusBanner
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if !workouts.isEmpty {
                        Menu {
                            Button {
                                showingPrintSummary = true
                            } label: {
                                Label("Print Summary", systemImage: "printer")
                            }
                            Button {
                                prepareCSVExport()
                            } label: {
                                Label("Export CSV", systemImage: "tablecells")
                            }
                            .disabled(isExportingCSV)
                        } label: {
                            Image(systemName: "ellipsis.circle")
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
            .sheet(isPresented: $showingCSVExportOptions) {
                NavigationStack {
                    WorkoutCSVExportRangeView(
                        startDate: $csvExportStartDate,
                        endDate: $csvExportEndDate,
                        isExporting: isExportingCSV,
                        availableRange: workoutDateBounds,
                        onApplyPreset: applyCSVExportPreset,
                        onCancel: { showingCSVExportOptions = false },
                        onExport: exportCSV
                    )
                }
                .presentationDetents([.medium])
            }
            .sheet(isPresented: $showingCSVShare, onDismiss: { csvShareURL = nil }) {
                if let url = csvShareURL {
                    ShareSheet(items: [url])
                }
            }
            .alert("Couldn't Export CSV", isPresented: Binding(
                get: { csvExportError != nil },
                set: { if !$0 { csvExportError = nil } }
            )) {
                Button("OK", role: .cancel) { csvExportError = nil }
            } message: {
                Text(csvExportError ?? "An unknown error occurred.")
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
                .tint(GymTheme.electricBlue)
        }
    }

    private var historyStatusBanner: some View {
        Group {
            if shouldShowLoadMore {
                Text("Showing \(visibleWorkouts.count) most recent workouts")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(GymTheme.steel)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.9))
                    )
                    .padding(.top, 6)
            }
        }
    }

    private var workoutDateBounds: ClosedRange<Date>? {
        guard let oldest = workouts.last?.date, let newest = workouts.first?.date else { return nil }
        return oldest...newest
    }

    private func prepareCSVExport() {
        guard let bounds = workoutDateBounds else {
            csvExportError = "There are no workouts available to export."
            return
        }

        csvExportStartDate = bounds.lowerBound
        csvExportEndDate = bounds.upperBound
        showingCSVExportOptions = true
    }

    private func exportCSV() {
        guard !isExportingCSV else { return }
        isExportingCSV = true
        Task { @MainActor in
            defer { isExportingCSV = false }
            do {
                let selectedRange = WorkoutExporter.ExportDateRange(
                    startDate: csvExportStartDate,
                    endDate: csvExportEndDate
                )
                let workoutsToExport = WorkoutExporter.workouts(Array(workouts), in: selectedRange)
                guard !workoutsToExport.isEmpty else {
                    csvExportError = "No workouts were found in the selected date range."
                    return
                }

                csvShareURL = try WorkoutExporter.exportCSV(for: workoutsToExport, in: selectedRange)
                showingCSVExportOptions = false
                showingCSVShare = true
            } catch {
                csvExportError = error.localizedDescription
            }
        }
    }

    private func applyCSVExportPreset(_ preset: WorkoutExporter.ExportDateRangePreset) {
        guard let bounds = workoutDateBounds else { return }
        let resolved = preset.resolve(within: bounds)
        csvExportStartDate = resolved.startDate
        csvExportEndDate = resolved.endDate
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

private struct WorkoutCSVExportRangeView: View {
    @Binding var startDate: Date
    @Binding var endDate: Date
    let isExporting: Bool
    let availableRange: ClosedRange<Date>?
    let onApplyPreset: (WorkoutExporter.ExportDateRangePreset) -> Void
    let onCancel: () -> Void
    let onExport: () -> Void

    var body: some View {
        Form {
            if availableRange != nil {
                Section("Quick Ranges") {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(WorkoutExporter.ExportDateRangePreset.allCases) { preset in
                            Button(preset.title) {
                                onApplyPreset(preset)
                            }
                            .buttonStyle(.bordered)
                            .disabled(isExporting)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            Section {
                if let availableRange {
                    DatePicker("Start Date", selection: $startDate, in: availableRange, displayedComponents: .date)

                    DatePicker("End Date", selection: $endDate, in: availableRange, displayedComponents: .date)
                } else {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)

                    DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                }
            } header: {
                Text("Export Range")
            } footer: {
                Text("Only workouts whose dates fall within the selected range will be included in the CSV.")
            }
        }
        .navigationTitle("Export CSV")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel", action: onCancel)
                    .disabled(isExporting)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(isExporting ? "Exporting..." : "Export", action: onExport)
                    .disabled(isExporting)
            }
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
                        if workout.hasPersonalBest {
                            Label("Personal Best", systemImage: "trophy.fill")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundStyle(.yellow)
                                .labelStyle(.iconOnly)
                        }
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
                .padding(.vertical, style == .list ? 8 : 0)
                .padding(.horizontal, style == .list ? 6 : 0)
                .background(style == .card ? Color.clear : Color.clear)
                .modifier(WorkoutSummaryRowTheme(style: style))
            }
        }
    }

    @ViewBuilder
    private var iconBadge: some View {
        if style == .card {
            RoundedRectangle(cornerRadius: 10)
                .fill(categoryColor.opacity(0.14))
                .frame(width: 48, height: 48)
                .overlay {
                    Image(systemName: categoryIcon)
                        .foregroundStyle(categoryColor)
                }
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(categoryColor.opacity(0.14))
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

private struct WorkoutSummaryRowTheme: ViewModifier {
    let style: WorkoutSummaryRowStyle

    func body(content: Content) -> some View {
        switch style {
        case .card:
            content
                .gymCard(cornerRadius: 18)
        case .list:
            content
                .gymCard(cornerRadius: 18)
                .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
                .listRowBackground(Color.clear)
        }
    }
}
