import Foundation
import CloudKit

// MARK: - Custom Report Models (Phase 4.11+ Business Logic Placeholder)
public struct CustomReport: Identifiable, Codable, Hashable {
    public let id: String
    public var name: String
    public var description: String?
    public var ownerId: String
    public var parserTemplateId: String
    public var reportType: ReportType
    public var dataSourceConnections: [DataSourceConnection]
    public var scheduleConfig: ReportScheduleConfig?
    public var outputFormat: ReportOutputFormat
    public var accessLevel: ReportAccessLevel
    public var tags: [String]
    public var createdAt: Date
    public var lastExecuted: Date?
    public var executionCount: Int
    public var averageExecutionTime: TimeInterval
    public var isActive: Bool
    public var retentionPolicy: RetentionPolicy
    
    public init(
        id: String = UUID().uuidString,
        name: String,
        description: String? = nil,
        ownerId: String,
        parserTemplateId: String,
        reportType: ReportType,
        dataSourceConnections: [DataSourceConnection] = [],
        scheduleConfig: ReportScheduleConfig? = nil,
        outputFormat: ReportOutputFormat = .pdf,
        accessLevel: ReportAccessLevel = .private,
        tags: [String] = [],
        createdAt: Date = Date(),
        lastExecuted: Date? = nil,
        executionCount: Int = 0,
        averageExecutionTime: TimeInterval = 0,
        isActive: Bool = true,
        retentionPolicy: RetentionPolicy = RetentionPolicy()
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.ownerId = ownerId
        self.parserTemplateId = parserTemplateId
        self.reportType = reportType
        self.dataSourceConnections = dataSourceConnections
        self.scheduleConfig = scheduleConfig
        self.outputFormat = outputFormat
        self.accessLevel = accessLevel
        self.tags = tags
        self.createdAt = createdAt
        self.lastExecuted = lastExecuted
        self.executionCount = executionCount
        self.averageExecutionTime = averageExecutionTime
        self.isActive = isActive
        self.retentionPolicy = retentionPolicy
    }
}

// MARK: - Report Enums
public enum ReportType: String, CaseIterable, Codable, Identifiable {
    case salesAnalysis = "SALES_ANALYSIS"
    case performanceMetrics = "PERFORMANCE_METRICS"
    case complianceReport = "COMPLIANCE_REPORT"
    case customDataProcessing = "CUSTOM_DATA_PROCESSING"
    case crossModuleAnalysis = "CROSS_MODULE_ANALYSIS"
    case financialSummary = "FINANCIAL_SUMMARY"
    case auditReport = "AUDIT_REPORT"
    case kpiDashboard = "KPI_DASHBOARD"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .salesAnalysis: return "Sales Analysis"
        case .performanceMetrics: return "Performance Metrics"
        case .complianceReport: return "Compliance Report"
        case .customDataProcessing: return "Custom Data Processing"
        case .crossModuleAnalysis: return "Cross-Module Analysis"
        case .financialSummary: return "Financial Summary"
        case .auditReport: return "Audit Report"
        case .kpiDashboard: return "KPI Dashboard"
        }
    }
}

public enum ReportOutputFormat: String, CaseIterable, Codable, Identifiable {
    case pdf = "PDF"
    case excel = "EXCEL"
    case csv = "CSV"
    case json = "JSON"
    case html = "HTML"
    case xml = "XML"
    
    public var id: String { rawValue }
}

public enum ReportAccessLevel: String, CaseIterable, Codable, Identifiable {
    case `private` = "PRIVATE"
    case team = "TEAM"
    case department = "DEPARTMENT"
    case company = "COMPANY"
    case `public` = "PUBLIC"
    
    public var id: String { rawValue }
}

public enum ExecutionStatus: String, CaseIterable, Codable, Identifiable {
    case queued = "QUEUED"
    case running = "RUNNING"
    case completed = "COMPLETED"
    case failed = "FAILED"
    case cancelled = "CANCELLED"
    case partialSuccess = "PARTIAL_SUCCESS"
    
    public var id: String { rawValue }
}

// MARK: - Supporting Structures
public struct DataSourceConnection: Identifiable, Codable, Hashable {
    public let id: String
    public var name: String
    public var connectionType: DataSourceType
    public var connectionString: String
    public var credentials: [String: String] // Encrypted in production
    public var isActive: Bool
    public var lastTested: Date?
    
    public init(
        id: String = UUID().uuidString,
        name: String,
        connectionType: DataSourceType,
        connectionString: String,
        credentials: [String: String] = [:],
        isActive: Bool = true,
        lastTested: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.connectionType = connectionType
        self.connectionString = connectionString
        self.credentials = credentials
        self.isActive = isActive
        self.lastTested = lastTested
    }
}

