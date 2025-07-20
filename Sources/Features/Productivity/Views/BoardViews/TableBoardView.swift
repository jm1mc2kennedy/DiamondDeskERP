//
//  TableBoardView.swift
//  DiamondDeskERP
//
//  Created by AI Assistant on 7/20/25.
//

import SwiftUI

struct TableBoardView: View {
    let tasks: [ProjectTask]
    let onTaskTap: (ProjectTask) -> Void
    let onTaskEdit: (ProjectTask) -> Void
    
    @State private var sortOrder: [KeyPathComparator<ProjectTask>] = [
        .init(\.priority, order: .forward),
        .init(\.createdAt, order: .reverse)
    ]
    @State private var selectedTaskIds = Set<String>()
    @State private var showingBulkActions = false
    
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    private var sortedTasks: [ProjectTask] {
        tasks.sorted(using: sortOrder)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Bulk Actions Bar
            if !selectedTaskIds.isEmpty {
                bulkActionsBar
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            // Table Content
            Table(sortedTasks, selection: $selectedTaskIds, sortOrder: $sortOrder) {
                // Task Title & Description
                TableColumn("Task", value: \.title) { task in
                    TaskTitleCell(task: task, onTap: { onTaskTap(task) })
                }
                .width(min: 200, ideal: 300, max: .infinity)
                
                // Status
                TableColumn("Status", value: \.status.rawValue) { task in
                    StatusCell(status: task.status)
                }
                .width(min: 100, ideal: 120)
                
                // Priority
                TableColumn("Priority", value: \.priority.rawValue) { task in
                    PriorityCell(priority: task.priority)
                }
                .width(min: 80, ideal: 100)
                
                // Assignees
                TableColumn("Assignees") { task in
                    AssigneesCell(assigneeIds: task.assigneeIds)
                }
                .width(min: 120, ideal: 150)
                
                // Due Date
                TableColumn("Due Date", value: \.dueDate?.timeIntervalSince1970) { task in
                    DueDateCell(dueDate: task.dueDate, isCompleted: task.status == .completed)
                }
                .width(min: 100, ideal: 120)
                
                // Progress
                TableColumn("Progress") { task in
                    ProgressCell(task: task)
                }
                .width(min: 80, ideal: 100)
                
                // Actions
                TableColumn("") { task in
                    ActionsCell(task: task, onEdit: { onTaskEdit(task) })
                }
                .width(min: 60, ideal: 80, max: 80)
            }
            .tableStyle(.inset(alternatesRowBackgrounds: true))
            .contextMenu(forSelectionType: String.self) { selection in
                if selection.count == 1, let taskId = selection.first,
                   let task = tasks.first(where: { $0.id == taskId }) {
                    Button("Edit Task") {
                        onTaskEdit(task)
                    }
                    
                    Button("Duplicate Task") {
                        duplicateTask(task)
                    }
                    
                    Divider()
                    
                    Button("Delete Task", role: .destructive) {
                        deleteTask(task)
                    }
                } else if selection.count > 1 {
                    Button("Mark as Completed") {
                        markTasksCompleted(Array(selection))
                    }
                    
                    Button("Change Priority") {
                        showBulkPriorityPicker(Array(selection))
                    }
                    
                    Divider()
                    
                    Button("Delete Tasks", role: .destructive) {
                        deleteTasks(Array(selection))
                    }
                }
            } primaryAction: { selection in
                if let taskId = selection.first,
                   let task = tasks.first(where: { $0.id == taskId }) {
                    onTaskTap(task)
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: selectedTaskIds.isEmpty)
    }
    
    // MARK: - Bulk Actions Bar
    
    private var bulkActionsBar: some View {
        HStack {
            Text("\(selectedTaskIds.count) selected")
                .font(.subheadline)
                .fontWeight(.medium)
            
            Spacer()
            
            HStack(spacing: 8) {
                Button("Complete") {
                    markTasksCompleted(Array(selectedTaskIds))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Button("Priority") {
                    showBulkPriorityPicker(Array(selectedTaskIds))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Button("Delete", role: .destructive) {
                    deleteTasks(Array(selectedTaskIds))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Button("Clear") {
                    selectedTaskIds.removeAll()
                }
                .buttonStyle(.borderless)
                .controlSize(.small)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.regularMaterial)
        .overlay(alignment: .bottom) {
            Divider()
        }
    }
    
    // MARK: - Actions
    
    private func markTasksCompleted(_ taskIds: [String]) {
        // Implementation would update task statuses
        print("Marking tasks completed: \(taskIds)")
        selectedTaskIds.removeAll()
    }
    
    private func showBulkPriorityPicker(_ taskIds: [String]) {
        // Implementation would show priority picker sheet
        print("Showing priority picker for tasks: \(taskIds)")
    }
    
    private func deleteTasks(_ taskIds: [String]) {
        // Implementation would delete tasks
        print("Deleting tasks: \(taskIds)")
        selectedTaskIds.removeAll()
    }
    
    private func duplicateTask(_ task: ProjectTask) {
        // Implementation would duplicate task
        print("Duplicating task: \(task.title)")
    }
    
    private func deleteTask(_ task: ProjectTask) {
        // Implementation would delete single task
        print("Deleting task: \(task.title)")
    }
}

// MARK: - Table Cells

private struct TaskTitleCell: View {
    let task: ProjectTask
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(task.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    // Indicators
                    HStack(spacing: 4) {
                        if !task.checklistItems.isEmpty {
                            let completed = task.checklistItems.filter { $0.isCompleted }.count
                            Text("\(completed)/\(task.checklistItems.count)")
                                .font(.caption2)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.1))
                                .foregroundColor(.green)
                                .clipShape(Capsule())
                        }
                        
                        if !task.attachmentIds.isEmpty {
                            Image(systemName: "paperclip")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        if !task.dependencyIds.isEmpty {
                            Image(systemName: "arrow.triangle.branch")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                    }
                }
                
                if let description = task.description, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                
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
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
    }
}

private struct StatusCell: View {
    let status: TaskStatus
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(status.color)
                .frame(width: 8, height: 8)
            
            Text(status.displayName)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(status.color.opacity(0.1))
        .clipShape(Capsule())
    }
}

private struct PriorityCell: View {
    let priority: TaskPriority
    
    var body: some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 2)
                .fill(priority.color)
                .frame(width: 12, height: 12)
            
            Text(priority.displayName)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(priority.color)
        }
    }
}

private struct AssigneesCell: View {
    let assigneeIds: [String]
    
