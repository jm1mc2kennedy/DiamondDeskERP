// NotificationService.swift
// Diamond Desk ERP
// Advanced notification system with CloudKit subscriptions, local reminders, and settings management

import CloudKit
import SwiftUI
import UserNotifications
import Combine

@MainActor
final class NotificationService: ObservableObject {
    static let shared = NotificationService()
    
    @Published var latestMessage: String?
    @Published var isSubscribedToNotifications = false
    @Published var notificationSettings = NotificationSettings()
    @Published var pendingNotifications: [PendingNotification] = []
    
    private let database = CKContainer.default().publicCloudDatabase
    private let userNotificationCenter = UNUserNotificationCenter.current()
    private var activeSubscriptions: [CKSubscription.ID: CKSubscription] = [:]
    
    private init() {
        Task {
            await setupNotifications()
        }
    }
    
    // MARK: - Setup & Permissions
    
    func setupNotifications() async {
        await requestNotificationPermissions()
        await loadNotificationSettings()
        await setupCloudKitSubscriptions()
    }
    
    private func requestNotificationPermissions() async {
        do {
            let options: UNAuthorizationOptions = [.alert, .badge, .sound, .provisional]
            let granted = try await userNotificationCenter.requestAuthorization(options: options)
            
            if granted {
                await registerForRemoteNotifications()
                isSubscribedToNotifications = true
            }
        } catch {
            print("Failed to request notification permissions: \(error)")
        }
    }
    
    private func registerForRemoteNotifications() async {
        await MainActor.run {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
    
    // MARK: - Enhanced CloudKit Subscriptions
    
    private func setupCloudKitSubscriptions() async {
        await setupTaskSubscriptions()
        await setupTicketSubscriptions()
        await setupClientSubscriptions()
    }
    
    func registerSubscriptions(for userRef: String) async {
        await setupCloudKitSubscriptions()
    }
    
    private func setupTaskSubscriptions() async {
        guard notificationSettings.taskNotifications.enabled else { return }
        
        do {
            // Enhanced task assignment subscription
            let assignmentSubscription = CKQuerySubscription(
                recordType: "Task",
                predicate: NSPredicate(format: "assignedUserIds CONTAINS %@", getCurrentUserId()),
                subscriptionID: "task-assignments-v2",
                options: [.firesOnRecordCreation, .firesOnRecordUpdate]
            )
            
            let assignmentInfo = CKSubscription.NotificationInfo()
            assignmentInfo.title = "New Task Assigned"
            assignmentInfo.alertBody = "You have been assigned a new task"
            assignmentInfo.shouldBadge = true
            assignmentInfo.shouldSendContentAvailable = true
            assignmentSubscription.notificationInfo = assignmentInfo
            
            let savedSubscription = try await database.save(assignmentSubscription)
            activeSubscriptions[savedSubscription.subscriptionID] = savedSubscription
            
            // Due soon tasks subscription
            if notificationSettings.taskNotifications.dueSoon {
                let dueSoonSubscription = CKQuerySubscription(
                    recordType: "Task",
                    predicate: NSPredicate(format: "dueDate <= %@ AND status != %@", 
                                         Date().addingTimeInterval(24*60*60) as CVarArg,
                                         TaskStatus.completed.rawValue),
                    subscriptionID: "task-due-soon",
                    options: [.firesOnRecordUpdate]
                )
                
                let dueSoonInfo = CKSubscription.NotificationInfo()
                dueSoonInfo.title = "Task Due Soon"
                dueSoonInfo.alertBody = "You have tasks due within 24 hours"
                dueSoonInfo.shouldBadge = true
                dueSoonSubscription.notificationInfo = dueSoonInfo
                
                let savedDueSoon = try await database.save(dueSoonSubscription)
                activeSubscriptions[savedDueSoon.subscriptionID] = savedDueSoon
            }
            
        } catch {
            print("Failed to setup task subscriptions: \(error)")
        }
    }
    
    private func setupTicketSubscriptions() async {
        guard notificationSettings.ticketNotifications.enabled else { return }
        
        do {
            // Enhanced ticket subscription
            let ticketSubscription = CKQuerySubscription(
                recordType: "Ticket",
                predicate: NSPredicate(format: "assignee.id == %@ OR watchers CONTAINS %@", 
                                     getCurrentUserId(), getCurrentUserId()),
                subscriptionID: "ticket-updates-v2",
                options: [.firesOnRecordCreation, .firesOnRecordUpdate]
            )
            
            let ticketInfo = CKSubscription.NotificationInfo()
            ticketInfo.title = "Ticket Update"
            ticketInfo.alertBody = "A ticket has been assigned or updated"
            ticketInfo.shouldBadge = true
            ticketInfo.shouldSendContentAvailable = true
            ticketSubscription.notificationInfo = ticketInfo
            
            let savedSubscription = try await database.save(ticketSubscription)
            activeSubscriptions[savedSubscription.subscriptionID] = savedSubscription
            
        } catch {
            print("Failed to setup ticket subscriptions: \(error)")
        }
    }
    
    private func setupClientSubscriptions() async {
        guard notificationSettings.crmNotifications.enabled else { return }
        
        do {
            // Client follow-up reminders
            let reminderSubscription = CKQuerySubscription(
                recordType: "Client",
                predicate: NSPredicate(format: "nextReminderAt <= %@", Date().addingTimeInterval(24*60*60) as CVarArg),
                subscriptionID: "client-reminders",
                options: [.firesOnRecordUpdate]
            )
            
            let reminderInfo = CKSubscription.NotificationInfo()
            reminderInfo.title = "Client Follow-up"
            reminderInfo.alertBody = "You have client follow-ups due"
            reminderInfo.shouldBadge = true
            reminderSubscription.notificationInfo = reminderInfo
            
            let savedReminder = try await database.save(reminderSubscription)
            activeSubscriptions[savedReminder.subscriptionID] = savedReminder
            
        } catch {
            print("Failed to setup client subscriptions: \(error)")
        }
    }
    
    // MARK: - Local Notifications & Reminders
    
    func scheduleLocalReminder(for client: ClientModel, type: ReminderType) async {
        guard notificationSettings.localReminders else { return }
        
        let content = UNMutableNotificationContent()
        
        switch type {
        case .followUp:
            content.title = "Client Follow-up"
            content.body = "Follow up with \(client.firstName) \(client.lastName)"
        case .birthday:
            content.title = "Client Birthday"
            content.body = "\(client.firstName) \(client.lastName)'s birthday is coming up"
        case .anniversary:
            content.title = "Client Anniversary"
            content.body = "\(client.firstName) \(client.lastName)'s anniversary is coming up"
        }
        
        content.sound = notificationSettings.soundEnabled ? .default : nil
        content.badge = notificationSettings.badgeEnabled ? 1 : 0
        content.userInfo = [
            "type": type.rawValue,
            "clientId": client.id,
            "action": "open_client"
        ]
        
        // Calculate trigger date
        let triggerDate = calculateTriggerDate(for: client, type: type)
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate),
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "\(type.rawValue)-\(client.id)",
            content: content,
            trigger: trigger
        )
        
        do {
            try await userNotificationCenter.add(request)
        } catch {
            print("Failed to schedule local notification: \(error)")
        }
    }
    
