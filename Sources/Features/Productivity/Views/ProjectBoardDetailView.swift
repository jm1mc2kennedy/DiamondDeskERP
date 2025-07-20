//
//  ProjectBoardDetailView.swift
//  DiamondDeskERP
//
//  Created by AI Assistant on 7/20/25.
//

import SwiftUI
import Combine

struct ProjectBoardDetailView: View {
    let projectBoardId: String
    
    @StateObject private var viewModel = ProjectBoardDetailViewModel()
    @State private var selectedViewType: ProjectBoardViewType = .kanban
    @State private var showingCreateTask = false
    @State private var showingSettings = false
    @State private var showingFilters = false
    @State private var searchText = ""
    
    // Filter State
    @State private var selectedAssigneeFilter: String?
    @State private var selectedPriorityFilter: TaskPriority?
    @State private var selectedStatusFilter: TaskStatus?
    @State private var selectedTagFilter: String?
    
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let board = viewModel.projectBoard {
                    boardHeaderView(board)
                    
                    filterBarView
                    
                    boardContentView(board)
                } else if viewModel.isLoading {
                    loadingView
                } else if viewModel.errorMessage != nil {
                    errorView
                } else {
                    emptyView
                }
            }
            .navigationTitle("Project Board")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Menu {
                        Button("Settings") {
                            showingSettings = true
                        }
                        
                        Button("Export Board") {
                            exportBoard()
                        }
                        
                        Button("Archive Board") {
                            archiveBoard()
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    
                    Button(action: { showingCreateTask = true }) {
                        Image(systemName: "plus.circle.fill")
                    }
                    .accessibilityLabel("Create new task")
                }
            }
            .searchable(text: $searchText, prompt: "Search tasks...")
            .onAppear {
                loadBoard()
            }
            .refreshable {
                await refreshBoard()
            }
            .sheet(isPresented: $showingCreateTask) {
                CreateProjectTaskSheet(projectBoardId: projectBoardId)
            }
            .sheet(isPresented: $showingSettings) {
                ProjectBoardSettingsSheet(projectBoard: viewModel.projectBoard)
            }
            .sheet(isPresented: $showingFilters) {
                TaskFiltersSheet(
                    selectedAssignee: $selectedAssigneeFilter,
                    selectedPriority: $selectedPriorityFilter,
                    selectedStatus: $selectedStatusFilter,
                    selectedTag: $selectedTagFilter
                )
            }
        }
        .onChange(of: searchText) { _, newValue in
            viewModel.updateSearchText(newValue)
        }
        .onChange(of: selectedAssigneeFilter) { _, newValue in
            viewModel.updateAssigneeFilter(newValue)
        }
        .onChange(of: selectedPriorityFilter) { _, newValue in
            viewModel.updatePriorityFilter(newValue)
        }
        .onChange(of: selectedStatusFilter) { _, newValue in
            viewModel.updateStatusFilter(newValue)
        }
        .onChange(of: selectedTagFilter) { _, newValue in
            viewModel.updateTagFilter(newValue)
        }
    }
    
    // MARK: - Board Header
    
    private func boardHeaderView(_ board: ProjectBoard) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(board.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    if let description = board.description {
                        Text(description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    StatusBadge(status: board.status)
                    
                    Text(board.progress, format: .percent)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
            }
            
            // Board Stats
            HStack(spacing: 20) {
                StatItem(title: "Tasks", value: "\(viewModel.filteredTasks.count)")
                StatItem(title: "Completed", value: "\(viewModel.completedTasksCount)")
                StatItem(title: "Due Soon", value: "\(viewModel.dueSoonTasksCount)")
                StatItem(title: "Overdue", value: "\(viewModel.overdueTasksCount)")
                
                Spacer()
                
                if !board.memberIds.isEmpty {
                    AvatarStack(memberIds: Array(board.memberIds.prefix(5)))
                }
            }
            
            // Progress Bar
            ProgressView(value: board.progress)
                .progressViewStyle(LinearProgressViewStyle(tint: board.status.color))
                .scaleEffect(y: 2)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
    
    // MARK: - Filter Bar
    
    private var filterBarView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // View Type Picker
                Picker("View Type", selection: $selectedViewType) {
                    ForEach(ProjectBoardViewType.allCases, id: \.self) { viewType in
                        HStack {
                            Image(systemName: viewType.iconName)
                            Text(viewType.displayName)
                        }
                        .tag(viewType)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 280)
                
                Divider()
                    .frame(height: 20)
                
                // Filter Buttons
                Button(action: { showingFilters = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                        Text("Filters")
                        
                        if hasActiveFilters {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                        }
                    }
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(hasActiveFilters ? Color.accentColor.opacity(0.2) : Color.gray.opacity(0.1))
                    .clipShape(Capsule())
                }
                
                if hasActiveFilters {
                    Button("Clear") {
                        clearAllFilters()
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                }
                
                Spacer(minLength: 0)
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Board Content
    
    private func boardContentView(_ board: ProjectBoard) -> some View {
        Group {
            switch selectedViewType {
            case .kanban:
                KanbanBoardView(
                    tasks: viewModel.filteredTasks,
                    onTaskTap: handleTaskTap,
                    onTaskMove: handleTaskMove
                )
            case .table:
                TableBoardView(
                    tasks: viewModel.filteredTasks,
                    onTaskTap: handleTaskTap,
                    onTaskEdit: handleTaskEdit
                )
            case .calendar:
                CalendarBoardView(
                    tasks: viewModel.filteredTasks,
                    onTaskTap: handleTaskTap,
                    onDateTap: handleDateTap
                )
            case .timeline:
                TimelineBoardView(
                    tasks: viewModel.filteredTasks,
                    onTaskTap: handleTaskTap,
                    onTaskResize: handleTaskResize
                )
            }
        }
    }
    
    // MARK: - State Views
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading board...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var errorView: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.orange)
            
            Text("Failed to load board")
                .font(.headline)
            
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("Try Again") {
                loadBoard()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            
            Text("Board not found")
                .font(.headline)
            
            Text("This board may have been deleted or you may not have access to it.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Computed Properties
    
    private var hasActiveFilters: Bool {
        selectedAssigneeFilter != nil ||
        selectedPriorityFilter != nil ||
        selectedStatusFilter != nil ||
        selectedTagFilter != nil
    }
    
    // MARK: - Actions
    
    private func loadBoard() {
        Task {
            await viewModel.loadProjectBoard(projectBoardId)
        }
    }
    
    private func refreshBoard() async {
        await viewModel.refreshBoard()
    }
    
    private func handleTaskTap(_ task: ProjectTask) {
        // Navigate to task detail
        print("Task tapped: \(task.title)")
    }
    
    private func handleTaskMove(_ task: ProjectTask, to status: TaskStatus) {
        Task {
            await viewModel.updateTaskStatus(task.id, to: status)
        }
    }
    
    private func handleTaskEdit(_ task: ProjectTask) {
        // Show edit sheet
        print("Edit task: \(task.title)")
    }
    
    private func handleDateTap(_ date: Date) {
        // Create task for specific date
        print("Date tapped: \(date)")
    }
    
    private func handleTaskResize(_ task: ProjectTask, newDates: (start: Date?, end: Date?)) {
        Task {
            await viewModel.updateTaskDates(task.id, startDate: newDates.start, endDate: newDates.end)
        }
    }
    
    private func clearAllFilters() {
        selectedAssigneeFilter = nil
        selectedPriorityFilter = nil
        selectedStatusFilter = nil
        selectedTagFilter = nil
    }
    
    private func exportBoard() {
        Task {
            await viewModel.exportBoard()
        }
    }
    
    private func archiveBoard() {
        Task {
            await viewModel.archiveBoard()
        }
    }
}

// MARK: - Supporting Views

private struct StatItem: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

private struct StatusBadge: View {
    let status: ProjectBoardStatus
    
    var body: some View {
        Text(status.displayName)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(status.color.opacity(0.2))
            .foregroundColor(status.color)
            .clipShape(Capsule())
    }
}

private struct AvatarStack: View {
    let memberIds: [String]
    let maxVisible = 5
    
    var body: some View {
        HStack(spacing: -8) {
            ForEach(Array(memberIds.prefix(maxVisible).enumerated()), id: \.offset) { index, memberId in
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 24, height: 24)
                    .overlay {
                        Text(String(memberId.prefix(1)).uppercased())
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    .overlay {
                        Circle()
                            .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                    }
                    .zIndex(Double(maxVisible - index))
            }
            
            if memberIds.count > maxVisible {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 24, height: 24)
                    .overlay {
                        Text("+\(memberIds.count - maxVisible)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }
            }
        }
    }
}

// MARK: - Extensions

extension ProjectBoardStatus {
    var color: Color {
        switch self {
        case .planning: return .blue
        case .active: return .green
        case .onHold: return .orange
        case .completed: return .purple
        case .archived: return .gray
        }
    }
}

#Preview {
    ProjectBoardDetailView(projectBoardId: "board1")
}
