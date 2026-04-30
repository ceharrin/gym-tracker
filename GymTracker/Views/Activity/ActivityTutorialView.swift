import SwiftUI

struct ActivityTutorialView: View {
    let activity: CDActivity
    @Environment(\.dismiss) private var dismiss
    @State private var showingEdit = false

    private var steps: [String] {
        guard let raw = activity.instructions, !raw.isEmpty else { return [] }
        return raw.components(separatedBy: "\n").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    heroSection
                    infoCards
                    if steps.isEmpty {
                        noInstructionsCard
                    } else {
                        stepsSection
                        safetyCard
                    }
                }
                .padding()
            }
            .navigationTitle(activity.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                if !activity.isPreset {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Edit") { showingEdit = true }
                    }
                }
            }
            .sheet(isPresented: $showingEdit) {
                AddActivityView(activity: activity)
            }
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        HStack {
            Spacer()
            VStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 28)
                        .fill(activity.activityCategory.color.opacity(0.15))
                        .frame(width: 110, height: 110)
                    Image(systemName: activity.icon)
                        .font(.system(size: 52))
                        .foregroundStyle(activity.activityCategory.color)
                }
                VStack(spacing: 6) {
                    Text(activity.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    Label(activity.activityCategory.displayName, systemImage: activity.activityCategory.icon)
                        .font(.subheadline)
                        .foregroundStyle(activity.activityCategory.color)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(activity.activityCategory.color.opacity(0.12))
                        .clipShape(Capsule())
                }
            }
            Spacer()
        }
        .padding(.top, 8)
    }

    // MARK: - Info cards

    private var infoCards: some View {
        HStack(spacing: 12) {
            if let muscles = activity.muscleGroups, !muscles.isEmpty {
                infoCard(title: "Muscles", value: muscles, icon: "figure.arms.open")
            }
            infoCard(title: "Tracking", value: activity.metric.displayName, icon: "chart.bar.fill")
        }
    }

    private func infoCard(title: String, value: String, icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(activity.activityCategory.color)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
                Text(value)
                    .font(.caption)
                    .fontWeight(.medium)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Steps

    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How to Perform")
                .font(.headline)
                .fontWeight(.semibold)

            VStack(spacing: 0) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(activity.activityCategory.color)
                                .frame(width: 26, height: 26)
                            Text("\(index + 1)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                        }
                        .padding(.top, 1)
                        Text(step)
                            .font(.subheadline)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 14)

                    if index < steps.count - 1 {
                        Divider()
                            .padding(.leading, 54)
                    }
                }
            }
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Safety

    private var safetyCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
                .font(.subheadline)
                .padding(.top, 1)
            Text("Start lighter than you think you need to. Prioritise form over load or speed. Stop immediately if you feel sharp or sudden pain.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .background(Color.orange.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - No instructions

    private var noInstructionsCard: some View {
        VStack(spacing: 10) {
            Image(systemName: "doc.text")
                .font(.title2)
                .foregroundStyle(.tertiary)
            Text("No instructions added yet.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if !activity.isPreset {
                Button("Add Instructions") { showingEdit = true }
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(28)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
