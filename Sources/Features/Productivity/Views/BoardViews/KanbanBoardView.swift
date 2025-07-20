//
//  KanbanBoardView.swift
//  DiamondDeskERP
//
//  Created by AI Assistant on 7/20/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct KanbanBoardView: View {
    let tasks: [ProjectTask]
    let onTaskTap: (ProjectTask) -> Void
    let onTaskMove: (ProjectTask, TaskStatus) -> Void
    
    @State private var draggedTask: ProjectTask?
    @State private var dragOffset = CGSize.zero
    @State private var dropTarget: TaskStatus?
    
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.colorScheme) private var colorScheme
    
    private let columns = [
        GridItem(.flexible(minimum: 280), spacing: 16),
        GridItem(.flexible(minimum: 280), spacing: 16),
        GridItem(.flexible(minimum: 280), spacing: 16),
        GridItem(.flexible(minimum: 280), spacing: 16)
    ]
    
    private let statusColumns: [TaskStatus] = [.todo, .inProgress, .inReview, .completed]
    
    var body: some View {
        ScrollView([.horizontal, .vertical], showsIndicators: true) {
            LazyHGrid(rows: [GridItem(.flexible())], spacing: 16) {
                ForEach(statusColumns, id: \.self) { status in
                    KanbanColumn(
                        status: status,
                        tasks: tasksForStatus(status),
                        draggedTask: $draggedTask,
                        dropTarget: $dropTarget,
                        onTaskTap: onTaskTap,
                        onTaskDrop: { task in
                            onTaskMove(task, status)
                        }
                    )
                    .frame(width: 300)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
    
    private func tasksForStatus(_ status: TaskStatus) -> [ProjectTask] {
        tasks.filter { $0.status == status }
            .sorted { task1, task2 in
                // Sort by priority first, then by creation date
                if task1.priority != task2.priority {
                    return task1.priority.sortOrder < task2.priority.sortOrder
                }
                return task1.createdAt > task2.createdAt
            }
    }
}

struct KanbanColumn: View {
    let status: TaskStatus
    let tasks: [ProjectTask]
    @Binding var draggedTask: ProjectTask?
    @Binding var dropTarget: TaskStatus?
    let onTaskTap: (ProjectTask) -> Void
    let onTaskDrop: (ProjectTask) -> Void
    
    @State private var isDropTarget = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Column Header
            HStack {
                HStack(spacing: 8) {
                    Circle()
                        .fill(status.color)
                        .frame(width: 12, height: 12)
                    
                    Text(status.displayName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Text("\(tasks.count)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.2))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            
            // Tasks Container
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 12) {
                    ForEach(tasks) { task in
                        KanbanTaskCard(
                            task: task,
                            isDragging: draggedTask?.id == task.id,
                            onTap: { onTaskTap(task) }
                        )
                        .draggable(task) {
                            KanbanTaskCard(task: task, isDragging: true, onTap: {})
                                .opacity(0.8)
                                .scaleEffect(0.95)
                        }
                        .onDrag {
                            draggedTask = task
                            return NSItemProvider(object: task.id as NSString)
                        }
                    }
                    
                    // Drop zone for empty columns or bottom of column
                    if tasks.isEmpty || draggedTask != nil {
                        DropZone(isActive: isDropTarget && dropTarget == status)
                            .frame(height: tasks.isEmpty ? 200 : 80)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .frame(maxHeight: .infinity)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
        .overlay {
            if isDropTarget && dropTarget == status {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(status.color, lineWidth: 2)
                    .animation(.easeInOut(duration: 0.2), value: isDropTarget)
            }
        }
        .dropDestination(for: String.self) { droppedItems, location in
            guard let draggedTask = draggedTask,
                  let droppedTaskId = droppedItems.first,
                  droppedTaskId == draggedTask.id else {
                return false
            }
            
            onTaskDrop(draggedTask)
            self.draggedTask = nil
            self.dropTarget = nil
            self.isDropTarget = false
            
            return true
        } isTargeted: { isTargeted in
            isDropTarget = isTargeted
            if isTargeted {
                dropTarget = status
            }
        }
    }
}

struct KanbanTaskCard: View {
    let task: ProjectTask
    let isDragging: Bool
    let onTap: () -> Void
    
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header with priority and actions
                HStack {
                    PriorityIndicator(priority: task.priority)
                    
                    Spacer()
                    
                    if !task.assigneeIds.isEmpty {
                        AssigneeAvatars(assigneeIds: Array(task.assigneeIds.prefix(3)))
                    }
                }
                
                // Title and description
                VStack(alignment: .leading, spacing: 6) {
                    Text(task.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                    
                    if let description = task.description, !description.isEmpty {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(3)
                            .multilineTextAlignment(.leading)
                    }
                }
                
                // Metadata row
                HStack {
                    // Tags
                    if !task.tags.isEmpty {
                        HStack(spacing: 4) {
                            ForEach(Array(task.tags.prefix(2)), id: \.self) { tag in
                                Text(tag)
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.accentColor.opacity(0.1))
                                    .foregroundColor(.accentColor)
                                    .clipShape(Capsule())
                            }
                            
                            if task.tags.count > 2 {
                                Text("+\(task.tags.count - 2)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Due date indicator
                    if let dueDate = task.dueDate {
                        DueDateIndicator(dueDate: dueDate, isCompleted: task.status == .completed)
                    }
                }
                
                // Progress indicators
                HStack {
                    // Checklist progress
                    if !task.checklistItems.isEmpty {
                        ChecklistProgress(items: task.checklistItems)
                    }
                    
                    Spacer()
                    
                    // Additional indicators
                    HStack(spacing: 8) {
                        if !task.dependencyIds.isEmpty {
                            Image(systemName: "arrow.triangle.branch")
                                .font(.caption2)
                                .foregroundColor(.orange)
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
                        
                        if let estimatedHours = task.estimatedHours {
                            HStack(spacing: 2) {
                                Image(systemName: "clock")
                                    .font(.caption2)
                                Text("\(Int(estimatedHours))h")
                                    .font(.caption2)
                            }
                            .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding(12)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(isDragging ? 0.2 : 0.05), radius: isDragging ? 8 : 2, x: 0, y: isDragging ? 4 : 1)
            .scaleEffect(isDragging ? 1.05 : 1.0)
            .opacity(isDragging ? 0.8 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isDragging)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(task.title), \(task.status.displayName), \(task.priority.displayName) priority")
        .accessibilityHint("Double tap to view task details")
    }
}

// MARK: - Supporting Views

private struct PriorityIndicator: View {
    let priority: TaskPriority
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(priority.color)
                .frame(width: 8, height: 8)
            
            Text(priority.displayName)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(priority.color)
        }
    }
}

private struct AssigneeAvatars: View {
    let assigneeIds: [String]
    
    var body: some View {
        HStack(spacing: -4) {
            ForEach(assigneeIds, id: \.self) { assigneeId in
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 20, height: 20)
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
        }
    }
}

private struct DueDateIndicator: View {
    let dueDate: Date
    let isCompleted: Bool
    
    private var isOverdue: Bool {
        dueDate < Date() && !isCompleted
    }
    
    private var isDueSoon: Bool {
        let threeDaysFromNow = Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date()
        return dueDate <= threeDaysFromNow && !isOverdue && !isCompleted
    }
    
    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: "calendar")
                .font(.caption2)
            
            Text(dueDate, style: .date)
                .font(.caption2)
        }
        .foregroundColor(isOverdue ? .red : (isDueSoon ? .orange : .secondary))
        .fontWeight(isOverdue || isDueSoon ? .medium : .regular)
    }
}

private struct ChecklistProgress: View {
    let items: [ChecklistItem]
    
    private var completedCount: Int {
        items.filter { $0.isCompleted }.count
    }
    
    private var progress: Double {
        items.isEmpty ? 0 : Double(completedCount) / Double(items.count)
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "checklist")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Text("\(completedCount)/\(items.count)")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: .green))
                .frame(width: 30)
                .scaleEffect(y: 0.5)
        }
    }
}

private struct DropZone: View {
    let isActive: Bool
    
    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(isActive ? Color.accentColor.opacity(0.1) : Color.clear)
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isActive ? Color.accentColor : Color.gray.opacity(0.3),
                        style: StrokeStyle(lineWidth: 2, dash: [8, 4])
                    )
            }
            .overlay {
                if isActive {
                    VStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.accentColor)
                        
                        Text("Drop task here")
                            .font(.caption)
                            .foregroundColor(.accentColor)
                            .fontWeight(.medium)
                    }
                }
            }
            .animation(.easeInOut(duration: 0.2), value: isActive)
    }
}

