import SwiftUI

struct EditTaskView: View {
    @StateObject private var viewModel = TaskViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.currentUser) private var currentUser
    
    let task: TaskModel
    
    @State private var title: String
    @State private var description: String
    @State private var selectedPriority: TaskPriority
    @State private var selectedStatus: TaskStatus
    @State private var selectedCompletionMode: TaskCompletionMode
    @State private var selectedCategory: String
    @State private var dueDate: Date
    @State private var estimatedDuration: TimeInterval
    @State private var selectedAssignee: User?
    @State private var selectedCollaborators: Set<User>
    @State private var selectedTags: Set<String>
    @State private var showingUserPicker = false
    @State private var showingCollaboratorPicker = false
    @State private var showingTagEditor = false
    
    @State private var isUpdating = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingDeleteConfirmation = false
    
    private let categories = [
        "Development",
        "Testing",
        "Documentation",
        "Research",
        "Meeting",
        "Review",
        "Bug Fix",
        "Feature",
        "Maintenance",
        "Training"
    ]
    
    init(task: TaskModel) {
        self.task = task
        self._title = State(initialValue: task.title)
        self._description = State(initialValue: task.description)
        self._selectedPriority = State(initialValue: task.priority)
        self._selectedStatus = State(initialValue: task.status)
        self._selectedCompletionMode = State(initialValue: task.completionMode)
        self._selectedCategory = State(initialValue: task.category)
        self._dueDate = State(initialValue: task.dueDate)
        self._estimatedDuration = State(initialValue: task.estimatedDuration)
        self._selectedAssignee = State(initialValue: task.assignee)
        self._selectedCollaborators = State(initialValue: Set(task.collaborators))
        self._selectedTags = State(initialValue: Set(task.tags))
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Task Details") {
                    TextField("Title", text: $title)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Description")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextEditor(text: $description)
                            .frame(minHeight: 100)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                            )
                    }
                    
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                Section("Priority & Status") {
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
                    .pickerStyle(MenuPickerStyle())
                    
                    Picker("Status", selection: $selectedStatus) {
                        ForEach(TaskStatus.allCases, id: \.self) { status in
                            Text(status.displayName).tag(status)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    
                    Picker("Completion Mode", selection: $selectedCompletionMode) {
                        ForEach(TaskCompletionMode.allCases, id: \.self) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                Section("Timeline") {
                    DatePicker("Due Date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Estimated Duration")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Picker("Duration", selection: $estimatedDuration) {
                            Text("30 minutes").tag(TimeInterval(1800))
                            Text("1 hour").tag(TimeInterval(3600))
                            Text("2 hours").tag(TimeInterval(7200))
                            Text("4 hours").tag(TimeInterval(14400))
                            Text("1 day").tag(TimeInterval(86400))
                            Text("2 days").tag(TimeInterval(172800))
                            Text("1 week").tag(TimeInterval(604800))
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                }
                
                Section("Assignment") {
                    HStack {
                        Text("Assignee")
                        Spacer()
                        if let assignee = selectedAssignee {
                            Text(assignee.displayName)
                                .foregroundColor(.secondary)
                        } else {
                            Text("Select Assignee")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        showingUserPicker = true
                    }
                    
                    HStack {
                        Text("Collaborators")
                        Spacer()
                        Text("\(selectedCollaborators.count) selected")
                            .foregroundColor(.secondary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        showingCollaboratorPicker = true
                    }
                    
                    if !selectedCollaborators.isEmpty {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
                            ForEach(Array(selectedCollaborators), id: \.id) { user in
                                HStack(spacing: 4) {
                                    Text(user.displayName)
                                        .font(.caption)
                                    Button(action: {
                                        selectedCollaborators.remove(user)
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.secondary)
                                            .font(.caption)
                                    }
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.secondary.opacity(0.1))
                                .cornerRadius(12)
                            }
                        }
                    }
                }
                
                Section("Tags") {
                    HStack {
                        Text("Tags")
                        Spacer()
                        Text("\(selectedTags.count) tags")
                            .foregroundColor(.secondary)
                        Button("Edit") {
                            showingTagEditor = true
                        }
                        .font(.caption)
                    }
                    
                    if !selectedTags.isEmpty {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 8) {
                            ForEach(Array(selectedTags), id: \.self) { tag in
                                HStack(spacing: 4) {
                                    Text(tag)
                                        .font(.caption)
                                    Button(action: {
                                        selectedTags.remove(tag)
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.secondary)
                                            .font(.caption)
                                    }
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(12)
                            }
                        }
                    }
                }
                
                Section("Actions") {
                    Button(action: {
                        showingDeleteConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete Task")
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        updateTask()
                    }
                    .disabled(!isFormValid || isUpdating)
                }
            }
            .sheet(isPresented: $showingUserPicker) {
                UserPickerView(
                    selectedUser: $selectedAssignee,
                    title: "Select Assignee"
                )
            }
            .sheet(isPresented: $showingCollaboratorPicker) {
                MultiUserPickerView(
                    selectedUsers: $selectedCollaborators,
                    title: "Select Collaborators"
                )
            }
            .sheet(isPresented: $showingTagEditor) {
                TagEditorView(selectedTags: $selectedTags)
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .alert("Delete Task", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteTask()
                }
            } message: {
                Text("Are you sure you want to delete this task? This action cannot be undone.")
            }
            .overlay {
                if isUpdating {
                    Color.black.opacity(0.3)
                        .overlay {
                            ProgressView("Updating task...")
                                .padding()
                                .background(Color(.systemBackground))
                                .cornerRadius(12)
                        }
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !selectedCategory.isEmpty
    }
    
    private func updateTask() {
        guard let user = currentUser else {
            errorMessage = "User not found"
            showingError = true
            return
        }
        
        isUpdating = true
        
        Task {
            do {
                var updatedTask = task
                updatedTask.title = title
                updatedTask.description = description
                updatedTask.priority = selectedPriority
                updatedTask.status = selectedStatus
                updatedTask.completionMode = selectedCompletionMode
                updatedTask.category = selectedCategory
                updatedTask.dueDate = dueDate
                updatedTask.estimatedDuration = estimatedDuration
                updatedTask.assignee = selectedAssignee
                updatedTask.collaborators = Array(selectedCollaborators)
                updatedTask.tags = Array(selectedTags)
                updatedTask.updatedAt = Date()
                
                try await viewModel.updateTask(updatedTask)
                
                await MainActor.run {
                    isUpdating = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isUpdating = false
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
    }
    
    private func deleteTask() {
        isUpdating = true
        
        Task {
            do {
                try await viewModel.deleteTask(task)
                
                await MainActor.run {
                    isUpdating = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isUpdating = false
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
    }
}

// Supporting tag editor view
struct TagEditorView: View {
    @Binding var selectedTags: Set<String>
    @Environment(\.dismiss) private var dismiss
    
    @State private var newTag = ""
    
    private let commonTags = [
        "urgent", "bug", "feature", "documentation", "testing",
        "review", "meeting", "research", "maintenance", "training"
    ]
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    TextField("Add new tag", text: $newTag)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button("Add") {
                        addTag()
                    }
                    .disabled(newTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding()
                
                List {
                    Section("Common Tags") {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
                            ForEach(commonTags, id: \.self) { tag in
                                Button(action: {
                                    toggleTag(tag)
                                }) {
                                    HStack {
                                        Text(tag)
                                            .font(.caption)
                                        if selectedTags.contains(tag) {
                                            Image(systemName: "checkmark")
                                                .font(.caption)
                                        }
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(selectedTags.contains(tag) ? Color.blue : Color.secondary.opacity(0.1))
                                    .foregroundColor(selectedTags.contains(tag) ? .white : .primary)
                                    .cornerRadius(12)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    
                    if !selectedTags.isEmpty {
                        Section("Selected Tags") {
                            ForEach(Array(selectedTags), id: \.self) { tag in
                                HStack {
                                    Text(tag)
                                    Spacer()
                                    Button(action: {
                                        selectedTags.remove(tag)
                                    }) {
                                        Image(systemName: "minus.circle")
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Edit Tags")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func addTag() {
        let tag = newTag.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !tag.isEmpty, !selectedTags.contains(tag) else { return }
        
        selectedTags.insert(tag)
        newTag = ""
    }
    
    private func toggleTag(_ tag: String) {
        if selectedTags.contains(tag) {
            selectedTags.remove(tag)
        } else {
            selectedTags.insert(tag)
        }
    }
}

#Preview {
    EditTaskView(task: TaskModel.sampleTask)
        .environment(\.currentUser, User.sampleUser)
}
