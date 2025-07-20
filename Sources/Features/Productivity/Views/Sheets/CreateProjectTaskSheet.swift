//
//  CreateProjectTaskSheet.swift
//  DiamondDeskERP
//
//  Created by AI Assistant on 7/20/25.
//

import SwiftUI
import Combine

struct CreateProjectTaskSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = CreateProjectTaskViewModel()
    
    let projectBoardId: String
    let parentTaskId: String?
    
    // Form State
    @State private var taskTitle = ""
    @State private var taskDescription = ""
    @State private var selectedPriority: TaskPriority = .medium
    @State private var selectedStatus: TaskStatus = .todo
    @State private var assigneeIds: Set<String> = []
    @State private var dueDate: Date?
    @State private var estimatedHours: Double = 0
    @State private var selectedTags: Set<String> = []
    @State private var selectedDependencies: Set<String> = []
    @State private var checklistItems: [ChecklistItemInput] = []
    @State private var attachments: [TaskAttachment] = []
    
    // UI State
    @State private var showingDatePicker = false
    @State private var showingAssigneePicker = false
    @State private var showingDependencyPicker = false
    @State private var showingTagPicker = false
    @State private var isCreating = false
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var newChecklistItem = ""
    
    // Accessibility
    @AccessibilityFocusState private var isTitleFieldFocused: Bool
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    init(projectBoardId: String, parentTaskId: String? = nil) {
        self.projectBoardId = projectBoardId
        self.parentTaskId = parentTaskId
    }
    
    var body: some View {
        NavigationStack {
            Form {
                basicInfoSection
                assignmentSection
                timelineSection
                checklistSection
                dependenciesSection
                if !attachments.isEmpty {
                    attachmentsSection
                }
            }
            .navigationTitle(parentTaskId == nil ? "New Task" : "New Subtask")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createTask()
                    }
                    .disabled(!canCreate)
                }
            }
            .onAppear {
                isTitleFieldFocused = true
                loadAvailableData()
            }
            .alert("Error Creating Task", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage ?? "An unexpected error occurred")
            }
            .sheet(isPresented: $showingAssigneePicker) {
                AssigneePickerSheet(
                    projectBoardId: projectBoardId,
                    selectedAssignees: $assigneeIds
                )
            }
            .sheet(isPresented: $showingDependencyPicker) {
                TaskDependencyPickerSheet(
                    projectBoardId: projectBoardId,
                    excludeTaskId: nil,
                    selectedDependencies: $selectedDependencies
                )
            }
            .disabled(isCreating)
            .overlay {
                if isCreating {
                    LoadingOverlay(message: "Creating task...")
                }
            }
        }
    }
    
    // MARK: - Form Sections
    
    private var basicInfoSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                TextField("Task title", text: $taskTitle)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityFocused($isTitleFieldFocused)
                    .accessibilityLabel("Task title")
                    .accessibilityHint("Enter a title for the task")
                
                TextField("Description (optional)", text: $taskDescription, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(3...6)
                    .accessibilityLabel("Task description")
                    .accessibilityHint("Enter an optional description for the task")
                
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Priority")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Picker("Priority", selection: $selectedPriority) {
                            ForEach(TaskPriority.allCases, id: \.self) { priority in
                                HStack {
                                    Circle()
                                        .fill(priority.color)
                                        .frame(width: 8, height: 8)
                                    Text(priority.displayName)
                                }
                                .tag(priority)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Status")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Picker("Status", selection: $selectedStatus) {
                            ForEach(TaskStatus.allCases, id: \.self) { status in
                                Text(status.displayName)
                                    .tag(status)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
            }
        } header: {
            Text("Basic Information")
        }
    }
    
    private var assignmentSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Assignees")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Button("Add") {
                        showingAssigneePicker = true
                    }
                    .font(.caption)
                    .foregroundColor(.accentColor)
                }
                
                if assigneeIds.isEmpty {
                    Text("No assignees")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                        ForEach(Array(assigneeIds), id: \.self) { assigneeId in
                            AssigneeChip(assigneeId: assigneeId) {
                                assigneeIds.remove(assigneeId)
                            }
                        }
                    }
                }
                
                // Tags
                HStack {
                    Text("Tags")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Button("Add") {
                        showingTagPicker = true
                    }
                    .font(.caption)
                    .foregroundColor(.accentColor)
                }
                
                if !selectedTags.isEmpty {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                        ForEach(Array(selectedTags), id: \.self) { tag in
                            TagChip(tag: tag) {
                                selectedTags.remove(tag)
                            }
                        }
                    }
                }
            }
        } header: {
            Text("Assignment & Tags")
        }
    }
    
    private var timelineSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                Toggle("Set due date", isOn: Binding(
                    get: { dueDate != nil },
                    set: { newValue in
                        if newValue {
                            dueDate = Calendar.current.date(byAdding: .day, value: 7, to: Date())
                        } else {
                            dueDate = nil
                        }
                    }
                ))
                
                if let _ = dueDate {
                    DatePicker("Due date", selection: Binding(
                        get: { dueDate ?? Date() },
                        set: { dueDate = $0 }
                    ), displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(.compact)
                }
                
                HStack {
                    Text("Estimated hours")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    TextField("0", value: $estimatedHours, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                        .keyboardType(.decimalPad)
                }
            }
        } header: {
            Text("Timeline")
        }
    }
    
    private var checklistSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Checklist")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text("\(checklistItems.count) items")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    TextField("Add checklist item", text: $newChecklistItem)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit {
                            addChecklistItem()
                        }
                    
                    Button("Add") {
                        addChecklistItem()
                    }
                    .disabled(newChecklistItem.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                
                ForEach(checklistItems.indices, id: \.self) { index in
                    HStack {
                        TextField("Item", text: $checklistItems[index].title)
                            .textFieldStyle(.roundedBorder)
                        
                        Button(action: {
                            checklistItems.remove(at: index)
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(.red)
                        }
                        .accessibilityLabel("Remove checklist item")
                    }
                }
            }
        } header: {
            Text("Checklist (\(checklistItems.count))")
        }
    }
    
    private var dependenciesSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Dependencies")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Button("Add") {
                        showingDependencyPicker = true
                    }
                    .font(.caption)
                    .foregroundColor(.accentColor)
                }
                
                if selectedDependencies.isEmpty {
                    Text("No dependencies")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(selectedDependencies), id: \.self) { dependencyId in
                            DependencyChip(taskId: dependencyId) {
                                selectedDependencies.remove(dependencyId)
                            }
                        }
                    }
                }
            }
        } header: {
            Text("Dependencies (\(selectedDependencies.count))")
        }
    }
    
    private var attachmentsSection: some View {
        Section {
            ForEach(attachments) { attachment in
                AttachmentRow(attachment: attachment) {
                    attachments.removeAll { $0.id == attachment.id }
                }
            }
        } header: {
            Text("Attachments (\(attachments.count))")
        }
    }
    
    // MARK: - Computed Properties
    
    private var canCreate: Bool {
        !taskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !isCreating
    }
    
    // MARK: - Actions
    
    private func createTask() {
        guard canCreate else { return }
        
        Task {
            await performCreation()
        }
    }
    
    @MainActor
    private func performCreation() async {
        isCreating = true
        errorMessage = nil
        
        do {
            let task = ProjectTask(
                id: UUID().uuidString,
                projectBoardId: projectBoardId,
                title: taskTitle.trimmingCharacters(in: .whitespacesAndNewlines),
                description: taskDescription.isEmpty ? nil : taskDescription,
                status: selectedStatus,
                priority: selectedPriority,
                assigneeIds: Array(assigneeIds),
                createdBy: UserDefaults.standard.string(forKey: "currentUserId") ?? "",
                dueDate: dueDate,
                estimatedHours: estimatedHours > 0 ? estimatedHours : nil,
                actualHours: nil,
                tags: Array(selectedTags),
                dependencyIds: Array(selectedDependencies),
                parentTaskId: parentTaskId,
                checklistItems: checklistItems.map { item in
                    ChecklistItem(
                        id: UUID().uuidString,
                        title: item.title,
                        isCompleted: false,
                        completedAt: nil,
                        completedBy: nil
                    )
                },
                attachmentIds: attachments.map { $0.id },
                createdAt: Date(),
                modifiedAt: Date()
            )
            
            try await viewModel.createProjectTask(task)
            
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
        
        isCreating = false
    }
    
    private func addChecklistItem() {
        let trimmed = newChecklistItem.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        checklistItems.append(ChecklistItemInput(title: trimmed))
        newChecklistItem = ""
    }
    
    private func loadAvailableData() {
        Task {
            await viewModel.loadAvailableData(for: projectBoardId)
        }
    }
}

