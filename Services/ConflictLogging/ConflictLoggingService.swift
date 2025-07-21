import Foundation
import CloudKit
import OSLog

/// CloudKit conflict detection and logging system
/// Implements comprehensive conflict tracking, resolution strategies, and audit trails
/// Provides admin-only conflict viewer and automated conflict resolution
@MainActor
class ConflictLoggingService: ObservableObject {
    
    static let shared = ConflictLoggingService()
    
    @Published var activeConflicts: [ConflictLog] = []
    @Published var conflictStatistics: ConflictStatistics = ConflictStatistics()
    @Published var isLoggingEnabled: Bool = true
    
    private let database: CKDatabase
    let logger = Logger(subsystem: "DiamondDeskERP", category: "ConflictLogging")
    private let conflictQueue = DispatchQueue(label: "conflict.logging", qos: .utility)
    
    // Conflict resolution strategies
    enum ConflictResolutionStrategy: String, CaseIterable {
        case clientWins = "CLIENT_WINS"
        case serverWins = "SERVER_WINS" 
        case lastWriterWins = "LAST_WRITER_WINS"
        case manualResolution = "MANUAL_RESOLUTION"
        case mergeFields = "MERGE_FIELDS"
        case versionBased = "VERSION_BASED"
    }
    
    // Conflict severity levels
    enum ConflictSeverity: String, CaseIterable {
        case critical = "CRITICAL"     // Data loss risk
        case high = "HIGH"             // Business logic impact
        case medium = "MEDIUM"         // User experience impact
        case low = "LOW"               // Minor inconsistency
    }
    
    private init() {
        self.database = CKContainer.default().privateCloudKitDatabase
        setupConflictMonitoring()
    }
    
    // MARK: - Conflict Detection
    
    /// Detects and logs CloudKit record conflicts
    func detectConflict(
        localRecord: CKRecord,
        serverRecord: CKRecord,
        operation: String
    ) async {
        let conflictLog = ConflictLog(
            localRecord: localRecord,
            serverRecord: serverRecord,
            operation: operation,
            detectedAt: Date(),
            strategy: determineResolutionStrategy(local: localRecord, server: serverRecord),
            severity: calculateConflictSeverity(local: localRecord, server: serverRecord)
        )
        
        await logConflict(conflictLog)
        await analyzeConflictPattern(conflictLog)
    }
    
    /// Detects conflicts during CloudKit save operations
    func handleSaveConflict(
        error: CKError,
        record: CKRecord,
        operation: String
    ) async {
        guard let conflictError = error as? CKError,
              conflictError.code == .serverRecordChanged,
              let serverRecord = conflictError.userInfo[CKRecordChangedErrorServerRecordKey] as? CKRecord else {
            return
        }
        
        await detectConflict(
            localRecord: record,
            serverRecord: serverRecord,
            operation: operation
        )
    }
    
    /// Detects conflicts during CloudKit fetch operations
    func handleFetchConflict(
        localRecord: CKRecord,
        fetchedRecord: CKRecord,
        operation: String
    ) async {
        // Compare modification dates and values to detect conflicts
        if localRecord.modificationDate != fetchedRecord.modificationDate {
            let hasValueConflicts = detectValueConflicts(
                local: localRecord,
                remote: fetchedRecord
            )
            
            if hasValueConflicts {
                await detectConflict(
                    localRecord: localRecord,
                    serverRecord: fetchedRecord,
                    operation: operation
                )
            }
        }
    }
    
    // MARK: - Conflict Resolution
    
    /// Resolves conflict using specified strategy
    func resolveConflict(
        conflictId: UUID,
        strategy: ConflictResolutionStrategy,
        customResolution: [String: Any]? = nil
    ) async throws -> CKRecord {
        
        guard let conflict = activeConflicts.first(where: { $0.id == conflictId }) else {
            throw ConflictLoggingError.conflictNotFound
        }
        
        let resolvedRecord: CKRecord
        
        switch strategy {
        case .clientWins:
            resolvedRecord = conflict.localRecord
            
        case .serverWins:
            resolvedRecord = conflict.serverRecord
            
        case .lastWriterWins:
            resolvedRecord = conflict.localRecord.modificationDate ?? Date() > 
                           conflict.serverRecord.modificationDate ?? Date() 
                           ? conflict.localRecord : conflict.serverRecord
            
        case .mergeFields:
            resolvedRecord = try mergeConflictedFields(
                local: conflict.localRecord,
                server: conflict.serverRecord
            )
            
        case .versionBased:
            resolvedRecord = try resolveVersionBasedConflict(
                local: conflict.localRecord,
                server: conflict.serverRecord
            )
            
        case .manualResolution:
            guard let customData = customResolution else {
                throw ConflictLoggingError.invalidResolution
            }
            resolvedRecord = try applyCustomResolution(
                conflict: conflict,
                resolution: customData
            )
        }
        
        // Update conflict log with resolution
        await updateConflictResolution(
            conflictId: conflictId,
            strategy: strategy,
            resolvedRecord: resolvedRecord
        )
        
        // Remove from active conflicts
        activeConflicts.removeAll { $0.id == conflictId }
        
        logger.info("Conflict resolved: \(conflictId) using \(strategy.rawValue)")
        
        return resolvedRecord
    }
    