    var body: some View {
        HStack(spacing: -4) {
            ForEach(Array(assigneeIds.prefix(3)), id: \.self) { assigneeId in
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 24, height: 24)
                    .overlay {
                        Text(String(assigneeId.prefix(1)).uppercased())
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    .overlay {
                        Circle()
                            .stroke(Color.white, lineWidth: 1)
                    }
            }
            
            if assigneeIds.count > 3 {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 24, height: 24)
                    .overlay {
                        Text("+\(assigneeIds.count - 3)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }
            }
            
            if assigneeIds.isEmpty {
                Text("Unassigned")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
    }
}

private struct DueDateCell: View {
    let dueDate: Date?
    let isCompleted: Bool
    
    private var isOverdue: Bool {
        guard let dueDate = dueDate else { return false }
        return dueDate < Date() && !isCompleted
    }
    
    private var isDueSoon: Bool {
        guard let dueDate = dueDate else { return false }
        let threeDaysFromNow = Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date()
        return dueDate <= threeDaysFromNow && !isOverdue && !isCompleted
    }
    
    var body: some View {
        Group {
            if let dueDate = dueDate {
                VStack(spacing: 2) {
                    Text(dueDate, style: .date)
                        .font(.caption)
                        .fontWeight(isOverdue || isDueSoon ? .medium : .regular)
                    
                    Text(dueDate, style: .time)
                        .font(.caption2)
                        .opacity(0.7)
                }
                .foregroundColor(isOverdue ? .red : (isDueSoon ? .orange : .primary))
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .background {
                    if isOverdue || isDueSoon {
                        Capsule()
                            .fill((isOverdue ? Color.red : Color.orange).opacity(0.1))
                    }
                }
            } else {
                Text("No due date")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
    }
}

private struct ProgressCell: View {
    let task: ProjectTask
    
    private var checklistProgress: Double {
        guard !task.checklistItems.isEmpty else { return 0 }
        let completed = task.checklistItems.filter { $0.isCompleted }.count
        return Double(completed) / Double(task.checklistItems.count)
    }
    
    private var timeProgress: Double? {
        guard let estimatedHours = task.estimatedHours,
              let actualHours = task.actualHours,
              estimatedHours > 0 else { return nil }
        return min(actualHours / estimatedHours, 1.0)
    }
    
    var body: some View {
        VStack(spacing: 4) {
            if !task.checklistItems.isEmpty {
                VStack(spacing: 2) {
                    HStack {
                        Text("Checklist")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(Int(checklistProgress * 100))%")
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    
                    ProgressView(value: checklistProgress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .green))
                        .scaleEffect(y: 0.8)
                }
            }
            
            if let timeProgress = timeProgress {
                VStack(spacing: 2) {
                    HStack {
                        Text("Time")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(Int(timeProgress * 100))%")
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    
                    ProgressView(value: timeProgress)
                        .progressViewStyle(LinearProgressViewStyle(
                            tint: timeProgress > 1.0 ? .red : .blue
                        ))
                        .scaleEffect(y: 0.8)
                }
            }
            
            if task.checklistItems.isEmpty && timeProgress == nil {
                Text("No progress data")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .frame(minWidth: 80)
    }
}

private struct ActionsCell: View {
    let task: ProjectTask
    let onEdit: () -> Void
    
    @State private var showingActionMenu = false
    
    var body: some View {
        Button(action: { showingActionMenu = true }) {
            Image(systemName: "ellipsis")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 20, height: 20)
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showingActionMenu) {
            VStack(alignment: .leading, spacing: 0) {
                Button("Edit Task") {
                    onEdit()
                    showingActionMenu = false
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                
                Button("Duplicate") {
                    // Handle duplicate
                    showingActionMenu = false
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                
                Divider()
                
                Button("Delete", role: .destructive) {
                    // Handle delete
                    showingActionMenu = false
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .frame(width: 150)
            .background(.regularMaterial)
        }
    }
}

#Preview {
    TableBoardView(
        tasks: [
            ProjectTask(
                id: "1",
                projectBoardId: "board1",
                title: "Implement user authentication system",
                description: "Add comprehensive login and registration functionality with security features",
                status: .inProgress,
                priority: .high,
                assigneeIds: ["user1", "user2"],
                createdBy: "user1",
                dueDate: Calendar.current.date(byAdding: .day, value: 7, to: Date()),
                estimatedHours: 16,
                actualHours: 8,
                tags: ["Frontend", "Backend", "Security"],
                dependencyIds: [],
                checklistItems: [
                    ChecklistItem(id: "1", title: "Design login form", isCompleted: true, completedAt: Date(), completedBy: "user1"),
                    ChecklistItem(id: "2", title: "Implement API endpoints", isCompleted: true, completedAt: Date(), completedBy: "user2"),
                    ChecklistItem(id: "3", title: "Add validation", isCompleted: false, completedAt: nil, completedBy: nil),
                    ChecklistItem(id: "4", title: "Write tests", isCompleted: false, completedAt: nil, completedBy: nil)
                ],
                attachmentIds: ["att1", "att2"],
                createdAt: Date(),
                modifiedAt: Date()
            ),
            ProjectTask(
                id: "2",
                projectBoardId: "board1",
                title: "Setup database schema",
                description: nil,
                status: .todo,
                priority: .medium,
                assigneeIds: ["user3"],
                createdBy: "user1",
                dueDate: nil,
                estimatedHours: 4,
                tags: ["Backend"],
                dependencyIds: ["1"],
                checklistItems: [],
                attachmentIds: [],
                createdAt: Date(),
                modifiedAt: Date()
            )
        ],
        onTaskTap: { _ in },
        onTaskEdit: { _ in }
    )
    .frame(height: 600)
}
