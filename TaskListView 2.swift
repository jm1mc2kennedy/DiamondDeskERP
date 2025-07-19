// TaskListView.swift
// Diamond Desk ERP

import SwiftUI

struct TaskListView: View {
    @StateObject private var viewModel: TaskViewModel
    @State private var showNewTaskSheet = false // State to control the presentation of NewTaskSheet

    init(userRef: String) {
        _viewModel = StateObject(wrappedValue: TaskViewModel(userRef: userRef))
    }

    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.tasks) { task in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(task.title)
                            .font(.headline)
                        Text(task.status)
                            .font(.subheadline).foregroundColor(.secondary)
                        Text("Due: \(task.dueDate, formatter: itemFormatter)")
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Assigned Tasks")
            .toolbar {
                // Toolbar button to present the NewTaskSheet
                Button {
                    showNewTaskSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
            .refreshable {
                await viewModel.fetchAssignedTasks()
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                }
            }
            // Present the NewTaskSheet when showNewTaskSheet is true
            .sheet(isPresented: $showNewTaskSheet) {
                NewTaskSheet { 
                    // On successful save, refresh the task list and dismiss sheet
                    TaskListViewTaskSaveCompletion(viewModel: viewModel, isPresented: $showNewTaskSheet)
                }
            }
        }
    }
}

// Helper view to handle task save completion asynchronously
@MainActor
private func TaskListViewTaskSaveCompletion(viewModel: TaskViewModel, isPresented: Binding<Bool>) async {
    await viewModel.fetchAssignedTasks()
    isPresented.wrappedValue = false
}

// Date formatter for displaying due date
private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    return formatter
}()

// MARK: - NewTaskSheet View
struct NewTaskSheet: View {
    // Input fields for new task
    @State private var title: String = ""
    @State private var detail: String = ""
    @State private var dueDate: Date = Date()
    
    // Environment dismiss to close the sheet
    @Environment(\.dismiss) private var dismiss
    
    // Completion handler called after saving
    var onSave: () async -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section("Title") {
                    TextField("Enter title", text: $title)
                }
                Section("Detail") {
                    TextField("Enter detail", text: $detail)
                }
                Section("Due Date") {
                    DatePicker("Select due date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                }
            }
            .navigationTitle("New Task")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await saveTask()
                        }
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // Save the new task and call completion
    private func saveTask() async {
        // Create a new TaskModel with mock/default values for required fields
        let newTask = TaskModel(
            id: UUID().uuidString, // Unique identifier
            title: title.trimmingCharacters(in: .whitespaces),
            detail: detail.trimmingCharacters(in: .whitespaces),
            dueDate: dueDate,
            status: "Pending",
            assignedTo: "demo-user-id" // This could be replaced with actual userRef if needed
        )
        
        do {
            // Save the task using TaskRepository
            try await TaskRepository.shared.saveTask(newTask)
            await onSave()
            dismiss()
        } catch {
            // Handle error appropriately (e.g. show alert) - omitted here for brevity
        }
    }
}

#Preview {
    TaskListView(userRef: "demo-user-id")
}
