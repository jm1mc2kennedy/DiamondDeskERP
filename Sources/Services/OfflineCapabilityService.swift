import Foundation
import CloudKit
import Combine
import Network

@MainActor
class OfflineCapabilityService: ObservableObject {
    @Published var isOffline = false
    @Published var syncStatus: LocalSyncStatus = .idle
    @Published var pendingSyncItems: Int = 0
    @Published var lastSyncDate: Date?
    
    private let database: CKDatabase
    private let coreDataManager: CoreDataManager
    private let networkMonitor = NWPathMonitor()
    private let syncQueue = DispatchQueue(label: "sync.queue", qos: .utility)
    
    private var pendingOperations: [OfflineOperation] = []
    private var cancellables = Set<AnyCancellable>()
    
    init(
        database: CKDatabase = CKContainer.default().publicCloudDatabase,
        coreDataManager: CoreDataManager = .shared
    ) {
        self.database = database
        self.coreDataManager = coreDataManager
        
        setupNetworkMonitoring()
        loadPendingOperations()
    }
    
    // MARK: - Network Monitoring
    
    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                let wasOffline = self?.isOffline ?? false
                self?.isOffline = path.status != .satisfied
                
                // If we just came back online, start sync
                if wasOffline && !self!.isOffline {
                    Task {
                        await self?.performSync()
                    }
                }
            }
        }
        
        networkMonitor.start(queue: syncQueue)
    }
    
    // MARK: - Offline Operations Management
    
    func queueOfflineOperation(_ operation: OfflineOperation) {
        pendingOperations.append(operation)
        pendingSyncItems = pendingOperations.count
        
        // Save to persistent storage
        savePendingOperations()
        
        // If online, try to sync immediately
        if !isOffline {
            Task {
                await performSync()
            }
        }
    }
    
    private func loadPendingOperations() {
        // Load from UserDefaults or Core Data
        if let data = UserDefaults.standard.data(forKey: "pendingOfflineOperations"),
           let operations = try? JSONDecoder().decode([OfflineOperation].self, from: data) {
            pendingOperations = operations
            pendingSyncItems = operations.count
        }
    }
    
    private func savePendingOperations() {
        if let data = try? JSONEncoder().encode(pendingOperations) {
            UserDefaults.standard.set(data, forKey: "pendingOfflineOperations")
        }
    }
    
    // MARK: - Data Management
    
    func saveTaskOffline(_ task: TaskModel) async throws {
        // Save to Core Data immediately
        try await coreDataManager.saveTask(task)
        
        // Queue CloudKit operation for later sync
        let operation = OfflineOperation(
            id: UUID().uuidString,
            type: .createTask,
            entityId: task.id.recordName,
            data: try JSONEncoder().encode(task),
            timestamp: Date()
        )
        
        queueOfflineOperation(operation)
    }
    
    func updateTaskOffline(_ task: TaskModel) async throws {
        // Update in Core Data
        try await coreDataManager.updateTask(task)
        
        // Queue CloudKit operation
        let operation = OfflineOperation(
            id: UUID().uuidString,
            type: .updateTask,
            entityId: task.id.recordName,
            data: try JSONEncoder().encode(task),
            timestamp: Date()
        )
        
        queueOfflineOperation(operation)
    }
    
    func deleteTaskOffline(_ taskId: String) async throws {
        // Mark as deleted in Core Data
        try await coreDataManager.markTaskAsDeleted(taskId)
        
        // Queue CloudKit operation
        let operation = OfflineOperation(
            id: UUID().uuidString,
            type: .deleteTask,
            entityId: taskId,
            data: Data(),
            timestamp: Date()
        )
        
        queueOfflineOperation(operation)
    }
    
    // Similar methods for Tickets and Clients...
    
    func saveTicketOffline(_ ticket: TicketModel) async throws {
        try await coreDataManager.saveTicket(ticket)
        
        let operation = OfflineOperation(
            id: UUID().uuidString,
            type: .createTicket,
            entityId: ticket.id.recordName,
            data: try JSONEncoder().encode(ticket),
            timestamp: Date()
        )
        
        queueOfflineOperation(operation)
    }
    
    func saveClientOffline(_ client: ClientModel) async throws {
        try await coreDataManager.saveClient(client)
        
        let operation = OfflineOperation(
            id: UUID().uuidString,
            type: .createClient,
            entityId: client.id.recordName,
            data: try JSONEncoder().encode(client),
            timestamp: Date()
        )
        
        queueOfflineOperation(operation)
    }
    
    // MARK: - Data Retrieval
    
    func fetchTasksOffline() async throws -> [TaskModel] {
        return try await coreDataManager.fetchTasks()
    }
    
    func fetchTicketsOffline() async throws -> [TicketModel] {
        return try await coreDataManager.fetchTickets()
    }
    
    func fetchClientsOffline() async throws -> [ClientModel] {
        return try await coreDataManager.fetchClients()
    }
    
    func fetchTaskOffline(id: String) async throws -> TaskModel? {
        return try await coreDataManager.fetchTask(id: id)
    }
    
    // MARK: - Synchronization
    
    func performSync() async {
        guard !isOffline && syncStatus == .idle else { return }
        
        syncStatus = .syncing
        
        do {
            // First, download latest changes from CloudKit
            await downloadCloudKitChanges()
            
            // Then, upload pending changes
            await uploadPendingChanges()
            
            lastSyncDate = Date()
            syncStatus = .completed
            
        } catch {
            syncStatus = .failed(error)
        }
    }
    
    private func downloadCloudKitChanges() async {
        do {
            // Fetch changes since last sync
            let changeToken = loadChangeToken()
            
            // Download Task changes
            try await downloadTaskChanges(since: changeToken)
            
            // Download Ticket changes
            try await downloadTicketChanges(since: changeToken)
            
            // Download Client changes
            try await downloadClientChanges(since: changeToken)
            
            // Save new change token
            saveChangeToken()
            
        } catch {
            print("Failed to download CloudKit changes: \(error)")
        }
    }
    
    private func downloadTaskChanges(since token: CKServerChangeToken?) async throws {
        let recordZone = CKRecordZone(zoneName: "Tasks")
        let options = CKFetchRecordZoneChangesOperation.ZoneConfiguration()
        options.previousServerChangeToken = token
        
        let operation = CKFetchRecordZoneChangesOperation(
            recordZoneIDs: [recordZone.zoneID],
            configurationsByRecordZoneID: [recordZone.zoneID: options]
        )
        
        operation.recordWasChangedBlock = { [weak self] record, _ in
            Task {
                if let task = TaskModel(record: record) {
                    try? await self?.coreDataManager.saveTask(task)
                }
            }
        }
        
        operation.recordWithIDWasDeletedBlock = { [weak self] recordID, _ in
            Task {
                try? await self?.coreDataManager.deleteTask(id: recordID.recordName)
            }
        }
        
        database.add(operation)
    }
    
    private func downloadTicketChanges(since token: CKServerChangeToken?) async throws {
        // Similar implementation for Tickets
    }
    
    private func downloadClientChanges(since token: CKServerChangeToken?) async throws {
        // Similar implementation for Clients
    }
    
    private func uploadPendingChanges() async {
        let operations = pendingOperations.sorted { $0.timestamp < $1.timestamp }
        var completedOperations: [String] = []
        
        for operation in operations {
            do {
                try await executeOperation(operation)
                completedOperations.append(operation.id)
            } catch {
                print("Failed to execute operation \(operation.id): \(error)")
                // Don't remove failed operations, they'll be retried next sync
                break
            }
        }
        
        // Remove completed operations
        pendingOperations.removeAll { completedOperations.contains($0.id) }
        pendingSyncItems = pendingOperations.count
        savePendingOperations()
    }
    
    private func executeOperation(_ operation: OfflineOperation) async throws {
        switch operation.type {
        case .createTask:
            let task = try JSONDecoder().decode(TaskModel.self, from: operation.data)
            let record = task.toRecord()
            _ = try await database.save(record)
            
        case .updateTask:
            let task = try JSONDecoder().decode(TaskModel.self, from: operation.data)
            let record = task.toRecord()
            _ = try await database.save(record)
            
        case .deleteTask:
            let recordID = CKRecord.ID(recordName: operation.entityId)
            _ = try await database.deleteRecord(withID: recordID)
            
        case .createTicket:
            let ticket = try JSONDecoder().decode(TicketModel.self, from: operation.data)
            let record = ticket.toRecord()
            _ = try await database.save(record)
            
        case .updateTicket:
            let ticket = try JSONDecoder().decode(TicketModel.self, from: operation.data)
            let record = ticket.toRecord()
            _ = try await database.save(record)
            
        case .deleteTicket:
            let recordID = CKRecord.ID(recordName: operation.entityId)
            _ = try await database.deleteRecord(withID: recordID)
            
        case .createClient:
            let client = try JSONDecoder().decode(ClientModel.self, from: operation.data)
            let record = client.toRecord()
            _ = try await database.save(record)
            
        case .updateClient:
            let client = try JSONDecoder().decode(ClientModel.self, from: operation.data)
            let record = client.toRecord()
            _ = try await database.save(record)
            
        case .deleteClient:
            let recordID = CKRecord.ID(recordName: operation.entityId)
            _ = try await database.deleteRecord(withID: recordID)
        }
    }
    
    // MARK: - Change Token Management
    
    private func loadChangeToken() -> CKServerChangeToken? {
        guard let data = UserDefaults.standard.data(forKey: "cloudKitChangeToken") else { return nil }
        return try? NSKeyedUnarchiver.unarchivedObject(ofClass: CKServerChangeToken.self, from: data)
    }
    
    private func saveChangeToken() {
        // This would typically be saved after a successful fetch operation
        // For now, we'll save a placeholder
    }
    
    // MARK: - Conflict Resolution
    
    func resolveConflict(localRecord: CKRecord, serverRecord: CKRecord) -> CKRecord {
        // Simple last-write-wins strategy
        // In a real app, you might want more sophisticated conflict resolution
        
        let localModified = localRecord.modificationDate ?? Date.distantPast
        let serverModified = serverRecord.modificationDate ?? Date.distantPast
        
        return localModified > serverModified ? localRecord : serverRecord
    }
    
    // MARK: - Manual Sync Trigger
    
    func forcSync() async {
        guard !isOffline else { return }
        
        if syncStatus == .syncing {
            return // Already syncing
        }
        
        await performSync()
    }
    
    // MARK: - Cleanup
    
    func cleanup() {
        networkMonitor.cancel()
    }
}

