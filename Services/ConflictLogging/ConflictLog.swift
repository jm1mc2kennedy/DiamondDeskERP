import Foundation
import CloudKit

/// ConflictLog model representing CloudKit record conflicts
/// Stores comprehensive conflict information for audit trails and resolution tracking
struct ConflictLog: Identifiable, Codable {
    let id: UUID
    let recordType: String
    let recordID: String
    let localRecord: CKRecord
    let serverRecord: CKRecord
    let operation: String
    let detectedAt: Date
    let severity: ConflictLoggingService.ConflictSeverity
    let strategy: ConflictLoggingService.ConflictResolutionStrategy
    
    // Resolution tracking
    var resolvedAt: Date?
    var resolutionStrategy: ConflictLoggingService.ConflictResolutionStrategy?
    var resolvedRecord: CKRecord?
    var resolvedBy: String?
    var resolutionNotes: String?
    
    // Conflict analysis metadata
    let conflictedFields: [String]
    let localModificationDate: Date?
    let serverModificationDate: Date?
    let conflictScore: Int
    let automaticResolution: Bool
    
    init(
        localRecord: CKRecord,
        serverRecord: CKRecord,
        operation: String,
        detectedAt: Date,
        strategy: ConflictLoggingService.ConflictResolutionStrategy,
        severity: ConflictLoggingService.ConflictSeverity
    ) {
        self.id = UUID()
        self.recordType = localRecord.recordType
        self.recordID = localRecord.recordID.recordName
        self.localRecord = localRecord
        self.serverRecord = serverRecord
        self.operation = operation
        self.detectedAt = detectedAt
        self.strategy = strategy
        self.severity = severity
        
        self.localModificationDate = localRecord.modificationDate
        self.serverModificationDate = serverRecord.modificationDate
        self.conflictedFields = ConflictLog.findConflictedFields(local: localRecord, server: serverRecord)
        self.conflictScore = ConflictLog.calculateConflictScore(local: localRecord, server: serverRecord)
        self.automaticResolution = strategy != .manualResolution
    }
    
    // MARK: - Conflict Analysis
    
    private static func findConflictedFields(local: CKRecord, server: CKRecord) -> [String] {
        let localKeys = Set(local.allKeys())
        let serverKeys = Set(server.allKeys())
        let commonKeys = localKeys.intersection(serverKeys)
        
        var conflictedFields: [String] = []
        
        for key in commonKeys {
            // Skip system fields
            if key.hasPrefix("CD_") || key == "modificationDate" || key == "creationDate" {
                continue
            }
            
            let localValue = local[key]
            let serverValue = server[key]
            
            if !areValuesEqual(localValue, serverValue) {
                conflictedFields.append(key)
            }
        }
        
        // Add fields that exist in only one record
        let localOnlyFields = localKeys.subtracting(serverKeys)
        let serverOnlyFields = serverKeys.subtracting(localKeys)
        
        conflictedFields.append(contentsOf: localOnlyFields.filter { !$0.hasPrefix("CD_") })
        conflictedFields.append(contentsOf: serverOnlyFields.filter { !$0.hasPrefix("CD_") })
        
        return conflictedFields.sorted()
    }
    
