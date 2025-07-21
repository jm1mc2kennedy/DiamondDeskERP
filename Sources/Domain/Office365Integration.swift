import Foundation
import CloudKit

// MARK: - Office365 Integration Models (Phase 4.13+ Implementation)
public struct Office365IntegrationModel: Identifiable, Codable, Hashable {t Foundation
import CloudKit

// MARK: - Office 365 Integration Models (Phase 4.13+ Placeholder)
public struct Office365IntegrationModel: Identifiable, Codable, Hashable {
    public let id: String
    public var userId: String
    public var tenantId: String
    public var applicationId: String
    public var authenticationTokens: Office365TokenSet
    public var enabledServices: [Office365Service]
    public var syncConfiguration: SyncConfiguration
    public var lastSyncStatus: SyncStatus
    public var errorHistory: [IntegrationError]
    public var usageStatistics: UsageStatistics
    public var permissionGrants: [PermissionGrant]
    public var isActive: Bool
    public var createdAt: Date
    public var lastSyncAt: Date?
    
    public init(
        id: String = UUID().uuidString,
        userId: String,
        tenantId: String,
        applicationId: String,
        authenticationTokens: Office365TokenSet = Office365TokenSet(),
        enabledServices: [Office365Service] = [],
        syncConfiguration: SyncConfiguration = SyncConfiguration(),
        lastSyncStatus: SyncStatus = .pending,
        errorHistory: [IntegrationError] = [],
        usageStatistics: UsageStatistics = UsageStatistics(),
        permissionGrants: [PermissionGrant] = [],
        isActive: Bool = true,
        createdAt: Date = Date(),
        lastSyncAt: Date? = nil
    ) {
        self.id = id
        self.userId = userId
        self.tenantId = tenantId
        self.applicationId = applicationId
        self.authenticationTokens = authenticationTokens
        self.enabledServices = enabledServices
        self.syncConfiguration = syncConfiguration
        self.lastSyncStatus = lastSyncStatus
        self.errorHistory = errorHistory
        self.usageStatistics = usageStatistics
        self.permissionGrants = permissionGrants
        self.isActive = isActive
        self.createdAt = createdAt
        self.lastSyncAt = lastSyncAt
    }
}

public enum Office365Service: String, CaseIterable, Codable, Identifiable {
    case outlook = "OUTLOOK"
    case sharePoint = "SHAREPOINT"
    case teams = "TEAMS"
    case powerBI = "POWER_BI"
    case oneDrive = "ONEDRIVE"
    case planner = "PLANNER"
    case dynamics365 = "DYNAMICS_365"
    case calendar = "CALENDAR"
    case contacts = "CONTACTS"
    case tasks = "TASKS"
    case notes = "NOTES"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .outlook: return "Outlook"
        case .sharePoint: return "SharePoint"
        case .teams: return "Teams"
        case .powerBI: return "Power BI"
        case .oneDrive: return "OneDrive"
        case .planner: return "Planner"
        case .dynamics365: return "Dynamics 365"
        case .calendar: return "Calendar"
        case .contacts: return "Contacts"
        case .tasks: return "Tasks"
        case .notes: return "Notes"
        }
    }
}

public struct Office365TokenSet: Codable, Hashable {
    public var accessToken: String
    public var refreshToken: String
    public var idToken: String?
    public var tokenType: String
    public var expiresAt: Date
    public var scope: [String]
    public var lastRefreshed: Date
    
    public init(
        accessToken: String = "",
        refreshToken: String = "",
        idToken: String? = nil,
        tokenType: String = "Bearer",
        expiresAt: Date = Date(),
        scope: [String] = [],
        lastRefreshed: Date = Date()
    ) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.idToken = idToken
        self.tokenType = tokenType
        self.expiresAt = expiresAt
        self.scope = scope
        self.lastRefreshed = lastRefreshed
    }
}

public struct SyncConfiguration: Codable, Hashable {
    public var autoSync: Bool
    public var syncInterval: TimeInterval
    public var maxRetries: Int
    public var syncDirection: SyncDirection
    public var conflictResolution: ConflictResolution
    public var dataFilters: [String: String]
    
