import Foundation
import CloudKit
import Combine

class UserProvisioningService: ObservableObject {
    private let database: CKDatabase
    @Published var currentUser: User?
    @Published var error: Error?

    init(database: CKDatabase = CKContainer.default().publicCloudDatabase) {
        self.database = database
    }

    func provisionUser(userId: String, email: String, displayName: String) async {
        do {
            if let user = try await fetchUser(userId: userId) {
                DispatchQueue.main.async {
                    self.currentUser = user
                }
            } else {
                let newUser = try await createUser(userId: userId, email: email, displayName: displayName)
                DispatchQueue.main.async {
                    self.currentUser = newUser
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.error = error
            }
        }
    }

    private func fetchUser(userId: String) async throws -> User? {
        let predicate = NSPredicate(format: "userId == %@", userId)
        let query = CKQuery(recordType: "User", predicate: predicate)
        
        let (results, _) = try await database.records(matching: query)
        
        guard let record = results.first?.1 else {
            return nil
        }
        
        return User(record: record)
    }

    private func createUser(userId: String, email: String, displayName: String) async throws -> User {
        let record = CKRecord(recordType: "User")
        record["userId"] = userId as CKRecordValue
        record["email"] = email as CKRecordValue
        record["displayName"] = displayName as CKRecordValue
        record["role"] = UserRole.associate.rawValue as CKRecordValue
        record["storeCodes"] = ["08"] as CKRecordValue // Default store
        record["departments"] = [] as CKRecordValue
        record["isActive"] = true as CKRecordValue
        
        let savedRecord = try await database.save(record)
        return User(record: savedRecord)!
    }
}