// MARK: - Supporting Views

private struct AssigneeChip: View {
    let assigneeId: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(Color.accentColor)
                .frame(width: 16, height: 16)
                .overlay {
                    Text(String(assigneeId.prefix(1)).uppercased())
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            
            Text(assigneeId) // In real app, resolve to name
                .font(.caption)
                .lineLimit(1)
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .accessibilityLabel("Remove assignee")
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.blue.opacity(0.1))
        .clipShape(Capsule())
    }
}

private struct TagChip: View {
    let tag: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(tag)
                .font(.caption)
                .lineLimit(1)
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.orange.opacity(0.1))
        .clipShape(Capsule())
    }
}

private struct DependencyChip: View {
    let taskId: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack {
            HStack(spacing: 4) {
                Image(systemName: "arrow.right")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text(taskId) // In real app, resolve to task title
                    .font(.caption)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

private struct AttachmentRow: View {
    let attachment: TaskAttachment
    let onRemove: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: attachment.iconName)
                .foregroundColor(.accentColor)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(attachment.filename)
                    .font(.caption)
                    .lineLimit(1)
                
                Text(attachment.formattedSize)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: onRemove) {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }
}

// MARK: - Supporting Models

struct ChecklistItemInput {
    let title: String
}

struct TaskAttachment: Identifiable {
    let id: String
    let filename: String
    let fileSize: Int64
    let mimeType: String
    let uploadedAt: Date
    
    var iconName: String {
        if mimeType.hasPrefix("image/") {
            return "photo"
        } else if mimeType.hasPrefix("video/") {
            return "video"
        } else if mimeType.contains("pdf") {
            return "doc.text"
        } else {
            return "paperclip"
        }
    }
    
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }
}

// MARK: - Extensions

extension TaskPriority {
    var color: Color {
        switch self {
        case .critical: return .red
        case .high: return .orange
        case .medium: return .yellow
        case .low: return .green
        }
    }
    
    var displayName: String {
        switch self {
        case .critical: return "Critical"
        case .high: return "High"
        case .medium: return "Medium"
        case .low: return "Low"
        }
    }
}

extension TaskStatus {
    var displayName: String {
        switch self {
        case .todo: return "To Do"
        case .inProgress: return "In Progress"
        case .inReview: return "In Review"
        case .completed: return "Completed"
        case .onHold: return "On Hold"
        case .cancelled: return "Cancelled"
        }
    }
}

#Preview {
    CreateProjectTaskSheet(projectBoardId: "board1")
}
