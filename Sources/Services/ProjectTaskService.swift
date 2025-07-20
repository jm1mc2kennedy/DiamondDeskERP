import Foundation
import CloudKit
import Apollo
import Combine

/// Service for managing ProjectTask operations with enhanced features:
/// - Checklist support with individual item completion
/// - Task dependencies and prerequisite management
/// - Time tracking with estimates and actual time
/// - Advanced filtering and assignment capabilities
@MainActor
final class ProjectTaskService: ObservableService {
    
    // MARK: - Published Properties
    @Published var projectTasks: [ProjectTask] = []
    @Published var checklistItems: [String: [ChecklistItem]] = [:] // TaskId -> Items
    @Published var taskDependencies: [String: [TaskDependency]] = [:] // TaskId -> Dependencies
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private let cloudKitService: CloudKitService
    private let apolloClient: ApolloClient
    private let currentUser: User
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(cloudKitService: CloudKitService, apolloClient: ApolloClient, currentUser: User) {
        self.cloudKitService = cloudKitService
        self.apolloClient = apolloClient
        self.currentUser = currentUser
        setupSubscriptions()
    }
    
    // MARK: - Subscription Management
    private func setupSubscriptions() {
        NotificationCenter.default.publisher(for: .CKAccountChanged)
            .sink { [weak self] _ in
                Task { await self?.refreshTasks() }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Data Refresh
    func refreshTasks() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let tasks = try await fetchProjectTasks()
            self.projectTasks = tasks
            
            // Load associated checklist items and dependencies
            await loadTaskMetadata(for: tasks)
            
            self.errorMessage = nil
            
        } catch {
            self.errorMessage = "Failed to refresh project tasks: \(error.localizedDescription)"
            LoggingService.shared.logError("ProjectTaskService.refreshTasks", error: error)
        }
    }
    
    /// Load checklist items and dependencies for tasks
    private func loadTaskMetadata(for tasks: [ProjectTask]) async {
        await withTaskGroup(of: Void.self) { group in
            for task in tasks {
                group.addTask { [weak self] in
                    await self?.loadChecklistItems(for: task.id)
                    await self?.loadTaskDependencies(for: task.id)
                }
            }
        }
    }
    
    // MARK: - Task CRUD Operations
    
    /// Fetch project tasks with advanced filtering
    func fetchProjectTasks(
        boardId: String? = nil,
        assignedToUser: String? = nil,
        status: TaskStatus? = nil,
        priority: TaskPriority? = nil,
        storeCodes: [String] = [],
        departments: [String] = []
    ) async throws -> [ProjectTask] {
        
        var predicates: [NSPredicate] = []
        
        // Board filter
        if let boardId = boardId {
            predicates.append(NSPredicate(format: "boardId == %@", boardId))
        }
        
        // Assignment filter
        if let userId = assignedToUser {
            predicates.append(NSPredicate(format: "assignedUserIds CONTAINS %@", userId))
        } else {
            // Default: tasks assigned to current user or in their stores/departments
            var userPredicates: [NSPredicate] = []
            
            // Assigned to user
            userPredicates.append(NSPredicate(format: "assignedUserIds CONTAINS %@", currentUser.id))
            
            // In user's stores
            if !currentUser.storeCodes.isEmpty {
                userPredicates.append(NSPredicate(format: "ANY storeCodes IN %@", currentUser.storeCodes))
            }
            
            // In user's departments
            if !currentUser.departments.isEmpty {
                userPredicates.append(NSPredicate(format: "ANY departments IN %@", currentUser.departments))
            }
            
            if !userPredicates.isEmpty {
                predicates.append(NSCompoundPredicate(orPredicateWithSubpredicates: userPredicates))
            }
        }
        
        // Status filter
        if let status = status {
            predicates.append(NSPredicate(format: "status == %@", status.rawValue))
        }
        
        // Priority filter
        if let priority = priority {
            predicates.append(NSPredicate(format: "priority == %@", priority.rawValue))
        }
        
        // Store codes filter
        if !storeCodes.isEmpty {
            predicates.append(NSPredicate(format: "ANY storeCodes IN %@", storeCodes))
        }
        
        // Departments filter
        if !departments.isEmpty {
            predicates.append(NSPredicate(format: "ANY departments IN %@", departments))
        }
        
        let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        
        let query = CKQuery(recordType: "ProjectTask", predicate: compoundPredicate)
        query.sortDescriptors = [
            NSSortDescriptor(key: "priority", ascending: false),
            NSSortDescriptor(key: "dueDate", ascending: true),
            NSSortDescriptor(key: "createdAt", ascending: false)
        ]
        
        let (results, _) = try await cloudKitService.publicDatabase.records(matching: query)
        
        return results.compactMap { result in
            switch result {
            case .success(let record):
                return ProjectTask.from(record: record)
            case .failure(let error):
                LoggingService.shared.logError("ProjectTask fetch failed", error: error)
                return nil
            }
        }
    }
    