    private static func areValuesEqual(_ value1: CKRecordValue?, _ value2: CKRecordValue?) -> Bool {
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
        case let (v1 as [String], v2 as [String]):
            return v1 == v2
        case let (v1 as Data, v2 as Data):
            return v1 == v2
        default:
            return false
        }
    }
    
    private static func calculateConflictScore(local: CKRecord, server: CKRecord) -> Int {
        var score = 0
        
        // Base score for having a conflict
        score += 1
        
        // Additional score for critical fields
        let criticalFields = ["status", "amount", "priority", "assignee", "dueDate"]
        for field in criticalFields {
            if local[field] != nil && server[field] != nil && !areValuesEqual(local[field], server[field]) {
                score += 3
            }
        }
        
        // Score for relationship conflicts
        let relationshipFields = ["clientID", "taskID", "ticketID", "parentID"]
        for field in relationshipFields {
            if local[field] != nil && server[field] != nil && !areValuesEqual(local[field], server[field]) {
                score += 2
            }
        }
        
        // Score for timestamp differences
        if let localDate = local.modificationDate,
           let serverDate = server.modificationDate {
            let timeDifference = abs(localDate.timeIntervalSince(serverDate))
            if timeDifference > 3600 { // More than 1 hour
                score += 2
            }
        }
        
        return score
    }
    
    // MARK: - CloudKit Persistence
    
    func toCKRecord() throws -> CKRecord {
        let record = CKRecord(recordType: "ConflictLog", recordID: CKRecord.ID(recordName: id.uuidString))
        
        // Basic conflict information
        record["recordType"] = recordType
        record["recordID"] = recordID
        record["operation"] = operation
        record["detectedAt"] = detectedAt
        record["severity"] = severity.rawValue
        record["strategy"] = strategy.rawValue
        
        // Conflict analysis
        record["conflictedFields"] = conflictedFields
        record["localModificationDate"] = localModificationDate
        record["serverModificationDate"] = serverModificationDate
        record["conflictScore"] = conflictScore
        record["automaticResolution"] = automaticResolution ? 1 : 0
        
        // Resolution tracking
        if let resolvedAt = resolvedAt {
            record["resolvedAt"] = resolvedAt
        }
        if let resolutionStrategy = resolutionStrategy {
            record["resolutionStrategy"] = resolutionStrategy.rawValue
        }
        if let resolvedBy = resolvedBy {
            record["resolvedBy"] = resolvedBy
        }
        if let resolutionNotes = resolutionNotes {
            record["resolutionNotes"] = resolutionNotes
        }
        
        // Store record data as encoded strings (CloudKit doesn't support nested CKRecords)
        do {
            let localRecordData = try encodeRecordToData(localRecord)
            let serverRecordData = try encodeRecordToData(serverRecord)
            
            record["localRecordData"] = localRecordData
            record["serverRecordData"] = serverRecordData
            
            if let resolvedRecord = resolvedRecord {
                let resolvedRecordData = try encodeRecordToData(resolvedRecord)
                record["resolvedRecordData"] = resolvedRecordData
            }
        } catch {
            throw ConflictLoggingError.persistenceFailure
        }
        
        return record
    }
    
    static func fromCKRecord(_ record: CKRecord) -> ConflictLog? {
        guard 
            let recordType = record["recordType"] as? String,
            let recordID = record["recordID"] as? String,
            let operation = record["operation"] as? String,
            let detectedAt = record["detectedAt"] as? Date,
            let severityString = record["severity"] as? String,
            let strategyString = record["strategy"] as? String,
            let severity = ConflictLoggingService.ConflictSeverity(rawValue: severityString),
            let strategy = ConflictLoggingService.ConflictResolutionStrategy(rawValue: strategyString),
            let conflictedFields = record["conflictedFields"] as? [String],
            let conflictScore = record["conflictScore"] as? Int,
            let automaticResolutionValue = record["automaticResolution"] as? Int,
            let localRecordData = record["localRecordData"] as? Data,
            let serverRecordData = record["serverRecordData"] as? Data,
            let localRecord = try? decodeRecordFromData(localRecordData),
            let serverRecord = try? decodeRecordFromData(serverRecordData)
        else {
            return nil
        }
        
        var conflictLog = ConflictLog(
            localRecord: localRecord,
            serverRecord: serverRecord,
            operation: operation,
            detectedAt: detectedAt,
            strategy: strategy,
            severity: severity
        )
        
        // Override with stored values
        if let id = UUID(uuidString: record.recordID.recordName) {
            conflictLog = ConflictLog(
                id: id,
                recordType: recordType,
                recordID: recordID,
                localRecord: localRecord,
                serverRecord: serverRecord,
                operation: operation,
                detectedAt: detectedAt,
                severity: severity,
                strategy: strategy,
                resolvedAt: record["resolvedAt"] as? Date,
                resolutionStrategy: (record["resolutionStrategy"] as? String).flatMap { 
                    ConflictLoggingService.ConflictResolutionStrategy(rawValue: $0) 
                },
                resolvedRecord: (record["resolvedRecordData"] as? Data).flatMap { 
                    try? decodeRecordFromData($0) 
                },
                resolvedBy: record["resolvedBy"] as? String,
                resolutionNotes: record["resolutionNotes"] as? String,
                conflictedFields: conflictedFields,
                localModificationDate: record["localModificationDate"] as? Date,
                serverModificationDate: record["serverModificationDate"] as? Date,
                conflictScore: conflictScore,
                automaticResolution: automaticResolutionValue == 1
            )
        }
        
        return conflictLog
    }
    
    // MARK: - Record Encoding/Decoding
    
    private func encodeRecordToData(_ record: CKRecord) throws -> Data {
        let archiver = NSKeyedArchiver(requiringSecureCoding: true)
        record.encodeSystemFields(with: archiver)
        archiver.finishEncoding()
        return archiver.encodedData
    }
    
    private static func decodeRecordFromData(_ data: Data) throws -> CKRecord {
        let unarchiver = try NSKeyedUnarchiver(forReadingFrom: data)
        unarchiver.requiresSecureCoding = true
        defer { unarchiver.finishDecoding() }
        
        guard let record = CKRecord(coder: unarchiver) else {
            throw ConflictLoggingError.persistenceFailure
        }
        
        return record
    }
    
    // MARK: - Helper Properties
    
    var isResolved: Bool {
        return resolvedAt != nil
    }
    
    var resolutionTime: TimeInterval? {
        guard let resolvedAt = resolvedAt else { return nil }
        return resolvedAt.timeIntervalSince(detectedAt)
    }
    
    var conflictDescription: String {
        let fieldList = conflictedFields.joined(separator: ", ")
        return "Conflict in \(recordType) record \(recordID): fields [\(fieldList)]"
    }
    
    var severityColor: String {
        switch severity {
        case .critical: return "red"
        case .high: return "orange"
        case .medium: return "yellow"
        case .low: return "blue"
        }
    }
    
    // MARK: - Field-Specific Conflict Analysis
    
    func getFieldConflictDetails() -> [FieldConflictDetail] {
        var details: [FieldConflictDetail] = []
        
        for field in conflictedFields {
            let localValue = localRecord[field]
            let serverValue = serverRecord[field]
            
            let detail = FieldConflictDetail(
                fieldName: field,
                localValue: formatValue(localValue),
                serverValue: formatValue(serverValue),
                conflictType: determineConflictType(field: field, local: localValue, server: serverValue)
            )
            
            details.append(detail)
        }
        
        return details.sorted { $0.fieldName < $1.fieldName }
    }
    
    private func formatValue(_ value: CKRecordValue?) -> String {
        guard let value = value else { return "(nil)" }
        
        switch value {
        case let stringValue as String:
            return stringValue
        case let numberValue as NSNumber:
            return numberValue.stringValue
        case let dateValue as Date:
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: dateValue)
        case let referenceValue as CKRecord.Reference:
            return "Reference: \(referenceValue.recordID.recordName)"
        case let arrayValue as [Any]:
            return "Array(\(arrayValue.count) items)"
        case let dataValue as Data:
            return "Data(\(dataValue.count) bytes)"
        default:
            return String(describing: value)
        }
    }
    
    private func determineConflictType(field: String, local: CKRecordValue?, server: CKRecordValue?) -> FieldConflictType {
        switch (local, server) {
        case (nil, _):
            return .missingLocal
        case (_, nil):
            return .missingServer
        case (let l as String, let s as String) where l != s:
            return .valueDifference
        case (let l as NSNumber, let s as NSNumber) where l != s:
            return .valueDifference
        case (let l as Date, let s as Date) where l != s:
            return .timestampDifference
        case (let l as CKRecord.Reference, let s as CKRecord.Reference) where l.recordID != s.recordID:
            return .referenceDifference
        default:
            return .unknown
        }
    }
}

