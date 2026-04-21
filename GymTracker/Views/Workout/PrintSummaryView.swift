import SwiftUI

struct PrintSummaryView: View {
    let allWorkouts: [CDWorkout]

    @Environment(\.dismiss) private var dismiss

    @State private var fromDate: Date = Calendar.current.date(
        byAdding: .month, value: -1, to: Date()) ?? Date()
    @State private var toDate: Date = Date()

    private var filtered: [CDWorkout] {
        allWorkouts.filter { $0.date >= fromDate && $0.date <= endOfDay(toDate) }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Date Range") {
                    DatePicker("From", selection: $fromDate, in: ...toDate, displayedComponents: .date)
                    DatePicker("To", selection: $toDate, in: fromDate..., displayedComponents: .date)
                }

                Section("Preview") {
                    HStack {
                        Text("Workouts in range")
                        Spacer()
                        Text("\(filtered.count)")
                            .foregroundStyle(.secondary)
                    }
                    let totalMin = filtered.reduce(0) { $0 + Int($1.durationMinutes) }
                    if totalMin > 0 {
                        HStack {
                            Text("Total duration")
                            Spacer()
                            Text("\(totalMin) min")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section {
                    Button {
                        let html = WorkoutHTMLFormatter.summaryHTML(
                            workouts: filtered, from: fromDate, to: toDate)
                        PrintCoordinator.printHTML(html, jobName: "Workout Summary")
                    } label: {
                        Label("Print Summary", systemImage: "printer")
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(filtered.isEmpty)
                }
            }
            .navigationTitle("Print Summary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func endOfDay(_ date: Date) -> Date {
        Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: date) ?? date
    }
}
