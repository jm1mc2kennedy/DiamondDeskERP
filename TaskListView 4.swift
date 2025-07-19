// TaskListView.swift
// Diamond Desk ERP

import SwiftUI

struct TaskListView: View {
    @StateObject private var viewModel: TaskViewModel
    
    // MARK: - State for task sheet presentation and editing task
    @State private var showTaskSheet = false
    @State private var editingTask: TaskModel? = nil
    
    // MARK: - Alert state for error handling in TaskSheet
    @State private var alertMessage: String?
    @State private var showAlert = false
    
    init(userRef: String) {
        _viewModel = StateObject(wrappedValue: TaskViewModel(userRef: userRef))
    }

    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.tasks) { task in
                    // Wrap task cell in a button to present editing sheet
                    Button {
                        editingTask = task
                        showTaskSheet = true
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(task.title)
                                .font(.headline)
                            Text(task.status)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("Due: \(task.dueDate, formatter: itemFormatter)")
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .accessibilityLabel("Edit Task")
                    .accessibilityHint("Opens form to edit this task")
                }
            }
            .navigationTitle("Assigned Tasks")
            .refreshable {
                await viewModel.fetchAssignedTasks()
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                        .accessibilityLabel("Loading tasks")
                }
            }
            // Toolbar button to add new task
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        editingTask = nil
                        showTaskSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("New Task")
                    .accessibilityHint("Opens form to create a new task")
                }
            }
            // Sheet to edit or create a task
            .sheet(isPresented: $showTaskSheet) {
                TaskSheet(
                    task: editingTask,
                    userRef: viewModel.userRef,
                    onSave: { result in
                        switch result {
                        case .success:
                            showTaskSheet = false
                            Task {
                                await viewModel.fetchAssignedTasks()
                            }
                        case .failure(let error):
                            alertMessage = error.localizedDescription
                            showAlert = true
                        }
                    },
                    onCancel: {
                        showTaskSheet = false
                    }
                )
            }
            // Alert for save errors
            .alert("Error", isPresented: $showAlert, actions: {
                Button("OK", role: .cancel) {}
            }, message: {
                if let alertMessage = alertMessage {
                    Text(alertMessage)
                }
            })
        }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    return formatter
}()

// MARK: - TaskSheet View for creating/editing a task

struct TaskSheet: View {
    // Editing task (nil if new)
    var task: TaskModel?
    var userRef: String
    
    // MARK: - Form state vars
    @State private var title: String = ""
    @State private var detail: String = ""
    @State private var dueDate: Date = Date()
    @State private var status: String = "Pending"
    
    // Status options
    private let statusOptions = ["Pending", "In Progress", "Completed", "Cancelled"]
    
    // Save callback with Result<Void, Error>
    var onSave: (Result<Void, Error>) -> Void
    var onCancel: () -> Void
    
    // Validation error message
    @State private var validationMessage: String? = nil
    
    // Accessibility focus for validation message
    @AccessibilityFocusState private var validationMessageFocused: Bool
    
    // Repository
    private let repo = TaskRepository.shared
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("Title", text: $title)
                            .accessibilityLabel("Task Title")
                            .accessibilityHint("Enter the title of the task")
                        
                        TextField("Detail", text: $detail, axis: .vertical)
                            .lineLimit(3, reservesSpace: true)
                            .accessibilityLabel("Task Detail")
                            .accessibilityHint("Enter detailed information about the task")
                        
                        DatePicker("Due Date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                            .accessibilityLabel("Due Date")
                            .accessibilityHint("Select the due date and time for the task")
                        
                        Picker("Status", selection: $status) {
                            ForEach(statusOptions, id: \.self) { option in
                                Text(option)
                            }
                        }
                        .pickerStyle(.segmented)
                        .accessibilityLabel("Task Status")
                        .accessibilityHint("Select the current status of the task")
                    }
                    .formStyle(.grouped)
                }
                
                if let validationMessage = validationMessage {
                    Section {
                        Text(validationMessage)
                            .foregroundColor(.red)
                            .accessibilityFocused($validationMessageFocused)
                    }
                }
            }
            .navigationTitle(task == nil ? "New Task" : "Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveTask()
                    }
                    .accessibilityLabel("Save Task")
                    .accessibilityHint("Saves the task and closes the form")
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                    .accessibilityLabel("Cancel")
                    .accessibilityHint("Dismiss the form without saving")
                }
            }
            .onAppear(perform: loadData)
        }
    }
    
    // Load existing task data into form fields
    private func loadData() {
        guard let task = task else {
            // New task defaults
            title = ""
            detail = ""
            dueDate = Date()
            status = "Pending"
            validationMessage = nil
            return
        }
        title = task.title
        detail = task.detail ?? ""
        dueDate = task.dueDate
        status = task.status
        validationMessage = nil
    }
    
    // Validate fields and save task using repository
    private func saveTask() {
        // Validation
        validationMessage = nil
        
        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationMessage = "Title cannot be empty."
            validationMessageFocused = true
            return
        }
        
        if dueDate < Date(timeIntervalSince1970: 0) {
            validationMessage = "Due date is invalid."
            validationMessageFocused = true
            return
        }
        
        // Construct TaskModel for saving
        let id = task?.id ?? UUID().uuidString
        let newTask = TaskModel(
            id: id,
            userRef: userRef,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            detail: detail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : detail,
            dueDate: dueDate,
            status: status
        )
        
        repo.save(task: newTask) { error in
            DispatchQueue.main.async {
                if let error = error {
                    onSave(.failure(error))
                } else {
                    onSave(.success(()))
                }
            }
        }
    }
}


// MARK: - Preview

#Preview {
    TaskListView(userRef: "demo-user-id")
}