    // MARK: - Conflict Analysis
    
    private func determineResolutionStrategy(
        local: CKRecord,
        server: CKRecord
    ) -> ConflictResolutionStrategy {
        
        // Analyze conflict pattern and suggest strategy
        let localModDate = local.modificationDate ?? Date.distantPast
        let serverModDate = server.modificationDate ?? Date.distantPast
        
        let timeDifference = abs(localModDate.timeIntervalSince(serverModDate))
        
        if timeDifference < 60 { // Within 1 minute
            return .mergeFields
        } else if localModDate > serverModDate {
            return .clientWins
        } else {
            return .serverWins
        }
    }
    
    private func calculateConflictSeverity(
        local: CKRecord,
        server: CKRecord
    ) -> ConflictSeverity {
        
        var conflictScore = 0
        
        // Check for critical field conflicts
        let criticalFields = ["status", "amount", "priority", "assignee"]
        for field in criticalFields {
            if local[field] != nil && server[field] != nil && local[field] != server[field] {
                conflictScore += 3
            }
        }
        
        // Check for data type conflicts
        if local.recordType != server.recordType {
            conflictScore += 5
        }
        
        // Check for relationship conflicts
        let relationshipFields = ["clientID", "taskID", "ticketID"]
        for field in relationshipFields {
            if local[field] != nil && server[field] != nil && local[field] != server[field] {
                conflictScore += 2
            }
        }
        
        switch conflictScore {
        case 0...1:
            return .low
        case 2...4:
            return .medium
        case 5...7:
            return .high
        default:
            return .critical
        }
    }
    
    private func detectValueConflicts(local: CKRecord, remote: CKRecord) -> Bool {
        let localKeys = Set(local.allKeys())
        let remoteKeys = Set(remote.allKeys())
        let commonKeys = localKeys.intersection(remoteKeys)
        
        for key in commonKeys {
            let localValue = local[key]
            let remoteValue = remote[key]
            
            // Skip system fields
            if key.hasPrefix("CD_") || key == "modificationDate" || key == "creationDate" {
                continue
            }
            
            if !areValuesEqual(localValue, remoteValue) {
                return true
            }
        }
        
        return false
    }
    
    private func areValuesEqual(_ value1: CKRecordValue?, _ value2: CKRecordValue?) -> Bool {
        switch (value1, value2) {
        case (nil, nil):
            return true
        case (nil, _), (_, nil):
            return false
        case let (v1 as String, v2 as String):
            return v1 == v2
        case let (v1 as NSNumber, v2 as NSNumber):
            return v1 == v2
        case let (v1 as Date, v2 as Date):
            return abs(v1.timeIntervalSince(v2)) < 1.0 // 1 second tolerance
        case let (v1 as CKRecord.Reference, v2 as CKRecord.Reference):
            return v1.recordID == v2.recordID
        default:
            return false
        }
    }
    
    // MARK: - Conflict Resolution Strategies
    
    private func mergeConflictedFields(
        local: CKRecord,
        server: CKRecord
    ) throws -> CKRecord {
        
        let mergedRecord = local.copy() as! CKRecord
        
        // Merge strategy: take newer non-nil values
        let serverKeys = Set(server.allKeys())
        let localKeys = Set(local.allKeys())
        let allKeys = serverKeys.union(localKeys)
        
        for key in allKeys {
            // Skip system fields
            if key.hasPrefix("CD_") || key == "modificationDate" || key == "creationDate" {
                continue
            }
            
            let localValue = local[key]
            let serverValue = server[key]
            
            // Merge logic based on field type and business rules
            switch key {
            case "lastModifiedBy":
                // Use server value for audit trail
                mergedRecord[key] = serverValue
                
            case "title", "description", "notes":
                // Merge text fields by concatenation if different
                if let localText = localValue as? String,
                   let serverText = serverValue as? String,
                   localText != serverText {
                    mergedRecord[key] = "\(localText)\n\n[MERGED]: \(serverText)"
                } else {
                    mergedRecord[key] = localValue ?? serverValue
                }
                
            case "status", "priority":
                // Use newer timestamp value
                let localModDate = local.modificationDate ?? Date.distantPast
                let serverModDate = server.modificationDate ?? Date.distantPast
                mergedRecord[key] = localModDate > serverModDate ? localValue : serverValue
                
            default:
                // Default: use local value if exists, otherwise server
                mergedRecord[key] = localValue ?? serverValue
            }
        }
        
        return mergedRecord
    }
    
