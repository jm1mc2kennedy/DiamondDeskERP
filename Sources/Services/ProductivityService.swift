import Foundation
import CloudKit
import Apollo
import Combine

/// Comprehensive service orchestrating all three productivity modules:
/// - Project Management (Monday.com-style boards with multiple views)
/// - Personal To-Dos (lightweight personal task system)
/// - OKRs (Objectives & Key Results for strategic alignment)
@MainActor
final class ProductivityService: ObservableObject {
    
    // MARK: - Published Properties
    @Published var projectBoards: [ProjectBoard] = []
    @Published var personalTodos: [PersonalTodo] = []
    @Published var objectives: [Objective] = []
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
        // Subscribe to CloudKit push notifications for real-time updates
        NotificationCenter.default.publisher(for: .CKAccountChanged)
            .sink { [weak self] _ in
                Task { await self?.refreshAllData() }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Data Refresh
    func refreshAllData() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            async let boards = fetchProjectBoards()
            async let todos = fetchPersonalTodos()
            async let okrs = fetchObjectives()
            
            let (fetchedBoards, fetchedTodos, fetchedOkrs) = try await (boards, todos, okrs)
            
            self.projectBoards = fetchedBoards
            self.personalTodos = fetchedTodos
            self.objectives = fetchedOkrs
            
            self.errorMessage = nil
            
        } catch {
            self.errorMessage = "Failed to refresh productivity data: \(error.localizedDescription)"
            LoggingService.shared.logError("ProductivityService.refreshAllData", error: error)
        }
    }
    
    // MARK: - Project Management Module
    
    /// Fetch project boards accessible to current user based on permissions
    func fetchProjectBoards() async throws -> [ProjectBoard] {
        let predicate = NSPredicate(format: "ownerUserId == %@ OR editorUserIds CONTAINS %@ OR viewerUserIds CONTAINS %@", 
                                  currentUser.id, currentUser.id, currentUser.id)
        
        let query = CKQuery(recordType: "ProjectBoard", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        
        let (results, _) = try await cloudKitService.publicDatabase.records(matching: query)
        
        return results.compactMap { result in
            switch result {
            case .success(let record):
                return ProjectBoard.from(record: record)
            case .failure(let error):
                LoggingService.shared.logError("ProjectBoard fetch failed", error: error)
                return nil
            }
        }
    }
    
    /// Create new project board with default settings
    func createProjectBoard(
        title: String,
        description: String,
        viewType: BoardViewType = .kanban,
        storeCodes: [String] = [],
        departments: [String] = []
    ) async throws -> ProjectBoard {
        
        let boardId = UUID().uuidString
        let record = CKRecord(recordType: "ProjectBoard", recordID: CKRecord.ID(recordName: boardId))
        
        // Core fields
        record["id"] = boardId
        record["title"] = title
        record["description"] = description
        record["viewType"] = viewType.rawValue
        record["createdAt"] = Date()
        record["updatedAt"] = Date()
        
        // Permission fields
        record["ownerUserId"] = currentUser.id
        record["editorUserIds"] = []
        record["viewerUserIds"] = []
        record["permissionLevel"] = PermissionLevel.owner.rawValue
        
        // Scope fields
        record["storeCodes"] = storeCodes
        record["departments"] = departments
        
        // Custom columns (empty initially)
        record["customColumns"] = try JSONEncoder().encode([CustomColumn]())
        
        let savedRecord = try await cloudKitService.publicDatabase.save(record)
        
        guard let board = ProjectBoard.from(record: savedRecord) else {
            throw ServiceError.dataConversionFailed
        }
        
        // Update local state
        projectBoards.insert(board, at: 0)
        
        LoggingService.shared.logInfo("Created project board", metadata: ["boardId": boardId, "title": title])
        
        return board
    }
    
    /// Update project board properties
    func updateProjectBoard(_ board: ProjectBoard) async throws {
        let recordID = CKRecord.ID(recordName: board.id)
        
        do {
            let record = try await cloudKitService.publicDatabase.record(for: recordID)
            
            // Update fields
            record["title"] = board.title
            record["description"] = board.description
            record["viewType"] = board.viewType.rawValue
            record["updatedAt"] = Date()
            record["storeCodes"] = board.storeCodes
            record["departments"] = board.departments
            record["customColumns"] = try JSONEncoder().encode(board.customColumns)
            
            let savedRecord = try await cloudKitService.publicDatabase.save(record)
            
            // Update local state
            if let index = projectBoards.firstIndex(where: { $0.id == board.id }),
               let updatedBoard = ProjectBoard.from(record: savedRecord) {
                projectBoards[index] = updatedBoard
            }
            
        } catch {
            throw ServiceError.updateFailed(error.localizedDescription)
        }
    }
    
    /// Delete project board (owner only)
    func deleteProjectBoard(_ board: ProjectBoard) async throws {
        guard board.ownerUserId == currentUser.id else {
            throw ServiceError.insufficientPermissions
        }
        
        let recordID = CKRecord.ID(recordName: board.id)
        
        do {
            try await cloudKitService.publicDatabase.deleteRecord(withID: recordID)
            
            // Update local state
            projectBoards.removeAll { $0.id == board.id }
            
            LoggingService.shared.logInfo("Deleted project board", metadata: ["boardId": board.id])
            
        } catch {
            throw ServiceError.deleteFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Personal To-Do Module
    
    /// Fetch personal todos for current user
    func fetchPersonalTodos() async throws -> [PersonalTodo] {
        let predicate = NSPredicate(format: "userId == %@", currentUser.id)
        
        let query = CKQuery(recordType: "PersonalTodo", predicate: predicate)
        query.sortDescriptors = [
            NSSortDescriptor(key: "priority", ascending: false),
            NSSortDescriptor(key: "dueDate", ascending: true)
        ]
        
        let (results, _) = try await cloudKitService.publicDatabase.records(matching: query)
        
        return results.compactMap { result in
            switch result {
            case .success(let record):
                return PersonalTodo.from(record: record)
            case .failure(let error):
                LoggingService.shared.logError("PersonalTodo fetch failed", error: error)
                return nil
            }
        }
    }
    
    /// Create new personal todo
    func createPersonalTodo(
        title: String,
        notes: String = "",
        dueDate: Date? = nil,
        priority: TaskPriority = .medium,
        recurringPattern: RecurringPattern? = nil,
        projectTaskId: String? = nil
    ) async throws -> PersonalTodo {
        
        let todoId = UUID().uuidString
        let record = CKRecord(recordType: "PersonalTodo", recordID: CKRecord.ID(recordName: todoId))
        
        // Core fields
        record["id"] = todoId
        record["userId"] = currentUser.id
        record["title"] = title
        record["notes"] = notes
        record["isCompleted"] = false
        record["priority"] = priority.rawValue
        record["createdAt"] = Date()
        record["updatedAt"] = Date()
        
        // Optional fields
        if let dueDate = dueDate {
            record["dueDate"] = dueDate
        }
        
        if let pattern = recurringPattern {
            record["recurringPattern"] = try JSONEncoder().encode(pattern)
        }
        
        if let projectTaskId = projectTaskId {
            record["projectTaskId"] = projectTaskId
        }
        
        // Time tracking
        record["estimatedMinutes"] = 0
        record["actualMinutes"] = 0
        
        let savedRecord = try await cloudKitService.publicDatabase.save(record)
        
        guard let todo = PersonalTodo.from(record: savedRecord) else {
            throw ServiceError.dataConversionFailed
        }
        
        // Update local state
        personalTodos.insert(todo, at: 0)
        
        // Schedule reminder if due date is set
        if let dueDate = dueDate {
            await NotificationService.shared.schedulePersonalTodoReminder(
                todoId: todoId,
                title: title,
                dueDate: dueDate
            )
        }
        
        LoggingService.shared.logInfo("Created personal todo", metadata: ["todoId": todoId, "title": title])
        
        return todo
    }
    
    /// Toggle todo completion status
    func toggleTodoCompletion(_ todo: PersonalTodo) async throws {
        let recordID = CKRecord.ID(recordName: todo.id)
        
        do {
            let record = try await cloudKitService.publicDatabase.record(for: recordID)
            let newCompletionStatus = !todo.isCompleted
            
            record["isCompleted"] = newCompletionStatus
            record["updatedAt"] = Date()
            
            if newCompletionStatus {
                record["completedAt"] = Date()
                
                // Handle recurring todos
                if let pattern = todo.recurringPattern {
                    try await createNextRecurringTodo(from: todo, pattern: pattern)
                }
            } else {
                record["completedAt"] = nil
            }
            
            let savedRecord = try await cloudKitService.publicDatabase.save(record)
            
            // Update local state
            if let index = personalTodos.firstIndex(where: { $0.id == todo.id }),
               let updatedTodo = PersonalTodo.from(record: savedRecord) {
                personalTodos[index] = updatedTodo
            }
            
        } catch {
            throw ServiceError.updateFailed(error.localizedDescription)
        }
    }
    
    /// Create next instance of recurring todo
    private func createNextRecurringTodo(from todo: PersonalTodo, pattern: RecurringPattern) async throws {
        guard let nextDueDate = pattern.nextDate(from: todo.dueDate ?? Date()) else { return }
        
        _ = try await createPersonalTodo(
            title: todo.title,
            notes: todo.notes,
            dueDate: nextDueDate,
            priority: todo.priority,
            recurringPattern: pattern,
            projectTaskId: todo.projectTaskId
        )
    }
    
    // MARK: - OKR Module
    
    /// Fetch objectives for current user's scope (company, store, individual)
    func fetchObjectives() async throws -> [Objective] {
        // Build predicate based on user's access level
        var predicates: [NSPredicate] = []
        
        // Always include individual objectives
        predicates.append(NSPredicate(format: "level == %@ AND ownerId == %@", 
                                    OKRLevel.individual.rawValue, currentUser.id))
        
        // Include store objectives for user's stores
        if !currentUser.storeCodes.isEmpty {
            for storeCode in currentUser.storeCodes {
                predicates.append(NSPredicate(format: "level == %@ AND scope == %@", 
                                            OKRLevel.store.rawValue, storeCode))
            }
        }
        
        // Include company objectives if user has appropriate role
        if ["Admin", "AreaDirector", "StoreDirector"].contains(currentUser.role.rawValue) {
            predicates.append(NSPredicate(format: "level == %@", OKRLevel.company.rawValue))
        }
        
        let compoundPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: predicates)
        
        let query = CKQuery(recordType: "Objective", predicate: compoundPredicate)
        query.sortDescriptors = [
            NSSortDescriptor(key: "level", ascending: true), // Company, Store, Individual
            NSSortDescriptor(key: "createdAt", ascending: false)
        ]
        
        let (results, _) = try await cloudKitService.publicDatabase.records(matching: query)
        
        return results.compactMap { result in
            switch result {
            case .success(let record):
                return Objective.from(record: record)
            case .failure(let error):
                LoggingService.shared.logError("Objective fetch failed", error: error)
                return nil
            }
        }
    }
    
    /// Create new objective
    func createObjective(
        title: String,
        description: String,
        level: OKRLevel,
        scope: String = "",
        parentObjectiveId: String? = nil,
        quarterYear: String
    ) async throws -> Objective {
        
        let objectiveId = UUID().uuidString
        let record = CKRecord(recordType: "Objective", recordID: CKRecord.ID(recordName: objectiveId))
        
        // Core fields
        record["id"] = objectiveId
        record["title"] = title
        record["description"] = description
        record["level"] = level.rawValue
        record["scope"] = scope
        record["quarterYear"] = quarterYear
        record["status"] = OKRStatus.draft.rawValue
        record["ownerId"] = currentUser.id
        record["createdAt"] = Date()
        record["updatedAt"] = Date()
        
        // Hierarchy
        if let parentId = parentObjectiveId {
            record["parentObjectiveId"] = parentId
        }
        
        // Progress tracking
        record["progressPercentage"] = 0.0
        record["keyResultIds"] = []
        
        let savedRecord = try await cloudKitService.publicDatabase.save(record)
        
        guard let objective = Objective.from(record: savedRecord) else {
            throw ServiceError.dataConversionFailed
        }
        
        // Update local state
        objectives.insert(objective, at: 0)
        
        LoggingService.shared.logInfo("Created objective", metadata: [
            "objectiveId": objectiveId, 
            "title": title, 
            "level": level.rawValue
        ])
        
        return objective
    }
    
    /// Update objective progress based on key results
    func updateObjectiveProgress(_ objective: Objective) async throws {
        // Fetch associated key results
        let keyResults = try await fetchKeyResults(for: objective.id)
        
        // Calculate weighted progress
        let totalProgress = keyResults.reduce(0.0) { total, keyResult in
            total + (keyResult.progressPercentage * keyResult.weight)
        }
        
        let totalWeight = keyResults.reduce(0.0) { $0 + $1.weight }
        let averageProgress = totalWeight > 0 ? totalProgress / totalWeight : 0.0
        
        // Update objective record
        let recordID = CKRecord.ID(recordName: objective.id)
        
        do {
            let record = try await cloudKitService.publicDatabase.record(for: recordID)
            
            record["progressPercentage"] = averageProgress
            record["updatedAt"] = Date()
            
            // Auto-update status based on progress
            if averageProgress >= 70.0 && objective.status == .active {
                record["status"] = OKRStatus.onTrack.rawValue
            } else if averageProgress < 30.0 && objective.status == .onTrack {
                record["status"] = OKRStatus.atRisk.rawValue
            }
            
            let savedRecord = try await cloudKitService.publicDatabase.save(record)
            
            // Update local state
            if let index = objectives.firstIndex(where: { $0.id == objective.id }),
               let updatedObjective = Objective.from(record: savedRecord) {
                objectives[index] = updatedObjective
            }
            
        } catch {
            throw ServiceError.updateFailed(error.localizedDescription)
        }
    }
    
    /// Fetch key results for an objective
    private func fetchKeyResults(for objectiveId: String) async throws -> [KeyResult] {
        let predicate = NSPredicate(format: "objectiveId == %@", objectiveId)
        let query = CKQuery(recordType: "KeyResult", predicate: predicate)
        
        let (results, _) = try await cloudKitService.publicDatabase.records(matching: query)
        
        return results.compactMap { result in
            switch result {
            case .success(let record):
                return KeyResult.from(record: record)
            case .failure:
                return nil
            }
        }
    }
    
    // MARK: - Cross-Module Integration
    
    /// Link personal todo to project task
    func linkTodoToProject(todoId: String, projectTaskId: String) async throws {
        let recordID = CKRecord.ID(recordName: todoId)
        
        do {
            let record = try await cloudKitService.publicDatabase.record(for: recordID)
            record["projectTaskId"] = projectTaskId
            record["updatedAt"] = Date()
            
            let savedRecord = try await cloudKitService.publicDatabase.save(record)
            
            // Update local state
            if let index = personalTodos.firstIndex(where: { $0.id == todoId }),
               let updatedTodo = PersonalTodo.from(record: savedRecord) {
                personalTodos[index] = updatedTodo
            }
            
        } catch {
            throw ServiceError.updateFailed(error.localizedDescription)
        }
    }
    
    /// Get productivity overview for dashboard
    func getProductivityOverview() -> ProductivityOverview {
        let totalBoards = projectBoards.count
        let activeTodos = personalTodos.filter { !$0.isCompleted }.count
        let completedTodos = personalTodos.filter { $0.isCompleted }.count
        let activeObjectives = objectives.filter { $0.status == .active || $0.status == .onTrack }.count
        
        let averageOKRProgress = objectives.isEmpty ? 0.0 : 
            objectives.reduce(0.0) { $0 + $1.progressPercentage } / Double(objectives.count)
        
        return ProductivityOverview(
            totalProjectBoards: totalBoards,
            activeTodos: activeTodos,
            completedTodos: completedTodos,
            todoCompletionRate: completedTodos > 0 ? 
                Double(completedTodos) / Double(activeTodos + completedTodos) : 0.0,
            activeObjectives: activeObjectives,
            averageOKRProgress: averageOKRProgress
        )
    }
}

// MARK: - Supporting Types

enum ServiceError: LocalizedError {
    case dataConversionFailed
    case insufficientPermissions
    case updateFailed(String)
    case deleteFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .dataConversionFailed:
            return "Failed to convert data"
        case .insufficientPermissions:
            return "Insufficient permissions for this operation"
        case .updateFailed(let message):
            return "Update failed: \(message)"
        case .deleteFailed(let message):
            return "Delete failed: \(message)"
        }
    }
}

