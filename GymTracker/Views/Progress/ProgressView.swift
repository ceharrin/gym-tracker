import SwiftUI
import Charts
import CoreData

struct ProgressTabView: View {
    @Environment(\.managedObjectContext) private var context

    @FetchRequest private var activities: FetchedResults<CDActivity>
    @FetchRequest private var profiles: FetchedResults<CDUserProfile>
    @FetchRequest private var workouts: FetchedResults<CDWorkout>

    @State private var selectedActivities: Set<CDActivity> = []
    @State private var selectedWorkoutMetrics: Set<WorkoutTotalMetric> = []
    @State private var selectedRange: ProgressDateRange = .threeMonths
    @State private var exportURL: URL? = nil
    @State private var showingShareSheet = false
    @State private var showingActivityPicker = false
    @State private var isExporting = false

    private var profile: CDUserProfile? { profiles.first }
    private var cutoffDate: Date? { selectedRange.cutoffDate }
    private var selectedActivityIDs: Set<NSManagedObjectID> {
        Set(selectedActivities.map(\.objectID))
    }

    init() {
        _activities = FetchRequest(fetchRequest: ManagedFetchRequests.activitiesByName(), animation: .default)
        _profiles = FetchRequest(fetchRequest: ManagedFetchRequests.profilesByCreatedAt(), animation: .default)
        _workouts = FetchRequest(fetchRequest: ManagedFetchRequests.workoutsByDate(ascending: true), animation: .default)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                GymTheme.appBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        rangeSelector
                        bodyWeightChart
                        workoutTotalsPicker
                        switch workoutTotalsSectionState {
                        case .noData:
                            workoutTotalsEmptyState
                        case .needsSelection:
                            workoutTotalsPlaceholder
                        case .ready:
                            ForEach(selectedWorkoutMetrics.sorted { $0.rawValue < $1.rawValue }) { metric in
                                workoutTotalChart(for: metric)
                            }
                        }
                        activityPicker
                        switch activitySectionState {
                        case .noData:
                            activityEmptyState
                        case .needsSelection:
                            activityPlaceholder
                        case .ready:
                            ForEach(selectedActivities.sorted { $0.name < $1.name }) { activity in
                                activityChart(for: activity)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Progress")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.white.opacity(0.92), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { @MainActor in
                            isExporting = true
                            // Yield so SwiftUI can render the spinner before the blocking render
                            await Task.yield()
                            defer { isExporting = false }
                            let toExport = selectedActivities.sorted { $0.name < $1.name }
                            guard let url = ProgressExporter.generatePDF(for: toExport, range: selectedRange) else { return }
                            exportURL = url
                            showingShareSheet = true
                        }
                    } label: {
                        if isExporting {
                            SwiftUI.ProgressView().scaleEffect(0.8)
                        } else {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                    .disabled(selectedActivities.isEmpty || isExporting)
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let url = exportURL {
                    ShareSheet(items: [url])
                }
            }
            .sheet(isPresented: $showingActivityPicker) {
                ActivityProgressPickerSheet(
                    activities: activitiesWithData,
                    selectedActivities: $selectedActivities
                )
            }
            .onAppear {
                reconcileSelections()
            }
            .onChange(of: selectedRange) {
                reconcileSelections()
            }
            .onChange(of: activitiesWithData.map(\.objectID)) {
                reconcileSelections()
            }
            .onChange(of: workoutMetricsWithData) {
                reconcileSelections()
            }
        }
    }

    // MARK: Range Selector

