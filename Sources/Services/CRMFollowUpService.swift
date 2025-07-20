import Foundation
import CloudKit
import Combine
import SwiftUI

@MainActor
class CRMFollowUpService: ObservableObject {
    @Published var upcomingFollowUps: [ClientFollowUp] = []
    @Published var overdueFollowUps: [ClientFollowUp] = []
    @Published var birthdayReminders: [ClientReminder] = []
    @Published var anniversaryReminders: [ClientReminder] = []
    @Published var isLoading = false
    
    private let database: CKDatabase
    private let notificationService: NotificationService
    private var cancellables = Set<AnyCancellable>()
    
    init(
        database: CKDatabase = CKContainer.default().publicCloudDatabase,
        notificationService: NotificationService = .shared
    ) {
        self.database = database
        self.notificationService = notificationService
        
        Task {
            await loadFollowUps()
            await loadReminders()
        }
    }
    
    // MARK: - Follow-up Management
    
    func loadFollowUps() async {
        isLoading = true
        
        do {
            let clients = try await fetchClientsWithFollowUps()
            
            let now = Date()
            let calendar = Calendar.current
            let nextWeek = calendar.date(byAdding: .day, value: 7, to: now) ?? now
            
            var upcoming: [ClientFollowUp] = []
            var overdue: [ClientFollowUp] = []
            
            for client in clients {
                if let followUpDate = client.nextReminderAt {
                    let followUp = ClientFollowUp(
                        id: UUID().uuidString,
                        client: client,
                        followUpDate: followUpDate,
                        type: determineFollowUpType(for: client),
                        priority: calculateFollowUpPriority(for: client, date: followUpDate),
                        notes: client.lastNote ?? ""
                    )
                    
                    if followUpDate < now {
                        overdue.append(followUp)
                    } else if followUpDate <= nextWeek {
                        upcoming.append(followUp)
                    }
                }
            }
            
            upcomingFollowUps = upcoming.sorted { $0.followUpDate < $1.followUpDate }
            overdueFollowUps = overdue.sorted { $0.followUpDate < $1.followUpDate }
            
        } catch {
            print("Failed to load follow-ups: \(error)")
        }
        
        isLoading = false
    }
    
    func createFollowUp(for client: ClientModel, date: Date, type: FollowUpType, notes: String) async throws {
        var updatedClient = client
        updatedClient.nextReminderAt = date
        updatedClient.lastNote = notes
        updatedClient.updatedAt = Date()
        
        // Save the updated client
        let repository = ClientRepository()
        try await repository.save(updatedClient)
        
        // Schedule local notification
        await notificationService.scheduleLocalReminder(for: updatedClient, type: .followUp)
        
        // Reload follow-ups
        await loadFollowUps()
    }
    
    func completeFollowUp(_ followUp: ClientFollowUp, outcome: FollowUpOutcome, nextDate: Date? = nil, notes: String = "") async throws {
        var client = followUp.client
        
        // Record the follow-up completion
        let completion = FollowUpCompletion(
            id: UUID().uuidString,
            clientId: client.id,
            completedAt: Date(),
            outcome: outcome,
            notes: notes,
            completedBy: getCurrentUserId()
        )
        
        // Update client with completion info
        client.lastContactDate = Date()
        client.nextReminderAt = nextDate
        client.lastNote = notes
        client.updatedAt = Date()
        
        // Save completion record and update client
        try await saveFollowUpCompletion(completion)
        
        let repository = ClientRepository()
        try await repository.save(client)
        
        // Schedule next reminder if provided
        if let nextDate = nextDate {
            await notificationService.scheduleLocalReminder(for: client, type: .followUp)
        }
        
        // Reload follow-ups
        await loadFollowUps()
    }
    
    func snoozeFollowUp(_ followUp: ClientFollowUp, until date: Date) async throws {
        var client = followUp.client
        client.nextReminderAt = date
        client.updatedAt = Date()
        
        let repository = ClientRepository()
        try await repository.save(client)
        
        // Reschedule notification
        await notificationService.scheduleLocalReminder(for: client, type: .followUp)
        
        await loadFollowUps()
    }
    
    // MARK: - Birthday & Anniversary Reminders
    