public enum DataSourceType: String, CaseIterable, Codable, Identifiable {
    case cloudKit = "CLOUDKIT"
    case coreData = "CORE_DATA"
    case restAPI = "REST_API"
    case graphQL = "GRAPHQL"
    case database = "DATABASE"
    case csv = "CSV"
    case json = "JSON"
    case xml = "XML"
    
    public var id: String { rawValue }
}

public struct ReportScheduleConfig: Codable, Hashable {
    public var isEnabled: Bool
    public var frequency: ScheduleFrequency
    public var startDate: Date
    public var endDate: Date?
    public var timeOfDay: String // Format: "HH:mm"
    public var timezone: String
    public var recipients: [String]
    public var lastRun: Date?
    public var nextRun: Date?
    
    public init(
        isEnabled: Bool = false,
        frequency: ScheduleFrequency = .daily,
        startDate: Date = Date(),
        endDate: Date? = nil,
        timeOfDay: String = "09:00",
        timezone: String = "UTC",
        recipients: [String] = [],
        lastRun: Date? = nil,
        nextRun: Date? = nil
    ) {
        self.isEnabled = isEnabled
        self.frequency = frequency
        self.startDate = startDate
        self.endDate = endDate
        self.timeOfDay = timeOfDay
        self.timezone = timezone
        self.recipients = recipients
        self.lastRun = lastRun
        self.nextRun = nextRun
    }
}

public enum ScheduleFrequency: String, CaseIterable, Codable, Identifiable {
    case hourly = "HOURLY"
    case daily = "DAILY"
    case weekly = "WEEKLY"
    case monthly = "MONTHLY"
    case quarterly = "QUARTERLY"
    case yearly = "YEARLY"
    case custom = "CUSTOM"
    
    public var id: String { rawValue }
}

public struct RetentionPolicy: Codable, Hashable {
    public var retentionDays: Int
    public var maxReports: Int
    public var archiveAfterDays: Int
    public var deleteAfterDays: Int
    
    public init(
        retentionDays: Int = 365,
        maxReports: Int = 1000,
        archiveAfterDays: Int = 90,
        deleteAfterDays: Int = 365
    ) {
        self.retentionDays = retentionDays
        self.maxReports = maxReports
        self.archiveAfterDays = archiveAfterDays
        self.deleteAfterDays = deleteAfterDays
    }
}

// MARK: - Parser Template Model
public struct ParserTemplate: Identifiable, Codable, Hashable {
    public let id: String
    public var name: String
    public var description: String?
    public var version: String
    public var pythonCode: String
    public var inputSchema: ReportSchema
    public var outputSchema: ReportSchema
    public var validationRules: [ValidationRule]
    public var testDataSets: [TestDataSet]
    public var createdBy: String
    public var createdAt: Date
    public var lastModified: Date
    public var isPublic: Bool
    public var downloadCount: Int
    public var rating: Double
    public var tags: [String]
    
    public init(
        id: String = UUID().uuidString,
        name: String,
        description: String? = nil,
        version: String = "1.0.0",
        pythonCode: String = "",
        inputSchema: ReportSchema = ReportSchema(),
        outputSchema: ReportSchema = ReportSchema(),
        validationRules: [ValidationRule] = [],
        testDataSets: [TestDataSet] = [],
        createdBy: String,
        createdAt: Date = Date(),
        lastModified: Date = Date(),
        isPublic: Bool = false,
        downloadCount: Int = 0,
        rating: Double = 0.0,
        tags: [String] = []
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.version = version
        self.pythonCode = pythonCode
        self.inputSchema = inputSchema
        self.outputSchema = outputSchema
        self.validationRules = validationRules
        self.testDataSets = testDataSets
        self.createdBy = createdBy
        self.createdAt = createdAt
        self.lastModified = lastModified
        self.isPublic = isPublic
        self.downloadCount = downloadCount
        self.rating = rating
        self.tags = tags
    }
}

public struct ReportSchema: Codable, Hashable {
    public var fields: [SchemaField]
    public var version: String
    public var description: String?
    
    public init(
        fields: [SchemaField] = [],
        version: String = "1.0",
        description: String? = nil
    ) {
        self.fields = fields
        self.version = version
        self.description = description
    }
}

public struct SchemaField: Identifiable, Codable, Hashable {
    public let id: String
    public var name: String
    public var type: FieldType
    public var isRequired: Bool
    public var defaultValue: String?
    public var validation: String?
    
    public init(
        id: String = UUID().uuidString,
        name: String,
        type: FieldType,
        isRequired: Bool = false,
        defaultValue: String? = nil,
        validation: String? = nil
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.isRequired = isRequired
        self.defaultValue = defaultValue
        self.validation = validation
    }
}