struct ProductivityOverview {
    let totalProjectBoards: Int
    let activeTodos: Int
    let completedTodos: Int
    let todoCompletionRate: Double
    let activeObjectives: Int
    let averageOKRProgress: Double
}

// MARK: - Extensions for Model Conversion

extension ProjectBoard {
    static func from(record: CKRecord) -> ProjectBoard? {
        guard let id = record["id"] as? String,
              let title = record["title"] as? String,
              let description = record["description"] as? String,
              let viewTypeRaw = record["viewType"] as? String,
              let viewType = BoardViewType(rawValue: viewTypeRaw),
              let createdAt = record["createdAt"] as? Date,
              let updatedAt = record["updatedAt"] as? Date,
              let ownerUserId = record["ownerUserId"] as? String,
              let permissionLevelRaw = record["permissionLevel"] as? String,
              let permissionLevel = PermissionLevel(rawValue: permissionLevelRaw) else {
            return nil
        }
        
        let storeCodes = record["storeCodes"] as? [String] ?? []
        let departments = record["departments"] as? [String] ?? []
        let editorUserIds = record["editorUserIds"] as? [String] ?? []
        let viewerUserIds = record["viewerUserIds"] as? [String] ?? []
        
        var customColumns: [CustomColumn] = []
        if let columnsData = record["customColumns"] as? Data {
            customColumns = (try? JSONDecoder().decode([CustomColumn].self, from: columnsData)) ?? []
        }
        
        return ProjectBoard(
            id: id,
            title: title,
            description: description,
            viewType: viewType,
            createdAt: createdAt,
            updatedAt: updatedAt,
            ownerUserId: ownerUserId,
            editorUserIds: editorUserIds,
            viewerUserIds: viewerUserIds,
            permissionLevel: permissionLevel,
            storeCodes: storeCodes,
            departments: departments,
            customColumns: customColumns
        )
    }
}