    private func resolveVersionBasedConflict(
        local: CKRecord,
        server: CKRecord
    ) throws -> CKRecord {
        
        // Extract version information
        let localVersion = local["version"] as? Int ?? 1
        let serverVersion = server["version"] as? Int ?? 1
        
        if localVersion > serverVersion {
            let resolvedRecord = local.copy() as! CKRecord
            resolvedRecord["version"] = localVersion + 1
            return resolvedRecord
        } else {
            let resolvedRecord = server.copy() as! CKRecord
            resolvedRecord["version"] = serverVersion + 1
            return resolvedRecord
        }
    }
    
    private func applyCustomResolution(
        conflict: ConflictLog,
        resolution: [String: Any]
    ) throws -> CKRecord {
        
        let resolvedRecord = conflict.localRecord.copy() as! CKRecord
        
        for (key, value) in resolution {
            switch value {
            case let stringValue as String:
                resolvedRecord[key] = stringValue
            case let numberValue as NSNumber:
                resolvedRecord[key] = numberValue
            case let dateValue as Date:
                resolvedRecord[key] = dateValue
            case let referenceValue as CKRecord.Reference:
                resolvedRecord[key] = referenceValue
            default:
                throw ConflictLoggingError.invalidResolutionValue
            }
        }
        
        return resolvedRecord
    }
    
    // MARK: - Conflict Persistence and Monitoring
    
    private func logConflict(_ conflict: ConflictLog) async {
        // Add to active conflicts
        activeConflicts.append(conflict)
        
        // Update statistics
        conflictStatistics.totalConflicts += 1
        conflictStatistics.updateSeverityCount(conflict.severity)
        
        // Persist to CloudKit for audit trail
        await persistConflictLog(conflict)
        
        // Log to system
        logger.warning("Conflict detected: \(conflict.id) - \(conflict.operation) - \(conflict.severity.rawValue)")
        
        // Notify if critical
        if conflict.severity == .critical {
            await notifyCriticalConflict(conflict)
        }
    }
    
    private func persistConflictLog(_ conflict: ConflictLog) async {
        do {
            let record = try conflict.toCKRecord()
            _ = try await database.save(record)
            logger.info("Conflict log persisted: \(conflict.id)")
        } catch {
            logger.error("Failed to persist conflict log: \(error)")
        }
    }
    
    private func updateConflictResolution(
        conflictId: UUID,
        strategy: ConflictResolutionStrategy,
        resolvedRecord: CKRecord
    ) async {
        
        if let index = activeConflicts.firstIndex(where: { $0.id == conflictId }) {
            activeConflicts[index].resolvedAt = Date()
            activeConflicts[index].resolutionStrategy = strategy
            activeConflicts[index].resolvedRecord = resolvedRecord
            
            // Update persisted record
            await persistConflictLog(activeConflicts[index])
        }
        
        conflictStatistics.totalResolved += 1
    }
    
    private func analyzeConflictPattern(_ conflict: ConflictLog) async {
        // Analyze for recurring conflicts
        let recentConflicts = activeConflicts.filter { 
            $0.recordType == conflict.recordType &&
            $0.detectedAt.timeIntervalSince(Date()) > -3600 // Last hour
        }
        
        if recentConflicts.count > 5 {
            logger.warning("High conflict rate detected for \(conflict.recordType): \(recentConflicts.count) in last hour")
            await notifyHighConflictRate(conflict.recordType, count: recentConflicts.count)
        }
    }
    
    private func notifyCriticalConflict(_ conflict: ConflictLog) async {
        // Send notification to admin users
        let notification = UNMutableNotificationContent()
        notification.title = "Critical CloudKit Conflict"
        notification.body = "Critical conflict detected in \(conflict.recordType)"
        notification.userInfo = ["conflictId": conflict.id.uuidString]
        
        let request = UNNotificationRequest(
            identifier: "critical-conflict-\(conflict.id)",
            content: notification,
            trigger: nil
        )
        
        try? await UNUserNotificationCenter.current().add(request)
    }
    
