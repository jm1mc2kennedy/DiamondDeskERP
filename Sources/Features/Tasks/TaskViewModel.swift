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
}
