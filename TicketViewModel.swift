import Foundation
import CloudKit
import Combine

@MainActor
class TicketViewModel: ObservableObject {
    @Published var tickets: [TicketModel] = []
    @Published var error: Error?
    @Published var isLoading: Bool = false
    
    private let database: CKDatabase
    
    init(database: CKDatabase = CKContainer.default().publicCloudDatabase) {
        self.database = database
    }
    
    func fetchTickets(for user: User) {
        isLoading = true
        
        let userRecordID = CKRecord.ID(recordName: user.userId)
        let userReference = CKRecord.Reference(recordID: userRecordID, action: .none)
        
        let assignedToUserPredicate = NSPredicate(format: "assignedUserRef == %@", userReference)
        let createdByUserPredicate = NSPredicate(format: "createdByRef == %@", userReference)
        
        let predicate = NSCompoundPredicate(orPredicateWithSubpredicates: [assignedToUserPredicate, createdByUserPredicate])
        
        let query = CKQuery(recordType: "Ticket", predicate: predicate)
        
        database.perform(query, inZoneWith: nil) { [weak self] records, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    self.error = error
                    return
                }
                
                self.tickets = records?.compactMap { TicketModel(record: $0) } ?? []
            }
        }
    }
}