public enum FieldType: String, CaseIterable, Codable, Identifiable {
    case string = "STRING"
    case integer = "INTEGER"
    case double = "DOUBLE"
    case boolean = "BOOLEAN"
    case date = "DATE"
    case array = "ARRAY"
    case object = "OBJECT"
    
    public var id: String { rawValue }
}

public struct ValidationRule: Identifiable, Codable, Hashable {
    public let id: String
    public var name: String
    public var rule: String
    public var errorMessage: String
    public var severity: ValidationSeverity
    
    public init(
        id: String = UUID().uuidString,
        name: String,
        rule: String,
        errorMessage: String,
        severity: ValidationSeverity = .error
    ) {
        self.id = id
        self.name = name
        self.rule = rule
        self.errorMessage = errorMessage
        self.severity = severity
    }
}

public enum ValidationSeverity: String, CaseIterable, Codable, Identifiable {
    case info = "INFO"
    case warning = "WARNING"
    case error = "ERROR"
    case critical = "CRITICAL"
    
    public var id: String { rawValue }
}

public struct TestDataSet: Identifiable, Codable, Hashable {
    public let id: String
    public var name: String
    public var inputData: String
    public var expectedOutput: String
    public var description: String?
    
    public init(
        id: String = UUID().uuidString,
        name: String,
        inputData: String,
        expectedOutput: String,
        description: String? = nil
    ) {
        self.id = id
        self.name = name
        self.inputData = inputData
        self.expectedOutput = expectedOutput
        self.description = description
    }
}

// MARK: - Report Execution Log
public struct ReportExecutionLog: Identifiable, Codable, Hashable {
    public let id: String
    public var reportId: String
    public var executionStartTime: Date
    public var executionEndTime: Date?
    public var status: ExecutionStatus
    public var inputFileMetadata: FileMetadata
    public var outputFileMetadata: FileMetadata?
    public var recordsProcessed: Int
    public var recordsValid: Int
    public var recordsRejected: Int
    public var errorMessages: [ExecutionError]
    public var performanceMetrics: ExecutionMetrics
    public var triggeredBy: String
    public var triggeredMethod: TriggerMethod
    
    public init(
        id: String = UUID().uuidString,
        reportId: String,
        executionStartTime: Date = Date(),
        executionEndTime: Date? = nil,
        status: ExecutionStatus = .queued,
        inputFileMetadata: FileMetadata = FileMetadata(),
        outputFileMetadata: FileMetadata? = nil,
        recordsProcessed: Int = 0,
        recordsValid: Int = 0,
        recordsRejected: Int = 0,
        errorMessages: [ExecutionError] = [],
        performanceMetrics: ExecutionMetrics = ExecutionMetrics(),
        triggeredBy: String,
        triggeredMethod: TriggerMethod = .manual
    ) {
        self.id = id
        self.reportId = reportId
        self.executionStartTime = executionStartTime
        self.executionEndTime = executionEndTime
        self.status = status
        self.inputFileMetadata = inputFileMetadata
        self.outputFileMetadata = outputFileMetadata
        self.recordsProcessed = recordsProcessed
        self.recordsValid = recordsValid
        self.recordsRejected = recordsRejected
        self.errorMessages = errorMessages
        self.performanceMetrics = performanceMetrics
        self.triggeredBy = triggeredBy
        self.triggeredMethod = triggeredMethod
    }
}

public struct FileMetadata: Codable, Hashable {
    public var fileName: String
    public var fileSize: Int64
    public var mimeType: String
    public var checksum: String
    public var createdAt: Date
    
    public init(
        fileName: String = "",
        fileSize: Int64 = 0,
        mimeType: String = "",
        checksum: String = "",
        createdAt: Date = Date()
    ) {
        self.fileName = fileName
        self.fileSize = fileSize
        self.mimeType = mimeType
        self.checksum = checksum
        self.createdAt = createdAt
    }
}

public struct ExecutionError: Identifiable, Codable, Hashable {
    public let id: String
    public var errorCode: String
    public var errorMessage: String
    public var severity: ValidationSeverity
    public var lineNumber: Int?
    public var fieldName: String?
    public var timestamp: Date
    
    public init(
        id: String = UUID().uuidString,
        errorCode: String,
        errorMessage: String,
        severity: ValidationSeverity = .error,
        lineNumber: Int? = nil,
        fieldName: String? = nil,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.errorCode = errorCode
        self.errorMessage = errorMessage
        self.severity = severity
        self.lineNumber = lineNumber
        self.fieldName = fieldName
        self.timestamp = timestamp
    }
}

