import Foundation
import CloudKit

#if ENABLE_CONFLICT_LOGGING

/// Repository integration extension for automatic conflict detection
/// Seamlessly integrates conflict logging into existing MVVM repository pattern
extension ConflictLoggingService {
    
    // MARK: - Repository Integration Methods
    
    /// Wraps CloudKit save operation with conflict detection
    func saveManagedRecord(
        _ record: CKRecord,
        operation: String,
        in database: CKDatabase = CKContainer.default().privateCloudDatabase
    ) async throws -> CKRecord {
        
        do {
            let savedRecord = try await database.save(record)
            logger.info("Record saved successfully: \(record.recordID.recordName)")
            return savedRecord
        } catch let error as CKError {
            
            // Handle specific CloudKit errors with conflict detection
            switch error.code {
            case .serverRecordChanged:
                await handleSaveConflict(error: error, record: record, operation: operation)
                throw error
                
            case .unknownItem:
                logger.warning("Record not found during save: \(record.recordID.recordName)")
                throw error
                
            case .quotaExceeded:
                logger.error("CloudKit quota exceeded during save operation")
                throw error
                
            case .zoneBusy:
                logger.warning("CloudKit zone busy, retrying save operation")
                // Implement retry logic
                try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
                return try await saveManagedRecord(record, operation: operation, in: database)
                
            default:
                logger.error("CloudKit save error: \(error.localizedDescription)")
                throw error
            }
        }
    }
    
    /// Wraps CloudKit fetch operation with conflict detection
    func fetchManagedRecord(
        _ recordID: CKRecord.ID,
        operation: String,
        localRecord: CKRecord? = nil,
        in database: CKDatabase = CKContainer.default().privateCloudDatabase
    ) async throws -> CKRecord {
        
        do {
            let fetchedRecord = try await database.record(for: recordID)
            
            // Check for conflicts if local record is provided
            if let localRecord = localRecord {
                await handleFetchConflict(
                    localRecord: localRecord,
                    fetchedRecord: fetchedRecord,
                    operation: operation
                )
            }
            
            logger.info("Record fetched successfully: \(recordID.recordName)")
            return fetchedRecord
        } catch let error as CKError {
            
            switch error.code {
            case .unknownItem:
                logger.warning("Record not found during fetch: \(recordID.recordName)")
                throw error
                
            case .zoneBusy:
                logger.warning("CloudKit zone busy, retrying fetch operation")
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
                return try await fetchManagedRecord(recordID, operation: operation, localRecord: localRecord, in: database)
                
            default:
                logger.error("CloudKit fetch error: \(error.localizedDescription)")
                throw error
            }
        }
    }
    
