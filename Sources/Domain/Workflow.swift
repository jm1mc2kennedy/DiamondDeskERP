import Foundation
import CloudKit

// MARK: - Workflow & Automation Models (Phase 4.12+ Implementation)

public struct Workflow: Identifiable, Codable, Hashable {
    public let id: String
    public var name: String
    public var description: String?
    public var triggerType: TriggerType
    public var isActive: Bool
    public var createdBy: String
    public var createdAt: Date
    public var lastExecuted: Date?
    public var executionCount: Int
    public var triggerConditions: [TriggerCondition]
    public var actionSteps: [ActionStep]
    public var errorHandling: ErrorHandlingConfig
    public var executionHistory: [WorkflowExecution]
    public var tags: [String]
    
    public init(
        id: String = UUID().uuidString,
        name: String,
        description: String? = nil,
        triggerType: TriggerType,
        isActive: Bool = true,
        createdBy: String,
        createdAt: Date = Date(),
        lastExecuted: Date? = nil,
        executionCount: Int = 0,
        triggerConditions: [TriggerCondition] = [],
        actionSteps: [ActionStep] = [],
        errorHandling: ErrorHandlingConfig = ErrorHandlingConfig(),
        executionHistory: [WorkflowExecution] = [],
        tags: [String] = []
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.triggerType = triggerType
        self.isActive = isActive
        self.createdBy = createdBy
        self.createdAt = createdAt
        self.lastExecuted = lastExecuted
        self.executionCount = executionCount
        self.triggerConditions = triggerConditions
        self.actionSteps = actionSteps
        self.errorHandling = errorHandling
        self.executionHistory = executionHistory
        self.tags = tags
    }
}

public enum TriggerType: String, CaseIterable, Codable, Identifiable {
    case manual = "MANUAL"
    case scheduled = "SCHEDULED"
    case dataChange = "DATA_CHANGE"
    case webhook = "WEBHOOK"
    case userAction = "USER_ACTION"
    case systemEvent = "SYSTEM_EVENT"
    case conditional = "CONDITIONAL"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .manual: return "Manual Trigger"
        case .scheduled: return "Scheduled"
        case .dataChange: return "Data Change"
        case .webhook: return "Webhook"
        case .userAction: return "User Action"
        case .systemEvent: return "System Event"
        case .conditional: return "Conditional"
        }
    }
}

public struct TriggerCondition: Identifiable, Codable, Hashable {
    public let id: String
    public var workflowId: String
    public var field: String
    public var operator: ConditionOperator
    public var value: String
    public var logicalOperator: LogicalOperator
    public var priority: Int
    public var isEnabled: Bool
    
    public init(
        id: String = UUID().uuidString,
        workflowId: String,
        field: String,
        operator: ConditionOperator,
        value: String,
        logicalOperator: LogicalOperator = .and,
        priority: Int = 0,
        isEnabled: Bool = true
    ) {
        self.id = id
        self.workflowId = workflowId
        self.field = field
        self.operator = `operator`
        self.value = value
        self.logicalOperator = logicalOperator
        self.priority = priority
        self.isEnabled = isEnabled
    }
}

public enum ConditionOperator: String, CaseIterable, Codable, Identifiable {
    case equals = "EQUALS"
    case notEquals = "NOT_EQUALS"
    case contains = "CONTAINS"
    case notContains = "NOT_CONTAINS"
    case greaterThan = "GREATER_THAN"
    case lessThan = "LESS_THAN"
    case greaterThanOrEqual = "GREATER_THAN_OR_EQUAL"
    case lessThanOrEqual = "LESS_THAN_OR_EQUAL"
    case isEmpty = "IS_EMPTY"
    case isNotEmpty = "IS_NOT_EMPTY"
    case startsWith = "STARTS_WITH"
    case endsWith = "ENDS_WITH"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .equals: return "Equals"
        case .notEquals: return "Not Equals"
        case .contains: return "Contains"
        case .notContains: return "Not Contains"
        case .greaterThan: return "Greater Than"
        case .lessThan: return "Less Than"
        case .greaterThanOrEqual: return "Greater Than or Equal"
        case .lessThanOrEqual: return "Less Than or Equal"
        case .isEmpty: return "Is Empty"
        case .isNotEmpty: return "Is Not Empty"
        case .startsWith: return "Starts With"
        case .endsWith: return "Ends With"
        }
    }
}

