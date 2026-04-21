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

    @State private var selectedActivity: CDActivity? = nil
    @State private var selectedRange: DateRange = .threeMonths

    enum DateRange: String, CaseIterable {
        case oneMonth   = "1M"
        case threeMonths = "3M"
        case sixMonths  = "6M"
        case oneYear    = "1Y"
        case allTime    = "All"

        var days: Int? {
            switch self {
            case .oneMonth: return 30
            case .threeMonths: return 90
            case .sixMonths: return 180
            case .oneYear: return 365
            case .allTime: return nil
            }
        }
    }

    private var profile: CDUserProfile? { profiles.first }

    private var cutoffDate: Date? {
        guard let days = selectedRange.days else { return nil }
        return Calendar.current.date(byAdding: .day, value: -days, to: Date())
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    rangeSelector
                    bodyWeightChart
                    activityPicker
                    if let activity = selectedActivity {
                        activityChart(for: activity)
                        personalRecordCard(for: activity)
                    } else {
                        activityPlaceholder
                    }
                }
                .padding()
            }
            .navigationTitle("Progress")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: Range Selector

    private var rangeSelector: some View {
        Picker("Range", selection: $selectedRange) {
            ForEach(DateRange.allCases, id: \.self) { range in
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
                emptyChartPlaceholder(message: "Log weight in your Profile to see trends here.")
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
                            selectedActivity = selectedActivity?.id == activity.id ? nil : activity
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
                            .background(selectedActivity?.id == activity.id
                                ? activity.activityCategory.color
                                : Color(.secondarySystemBackground))
                            .foregroundStyle(selectedActivity?.id == activity.id ? .white : .primary)
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
            Text("Select an activity above to see your progress chart.")
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
                Text(chartYLabel(for: activity))
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
                            y: .value(chartYLabel(for: activity), point.value)
                        )
                        .foregroundStyle(activity.activityCategory.color)
                        .interpolationMethod(.catmullRom)

                        PointMark(
                            x: .value("Date", point.date),
                            y: .value(chartYLabel(for: activity), point.value)
                        )
                        .foregroundStyle(activity.activityCategory.color)
                        .annotation(position: .top) {
                            Text(formattedValue(point.value, metric: activity.metric))
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
        let entries = activity.sortedEntries.filter { entry in
            guard let date = entry.workout?.date else { return false }
            if let cutoff = cutoffDate { return date >= cutoff }
            return true
        }

        return entries.compactMap { entry -> ChartPoint? in
            guard let date = entry.workout?.date,
                  let set = entry.bestSet else { return nil }
            let value: Double
            switch activity.metric {
            case .weightReps:   value = Units.weightValue(fromKg: set.weightKg)
            case .distanceTime: value = Units.distanceValue(fromMeters: set.distanceMeters)
            case .lapsTime:     value = Double(set.laps)
            case .duration:     value = Double(set.durationSeconds) / 60
            case .custom:       value = set.customValue
            }
            return ChartPoint(date: date, value: value)
        }
        .sorted { $0.date < $1.date }
    }

    private func chartYLabel(for activity: CDActivity) -> String {
        switch activity.metric {
        case .weightReps:   return Units.weightUnit
        case .distanceTime: return Units.distanceUnit
        case .lapsTime:     return "laps"
        case .duration:     return "min"
        case .custom:       return "value"
        }
    }

    private func formattedValue(_ value: Double, metric: PrimaryMetric) -> String {
        switch metric {
        case .weightReps:   return String(format: "%.1f", value)
        case .distanceTime: return String(format: "%.1f", value)
        case .lapsTime:     return String(format: "%.0f", value)
        case .duration:     return String(format: "%.0f", value)
        case .custom:       return String(format: "%.1f", value)
        }
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
