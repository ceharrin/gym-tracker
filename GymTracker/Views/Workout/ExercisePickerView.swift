import SwiftUI
import CoreData

struct ExercisePickerView: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss

    @FetchRequest private var activities: FetchedResults<CDActivity>

    let onSelect: (CDActivity) -> Void

    @State private var searchText = ""
    @State private var selectedCategory: ActivityCategory? = nil
    @State private var showingAddActivity = false

    init(onSelect: @escaping (CDActivity) -> Void) {
        self.onSelect = onSelect
        _activities = FetchRequest(fetchRequest: ManagedFetchRequests.activitiesByName(), animation: .default)
    }

    private var filtered: [CDActivity] {
        ActivityFilterPolicy.filteredActivities(
            from: Array(activities),
            searchText: searchText,
            selectedCategory: selectedCategory
        )
    }

    private var grouped: [(ActivityCategory, [CDActivity])] {
        let categories = selectedCategory.map { [$0] } ?? ActivityCategory.allCases
        return categories.compactMap { cat in
            let items = filtered.filter { $0.category == cat.rawValue }
            guard !items.isEmpty else { return nil }
            return (cat, items)
        }
    }

    private var contentState: ActivityFilterPolicy.ContentState {
        ActivityFilterPolicy.contentState(
            totalActivityCount: activities.count,
            filteredActivityCount: filtered.count
        )
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                categoryFilterBar

                switch contentState {
                case .empty:
                    emptyState
                case .noResults:
                    noResultsState
                case .list:
                    activityList
                }
            }
            .navigationTitle("Add Activity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddActivity = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddActivity) {
                AddActivityView()
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Activities Yet", systemImage: "dumbbell")
        } description: {
            Text("Add an activity to start building workouts.")
        } actions: {
            Button("Add Activity") {
                showingAddActivity = true
            }
            .buttonStyle(.borderedProminent)
            .tint(GymTheme.electricBlue)
        }
    }

    private var noResultsState: some View {
        ContentUnavailableView {
            Label("No Matching Activities", systemImage: "magnifyingglass")
        } description: {
            Text(ActivityFilterPolicy.noResultsDescription)
        } actions: {
            Button("Clear Filters") {
                searchText = ""
                selectedCategory = nil
            }
            .buttonStyle(.borderedProminent)
            .tint(GymTheme.electricBlue)
        }
        .searchable(text: $searchText, prompt: "Search activities")
    }

    private var activityList: some View {
        List {
            ForEach(grouped, id: \.0) { category, items in
                Section {
                    ForEach(items) { activity in
                        Button {
                            onSelect(activity)
                            dismiss()
                        } label: {
                            ActivityPickerRow(activity: activity)
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Label(category.displayName, systemImage: category.icon)
                        .foregroundStyle(category.color)
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search activities")
        .listStyle(.insetGrouped)
    }

    private var categoryFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                CategoryFilterChip(
                    label: "All",
                    icon: "square.grid.2x2",
                    isSelected: selectedCategory == nil,
                    color: .gray
                ) {
                    selectedCategory = nil
                }
                ForEach(ActivityCategory.allCases) { cat in
                    CategoryFilterChip(
                        label: cat.displayName,
                        icon: cat.icon,
                        isSelected: selectedCategory == cat,
                        color: cat.color
                    ) {
                        selectedCategory = selectedCategory == cat ? nil : cat
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
        .background(Color(.systemBackground))
        .overlay(alignment: .bottom) {
            Divider()
        }
    }
}

struct ActivityPickerRow: View {
    let activity: CDActivity

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(activity.activityCategory.color.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: activity.icon)
                    .font(.footnote)
                    .foregroundStyle(activity.activityCategory.color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(activity.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                if let muscles = activity.muscleGroups, !muscles.isEmpty {
                    Text(muscles)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Text(activity.metric.displayName)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

struct CategoryFilterChip: View {
    let label: String
    let icon: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text(label)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? color : Color(.secondarySystemBackground))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
