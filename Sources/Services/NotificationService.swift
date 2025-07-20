// NotificationService.swift
// Diamond Desk ERP
// Registers and handles CloudKit push subscriptions for Tasks and Tickets

import CloudKit
import SwiftUI

final class NotificationService: ObservableObject {
    static let shared = NotificationService()
    @Published var latestMessage: String?
    private let db = CKContainer.default().publicCloudDatabase
    private init() {}
    
    func registerSubscriptions(for userRef: String) async {
        await registerTaskSubscription(userRef: userRef)
        await registerTicketSubscription(userRef: userRef)
    }
    
    private func registerTaskSubscription(userRef: String) async {
        let sub = CKQuerySubscription(
            recordType: "Task",
            predicate: NSPredicate(format: "assignedUserRefs CONTAINS %@", userRef),
            subscriptionID: "task-changes",
            options: [.firesOnRecordCreation, .firesOnRecordUpdate]
        )
        let info = CKSubscription.NotificationInfo()
        info.title = "Task Update"
        info.alertBody = "A relevant task was updated."
        info.shouldSendContentAvailable = true
        sub.notificationInfo = info
        do { _ = try await db.save(sub) } catch { /* already registered is OK */ }
    }
    
    private func registerTicketSubscription(userRef: String) async {
        let sub = CKQuerySubscription(
            recordType: "Ticket",
            predicate: NSPredicate(format: "assignedUserRef == %@", userRef),
            subscriptionID: "ticket-changes",
            options: [.firesOnRecordCreation, .firesOnRecordUpdate]
        )
        let info = CKSubscription.NotificationInfo()
        info.title = "Ticket Update"
        info.alertBody = "A relevant ticket was updated."
        info.shouldSendContentAvailable = true
        sub.notificationInfo = info
        do { _ = try await db.save(sub) } catch { /* already registered is OK */ }
    }
    
    // Call this from your App/SceneDelegate to intercept push and show banner
    func handleNotification(_ userInfo: [AnyHashable: Any]) {
        // Parse CloudKit notification and emit message
        latestMessage = "You have updates!"
        // For production, parse userInfo for detailed info, update UI if needed
    }
}
