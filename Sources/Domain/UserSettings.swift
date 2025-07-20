import Foundation
import CloudKit

/// User preference and settings model for private database storage
struct UserSettings: Identifiable, Hashable {
    let id: CKRecord.ID
    var userRef: CKRecord.Reference
    var notificationPrefs: [String: Any]
    var crmLayout: CRMLayout
    var darkMode: Bool
    var smartRemindersEnabled: Bool
    var createdAt: Date
    var updatedAt: Date
    
    enum CRMLayout: String, Codable, CaseIterable {
        case tabbed = "tabbed"
        case scroll = "scroll"
    }
    
    init?(record: CKRecord) {
        guard
            let userRef = record["userRef"] as? CKRecord.Reference,
            let crmLayoutRaw = record["crmLayout"] as? String,
            let crmLayout = CRMLayout(rawValue: crmLayoutRaw),
            let darkMode = record["darkMode"] as? Bool,
            let smartRemindersEnabled = record["smartRemindersEnabled"] as? Bool,
            let createdAt = record["createdAt"] as? Date,
            let updatedAt = record["updatedAt"] as? Date
        else {
            return nil
        }
        
        self.id = record.recordID
        self.userRef = userRef
        self.crmLayout = crmLayout
        self.darkMode = darkMode
        self.smartRemindersEnabled = smartRemindersEnabled
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        
        // Decode notification preferences from JSON data
        if let notificationPrefsData = record["notificationPrefs"] as? Data,
           let notificationPrefs = try? JSONSerialization.jsonObject(with: notificationPrefsData) as? [String: Any] {
            self.notificationPrefs = notificationPrefs
        } else {
            self.notificationPrefs = UserSettings.defaultNotificationPrefs()
        }
    }
    
    func toRecord() -> CKRecord {
        let record = CKRecord(recordType: "UserSettings", recordID: id)
        record["userRef"] = userRef as CKRecordValue
        record["crmLayout"] = crmLayout.rawValue as CKRecordValue
        record["darkMode"] = darkMode as CKRecordValue
        record["smartRemindersEnabled"] = smartRemindersEnabled as CKRecordValue
        record["createdAt"] = createdAt as CKRecordValue
        record["updatedAt"] = updatedAt as CKRecordValue
        
        // Encode notification preferences as JSON data
        if let notificationPrefsData = try? JSONSerialization.data(withJSONObject: notificationPrefs) {
            record["notificationPrefs"] = notificationPrefsData as CKRecordValue
        }
        
        return record
    }
    
    static func from(record: CKRecord) -> UserSettings? {
        return UserSettings(record: record)
    }
    
    // MARK: - Factory Methods
    
    /// Create default user settings for a new user
    static func defaultSettings(for userRef: CKRecord.Reference) -> UserSettings {
        let id = CKRecord.ID(recordName: UUID().uuidString)
        let now = Date()
        
        return UserSettings(
            id: id,
            userRef: userRef,
            notificationPrefs: defaultNotificationPrefs(),
            crmLayout: .tabbed,
            darkMode: false,
            smartRemindersEnabled: true,
            createdAt: now,
            updatedAt: now
        )
    }
    
    /// Default notification preferences configuration
    static func defaultNotificationPrefs() -> [String: Any] {
        return [
            "taskAssignments": true,
            "ticketUpdates": true,
            "messageNotifications": true,
            "crmReminders": true,
            "auditDeadlines": true,
            "trainingNotifications": true,
            "systemAnnouncements": true,
            "digestFrequency": "daily", // "none", "daily", "weekly"
            "quietHoursEnabled": false,
            "quietHoursStart": "22:00",
            "quietHoursEnd": "08:00"
        ]
    }
    
    // MARK: - Computed Properties
    
    var isQuietHoursActive: Bool {
        guard let quietHoursEnabled = notificationPrefs["quietHoursEnabled"] as? Bool,
              quietHoursEnabled else {
            return false
        }
        
        // Implementation would check current time against quiet hours
        // Simplified for now
        return false
    }
    
    var digestFrequency: String {
        return notificationPrefs["digestFrequency"] as? String ?? "daily"
    }
    
    // MARK: - Mutation Methods
    
    mutating func updateNotificationPreference(key: String, value: Any) {
        notificationPrefs[key] = value
        updatedAt = Date()
    }
    
    mutating func toggleDarkMode() {
        darkMode.toggle()
        updatedAt = Date()
    }
    
    mutating func setCRMLayout(_ layout: CRMLayout) {
        crmLayout = layout
        updatedAt = Date()
    }
}

// MARK: - UserSettings Convenience Initializer

extension UserSettings {
    init(
        id: CKRecord.ID,
        userRef: CKRecord.Reference,
        notificationPrefs: [String: Any],
        crmLayout: CRMLayout,
        darkMode: Bool,
        smartRemindersEnabled: Bool,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.userRef = userRef
        self.notificationPrefs = notificationPrefs
        self.crmLayout = crmLayout
        self.darkMode = darkMode
        self.smartRemindersEnabled = smartRemindersEnabled
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