    func loadReminders() async {
        do {
            let clients = try await fetchAllClients()
            
            let now = Date()
            let calendar = Calendar.current
            let nextMonth = calendar.date(byAdding: .month, value: 1, to: now) ?? now
            
            var birthdays: [ClientReminder] = []
            var anniversaries: [ClientReminder] = []
            
            for client in clients {
                // Birthday reminders
                if let birthday = client.birthday {
                    if let nextBirthday = calendar.nextDate(
                        after: now,
                        matching: calendar.dateComponents([.month, .day], from: birthday),
                        matchingPolicy: .nextTime
                    ), nextBirthday <= nextMonth {
                        let reminder = ClientReminder(
                            id: UUID().uuidString,
                            client: client,
                            date: nextBirthday,
                            type: .birthday,
                            daysUntil: calendar.dateComponents([.day], from: now, to: nextBirthday).day ?? 0
                        )
                        birthdays.append(reminder)
                    }
                }
                
                // Anniversary reminders
                if let anniversary = client.anniversary {
                    if let nextAnniversary = calendar.nextDate(
                        after: now,
                        matching: calendar.dateComponents([.month, .day], from: anniversary),
                        matchingPolicy: .nextTime
                    ), nextAnniversary <= nextMonth {
                        let reminder = ClientReminder(
                            id: UUID().uuidString,
                            client: client,
                            date: nextAnniversary,
                            type: .anniversary,
                            daysUntil: calendar.dateComponents([.day], from: now, to: nextAnniversary).day ?? 0
                        )
                        anniversaries.append(reminder)
                    }
                }
            }
            
            birthdayReminders = birthdays.sorted { $0.date < $1.date }
            anniversaryReminders = anniversaries.sorted { $0.date < $1.date }
            
        } catch {
            print("Failed to load reminders: \(error)")
        }
    }
    
    func scheduleReminderNotifications() async {
        // Schedule birthday notifications
        for reminder in birthdayReminders {
            if reminder.daysUntil <= 7 {
                await notificationService.scheduleLocalReminder(for: reminder.client, type: .birthday)
            }
        }
        
        // Schedule anniversary notifications
        for reminder in anniversaryReminders {
            if reminder.daysUntil <= 7 {
                await notificationService.scheduleLocalReminder(for: reminder.client, type: .anniversary)
            }
        }
    }
    
    func markReminderAsHandled(_ reminder: ClientReminder) async {
        // Record that the reminder was acknowledged
        let completion = ReminderCompletion(
            id: UUID().uuidString,
            clientId: reminder.client.id,
            reminderType: reminder.type,
            handledAt: Date(),
            handledBy: getCurrentUserId()
        )
        
        try? await saveReminderCompletion(completion)
        
        // Remove from active reminders
        switch reminder.type {
        case .birthday:
            birthdayReminders.removeAll { $0.id == reminder.id }
        case .anniversary:
            anniversaryReminders.removeAll { $0.id == reminder.id }
        case .followUp:
            break // Handled separately
        }
    }
    
    // MARK: - Smart Follow-up Suggestions
    
    func generateSmartFollowUpSuggestions() async -> [FollowUpSuggestion] {
        do {
            let clients = try await fetchAllClients()
            var suggestions: [FollowUpSuggestion] = []
            
            let now = Date()
            let calendar = Calendar.current
            
            for client in clients {
                // Check for various follow-up triggers
                
                // 1. Long time since last contact
                if let lastContact = client.lastContactDate {
                    let daysSinceContact = calendar.dateComponents([.day], from: lastContact, to: now).day ?? 0
                    if daysSinceContact > 30 {
                        suggestions.append(FollowUpSuggestion(
                            id: UUID().uuidString,
                            client: client,
                            type: .longTimeNoContact,
                            priority: .medium,
                            suggestedDate: calendar.date(byAdding: .day, value: 1, to: now) ?? now,
                            reason: "No contact for \(daysSinceContact) days",
                            suggestedAction: "Check in and see how they're doing"
                        ))
                    }
                }
                
                // 2. Purchase anniversary
                if let lastPurchase = client.lastPurchaseDate {
                    let monthsSincePurchase = calendar.dateComponents([.month], from: lastPurchase, to: now).month ?? 0
                    if monthsSincePurchase == 12 {
                        suggestions.append(FollowUpSuggestion(
                            id: UUID().uuidString,
                            client: client,
                            type: .purchaseAnniversary,
                            priority: .high,
                            suggestedDate: now,
                            reason: "One year since last purchase",
                            suggestedAction: "Offer special anniversary discount or new collection preview"
                        ))
                    }
                }
                
                // 3. High-value client check-in
                if client.totalSpent > 5000 && client.lastContactDate == nil {
                    suggestions.append(FollowUpSuggestion(
                        id: UUID().uuidString,
                        client: client,
                        type: .vipCheckIn,
                        priority: .high,
                        suggestedDate: now,
                        reason: "High-value client with no recent contact",
                        suggestedAction: "VIP check-in and exclusive offer"
                    ))
                }
                
                // 4. Seasonal opportunities
                let currentMonth = calendar.component(.month, from: now)
                if (currentMonth == 2 || currentMonth == 5 || currentMonth == 12) && client.interestedInPromotions {
                    suggestions.append(FollowUpSuggestion(
                        id: UUID().uuidString,
                        client: client,
                        type: .seasonalOpportunity,
                        priority: .low,
                        suggestedDate: now,
                        reason: "Seasonal promotion opportunity",
                        suggestedAction: "Share seasonal collection and promotions"
                    ))
                }
            }
            
            return suggestions.sorted { $0.priority.sortOrder < $1.priority.sortOrder }
            
        } catch {
            print("Failed to generate suggestions: \(error)")
            return []
        }
    }
    
    // MARK: - Data Fetching
    
    private func fetchClientsWithFollowUps() async throws -> [ClientModel] {
        let predicate = NSPredicate(format: "nextReminderAt != nil")
        let query = CKQuery(recordType: "Client", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "nextReminderAt", ascending: true)]
        
