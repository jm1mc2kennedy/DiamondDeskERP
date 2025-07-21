import SwiftUI

struct TicketListView: View {
    @StateObject private var viewModel = TicketViewModel()
    @Environment(\.currentUser) private var currentUser
    @State private var navigationPath = NavigationPath()

    var body: some View {
        SimpleAdaptiveNavigationView(path: $navigationPath) {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading tickets...")
                } else if let error = viewModel.error {
                    VStack {
                        Text("Error loading tickets")
                        Text(error.localizedDescription).font(.caption)
                    }
                } else if viewModel.tickets.isEmpty {
                    Text("No tickets found.")
                } else {
                    List(viewModel.tickets) { ticket in
                        TicketRow(ticket: ticket)
                    }
                }
            }
            .navigationTitle("My Tickets")
            .onAppear {
                if let user = currentUser {
                    viewModel.fetchTickets(for: user)
                }
            }
        }
    }
}

struct TicketRow: View {
    let ticket: TicketModel

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(ticket.title).font(.headline)
                Spacer()
                Text(ticket.priority.rawValue)
                    .font(.caption)
                    .padding(4)
                    .background(priorityColor(for: ticket.priority))
                    .foregroundColor(.white)
                    .cornerRadius(4)
            }
            Text(ticket.description).font(.subheadline).lineLimit(2)
            HStack {
                Text(ticket.status.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(ticket.category)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private func priorityColor(for priority: TicketPriority) -> Color {
        switch priority {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .orange
        case .urgent: return .red
        }
    }
}

struct TicketListView_Previews: PreviewProvider {
    static var previews: some View {
        TicketListView()
    }
}
