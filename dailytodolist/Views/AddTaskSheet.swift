//
//  AddTaskSheet.swift
//  Reps
//
//  Purpose: Sheet view for creating new tasks with Whoop-inspired design
//  Design: Dark theme with icon-based category selector and styled inputs
//
//  Features:
//  - Autocomplete for existing tasks (prevents duplicates)
//  - Edit mode when existing task is selected
//  - Start date picker for One-Time and Daily tasks
//

import SwiftUI
import UIKit
import SwiftData

/// Sheet view for adding a new task with Whoop-inspired styling
///
/// Features:
/// - Dark theme with gradient backgrounds
/// - Icon-based category grid selector
/// - Radio button frequency selector
/// - Autocomplete with existing task suggestions
/// - Edit mode when selecting existing task
/// - Start date selection for future tasks
struct AddTaskSheet: View {

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    // MARK: - Query

    @Query(filter: #Predicate<TodoTask> { $0.isActive == true })
    private var existingTasks: [TodoTask]

    // MARK: - State

    @State private var title: String = ""
    @State private var category: String = ""
    @State private var recurrenceType: RecurrenceType = .none
    @State private var selectedWeekdays: [Int] = []
    @State private var selectedMonthDays: [Int] = []
    @State private var startDate: Date = Calendar.current.startOfDay(for: Date())
    @State private var useStartDate: Bool = false
    @State private var showDatePicker: Bool = false
    @FocusState private var isTitleFocused: Bool

    /// Task being edited (nil = create mode)
    @State private var editingTask: TodoTask?

    // MARK: - Computed Properties

    /// Whether we're in edit mode (updating existing task)
    private var isEditMode: Bool {
        editingTask != nil
    }

    /// Whether start date picker should be available
    private var showStartDateOption: Bool {
        recurrenceType == .none || recurrenceType == .daily
    }

    private var isFormValid: Bool {
        let hasTitle = !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        // Validate recurrence-specific requirements
        switch recurrenceType {
        case .none, .daily:
            return hasTitle
        case .weekly:
            return hasTitle && !selectedWeekdays.isEmpty
        case .monthly:
            return hasTitle && !selectedMonthDays.isEmpty
        }
    }

    /// The effective start date to save (nil if today or not using start date)
    private var effectiveStartDate: Date? {
        guard useStartDate && showStartDateOption else { return nil }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let selectedDay = calendar.startOfDay(for: startDate)

        // Don't save startDate if it's today
        if selectedDay <= today {
            return nil
        }
        return selectedDay
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.brandBlack.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Spacing.section) {
                        // Task Name Input with Autocomplete
                        taskNameSection

                        // Edit Mode Indicator
                        if isEditMode {
                            editModeIndicator
                        }

                        // Category Selector
                        CategorySelector(selectedCategory: $category)

                        // Recurrence Selector
                        RecurrenceSelector(
                            recurrenceType: $recurrenceType,
                            selectedWeekdays: $selectedWeekdays,
                            selectedMonthDays: $selectedMonthDays
                        )

                        // Start Date Section (only for One-Time and Daily)
                        if showStartDateOption {
                            startDateSection
                        }

                        // Create/Update Button
                        Button(isEditMode ? "UPDATE TASK" : "CREATE TASK") {
                            saveTask()
                        }
                        .buttonStyle(.primary)
                        .disabled(!isFormValid)
                        .padding(.top, Spacing.sm)
                    }
                    .padding(Spacing.xl)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(isEditMode ? "EDIT TASK" : "ADD TASK")
                        .font(.system(size: 15, weight: .black))
                        .italic()
                        .foregroundStyle(Color.pureWhite)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color.mediumGray)
                            .frame(width: 36, height: 36)
                            .background(Color.darkGray1)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
            .toolbarBackground(Color.brandBlack, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .onAppear {
                isTitleFocused = true
            }
            .onChange(of: recurrenceType) { _, newValue in
                // Reset start date when switching to Weekly/Monthly
                if newValue == .weekly || newValue == .monthly {
                    useStartDate = false
                    showDatePicker = false
                }
            }
        }
        .presentationBackground(Color.brandBlack)
    }

    // MARK: - Subviews

    /// Task name input section with autocomplete
    private var taskNameSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("TASK NAME")
                .font(.system(size: Typography.labelSize, weight: .bold))
                .foregroundStyle(Color.mediumGray)
                .tracking(1.0)

            TaskNameAutocomplete(
                existingTasks: existingTasks,
                text: $title,
                isFocused: $isTitleFocused
            ) { selectedTask in
                switchToEditMode(for: selectedTask)
            }
        }
    }

    /// Indicator showing we're editing an existing task
    private var editModeIndicator: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "pencil.circle.fill")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color.workBlue)

            Text("EDITING EXISTING TASK")
                .font(.system(size: Typography.captionSize, weight: .bold))
                .foregroundStyle(Color.workBlue)
                .tracking(0.5)

            Spacer()

            Button {
                clearEditMode()
            } label: {
                Text("CREATE NEW")
                    .font(.system(size: Typography.captionSize, weight: .bold))
                    .foregroundStyle(Color.mediumGray)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.xs)
                    .background(Color.darkGray2)
                    .clipShape(Capsule())
            }
        }
        .padding(Spacing.md)
        .background(Color.workBlue.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.standard))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.standard)
                .stroke(Color.workBlue.opacity(0.3), lineWidth: 1)
        )
    }

    /// Start date selection section
    private var startDateSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("START DATE")
                .font(.system(size: Typography.labelSize, weight: .bold))
                .foregroundStyle(Color.mediumGray)
                .tracking(1.0)

            // Toggle row
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    if useStartDate {
                        showDatePicker.toggle()
                    } else {
                        useStartDate = true
                        showDatePicker = true
                        // Default to tomorrow when enabling
                        startDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
                    }
                }
            } label: {
                HStack(spacing: Spacing.md) {
                    Image(systemName: useStartDate ? "calendar.badge.clock" : "calendar")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(useStartDate ? Color.recoveryGreen : Color.mediumGray)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(useStartDate ? formattedStartDate : "Starts Today")
                            .font(.system(size: Typography.bodySize, weight: .semibold))
                            .foregroundStyle(Color.pureWhite)

                        Text(useStartDate ? "Task will appear on this date" : "Tap to schedule for later")
                            .font(.system(size: Typography.captionSize, weight: .regular))
                            .foregroundStyle(Color.mediumGray)
                    }

                    Spacer()

                    if useStartDate {
                        Button {
                            withAnimation {
                                useStartDate = false
                                showDatePicker = false
                                startDate = Calendar.current.startOfDay(for: Date())
                            }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundStyle(Color.mediumGray)
                        }
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.mediumGray)
                    }
                }
                .padding(Spacing.lg)
                .background(Color.darkGray1)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.standard))
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.standard)
                        .stroke(useStartDate ? Color.recoveryGreen.opacity(0.5) : Color.clear, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

            // Date picker (expanded)
            if showDatePicker {
                DatePicker(
                    "Start Date",
                    selection: $startDate,
                    in: (Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: Date())) ?? Date())...,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .tint(Color.recoveryGreen)
                .colorScheme(.dark)
                .padding(Spacing.md)
                .background(Color.darkGray1)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.standard))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    /// Formatted start date for display
    private var formattedStartDate: String {
        let calendar = Calendar.current
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: Date())) else {
            return "Tomorrow"
        }
        let selectedDay = calendar.startOfDay(for: startDate)

        if selectedDay == tomorrow {
            return "Tomorrow"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, MMM d"
            return formatter.string(from: startDate)
        }
    }

    // MARK: - Methods

    /// Switches to edit mode for the selected task
    private func switchToEditMode(for task: TodoTask) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            editingTask = task
            title = task.title
            category = task.category ?? ""
            recurrenceType = task.recurrenceType
            selectedWeekdays = task.selectedWeekdays
            selectedMonthDays = task.selectedMonthDays

            // Set start date if task has one
            if let taskStartDate = task.startDate {
                startDate = taskStartDate
                useStartDate = true
            } else {
                startDate = Calendar.current.startOfDay(for: Date())
                useStartDate = false
            }
            showDatePicker = false
            isTitleFocused = false
        }
    }

    /// Clears edit mode and resets to create mode
    private func clearEditMode() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            editingTask = nil
            title = ""
            category = ""
            recurrenceType = .none
            selectedWeekdays = []
            selectedMonthDays = []
            startDate = Calendar.current.startOfDay(for: Date())
            useStartDate = false
            showDatePicker = false
            isTitleFocused = true
        }
    }

    private func saveTask() {
        let taskService = TaskService(modelContext: modelContext)

        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let taskCategory: String? = category.isEmpty ? nil : category

        if let existingTask = editingTask {
            // Update existing task
            taskService.updateTask(
                existingTask,
                title: trimmedTitle,
                category: taskCategory,
                recurrenceType: recurrenceType,
                selectedWeekdays: selectedWeekdays,
                selectedMonthDays: selectedMonthDays,
                startDate: effectiveStartDate
            )
        } else {
            // Create new task
            taskService.createTask(
                title: trimmedTitle,
                category: taskCategory,
                recurrenceType: recurrenceType,
                selectedWeekdays: selectedWeekdays,
                selectedMonthDays: selectedMonthDays,
                startDate: effectiveStartDate
            )
        }

        // Success haptic
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        dismiss()
    }
}

// MARK: - Preview

#Preview {
    AddTaskSheet()
        .modelContainer(for: [TodoTask.self, TaskCompletion.self, CustomCategory.self], inMemory: true)
}
