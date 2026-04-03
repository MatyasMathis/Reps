//
//  EditTaskSheet.swift
//  Reps
//
//  Purpose: Sheet view for editing existing tasks
//  Features: Pre-filled form with current task values, save/cancel flow
//

import SwiftUI
import UIKit
import SwiftData

/// Sheet view for editing an existing task
///
/// Features:
/// - Pre-fills all fields with current task values
/// - Same UI as AddTaskSheet for consistency
/// - Save Changes button updates the task
/// - Delete option available
/// - Start date selection for One-Time and Daily tasks
struct EditTaskSheet: View {

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    // MARK: - Properties

    /// The task being edited
    let task: TodoTask

    /// Callback when task is deleted
    var onDelete: (() -> Void)?

    // MARK: - State

    @State private var title: String = ""
    @State private var category: String = ""
    @State private var recurrenceType: RecurrenceType = .none
    @State private var selectedWeekdays: [Int] = []
    @State private var selectedMonthDays: [Int] = []
    @State private var startDate: Date = Calendar.current.startOfDay(for: Date())
    @State private var useStartDate: Bool = false
    @State private var showDatePicker: Bool = false
    @State private var showDeleteConfirmation: Bool = false
    @FocusState private var isTitleFocused: Bool

    // MARK: - Computed Properties

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

        // Don't save startDate if it's today or earlier
        if selectedDay <= today {
            return nil
        }
        return selectedDay
    }

    private var hasChanges: Bool {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let currentCategory = category.isEmpty ? nil : category

        return trimmedTitle != task.title ||
               currentCategory != task.category ||
               recurrenceType != task.recurrenceType ||
               selectedWeekdays != task.selectedWeekdays ||
               selectedMonthDays != task.selectedMonthDays ||
               effectiveStartDate != task.startDate
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.brandBlack.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Spacing.section) {
                        // Task Name Input
                        taskNameSection

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

                        // Save Button
                        Button("SAVE CHANGES") {
                            saveTask()
                        }
                        .buttonStyle(.primary)
                        .disabled(!isFormValid || !hasChanges)
                        .padding(.top, Spacing.sm)

                        // Delete Button
                        Button {
                            showDeleteConfirmation = true
                        } label: {
                            HStack(spacing: Spacing.sm) {
                                Image(systemName: "trash")
                                    .font(.system(size: 14, weight: .bold))
                                Text("DELETE TASK")
                                    .font(.system(size: Typography.bodySize, weight: .bold))
                                    .tracking(0.5)
                            }
                            .foregroundStyle(Color.strainRed)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.md)
                            .background(Color.strainRed.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.standard))
                            .overlay(
                                RoundedRectangle(cornerRadius: CornerRadius.standard)
                                    .stroke(Color.strainRed.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(Spacing.xl)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("EDIT TASK")
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
                loadTaskData()
            }
            .onChange(of: recurrenceType) { _, newValue in
                // Reset start date when switching to Weekly/Monthly
                if newValue == .weekly || newValue == .monthly {
                    useStartDate = false
                    showDatePicker = false
                }
            }
            .confirmationDialog(
                "Delete Task",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    deleteTask()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete this task? This action cannot be undone.")
            }
        }
        .presentationBackground(Color.brandBlack)
    }

    // MARK: - Subviews

    /// Task name input section
    private var taskNameSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("TASK NAME")
                .font(.system(size: Typography.labelSize, weight: .bold))
                .foregroundStyle(Color.mediumGray)
                .tracking(1.0)

            TextField("", text: $title, prompt: Text("Enter task name...")
                .foregroundStyle(Color.mediumGray))
                .font(.system(size: Typography.h4Size, weight: .semibold))
                .foregroundStyle(Color.pureWhite)
                .padding(Spacing.lg)
                .background(Color.darkGray1)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.standard))
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.standard)
                        .stroke(isTitleFocused ? Color.recoveryGreen : Color.clear, lineWidth: 2)
                )
                .focused($isTitleFocused)
        }
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

    /// Loads the current task data into the form fields
    private func loadTaskData() {
        title = task.title
        category = task.category ?? ""
        recurrenceType = task.recurrenceType
        selectedWeekdays = task.selectedWeekdays
        selectedMonthDays = task.selectedMonthDays

        // Load start date
        if let taskStartDate = task.startDate {
            startDate = taskStartDate
            useStartDate = true
        } else {
            startDate = Calendar.current.startOfDay(for: Date())
            useStartDate = false
        }
    }

    /// Saves the updated task
    private func saveTask() {
        let taskService = TaskService(modelContext: modelContext)

        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let taskCategory: String? = category.isEmpty ? nil : category

        taskService.updateTask(
            task,
            title: trimmedTitle,
            category: taskCategory,
            recurrenceType: recurrenceType,
            selectedWeekdays: selectedWeekdays,
            selectedMonthDays: selectedMonthDays,
            startDate: effectiveStartDate
        )

        // Success haptic
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        dismiss()
    }

    /// Deletes the task
    private func deleteTask() {
        let taskService = TaskService(modelContext: modelContext)
        taskService.deleteTask(task)

        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)

        onDelete?()
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: TodoTask.self, TaskCompletion.self, CustomCategory.self, configurations: config)

    let task = TodoTask(
        title: "Morning Workout",
        category: "Health",
        recurrenceType: .weekly,
        selectedWeekdays: [2, 4, 6]
    )
    container.mainContext.insert(task)

    return EditTaskSheet(task: task)
        .modelContainer(container)
}