    // MARK: - Settings Management
    
    func updateNotificationSettings(_ settings: NotificationSettings) async {
        self.notificationSettings = settings
        await saveNotificationSettings()
        await refreshSubscriptions()
    }
    
    private func loadNotificationSettings() async {
        if let data = UserDefaults.standard.data(forKey: "notificationSettings"),
           let settings = try? JSONDecoder().decode(NotificationSettings.self, from: data) {
            self.notificationSettings = settings
        }
    }
    
    private func saveNotificationSettings() async {
        if let data = try? JSONEncoder().encode(notificationSettings) {
            UserDefaults.standard.set(data, forKey: "notificationSettings")
        }
    }
    
    private func refreshSubscriptions() async {
        // Remove existing subscriptions
        for subscriptionId in activeSubscriptions.keys {
            do {
                try await database.deleteSubscription(withID: subscriptionId)
            } catch {
                print("Failed to delete subscription \(subscriptionId): \(error)")
            }
        }
        activeSubscriptions.removeAll()
        
        // Setup new subscriptions based on current settings
        await setupCloudKitSubscriptions()
    }
    
    // MARK: - Notification Handling
    
    func handleNotification(_ userInfo: [AnyHashable: Any]) {
        if let ckNotification = CKNotification(fromRemoteNotificationDictionary: userInfo) {
            Task {
                await handleCloudKitNotification(ckNotification)
            }
        }
        
        // Legacy support
        if let alertBody = userInfo["aps"] as? [String: Any],
           let message = alertBody["alert"] as? String {
            DispatchQueue.main.async {
                self.latestMessage = message
            }
        }
    }
    
