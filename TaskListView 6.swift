// TaskListView.swift
// Diamond Desk ERP

import SwiftUI
import CloudKit

struct TaskListView: View {
    @StateObject private var viewModel: TaskViewModel
    @State private var selection: Set<CKRecord.ID> = [] // Track selected tasks for batch actions
    @State private var showDeleteAlert = false // Controls display of delete confirmation alert
    @State private var deleteErrorMessage: String? = nil // Holds error message if delete fails
    @State private var showErrorAlert = false // Controls display of error alert

    init(userRef: String) {
        _viewModel = StateObject(wrappedValue: TaskViewModel(userRef: userRef))
    }

    var body: some View {
        NavigationView {
            List(selection: $selection) { // Enable multi-selection binding
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
            .refreshable {
                await viewModel.fetchAssignedTasks()
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                }
            }
            // Toolbar with Delete button for batch deletion
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(role: .destructive) {
                        // Show confirmation alert before deleting
                        showDeleteAlert = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    .disabled(selection.isEmpty) // Disable if no selection
                    .accessibilityLabel("Delete selected tasks")
                    .accessibilityHint(selection.isEmpty ? "Select tasks to enable delete" : "Deletes selected tasks after confirmation")
                }
            }
            // Confirmation alert before batch delete
            .alert("Delete Selected Tasks?", isPresented: $showDeleteAlert) {
                Button("Delete", role: .destructive) {
                    Task {
                        await deleteSelectedTasks()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete the selected tasks? This action cannot be undone.")
            }
            // Show error alert if delete fails
            .alert("Error", isPresented: $showErrorAlert, actions: {
                Button("OK", role: .cancel) {}
            }, message: {
                Text(deleteErrorMessage ?? "An unknown error occurred.")
            })
        }
    }

    // Batch delete function
    private func deleteSelectedTasks() async {
        do {
            // Delete tasks with the selected record IDs via the view model
            try await viewModel.deleteTasks(with: selection)
            selection.removeAll() // Clear selection after successful delete
            await viewModel.fetchAssignedTasks() // Refresh list to reflect deletions
        } catch {
            // Show error alert with error message
            deleteErrorMessage = error.localizedDescription
            showErrorAlert = true
        }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    return formatter
}()

#Preview {
    TaskListView(userRef: "demo-user-id")
}
