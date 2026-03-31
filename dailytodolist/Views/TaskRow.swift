//
//  TaskRow.swift
//  Reps
//
//  Purpose: Individual task row component with Whoop-inspired design
//  Design: Dark card styling with custom checkbox and category badges
//

import SwiftUI
import SwiftData
import AudioToolbox

/// A row view displaying a single task with Whoop-inspired styling
///
/// Features:
/// - Custom circular checkbox with animation
/// - Dark card background with subtle shadow
/// - Category badge with color-coded styling
/// - Recurring badge with purple accent
/// - Strikethrough and opacity change when completed
/// - Tap to edit (except checkbox area)
struct TaskRow: View {

    // MARK: - Properties

    /// The task to display
    let task: TodoTask

    /// Callback when task completion is toggled
    var onComplete: ((TodoTask) -> Void)?

    /// Callback when task is tapped for editing
    var onEdit: ((TodoTask) -> Void)?

    // MARK: - State

    /// Tracks whether the task appears completed in the UI
    @State private var isCompleted: Bool = false

    /// Sound preference
    @AppStorage("soundEnabled") private var soundEnabled: Bool = true

    // MARK: - Body

    var body: some View {
        HStack(spacing: Spacing.md) {
            // MARK: Checkbox (separate tap target)
            CheckboxButton(isChecked: isCompleted) {
                toggleCompletion()
            }

            // MARK: Task Info (tappable for edit)
            Button {
                if !isCompleted {
                    onEdit?(task)
                }
            } label: {
                HStack(spacing: Spacing.md) {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        // Task title
                        Text(task.title)
                            .font(.system(size: Typography.h4Size, weight: .medium))
                            .foregroundStyle(isCompleted ? Color.pureWhite.opacity(0.6) : Color.pureWhite)
                            .strikethrough(isCompleted, color: Color.pureWhite.opacity(0.4))
                            .multilineTextAlignment(.leading)

                        // Badges row (only show when not completed)
                        if !isCompleted {
                            HStack(spacing: Spacing.sm) {
                                // Category badge
                                if let category = task.category, !category.isEmpty {
                                    CategoryBadge(category: category)
                                }

                                // Recurring badge
                                if task.recurrenceType != .none {
                                    RecurringBadge(task: task)
                                }
                            }
                        }
                    }

                    Spacer()

                    // Chevron indicator
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.mediumGray)
                        .opacity(isCompleted ? 0 : 0.5)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(isCompleted)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, 14)
        .background(Color.darkGray1)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.standard))
        .shadowLevel1()
        .opacity(isCompleted ? 0.7 : 1.0)
        .onAppear {
            updateCompletionStatus()
        }
        .animation(.easeInOut(duration: 0.2), value: isCompleted)
    }

    // MARK: - Methods

    /// Toggles the task's completion status with animation and haptic feedback
    private func toggleCompletion() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            isCompleted.toggle()
        }

        // Success haptic and sound for completion
        if isCompleted {
            HapticService.success()
            if soundEnabled {
                AudioServicesPlaySystemSound(1104)
            }
        }

        // Notify parent to handle the completion in the database
        onComplete?(task)
    }

    /// Updates the local completion state from the task's actual status
    private func updateCompletionStatus() {
        isCompleted = task.isCompletedToday()
    }
}

// MARK: - Preview

#Preview("Task Rows") {
    ZStack {
        Color.brandBlack.ignoresSafeArea()
        VStack(spacing: Spacing.sm) {
            TaskRow(task: TodoTask(title: "Morning Workout", category: "Health"))
            TaskRow(task: TodoTask(title: "Team Meeting", category: "Work", recurrenceType: .daily))
            TaskRow(task: TodoTask(title: "Gym Session", category: "Health", recurrenceType: .weekly, selectedWeekdays: [2, 4, 6]))
            TaskRow(task: TodoTask(title: "Pay Bills", category: "Personal", recurrenceType: .monthly, selectedMonthDays: [1, 15]))
            TaskRow(task: TodoTask(title: "Buy groceries", category: "Shopping"))
        }
        .padding(Spacing.lg)
    }
    .modelContainer(for: [TodoTask.self, TaskCompletion.self, CustomCategory.self], inMemory: true)
}
