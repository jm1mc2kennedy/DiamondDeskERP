import Foundation
import UserNotifications

public final class CalendarNotificationManager {
    public static let shared = CalendarNotificationManager()

    private init() {}

    public func requestAuthorization() async throws {
        let center = UNUserNotificationCenter.current()
        let granted = try await withCheckedThrowingContinuation { cont in
            center.requestAuthorization(options: [.alert, .sound, .badge]) { success, error in
                if let error = error {
                    cont.resume(throwing: error)
                } else {
                    cont.resume(returning: success)
                }
            }
        }
        if !granted {
            throw NotificationError.authorizationDenied
        }
    }

    public func scheduleNotifications(for event: CalendarEvent) {
        let center = UNUserNotificationCenter.current()
        // Remove existing notifications
        removeNotifications(for: event)
        
        for reminder in event.reminders {
            let content = UNMutableNotificationContent()
            content.title = event.title
            content.body = event.notes ?? "Event Reminder"
            content.sound = .default

            let triggerDate = event.startDate.addingTimeInterval(-reminder.offset)
            let dateComponents = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute, .second],
                from: triggerDate
            )
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            
            let request = UNNotificationRequest(
                identifier: reminder.id.uuidString,
                content: content,
                trigger: trigger
            )
            center.add(request) { error in
                if let error = error {
                    print("Failed to schedule notification: \(error)")
                }
            }
        }
    }

    public func removeNotifications(for event: CalendarEvent) {
        let center = UNUserNotificationCenter.current()
        let ids = event.reminders.map { $0.id.uuidString }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }
}

public enum NotificationError: Error {
    case authorizationDenied
}
