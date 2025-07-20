import Foundation
import CloudKit
import Combine

@MainActor
class TaskViewModel: ObservableObject {
    @Published var tasks: [TaskModel] = []
    @Published var error: Error?
    @Published var isLoading: Bool = false
    
    private let database: CKDatabase
    private var subscriptions = Set<AnyCancellable>()
    
    init(database: CKDatabase = CKContainer.default().publicCloudDatabase) {
        self.database = database
    }
    
    func fetchTasks(for user: User) {
        isLoading = true
        let userRecordID = CKRecord.ID(recordName: user.userId)
        let userReference = CKRecord.Reference(recordID: userRecordID, action: .none)
        
        let predicate = NSPredicate(format: "assignedUserRefs CONTAINS %@", userReference)
        let query = CKQuery(recordType: "Task", predicate: predicate)
        
        database.perform(query, inZoneWith: nil) { [weak self] records, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    self.error = error
                    return
                }
                
                self.tasks = records?.compactMap { TaskModel(record: $0) } ?? []
            }
        }
    }
    
    func createTask(data: [String: Any], createdBy user: User) async throws {
        let record = CKRecord(recordType: "Task")
        
        record["title"] = data["title"] as? String
        record["description"] = data["description"] as? String
        record["status"] = data["status"] as? String
        record["dueDate"] = data["dueDate"] as? Date
        record["isGroupTask"] = data["isGroupTask"] as? Bool
        record["completionMode"] = data["completionMode"] as? String
        record["requiresAck"] = data["requiresAck"] as? Bool
        record["storeCodes"] = data["storeCodes"] as? [String]
        record["departments"] = data["departments"] as? [String]
        record["createdAt"] = data["createdAt"] as? Date
        
        // Create user references
        let createdByRef = CKRecord.Reference(recordID: user.id, action: .none)
        record["createdByRef"] = createdByRef
        
        // Convert assignedUserIds to references
        if let assignedUserIds = data["assignedUserIds"] as? [String] {
            let assignedRefs = assignedUserIds.map { userId in
                CKRecord.Reference(recordID: CKRecord.ID(recordName: userId), action: .none)
            }
            record["assignedUserRefs"] = assignedRefs
        }
        
        // Initialize empty completed users array
        record["completedUserRefs"] = [] as [CKRecord.Reference]
        
        do {
            let savedRecord = try await database.save(record)
            if let newTask = TaskModel(record: savedRecord) {
                await MainActor.run {
                    self.tasks.append(newTask)
                }
            }
        } catch {
            throw error
        }
    }
}