public enum LogicalOperator: String, CaseIterable, Codable, Identifiable {
    case and = "AND"
    case or = "OR"
    case not = "NOT"
    
    public var id: String { rawValue }
}

public struct ActionStep: Identifiable, Codable, Hashable {
    public let id: String
    public var workflowId: String
    public var stepOrder: Int
    public var actionType: ActionType
    public var parameters: [String: String]
    public var isEnabled: Bool
    public var retryConfig: RetryConfig
    public var timeout: TimeInterval
    public var description: String?
    
    public init(
        id: String = UUID().uuidString,
        workflowId: String,
        stepOrder: Int,
        actionType: ActionType,
        parameters: [String: String] = [:],
        isEnabled: Bool = true,
        retryConfig: RetryConfig = RetryConfig(),
        timeout: TimeInterval = 30.0,
        description: String? = nil
    ) {
        self.id = id
        self.workflowId = workflowId
        self.stepOrder = stepOrder
        self.actionType = actionType
        self.parameters = parameters
        self.isEnabled = isEnabled
        self.retryConfig = retryConfig
        self.timeout = timeout
        self.description = description
    }
}

public enum ActionType: String, CaseIterable, Codable, Identifiable {
    case sendEmail = "SEND_EMAIL"
    case sendNotification = "SEND_NOTIFICATION"
    case createRecord = "CREATE_RECORD"
    case updateRecord = "UPDATE_RECORD"
    case deleteRecord = "DELETE_RECORD"
    case executeScript = "EXECUTE_SCRIPT"
    case callWebhook = "CALL_WEBHOOK"
    case generateReport = "GENERATE_REPORT"
    case assignTask = "ASSIGN_TASK"
    case waitForCondition = "WAIT_FOR_CONDITION"
    case branch = "BRANCH"
    case loop = "LOOP"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .sendEmail: return "Send Email"
        case .sendNotification: return "Send Notification"
        case .createRecord: return "Create Record"
        case .updateRecord: return "Update Record"
        case .deleteRecord: return "Delete Record"
        case .executeScript: return "Execute Script"
        case .callWebhook: return "Call Webhook"
        case .generateReport: return "Generate Report"
        case .assignTask: return "Assign Task"
        case .waitForCondition: return "Wait for Condition"
        case .branch: return "Branch"
        case .loop: return "Loop"
        }
    }
}

public struct WorkflowExecution: Identifiable, Codable, Hashable {
    public let id: String
    public var workflowId: String
    public var status: ExecutionStatus
    public var startedAt: Date
    public var completedAt: Date?
    public var triggeredBy: String?
    public var triggerMethod: String?
    public var errorMessage: String?
    public var stepResults: [StepResult]
    public var metrics: ExecutionMetrics
    
    public init(
        id: String = UUID().uuidString,
        workflowId: String,
        status: ExecutionStatus = .running,
        startedAt: Date = Date(),
        completedAt: Date? = nil,
        triggeredBy: String? = nil,
        triggerMethod: String? = nil,
        errorMessage: String? = nil,
        stepResults: [StepResult] = [],
        metrics: ExecutionMetrics = ExecutionMetrics()
    ) {
        self.id = id
        self.workflowId = workflowId
        self.status = status
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.triggeredBy = triggeredBy
        self.triggerMethod = triggerMethod
        self.errorMessage = errorMessage
        self.stepResults = stepResults
        self.metrics = metrics
    }
}

