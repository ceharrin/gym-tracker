import SwiftUI
import CoreData

struct ExercisePickerView: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \CDActivity.name, ascending: true)],
        animation: .default
    ) private var activities: FetchedResults<CDActivity>

    let onSelect: (CDActivity) -> Void

    @State private var searchText = ""
    @State private var selectedCategory: ActivityCategory? = nil
    @State private var showingAddActivity = false

    private var filtered: [CDActivity] {
        activities.filter { activity in
            let matchesCategory = selectedCategory == nil || activity.category == selectedCategory?.rawValue
            let matchesSearch = searchText.isEmpty ||
                activity.name.localizedCaseInsensitiveContains(searchText) ||
                (activity.muscleGroups?.localizedCaseInsensitiveContains(searchText) ?? false)
            return matchesCategory && matchesSearch
        }
    }

    private var grouped: [(ActivityCategory, [CDActivity])] {
        let categories = selectedCategory.map { [$0] } ?? ActivityCategory.allCases
        return categories.compactMap { cat in
            let items = filtered.filter { $0.category == cat.rawValue }
            guard !items.isEmpty else { return nil }
            return (cat, items)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                categoryFilterBar

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