    /// Create new project task
    func createProjectTask(
        boardId: String,
        title: String,
        description: String = "",
        assignedUserIds: [String] = [],
        status: TaskStatus = .todo,
        priority: TaskPriority = .medium,
        dueDate: Date? = nil,
        estimatedHours: Double = 0,
        tags: [String] = [],
        storeCodes: [String] = [],
        departments: [String] = []
    ) async throws -> ProjectTask {
        
        let taskId = UUID().uuidString
        let record = CKRecord(recordType: "ProjectTask", recordID: CKRecord.ID(recordName: taskId))
        
        // Core fields
        record["id"] = taskId
        record["boardId"] = boardId
        record["title"] = title
        record["description"] = description
        record["status"] = status.rawValue
        record["priority"] = priority.rawValue
        record["createdAt"] = Date()
        record["updatedAt"] = Date()
        record["createdByUserId"] = currentUser.id
        
        // Assignment fields
        record["assignedUserIds"] = assignedUserIds
        
        // Optional fields
        if let dueDate = dueDate {
            record["dueDate"] = dueDate
        }
        
        // Time tracking
        record["estimatedHours"] = estimatedHours
        record["actualHours"] = 0.0
        
        // Categorization
        record["tags"] = tags
        record["storeCodes"] = storeCodes
        record["departments"] = departments
        
        // Progress tracking
        record["progressPercentage"] = 0.0
        record["checklistCompletionPercentage"] = 0.0
        
        // Dependencies (empty initially)
        record["prerequisiteTaskIds"] = []
        record["dependentTaskIds"] = []
        
        let savedRecord = try await cloudKitService.publicDatabase.save(record)
        
        guard let task = ProjectTask.from(record: savedRecord) else {
            throw ServiceError.dataConversionFailed
        }
        
        // Update local state
        projectTasks.insert(task, at: 0)
        
        // Send notifications to assigned users
        await NotificationService.shared.sendTaskAssignmentNotifications(
            task: task,
            assignedUserIds: assignedUserIds
        )
        
        LoggingService.shared.logInfo("Created project task", metadata: [
            "taskId": taskId,
            "boardId": boardId,
            "title": title,
            "assignedCount": assignedUserIds.count
        ])
        
        return task
    }
    