// MARK: - Extensions

extension TaskStatus {
    var color: Color {
        switch self {
        case .todo: return .gray
        case .inProgress: return .blue
        case .inReview: return .orange
        case .completed: return .green
        case .onHold: return .yellow
        case .cancelled: return .red
        }
    }
}

extension TaskPriority {
    var sortOrder: Int {
        switch self {
        case .critical: return 0
        case .high: return 1
        case .medium: return 2
        case .low: return 3
        }
    }
}

// MARK: - Draggable Conformance

extension ProjectTask: Transferable {
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .data)
    }
}

#Preview {
    KanbanBoardView(
        tasks: [
            ProjectTask(
                id: "1",
                projectBoardId: "board1",
                title: "Implement user authentication",
                description: "Add login and registration functionality",
                status: .todo,
                priority: .high,
                assigneeIds: ["user1", "user2"],
                createdBy: "user1",
                dueDate: Calendar.current.date(byAdding: .day, value: 7, to: Date()),
                estimatedHours: 8,
                tags: ["Frontend", "Backend"],
                dependencyIds: [],
                checklistItems: [
                    ChecklistItem(id: "1", title: "Design login form", isCompleted: true, completedAt: Date(), completedBy: "user1"),
                    ChecklistItem(id: "2", title: "Implement API", isCompleted: false, completedAt: nil, completedBy: nil)
                ],
                attachmentIds: ["att1"],
                createdAt: Date(),
                modifiedAt: Date()
            )
        ],
        onTaskTap: { _ in },
        onTaskMove: { _, _ in }
    )
}
