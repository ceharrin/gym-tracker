import SwiftUI
import CoreData

struct HomeView: View {
    @Environment(\.managedObjectContext) private var context
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \CDWorkout.date, ascending: false)],
        animation: .default
    ) private var workouts: FetchedResults<CDWorkout>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \CDUserProfile.createdAt, ascending: true)],
        animation: .default
    ) private var profiles: FetchedResults<CDUserProfile>

    @State private var showingLogWorkout = false

    private var profile: CDUserProfile? { profiles.first }
    private var recentWorkouts: [CDWorkout] { Array(workouts.prefix(3)) }

    private var greeting: String {
        let name = profile?.name.isEmpty == false ? profile!.name : "Coach"
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good morning, \(name)"
        case 12..<17: return "Good afternoon, \(name)"
        default: return "Good evening, \(name)"
        }
    }

    private var weeklyWorkoutCount: Int {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return workouts.filter { $0.date >= weekAgo }.count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    headerSection
                    statsRow
                    startWorkoutButton
                    if !recentWorkouts.isEmpty {
                        recentSection
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .navigationTitle("GymTracker")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingLogWorkout) {
                LogWorkoutView()
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(greeting)
                .font(.title2)
                .fontWeight(.semibold)
            Text(Date(), style: .date)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            StatCard(
                value: "\(weeklyWorkoutCount)",
                label: "This Week",
                icon: "flame.fill",
                color: .orange
            )
            StatCard(
                value: "\(workouts.count)",
                label: "Total Sessions",
                icon: "checkmark.seal.fill",
                color: .green
            )
            StatCard(
                value: latestWeightString,
                label: "Current Weight",
                icon: "scalemass.fill",
                color: .blue,
                trend: profile?.weightTrend
            )
        }
    }

    private var latestWeightString: String {
        guard let kg = profile?.latestWeight?.weightKg, kg > 0 else { return "—" }
        return Units.displayWeight(kg: kg)
    }

    private var startWorkoutButton: some View {
        Button {
            showingLogWorkout = true
        } label: {
            Label("Start Workout", systemImage: "plus.circle.fill")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Workouts")
                .font(.headline)

            ForEach(recentWorkouts) { workout in
                NavigationLink {
                    WorkoutDetailView(workout: workout)
                } label: {
                    WorkoutSummaryRow(workout: workout, style: .card)
                }
                .buttonStyle(.plain)
            }

            if workouts.count > 3 {
                NavigationLink("See all history →") {
                    WorkoutListView()
                }
                .font(.subheadline)
                .foregroundStyle(Color.accentColor)
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }
}

struct StatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    var trend: WeightTrend? = nil

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .overlay(alignment: .topTrailing) {
                    if let trend, trend != .none {
                        Image(systemName: trend == .up ? "arrow.up" : (trend == .down ? "arrow.down" : "minus"))
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(trend == .up ? Color.red : (trend == .down ? Color.green : Color.secondary))
                            .offset(x: 10, y: -2)
                    }
                }
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