    /// Update project task
    func updateProjectTask(_ task: ProjectTask) async throws {
        let recordID = CKRecord.ID(recordName: task.id)
        
        do {
            let record = try await cloudKitService.publicDatabase.record(for: recordID)
            
            // Update fields
            record["title"] = task.title
            record["description"] = task.description
            record["status"] = task.status.rawValue
            record["priority"] = task.priority.rawValue
            record["updatedAt"] = Date()
            record["assignedUserIds"] = task.assignedUserIds
            record["estimatedHours"] = task.estimatedHours
            record["actualHours"] = task.actualHours
            record["tags"] = task.tags
            record["storeCodes"] = task.storeCodes
            record["departments"] = task.departments
            record["progressPercentage"] = task.progressPercentage
            
            if let dueDate = task.dueDate {
                record["dueDate"] = dueDate
            } else {
                record["dueDate"] = nil
            }
            
            if let completedAt = task.completedAt {
                record["completedAt"] = completedAt
            }
            
            let savedRecord = try await cloudKitService.publicDatabase.save(record)
            
            // Update local state
            if let index = projectTasks.firstIndex(where: { $0.id == task.id }),
               let updatedTask = ProjectTask.from(record: savedRecord) {
                projectTasks[index] = updatedTask
            }
            
            LoggingService.shared.logInfo("Updated project task", metadata: ["taskId": task.id])
            
        } catch {
            throw ServiceError.updateFailed(error.localizedDescription)
        }
    }
    
    /// Delete project task and associated data
    func deleteProjectTask(_ task: ProjectTask) async throws {
        let recordID = CKRecord.ID(recordName: task.id)
        
        do {
            // Delete associated checklist items first
            await deleteChecklistItems(for: task.id)
            
            // Delete task dependencies
            await deleteTaskDependencies(for: task.id)
            
            // Delete the main task record
            try await cloudKitService.publicDatabase.deleteRecord(withID: recordID)
            
            // Update local state
            projectTasks.removeAll { $0.id == task.id }
            checklistItems.removeValue(forKey: task.id)
            taskDependencies.removeValue(forKey: task.id)
            
            LoggingService.shared.logInfo("Deleted project task", metadata: ["taskId": task.id])
            
        } catch {
            throw ServiceError.deleteFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Checklist Management
    
    /// Load checklist items for a task
    func loadChecklistItems(for taskId: String) async {
        do {
            let predicate = NSPredicate(format: "taskId == %@", taskId)
            let query = CKQuery(recordType: "ChecklistItem", predicate: predicate)
            query.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true)]
            
            let (results, _) = try await cloudKitService.publicDatabase.records(matching: query)
            
            let items = results.compactMap { result in
                switch result {
                case .success(let record):
                    return ChecklistItem.from(record: record)
                case .failure:
                    return nil
                }
            }
            
            checklistItems[taskId] = items
            
            // Update task completion percentage
            await updateChecklistCompletion(for: taskId, items: items)
            
        } catch {
            LoggingService.shared.logError("Failed to load checklist items", error: error)
        }
    }
    
    /// Add checklist item to task
    func addChecklistItem(
        to taskId: String,
        title: String,
        description: String = "",
        isRequired: Bool = false
    ) async throws -> ChecklistItem {
        
        let itemId = UUID().uuidString
        let record = CKRecord(recordType: "ChecklistItem", recordID: CKRecord.ID(recordName: itemId))
        
        // Determine order (last item + 1)
        let existingItems = checklistItems[taskId] ?? []
        let order = existingItems.count
        
        record["id"] = itemId
        record["taskId"] = taskId
        record["title"] = title
        record["description"] = description
        record["isCompleted"] = false
        record["isRequired"] = isRequired
        record["order"] = order
        record["createdAt"] = Date()
        record["updatedAt"] = Date()
        record["createdByUserId"] = currentUser.id
        
        let savedRecord = try await cloudKitService.publicDatabase.save(record)
        
        guard let item = ChecklistItem.from(record: savedRecord) else {
            throw ServiceError.dataConversionFailed
        }
        
        // Update local state
        if checklistItems[taskId] == nil {
            checklistItems[taskId] = []
        }
        checklistItems[taskId]?.append(item)
        
        // Recalculate task completion
        await updateChecklistCompletion(for: taskId, items: checklistItems[taskId] ?? [])
        
        return item
    }
    
