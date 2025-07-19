// TaskListView.swift
// Diamond Desk ERP

import SwiftUI

struct TaskListView: View {
    @StateObject private var viewModel: TaskViewModel
    
    // --- Advanced Filtering & Search ---
    @State private var searchText: String = ""
    @State private var selectedStatus: TaskStatusFilter? = nil
    @State private var showFilters: Bool = false
    
    init(userRef: String) {
        _viewModel = StateObject(wrappedValue: TaskViewModel(userRef: userRef))
    }

    var body: some View {
        NavigationView {
            List {
                // Filter tasks by searchText and selectedStatus
                ForEach(filteredTasks) { task in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(task.title)
                            .font(.headline)
                        Text(task.status)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("Due: \(task.dueDate, formatter: itemFormatter)")
                            .font(.caption)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(task.title), status \(task.status), due \(itemFormatter.string(from: task.dueDate))")
                }
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer) // Search bar for task title/detail
            .accessibilityLabel("Search Tasks")
            .accessibilityHint("Search tasks by title or details")
            .navigationTitle("Assigned Tasks")
            .refreshable {
                await viewModel.fetchAssignedTasks()
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        // Status filter picker inside menu
                        Picker("Status", selection: $selectedStatus) {
                            Text("All").tag(TaskStatusFilter?.none)
                            ForEach(TaskStatusFilter.allCases, id: \.self) { filter in
                                Text(filter.rawValue).tag(TaskStatusFilter?.some(filter))
                            }
                        }
                        .pickerStyle(.inline)
                        .accessibilityLabel("Filter by task status")
                        .accessibilityHint("Filters tasks by selected status")
                    } label: {
                        Label("Filters", systemImage: "line.3.horizontal.decrease.circle")
                    }
                    .background(
                        // Visual polish: ultraThinMaterial background with rounded rectangle
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.ultraThinMaterial)
                            .opacity(showFilters ? 1.0 : 0.0)
                    )
                    .accessibilityLabel("Filters menu")
                    .accessibilityHint("Open filter options")
                }
            }
        }
    }
    
    // Computed property for filtered tasks
    private var filteredTasks: [Task] {
        viewModel.tasks.filter { task in
            // Filter by searchText (matches title or detail)
            let matchesSearch = searchText.isEmpty || task.title.localizedCaseInsensitiveContains(searchText) || task.detail.localizedCaseInsensitiveContains(searchText)
            
            // Filter by selectedStatus if set
            let matchesStatus = selectedStatus == nil || task.status == selectedStatus?.rawValue
            
            return matchesSearch && matchesStatus
        }
    }
}

// Define TaskStatusFilter enum for status filtering
enum TaskStatusFilter: String, CaseIterable {
    case open = "Open"
    case inProgress = "In Progress"
    case done = "Done"
}

// Assuming Task and TaskViewModel are defined elsewhere with needed properties

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    return formatter
}()

#Preview {
    TaskListView(userRef: "demo-user-id")
}
