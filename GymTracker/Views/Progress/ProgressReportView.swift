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
        if let record = activity.progressPrimaryRecordSummary(cutoffDate: cutoffDate) {
            Divider()
            HStack {
                Image(systemName: "trophy.fill").foregroundStyle(.orange)
                Text("Personal Best").font(.caption).fontWeight(.semibold)
                Spacer()
                Text(record)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Data helpers

    private var chartPoints: [ProgressChartPoint] { activity.progressChartPoints(cutoffDate: cutoffDate) }

    private var yLabel: String { activity.metric.chartYLabel }
}