    /// Wraps CloudKit query operation with conflict detection
    func queryManagedRecords(
        _ query: CKQuery,
        operation: String,
        localRecords: [CKRecord] = [],
        in database: CKDatabase = CKContainer.default().privateCloudDatabase
    ) async throws -> [CKRecord] {
        
        do {
            let (results, _) = try await database.records(matching: query)
            
            var fetchedRecords: [CKRecord] = []
            
            for (recordID, result) in results {
                switch result {
                case .success(let record):
                    fetchedRecords.append(record)
                    
                    // Check for conflicts with local records
                    if let localRecord = localRecords.first(where: { $0.recordID == recordID }) {
                        await handleFetchConflict(
                            localRecord: localRecord,
                            fetchedRecord: record,
                            operation: operation
                        )
                    }
                    
                case .failure(let error):
                    logger.error("Failed to fetch record \(recordID.recordName): \(error)")
                }
            }
            
            logger.info("Query completed successfully: \(fetchedRecords.count) records fetched")
            return fetchedRecords
        } catch {
            logger.error("CloudKit query error: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Wraps CloudKit delete operation with conflict detection
    func deleteManagedRecord(
        _ recordID: CKRecord.ID,
        operation: String,
        in database: CKDatabase = CKContainer.default().privateCloudDatabase
    ) async throws {
        
        do {
            _ = try await database.deleteRecord(withID: recordID)
            logger.info("Record deleted successfully: \(recordID.recordName)")
        } catch let error as CKError {
            
            switch error.code {
            case .unknownItem:
                // Record already deleted, log but don't throw
                logger.info("Record already deleted: \(recordID.recordName)")
                
            case .serverRecordChanged:
                // Record was modified since last fetch, potential conflict
                logger.warning("Delete conflict detected: record was modified: \(recordID.recordName)")
                await logDeleteConflict(recordID: recordID, operation: operation)
                throw error
                
            default:
                logger.error("CloudKit delete error: \(error.localizedDescription)")
                throw error
            }
        }
    }
    
    // MARK: - Batch Operations with Conflict Detection
    
    /// Wraps CloudKit batch save operation with conflict detection
    func saveManagedRecords(
        _ records: [CKRecord],
        operation: String,
        in database: CKDatabase = CKContainer.default().privateCloudDatabase
    ) async throws -> [CKRecord] {
        
        let saveOperation = CKModifyRecordsOperation(recordsToSave: records)
        saveOperation.savePolicy = .ifServerRecordUnchanged // Enable conflict detection
        saveOperation.qualityOfService = .userInitiated
        
        return try await withCheckedThrowingContinuation { continuation in
            saveOperation.modifyRecordsResultBlock = { result in
                switch result {
                case .success():
                    let savedRecords = saveOperation.savedRecords ?? []
                    continuation.resume(returning: savedRecords)
                    
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            
            saveOperation.perRecordResultBlock = { recordID, result in
                switch result {
                case .success(let record):
                    self.logger.info("Batch save successful: \(recordID.recordName)")
                    
                case .failure(let error):
                    if let ckError = error as? CKError, ckError.code == .serverRecordChanged {
                        // Handle individual record conflicts
                        Task {
                            if let originalRecord = records.first(where: { $0.recordID == recordID }) {
                                await self.handleSaveConflict(error: ckError, record: originalRecord, operation: operation)
                            }
                        }
                    }
                    self.logger.error("Batch save failed for \(recordID.recordName): \(error)")
                }
            }
            
            database.add(saveOperation)
        }
    }
    
    // MARK: - Specialized Conflict Handling
    
    private func logDeleteConflict(recordID: CKRecord.ID, operation: String) async {
        // Create a synthetic conflict log for delete operations
        let deleteConflictLog = ConflictLog(
            localRecord: CKRecord(recordType: "Unknown", recordID: recordID),
            serverRecord: CKRecord(recordType: "Unknown", recordID: recordID),
            operation: operation,
            detectedAt: Date(),
            strategy: .manualResolution,
            severity: .high
        )
        
        await logConflict(deleteConflictLog)
    }
    
    // MARK: - Repository Pattern Integration
    
    /// Creates a conflict-aware repository wrapper
    func createConflictAwareRepository<T: Codable>() -> ConflictAwareRepository<T> {
        return ConflictAwareRepository<T>(conflictService: self)
    }
}

/// Conflict-aware repository wrapper that automatically handles CloudKit conflicts
class ConflictAwareRepository<T: Codable>: ObservableObject {
    private let conflictService: ConflictLoggingService
    private let database: CKDatabase
    
    init(conflictService: ConflictLoggingService, database: CKDatabase = CKContainer.default().privateCloudDatabase) {
        self.conflictService = conflictService
        self.database = database
    }
    
    // MARK: - CRUD Operations with Conflict Management
    
    func save(_ record: CKRecord, operation: String = "save") async throws -> CKRecord {
        return try await conflictService.saveManagedRecord(record, operation: operation, in: database)
    }
    
    func fetch(_ recordID: CKRecord.ID, operation: String = "fetch", localRecord: CKRecord? = nil) async throws -> CKRecord {
        return try await conflictService.fetchManagedRecord(recordID, operation: operation, localRecord: localRecord, in: database)
    }
    
    func query(_ query: CKQuery, operation: String = "query", localRecords: [CKRecord] = []) async throws -> [CKRecord] {
        return try await conflictService.queryManagedRecords(query, operation: operation, localRecords: localRecords, in: database)
    }
    
    func delete(_ recordID: CKRecord.ID, operation: String = "delete") async throws {
        try await conflictService.deleteManagedRecord(recordID, operation: operation, in: database)
    }
    
    func batchSave(_ records: [CKRecord], operation: String = "batchSave") async throws -> [CKRecord] {
        return try await conflictService.saveManagedRecords(records, operation: operation, in: database)
    }
    
    // MARK: - Conflict Resolution Helpers
    
    func resolveConflict(_ conflictId: UUID, strategy: ConflictLoggingService.ConflictResolutionStrategy) async throws -> CKRecord {
        return try await conflictService.resolveConflict(conflictId: conflictId, strategy: strategy)
    }
    
    func getActiveConflicts() -> [ConflictLog] {
        return conflictService.activeConflicts
    }
    
    func getConflictStatistics() -> ConflictStatistics {
        return conflictService.exportConflictStatistics()
    }
}

// MARK: - Repository Integration Extensions

extension TaskRepository {
    /// Enhanced save method with conflict detection
    func saveWithConflictDetection(_ task: TaskModel) async throws -> TaskModel {
        let record = try task.toCKRecord()
        let savedRecord = try await ConflictLoggingService.shared.saveManagedRecord(
            record, 
            operation: "TaskRepository.save"
        )
        return try TaskModel.fromCKRecord(savedRecord)
    }
    
    /// Enhanced fetch method with conflict detection
    func fetchWithConflictDetection(_ taskId: String, localTask: TaskModel? = nil) async throws -> TaskModel? {
        let recordID = CKRecord.ID(recordName: taskId)
        let localRecord = try localTask?.toCKRecord()
        
        let fetchedRecord = try await ConflictLoggingService.shared.fetchManagedRecord(
            recordID,
            operation: "TaskRepository.fetch",
            localRecord: localRecord
        )
        
        return try TaskModel.fromCKRecord(fetchedRecord)
    }
}

extension TicketRepository {
    /// Enhanced save method with conflict detection
    func saveWithConflictDetection(_ ticket: TicketModel) async throws -> TicketModel {
        let record = try ticket.toCKRecord()
        let savedRecord = try await ConflictLoggingService.shared.saveManagedRecord(
            record, 
            operation: "TicketRepository.save"
        )
        return try TicketModel.fromCKRecord(savedRecord)
    }
    
    /// Enhanced fetch method with conflict detection  
    func fetchWithConflictDetection(_ ticketId: String, localTicket: TicketModel? = nil) async throws -> TicketModel? {
        let recordID = CKRecord.ID(recordName: ticketId)
        let localRecord = try localTicket?.toCKRecord()
        
        let fetchedRecord = try await ConflictLoggingService.shared.fetchManagedRecord(
            recordID,
            operation: "TicketRepository.fetch",
            localRecord: localRecord
        )
        
        return try TicketModel.fromCKRecord(fetchedRecord)
    }
}

extension ClientRepository {
    /// Enhanced save method with conflict detection
    func saveWithConflictDetection(_ client: ClientModel) async throws -> ClientModel {
        let record = try client.toCKRecord()
        let savedRecord = try await ConflictLoggingService.shared.saveManagedRecord(
            record, 
            operation: "ClientRepository.save"
        )
        return try ClientModel.fromCKRecord(savedRecord)
    }
    
    /// Enhanced fetch method with conflict detection
    func fetchWithConflictDetection(_ clientId: String, localClient: ClientModel? = nil) async throws -> ClientModel? {
        let recordID = CKRecord.ID(recordName: clientId)
        let localRecord = try localClient?.toCKRecord()
        
        let fetchedRecord = try await ConflictLoggingService.shared.fetchManagedRecord(
            recordID,
            operation: "ClientRepository.fetch",
            localRecord: localRecord
        )
        
        return try ClientModel.fromCKRecord(fetchedRecord)
    }
}

extension KPIRepository {
    /// Enhanced save method with conflict detection
    func saveWithConflictDetection(_ kpi: KPIModel) async throws -> KPIModel {
        let record = try kpi.toCKRecord()
        let savedRecord = try await ConflictLoggingService.shared.saveManagedRecord(
            record, 
            operation: "KPIRepository.save"
        )
        return try KPIModel.fromCKRecord(savedRecord)
    }
}

extension StoreReportRepository {
    /// Enhanced save method with conflict detection
    func saveWithConflictDetection(_ report: StoreReportModel) async throws -> StoreReportModel {
        let record = try report.toCKRecord()
        let savedRecord = try await ConflictLoggingService.shared.saveManagedRecord(
            record, 
            operation: "StoreReportRepository.save"
        )
        return try StoreReportModel.fromCKRecord(savedRecord)
    }
}

// MARK: - Conflict Detection Integration for ViewModels

extension TaskViewModel {
    /// Save task with automatic conflict detection
    func saveTaskWithConflictDetection() async {
        guard let taskRepository = taskRepository as? TaskRepository else { return }
        
        do {
            for task in tasks {
                _ = try await taskRepository.saveWithConflictDetection(task)
            }
            await refreshTasks()
        } catch {
            print("Failed to save tasks with conflict detection: \(error)")
        }
    }
}

extension TicketViewModel {
    /// Save ticket with automatic conflict detection
    func saveTicketWithConflictDetection() async {
        guard let ticketRepository = ticketRepository as? TicketRepository else { return }
        
        do {
            for ticket in tickets {
                _ = try await ticketRepository.saveWithConflictDetection(ticket)
            }
            await refreshTickets()
        } catch {
            print("Failed to save tickets with conflict detection: \(error)")
        }
    }
}

extension ClientViewModel {
    /// Save client with automatic conflict detection
    func saveClientWithConflictDetection() async {
        guard let clientRepository = clientRepository as? ClientRepository else { return }
        
        do {
            for client in clients {
                _ = try await clientRepository.saveWithConflictDetection(client)
            }
            await refreshClients()
        } catch {
            print("Failed to save clients with conflict detection: \(error)")
        }
    }
}
#endif
