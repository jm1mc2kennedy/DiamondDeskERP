import Foundation
import SwiftUI
import Combine
import CloudKit

/// Centralized view model for the comprehensive productivity suite
/// Orchestrates Project Management, Personal To-Dos, and OKR modules
/// Provides unified state management and cross-module integration
@MainActor
final class ProductivityViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    // Combined state
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedModule: ProductivityModule = .projects
    @Published var searchText = ""
    @Published var selectedFilters: ProductivityFilters = ProductivityFilters()
    
    // Project Management
    @Published var projectBoards: [ProjectBoard] = []
    @Published var selectedBoard: ProjectBoard?
    @Published var projectTasks: [ProjectTask] = []
    @Published var selectedTask: ProjectTask?
    @Published var boardViewType: BoardViewType = .kanban
    
    // Personal To-Dos
    @Published var personalTodos: [PersonalTodo] = []
    @Published var todoCompletionRate: Double = 0.0
    @Published var overdueTodos: [PersonalTodo] = []
    
    // OKRs
    @Published var objectives: [Objective] = []
    @Published var selectedObjective: Objective?
    @Published var okrProgress: OKRProgress = OKRProgress()
    
    // UI State
    @Published var showingCreateBoard = false
    @Published var showingCreateTask = false
    @Published var showingCreateTodo = false
    @Published var showingCreateObjective = false
    @Published var showingFilters = false
    @Published var showingExportOptions = false
    
    // MARK: - Private Properties
    private let productivityService: ProductivityService
    private let projectTaskService: ProjectTaskService
    private let currentUser: User
    private var cancellables = Set<AnyCancellable>()
    
    // Computed Properties
    var filteredProjectBoards: [ProjectBoard] {
        filterProjectBoards(projectBoards)
    }
    
    var filteredProjectTasks: [ProjectTask] {
        filterProjectTasks(projectTasks)
    }
    
    var filteredPersonalTodos: [PersonalTodo] {
        filterPersonalTodos(personalTodos)
    }
    
    var filteredObjectives: [Objective] {
        filterObjectives(objectives)
    }
    
    var productivityOverview: ProductivityOverview {
        productivityService.getProductivityOverview()
    }
    
    // MARK: - Initialization
    init(productivityService: ProductivityService, projectTaskService: ProjectTaskService, currentUser: User) {
        self.productivityService = productivityService
        self.projectTaskService = projectTaskService
        self.currentUser = currentUser
        
        setupObservation()
        
        Task {
            await refreshAllData()
        }
    }
    
    // MARK: - Setup
    private func setupObservation() {
        // Observe productivity service changes
        productivityService.$projectBoards
            .receive(on: DispatchQueue.main)
            .assign(to: \.projectBoards, on: self)
            .store(in: &cancellables)
        
        productivityService.$personalTodos
            .receive(on: DispatchQueue.main)
            .sink { [weak self] todos in
                self?.personalTodos = todos
                self?.updateTodoMetrics(todos)
            }
            .store(in: &cancellables)
        
        productivityService.$objectives
            .receive(on: DispatchQueue.main)
            .sink { [weak self] objectives in
                self?.objectives = objectives
                self?.updateOKRProgress(objectives)
            }
            .store(in: &cancellables)
        
        productivityService.$isLoading
            .combineLatest(projectTaskService.$isLoading)
            .map { $0 || $1 }
            .receive(on: DispatchQueue.main)
            .assign(to: \.isLoading, on: self)
            .store(in: &cancellables)
        
        productivityService.$errorMessage
            .combineLatest(projectTaskService.$errorMessage)
            .map { $0 ?? $1 }
            .receive(on: DispatchQueue.main)
            .assign(to: \.errorMessage, on: self)
            .store(in: &cancellables)
        
        // Observe project task service changes
        projectTaskService.$projectTasks
            .receive(on: DispatchQueue.main)
            .assign(to: \.projectTasks, on: self)
            .store(in: &cancellables)
        
        // Auto-refresh when search or filters change
        Publishers.CombineLatest($searchText.debounce(for: .milliseconds(300), scheduler: DispatchQueue.main),
                                $selectedFilters)
            .sink { [weak self] _, _ in
                // Filtering happens in computed properties
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Data Management
    
    func refreshAllData() async {
        await productivityService.refreshAllData()
        
        if let selectedBoard = selectedBoard {
            await loadTasksForBoard(selectedBoard.id)
        }
    }
    
    func refreshModule(_ module: ProductivityModule) async {
        switch module {
        case .projects:
            await refreshProjectData()
        case .todos:
            await refreshTodoData()
        case .okrs:
            await refreshOKRData()
        }
    }
    
    private func refreshProjectData() async {
        do {
            let boards = try await productivityService.fetchProjectBoards()
            projectBoards = boards
            
            if let selectedBoard = selectedBoard {
                await loadTasksForBoard(selectedBoard.id)
            }
        } catch {
            errorMessage = "Failed to refresh project data: \(error.localizedDescription)"
        }
    }
    
    private func refreshTodoData() async {
        do {
            let todos = try await productivityService.fetchPersonalTodos()
            personalTodos = todos
            updateTodoMetrics(todos)
        } catch {
            errorMessage = "Failed to refresh todo data: \(error.localizedDescription)"
        }
    }
    
    private func refreshOKRData() async {
        do {
            let objectives = try await productivityService.fetchObjectives()
            self.objectives = objectives
            updateOKRProgress(objectives)
        } catch {
            errorMessage = "Failed to refresh OKR data: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Project Management Actions
    
    func selectBoard(_ board: ProjectBoard) async {
        selectedBoard = board
        selectedTask = nil
        await loadTasksForBoard(board.id)
    }
    
    func loadTasksForBoard(_ boardId: String) async {
        do {
            let tasks = try await projectTaskService.fetchProjectTasks(boardId: boardId)
            projectTasks = tasks
        } catch {
            errorMessage = "Failed to load tasks: \(error.localizedDescription)"
        }
    }
    
    func createProjectBoard(title: String, description: String, viewType: BoardViewType) async {
        do {
            let board = try await productivityService.createProjectBoard(
                title: title,
                description: description,
                viewType: viewType,
                storeCodes: selectedFilters.storeCodes,
                departments: selectedFilters.departments
            )
            
            // Auto-select new board
            await selectBoard(board)
            showingCreateBoard = false
            
        } catch {
            errorMessage = "Failed to create board: \(error.localizedDescription)"
        }
    }
    
    func updateProjectBoard(_ board: ProjectBoard) async {
        do {
            try await productivityService.updateProjectBoard(board)
        } catch {
            errorMessage = "Failed to update board: \(error.localizedDescription)"
        }
    }
    
    func deleteProjectBoard(_ board: ProjectBoard) async {
        do {
            try await productivityService.deleteProjectBoard(board)
            
            if selectedBoard?.id == board.id {
                selectedBoard = nil
                projectTasks = []
            }
            
        } catch {
            errorMessage = "Failed to delete board: \(error.localizedDescription)"
        }
    }
    
    func createProjectTask(
        title: String,
        description: String,
        assignedUserIds: [String] = [],
        priority: TaskPriority = .medium,
        dueDate: Date? = nil
    ) async {
        guard let boardId = selectedBoard?.id else { return }
        
        do {
            let task = try await projectTaskService.createProjectTask(
                boardId: boardId,
                title: title,
                description: description,
                assignedUserIds: assignedUserIds,
                priority: priority,
                dueDate: dueDate,
                storeCodes: selectedFilters.storeCodes,
                departments: selectedFilters.departments
            )
            
            // Task automatically added to projectTasks via service observation
            showingCreateTask = false
            
        } catch {
            errorMessage = "Failed to create task: \(error.localizedDescription)"
        }
    }
    
    func updateProjectTask(_ task: ProjectTask) async {
        do {
            try await projectTaskService.updateProjectTask(task)
        } catch {
            errorMessage = "Failed to update task: \(error.localizedDescription)"
        }
    }
    
    func deleteProjectTask(_ task: ProjectTask) async {
        do {
            try await projectTaskService.deleteProjectTask(task)
            
            if selectedTask?.id == task.id {
                selectedTask = nil
            }
            
        } catch {
            errorMessage = "Failed to delete task: \(error.localizedDescription)"
        }
    }
    
    func toggleTaskCompletion(_ task: ProjectTask) async {
        let newStatus: TaskStatus = task.status == .completed ? .todo : .completed
        let updatedTask = task.with(
            status: newStatus,
            completedAt: newStatus == .completed ? Date() : nil
        )
        
        await updateProjectTask(updatedTask)
    }
    
    // MARK: - Personal To-Do Actions
    
    func createPersonalTodo(
        title: String,
        notes: String = "",
        dueDate: Date? = nil,
        priority: TodoPriority = .medium,
        recurringPattern: RecurringPattern? = nil
    ) async {
        do {
            let todo = try await productivityService.createPersonalTodo(
                title: title,
                notes: notes,
                dueDate: dueDate,
                priority: priority,
                recurringPattern: recurringPattern
            )
            
            showingCreateTodo = false
            
        } catch {
            errorMessage = "Failed to create todo: \(error.localizedDescription)"
        }
    }
    
    func toggleTodoCompletion(_ todo: PersonalTodo) async {
        do {
            try await productivityService.toggleTodoCompletion(todo)
        } catch {
            errorMessage = "Failed to update todo: \(error.localizedDescription)"
        }
    }
    
    func linkTodoToProject(todoId: String, projectTaskId: String) async {
        do {
            try await productivityService.linkTodoToProject(todoId: todoId, projectTaskId: projectTaskId)
        } catch {
            errorMessage = "Failed to link todo to project: \(error.localizedDescription)"
        }
    }
    
    // MARK: - OKR Actions
    
    func createObjective(
        title: String,
        description: String,
        level: OKRLevel,
        scope: String = "",
        quarterYear: String
    ) async {
        do {
            let objective = try await productivityService.createObjective(
                title: title,
                description: description,
                level: level,
                scope: scope,
                quarterYear: quarterYear
            )
            
            showingCreateObjective = false
            
        } catch {
            errorMessage = "Failed to create objective: \(error.localizedDescription)"
        }
    }
    
    func updateObjectiveProgress(_ objective: Objective) async {
        do {
            try await productivityService.updateObjectiveProgress(objective)
        } catch {
            errorMessage = "Failed to update objective progress: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Filtering and Search
    
    private func filterProjectBoards(_ boards: [ProjectBoard]) -> [ProjectBoard] {
        var filtered = boards
        
        // Search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { board in
                board.title.localizedCaseInsensitiveContains(searchText) ||
                board.description.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Store filter
        if !selectedFilters.storeCodes.isEmpty {
            filtered = filtered.filter { board in
                !Set(board.storeCodes).isDisjoint(with: Set(selectedFilters.storeCodes))
            }
        }
        
        // Department filter
        if !selectedFilters.departments.isEmpty {
            filtered = filtered.filter { board in
                !Set(board.departments).isDisjoint(with: Set(selectedFilters.departments))
            }
        }
        
        return filtered
    }
    
    private func filterProjectTasks(_ tasks: [ProjectTask]) -> [ProjectTask] {
        var filtered = tasks
        
        // Search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { task in
                task.title.localizedCaseInsensitiveContains(searchText) ||
                task.description.localizedCaseInsensitiveContains(searchText) ||
                task.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        // Status filter
        if !selectedFilters.taskStatuses.isEmpty {
            filtered = filtered.filter { task in
                selectedFilters.taskStatuses.contains(task.status)
            }
        }
        
        // Priority filter
        if !selectedFilters.taskPriorities.isEmpty {
            filtered = filtered.filter { task in
                selectedFilters.taskPriorities.contains(task.priority)
            }
        }
        
        // Assignment filter
        if selectedFilters.showOnlyAssignedToMe {
            filtered = filtered.filter { task in
                task.assignedUserIds.contains(currentUser.id)
            }
        }
        
        // Due date filter
        if let dateRange = selectedFilters.dueDateRange {
            filtered = filtered.filter { task in
                guard let dueDate = task.dueDate else { return false }
                return dateRange.contains(dueDate)
            }
        }
        
        return filtered
    }
    
    private func filterPersonalTodos(_ todos: [PersonalTodo]) -> [PersonalTodo] {
        var filtered = todos
        
        // Search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { todo in
                todo.title.localizedCaseInsensitiveContains(searchText) ||
                todo.notes.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Completion filter
        if selectedFilters.hideCompletedTodos {
            filtered = filtered.filter { !$0.isCompleted }
        }
        
        // Priority filter
        if !selectedFilters.todoPriorities.isEmpty {
            filtered = filtered.filter { todo in
                selectedFilters.todoPriorities.contains(todo.priority)
            }
        }
        
        // Due date filter
        if let dateRange = selectedFilters.dueDateRange {
            filtered = filtered.filter { todo in
                guard let dueDate = todo.dueDate else { return false }
                return dateRange.contains(dueDate)
            }
        }
        
        return filtered
    }
    
    private func filterObjectives(_ objectives: [Objective]) -> [Objective] {
        var filtered = objectives
        
        // Search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { objective in
                objective.title.localizedCaseInsensitiveContains(searchText) ||
                objective.description.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Level filter
        if !selectedFilters.okrLevels.isEmpty {
            filtered = filtered.filter { objective in
                selectedFilters.okrLevels.contains(objective.level)
            }
        }
        
        // Status filter
        if !selectedFilters.okrStatuses.isEmpty {
            filtered = filtered.filter { objective in
                selectedFilters.okrStatuses.contains(objective.status)
            }
        }
        
        // Quarter filter
        if !selectedFilters.quarters.isEmpty {
            filtered = filtered.filter { objective in
                selectedFilters.quarters.contains(objective.quarterYear)
            }
        }
        
        return filtered
    }
    
    // MARK: - Metrics Calculation
    
    private func updateTodoMetrics(_ todos: [PersonalTodo]) {
        let completedCount = todos.filter { $0.isCompleted }.count
        todoCompletionRate = todos.isEmpty ? 0.0 : Double(completedCount) / Double(todos.count)
        
        // Calculate overdue todos
        let now = Date()
        overdueTodos = todos.filter { todo in
            !todo.isCompleted && 
            todo.dueDate != nil && 
            todo.dueDate! < now
        }
    }
    
    private func updateOKRProgress(_ objectives: [Objective]) {
        let activeObjectives = objectives.filter { $0.status == .active || $0.status == .onTrack }
        
        let averageProgress = activeObjectives.isEmpty ? 0.0 :
            activeObjectives.reduce(0.0) { $0 + $1.progressPercentage } / Double(activeObjectives.count)
        
        let onTrackCount = objectives.filter { $0.status == .onTrack }.count
        let atRiskCount = objectives.filter { $0.status == .atRisk }.count
        
        okrProgress = OKRProgress(
            averageProgress: averageProgress,
            totalObjectives: objectives.count,
            activeObjectives: activeObjectives.count,
            onTrackCount: onTrackCount,
            atRiskCount: atRiskCount
        )
    }
    
    // MARK: - Export and Reporting
    
    func exportProductivityData(format: ExportFormat, dateRange: DateInterval?) async -> URL? {
        do {
            // Implement comprehensive export logic
            let exporter = ProductivityExporter()
            
            switch selectedModule {
            case .projects:
                return try await exporter.exportProjects(
                    boards: filteredProjectBoards,
                    tasks: filteredProjectTasks,
                    format: format,
                    dateRange: dateRange
                )
            case .todos:
                return try await exporter.exportTodos(
                    todos: filteredPersonalTodos,
                    format: format,
                    dateRange: dateRange
                )
            case .okrs:
                return try await exporter.exportOKRs(
                    objectives: filteredObjectives,
                    format: format,
                    dateRange: dateRange
                )
            }
            
        } catch {
            errorMessage = "Failed to export data: \(error.localizedDescription)"
            return nil
        }
    }
    
    // MARK: - Utility Methods
    
    func clearError() {
        errorMessage = nil
    }
    
    func resetFilters() {
        selectedFilters = ProductivityFilters()
        searchText = ""
    }
    
    func canUserCreateBoard() -> Bool {
        return ["Admin", "AreaDirector", "StoreDirector", "DepartmentHead"].contains(currentUser.role.rawValue)
    }
    
    func canUserAssignTasks() -> Bool {
        return ["Admin", "AreaDirector", "StoreDirector", "DepartmentHead", "Agent"].contains(currentUser.role.rawValue)
    }
    
    func canUserCreateObjectives(level: OKRLevel) -> Bool {
        switch level {
        case .company:
            return ["Admin", "AreaDirector"].contains(currentUser.role.rawValue)
        case .store:
            return ["Admin", "AreaDirector", "StoreDirector"].contains(currentUser.role.rawValue)
        case .individual:
            return true // All users can create individual objectives
        }
    }
}

// MARK: - Supporting Types

enum ProductivityModule: String, CaseIterable {
    case projects = "Projects"
    case todos = "To-Dos"
    case okrs = "OKRs"
    
    var systemImage: String {
        switch self {
        case .projects: return "square.stack.3d.up"
        case .todos: return "checklist"
        case .okrs: return "target"
        }
    }
}

struct ProductivityFilters {
    var storeCodes: [String] = []
    var departments: [String] = []
    var taskStatuses: [TaskStatus] = []
    var taskPriorities: [TaskPriority] = []
    var todoPriorities: [TodoPriority] = []
    var okrLevels: [OKRLevel] = []
    var okrStatuses: [OKRStatus] = []
    var quarters: [String] = []
    var dueDateRange: DateInterval?
    var showOnlyAssignedToMe = false
    var hideCompletedTodos = false
}

struct OKRProgress {
    let averageProgress: Double
    let totalObjectives: Int
    let activeObjectives: Int
    let onTrackCount: Int
    let atRiskCount: Int
    
    init(
        averageProgress: Double = 0.0,
        totalObjectives: Int = 0,
        activeObjectives: Int = 0,
        onTrackCount: Int = 0,
        atRiskCount: Int = 0
    ) {
        self.averageProgress = averageProgress
        self.totalObjectives = totalObjectives
        self.activeObjectives = activeObjectives
        self.onTrackCount = onTrackCount
        self.atRiskCount = atRiskCount
    }
}

enum ExportFormat: String, CaseIterable {
    case csv = "CSV"
    case json = "JSON"
    case pdf = "PDF"
    
    var fileExtension: String {
        switch self {
        case .csv: return "csv"
        case .json: return "json"
        case .pdf: return "pdf"
        }
    }
}

// MARK: - Productivity Exporter (Placeholder)

class ProductivityExporter {
    func exportProjects(boards: [ProjectBoard], tasks: [ProjectTask], format: ExportFormat, dateRange: DateInterval?) async throws -> URL? {
        // Implementation would create export file
        // Return temporary file URL
        return nil
    }
    
    func exportTodos(todos: [PersonalTodo], format: ExportFormat, dateRange: DateInterval?) async throws -> URL? {
        // Implementation would create export file
        return nil
    }
    
    func exportOKRs(objectives: [Objective], format: ExportFormat, dateRange: DateInterval?) async throws -> URL? {
        // Implementation would create export file
        return nil
    }
}
