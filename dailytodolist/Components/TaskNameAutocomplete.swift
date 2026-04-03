//
//  TaskNameAutocomplete.swift
//  dailytodolist
//
//  Purpose: Autocomplete text field for task names that suggests existing tasks
//  When an existing task is selected, the form switches to edit mode
//

import SwiftUI
import SwiftData

/// Autocomplete text field for task names with dropdown suggestions
///
/// Features:
/// - Shows dropdown with matching tasks as user types (partial matching)
/// - Selecting an existing task triggers edit mode callback
/// - Supports creating new tasks when no match is selected
struct TaskNameAutocomplete: View {

    // MARK: - Properties

    /// All existing tasks to search through
    let existingTasks: [TodoTask]

    /// Bound text value for the task name
    @Binding var text: String

    /// Whether the text field is focused
    var isFocused: FocusState<Bool>.Binding

    /// Callback when an existing task is selected (switches to edit mode)
    var onTaskSelected: ((TodoTask) -> Void)?

    // MARK: - State

    @State private var showDropdown: Bool = false

    // MARK: - Computed Properties

    /// Filtered tasks matching the search text (partial, case-insensitive)
    private var matchingTasks: [TodoTask] {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }

        let searchText = text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        return existingTasks
            .filter { $0.title.lowercased().contains(searchText) }
            .sorted { task1, task2 in
                // Prioritize tasks that start with the search text
                let title1 = task1.title.lowercased()
                let title2 = task2.title.lowercased()
                let startsWithSearch1 = title1.hasPrefix(searchText)
                let startsWithSearch2 = title2.hasPrefix(searchText)

                if startsWithSearch1 && !startsWithSearch2 { return true }
                if !startsWithSearch1 && startsWithSearch2 { return false }

                // Then sort alphabetically
                return title1 < title2
            }
    }

    /// Whether to show the dropdown
    private var shouldShowDropdown: Bool {
        showDropdown && !matchingTasks.isEmpty && isFocused.wrappedValue
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Text field
            TextField("", text: $text, prompt: Text("Enter task name...")
                .foregroundStyle(Color.mediumGray))
                .font(.system(size: Typography.h4Size, weight: .semibold))
                .foregroundStyle(Color.pureWhite)
                .padding(Spacing.lg)
                .background(Color.darkGray1)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.standard))
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.standard)
                        .stroke(isFocused.wrappedValue ? Color.recoveryGreen : Color.clear, lineWidth: 2)
                )
                .focused(isFocused)
                .onChange(of: text) { _, newValue in
                    // Show dropdown when user types
                    showDropdown = !newValue.isEmpty
                }

            // Dropdown suggestions
            if shouldShowDropdown {
                dropdownView
            }
        }
    }

    // MARK: - Subviews

    private var dropdownView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header hint
            HStack {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.workBlue)
                Text("Existing tasks found - tap to edit instead")
                    .font(.system(size: Typography.captionSize, weight: .medium))
                    .foregroundStyle(Color.mediumGray)
                Spacer()
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(Color.darkGray1)

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(matchingTasks.prefix(5)) { task in
                        TaskSuggestionRow(task: task, searchText: text) {
                            selectTask(task)
                        }
                    }
                }
            }
            .frame(maxHeight: 200)
        }
        .background(Color.darkGray1)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.standard))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.standard)
                .stroke(Color.mediumGray.opacity(0.3), lineWidth: 1)
        )
        .padding(.top, Spacing.xs)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    // MARK: - Methods

    private func selectTask(_ task: TodoTask) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            showDropdown = false
            onTaskSelected?(task)
        }
    }
}

// MARK: - Task Suggestion Row

/// Individual row in the autocomplete dropdown
struct TaskSuggestionRow: View {
    let task: TodoTask
    let searchText: String
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: Spacing.md) {
                // Edit icon
                Image(systemName: "pencil.circle.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(Color.recoveryGreen)

                VStack(alignment: .leading, spacing: 2) {
                    // Task title with highlighted match
                    highlightedTitle

                    // Recurrence/Category badge
                    if task.recurrenceType != .none {
                        Text(task.recurrenceType.displayName)
                            .font(.system(size: Typography.captionSize, weight: .medium))
                            .foregroundStyle(Color.mediumGray)
                    } else if let category = task.category {
                        Text(category)
                            .font(.system(size: Typography.captionSize, weight: .medium))
                            .foregroundStyle(Color.mediumGray)
                    }
                }

                Spacer()

                // Arrow indicator
                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.mediumGray)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(Color.darkGray2.opacity(0.5))
        }
        .buttonStyle(.plain)
    }

    /// Title with the matching portion highlighted
    private var highlightedTitle: Text {
        let title = task.title
        let search = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        if let range = title.range(of: search, options: .caseInsensitive) {
            let beforeMatch = String(title[..<range.lowerBound])
            let match = String(title[range])
            let afterMatch = String(title[range.upperBound...])

            return Text(beforeMatch)
                .foregroundStyle(Color.pureWhite) +
            Text(match)
                .foregroundStyle(Color.recoveryGreen)
                .fontWeight(.semibold) +
            Text(afterMatch)
                .foregroundStyle(Color.pureWhite)
        } else {
            return Text(title)
                .foregroundStyle(Color.pureWhite)
        }
    }
}

// MARK: - Preview

#Preview("Task Name Autocomplete") {
    struct PreviewWrapper: View {
        @State private var text = ""
        @FocusState private var isFocused: Bool

        var body: some View {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            let container = try! ModelContainer(for: TodoTask.self, TaskCompletion.self, CustomCategory.self, configurations: config)

            let task1 = TodoTask(title: "GYM Workout", category: "Health", recurrenceType: .daily)
            let task2 = TodoTask(title: "Go to the gym", category: "Health")
            let task3 = TodoTask(title: "Gymnastics class", category: "Health", recurrenceType: .weekly, selectedWeekdays: [2, 4, 6])
            let task4 = TodoTask(title: "Buy groceries", category: "Shopping")

            container.mainContext.insert(task1)
            container.mainContext.insert(task2)
            container.mainContext.insert(task3)
            container.mainContext.insert(task4)

            return ZStack {
                Color.darkGray1.ignoresSafeArea()
                VStack {
                    TaskNameAutocomplete(
                        existingTasks: [task1, task2, task3, task4],
                        text: $text,
                        isFocused: $isFocused
                    ) { selectedTask in
                        print("Selected: \(selectedTask.title)")
                    }
                    .padding(Spacing.lg)

                    Spacer()
                }
            }
            .onAppear {
                isFocused = true
            }
        }
    }

    return PreviewWrapper()
}
