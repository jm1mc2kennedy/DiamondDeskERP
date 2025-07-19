// TaskListView.swift
// Diamond Desk ERP

import SwiftUI

struct TaskListView: View {
    @StateObject private var viewModel: TaskViewModel
    
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
            .refreshable {
                await viewModel.fetchAssignedTasks()
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                }
            }
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