extension PersonalTodo {
    static func from(record: CKRecord) -> PersonalTodo? {
        guard let id = record["id"] as? String,
              let userId = record["userId"] as? String,
              let title = record["title"] as? String,
              let isCompleted = record["isCompleted"] as? Bool,
              let priorityRaw = record["priority"] as? String,
              let priority = TaskPriority(rawValue: priorityRaw),
              let createdAt = record["createdAt"] as? Date,
              let updatedAt = record["updatedAt"] as? Date else {
            return nil
        }
        
        let notes = record["notes"] as? String ?? ""
        let dueDate = record["dueDate"] as? Date
        let completedAt = record["completedAt"] as? Date
        let projectTaskId = record["projectTaskId"] as? String
        let estimatedMinutes = record["estimatedMinutes"] as? Int ?? 0
        let actualMinutes = record["actualMinutes"] as? Int ?? 0
        
        var recurringPattern: RecurringPattern?
        if let patternData = record["recurringPattern"] as? Data {
            recurringPattern = try? JSONDecoder().decode(RecurringPattern.self, from: patternData)
        }
        
        return PersonalTodo(
            id: id,
            userId: userId,
            title: title,
            notes: notes,
            isCompleted: isCompleted,
            dueDate: dueDate,
            completedAt: completedAt,
            priority: priority,
            recurringPattern: recurringPattern,
            projectTaskId: projectTaskId,
            estimatedMinutes: estimatedMinutes,
            actualMinutes: actualMinutes,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

extension Objective {
    static func from(record: CKRecord) -> Objective? {
        guard let id = record["id"] as? String,
              let title = record["title"] as? String,
              let description = record["description"] as? String,
              let levelRaw = record["level"] as? String,
              let level = OKRLevel(rawValue: levelRaw),
              let scope = record["scope"] as? String,
              let quarterYear = record["quarterYear"] as? String,
              let statusRaw = record["status"] as? String,
              let status = OKRStatus(rawValue: statusRaw),
              let ownerId = record["ownerId"] as? String,
              let progressPercentage = record["progressPercentage"] as? Double,
              let createdAt = record["createdAt"] as? Date,
              let updatedAt = record["updatedAt"] as? Date else {
            return nil
        }
        
        let parentObjectiveId = record["parentObjectiveId"] as? String
        let keyResultIds = record["keyResultIds"] as? [String] ?? []
        
        return Objective(
            id: id,
            title: title,
            description: description,
            level: level,
            scope: scope,
            parentObjectiveId: parentObjectiveId,
            quarterYear: quarterYear,
            status: status,
            ownerId: ownerId,
            progressPercentage: progressPercentage,
            keyResultIds: keyResultIds,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

extension KeyResult {
    static func from(record: CKRecord) -> KeyResult? {
        guard let id = record["id"] as? String,
              let objectiveId = record["objectiveId"] as? String,
              let title = record["title"] as? String,
              let description = record["description"] as? String,
              let valueTypeRaw = record["valueType"] as? String,
              let valueType = KeyResultValueType(rawValue: valueTypeRaw),
              let targetValue = record["targetValue"] as? Double,
              let currentValue = record["currentValue"] as? Double,
              let weight = record["weight"] as? Double,
              let progressPercentage = record["progressPercentage"] as? Double,
              let createdAt = record["createdAt"] as? Date,
              let updatedAt = record["updatedAt"] as? Date else {
            return nil
        }
        
        let unit = record["unit"] as? String
        
        return KeyResult(
            id: id,
            objectiveId: objectiveId,
            title: title,
            description: description,
            valueType: valueType,
            targetValue: targetValue,
            currentValue: currentValue,
            unit: unit,
            weight: weight,
            progressPercentage: progressPercentage,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