    private func handleCloudKitNotification(_ notification: CKNotification) async {
        guard let queryNotification = notification as? CKQueryNotification,
              let subscriptionID = queryNotification.subscriptionID else { return }
        
        let pendingNotification = PendingNotification(
            id: UUID().uuidString,
            type: getNotificationType(from: subscriptionID),
            title: queryNotification.alertBody ?? "Update",
            message: queryNotification.alertBody ?? "",
            recordID: queryNotification.recordID,
            receivedAt: Date()
        )
        
        pendingNotifications.append(pendingNotification)
        
        // Trigger data refresh
        await triggerDataRefresh(for: subscriptionID)
    }
    
    // MARK: - Helper Methods
    
    private func getCurrentUserId() -> String {
        return UserDefaults.standard.string(forKey: "currentUserId") ?? ""
    }
    
    private func calculateTriggerDate(for client: ClientModel, type: ReminderType) -> Date {
        let calendar = Calendar.current
        let now = Date()
        
        switch type {
        case .followUp:
            return client.nextReminderAt ?? now.addingTimeInterval(24*60*60)
        case .birthday:
            if let birthday = client.birthday {
                let nextBirthday = calendar.nextDate(
                    after: now,
                    matching: calendar.dateComponents([.month, .day], from: birthday),
                    matchingPolicy: .nextTime
                ) ?? now.addingTimeInterval(24*60*60)
                return nextBirthday.addingTimeInterval(-7*24*60*60) // 7 days before
            }
            return now.addingTimeInterval(24*60*60)
        case .anniversary:
            if let anniversary = client.anniversary {
                let nextAnniversary = calendar.nextDate(
                    after: now,
                    matching: calendar.dateComponents([.month, .day], from: anniversary),
                    matchingPolicy: .nextTime
                ) ?? now.addingTimeInterval(24*60*60)
                return nextAnniversary.addingTimeInterval(-7*24*60*60) // 7 days before
            }
            return now.addingTimeInterval(24*60*60)
        }
    }
    
    private func getNotificationType(from subscriptionID: String) -> NotificationType {
        switch subscriptionID {
        case let id where id.contains("task"):
            return .task
        case let id where id.contains("ticket"):
            return .ticket
        case let id where id.contains("client"):
            return .client
        default:
            return .system
        }
    }
    
    private func triggerDataRefresh(for subscriptionID: String) async {
        switch subscriptionID {
        case let id where id.contains("task"):
            NotificationCenter.default.post(name: .refreshTasks, object: nil)
        case let id where id.contains("ticket"):
            NotificationCenter.default.post(name: .refreshTickets, object: nil)
        case let id where id.contains("client"):
            NotificationCenter.default.post(name: .refreshClients, object: nil)
        default:
            break
        }
    }
}

// MARK: - Supporting Models

struct NotificationSettings: Codable {
    var taskNotifications = TaskNotificationSettings()
    var ticketNotifications = TicketNotificationSettings()
    var crmNotifications = CRMNotificationSettings()
    var localReminders = true
    var soundEnabled = true
    var badgeEnabled = true
}

struct TaskNotificationSettings: Codable {
    var enabled = true
    var assignments = true
    var completions = true
    var dueSoon = true
    var overdue = true
}

struct TicketNotificationSettings: Codable {
    var enabled = true
    var assignments = true
    var statusChanges = true
    var comments = true
    var watchers = true
}

struct CRMNotificationSettings: Codable {
    var enabled = true
    var followUps = true
    var birthdays = true
    var anniversaries = true
}

struct PendingNotification: Identifiable {
    let id: String
    let type: NotificationType
    let title: String
    let message: String
    let recordID: CKRecord.ID?
    let receivedAt: Date
}

enum NotificationType {
    case task
    case ticket
    case client
    case system
}

enum ReminderType: String {
    case followUp = "follow_up"
    case birthday = "birthday"
    case anniversary = "anniversary"
}

// MARK: - Notification Names

extension Notification.Name {
    static let refreshTasks = Notification.Name("refreshTasks")
    static let refreshTickets = Notification.Name("refreshTickets")
    static let refreshClients = Notification.Name("refreshClients")
}
        // Parse CloudKit notification and emit message
        latestMessage = "You have updates!"
        // For production, parse userInfo for detailed info, update UI if needed
    }
}
