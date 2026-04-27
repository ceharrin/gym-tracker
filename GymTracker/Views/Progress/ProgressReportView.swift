import SwiftUI
import Charts

/// Standalone view rendered to PDF by ProgressExporter via ImageRenderer.
/// Fixed-width, light-mode, no interactivity.
struct ProgressReportView: View {
    let activities: [CDActivity]
    let range: ProgressDateRange

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            header
            if activities.isEmpty {
                Text("No activity data to export.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(activities) { activity in
                    ActivityExportCard(activity: activity, cutoffDate: range.cutoffDate)
                }
            }
        }
        .padding(24)
        .frame(width: 600, alignment: .leading)
        .background(Color.white)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Progress Report")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.black)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Divider().padding(.top, 4)
        }
    }

    private var subtitle: String {
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        let label = range == .allTime ? "All Time" : "Last \(range.rawValue)"
        return "GymTracker · \(fmt.string(from: Date())) · \(label)"
    }
}

// MARK: - Per-activity card

private struct ActivityExportCard: View {
    let activity: CDActivity
    let cutoffDate: Date?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            activityHeader
            chartSection
            prSection
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var activityHeader: some View {
        HStack(spacing: 8) {
            Image(systemName: activity.activityCategory.icon)
                .foregroundStyle(activity.activityCategory.color)
            Text(activity.name)
                .font(.headline)
                .foregroundStyle(.primary)
        }
    }

    @ViewBuilder
    private var chartSection: some View {
        let points = chartPoints
        if points.isEmpty {
            Text("No data in selected range.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 16)
        } else {
            Chart {
                ForEach(points, id: \.date) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value(yLabel, point.value)
                    )
                    .foregroundStyle(activity.activityCategory.color)
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Date", point.date),
                        y: .value(yLabel, point.value)
                    )
                    .foregroundStyle(activity.activityCategory.color)
                    .annotation(position: .top) {
                        Text(activity.metric.formattedChartValue(point.value))
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .chartYAxis { AxisMarks(position: .leading) }
            .frame(height: 180)
        }
    }

    @ViewBuilder
    private var prSection: some View {
        let allSets = activity.sortedEntries
            .filter { entry in
                guard let date = entry.workout?.date else { return false }
                if let cutoffDate { return date >= cutoffDate }
                return true
            }
            .flatMap { $0.sortedSets }

        if !allSets.isEmpty {
            Divider()
            HStack {
                Image(systemName: "trophy.fill").foregroundStyle(.orange)
                Text("Personal Best").font(.caption).fontWeight(.semibold)
                Spacer()
                Text(prText(from: allSets))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Data helpers

    private struct ChartPoint { let date: Date; let value: Double }

    private var chartPoints: [ChartPoint] {
        activity.sortedEntries
            .filter { entry in
                guard let date = entry.workout?.date else { return false }
                if let cutoffDate { return date >= cutoffDate }
                return true
            }
            .compactMap { entry -> ChartPoint? in
                guard let date = entry.workout?.date, let set = entry.bestSet else { return nil }
                return ChartPoint(date: date, value: activity.metric.chartValue(from: set))
            }
            .sorted { $0.date < $1.date }
    }

    private var yLabel: String { activity.metric.chartYLabel }

    private func prText(from sets: [CDEntrySet]) -> String {
        switch activity.metric {
        case .weightReps:
            if let best = sets.max(by: { $0.weightKg < $1.weightKg }) {
                return "\(Units.displayWeight(kg: best.weightKg)) × \(best.reps) reps"
            }
        case .distanceTime:
            if let best = sets.max(by: { $0.distanceMeters < $1.distanceMeters }) {
                return Units.displayDistance(meters: best.distanceMeters)
            }
        case .lapsTime:
            if let best = sets.max(by: { $0.laps < $1.laps }) { return "\(best.laps) laps" }
        case .duration:
            if let best = sets.max(by: { $0.durationSeconds < $1.durationSeconds }) {
                return best.formattedDuration
            }
        case .custom:
            if let best = sets.max(by: { $0.customValue < $1.customValue }) {
                return String(format: "%.1f %@", best.customValue, best.customLabel ?? "")
            }
        }
        return ""
    }
}
