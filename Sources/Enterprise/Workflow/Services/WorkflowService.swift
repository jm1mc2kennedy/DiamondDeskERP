import Foundation
import CloudKit
import Combine

// MARK: - Workflow Service Protocol
public protocol WorkflowServiceProtocol {
    func fetchWorkflows() async throws -> [Workflow]
    func fetchWorkflow(by id: String) async throws -> Workflow?
    func fetchWorkflowsByType(_ type: TriggerType) async throws -> [Workflow]
    func fetchActiveWorkflows() async throws -> [Workflow]
    func fetchWorkflowsByUser(_ userId: String) async throws -> [Workflow]
    func createWorkflow(_ workflow: Workflow) async throws -> Workflow
    func updateWorkflow(_ workflow: Workflow) async throws -> Workflow
    func deleteWorkflow(id: String) async throws
    func toggleWorkflowStatus(id: String, isActive: Bool) async throws -> Workflow
    func executeWorkflow(id: String, context: [String: Any]?) async throws -> WorkflowExecution
    func fetchWorkflowExecutions(workflowId: String, limit: Int?) async throws -> [WorkflowExecution]
    func searchWorkflows(query: String) async throws -> [Workflow]
}

// MARK: - Workflow Service Implementation
@MainActor
public final class WorkflowService: ObservableObject, WorkflowServiceProtocol {
    
    // MARK: - Published Properties
    @Published public private(set) var workflows: [Workflow] = []
    @Published public private(set) var activeWorkflows: [Workflow] = []
    @Published public private(set) var recentExecutions: [WorkflowExecution] = []
    @Published public private(set) var isLoading = false
    @Published public private(set) var error: Error?
    
    // MARK: - Private Properties
    private let container: CKContainer
    private let privateDatabase: CKDatabase
    private let publicDatabase: CKDatabase
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Constants
    private enum RecordType {
        static let workflow = "Workflow"
        static let workflowExecution = "WorkflowExecution"
        static let triggerCondition = "TriggerCondition"
        static let actionStep = "ActionStep"
    }
    
    // MARK: - Initialization
    public init(container: CKContainer = CKContainer.default) {
        self.container = container
        self.privateDatabase = container.privateCloudDatabase
        self.publicDatabase = container.publicCloudDatabase
        
        Task {
            await loadInitialData()
        }
    }
    
    // MARK: - Public Methods
    
    public func fetchWorkflows() async throws -> [Workflow] {
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        do {
            let query = CKQuery(recordType: RecordType.workflow, predicate: NSPredicate(value: true))
            query.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
            
            let (records, _) = try await privateDatabase.records(matching: query)
            let workflows = records.compactMap { _, result in
                switch result {
                case .success(let record):
                    return Workflow.from(record: record)
                case .failure:
                    return nil
                }
            }
            
            self.workflows = workflows
            self.activeWorkflows = workflows.filter { $0.isActive }
            
            return workflows
        } catch {
            self.error = error
            throw error
        }
    }
    
    public func fetchWorkflow(by id: String) async throws -> Workflow? {
        do {
            let recordID = CKRecord.ID(recordName: id)
            let record = try await privateDatabase.record(for: recordID)
            return Workflow.from(record: record)
        } catch {
            if let ckError = error as? CKError, ckError.code == .unknownItem {
                return nil
            }
            throw error
        }
    }
    
    public func fetchWorkflowsByType(_ type: TriggerType) async throws -> [Workflow] {
        let predicate = NSPredicate(format: "triggerType == %@", type.rawValue)
        let query = CKQuery(recordType: RecordType.workflow, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        
        let (records, _) = try await privateDatabase.records(matching: query)
        return records.compactMap { _, result in
            switch result {
            case .success(let record):
                return Workflow.from(record: record)
            case .failure:
                return nil
            }
        }
    }
    
    public func fetchActiveWorkflows() async throws -> [Workflow] {
        let predicate = NSPredicate(format: "isActive == YES")
        let query = CKQuery(recordType: RecordType.workflow, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "lastExecuted", ascending: false)]
        
        let (records, _) = try await privateDatabase.records(matching: query)
        let workflows = records.compactMap { _, result in
            switch result {
            case .success(let record):
                return Workflow.from(record: record)
            case .failure:
                return nil
            }
        }
        
        self.activeWorkflows = workflows
        return workflows
    }
    