    public init(
        autoSync: Bool = true,
        syncInterval: TimeInterval = 3600, // 1 hour
        maxRetries: Int = 3,
        syncDirection: SyncDirection = .bidirectional,
        conflictResolution: ConflictResolution = .manual,
        dataFilters: [String: String] = [:]
    ) {
        self.autoSync = autoSync
        self.syncInterval = syncInterval
        self.maxRetries = maxRetries
        self.syncDirection = syncDirection
        self.conflictResolution = conflictResolution
        self.dataFilters = dataFilters
    }
}

public enum SyncDirection: String, CaseIterable, Codable, Identifiable {
    case toOffice365 = "TO_OFFICE365"
    case fromOffice365 = "FROM_OFFICE365"
    case bidirectional = "BIDIRECTIONAL"
    
    public var id: String { rawValue }
}

public enum ConflictResolution: String, CaseIterable, Codable, Identifiable {
    case manual = "MANUAL"
    case newestWins = "NEWEST_WINS"
    case office365Wins = "OFFICE365_WINS"
    case localWins = "LOCAL_WINS"
    case merge = "MERGE"
    
    public var id: String { rawValue }
}

public enum SyncStatus: String, CaseIterable, Codable, Identifiable {
    case pending = "PENDING"
    case running = "RUNNING"
    case completed = "COMPLETED"
    case failed = "FAILED"
    case paused = "PAUSED"
    case cancelled = "CANCELLED"
    
    public var id: String { rawValue }
}

public struct IntegrationError: Identifiable, Codable, Hashable {
    public let id: String
    public var errorCode: String
    public var errorMessage: String
    public var service: Office365Service
    public var severity: ErrorSeverity
    public var timestamp: Date
    public var retryCount: Int
    public var isResolved: Bool
    
    public init(
        id: String = UUID().uuidString,
        errorCode: String,
        errorMessage: String,
        service: Office365Service,
        severity: ErrorSeverity = .error,
        timestamp: Date = Date(),
        retryCount: Int = 0,
        isResolved: Bool = false
    ) {
        self.id = id
        self.errorCode = errorCode
        self.errorMessage = errorMessage
        self.service = service
        self.severity = severity
        self.timestamp = timestamp
        self.retryCount = retryCount
        self.isResolved = isResolved
    }
}

public enum ErrorSeverity: String, CaseIterable, Codable, Identifiable {
    case info = "INFO"
    case warning = "WARNING"
    case error = "ERROR"
    case critical = "CRITICAL"
    
    public var id: String { rawValue }
}

public struct UsageStatistics: Codable, Hashable {
    public var totalSyncs: Int
    public var successfulSyncs: Int
    public var failedSyncs: Int
    public var lastSyncDuration: TimeInterval
    public var averageSyncDuration: TimeInterval
    public var dataTransferred: Int64 // bytes
    public var recordsSynced: Int
    
    public init(
        totalSyncs: Int = 0,
        successfulSyncs: Int = 0,
        failedSyncs: Int = 0,
        lastSyncDuration: TimeInterval = 0,
        averageSyncDuration: TimeInterval = 0,
        dataTransferred: Int64 = 0,
        recordsSynced: Int = 0
    ) {
        self.totalSyncs = totalSyncs
        self.successfulSyncs = successfulSyncs
        self.failedSyncs = failedSyncs
        self.lastSyncDuration = lastSyncDuration
        self.averageSyncDuration = averageSyncDuration
        self.dataTransferred = dataTransferred
        self.recordsSynced = recordsSynced
    }
}

public struct PermissionGrant: Identifiable, Codable, Hashable {
    public let id: String
    public var permission: String
    public var scope: String
    public var grantedAt: Date
    public var expiresAt: Date?
    public var isActive: Bool
    
    public init(
        id: String = UUID().uuidString,
        permission: String,
        scope: String,
        grantedAt: Date = Date(),
        expiresAt: Date? = nil,
        isActive: Bool = true
    ) {
        self.id = id
        self.permission = permission
        self.scope = scope
        self.grantedAt = grantedAt
        self.expiresAt = expiresAt
        self.isActive = isActive
    }
}