public enum ExecutionStatus: String, CaseIterable, Codable, Identifiable {
    case queued = "QUEUED"
    case running = "RUNNING"
    case completed = "COMPLETED"
    case failed = "FAILED"
    case cancelled = "CANCELLED"
    case paused = "PAUSED"
    case skipped = "SKIPPED"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .queued: return "Queued"
        case .running: return "Running"
        case .completed: return "Completed"
        case .failed: return "Failed"
        case .cancelled: return "Cancelled"
        case .paused: return "Paused"
        case .skipped: return "Skipped"
        }
    }
}

public struct StepResult: Identifiable, Codable, Hashable {
    public let id: String
    public var stepId: String
    public var status: ExecutionStatus
    public var startedAt: Date
    public var completedAt: Date?
    public var output: String?
    public var errorMessage: String?
    public var retryCount: Int
    
    public init(
        id: String = UUID().uuidString,
        stepId: String,
        status: ExecutionStatus = .running,
        startedAt: Date = Date(),
        completedAt: Date? = nil,
        output: String? = nil,
        errorMessage: String? = nil,
        retryCount: Int = 0
    ) {
        self.id = id
        self.stepId = stepId
        self.status = status
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.output = output
        self.errorMessage = errorMessage
        self.retryCount = retryCount
    }
}

public struct ExecutionMetrics: Codable, Hashable {
    public var totalDuration: TimeInterval
    public var stepDurations: [String: TimeInterval]
    public var memoryUsage: Int64
    public var cpuUsage: Double
    
    public init(
        totalDuration: TimeInterval = 0.0,
        stepDurations: [String: TimeInterval] = [:],
        memoryUsage: Int64 = 0,
        cpuUsage: Double = 0.0
    ) {
        self.totalDuration = totalDuration
        self.stepDurations = stepDurations
        self.memoryUsage = memoryUsage
        self.cpuUsage = cpuUsage
    }
}

public struct RetryConfig: Codable, Hashable {
    public var maxRetries: Int
    public var retryInterval: TimeInterval
    public var exponentialBackoff: Bool
    
    public init(
        maxRetries: Int = 3,
        retryInterval: TimeInterval = 1.0,
        exponentialBackoff: Bool = true
    ) {
        self.maxRetries = maxRetries
        self.retryInterval = retryInterval
        self.exponentialBackoff = exponentialBackoff
    }
}

public struct ErrorHandlingConfig: Codable, Hashable {
    public var continueOnError: Bool
    public var notifyOnError: Bool
    public var rollbackOnError: Bool
    public var errorNotificationRecipients: [String]
    
    public init(
        continueOnError: Bool = false,
        notifyOnError: Bool = true,
        rollbackOnError: Bool = false,
        errorNotificationRecipients: [String] = []
    ) {
        self.continueOnError = continueOnError
        self.notifyOnError = notifyOnError
        self.rollbackOnError = rollbackOnError
        self.errorNotificationRecipients = errorNotificationRecipients
    }
}