    private func notifyHighConflictRate(_ recordType: String, count: Int) async {
        logger.critical("High conflict rate: \(recordType) - \(count) conflicts in last hour")
        
        // Could trigger additional monitoring or automatic resolution
        // Implementation depends on business requirements
    }
    
    private func setupConflictMonitoring() {
        // Monitor CloudKit database changes
        // Setup subscription for conflict-prone record types
        Task {
            await setupCloudKitSubscriptions()
        }
    }
    
    private func setupCloudKitSubscriptions() async {
        let conflictMonitoringRecordTypes = ["Task", "Ticket", "Client", "KPI", "StoreReport"]
        
        for recordType in conflictMonitoringRecordTypes {
            do {
                let subscription = CKQuerySubscription(
                    recordType: recordType,
                    predicate: NSPredicate(value: true),
                    options: [.firesOnRecordUpdate, .firesOnRecordCreation]
                )
                
                subscription.notificationInfo = CKSubscription.NotificationInfo()
                subscription.notificationInfo?.shouldSendContentAvailable = true
                
                _ = try await database.save(subscription)
                logger.info("Conflict monitoring subscription created for \(recordType)")
            } catch {
                logger.error("Failed to create subscription for \(recordType): \(error)")
            }
        }
    }
    
    // MARK: - Public Interface
    
    /// Retrieves conflict history for admin review
    func getConflictHistory(
        recordType: String? = nil,
        severity: ConflictSeverity? = nil,
        limit: Int = 100
    ) async throws -> [ConflictLog] {
        
        var predicate = NSPredicate(value: true)
        
        if let recordType = recordType {
            predicate = NSPredicate(format: "recordType == %@", recordType)
        }
        
        if let severity = severity {
            let severityPredicate = NSPredicate(format: "severity == %@", severity.rawValue)
            predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, severityPredicate])
        }
        
        let query = CKQuery(recordType: "ConflictLog", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "detectedAt", ascending: false)]
        
        let (results, _) = try await database.records(matching: query, resultsLimit: limit)
        
        return results.compactMap { (_, result) in
            switch result {
            case .success(let record):
                return ConflictLog.fromCKRecord(record)
            case .failure(let error):
                logger.error("Failed to fetch conflict log record: \(error)")
                return nil
            }
        }
    }
    
    /// Exports conflict statistics for analysis
    func exportConflictStatistics() -> ConflictStatistics {
        return conflictStatistics
    }
    
    /// Clears resolved conflicts older than specified days
    func clearOldConflicts(olderThanDays days: Int = 30) async {
        let cutoffDate = Date().addingTimeInterval(-TimeInterval(days * 24 * 60 * 60))
        
        activeConflicts.removeAll { conflict in
            guard let resolvedAt = conflict.resolvedAt else { return false }
            return resolvedAt < cutoffDate
        }
        
        logger.info("Cleared resolved conflicts older than \(days) days")
    }
}

// MARK: - Supporting Types

enum ConflictLoggingError: Error, LocalizedError {
    case conflictNotFound
    case invalidResolution
    case invalidResolutionValue
    case persistenceFailure
    
    var errorDescription: String? {
        switch self {
        case .conflictNotFound:
            return "Conflict not found in active conflicts list"
        case .invalidResolution:
            return "Invalid or missing resolution data"
        case .invalidResolutionValue:
            return "Invalid value type in resolution data"
        case .persistenceFailure:
            return "Failed to persist conflict log to CloudKit"
        }
    }
}

struct ConflictStatistics: Codable {
    var totalConflicts: Int = 0
    var totalResolved: Int = 0
    var criticalCount: Int = 0
    var highCount: Int = 0
    var mediumCount: Int = 0
    var lowCount: Int = 0
    var lastUpdated: Date = Date()
    
    mutating func updateSeverityCount(_ severity: ConflictLoggingService.ConflictSeverity) {
        switch severity {
        case .critical:
            criticalCount += 1
        case .high:
            highCount += 1
        case .medium:
            mediumCount += 1
        case .low:
            lowCount += 1
        }
        lastUpdated = Date()
    }
    
    var resolutionRate: Double {
        guard totalConflicts > 0 else { return 0.0 }
        return Double(totalResolved) / Double(totalConflicts)
    }
    
    var pendingConflicts: Int {
        return totalConflicts - totalResolved
    }
}