// MARK: - Supporting Types

struct OfflineOperation: Codable {
    let id: String
    let type: OperationType
    let entityId: String
    let data: Data
    let timestamp: Date
}

enum OperationType: String, Codable {
    case createTask
    case updateTask
    case deleteTask
    case createTicket
    case updateTicket
    case deleteTicket
    case createClient
    case updateClient
    case deleteClient
}

enum LocalSyncStatus: Equatable {
    case idle
    case syncing
    case completed
    case failed(Error)
    
    static func == (lhs: LocalSyncStatus, rhs: LocalSyncStatus) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.syncing, .syncing), (.completed, .completed):
            return true
        case (.failed, .failed):
            return true // Simplified comparison
        default:
            return false
        }
    }
}

// MARK: - Core Data Manager Protocol

protocol CoreDataManagerProtocol {
    func saveTask(_ task: TaskModel) async throws
    func updateTask(_ task: TaskModel) async throws
    func deleteTask(id: String) async throws
    func markTaskAsDeleted(_ id: String) async throws
    func fetchTasks() async throws -> [TaskModel]
    func fetchTask(id: String) async throws -> TaskModel?
    
    func saveTicket(_ ticket: TicketModel) async throws
    func fetchTickets() async throws -> [TicketModel]
    
    func saveClient(_ client: ClientModel) async throws
    func fetchClients() async throws -> [ClientModel]
}

// Placeholder Core Data Manager
class CoreDataManager: CoreDataManagerProtocol {
    static let shared = CoreDataManager()
    
    private init() {}
    
    func saveTask(_ task: TaskModel) async throws {
        // Implementation would save to Core Data
    }
    
    func updateTask(_ task: TaskModel) async throws {
        // Implementation would update in Core Data
    }
    
    func deleteTask(id: String) async throws {
        // Implementation would delete from Core Data
    }
    
    func markTaskAsDeleted(_ id: String) async throws {
        // Implementation would mark as deleted in Core Data
    }
    
    func fetchTasks() async throws -> [TaskModel] {
        // Implementation would fetch from Core Data
        return []
    }
    
    func fetchTask(id: String) async throws -> TaskModel? {
        // Implementation would fetch single task from Core Data
        return nil
    }
    
    func saveTicket(_ ticket: TicketModel) async throws {
        // Implementation would save to Core Data
    }
    
    func fetchTickets() async throws -> [TicketModel] {
        // Implementation would fetch from Core Data
        return []
    }
    
    func saveClient(_ client: ClientModel) async throws {
        // Implementation would save to Core Data
    }
    
    func fetchClients() async throws -> [ClientModel] {
        // Implementation would fetch from Core Data
        return []
    }
}
