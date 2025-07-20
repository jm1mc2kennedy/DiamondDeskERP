//
//  TasksForDateSheet.swift
//  DiamondDeskERP
//
//  Created by AI Assistant on 7/20/25.
//

import SwiftUI

struct TasksForDateSheet: View {
    let date: Date
    let tasks: [ProjectTask]
    let onTaskTap: (ProjectTask) -> Void
    let onCreateTask: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    private var sortedTasks: [ProjectTask] {
        tasks.sorted { task1, task2 in
            // Sort by priority first, then by creation time
            if task1.priority != task2.priority {
                return task1.priority.sortOrder < task2.priority.sortOrder
            }
            return task1.createdAt > task2.createdAt
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                if tasks.isEmpty {
                    emptyStateView
                } else {
                    tasksList
                }
            }
            .navigationTitle(dateTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button(action: onCreateTask) {
                        Image(systemName: "plus.circle.fill")
                    }
                    .accessibilityLabel("Create new task for this date")
                }
            }
        }
    }
    
    // MARK: - Content Views
    
    private var tasksList: some View {
        List {
            Section {
                ForEach(sortedTasks) { task in
                    TaskRowView(task: task, onTap: { onTaskTap(task) })
                }
            } header: {
                HStack {
                    Text("\(tasks.count) task\(tasks.count == 1 ? "" : "s")")
                    
                    Spacer()
                    
                    // Summary stats
                    HStack(spacing: 12) {
                        StatBadge(
                            count: completedTasksCount,
                            label: "Done",
                            color: .green
                        )
                        
                        StatBadge(
                            count: overdueTasksCount,
                            label: "Overdue",
                            color: .red
                        )
                        
                        StatBadge(
                            count: inProgressTasksCount,
                            label: "Active",
                            color: .blue
                        )
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("No tasks for this date")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("Create a new task or adjust existing task due dates to organize your work.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: onCreateTask) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Create Task")
                }
                .font(.subheadline)
                .fontWeight(.medium)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Computed Properties
    
    private var dateTitle: String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(date) {
            return "Today's Tasks"
        } else if Calendar.current.isDateInTomorrow(date) {
            return "Tomorrow's Tasks"
        } else if Calendar.current.isDateInYesterday(date) {
            return "Yesterday's Tasks"
        } else {
            formatter.dateStyle = .full
            return formatter.string(from: date)
        }
    }
    
    private var completedTasksCount: Int {
        tasks.filter { $0.status == .completed }.count
    }
    
    private var overdueTasksCount: Int {
        let now = Date()
        return tasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return dueDate < now && task.status != .completed
        }.count
    }
    
    private var inProgressTasksCount: Int {
        tasks.filter { $0.status == .inProgress }.count
    }
}

// MARK: - Task Row View

struct TaskRowView: View {
    let task: ProjectTask
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Priority indicator
                RoundedRectangle(cornerRadius: 3)
                    .fill(task.priority.color)
                    .frame(width: 6, height: 40)
                
                // Task content
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(task.title)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                        
                        // Time if available
                        if let dueDate = task.dueDate {
                            Text(dueDate, style: .time)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Task metadata
                    HStack {
                        // Status badge
                        HStack(spacing: 4) {
                            Circle()
                                .fill(task.status.color)
                                .frame(width: 6, height: 6)
                            
                            Text(task.status.displayName)
                                .font(.caption2)
                                .foregroundColor(task.status.color)
                        }
                        
                        // Assignees
                        if !task.assigneeIds.isEmpty {
                            HStack(spacing: -4) {
                                ForEach(Array(task.assigneeIds.prefix(3)), id: \.self) { assigneeId in
                                    Circle()
                                        .fill(Color.accentColor)
                                        .frame(width: 16, height: 16)
                                        .overlay {
                                            Text(String(assigneeId.prefix(1)).uppercased())
                                                .font(.caption2)
                                                .fontWeight(.bold)
                                                .foregroundColor(.white)
                                        }
                                }
                                
                                if task.assigneeIds.count > 3 {
                                    Circle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 16, height: 16)
                                        .overlay {
                                            Text("+\(task.assigneeIds.count - 3)")
                                                .font(.caption2)
                                                .fontWeight(.bold)
                                                .foregroundColor(.primary)
                                        }
                                }
                            }
                        }
                        
                        Spacer()
                        
                        // Additional indicators
                        HStack(spacing: 6) {
                            if !task.checklistItems.isEmpty {
                                let completed = task.checklistItems.filter { $0.isCompleted }.count
                                HStack(spacing: 2) {
                                    Image(systemName: "checklist")
                                        .font(.caption2)
                                    Text("\(completed)/\(task.checklistItems.count)")
                                        .font(.caption2)
                                }
                                .foregroundColor(.secondary)
                            }
                            
                            if !task.attachmentIds.isEmpty {
                                HStack(spacing: 2) {
                                    Image(systemName: "paperclip")
                                        .font(.caption2)
                                    Text("\(task.attachmentIds.count)")
                                        .font(.caption2)
                                }
                                .foregroundColor(.secondary)
                            }
                            
                            if !task.dependencyIds.isEmpty {
                                Image(systemName: "arrow.triangle.branch")
                                    .font(.caption2)
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                    
                    // Tags if available
                    if !task.tags.isEmpty {
                        HStack(spacing: 4) {
                            ForEach(Array(task.tags.prefix(3)), id: \.self) { tag in
                                Text(tag)
                                    .font(.caption2)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 2)
                                    .background(Color.accentColor.opacity(0.1))
                                    .foregroundColor(.accentColor)
                                    .clipShape(Capsule())
                            }
                            
                            if task.tags.count > 3 {
                                Text("+\(task.tags.count - 3)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(task.title), \(task.status.displayName), \(task.priority.displayName) priority")
        .accessibilityHint("Double tap to view task details")
    }
}

// MARK: - Stat Badge

struct StatBadge: View {
    let count: Int
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text("\(count)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(minWidth: 40)
    }
}

#Preview {
    TasksForDateSheet(
        date: Date(),
        tasks: [
            ProjectTask(
                id: "1",
                projectBoardId: "board1",
                title: "Review design mockups and provide feedback",
                description: nil,
                status: .inProgress,
                priority: .high,
                assigneeIds: ["user1", "user2"],
                createdBy: "user1",
                dueDate: Date(),
                tags: ["Design", "Review"],
                dependencyIds: [],
                checklistItems: [
                    ChecklistItem(id: "1", title: "Check color scheme", isCompleted: true, completedAt: Date(), completedBy: "user1"),
                    ChecklistItem(id: "2", title: "Verify responsive layout", isCompleted: false, completedAt: nil, completedBy: nil)
                ],
                attachmentIds: ["att1"],
                createdAt: Date(),
                modifiedAt: Date()
            ),
            ProjectTask(
                id: "2",
                projectBoardId: "board1",
                title: "Update API documentation",
                description: nil,
                status: .completed,
                priority: .medium,
                assigneeIds: ["user3"],
                createdBy: "user1",
                dueDate: Date(),
                tags: ["Documentation"],
                dependencyIds: [],
                checklistItems: [],
                attachmentIds: [],
                createdAt: Date(),
                modifiedAt: Date()
            )
        ],
        onTaskTap: { _ in },
        onCreateTask: { }
    )
}