// MARK: - SharePoint Resource Model
public struct SharePointResource: Identifiable, Codable, Hashable {
    public let id: String
    public var userId: String
    public var siteId: String
    public var driveId: String
    public var itemId: String
    public var itemPath: String
    public var itemName: String
    public var itemType: SharePointItemType
    public var mimeType: String
    public var fileSize: Int64?
    public var lastModifiedBy: String
    public var lastModifiedAt: Date
    public var accessLevel: SharePointAccessLevel
    public var syncStatus: SyncStatus
    public var localCachePath: String?
    public var versionInfo: SharePointVersionInfo
    public var isShared: Bool
    public var sharePermissions: [SharePermission]
    
    public init(
        id: String = UUID().uuidString,
        userId: String,
        siteId: String,
        driveId: String,
        itemId: String,
        itemPath: String,
        itemName: String,
        itemType: SharePointItemType,
        mimeType: String = "",
        fileSize: Int64? = nil,
        lastModifiedBy: String,
        lastModifiedAt: Date = Date(),
        accessLevel: SharePointAccessLevel = .read,
        syncStatus: SyncStatus = .pending,
        localCachePath: String? = nil,
        versionInfo: SharePointVersionInfo = SharePointVersionInfo(),
        isShared: Bool = false,
        sharePermissions: [SharePermission] = []
    ) {
        self.id = id
        self.userId = userId
        self.siteId = siteId
        self.driveId = driveId
        self.itemId = itemId
        self.itemPath = itemPath
        self.itemName = itemName
        self.itemType = itemType
        self.mimeType = mimeType
        self.fileSize = fileSize
        self.lastModifiedBy = lastModifiedBy
        self.lastModifiedAt = lastModifiedAt
        self.accessLevel = accessLevel
        self.syncStatus = syncStatus
        self.localCachePath = localCachePath
        self.versionInfo = versionInfo
        self.isShared = isShared
        self.sharePermissions = sharePermissions
    }
}

public enum SharePointItemType: String, CaseIterable, Codable, Identifiable {
    case folder = "FOLDER"
    case file = "FILE"
    case list = "LIST"
    case listItem = "LIST_ITEM"
    case site = "SITE"
    case drive = "DRIVE"
    case notebook = "NOTEBOOK"
    case page = "PAGE"
    
    public var id: String { rawValue }
}

public enum SharePointAccessLevel: String, CaseIterable, Codable, Identifiable {
    case read = "READ"
    case write = "WRITE"
    case admin = "ADMIN"
    case owner = "OWNER"
    case contributor = "CONTRIBUTOR"
    case visitor = "VISITOR"
    
    public var id: String { rawValue }
}

public struct SharePointVersionInfo: Codable, Hashable {
    public var currentVersion: String
    public var versionHistory: [VersionEntry]
    public var isLatest: Bool
    public var checkoutUser: String?
    
    public init(
        currentVersion: String = "1.0",
        versionHistory: [VersionEntry] = [],
        isLatest: Bool = true,
        checkoutUser: String? = nil
    ) {
        self.currentVersion = currentVersion
        self.versionHistory = versionHistory
        self.isLatest = isLatest
        self.checkoutUser = checkoutUser
    }
}

public struct VersionEntry: Identifiable, Codable, Hashable {
    public let id: String
    public var version: String
    public var createdBy: String
    public var createdAt: Date
    public var comment: String?
    public var size: Int64
    
    public init(
        id: String = UUID().uuidString,
        version: String,
        createdBy: String,
        createdAt: Date = Date(),
        comment: String? = nil,
        size: Int64 = 0
    ) {
        self.id = id
        self.version = version
        self.createdBy = createdBy
        self.createdAt = createdAt
        self.comment = comment
        self.size = size
    }
}

public struct SharePermission: Identifiable, Codable, Hashable {
    public let id: String
    public var userId: String
    public var permission: SharePointAccessLevel
    public var grantedBy: String
    public var grantedAt: Date
    public var expiresAt: Date?
    
    public init(
        id: String = UUID().uuidString,
        userId: String,
        permission: SharePointAccessLevel,
        grantedBy: String,
        grantedAt: Date = Date(),
        expiresAt: Date? = nil
    ) {
        self.id = id
        self.userId = userId
        self.permission = permission
        self.grantedBy = grantedBy
        self.grantedAt = grantedAt
        self.expiresAt = expiresAt
    }
}

