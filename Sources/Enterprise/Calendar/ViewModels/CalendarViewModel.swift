import Foundation
import Combine

@MainActor
public final class CalendarViewModel: ObservableObject {
    @Published public var events: [CalendarEvent] = []
    @Published public var selectedEvent: CalendarEvent?
    @Published public var isLoading = false
    @Published public var error: Error?

    private let service: CalendarServiceProtocol

    private var syncTimer: Timer?
    private let notificationManager = CalendarNotificationManager.shared
    public init(service: CalendarServiceProtocol = CalendarService()) {
        self.service = service
        Task {
            try? await notificationManager.requestAuthorization()
        }
        // start periodic background sync
        syncTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            Task { await self?.fetchChanges(since: Date().addingTimeInterval(-300)) }
        }
    }

    public func loadEvents(from start: Date? = nil, to end: Date? = nil) async {
        isLoading = true
        error = nil
        do {
            let fetched = try await service.fetchEvents(start: start, end: end)
            // Expand recurring events into occurrences within next 7 days
            let occurrences = expandRecurrences(for: fetched, upTo: Date().addingTimeInterval(7*24*3600))
            let allEvents = fetched + occurrences
            self.events = allEvents.sorted { $0.startDate < $1.startDate }
            // schedule notifications
            for event in self.events {
                notificationManager.scheduleNotifications(for: event)
            }
        } catch {
            self.error = error
        }
        isLoading = false
    }

    public func createEvent(_ event: CalendarEvent) async {
        isLoading = true
        error = nil
        do {
            let created = try await service.createEvent(event)
            events.append(created)
            events.sort { $0.startDate < $1.startDate }
        } catch {
            self.error = error
        }
        isLoading = false
    }

    public func updateEvent(_ event: CalendarEvent) async {
        isLoading = true
        error = nil
        do {
            let updated = try await service.updateEvent(event)
            if let idx = events.firstIndex(where: { $0.id == updated.id }) {
                events[idx] = updated
            }
        } catch {
            self.error = error
        }
        isLoading = false
    }

    public func deleteEvent(_ eventID: UUID) async {
        isLoading = true
        error = nil
        do {
            try await service.deleteEvent(eventID)
            events.removeAll { $0.id == eventID }
        } catch {
            self.error = error
        }
        isLoading = false
    }

    public func fetchChanges(since date: Date) async {
        isLoading = true
        error = nil
        do {
            let changes = try await service.fetchEventChanges(since: date)
            for event in changes {
                if let idx = events.firstIndex(where: { $0.id == event.id }) {
                    events[idx] = event
                } else {
                    events.append(event)
                }
            }
            events.sort { $0.startDate < $1.startDate }
        } catch {
            self.error = error
        }
        isLoading = false
    }
    
    // MARK: - Recurrence Expansion
    private func expandRecurrences(for events: [CalendarEvent], upTo endDate: Date) -> [CalendarEvent] {
        var occurrences: [CalendarEvent] = []
        for event in events {
            guard let rule = event.recurrenceRule else { continue }
            var nextDate = event.startDate
            let interval = rule.interval
            while true {
                switch rule.frequency {
                case .daily:
                    nextDate = Calendar.current.date(byAdding: .day, value: interval, to: nextDate) ?? nextDate
                case .weekly:
                    nextDate = Calendar.current.date(byAdding: .weekOfYear, value: interval, to: nextDate) ?? nextDate
                case .monthly:
                    nextDate = Calendar.current.date(byAdding: .month, value: interval, to: nextDate) ?? nextDate
                case .yearly:
                    nextDate = Calendar.current.date(byAdding: .year, value: interval, to: nextDate) ?? nextDate
                }
                if nextDate > endDate { break }
                var occ = event
                let duration = event.endDate.timeIntervalSince(event.startDate)
                occ = CalendarEvent(
                    id: UUID(),
                    title: event.title,
                    notes: event.notes,
                    startDate: nextDate,
                    endDate: nextDate.addingTimeInterval(duration),
                    allDay: event.allDay,
                    location: event.location,
                    recurrenceRule: rule,
                    attendees: event.attendees,
                    reminders: event.reminders,
                    createdBy: event.createdBy,
                    createdAt: event.createdAt,
                    updatedAt: event.updatedAt,
                    isCancelled: event.isCancelled,
                    metadata: event.metadata
                )
                occurrences.append(occ)
            }
        }
        return occurrences
    }
}
