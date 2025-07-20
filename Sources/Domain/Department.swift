import Foundation
import CloudKit

struct Department: Identifiable, Hashable {
    let id: CKRecord.ID
    let code: String
    let name: String
    let createdAt: Date
    
    init?(record: CKRecord) {
        guard
            let code = record["code"] as? String,
            let name = record["name"] as? String,
            let createdAt = record["createdAt"] as? Date
        else {
            return nil
        }
        
        self.id = record.recordID
        self.code = code
        self.name = name
        self.createdAt = createdAt
    }
    
    func toRecord() -> CKRecord {
        let record = CKRecord(recordType: "Department", recordID: id)
        record["code"] = code as CKRecordValue
        record["name"] = name as CKRecordValue
        record["createdAt"] = createdAt as CKRecordValue
        return record
    }
    
    static func from(record: CKRecord) -> Department? {
        return Department(record: record)
    }
}

// Predefined department codes from the buildout plan
extension Department {
    static let predefinedDepartments = [
        "HR": "Human Resources",
        "LP": "Loss Prevention", 
        "Ops": "Operations",
        "Marketing": "Marketing",
        "Inventory": "Inventory",
        "QA": "Quality Assurance",
        "Finance": "Finance",
        "Facilities": "Facilities",
        "LossPrevention": "Loss Prevention",
        "Productivity": "Productivity"
    ]
}