// MARK: - Outlook Integration Model
public struct OutlookIntegration: Identifiable, Codable, Hashable {
    public let id: String
    public var userId: String
    public var mailboxId: String
    public var calendarSyncEnabled: Bool
    public var emailSyncEnabled: Bool
    public var contactSyncEnabled: Bool
    public var taskSyncEnabled: Bool
    public var syncFilters: OutlookSyncFilters
    public var lastCalendarSync: Date?
    public var lastEmailSync: Date?
    public var lastContactSync: Date?
    public var syncErrors: [OutlookSyncError]
    public var performanceMetrics: OutlookMetrics
    
    public init(
        id: String = UUID().uuidString,
        userId: String,
        mailboxId: String,
        calendarSyncEnabled: Bool = true,
        emailSyncEnabled: Bool = false,
        contactSyncEnabled: Bool = true,
        taskSyncEnabled: Bool = true,
        syncFilters: OutlookSyncFilters = OutlookSyncFilters(),
        lastCalendarSync: Date? = nil,
        lastEmailSync: Date? = nil,
        lastContactSync: Date? = nil,
        syncErrors: [OutlookSyncError] = [],
        performanceMetrics: OutlookMetrics = OutlookMetrics()
    ) {
        self.id = id
        self.userId = userId
        self.mailboxId = mailboxId
        self.calendarSyncEnabled = calendarSyncEnabled
        self.emailSyncEnabled = emailSyncEnabled
        self.contactSyncEnabled = contactSyncEnabled
        self.taskSyncEnabled = taskSyncEnabled
        self.syncFilters = syncFilters
        self.lastCalendarSync = lastCalendarSync
        self.lastEmailSync = lastEmailSync
        self.lastContactSync = lastContactSync
        self.syncErrors = syncErrors
        self.performanceMetrics = performanceMetrics
    }
}

public struct OutlookSyncFilters: Codable, Hashable {
    public var calendarFilters: [String: String]
    public var emailFilters: [String: String]
    public var contactFilters: [String: String]
    public var taskFilters: [String: String]
    public var dateRange: DateInterval?
    
    public init(
        calendarFilters: [String: String] = [:],
        emailFilters: [String: String] = [:],
        contactFilters: [String: String] = [:],
        taskFilters: [String: String] = [:],
        dateRange: DateInterval? = nil
    ) {
        self.calendarFilters = calendarFilters
        self.emailFilters = emailFilters
        self.contactFilters = contactFilters
        self.taskFilters = taskFilters
        self.dateRange = dateRange
    }
}

public struct OutlookSyncError: Identifiable, Codable, Hashable {
    public let id: String
    public var service: OutlookService
    public var errorCode: String
    public var errorMessage: String
    public var timestamp: Date
    public var itemId: String?
    
    public init(
        id: String = UUID().uuidString,
        service: OutlookService,
        errorCode: String,
        errorMessage: String,
        timestamp: Date = Date(),
        itemId: String? = nil
    ) {
        self.id = id
        self.service = service
        self.errorCode = errorCode
        self.errorMessage = errorMessage
        self.timestamp = timestamp
        self.itemId = itemId
    }
}

public enum OutlookService: String, CaseIterable, Codable, Identifiable {
    case calendar = "CALENDAR"
    case email = "EMAIL"
    case contacts = "CONTACTS"
    case tasks = "TASKS"
    
    public var id: String { rawValue }
}

public struct OutlookMetrics: Codable, Hashable {
    public var calendarItems: Int
    public var emailItems: Int
    public var contactItems: Int
    public var taskItems: Int
    public var totalSyncTime: TimeInterval
    public var lastPerformanceCheck: Date
    
    public init(
        calendarItems: Int = 0,
        emailItems: Int = 0,
        contactItems: Int = 0,
        taskItems: Int = 0,
        totalSyncTime: TimeInterval = 0,
        lastPerformanceCheck: Date = Date()
    ) {
        self.calendarItems = calendarItems
        self.emailItems = emailItems
        self.contactItems = contactItems
        self.taskItems = taskItems
        self.totalSyncTime = totalSyncTime
        self.lastPerformanceCheck = lastPerformanceCheck
    }
}

