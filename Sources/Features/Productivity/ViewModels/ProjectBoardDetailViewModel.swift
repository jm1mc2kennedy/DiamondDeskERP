//
//  ProjectBoardDetailViewModel.swift
//  DiamondDeskERP
//
//  Created by AI Assistant on 7/20/25.
//

import Foundation
import Combine
import CloudKit

@MainActor
class ProjectBoardDetailViewModel: ObservableObject {
    @Published var projectBoard: ProjectBoard?
    @Published var tasks: [ProjectTask] = []
    @Published var filteredTasks: [ProjectTask] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Filter State
    @Published var searchText = ""
    @Published var assigneeFilter: String?
    @Published var priorityFilter: TaskPriority?
    @Published var statusFilter: TaskStatus?
    @Published var tagFilter: String?
    
    private let productivityService: ProductivityService
    private let projectTaskService: ProjectTaskService
    private var cancellables = Set<AnyCancellable>()
    
    init(
        productivityService: ProductivityService = ProductivityService.shared,
        projectTaskService: ProjectTaskService = ProjectTaskService.shared
    ) {
        self.productivityService = productivityService
        self.projectTaskService = projectTaskService
        
        setupFilterSubscriptions()
    }
    
    // MARK: - Public Methods
    
    func loadProjectBoard(_ boardId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            async let board = productivityService.getProjectBoard(boardId)
            async let boardTasks = projectTaskService.getTasksForBoard(boardId)
            
            let (loadedBoard, loadedTasks) = try await (board, boardTasks)
            
            self.projectBoard = loadedBoard
            self.tasks = loadedTasks
            self.filteredTasks = loadedTasks
            
            await updateBoardProgress()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func refreshBoard() async {
        guard let boardId = projectBoard?.id else { return }
        await loadProjectBoard(boardId)
    }
    
    func updateTaskStatus(_ taskId: String, to status: TaskStatus) async {
        do {
            try await projectTaskService.updateTaskStatus(taskId, status: status)
            await refreshTasksData()
        } catch {
            errorMessage = "Failed to update task: \(error.localizedDescription)"
        }
    }
    
    func updateTaskDates(_ taskId: String, startDate: Date?, endDate: Date?) async {
        do {
            if let task = tasks.first(where: { $0.id == taskId }) {
                var updatedTask = task
                // In real implementation, update date fields
                try await projectTaskService.updateTask(updatedTask)
                await refreshTasksData()
            }
        } catch {
            errorMessage = "Failed to update task dates: \(error.localizedDescription)"
        }
    }
    
    func exportBoard() async {
        guard let board = projectBoard else { return }
        
        do {
            let exportData = BoardExportData(
                board: board,
                tasks: tasks,
                exportedAt: Date()
            )
            
            // In real implementation, handle export (CSV, JSON, etc.)
            print("Exporting board: \(exportData)")
        } catch {
            errorMessage = "Failed to export board: \(error.localizedDescription)"
        }
    }
    
    func archiveBoard() async {
        guard let board = projectBoard else { return }
        
        do {
            var updatedBoard = board
            updatedBoard.status = .archived
            updatedBoard.modifiedAt = Date()
            
            try await productivityService.updateProjectBoard(updatedBoard)
            self.projectBoard = updatedBoard
        } catch {
            errorMessage = "Failed to archive board: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Filter Methods
    
    func updateSearchText(_ text: String) {
        searchText = text
        applyFilters()
    }
    
    func updateAssigneeFilter(_ assignee: String?) {
        assigneeFilter = assignee
        applyFilters()
    }
    
    func updatePriorityFilter(_ priority: TaskPriority?) {
        priorityFilter = priority
        applyFilters()
    }
    
    func updateStatusFilter(_ status: TaskStatus?) {
        statusFilter = status
        applyFilters()
    }
    
    func updateTagFilter(_ tag: String?) {
        tagFilter = tag
        applyFilters()
    }
    
    // MARK: - Computed Properties
    
    var completedTasksCount: Int {
        tasks.filter { $0.status == .completed }.count
    }
    
    var dueSoonTasksCount: Int {
        let threeDaysFromNow = Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date()
        return tasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return dueDate <= threeDaysFromNow && task.status != .completed
        }.count
    }
    
    var overdueTasksCount: Int {
        let now = Date()
        return tasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return dueDate < now && task.status != .completed
        }.count
    }
    
    // MARK: - Private Methods
    
    private func setupFilterSubscriptions() {
        // Combine filter publishers for reactive filtering
        Publishers.CombineLatest4(
            $searchText,
            $assigneeFilter,
            $priorityFilter,
            $statusFilter
        )
        .combineLatest($tagFilter)
        .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
        .sink { [weak self] _ in
            self?.applyFilters()
        }
        .store(in: &cancellables)
    }
    
    private func applyFilters() {
        var filtered = tasks
        
        // Text search
        if !searchText.isEmpty {
            filtered = filtered.filter { task in
                task.title.localizedCaseInsensitiveContains(searchText) ||
                (task.description?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                task.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        // Assignee filter
        if let assigneeFilter = assigneeFilter {
            filtered = filtered.filter { task in
                task.assigneeIds.contains(assigneeFilter)
            }
        }
        
        // Priority filter
        if let priorityFilter = priorityFilter {
            filtered = filtered.filter { $0.priority == priorityFilter }
        }
        
        // Status filter
        if let statusFilter = statusFilter {
            filtered = filtered.filter { $0.status == statusFilter }
        }
        
        // Tag filter
        if let tagFilter = tagFilter {
            filtered = filtered.filter { task in
                task.tags.contains(tagFilter)
            }
        }
        
        filteredTasks = filtered
    }
    
    private func refreshTasksData() async {
        guard let boardId = projectBoard?.id else { return }
        
        do {
            tasks = try await projectTaskService.getTasksForBoard(boardId)
            applyFilters()
            await updateBoardProgress()
        } catch {
            errorMessage = "Failed to refresh tasks: \(error.localizedDescription)"
        }
    }
    
    private func updateBoardProgress() async {
        guard var board = projectBoard else { return }
        
        let totalTasks = tasks.count
        let completedTasks = tasks.filter { $0.status == .completed }.count
        
        board.progress = totalTasks > 0 ? Double(completedTasks) / Double(totalTasks) : 0.0
        board.modifiedAt = Date()
        
        do {
            try await productivityService.updateProjectBoard(board)
            self.projectBoard = board
        } catch {
            // Don't show error for progress updates
            print("Failed to update board progress: \(error)")
        }
    }
}

// MARK: - Supporting Models

struct BoardExportData {
    let board: ProjectBoard
    let tasks: [ProjectTask]
    let exportedAt: Date
}
