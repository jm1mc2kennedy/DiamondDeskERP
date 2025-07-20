import SwiftUI

public struct EventDetailView: View {
    @ObservedObject var viewModel: CalendarViewModel
    let event: CalendarEvent
    @Environment(\.dismiss) private var dismiss

    public var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Details")) {
                    Text(event.title).font(.headline)
                    Text(event.notes ?? "").font(.body)
                    HStack { Text("Start"); Spacer(); Text(formatDate(event.startDate)) }
                    HStack { Text("End"); Spacer(); Text(formatDate(event.endDate)) }
                    if let loc = event.location { HStack { Text("Location"); Spacer(); Text(loc) } }
                }
                Section(header: Text("Attendees")) {
                    if event.attendees.isEmpty {
                        Text("None")
                    } else {
                        ForEach(event.attendees) { att in
                            HStack {
                                Text(att.name)
                                Spacer()
                                Text(att.responseStatus.rawValue.capitalized)
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                        }
                    }
                }
                Section {
                    Button("Edit") {
                        viewModel.selectedEvent = event
                    }
                    .disabled(viewModel.isLoading)
                    Button("Delete") {
                        Task { await viewModel.deleteEvent(event.id); dismiss() }
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Event Details")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        fmt.timeStyle = .short
        return fmt.string(from: date)
    }
}