    /// Toggle checklist item completion
    func toggleChecklistItem(_ item: ChecklistItem) async throws {
        let recordID = CKRecord.ID(recordName: item.id)
        
        do {
            let record = try await cloudKitService.publicDatabase.record(for: recordID)
            let newCompletionStatus = !item.isCompleted
            
            record["isCompleted"] = newCompletionStatus
            record["updatedAt"] = Date()
            
            if newCompletionStatus {
                record["completedAt"] = Date()
                record["completedByUserId"] = currentUser.id
            } else {
                record["completedAt"] = nil
                record["completedByUserId"] = nil
            }
            
            let savedRecord = try await cloudKitService.publicDatabase.save(record)
            
            // Update local state
            if var items = checklistItems[item.taskId],
               let index = items.firstIndex(where: { $0.id == item.id }),
               let updatedItem = ChecklistItem.from(record: savedRecord) {
                items[index] = updatedItem
                checklistItems[item.taskId] = items
                
                // Recalculate task completion
                await updateChecklistCompletion(for: item.taskId, items: items)
            }
            
        } catch {
            throw ServiceError.updateFailed(error.localizedDescription)
        }
    }
    
    /// Update task checklist completion percentage
    private func updateChecklistCompletion(for taskId: String, items: [ChecklistItem]) async {
        guard !items.isEmpty else { return }
        
        let completedCount = items.filter { $0.isCompleted }.count
        let completionPercentage = Double(completedCount) / Double(items.count) * 100.0
        
        do {
            let recordID = CKRecord.ID(recordName: taskId)
            let record = try await cloudKitService.publicDatabase.record(for: recordID)
            
            record["checklistCompletionPercentage"] = completionPercentage
            record["updatedAt"] = Date()
            
            try await cloudKitService.publicDatabase.save(record)
            
            // Update local task state
            if let index = projectTasks.firstIndex(where: { $0.id == taskId }) {
                projectTasks[index] = projectTasks[index].with(checklistCompletionPercentage: completionPercentage)
            }
            
        } catch {
            LoggingService.shared.logError("Failed to update checklist completion", error: error)
        }
    }
    
    /// Delete all checklist items for a task
    private func deleteChecklistItems(for taskId: String) async {
        guard let items = checklistItems[taskId] else { return }
        
        await withTaskGroup(of: Void.self) { group in
            for item in items {
                group.addTask { [weak self] in
                    do {
                        let recordID = CKRecord.ID(recordName: item.id)
                        try await self?.cloudKitService.publicDatabase.deleteRecord(withID: recordID)
                    } catch {
                        LoggingService.shared.logError("Failed to delete checklist item", error: error)
                    }
                }
            }
        }
    }
    
    // MARK: - Task Dependencies
    
    /// Load task dependencies
    func loadTaskDependencies(for taskId: String) async {
        do {
            let predicate = NSPredicate(format: "dependentTaskId == %@ OR prerequisiteTaskId == %@", taskId, taskId)
            let query = CKQuery(recordType: "TaskDependency", predicate: predicate)
            
            let (results, _) = try await cloudKitService.publicDatabase.records(matching: query)
            
            let dependencies = results.compactMap { result in
                switch result {
                case .success(let record):
                    return TaskDependency.from(record: record)
                case .failure:
                    return nil
                }
            }
            
            taskDependencies[taskId] = dependencies
            
        } catch {
            LoggingService.shared.logError("Failed to load task dependencies", error: error)
        }
    }
    
