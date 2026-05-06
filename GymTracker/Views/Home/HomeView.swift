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

    @State private var startDestination: WorkoutStartDestination? = nil
    @State private var navigationPath: [WorkoutNavigationRoute] = []

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
        NavigationStack(path: $navigationPath) {
            ZStack {
                GymTheme.appBackground.ignoresSafeArea()

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
            }
            .navigationTitle("GymTracker")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.white.opacity(0.92), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .sheet(item: $startDestination) { destination in
                if let workout = destination.workout {
                    LogWorkoutView(workout: workout)
                } else {
                    LogWorkoutView()
                }
            }
            .navigationDestination(for: WorkoutNavigationRoute.self) { route in
                if let workout = workouts.first(where: { $0.objectID == route.workoutObjectID }) {
                    WorkoutNavigationDestination(workout: workout, mode: route.mode)
                } else {
                    Color.clear
                }
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("TRAINING DAY")
                        .font(.caption)
                        .fontWeight(.bold)
                        .tracking(1.8)
                        .foregroundStyle(GymTheme.brightBlue)
                    Text(greeting)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    Text(Date(), style: .date)
                        .font(.subheadline)
                        .foregroundStyle(Color.white.opacity(0.72))
                }

                Spacer()

                ZStack {
                    Circle()
                        .fill(.white.opacity(0.12))
                        .frame(width: 58, height: 58)
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.title2)
                        .foregroundStyle(.white)
                }
            }

            HStack(spacing: 10) {
                Label("Built for momentum", systemImage: "bolt.fill")
                Label("Clean logbook", systemImage: "chart.line.uptrend.xyaxis")
            }
            .font(.caption)
            .foregroundStyle(Color.white.opacity(0.82))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(22)
        .padding(.top, 8)
        .gymCard(cornerRadius: 28, dark: true)
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
            startDestination = WorkoutStartCoordinator.startDestination(from: Array(workouts))
        } label: {
            Label("Start Workout", systemImage: "plus.circle.fill")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(GymTheme.buttonBackground)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: GymTheme.electricBlue.opacity(0.30), radius: 16, x: 0, y: 10)
        }
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Workouts")
                    .font(.headline)
                Spacer()
                Text("Your latest sessions")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ForEach(recentWorkouts) { workout in
                Button {
                    navigationPath.append(WorkoutNavigationRoute(workout: workout))
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
        .gymCard(cornerRadius: 18)
    }
}