    public func fetchWorkflowsByUser(_ userId: String) async throws -> [Workflow] {
        let predicate = NSPredicate(format: "createdBy == %@", userId)
        let query = CKQuery(recordType: RecordType.workflow, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        
        let (records, _) = try await privateDatabase.records(matching: query)
        return records.compactMap { _, result in
            switch result {
            case .success(let record):
                return Workflow.from(record: record)
            case .failure:
                return nil
            }
        }
    }
    
    public func createWorkflow(_ workflow: Workflow) async throws -> Workflow {
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        do {
            let record = workflow.toCKRecord()
            let savedRecord = try await privateDatabase.save(record)
            
            if let savedWorkflow = Workflow.from(record: savedRecord) {
                workflows.insert(savedWorkflow, at: 0)
                if savedWorkflow.isActive {
                    activeWorkflows.insert(savedWorkflow, at: 0)
                }
                return savedWorkflow
            }
            
            throw WorkflowServiceError.invalidWorkflowData
        } catch {
            self.error = error
            throw error
        }
    }
    
    public func updateWorkflow(_ workflow: Workflow) async throws -> Workflow {
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        do {
            let record = workflow.toCKRecord()
            let savedRecord = try await privateDatabase.save(record)
            
            if let updatedWorkflow = Workflow.from(record: savedRecord) {
                if let index = workflows.firstIndex(where: { $0.id == workflow.id }) {
                    workflows[index] = updatedWorkflow
                }
                
                // Update active workflows
                activeWorkflows.removeAll { $0.id == workflow.id }
                if updatedWorkflow.isActive {
                    activeWorkflows.append(updatedWorkflow)
                }
                
                return updatedWorkflow
            }
            
            throw WorkflowServiceError.invalidWorkflowData
        } catch {
            self.error = error
            throw error
        }
    }
    
    public func deleteWorkflow(id: String) async throws {
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        do {
            let recordID = CKRecord.ID(recordName: id)
            _ = try await privateDatabase.deleteRecord(withID: recordID)
            
            workflows.removeAll { $0.id == id }
            activeWorkflows.removeAll { $0.id == id }
        } catch {
            self.error = error
            throw error
        }
    }
    
    public func toggleWorkflowStatus(id: String, isActive: Bool) async throws -> Workflow {
        guard let workflow = try await fetchWorkflow(by: id) else {
            throw WorkflowServiceError.workflowNotFound
        }
        
        var updatedWorkflow = workflow
        updatedWorkflow.isActive = isActive
        
        return try await updateWorkflow(updatedWorkflow)
    }
    
    public func executeWorkflow(id: String, context: [String: Any]?) async throws -> WorkflowExecution {
        guard let workflow = try await fetchWorkflow(by: id) else {
            throw WorkflowServiceError.workflowNotFound
        }
        
        guard workflow.isActive else {
            throw WorkflowServiceError.workflowInactive
        }
        
        // Create execution record
        let execution = WorkflowExecution(
            id: UUID().uuidString,
            workflowId: id,
            status: .running,
            startedAt: Date(),
            triggeredBy: "manual", // This would come from context in real implementation
            triggerMethod: "manual_execution"
        )
        
        // In a real implementation, this would execute the workflow steps
        // For now, we'll simulate a successful execution
        var completedExecution = execution
        completedExecution.completedAt = Date()
        completedExecution.status = .completed
        
        // Update workflow execution count
        var updatedWorkflow = workflow
        updatedWorkflow.executionCount += 1
        updatedWorkflow.lastExecuted = Date()
        
        _ = try await updateWorkflow(updatedWorkflow)
        
        // Add to recent executions
        recentExecutions.insert(completedExecution, at: 0)
        if recentExecutions.count > 50 {
            recentExecutions = Array(recentExecutions.prefix(50))
        }
        
        return completedExecution
    }
    
    public func fetchWorkflowExecutions(workflowId: String, limit: Int? = 20) async throws -> [WorkflowExecution] {
        let predicate = NSPredicate(format: "workflowId == %@", workflowId)
        let query = CKQuery(recordType: RecordType.workflowExecution, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "startedAt", ascending: false)]
        
        let (records, _) = try await privateDatabase.records(matching: query)
        let executions = records.compactMap { _, result in
            switch result {
            case .success(let record):
                return WorkflowExecution.from(record: record)
            case .failure:
                return nil
            }
        }
        
        let limitedExecutions = limit.map { Array(executions.prefix($0)) } ?? executions
        
        if workflowId.isEmpty {
            recentExecutions = limitedExecutions
        }
        
        return limitedExecutions
    }
    