    /// Add task dependency (prerequisite -> dependent)
    func addTaskDependency(
        prerequisiteTaskId: String,
        dependentTaskId: String,
        type: DependencyType = .finishToStart
    ) async throws -> TaskDependency {
        
        // Validate dependency doesn't create a cycle
        if await wouldCreateCycle(prerequisite: prerequisiteTaskId, dependent: dependentTaskId) {
            throw ServiceError.circularDependency
        }
        
        let dependencyId = UUID().uuidString
        let record = CKRecord(recordType: "TaskDependency", recordID: CKRecord.ID(recordName: dependencyId))
        
        record["id"] = dependencyId
        record["prerequisiteTaskId"] = prerequisiteTaskId
        record["dependentTaskId"] = dependentTaskId
        record["dependencyType"] = type.rawValue
        record["createdAt"] = Date()
        record["createdByUserId"] = currentUser.id
        
        let savedRecord = try await cloudKitService.publicDatabase.save(record)
        
        guard let dependency = TaskDependency.from(record: savedRecord) else {
            throw ServiceError.dataConversionFailed
        }
        
        // Update local state for both tasks
        if taskDependencies[prerequisiteTaskId] == nil {
            taskDependencies[prerequisiteTaskId] = []
        }
        if taskDependencies[dependentTaskId] == nil {
            taskDependencies[dependentTaskId] = []
        }
        
        taskDependencies[prerequisiteTaskId]?.append(dependency)
        taskDependencies[dependentTaskId]?.append(dependency)
        
        return dependency
    }
    
    /// Check if adding dependency would create a cycle
    private func wouldCreateCycle(prerequisite: String, dependent: String) async -> Bool {
        // Simple cycle detection: check if prerequisite depends on dependent (directly or indirectly)
        var visited = Set<String>()
        var stack = [prerequisite]
        
        while !stack.isEmpty {
            let current = stack.removeFirst()
            
            if current == dependent {
                return true
            }
            
            if visited.contains(current) {
                continue
            }
            visited.insert(current)
            
            // Add all tasks that depend on current task
            if let dependencies = taskDependencies[current] {
                for dep in dependencies where dep.prerequisiteTaskId == current {
                    stack.append(dep.dependentTaskId)
                }
            }
        }
        
        return false
    }
    
    /// Delete task dependencies
    private func deleteTaskDependencies(for taskId: String) async {
        guard let dependencies = taskDependencies[taskId] else { return }
        
        await withTaskGroup(of: Void.self) { group in
            for dependency in dependencies {
                group.addTask { [weak self] in
                    do {
                        let recordID = CKRecord.ID(recordName: dependency.id)
                        try await self?.cloudKitService.publicDatabase.deleteRecord(withID: recordID)
                    } catch {
                        LoggingService.shared.logError("Failed to delete task dependency", error: error)
                    }
                }
            }
        }
    }
    
    // MARK: - Time Tracking
    
    /// Log time spent on task
    func logTimeSpent(taskId: String, hours: Double, description: String = "") async throws {
        // Update task's actual hours
        guard let taskIndex = projectTasks.firstIndex(where: { $0.id == taskId }) else {
            throw ServiceError.taskNotFound
        }
        
        let task = projectTasks[taskIndex]
        let newActualHours = task.actualHours + hours
        
        let recordID = CKRecord.ID(recordName: taskId)
        
        do {
            let record = try await cloudKitService.publicDatabase.record(for: recordID)
            record["actualHours"] = newActualHours
            record["updatedAt"] = Date()
            
            try await cloudKitService.publicDatabase.save(record)
            
            // Update local state
            projectTasks[taskIndex] = task.with(actualHours: newActualHours)
            
            // Log time entry for detailed tracking
            await createTimeEntry(taskId: taskId, hours: hours, description: description)
            
        } catch {
            throw ServiceError.updateFailed(error.localizedDescription)
        }
    }
    
    /// Create detailed time entry record
    private func createTimeEntry(taskId: String, hours: Double, description: String) async {
        do {
            let entryId = UUID().uuidString
            let record = CKRecord(recordType: "TimeEntry", recordID: CKRecord.ID(recordName: entryId))
            
            record["id"] = entryId
            record["taskId"] = taskId
            record["userId"] = currentUser.id
            record["hours"] = hours
            record["description"] = description
            record["loggedAt"] = Date()
            
            try await cloudKitService.publicDatabase.save(record)
            
        } catch {
            LoggingService.shared.logError("Failed to create time entry", error: error)
        }
    }
    