// MARK: - CloudKit Extensions
extension Workflow {
    public func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: "Workflow", recordID: CKRecord.ID(recordName: id))
        record["name"] = name
        record["description"] = description
        record["triggerType"] = triggerType.rawValue
        record["isActive"] = isActive
        record["createdBy"] = createdBy
        record["createdAt"] = createdAt
        record["lastExecuted"] = lastExecuted
        record["executionCount"] = executionCount
        record["tags"] = tags
        
        // Encode complex objects as Data
        if let conditionsData = try? JSONEncoder().encode(triggerConditions) {
            record["triggerConditions"] = conditionsData
        }
        if let stepsData = try? JSONEncoder().encode(actionSteps) {
            record["actionSteps"] = stepsData
        }
        if let errorHandlingData = try? JSONEncoder().encode(errorHandling) {
            record["errorHandling"] = errorHandlingData
        }
        
        return record
    }
    
    public static func from(record: CKRecord) -> Workflow? {
        guard let name = record["name"] as? String,
              let triggerTypeString = record["triggerType"] as? String,
              let triggerType = TriggerType(rawValue: triggerTypeString),
              let isActive = record["isActive"] as? Bool,
              let createdBy = record["createdBy"] as? String,
              let createdAt = record["createdAt"] as? Date,
              let executionCount = record["executionCount"] as? Int else {
            return nil
        }
        
        let description = record["description"] as? String
        let lastExecuted = record["lastExecuted"] as? Date
        let tags = record["tags"] as? [String] ?? []
        
        // Decode complex objects
        var triggerConditions: [TriggerCondition] = []
        if let conditionsData = record["triggerConditions"] as? Data {
            triggerConditions = (try? JSONDecoder().decode([TriggerCondition].self, from: conditionsData)) ?? []
        }
        
        var actionSteps: [ActionStep] = []
        if let stepsData = record["actionSteps"] as? Data {
            actionSteps = (try? JSONDecoder().decode([ActionStep].self, from: stepsData)) ?? []
        }
        
        var errorHandling = ErrorHandlingConfig()
        if let errorHandlingData = record["errorHandling"] as? Data {
            errorHandling = (try? JSONDecoder().decode(ErrorHandlingConfig.self, from: errorHandlingData)) ?? ErrorHandlingConfig()
        }
        
        return Workflow(
            id: record.recordID.recordName,
            name: name,
            description: description,
            triggerType: triggerType,
            isActive: isActive,
            createdBy: createdBy,
            createdAt: createdAt,
            lastExecuted: lastExecuted,
            executionCount: executionCount,
            triggerConditions: triggerConditions,
            actionSteps: actionSteps,
            errorHandling: errorHandling,
            tags: tags
        )
    }
}

// MARK: - WorkflowExecution CloudKit Extensions
extension WorkflowExecution {
    public func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: "WorkflowExecution", recordID: CKRecord.ID(recordName: id))
        record["workflowId"] = workflowId
        record["status"] = status.rawValue
        record["startedAt"] = startedAt
        record["completedAt"] = completedAt
        record["triggeredBy"] = triggeredBy
        record["triggerMethod"] = triggerMethod
        record["errorMessage"] = errorMessage
        
        // Encode complex objects as Data
        if let stepResultsData = try? JSONEncoder().encode(stepResults) {
            record["stepResults"] = stepResultsData
        }
        if let metricsData = try? JSONEncoder().encode(metrics) {
            record["metrics"] = metricsData
        }
        
        return record
    }
    
    public static func from(record: CKRecord) -> WorkflowExecution? {
        guard let workflowId = record["workflowId"] as? String,
              let statusString = record["status"] as? String,
              let status = ExecutionStatus(rawValue: statusString),
              let startedAt = record["startedAt"] as? Date else {
            return nil
        }
        
        let completedAt = record["completedAt"] as? Date
        let triggeredBy = record["triggeredBy"] as? String
        let triggerMethod = record["triggerMethod"] as? String
        let errorMessage = record["errorMessage"] as? String
        
        // Decode complex objects
        var stepResults: [StepResult] = []
        if let stepResultsData = record["stepResults"] as? Data {
            stepResults = (try? JSONDecoder().decode([StepResult].self, from: stepResultsData)) ?? []
        }
        
        var metrics = ExecutionMetrics()
        if let metricsData = record["metrics"] as? Data {
            metrics = (try? JSONDecoder().decode(ExecutionMetrics.self, from: metricsData)) ?? ExecutionMetrics()
        }
        
        return WorkflowExecution(
            id: record.recordID.recordName,
            workflowId: workflowId,
            status: status,
            startedAt: startedAt,
            completedAt: completedAt,
            triggeredBy: triggeredBy,
            triggerMethod: triggerMethod,
            errorMessage: errorMessage,
            stepResults: stepResults,
            metrics: metrics
        )
    }
}
