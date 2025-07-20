import Foundation
import CloudKit

struct ClientModel: Identifiable, Hashable {
    // Core identification
    let id: CKRecord.ID
    var guestName: String
    var partnerName: String?
    
    // Contact information
    var email: String
    var phoneNumber: String?
    var alternatePhone: String?
    var address: String?
    var city: String?
    var state: String?
    var zipCode: String?
    var country: String?
    
    // Preferences and details
    var contactPreference: [String]
    var notes: String?
    var assignedUserRef: CKRecord.Reference
    var preferredStoreCode: String
    
    // CRM tracking fields
    var lastInteraction: Date?
    var lastContactDate: Date?
    var lastPurchaseDate: Date?
    var nextReminderAt: Date?
    var lastNote: String?
    var totalSpent: Double
    var interestedInPromotions: Bool
    
    // Special dates
    var birthday: Date?
    var anniversary: Date?
    
    // Metadata
    var createdAt: Date
    var updatedAt: Date
    
    // Computed properties
    var fullName: String {
        if let partnerName = partnerName, !partnerName.isEmpty {
            return "\(guestName) & \(partnerName)"
        }
        return guestName
    }
    
    var primaryPhone: String {
        return phoneNumber ?? alternatePhone ?? ""
    }
    
    var fullAddress: String {
        let components = [address, city, state, zipCode].compactMap { $0?.isEmpty == false ? $0 : nil }
        return components.joined(separator: ", ")
    }

    init?(record: CKRecord) {
        guard
            let guestName = record["guestName"] as? String,
            let email = record["email"] as? String,
            let contactPreference = record["contactPreference"] as? [String],
            let assignedUserRef = record["assignedUserRef"] as? CKRecord.Reference,
            let preferredStoreCode = record["preferredStoreCode"] as? String
        else {
            return nil
        }

        self.id = record.recordID
        self.guestName = guestName
        self.email = email
        self.partnerName = record["partnerName"] as? String
        self.phoneNumber = record["phoneNumber"] as? String
        self.alternatePhone = record["alternatePhone"] as? String
        self.address = record["address"] as? String
        self.city = record["city"] as? String
        self.state = record["state"] as? String
        self.zipCode = record["zipCode"] as? String
        self.country = record["country"] as? String
        self.contactPreference = contactPreference
        self.notes = record["notes"] as? String
        self.assignedUserRef = assignedUserRef
        self.preferredStoreCode = preferredStoreCode
        self.lastInteraction = record["lastInteraction"] as? Date
        self.lastContactDate = record["lastContactDate"] as? Date
        self.lastPurchaseDate = record["lastPurchaseDate"] as? Date
        self.nextReminderAt = record["nextReminderAt"] as? Date
        self.lastNote = record["lastNote"] as? String
        self.totalSpent = record["totalSpent"] as? Double ?? 0.0
        self.interestedInPromotions = record["interestedInPromotions"] as? Bool ?? true
        self.birthday = record["birthday"] as? Date
        self.anniversary = record["anniversary"] as? Date
        self.createdAt = record["createdAt"] as? Date ?? Date()
        self.updatedAt = record["updatedAt"] as? Date ?? Date()
    }
    
    // Initialize with minimal required fields
    init(
        guestName: String,
        email: String,
        assignedUserRef: CKRecord.Reference,
        preferredStoreCode: String
    ) {
        self.id = CKRecord.ID(recordName: UUID().uuidString)
        self.guestName = guestName
        self.email = email
        self.partnerName = nil
        self.phoneNumber = nil
        self.alternatePhone = nil
        self.address = nil
        self.city = nil
        self.state = nil
        self.zipCode = nil
        self.country = nil
        self.contactPreference = ["email"]
        self.notes = nil
        self.assignedUserRef = assignedUserRef
        self.preferredStoreCode = preferredStoreCode
        self.lastInteraction = nil
        self.lastContactDate = nil
        self.lastPurchaseDate = nil
        self.nextReminderAt = nil
        self.lastNote = nil
        self.totalSpent = 0.0
        self.interestedInPromotions = true
        self.birthday = nil
        self.anniversary = nil
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    func toRecord() -> CKRecord {
        let record = CKRecord(recordType: "Client", recordID: id)
        
        // Core fields
        record["guestName"] = guestName
        record["email"] = email
        record["partnerName"] = partnerName
        record["phoneNumber"] = phoneNumber
        record["alternatePhone"] = alternatePhone
        record["address"] = address
        record["city"] = city
        record["state"] = state
        record["zipCode"] = zipCode
        record["country"] = country
        record["contactPreference"] = contactPreference
        record["notes"] = notes
        record["assignedUserRef"] = assignedUserRef
        record["preferredStoreCode"] = preferredStoreCode
        
        // CRM fields
        record["lastInteraction"] = lastInteraction
        record["lastContactDate"] = lastContactDate
        record["lastPurchaseDate"] = lastPurchaseDate
        record["nextReminderAt"] = nextReminderAt
        record["lastNote"] = lastNote
        record["totalSpent"] = totalSpent
        record["interestedInPromotions"] = interestedInPromotions
        
        // Special dates
        record["birthday"] = birthday
        record["anniversary"] = anniversary
        
        // Metadata
        record["createdAt"] = createdAt
        record["updatedAt"] = updatedAt
        
        return record
    }
}

// MARK: - Supporting Types

enum ReminderType: String, CaseIterable {
    case followUp = "follow_up"
    case birthday = "birthday"
    case anniversary = "anniversary"
    
    var displayName: String {
        switch self {
        case .followUp: return "Follow-up"
        case .birthday: return "Birthday"
        case .anniversary: return "Anniversary"
        }
    }
}