    // MARK: - Batch Operations
    
    /// Assign multiple tasks to user
    func assignTasks(_ taskIds: [String], to userId: String) async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            for taskId in taskIds {
                group.addTask { [weak self] in
                    guard let self = self,
                          let taskIndex = self.projectTasks.firstIndex(where: { $0.id == taskId }) else {
                        return
                    }
                    
                    let task = self.projectTasks[taskIndex]
                    var updatedAssignees = task.assignedUserIds
                    
                    if !updatedAssignees.contains(userId) {
                        updatedAssignees.append(userId)
                        
                        let updatedTask = task.with(assignedUserIds: updatedAssignees)
                        try await self.updateProjectTask(updatedTask)
                    }
                }
            }
        }
    }
    
    /// Update multiple task statuses
    func updateTaskStatuses(_ taskIds: [String], to status: TaskStatus) async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            for taskId in taskIds {
                group.addTask { [weak self] in
                    guard let self = self,
                          let taskIndex = self.projectTasks.firstIndex(where: { $0.id == taskId }) else {
                        return
                    }
                    
                    let task = self.projectTasks[taskIndex]
                    let updatedTask = task.with(status: status)
                    try await self.updateProjectTask(updatedTask)
                }
            }
        }
    }
}

// MARK: - Service Error Extensions

extension ServiceError {
    static let circularDependency = ServiceError.customError("Adding this dependency would create a circular reference")
    static let taskNotFound = ServiceError.customError("Task not found")
    
    case customError(String)
    
    var errorDescription: String? {
        switch self {
        case .customError(let message):
            return message
        default:
            return nil
        }
    }
}

// MARK: - Model Extensions

extension ProjectTask {
    func with(
        title: String? = nil,
        description: String? = nil,
        status: TaskStatus? = nil,
        priority: TaskPriority? = nil,
        assignedUserIds: [String]? = nil,
        dueDate: Date? = nil,
        estimatedHours: Double? = nil,
        actualHours: Double? = nil,
        tags: [String]? = nil,
        storeCodes: [String]? = nil,
        departments: [String]? = nil,
        progressPercentage: Double? = nil,
        checklistCompletionPercentage: Double? = nil,
        completedAt: Date? = nil
    ) -> ProjectTask {
        return ProjectTask(
            id: self.id,
            boardId: self.boardId,
            title: title ?? self.title,
            description: description ?? self.description,
            status: status ?? self.status,
            priority: priority ?? self.priority,
            assignedUserIds: assignedUserIds ?? self.assignedUserIds,
            dueDate: dueDate ?? self.dueDate,
            estimatedHours: estimatedHours ?? self.estimatedHours,
            actualHours: actualHours ?? self.actualHours,
            tags: tags ?? self.tags,
            storeCodes: storeCodes ?? self.storeCodes,
            departments: departments ?? self.departments,
            progressPercentage: progressPercentage ?? self.progressPercentage,
            checklistCompletionPercentage: checklistCompletionPercentage ?? self.checklistCompletionPercentage,
            prerequisiteTaskIds: self.prerequisiteTaskIds,
            dependentTaskIds: self.dependentTaskIds,
            attachmentIds: self.attachmentIds,
            createdByUserId: self.createdByUserId,
            createdAt: self.createdAt,
            updatedAt: Date(),
            completedAt: completedAt ?? self.completedAt
        )
    }
}

