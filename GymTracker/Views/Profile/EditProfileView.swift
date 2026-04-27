import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss

    let profile: CDUserProfile?

    @State private var name: String = ""
    @State private var birthDate: Date = Calendar.current.date(byAdding: .year, value: -30, to: Date()) ?? Date()
    @State private var hasBirthDate: Bool = false
    @State private var heightCm: String = ""
    @State private var heightFeet: String = ""
    @State private var heightInches: String = ""
    @State private var weightInput: String = ""
    @State private var goals: String = ""
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var pendingPhotoData: Data? = nil
    @State private var saveError: String? = nil

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Spacer()
                        PhotosPicker(selection: $selectedPhotoItem, matching: .images, photoLibrary: .shared()) {
                            ZStack(alignment: .bottomTrailing) {
                                avatarPreview
                                Image(systemName: "camera.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(Color.accentColor)
                                    .background(Color(.systemBackground).clipShape(Circle()))
                            }
                        }
                        .buttonStyle(.plain)
                        Spacer()
                    }
                }
                .onChange(of: selectedPhotoItem) { _, item in
                    Task {
                        pendingPhotoData = try? await item?.loadTransferable(type: Data.self)
                    }
                }

                Section("Personal Info") {
                    TextField("Name", text: $name)
                    Toggle("Date of Birth", isOn: $hasBirthDate)
                    if hasBirthDate {
                        DatePicker("Birthday", selection: $birthDate, displayedComponents: .date)
                    }
                    if Units.isMetric {
                        HStack {
                            TextField("Height (cm)", text: $heightCm)
                                .keyboardType(.decimalPad)
                            Text("cm").foregroundStyle(.secondary)
                        }
                    } else {
                        HStack(spacing: 8) {
                            TextField("ft", text: $heightFeet)
                                .keyboardType(.numberPad)
                                .frame(maxWidth: .infinity)
                            Text("ft").foregroundStyle(.secondary)
                            TextField("in", text: $heightInches)
                                .keyboardType(.numberPad)
                                .frame(maxWidth: .infinity)
                            Text("in").foregroundStyle(.secondary)
                        }
                    }
                    HStack {
                        TextField("Weight (\(Units.weightUnit))", text: $weightInput)
                            .keyboardType(.decimalPad)
                        Text(Units.weightUnit)
                            .foregroundStyle(.secondary)
                    }
                }
                Section("Goals") {
                    TextField("What are your fitness goals?", text: $goals, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                }
            }
            .onAppear { loadProfile() }
            .alert("Couldn't Save Profile", isPresented: Binding(
                get: { saveError != nil },
                set: { if !$0 { saveError = nil } }
            )) {
                Button("OK", role: .cancel) { saveError = nil }
            } message: {
                Text(saveError ?? "An unknown error occurred.")
            }
        }
    }

    @ViewBuilder
    private var avatarPreview: some View {
        if let data = pendingPhotoData ?? profile?.photoData,
           let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: 80, height: 80)
                .clipShape(Circle())
        } else {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 80, height: 80)
                Image(systemName: "person.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(Color.accentColor)
            }
        }
    }

    private func loadProfile() {
        guard let p = profile else { return }
        name = p.name
        if p.heightCm > 0 {
            if Units.isMetric {
                heightCm = String(format: "%.0f", p.heightCm)
            } else {
                heightFeet = "\(Units.heightFeet(fromCm: p.heightCm))"
                heightInches = "\(Units.heightInches(fromCm: p.heightCm))"
            }
        }
        if let kg = p.latestWeight?.weightKg, kg > 0 {
            weightInput = String(format: "%.1f", Units.weightValue(fromKg: kg))
        }
        goals = p.goals ?? ""
        if let bd = p.birthDate {
            birthDate = bd
            hasBirthDate = true
        }
    }

    private func save() {
        let p = profile ?? CDUserProfile(context: context)
        var createdMeasurement: CDBodyMeasurement?
        if profile == nil {
            p.createdAt = Date()
        }
        p.name = name
        if Units.isMetric {
            p.heightCm = Double(heightCm) ?? p.heightCm
        } else {
            let ft = Int(heightFeet) ?? 0
            let inches = Int(heightInches) ?? 0
            if ft > 0 || inches > 0 {
                p.heightCm = Units.cmFromFeetInches(feet: ft, inches: inches)
            }
        }
        p.goals = goals.isEmpty ? nil : goals
        p.birthDate = hasBirthDate ? birthDate : nil
        if let inputVal = Double(weightInput), inputVal > 0 {
            let newKg = Units.kgFromInput(inputVal)
            let latestKg = p.latestWeight?.weightKg ?? 0
            if abs(newKg - latestKg) > 0.01 {
                let m = CDBodyMeasurement(context: context)
                m.id = UUID()
                m.date = Date()
                m.healthDataSource = .local
                m.healthKitSyncState = .notSynced
                m.weightKg = newKg
                m.profile = p
                createdMeasurement = m
            }
        }
        if let data = pendingPhotoData {
            p.photoData = data
        }
        do {
            try context.saveIfChanged()
            if let createdMeasurement {
                Task { await WorkoutHealthKitManager.shared.syncBodyMeasurement(createdMeasurement) }
            }
            dismiss()
        } catch {
            saveError = error.localizedDescription
        }
    }
}

struct AddMeasurementView: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss

    let profile: CDUserProfile?

    @State private var weightInput: String = ""
    @State private var bodyFatPercent: String = ""
    @State private var notes: String = ""
    @State private var date: Date = Date()
    @State private var saveError: String? = nil

    var body: some View {
        NavigationStack {
            Form {
                Section("Measurement") {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    HStack {
                        TextField("Weight", text: $weightInput)
                            .keyboardType(.decimalPad)
                        Text(Units.weightUnit)
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        TextField("Body Fat % (optional)", text: $bodyFatPercent)
                            .keyboardType(.decimalPad)
                        Text("%")
                            .foregroundStyle(.secondary)
                    }
                }
                Section("Notes") {
                    TextField("Optional notes", text: $notes)
                }
            }
            .navigationTitle("Log Weight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(weightInput.isEmpty)
                }
            }
            .alert("Couldn't Save Measurement", isPresented: Binding(
                get: { saveError != nil },
                set: { if !$0 { saveError = nil } }
            )) {
                Button("OK", role: .cancel) { saveError = nil }
            } message: {
                Text(saveError ?? "An unknown error occurred.")
            }
        }
    }

    private func save() {
        guard let inputVal = Double(weightInput), inputVal > 0, let profile else { return }
        let m = CDBodyMeasurement(context: context)
        m.id = UUID()
        m.date = date
        m.healthDataSource = .local
        m.healthKitSyncState = .notSynced
        m.weightKg = Units.kgFromInput(inputVal)
        m.bodyFatPercent = Double(bodyFatPercent) ?? 0
        m.notes = notes.isEmpty ? nil : notes
        m.profile = profile
        do {
            try context.saveIfChanged()
            Task { await WorkoutHealthKitManager.shared.syncBodyMeasurement(m) }
            dismiss()
        } catch {
            saveError = error.localizedDescription
        }
    }
}
