import SwiftUI
import Combine

// MARK: - Workflow View Model

@MainActor
public class WorkflowViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published public var workflows: [Workflow] = []
    @Published public var activeWorkflows: [Workflow] = []
    @Published public var recentExecutions: [WorkflowExecution] = []
    @Published public var filteredWorkflows: [Workflow] = []
    
    @Published public var searchText = ""
    @Published public var selectedTriggerType: TriggerType?
    @Published public var showActiveOnly = false
    @Published public var viewMode: WorkflowViewMode = .list
    
    @Published public var isLoading = false
    @Published public var error: WorkflowError?
    @Published public var showingCreateWorkflow = false
    @Published public var showingExecutionHistory = false
    @Published public var showingAnalytics = false
    
    @Published public var selectedWorkflow: Workflow?
    @Published public var executionInProgress = false
    @Published public var lastExecutionResult: WorkflowExecution?
    
    // MARK: - Analytics Data
    
    @Published public var analytics: WorkflowAnalytics?
    @Published public var performanceMetrics: WorkflowPerformanceMetrics?
    
    // MARK: - Services
    
    private let workflowService: WorkflowServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    public init(workflowService: WorkflowServiceProtocol = WorkflowService()) {
        self.workflowService = workflowService
        setupBindings()
        setupSearchAndFilters()
    }
    
    // MARK: - Setup Methods
    
    private func setupBindings() {
        if let service = workflowService as? WorkflowService {
            service.$workflows
                .receive(on: DispatchQueue.main)
                .assign(to: \.workflows, on: self)
                .store(in: &cancellables)
            
            service.$activeWorkflows
                .receive(on: DispatchQueue.main)
                .assign(to: \.activeWorkflows, on: self)
                .store(in: &cancellables)
            
            service.$recentExecutions
                .receive(on: DispatchQueue.main)
                .assign(to: \.recentExecutions, on: self)
                .store(in: &cancellables)
            
            service.$isLoading
                .receive(on: DispatchQueue.main)
                .assign(to: \.isLoading, on: self)
                .store(in: &cancellables)
            
            service.$error
                .receive(on: DispatchQueue.main)
                .map { $0.map(WorkflowError.serviceError) }
                .assign(to: \.error, on: self)
                .store(in: &cancellables)
        }
    }
    
    private func setupSearchAndFilters() {
        Publishers.CombineLatest4($workflows, $searchText, $selectedTriggerType, $showActiveOnly)
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .map { workflows, searchText, triggerType, activeOnly in
                self.filterWorkflows(workflows, searchText: searchText, triggerType: triggerType, activeOnly: activeOnly)
            }
            .assign(to: \.filteredWorkflows, on: self)
            .store(in: &cancellables)
    }
    
    // MARK: - Data Loading Methods
    
    public func loadData() async {
        do {
            await MainActor.run { isLoading = true }
            _ = try await workflowService.fetchWorkflows()
            await loadAnalytics()
        } catch {
            await MainActor.run { 
                self.error = WorkflowError.loadingFailed(error.localizedDescription)
                isLoading = false
            }
        }
    }
    
    public func refreshData() async {
        await loadData()
    }
    
    private func loadAnalytics() async {
        // Calculate workflow analytics
        let totalWorkflows = workflows.count
        let activeCount = workflows.filter { $0.isActive }.count
        let totalExecutions = workflows.reduce(0) { $0 + $1.executionCount }
        let avgExecutionsPerWorkflow = totalWorkflows > 0 ? Double(totalExecutions) / Double(totalWorkflows) : 0
        
        analytics = WorkflowAnalytics(
            totalWorkflows: totalWorkflows,
            activeWorkflows: activeCount,
            totalExecutions: totalExecutions,
            averageExecutionsPerWorkflow: avgExecutionsPerWorkflow,
            executionSuccessRate: calculateSuccessRate(),
            mostUsedTriggerType: findMostUsedTriggerType()
        )
        
        performanceMetrics = WorkflowPerformanceMetrics(
            averageExecutionTime: calculateAverageExecutionTime(),
            fastestExecution: findFastestExecution(),
            slowestExecution: findSlowestExecution(),
            errorRate: calculateErrorRate()
        )
    }
    
    // MARK: - Workflow Operations
    
    public func createWorkflow(_ workflow: Workflow) async {
        do {
            await MainActor.run { isLoading = true }
            _ = try await workflowService.createWorkflow(workflow)
            await MainActor.run { 
                showingCreateWorkflow = false
                isLoading = false
            }
        } catch {
            await MainActor.run { 
                self.error = WorkflowError.creationFailed(error.localizedDescription)
                isLoading = false
            }
        }
    }
    
    public func updateWorkflow(_ workflow: Workflow) async {
        do {
            await MainActor.run { isLoading = true }
            _ = try await workflowService.updateWorkflow(workflow)
            await MainActor.run { isLoading = false }
        } catch {
            await MainActor.run { 
                self.error = WorkflowError.updateFailed(error.localizedDescription)
                isLoading = false
            }
        }
    }
    
    public func deleteWorkflow(_ workflow: Workflow) async {
        do {
            await MainActor.run { isLoading = true }
            try await workflowService.deleteWorkflow(id: workflow.id)
            await MainActor.run { isLoading = false }
        } catch {
            await MainActor.run { 
                self.error = WorkflowError.deletionFailed(error.localizedDescription)
                isLoading = false
            }
        }
    }
    
    public func executeWorkflow(_ workflow: Workflow, context: [String: Any]? = nil) async {
        do {
            await MainActor.run { 
                executionInProgress = true
                error = nil
            }
            
            let execution = try await workflowService.executeWorkflow(id: workflow.id, context: context)
            
            await MainActor.run { 
                lastExecutionResult = execution
                executionInProgress = false
            }
            
            // Refresh data to show updated execution count
            await refreshData()
        } catch {
            await MainActor.run { 
                self.error = WorkflowError.executionFailed(error.localizedDescription)
                executionInProgress = false
            }
        }
    }
    
    public func toggleWorkflowStatus(_ workflow: Workflow) async {
        do {
            await MainActor.run { isLoading = true }
            _ = try await workflowService.toggleWorkflowStatus(id: workflow.id, isActive: !workflow.isActive)
            await MainActor.run { isLoading = false }
        } catch {
            await MainActor.run { 
                self.error = WorkflowError.updateFailed(error.localizedDescription)
                isLoading = false
            }
        }
    }
    
    public func searchWorkflows(_ query: String) async {
        if query.isEmpty {
            searchText = ""
            return
        }
        
        do {
            let results = try await workflowService.searchWorkflows(query: query)
            await MainActor.run { 
                filteredWorkflows = results
                searchText = query
            }
        } catch {
            await MainActor.run { 
                self.error = WorkflowError.searchFailed(error.localizedDescription)
            }
        }
    }
    
    // MARK: - Private Helper Methods
    
    private func filterWorkflows(_ workflows: [Workflow], searchText: String, triggerType: TriggerType?, activeOnly: Bool) -> [Workflow] {
        var filtered = workflows
        
        // Filter by active status
        if activeOnly {
            filtered = filtered.filter { $0.isActive }
        }
        
        // Filter by trigger type
        if let triggerType = triggerType {
            filtered = filtered.filter { $0.triggerType == triggerType }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { workflow in
                workflow.name.localizedCaseInsensitiveContains(searchText) ||
                workflow.description?.localizedCaseInsensitiveContains(searchText) == true ||
                workflow.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        return filtered.sorted { $0.name < $1.name }
    }
    
    private func calculateSuccessRate() -> Double {
        // In a real implementation, this would analyze execution history
        return 0.95 // 95% success rate as placeholder
    }
    
    private func findMostUsedTriggerType() -> TriggerType? {
        let triggerCounts = Dictionary(grouping: workflows, by: { $0.triggerType })
            .mapValues { $0.count }
        return triggerCounts.max(by: { $0.value < $1.value })?.key
    }
    
    private func calculateAverageExecutionTime() -> TimeInterval {
        // Placeholder - would calculate from execution history
        return 2.5 // 2.5 seconds average
    }
    
    private func findFastestExecution() -> TimeInterval {
        // Placeholder - would find from execution history
        return 0.8 // 0.8 seconds
    }
    
    private func findSlowestExecution() -> TimeInterval {
        // Placeholder - would find from execution history
        return 15.2 // 15.2 seconds
    }
    
    private func calculateErrorRate() -> Double {
        // Placeholder - would calculate from execution history
        return 0.05 // 5% error rate
    }
}

// MARK: - Supporting Types

public enum WorkflowViewMode: CaseIterable {
    case list
    case grid
    case kanban
    
    public var displayName: String {
        switch self {
        case .list: return "List"
        case .grid: return "Grid"
        case .kanban: return "Kanban"
        }
    }
}

public enum WorkflowError: LocalizedError {
    case loadingFailed(String)
    case creationFailed(String)
    case updateFailed(String)
    case deletionFailed(String)
    case executionFailed(String)
    case searchFailed(String)
    case serviceError(Error)
    
    public var errorDescription: String? {
        switch self {
        case .loadingFailed(let message):
            return "Failed to load workflows: \(message)"
        case .creationFailed(let message):
            return "Failed to create workflow: \(message)"
        case .updateFailed(let message):
            return "Failed to update workflow: \(message)"
        case .deletionFailed(let message):
            return "Failed to delete workflow: \(message)"
        case .executionFailed(let message):
            return "Failed to execute workflow: \(message)"
        case .searchFailed(let message):
            return "Search failed: \(message)"
        case .serviceError(let error):
            return error.localizedDescription
        }
    }
}

public struct WorkflowAnalytics {
    public let totalWorkflows: Int
    public let activeWorkflows: Int
    public let totalExecutions: Int
    public let averageExecutionsPerWorkflow: Double
    public let executionSuccessRate: Double
    public let mostUsedTriggerType: TriggerType?
    
    public init(totalWorkflows: Int, activeWorkflows: Int, totalExecutions: Int, averageExecutionsPerWorkflow: Double, executionSuccessRate: Double, mostUsedTriggerType: TriggerType?) {
        self.totalWorkflows = totalWorkflows
        self.activeWorkflows = activeWorkflows
        self.totalExecutions = totalExecutions
        self.averageExecutionsPerWorkflow = averageExecutionsPerWorkflow
        self.executionSuccessRate = executionSuccessRate
        self.mostUsedTriggerType = mostUsedTriggerType
    }
}

public struct WorkflowPerformanceMetrics {
    public let averageExecutionTime: TimeInterval
    public let fastestExecution: TimeInterval
    public let slowestExecution: TimeInterval
    public let errorRate: Double
    
    public init(averageExecutionTime: TimeInterval, fastestExecution: TimeInterval, slowestExecution: TimeInterval, errorRate: Double) {
        self.averageExecutionTime = averageExecutionTime
        self.fastestExecution = fastestExecution
        self.slowestExecution = slowestExecution
        self.errorRate = errorRate
    }
}