    private var rangeSelector: some View {
        Picker("Range", selection: $selectedRange) {
            ForEach(ProgressDateRange.allCases, id: \.self) { range in
                Text(range.rawValue).tag(range)
            }
        }
        .pickerStyle(.segmented)
        .padding(6)
        .background(Color.white.opacity(0.64))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: Body Weight Chart

    private var bodyWeightChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Body Weight")
                .font(.headline)

            let measurements = filteredMeasurements
            if bodyWeightSectionState == .noData {
                // Render an empty Chart so the Charts framework is always initialised
                // in the view hierarchy — required for ImageRenderer to work correctly
                // when exporting progress before any activity chart has been shown.
                Chart([] as [Double], id: \.self) { _ in }
                    .frame(height: 80)
                    .chartXAxis(.hidden)
                    .chartYAxis(.hidden)
                    .overlay {
                        emptyChartPlaceholder(message: "Add a body-weight measurement in Profile to unlock this chart.")
                    }
            } else {
                Chart {
                    ForEach(measurements) { m in
                        LineMark(
                            x: .value("Date", m.date),
                            y: .value(Units.weightUnit, Units.weightValue(fromKg: m.weightKg))
                        )
                        .foregroundStyle(Color.accentColor)
                        .interpolationMethod(.catmullRom)

                        PointMark(
                            x: .value("Date", m.date),
                            y: .value(Units.weightUnit, Units.weightValue(fromKg: m.weightKg))
                        )
                        .foregroundStyle(Color.accentColor)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .frame(height: 180)

                if let first = measurements.first, let last = measurements.last {
                    let delta = last.weightKg - first.weightKg
                    weightChangeSummary(delta: delta)
                }
            }
        }
        .padding(16)
        .gymCard()
    }

    private var filteredMeasurements: [CDBodyMeasurement] {
        let all = profile?.sortedMeasurements ?? []
        guard let cutoff = cutoffDate else { return all }
        return all.filter { $0.date >= cutoff }
    }

    private var bodyWeightSectionState: ProgressSelectionPolicy.SectionState {
        ProgressSelectionPolicy.sectionState(
            availableItemCount: filteredMeasurements.count,
            selectedItemCount: filteredMeasurements.count
        )
    }

    private func weightChangeSummary(delta: Double) -> some View {
        HStack {
            Image(systemName: delta <= 0 ? "arrow.down" : "arrow.up")
                .foregroundStyle(delta <= 0 ? .green : .orange)
            Text(String(format: "%.1f \(Units.weightUnit) in selected period", Units.weightValue(fromKg: abs(delta))))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: Activity Picker

    private var activityPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Activity Progress")
                        .font(.headline)
                    Text(activityPickerSummary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    showingActivityPicker = true
                } label: {
                    Label("Choose", systemImage: "line.3.horizontal.decrease.circle")
                        .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.bordered)
                .disabled(activitiesWithData.isEmpty)
            }

            if selectedActivities.isEmpty {
                Text("Choose an activity to review its trend.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Color.white.opacity(0.62))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(selectedActivities.sorted { $0.name < $1.name }) { activity in
                            selectedActivityPill(activity)
                        }
                    }
                    .padding(.horizontal, 1)
                }
            }
        }
        .padding(16)
        .gymCard()
    }

    private var activityPickerSummary: String {
        switch (selectedActivities.count, activitiesWithData.count) {
        case (_, 0):
            return "Complete workouts with activity entries to unlock trends."
        case (0, let available):
            return "\(available) activit\(available == 1 ? "y" : "ies") available"
        case (let selected, let available):
            return "\(selected) selected of \(available)"
        }
    }

    private func selectedActivityPill(_ activity: CDActivity) -> some View {
        Button {
            selectedActivities.remove(activity)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: activity.activityCategory.icon)
                    .font(.caption)
                Text(activity.name)
                    .font(.caption)
                    .fontWeight(.medium)
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .foregroundStyle(GymTheme.ink)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Color.white.opacity(0.78))
            .clipShape(Capsule())
            .overlay {
                Capsule()
                    .stroke(activity.activityCategory.color.opacity(0.45), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }

    private var activitiesWithData: [CDActivity] {
        activities.filter { ($0.entries?.count ?? 0) > 0 }
    }

    private var activitySectionState: ProgressSelectionPolicy.SectionState {
        ProgressSelectionPolicy.sectionState(
            availableItemCount: activitiesWithData.count,
            selectedItemCount: selectedActivities.count
        )
    }

    private func reconcileSelections() {
        selectedWorkoutMetrics = ProgressSelectionPolicy.updatedMetricSelection(
            current: selectedWorkoutMetrics,
            available: workoutMetricsWithData
        )

        let updatedActivityIDs = ProgressSelectionPolicy.updatedActivitySelection(
            currentIDs: selectedActivityIDs,
            availableIDs: activitiesWithData.map(\.objectID)
        )
        selectedActivities = Set(activitiesWithData.filter { updatedActivityIDs.contains($0.objectID) })
    }

    // MARK: Workout Totals

    private var workoutTotalsPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Workout Totals")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(workoutMetricsWithData) { metric in
                        Button {
                            if selectedWorkoutMetrics.contains(metric) {
                                selectedWorkoutMetrics.remove(metric)
                            } else {
                                selectedWorkoutMetrics.insert(metric)
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: metric.icon)
                                    .font(.caption)
                                Text(metric.title)
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(selectedWorkoutMetrics.contains(metric)
                                ? AnyShapeStyle(
                                    LinearGradient(
                                        colors: [GymTheme.electricBlue, GymTheme.brightBlue],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                : AnyShapeStyle(Color.white.opacity(0.78)))
                            .foregroundStyle(selectedWorkoutMetrics.contains(metric) ? .white : GymTheme.ink)
                            .clipShape(Capsule())
                            .overlay {
                                Capsule()
                                    .stroke(Color.white.opacity(selectedWorkoutMetrics.contains(metric) ? 0.0 : 0.65), lineWidth: 1)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 1)
            }
        }
    }

    private var workoutMetricsWithData: [WorkoutTotalMetric] {
        WorkoutTotalMetric.allCases.filter { metric in
            Array(workouts).contains { workout in
                if let cutoffDate, workout.date < cutoffDate { return false }
                return metric.value(from: workout) > 0
            }
        }
    }

    private var workoutTotalsSectionState: ProgressSelectionPolicy.SectionState {
        ProgressSelectionPolicy.sectionState(
            availableItemCount: workoutMetricsWithData.count,
            selectedItemCount: selectedWorkoutMetrics.count
        )
    }

    private func workoutTotalChart(for metric: WorkoutTotalMetric) -> some View {
        let dataPoints = Array(workouts).workoutTotalChartPoints(for: metric, cutoffDate: cutoffDate)

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: metric.icon)
                    .foregroundStyle(GymTheme.electricBlue)
                Text(metric.title)
                    .font(.headline)
                Spacer()
                Text(metric.chartLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if dataPoints.isEmpty {
                emptyChartPlaceholder(message: "No workout totals in selected range.")
            } else {
                Chart {
                    ForEach(dataPoints) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value(metric.chartLabel, point.value)
                        )
                        .foregroundStyle(GymTheme.electricBlue)
                        .interpolationMethod(.catmullRom)

                        PointMark(
                            x: .value("Date", point.date),
                            y: .value(metric.chartLabel, point.value)
                        )
                        .foregroundStyle(GymTheme.electricBlue)
                        .annotation(position: .top) {
                            Text(metric.formattedValue(point.value))
                                .font(.system(size: 9))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .frame(height: 200)
            }
        }
        .padding(16)
        .gymCard()
    }

    private var activityPlaceholder: some View {
        progressEmptyStateCard(
            icon: "chart.line.uptrend.xyaxis",
            title: "No activity selected",
            message: "Select one or more activities above to see your progress chart."
        )
    }

    private var activityEmptyState: some View {
        progressEmptyStateCard(
            icon: "chart.line.uptrend.xyaxis",
            title: "No activity trends yet",
            message: "Complete workouts with activity entries to unlock progress charts."
        )
    }

    private var workoutTotalsPlaceholder: some View {
        progressEmptyStateCard(
            icon: "chart.bar.xaxis",
            title: "No total selected",
            message: "Select one or more totals above to compare workout volume."
        )
    }

    private var workoutTotalsEmptyState: some View {
        progressEmptyStateCard(
            icon: "chart.bar.xaxis",
            title: "No workout totals yet",
            message: "Complete workouts in this range to unlock total duration, reps, distance, or laps."
        )
    }

    private func progressEmptyStateCard(icon: String, title: String, message: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text(title)
                .font(.headline)
                .foregroundStyle(GymTheme.ink)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .gymCard()
    }

    // MARK: Activity Chart

    @ViewBuilder
    private func activityChart(for activity: CDActivity) -> some View {
        let dataPoints = activity.progressChartPoints(cutoffDate: cutoffDate)

        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: activity.activityCategory.icon)
                    .foregroundStyle(activity.activityCategory.color)
                Text(activity.name)
                    .font(.headline)
                Spacer()
                Text(activity.metric.chartYLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if dataPoints.isEmpty {
                emptyChartPlaceholder(message: "No data in selected range.")
            } else {
                Chart {
                    ForEach(dataPoints) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value(activity.metric.chartYLabel, point.value)
                        )
                        .foregroundStyle(activity.activityCategory.color)
                        .interpolationMethod(.catmullRom)

                        PointMark(
                            x: .value("Date", point.date),
                            y: .value(activity.metric.chartYLabel, point.value)
                        )
                        .foregroundStyle(activity.activityCategory.color)
                        .annotation(position: .top) {
                            Text(activity.metric.formattedChartValue(point.value))
                                .font(.system(size: 9))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .frame(height: 200)
            }
        }
        .padding(16)
        .gymCard()
    }

    // MARK: Personal Records

    @ViewBuilder
    private func personalRecordCard(for activity: CDActivity) -> some View {
        let records = activity.progressPersonalRecords(cutoffDate: cutoffDate)
        if records.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: 12) {
                Label("Personal Records", systemImage: "trophy.fill")
                    .font(.headline)
                    .foregroundStyle(.orange)

                ForEach(records) { record in
                    PRRow(label: record.label, value: record.value)
                }
            }
            .padding(16)
            .gymCard()
        }
    }

    private func emptyChartPlaceholder(message: String) -> some View {
        Text(message)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
    }
}