public struct ExecutionMetrics: Codable, Hashable {
    public var cpuTime: TimeInterval
    public var memoryUsage: Int64
    public var ioOperations: Int
    public var networkCalls: Int
    public var processingTime: TimeInterval
    
    public init(
        cpuTime: TimeInterval = 0,
        memoryUsage: Int64 = 0,
        ioOperations: Int = 0,
        networkCalls: Int = 0,
        processingTime: TimeInterval = 0
    ) {
        self.cpuTime = cpuTime
        self.memoryUsage = memoryUsage
        self.ioOperations = ioOperations
        self.networkCalls = networkCalls
        self.processingTime = processingTime
    }
}

public enum TriggerMethod: String, CaseIterable, Codable, Identifiable {
    case manual = "MANUAL"
    case scheduled = "SCHEDULED"
    case webhook = "WEBHOOK"
    case api = "API"
    case event = "EVENT"
    
    public var id: String { rawValue }
}

// MARK: - CloudKit Extensions (Placeholder)
extension CustomReport {
    public func toRecord() -> CKRecord {
        let record = CKRecord(recordType: "CustomReport", recordID: CKRecord.ID(recordName: id))
        record["name"] = name
        record["description"] = description
        record["ownerId"] = ownerId
        record["parserTemplateId"] = parserTemplateId
        record["reportType"] = reportType.rawValue
        record["outputFormat"] = outputFormat.rawValue
        record["accessLevel"] = accessLevel.rawValue
        record["tags"] = tags
        record["createdAt"] = createdAt
        record["lastExecuted"] = lastExecuted
        record["executionCount"] = executionCount
        record["averageExecutionTime"] = averageExecutionTime
        record["isActive"] = isActive ? 1 : 0
        
        // Store complex objects as JSON (placeholder implementation)
        if let data = try? JSONEncoder().encode(dataSourceConnections) {
            record["dataSourceConnections"] = String(data: data, encoding: .utf8)
        }
        if let scheduleConfig = scheduleConfig,
           let data = try? JSONEncoder().encode(scheduleConfig) {
            record["scheduleConfig"] = String(data: data, encoding: .utf8)
        }
        if let data = try? JSONEncoder().encode(retentionPolicy) {
            record["retentionPolicy"] = String(data: data, encoding: .utf8)
        }
        
        return record
    }
    
    public static func from(record: CKRecord) -> CustomReport? {
        guard let name = record["name"] as? String,
              let ownerId = record["ownerId"] as? String,
              let parserTemplateId = record["parserTemplateId"] as? String,
              let reportTypeString = record["reportType"] as? String,
              let reportType = ReportType(rawValue: reportTypeString) else {
            return nil
        }
        
        let outputFormat = ReportOutputFormat(rawValue: record["outputFormat"] as? String ?? "PDF") ?? .pdf
        let accessLevel = ReportAccessLevel(rawValue: record["accessLevel"] as? String ?? "PRIVATE") ?? .private
        let isActive = (record["isActive"] as? Int) == 1
        
        // Decode complex objects (placeholder implementation)
        var dataSourceConnections: [DataSourceConnection] = []
        if let connectionsData = record["dataSourceConnections"] as? String,
           let data = connectionsData.data(using: .utf8) {
            dataSourceConnections = (try? JSONDecoder().decode([DataSourceConnection].self, from: data)) ?? []
        }
        
        var scheduleConfig: ReportScheduleConfig?
        if let scheduleData = record["scheduleConfig"] as? String,
           let data = scheduleData.data(using: .utf8) {
            scheduleConfig = try? JSONDecoder().decode(ReportScheduleConfig.self, from: data)
        }
        
        var retentionPolicy = RetentionPolicy()
        if let retentionData = record["retentionPolicy"] as? String,
           let data = retentionData.data(using: .utf8) {
            retentionPolicy = (try? JSONDecoder().decode(RetentionPolicy.self, from: data)) ?? RetentionPolicy()
        }
        
        return CustomReport(
            id: record.recordID.recordName,
            name: name,
            description: record["description"] as? String,
            ownerId: ownerId,
            parserTemplateId: parserTemplateId,
            reportType: reportType,
            dataSourceConnections: dataSourceConnections,
            scheduleConfig: scheduleConfig,
            outputFormat: outputFormat,
            accessLevel: accessLevel,
            tags: record["tags"] as? [String] ?? [],
            createdAt: record["createdAt"] as? Date ?? Date(),
            lastExecuted: record["lastExecuted"] as? Date,
            executionCount: record["executionCount"] as? Int ?? 0,
            averageExecutionTime: record["averageExecutionTime"] as? TimeInterval ?? 0,
            isActive: isActive,
            retentionPolicy: retentionPolicy
        )
    }
}
