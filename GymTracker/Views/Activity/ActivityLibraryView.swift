import SwiftUI
import CoreData

struct ActivityLibraryView: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \CDActivity.name, ascending: true)],
        animation: .default
    ) private var activities: FetchedResults<CDActivity>

    @State private var searchText = ""
    @State private var selectedCategory: ActivityCategory? = nil
    @State private var showingAdd = false

    private var filtered: [CDActivity] {
        activities.filter { activity in
            let matchesCat = selectedCategory == nil || activity.category == selectedCategory?.rawValue
            let matchesSearch = searchText.isEmpty ||
                activity.name.localizedCaseInsensitiveContains(searchText) ||
                (activity.muscleGroups?.localizedCaseInsensitiveContains(searchText) ?? false)
            return matchesCat && matchesSearch
        }
    }

    private var grouped: [(ActivityCategory, [CDActivity])] {
        let cats = selectedCategory.map { [$0] } ?? ActivityCategory.allCases
        return cats.compactMap { cat in
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
                            let presets = items.filter(\.isPreset)
                            let custom  = items.filter { !$0.isPreset }
                            ForEach(presets) { activity in
                                ActivityLibraryRow(activity: activity)
                            }
                            ForEach(custom) { activity in
                                ActivityLibraryRow(activity: activity)
                            }
                            .onDelete { deleteItems(from: custom, offsets: $0) }
                        } header: {
                            Label(category.displayName, systemImage: category.icon)
                                .foregroundStyle(category.color)
                        }
                    }
                }
                .searchable(text: $searchText, prompt: "Search library")
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Activity Library")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAdd = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAdd) {
                AddActivityView()
            }
        }
    }

    private var categoryFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                CategoryFilterChip(label: "All", icon: "square.grid.2x2", isSelected: selectedCategory == nil, color: .gray) {
                    selectedCategory = nil
                }
                ForEach(ActivityCategory.allCases) { cat in
                    CategoryFilterChip(label: cat.displayName, icon: cat.icon, isSelected: selectedCategory == cat, color: cat.color) {
                        selectedCategory = selectedCategory == cat ? nil : cat
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
        .background(Color(.systemBackground))
        .overlay(alignment: .bottom) { Divider() }
    }

    private func deleteItems(from items: [CDActivity], offsets: IndexSet) {
        for idx in offsets {
            let activity = items[idx]
            guard !activity.isPreset else { continue }
            context.delete(activity)
        }
        try? context.save()
    }
}

struct ActivityLibraryRow: View {
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
                HStack {
                    Text(activity.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    if !activity.isPreset {
                        Text("Custom")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.accentColor.opacity(0.15))
                            .foregroundStyle(Color.accentColor)
                            .clipShape(Capsule())
                    }
                }
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
