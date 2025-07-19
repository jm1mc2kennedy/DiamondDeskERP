// TaskListView.swift
// Diamond Desk ERP

import SwiftUI

struct TaskListView: View {
    @StateObject private var viewModel: TaskViewModel
    @State private var error: IdentifiableError? // Added error state for ErrorBoundary
    
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency // For background fallback

    init(userRef: String) {
        _viewModel = StateObject(wrappedValue: TaskViewModel(userRef: userRef))
    }

    var body: some View {
        NavigationView {
            // Wrap List in ErrorBoundary to handle errors and provide retry action
            ErrorBoundary(error: $error, retry: { await viewModel.fetchAssignedTasks() }) {
                List {
                    ForEach(viewModel.tasks) { task in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(task.title)
                                .font(.body)
                                .dynamicTypeSize(.large ... .accessibility5)
                                .accessibilityLabel("Task title: \(task.title)") // Accessibility label
                            Text(task.status)
                                .font(.body)
                                .dynamicTypeSize(.large ... .accessibility5)
                                .foregroundColor(.secondary)
                                .accessibilityLabel("Status: \(task.status)") // Accessibility label
                            Text("Due: \(task.dueDate, formatter: itemFormatter)")
                                .font(.body)
                                .dynamicTypeSize(.large ... .accessibility5)
                                .accessibilityLabel("Due date: \(task.dueDate.formatted(date: .numeric, time: .shortened))") // Accessibility label
                        }
                        // Apply translucent background with fallback for accessibility setting
                        .background {
                            if reduceTransparency {
                                Color(.systemBackground)
                            } else {
                                .ultraThinMaterial
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
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
