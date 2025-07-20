import SwiftUI

struct TaskListView: View {
    @StateObject private var viewModel = TaskViewModel()
    @Environment(\.currentUser) private var currentUser

    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading tasks...")
                } else if let error = viewModel.error {
                    VStack {
                        Text("Error loading tasks")
                        Text(error.localizedDescription).font(.caption)
                    }
                } else if viewModel.tasks.isEmpty {
                    Text("No tasks assigned.")
                } else {
                    List(viewModel.tasks) { task in
                        TaskRow(task: task)
                    }
                }
            }
            .navigationTitle("My Tasks")
            .onAppear {
                if let user = currentUser {
                    viewModel.fetchTasks(for: user)
                }
            }
        }
    }
}

struct TaskRow: View {
    let task: TaskModel

    var body: some View {
        VStack(alignment: .leading) {
            Text(task.title).font(.headline)
            Text(task.description).font(.subheadline).lineLimit(2)
            HStack {
                Text(task.status.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                if let dueDate = task.dueDate {
                    Text("Due: \(dueDate, style: .date)")
                        .font(.caption)
                        .foregroundColor(dueDate < Date() ? .red : .secondary)
                }
            }
        }
    }
}

struct TaskListView_Previews: PreviewProvider {
    static var previews: some View {
        TaskListView()
    }
}
