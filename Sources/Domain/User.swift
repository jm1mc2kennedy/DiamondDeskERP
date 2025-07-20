import Foundation
import CloudKit

enum UserRole: String, Codable, CaseIterable {
    case admin = "Admin"
    case areaDirector = "AreaDirector"
    case storeDirector = "StoreDirector"
    case departmentHead = "DepartmentHead"
    case agent = "Agent"
    case associate = "Associate"
}

struct User: Identifiable, Hashable {
    let id: CKRecord.ID
    let userId: String
    let email: String
    let displayName: String
    let role: UserRole
    let storeCodes: [String]
    let departments: [String]
    let isActive: Bool
    let createdAt: Date
    let lastLoginAt: Date?

    init?(record: CKRecord) {
        guard
            let userId = record["userId"] as? String,
            let email = record["email"] as? String,
            let displayName = record["displayName"] as? String,
            let roleRawValue = record["role"] as? String,
            let role = UserRole(rawValue: roleRawValue),
            let storeCodes = record["storeCodes"] as? [String],
            let departments = record["departments"] as? [String],
            let isActive = record["isActive"] as? Bool,
            let createdAt = record["createdAt"] as? Date
        else {
            return nil
        }

        self.id = record.recordID
        self.userId = userId
        self.email = email
        self.displayName = displayName
        self.role = role
        self.storeCodes = storeCodes
        self.departments = departments
        self.isActive = isActive
        self.createdAt = createdAt
        self.lastLoginAt = record["lastLoginAt"] as? Date
    }
}
