import SwiftUI
import CoreData
import UIKit

struct ProfileView: View {
    @Environment(\.managedObjectContext) private var context
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \CDUserProfile.createdAt, ascending: true)],
        animation: .default
    ) private var profiles: FetchedResults<CDUserProfile>

    @StateObject private var cloudSync = CloudSyncMonitor.shared

    @State private var showingEdit = false
    @State private var showingActivityLibrary = false

    private var profile: CDUserProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if let profile {
                        ProfileDataView(profile: profile)
                    }
                    activityLibraryButton
                    iCloudStatusRow
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Edit") { showingEdit = true }
                }
            }
            .sheet(isPresented: $showingEdit) {
                EditProfileView(profile: profile)
            }
            .sheet(isPresented: $showingActivityLibrary) {
                ActivityLibraryView()
            }
        }
    }

    private var iCloudStatusRow: some View {
        HStack(spacing: 12) {
            Image(systemName: cloudSync.statusIcon)
                .foregroundStyle(cloudSync.isSyncing ? Color.accentColor : .secondary)
                .frame(width: 24)
            Text(cloudSync.statusLabel)
                .font(.subheadline)
                .foregroundStyle(cloudSync.isSyncing ? .primary : .secondary)
            Spacer()
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var activityLibraryButton: some View {
        Button {
            showingActivityLibrary = true
        } label: {
            HStack {
                Image(systemName: "list.bullet.rectangle.fill")
                Text("Activity Library")
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Profile Data (observed)

private struct ProfileDataView: View {
    @ObservedObject var profile: CDUserProfile
    @State private var showingAddWeight = false

    var body: some View {
        Group {
            avatarSection
            statsGrid
            bodyWeightSection
        }
        .sheet(isPresented: $showingAddWeight) {
            AddMeasurementView(profile: profile)
        }
    }

    private var avatarSection: some View {
        VStack(spacing: 10) {
            ZStack {
                if let data = profile.photoData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 90, height: 90)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color.accentColor.opacity(0.15))
                        .frame(width: 90, height: 90)
                    Image(systemName: "person.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(Color.accentColor)
                }
            }
            Text(profile.name.isEmpty ? "Your Name" : profile.name)
                .font(.title2)
                .fontWeight(.semibold)
            if let goals = profile.goals, !goals.isEmpty {
                Text(goals)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 8)
    }

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ProfileStatCell(label: "Age", value: profile.age.map { "\($0)" } ?? "—")
            ProfileStatCell(label: "Height", value: heightString)
            ProfileStatCell(label: "Weight", value: weightString)
        }
    }

    private var heightString: String {
        guard profile.heightCm > 0 else { return "—" }
        return Units.displayHeight(cm: profile.heightCm)
    }

    private var weightString: String {
        guard let kg = profile.latestWeight?.weightKg, kg > 0 else { return "—" }
        return Units.displayWeight(kg: kg)
    }

    private var bodyWeightSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Body Weight")
                    .font(.headline)
                Spacer()
                Button {
                    showingAddWeight = true
                } label: {
                    Label("Log", systemImage: "plus")
                        .font(.subheadline)
                }
            }

            if let measurements = profile.sortedMeasurements as [CDBodyMeasurement]?, !measurements.isEmpty {
                ForEach(measurements.suffix(5).reversed()) { m in
                    HStack {
                        Text(m.date, style: .date)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(Units.displayWeight(kg: m.weightKg))
                            .font(.subheadline)
                            .fontWeight(.medium)
                        if m.bodyFatPercent > 0 {
                            Text(String(format: "%.1f%% BF", m.bodyFatPercent))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                    Divider()
                }
            } else {
                Text("No measurements yet. Log your first weigh-in!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Stat Cell

struct ProfileStatCell: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
