// TicketListView.swift
// Diamond Desk ERP

import SwiftUI

struct TicketListView: View {
    @StateObject private var viewModel: TicketViewModel
    
    init(userRef: String) {
        _viewModel = StateObject(wrappedValue: TicketViewModel(userRef: userRef))
    }

    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.tickets) { ticket in
                    NavigationLink(destination: TicketDetailView(ticket: ticket)) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(ticket.title)
                                .font(.headline)
                            Text(ticket.status)
                                .font(.subheadline).foregroundColor(.secondary)
                            Text("Store: \(ticket.storeCode)")
                                .font(.caption)
                        }
                    }
                }
            }
            .navigationTitle("Assigned Tickets")
            .refreshable {
                await viewModel.fetchAssignedTickets()
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                }
            }
        }
    }
}

#Preview {
    TicketListView(userRef: "demo-user-id")
}