// MARK: - Supporting Types

extension ConflictLog {
    init(
        id: UUID,
        recordType: String,
        recordID: String,
        localRecord: CKRecord,
        serverRecord: CKRecord,
        operation: String,
        detectedAt: Date,
        severity: ConflictLoggingService.ConflictSeverity,
        strategy: ConflictLoggingService.ConflictResolutionStrategy,
        resolvedAt: Date?,
        resolutionStrategy: ConflictLoggingService.ConflictResolutionStrategy?,
        resolvedRecord: CKRecord?,
        resolvedBy: String?,
        resolutionNotes: String?,
        conflictedFields: [String],
        localModificationDate: Date?,
        serverModificationDate: Date?,
        conflictScore: Int,
        automaticResolution: Bool
    ) {
        self.id = id
        self.recordType = recordType
        self.recordID = recordID
        self.localRecord = localRecord
        self.serverRecord = serverRecord
        self.operation = operation
        self.detectedAt = detectedAt
        self.severity = severity
        self.strategy = strategy
        self.resolvedAt = resolvedAt
        self.resolutionStrategy = resolutionStrategy
        self.resolvedRecord = resolvedRecord
        self.resolvedBy = resolvedBy
        self.resolutionNotes = resolutionNotes
        self.conflictedFields = conflictedFields
        self.localModificationDate = localModificationDate
        self.serverModificationDate = serverModificationDate
        self.conflictScore = conflictScore
        self.automaticResolution = automaticResolution
    }
}

struct FieldConflictDetail {
    let fieldName: String
    let localValue: String
    let serverValue: String
    let conflictType: FieldConflictType
}

enum FieldConflictType {
    case missingLocal
    case missingServer
    case valueDifference
    case timestampDifference
    case referenceDifference
    case unknown
    
    var description: String {
        switch self {
        case .missingLocal:
            return "Missing in local record"
        case .missingServer:
            return "Missing in server record"
        case .valueDifference:
            return "Different values"
        case .timestampDifference:
            return "Different timestamps"
        case .referenceDifference:
            return "Different references"
        case .unknown:
            return "Unknown conflict type"
        }
    }
}