extension ChecklistItem {
    static func from(record: CKRecord) -> ChecklistItem? {
        guard let id = record["id"] as? String,
              let taskId = record["taskId"] as? String,
              let title = record["title"] as? String,
              let isCompleted = record["isCompleted"] as? Bool,
              let isRequired = record["isRequired"] as? Bool,
              let order = record["order"] as? Int,
              let createdAt = record["createdAt"] as? Date,
              let updatedAt = record["updatedAt"] as? Date,
              let createdByUserId = record["createdByUserId"] as? String else {
            return nil
        }
        
        let description = record["description"] as? String ?? ""
        let completedAt = record["completedAt"] as? Date
        let completedByUserId = record["completedByUserId"] as? String
        
        return ChecklistItem(
            id: id,
            taskId: taskId,
            title: title,
            description: description,
            isCompleted: isCompleted,
            isRequired: isRequired,
            order: order,
            createdByUserId: createdByUserId,
            completedByUserId: completedByUserId,
            createdAt: createdAt,
            updatedAt: updatedAt,
            completedAt: completedAt
        )
    }
}

extension TaskDependency {
    static func from(record: CKRecord) -> TaskDependency? {
        guard let id = record["id"] as? String,
              let prerequisiteTaskId = record["prerequisiteTaskId"] as? String,
              let dependentTaskId = record["dependentTaskId"] as? String,
              let typeRaw = record["dependencyType"] as? String,
              let dependencyType = DependencyType(rawValue: typeRaw),
              let createdAt = record["createdAt"] as? Date,
              let createdByUserId = record["createdByUserId"] as? String else {
            return nil
        }
        
        return TaskDependency(
            id: id,
            prerequisiteTaskId: prerequisiteTaskId,
            dependentTaskId: dependentTaskId,
            dependencyType: dependencyType,
            createdByUserId: createdByUserId,
            createdAt: createdAt
        )
    }
}

extension ProjectTask {
    static func from(record: CKRecord) -> ProjectTask? {
        guard let id = record["id"] as? String,
              let boardId = record["boardId"] as? String,
              let title = record["title"] as? String,
              let description = record["description"] as? String,
              let statusRaw = record["status"] as? String,
              let status = TaskStatus(rawValue: statusRaw),
              let priorityRaw = record["priority"] as? String,
              let priority = TaskPriority(rawValue: priorityRaw),
              let createdAt = record["createdAt"] as? Date,
              let updatedAt = record["updatedAt"] as? Date,
              let createdByUserId = record["createdByUserId"] as? String else {
            return nil
        }
        
        let assignedUserIds = record["assignedUserIds"] as? [String] ?? []
        let dueDate = record["dueDate"] as? Date
        let estimatedHours = record["estimatedHours"] as? Double ?? 0.0
        let actualHours = record["actualHours"] as? Double ?? 0.0
        let tags = record["tags"] as? [String] ?? []
        let storeCodes = record["storeCodes"] as? [String] ?? []
        let departments = record["departments"] as? [String] ?? []
        let progressPercentage = record["progressPercentage"] as? Double ?? 0.0
        let checklistCompletionPercentage = record["checklistCompletionPercentage"] as? Double ?? 0.0
        let prerequisiteTaskIds = record["prerequisiteTaskIds"] as? [String] ?? []
        let dependentTaskIds = record["dependentTaskIds"] as? [String] ?? []
        let attachmentIds = record["attachmentIds"] as? [String] ?? []
        let completedAt = record["completedAt"] as? Date
        
        return ProjectTask(
            id: id,
            boardId: boardId,
            title: title,
            description: description,
            status: status,
            priority: priority,
            assignedUserIds: assignedUserIds,
            dueDate: dueDate,
            estimatedHours: estimatedHours,
            actualHours: actualHours,
            tags: tags,
            storeCodes: storeCodes,
            departments: departments,
            progressPercentage: progressPercentage,
            checklistCompletionPercentage: checklistCompletionPercentage,
            prerequisiteTaskIds: prerequisiteTaskIds,
            dependentTaskIds: dependentTaskIds,
            attachmentIds: attachmentIds,
            createdByUserId: createdByUserId,
            createdAt: createdAt,
            updatedAt: updatedAt,
            completedAt: completedAt
        )
    }
}

// MARK: - Supporting Protocols

protocol ObservableService: ObservableObject {
    var isLoading: Bool { get set }
    var errorMessage: String? { get set }
}
