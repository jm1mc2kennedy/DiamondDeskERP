import Foundation
import CloudKit
import Combine

@MainActor
class UserService: ObservableObject {
    @Published var users: [User] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let database: CKDatabase
    
    init(database: CKDatabase = CKContainer.default().publicCloudDatabase) {
        self.database = database
    }
    
    func loadUsers() async {
        isLoading = true
        error = nil
        
        do {
            let query = CKQuery(recordType: "User", predicate: NSPredicate(value: true))
            let records = try await database.records(matching: query)
            
            self.users = records.matchResults.compactMap { (_, result) in
                switch result {
                case .success(let record):
                    return User(record: record)
                case .failure(_):
                    return nil
                }
            }
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    func findUser(by id: String) -> User? {
        return users.first { $0.id == id }
    }
    
    func searchUsers(query: String) -> [User] {
        guard !query.isEmpty else { return users }
        
        return users.filter { user in
            user.displayName.localizedCaseInsensitiveContains(query) ||
            user.email.localizedCaseInsensitiveContains(query)
        }
    }
}