private struct ActivityProgressPickerSheet: View {
    let activities: [CDActivity]
    @Binding var selectedActivities: Set<CDActivity>

    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selectedCategory: ActivityCategory? = nil

    private var categoriesWithData: [ActivityCategory] {
        ActivityCategory.allCases.filter { category in
            activities.contains { $0.activityCategory == category }
        }
    }

    private var filteredActivities: [CDActivity] {
        activities.filter {
            ProgressSelectionPolicy.activityMatchesFilters(
                name: $0.name,
                category: $0.activityCategory,
                searchText: searchText,
                selectedCategory: selectedCategory
            )
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Category", selection: $selectedCategory) {
                        Text("All Categories").tag(ActivityCategory?.none)
                        ForEach(categoriesWithData, id: \.self) { category in
                            Label(category.displayName, systemImage: category.icon)
                                .tag(Optional(category))
                        }
                    }
                }

                Section {
                    if filteredActivities.isEmpty {
                        ContentUnavailableView(
                            "No Activities Found",
                            systemImage: "magnifyingglass",
                            description: Text("Try a different search or category.")
                        )
                    } else {
                        ForEach(filteredActivities) { activity in
                            Button {
                                toggle(activity)
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: activity.activityCategory.icon)
                                        .foregroundStyle(activity.activityCategory.color)
                                        .frame(width: 24)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(activity.name)
                                            .foregroundStyle(GymTheme.ink)
                                        Text(activity.activityCategory.displayName)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()

                                    if selectedActivities.contains(activity) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(GymTheme.electricBlue)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } header: {
                    Text("Activities")
                } footer: {
                    Text("\(selectedActivities.count) selected")
                }
            }
            .navigationTitle("Choose Activities")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Clear") {
                        selectedActivities.removeAll()
                    }
                    .disabled(selectedActivities.isEmpty)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func toggle(_ activity: CDActivity) {
        if selectedActivities.contains(activity) {
            selectedActivities.remove(activity)
        } else {
            selectedActivities.insert(activity)
        }
    }
}

struct PRRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
    }
}
