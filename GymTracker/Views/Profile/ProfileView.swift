import SwiftUI
import CoreData
import UIKit
import UniformTypeIdentifiers

struct ProfileView: View {
    @Environment(\.managedObjectContext) private var context
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \CDUserProfile.createdAt, ascending: true)],
        animation: .default
    ) private var profiles: FetchedResults<CDUserProfile>
    @FetchRequest(
        sortDescriptors: [],
        animation: .default
    ) private var workouts: FetchedResults<CDWorkout>
    @FetchRequest(
        sortDescriptors: [],
        animation: .default
    ) private var measurements: FetchedResults<CDBodyMeasurement>
    @FetchRequest(
        sortDescriptors: [],
        predicate: NSPredicate(format: "isPreset == NO"),
        animation: .default
    ) private var customActivities: FetchedResults<CDActivity>

    @State private var showingEdit = false
    @State private var showingActivityLibrary = false
    @State private var backupShareURL: URL? = nil
    @State private var showingBackupShare = false
    @State private var backupError: String? = nil
    @State private var isExportingBackup = false
    @State private var showingBackupImporter = false
    @State private var isImportingBackup = false
    @State private var backupStatusMessage: String? = nil
    @State private var pendingBackupImportURL: URL? = nil
    @State private var pendingBackupImportWarning: LocalBackupImportWarning? = nil

    private var profile: CDUserProfile? { profiles.first }
    private var hasMeaningfulBackupData: Bool {
        if !workouts.isEmpty || !measurements.isEmpty || !customActivities.isEmpty {
            return true
        }
        guard let profile else { return false }
        return !profile.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
            profile.heightCm > 0 ||
            profile.birthDate != nil ||
            !(profile.goals?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true) ||
            profile.photoData != nil
    }

    var body: some View {
        NavigationStack {
            ZStack {
                GymTheme.appBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        if let profile {
                            ProfileDataView(profile: profile)
                        }
                        localDataSection
                        activityLibraryButton
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.white.opacity(0.92), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
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
            .sheet(isPresented: $showingBackupShare, onDismiss: { backupShareURL = nil }) {
                if let url = backupShareURL {
                    ShareSheet(items: [url])
                }
            }
            .fileImporter(
                isPresented: $showingBackupImporter,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                handleBackupImport(result)
            }
            .alert("Backup Error", isPresented: Binding(
                get: { backupError != nil },
                set: { if !$0 { backupError = nil } }
            )) {
                Button("OK", role: .cancel) { backupError = nil }
            } message: {
                Text(backupError ?? "An unknown error occurred.")
            }
            .alert("Backup Updated", isPresented: Binding(
                get: { backupStatusMessage != nil },
                set: { if !$0 { backupStatusMessage = nil } }
            )) {
                Button("OK", role: .cancel) { backupStatusMessage = nil }
            } message: {
                Text(backupStatusMessage ?? "")
            }
            .alert("Replace Local Data?", isPresented: Binding(
                get: { pendingBackupImportWarning?.requiresConfirmation == true },
                set: { if !$0 { pendingBackupImportWarning = nil; pendingBackupImportURL = nil } }
            )) {
                Button("Replace", role: .destructive) {
                    guard let fileURL = pendingBackupImportURL else { return }
                    beginBackupImport(from: fileURL)
                }
                Button("Cancel", role: .cancel) {
                    pendingBackupImportURL = nil
                    pendingBackupImportWarning = nil
                }
            } message: {
                Text(pendingBackupImportWarning?.message ?? "")
            }
        }
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
            .gymCard()
        }
        .buttonStyle(.plain)
    }

    private var localDataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Local Data & Backup", systemImage: "externaldrive.badge.checkmark")
                .font(.headline)

            Text("GymTracker stores your data on this device for version 1. If you delete the app, your workouts, profile, measurements, and custom activities will be removed from this device.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button {
                exportBackup()
            } label: {
                HStack {
                    if isExportingBackup {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Image(systemName: "square.and.arrow.up")
                    }
                    Text(isExportingBackup ? "Preparing Backup..." : "Export Local Backup")
                    Spacer()
                }
                .padding(14)
                .background(GymTheme.electricBlue.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(isExportingBackup || isImportingBackup || !hasMeaningfulBackupData)

            Button {
                showingBackupImporter = true
            } label: {
                HStack {
                    if isImportingBackup {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Image(systemName: "square.and.arrow.down")
                    }
                    Text(isImportingBackup ? "Importing Backup..." : "Import Local Backup")
                    Spacer()
                }
                .padding(14)
                .background(GymTheme.buttonBackground.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(isExportingBackup || isImportingBackup)

            Text(hasMeaningfulBackupData
                 ? "Export a backup before deleting the app or moving to a new phone. Importing a backup replaces the current local data on this device."
                 : "Add a workout, measurement, custom activity, or profile details before exporting your first backup.")
                .font(.caption)
                .foregroundStyle(GymTheme.steel)
        }
        .padding(16)
        .gymCard()
    }

    private func exportBackup() {
        guard !isExportingBackup else { return }
        isExportingBackup = true
        Task { @MainActor in
            defer { isExportingBackup = false }
            do {
                backupShareURL = try LocalBackupExporter.exportBackup(from: context)
                showingBackupShare = true
            } catch {
                backupError = error.localizedDescription
            }
        }
    }

    private func handleBackupImport(_ result: Result<[URL], Error>) {
        guard !isImportingBackup else { return }

        switch result {
        case .success(let urls):
            guard let fileURL = urls.first else { return }
            let warning = LocalBackupExporter.importWarning(
                workoutCount: workouts.count,
                measurementCount: measurements.count,
                customActivityCount: customActivities.count,
                hasProfileDetails: hasMeaningfulProfileDetails
            )
            if warning.requiresConfirmation {
                pendingBackupImportURL = fileURL
                pendingBackupImportWarning = warning
            } else {
                beginBackupImport(from: fileURL)
            }
        case .failure(let error):
            backupError = error.localizedDescription
        }
    }

    private var hasMeaningfulProfileDetails: Bool {
        guard let profile else { return false }
        return !profile.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
            profile.heightCm > 0 ||
            profile.birthDate != nil ||
            !(profile.goals?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true) ||
            profile.photoData != nil
    }

    private func beginBackupImport(from fileURL: URL) {
        pendingBackupImportURL = nil
        pendingBackupImportWarning = nil
        isImportingBackup = true
        Task { @MainActor in
            defer { isImportingBackup = false }
            do {
                try LocalBackupExporter.importBackup(from: fileURL, into: context)
                backupStatusMessage = "Your local GymTracker data was restored from the selected backup."
            } catch {
                backupError = error.localizedDescription
            }
        }
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
                        .fill(GymTheme.buttonBackground.opacity(0.16))
                        .frame(width: 90, height: 90)
                    Image(systemName: "person.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(GymTheme.electricBlue)
                }
            }
            Text(profile.name.isEmpty ? "Your Name" : profile.name)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
            if let goals = profile.goals, !goals.isEmpty {
                Text(goals)
                    .font(.subheadline)
                    .foregroundStyle(Color.white.opacity(0.72))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
        .padding(.bottom, 8)
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
        .gymCard(dark: true)
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
        .gymCard()
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
        .gymCard(cornerRadius: 16)
    }
}