    public func searchWorkflows(query: String) async throws -> [Workflow] {
        let predicate = NSPredicate(format: "name CONTAINS[cd] %@ OR description CONTAINS[cd] %@", query, query)
        let ckQuery = CKQuery(recordType: RecordType.workflow, predicate: predicate)
        ckQuery.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        
        let (records, _) = try await privateDatabase.records(matching: ckQuery)
        return records.compactMap { _, result in
            switch result {
            case .success(let record):
                return Workflow.from(record: record)
            case .failure:
                return nil
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func loadInitialData() async {
        do {
            _ = try await fetchWorkflows()
        } catch {
            self.error = error
        }
    }
}

// MARK: - Workflow Service Error
public enum WorkflowServiceError: LocalizedError {
    case invalidWorkflowData
    case workflowNotFound
    case workflowInactive
    case executionFailed(String)
    case cloudKitError(Error)
    
    public var errorDescription: String? {
        switch self {
        case .invalidWorkflowData:
            return "Invalid workflow data"
        case .workflowNotFound:
            return "Workflow not found"
        case .workflowInactive:
            return "Workflow is not active"
        case .executionFailed(let message):
            return "Workflow execution failed: \(message)"
        case .cloudKitError(let error):
            return "CloudKit error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Mock Workflow Service (for testing/previews)
public final class MockWorkflowService: WorkflowServiceProtocol {
    private var workflows: [Workflow] = []
    
    public init() {}
    
    public func fetchWorkflows() async throws -> [Workflow] {
        return workflows
    }
    
    public func fetchWorkflow(by id: String) async throws -> Workflow? {
        return workflows.first { $0.id == id }
    }
    
    public func fetchWorkflowsByType(_ type: TriggerType) async throws -> [Workflow] {
        return workflows.filter { $0.triggerType == type }
    }
    
    public func fetchActiveWorkflows() async throws -> [Workflow] {
        return workflows.filter { $0.isActive }
    }
    
    public func fetchWorkflowsByUser(_ userId: String) async throws -> [Workflow] {
        return workflows.filter { $0.createdBy == userId }
    }
    
    public func createWorkflow(_ workflow: Workflow) async throws -> Workflow {
        workflows.append(workflow)
        return workflow
    }
    
    public func updateWorkflow(_ workflow: Workflow) async throws -> Workflow {
        if let index = workflows.firstIndex(where: { $0.id == workflow.id }) {
            workflows[index] = workflow
        }
        return workflow
    }
    
    public func deleteWorkflow(id: String) async throws {
        workflows.removeAll { $0.id == id }
    }
    
    public func toggleWorkflowStatus(id: String, isActive: Bool) async throws -> Workflow {
        guard let workflow = workflows.first(where: { $0.id == id }) else {
            throw WorkflowServiceError.workflowNotFound
        }
        var updated = workflow
        updated.isActive = isActive
        return try await updateWorkflow(updated)
    }
    
    public func executeWorkflow(id: String, context: [String: Any]?) async throws -> WorkflowExecution {
        guard let workflow = workflows.first(where: { $0.id == id }) else {
            throw WorkflowServiceError.workflowNotFound
        }
        
        return WorkflowExecution(
            id: UUID().uuidString,
            workflowId: id,
            status: .completed,
            startedAt: Date(),
            completedAt: Date(),
            triggeredBy: "manual",
            triggerMethod: "manual_execution"
        )
    }
    
    public func fetchWorkflowExecutions(workflowId: String, limit: Int?) async throws -> [WorkflowExecution] {
        return []
    }
    
    public func searchWorkflows(query: String) async throws -> [Workflow] {
        return workflows.filter {
            $0.name.localizedCaseInsensitiveContains(query) ||
            $0.description?.localizedCaseInsensitiveContains(query) == true
        }
    }
}