// MARK: - CloudKit Extensions (Placeholder)
extension Office365IntegrationModel {
    public func toRecord() -> CKRecord {
        let record = CKRecord(recordType: "Office365Integration", recordID: CKRecord.ID(recordName: id))
        record["userId"] = userId
        record["tenantId"] = tenantId
        record["applicationId"] = applicationId
        record["isActive"] = isActive ? 1 : 0
        record["createdAt"] = createdAt
        record["lastSyncAt"] = lastSyncAt
        record["lastSyncStatus"] = lastSyncStatus.rawValue
        
        // Store arrays as comma-separated strings for CloudKit compatibility
        record["enabledServices"] = enabledServices.map { $0.rawValue }.joined(separator: ",")
        
        // Store complex objects as JSON (encrypted for tokens in production)
        if let data = try? JSONEncoder().encode(authenticationTokens) {
            record["authenticationTokens"] = String(data: data, encoding: .utf8)
        }
        if let data = try? JSONEncoder().encode(syncConfiguration) {
            record["syncConfiguration"] = String(data: data, encoding: .utf8)
        }
        if let data = try? JSONEncoder().encode(errorHistory) {
            record["errorHistory"] = String(data: data, encoding: .utf8)
        }
        if let data = try? JSONEncoder().encode(usageStatistics) {
            record["usageStatistics"] = String(data: data, encoding: .utf8)
        }
        if let data = try? JSONEncoder().encode(permissionGrants) {
            record["permissionGrants"] = String(data: data, encoding: .utf8)
        }
        
        return record
    }
    
    public static func from(record: CKRecord) -> Office365IntegrationModel? {
        guard let userId = record["userId"] as? String,
              let tenantId = record["tenantId"] as? String,
              let applicationId = record["applicationId"] as? String else {
            return nil
        }
        
        let isActive = (record["isActive"] as? Int) == 1
        let lastSyncStatus = SyncStatus(rawValue: record["lastSyncStatus"] as? String ?? "PENDING") ?? .pending
        
        // Parse enabled services
        var enabledServices: [Office365Service] = []
        if let servicesString = record["enabledServices"] as? String,
           !servicesString.isEmpty {
            enabledServices = servicesString.components(separatedBy: ",").compactMap { Office365Service(rawValue: $0) }
        }
        
        // Decode complex objects
        var authenticationTokens = Office365TokenSet()
        if let tokensData = record["authenticationTokens"] as? String,
           let data = tokensData.data(using: .utf8) {
            authenticationTokens = (try? JSONDecoder().decode(Office365TokenSet.self, from: data)) ?? Office365TokenSet()
        }
        
        var syncConfiguration = SyncConfiguration()
        if let syncData = record["syncConfiguration"] as? String,
           let data = syncData.data(using: .utf8) {
            syncConfiguration = (try? JSONDecoder().decode(SyncConfiguration.self, from: data)) ?? SyncConfiguration()
        }
        
        var errorHistory: [IntegrationError] = []
        if let errorData = record["errorHistory"] as? String,
           let data = errorData.data(using: .utf8) {
            errorHistory = (try? JSONDecoder().decode([IntegrationError].self, from: data)) ?? []
        }
        
        var usageStatistics = UsageStatistics()
        if let statsData = record["usageStatistics"] as? String,
           let data = statsData.data(using: .utf8) {
            usageStatistics = (try? JSONDecoder().decode(UsageStatistics.self, from: data)) ?? UsageStatistics()
        }
        
        var permissionGrants: [PermissionGrant] = []
        if let grantsData = record["permissionGrants"] as? String,
           let data = grantsData.data(using: .utf8) {
            permissionGrants = (try? JSONDecoder().decode([PermissionGrant].self, from: data)) ?? []
        }
        
        return Office365IntegrationModel(
            id: record.recordID.recordName,
            userId: userId,
            tenantId: tenantId,
            applicationId: applicationId,
            authenticationTokens: authenticationTokens,
            enabledServices: enabledServices,
            syncConfiguration: syncConfiguration,
            lastSyncStatus: lastSyncStatus,
            errorHistory: errorHistory,
            usageStatistics: usageStatistics,
            permissionGrants: permissionGrants,
            isActive: isActive,
            createdAt: record["createdAt"] as? Date ?? Date(),
            lastSyncAt: record["lastSyncAt"] as? Date
        )
    }
}
