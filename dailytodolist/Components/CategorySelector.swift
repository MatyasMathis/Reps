//
//  CategorySelector.swift
//  dailytodolist
//
//  Purpose: Category selection grid component for AddTaskSheet
//  Supports built-in categories and user-created custom categories
//

import SwiftUI
import UIKit
import SwiftData

// MARK: - Category Selector

/// Grid-based category selector with icons, supporting custom categories
struct CategorySelector: View {
    @Binding var selectedCategory: String

    @Query(sort: \CustomCategory.sortOrder)
    private var customCategories: [CustomCategory]

    @Environment(\.modelContext) private var modelContext

    @State private var showAddCategory = false
    @State private var editingCategory: CustomCategory?
    @State private var categoryToDelete: CustomCategory?
    @State private var showDeleteConfirmation = false

    private let builtInCategories: [(id: String, icon: String, label: String, color: Color)] = [
        ("Work", "briefcase.fill", "Work", .workBlue),
        ("Personal", "house.fill", "Personal", .personalOrange),
        ("Health", "heart.fill", "Health", .healthGreen),
        ("Shopping", "cart.fill", "Shopping", .shoppingMagenta),
        ("Other", "circle.fill", "Other", .otherGray)
    ]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: Spacing.sm), count: 5)

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("CATEGORY")
                .font(.system(size: Typography.labelSize, weight: .bold))
                .foregroundStyle(Color.mediumGray)
                .tracking(1.0)

            LazyVGrid(columns: columns, spacing: Spacing.sm) {
                // Built-in categories
                ForEach(builtInCategories, id: \.id) { category in
                    CategoryButton(
                        icon: category.icon,
                        label: category.label,
                        color: category.color,
                        isSelected: selectedCategory == category.id
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            if selectedCategory == category.id {
                                selectedCategory = ""
                            } else {
                                selectedCategory = category.id
                            }
                        }
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                    }
                }

                // Custom categories
                ForEach(customCategories) { custom in
                    CategoryButton(
                        icon: custom.iconName,
                        label: custom.name,
                        color: Color(hex: custom.colorHex),
                        isSelected: selectedCategory == custom.name
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            if selectedCategory == custom.name {
                                selectedCategory = ""
                            } else {
                                selectedCategory = custom.name
                            }
                        }
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                    }
                    .contextMenu {
                        Button {
                            editingCategory = custom
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }

                        Button(role: .destructive) {
                            categoryToDelete = custom
                            showDeleteConfirmation = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }

                // Add custom category button with PRO badge
                AddCategoryButton {
                    showAddCategory = true
                }
            }
        }
        .sheet(isPresented: $showAddCategory) {
            AddCategorySheet()
        }
        .sheet(item: $editingCategory) { category in
            AddCategorySheet(editingCategory: category)
        }
        .confirmationDialog(
            "Delete Category",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let cat = categoryToDelete {
                    deleteCategory(cat)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Tasks using this category will keep their name but show default styling.")
        }
    }

    private func deleteCategory(_ category: CustomCategory) {
        // Clear selection if this category was selected
        if selectedCategory == category.name {
            selectedCategory = ""
        }
        modelContext.delete(category)
        try? modelContext.save()
    }
}

// MARK: - Category Button

/// Individual category selection button
struct CategoryButton: View {
    let icon: String
    let label: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: Spacing.xs) {
                ZStack {
                    RoundedRectangle(cornerRadius: CornerRadius.standard)
                        .fill(isSelected ? color.opacity(0.3) : Color.darkGray1)
                        .frame(width: ComponentSize.categoryButton, height: ComponentSize.categoryButton)

                    RoundedRectangle(cornerRadius: CornerRadius.standard)
                        .stroke(isSelected ? color : Color.clear, lineWidth: 2)
                        .frame(width: ComponentSize.categoryButton, height: ComponentSize.categoryButton)

                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundStyle(isSelected ? color : Color.mediumGray)
                }

                Text(label)
                    .font(.system(size: Typography.captionSize, weight: .medium))
                    .foregroundStyle(isSelected ? color : Color.mediumGray)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Add Category Button

/// Button to create a new custom category, shown with PRO badge
struct AddCategoryButton: View {
    let action: () -> Void

    @ObservedObject private var store = StoreKitService.shared
    @State private var showPaywall = false

    var body: some View {
        Button(action: {
            if store.isProUnlocked {
                action()
            } else {
                showPaywall = true
            }
        }) {
            VStack(spacing: Spacing.xs) {
                ZStack {
                    RoundedRectangle(cornerRadius: CornerRadius.standard)
                        .fill(Color.darkGray1)
                        .frame(width: ComponentSize.categoryButton, height: ComponentSize.categoryButton)

                    RoundedRectangle(cornerRadius: CornerRadius.standard)
                        .strokeBorder(Color.mediumGray.opacity(0.5), style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
                        .frame(width: ComponentSize.categoryButton, height: ComponentSize.categoryButton)

                    VStack(spacing: 2) {
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(Color.mediumGray)

                        if !store.isProUnlocked {
                            ProBadge()
                        }
                    }
                }

                Text("Custom")
                    .font(.system(size: Typography.captionSize, weight: .medium))
                    .foregroundStyle(Color.mediumGray)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showPaywall) {
            PaywallView()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Frequency Selector

/// Radio button selector for task frequency
struct FrequencySelector: View {
    @Binding var isRecurring: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("FREQUENCY")
                .font(.system(size: Typography.labelSize, weight: .semibold))
                .foregroundStyle(Color.mediumGray)

            VStack(spacing: 0) {
                FrequencyOption(
                    title: "One Time",
                    subtitle: "Task disappears after completion",
                    isSelected: !isRecurring
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isRecurring = false
                    }
                }

                Divider()
                    .background(Color.darkGray1)

                FrequencyOption(
                    title: "Daily Recurring",
                    subtitle: "Task reappears every day",
                    icon: "repeat",
                    isSelected: isRecurring
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isRecurring = true
                    }
                }
            }
            .background(Color.darkGray2)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.standard))
        }
    }
}

// MARK: - Frequency Option

/// Individual frequency selection option (radio style)
struct FrequencyOption: View {
    let title: String
    let subtitle: String
    var icon: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            action()
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }) {
            HStack(spacing: Spacing.md) {
                // Radio button
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.recoveryGreen : Color.mediumGray, lineWidth: 2)
                        .frame(width: 20, height: 20)

                    if isSelected {
                        Circle()
                            .fill(Color.recoveryGreen)
                            .frame(width: 12, height: 12)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: Spacing.xs) {
                        Text(title)
                            .font(.system(size: Typography.bodySize, weight: .medium))
                            .foregroundStyle(Color.pureWhite)

                        if let icon = icon {
                            Image(systemName: icon)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color.performancePurple)
                        }
                    }

                    Text(subtitle)
                        .font(.system(size: Typography.captionSize, weight: .regular))
                        .foregroundStyle(Color.mediumGray)
                }

                Spacer()
            }
            .padding(Spacing.lg)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview("Selectors") {
    struct PreviewWrapper: View {
        @State private var category = "Work"
        @State private var isRecurring = false

        var body: some View {
            ZStack {
                Color.brandBlack.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: Spacing.section) {
                        CategorySelector(selectedCategory: $category)
                        FrequencySelector(isRecurring: $isRecurring)
                    }
                    .padding(Spacing.xl)
                }
            }
        }
    }

    return PreviewWrapper()
        .modelContainer(for: [TodoTask.self, TaskCompletion.self, CustomCategory.self], inMemory: true)
}
