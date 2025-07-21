import Foundation
import CloudKit
import Combine

@MainActor
class ClientViewModel: ObservableObject {
    @Published var clients: [ClientModel] = []
    @Published var error: Error?
    @Published var isLoading: Bool = false
    
    private let database: CKDatabase
    
    init(database: CKDatabase = CKContainer.default().publicCloudDatabase) {
        self.database = database
    }
    
    func fetchClients(for user: User) {
        isLoading = true
        
        let userRecordID = CKRecord.ID(recordName: user.userId)
        let userReference = CKRecord.Reference(recordID: userRecordID, action: .none)
        
        let predicate = NSPredicate(format: "assignedUserRef == %@", userReference)
        let query = CKQuery(recordType: "Client", predicate: predicate)
        
        database.perform(query, inZoneWith: nil) { [weak self] records, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    self.error = error
                    return
                }
                
                self.clients = records?.compactMap { ClientModel(record: $0) } ?? []
            }
        }
    }
}
