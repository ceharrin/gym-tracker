import SwiftUI
import Charts
import CoreData

struct ProgressView: View {
    @Environment(\.managedObjectContext) private var context

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \CDActivity.name, ascending: true)],
        animation: .default
    ) private var activities: FetchedResults<CDActivity>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \CDUserProfile.createdAt, ascending: true)],
        animation: .default
    ) private var profiles: FetchedResults<CDUserProfile>

    @State private var selectedActivities: Set<CDActivity> = []
    @State private var selectedRange: ProgressDateRange = .threeMonths
    @State private var exportURL: URL? = nil
    @State private var showingShareSheet = false
    @State private var isExporting = false

    private var profile: CDUserProfile? { profiles.first }
    private var cutoffDate: Date? { selectedRange.cutoffDate }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    rangeSelector
                    bodyWeightChart
                    activityPicker
                    if selectedActivities.isEmpty {
                        activityPlaceholder
                    } else {
                        ForEach(selectedActivities.sorted { $0.name < $1.name }) { activity in
                            activityChart(for: activity)
                            personalRecordCard(for: activity)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Progress")
            .navigationBarTitleDisplayMode(.large)
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
                            ProgressView().scaleEffect(0.8)
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
    }

    // MARK: Body Weight Chart

    private var bodyWeightChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Body Weight")
                .font(.headline)

            let measurements = filteredMeasurements
            if measurements.isEmpty {
                // Render an empty Chart so the Charts framework is always initialised
                // in the view hierarchy — required for ImageRenderer to work correctly
                // when exporting progress before any activity chart has been shown.
                Chart([] as [Double], id: \.self) { _ in }
                    .frame(height: 80)
                    .chartXAxis(.hidden)
                    .chartYAxis(.hidden)
                    .overlay {
                        emptyChartPlaceholder(message: "Log weight in your Profile to see trends here.")
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
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var filteredMeasurements: [CDBodyMeasurement] {
        let all = profile?.sortedMeasurements ?? []
        guard let cutoff = cutoffDate else { return all }
        return all.filter { $0.date >= cutoff }
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
        VStack(alignment: .leading, spacing: 8) {
            Text("Activity Progress")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(activitiesWithData) { activity in
                        Button {
                            if selectedActivities.contains(activity) {
                                selectedActivities.remove(activity)
                            } else {
                                selectedActivities.insert(activity)
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: activity.activityCategory.icon)
                                    .font(.caption)
                                Text(activity.name)
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(selectedActivities.contains(activity)
                                ? activity.activityCategory.color
                                : Color(.secondarySystemBackground))
                            .foregroundStyle(selectedActivities.contains(activity) ? .white : .primary)
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 1)
            }
        }
    }

    private var activitiesWithData: [CDActivity] {
        activities.filter { ($0.entries?.count ?? 0) > 0 }
    }

    private var activityPlaceholder: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("Select one or more activities above to see your progress chart.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: Activity Chart

    @ViewBuilder
    private func activityChart(for activity: CDActivity) -> some View {
        let dataPoints = chartData(for: activity)

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
                    ForEach(dataPoints, id: \.date) { point in
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
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: Personal Records

    @ViewBuilder
    private func personalRecordCard(for activity: CDActivity) -> some View {
        let allSets = allSetsForActivity(activity)
        if allSets.isEmpty {
            EmptyView()
        } else {

        VStack(alignment: .leading, spacing: 12) {
            Label("Personal Records", systemImage: "trophy.fill")
                .font(.headline)
                .foregroundStyle(.orange)

            switch activity.metric {
            case .weightReps:
                if let best = allSets.max(by: { $0.weightKg < $1.weightKg }) {
                    PRRow(label: "Heaviest Weight", value: "\(Units.displayWeight(kg: best.weightKg)) × \(best.reps) reps")
                }
                if let most = allSets.max(by: { $0.reps < $1.reps }) {
                    PRRow(label: "Most Reps", value: "\(most.reps) @ \(Units.displayWeight(kg: most.weightKg))")
                }
            case .distanceTime:
                if let longest = allSets.max(by: { $0.distanceMeters < $1.distanceMeters }) {
                    PRRow(label: "Longest Distance", value: Units.displayDistance(meters: longest.distanceMeters))
                }
                if let fastest = allSets.filter({ $0.distanceMeters > 0 }).min(by: {
                    Double($0.durationSeconds) / $0.distanceMeters < Double($1.durationSeconds) / $1.distanceMeters
                }), let pace = fastest.pacePerUnit {
                    PRRow(label: "Best Pace", value: pace)
                }
            case .lapsTime:
                if let most = allSets.max(by: { $0.laps < $1.laps }) {
                    PRRow(label: "Most Laps", value: "\(most.laps) laps")
                }
            case .duration:
                if let longest = allSets.max(by: { $0.durationSeconds < $1.durationSeconds }) {
                    PRRow(label: "Longest Session", value: longest.formattedDuration)
                }
            case .custom:
                if let best = allSets.max(by: { $0.customValue < $1.customValue }) {
                    PRRow(label: "Best", value: String(format: "%.1f %@", best.customValue, best.customLabel ?? ""))
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        } // end else
    }

    // MARK: Helpers

    struct ChartPoint {
        let date: Date
        let value: Double
    }

    private func chartData(for activity: CDActivity) -> [ChartPoint] {
        activity.sortedEntries
            .filter { entry in
                guard let date = entry.workout?.date else { return false }
                if let cutoff = cutoffDate { return date >= cutoff }
                return true
            }
            .compactMap { entry -> ChartPoint? in
                guard let date = entry.workout?.date, let set = entry.bestSet else { return nil }
                return ChartPoint(date: date, value: activity.metric.chartValue(from: set))
            }
            .sorted { $0.date < $1.date }
    }

    private func allSetsForActivity(_ activity: CDActivity) -> [CDEntrySet] {
        activity.sortedEntries.flatMap { $0.sortedSets }
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