        let records = try await database.records(matching: query)
        return records.matchResults.compactMap { result in
            switch result.1 {
            case .success(let record):
                return ClientModel(record: record)
            case .failure(_):
                return nil
            }
        }
    }
    
    private func fetchAllClients() async throws -> [ClientModel] {
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "Client", predicate: predicate)
        
        let records = try await database.records(matching: query)
        return records.matchResults.compactMap { result in
            switch result.1 {
            case .success(let record):
                return ClientModel(record: record)
            case .failure(_):
                return nil
            }
        }
    }
    
    private func saveFollowUpCompletion(_ completion: FollowUpCompletion) async throws {
        let record = try completion.toRecord()
        _ = try await database.save(record)
    }
    
    private func saveReminderCompletion(_ completion: ReminderCompletion) async throws {
        let record = try completion.toRecord()
        _ = try await database.save(record)
    }
    
    // MARK: - Helper Methods
    
    private func determineFollowUpType(for client: ClientModel) -> FollowUpType {
        let now = Date()
        let calendar = Calendar.current
        
        if let lastPurchase = client.lastPurchaseDate {
            let daysSincePurchase = calendar.dateComponents([.day], from: lastPurchase, to: now).day ?? 0
            if daysSincePurchase <= 7 {
                return .postPurchase
            }
        }
        
        if let lastContact = client.lastContactDate {
            let daysSinceContact = calendar.dateComponents([.day], from: lastContact, to: now).day ?? 0
            if daysSinceContact > 90 {
                return .reengagement
            }
        }
        
        return .general
    }
    
    private func calculateFollowUpPriority(for client: ClientModel, date: Date) -> FollowUpPriority {
        let now = Date()
        let calendar = Calendar.current
        let daysOverdue = calendar.dateComponents([.day], from: date, to: now).day ?? 0
        
        if daysOverdue > 7 {
            return .high
        } else if daysOverdue > 0 {
            return .medium
        } else {
            return .low
        }
    }
    
    private func getCurrentUserId() -> String {
        return UserDefaults.standard.string(forKey: "currentUserId") ?? ""
    }
}

// MARK: - Supporting Models

struct ClientFollowUp: Identifiable {
    let id: String
    let client: ClientModel
    let followUpDate: Date
    let type: FollowUpType
    let priority: FollowUpPriority
    let notes: String
    
    var isOverdue: Bool {
        followUpDate < Date()
    }
    
    var daysSinceDate: Int {
        Calendar.current.dateComponents([.day], from: followUpDate, to: Date()).day ?? 0
    }
}

struct ClientReminder: Identifiable {
    let id: String
    let client: ClientModel
    let date: Date
    let type: ReminderType
    let daysUntil: Int
}

struct FollowUpCompletion: Identifiable {
    let id: String
    let clientId: String
    let completedAt: Date
    let outcome: FollowUpOutcome
    let notes: String
    let completedBy: String
    
    func toRecord() throws -> CKRecord {
        let record = CKRecord(recordType: "FollowUpCompletion", recordID: CKRecord.ID(recordName: id))
        record["id"] = id
        record["clientId"] = clientId
        record["completedAt"] = completedAt
        record["outcome"] = outcome.rawValue
        record["notes"] = notes
        record["completedBy"] = completedBy
        return record
    }
}

struct ReminderCompletion: Identifiable {
    let id: String
    let clientId: String
    let reminderType: ReminderType
    let handledAt: Date
    let handledBy: String
    
    func toRecord() throws -> CKRecord {
        let record = CKRecord(recordType: "ReminderCompletion", recordID: CKRecord.ID(recordName: id))
        record["id"] = id
        record["clientId"] = clientId
        record["reminderType"] = reminderType.rawValue
        record["handledAt"] = handledAt
        record["handledBy"] = handledBy
        return record
    }
}

struct FollowUpSuggestion: Identifiable {
    let id: String
    let client: ClientModel
    let type: SuggestionType
    let priority: SuggestionPriority
    let suggestedDate: Date
    let reason: String
    let suggestedAction: String
}

enum FollowUpType {
    case general
    case postPurchase
    case reengagement
    case vipCheckIn
    case seasonal
}

enum FollowUpPriority {
    case low
    case medium
    case high
    
    var color: Color {
        switch self {
        case .low: return .blue
        case .medium: return .orange
        case .high: return .red
        }
    }
}

enum FollowUpOutcome: String, CaseIterable {
    case contacted = "contacted"
    case leftMessage = "left_message"
    case scheduled = "scheduled"
    case notInterested = "not_interested"
    case purchaseMade = "purchase_made"
    case needsCallback = "needs_callback"
}

enum SuggestionType {
    case longTimeNoContact
    case purchaseAnniversary
    case vipCheckIn
    case seasonalOpportunity
}

enum SuggestionPriority {
    case low
    case medium
    case high
    
    var sortOrder: Int {
        switch self {
        case .high: return 0
        case .medium: return 1
        case .low: return 2
        }
    }
}
