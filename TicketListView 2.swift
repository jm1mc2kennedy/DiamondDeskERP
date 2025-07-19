// TicketListView.swift
// Diamond Desk ERP

import SwiftUI

struct TicketListView: View {
    @StateObject private var viewModel: TicketViewModel
    @State private var error: IdentifiableError? // Added error state
    
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency // For transparency fallback
    
    init(userRef: String) {
        _viewModel = StateObject(wrappedValue: TicketViewModel(userRef: userRef))
    }

    var body: some View {
        NavigationView {
            // Wrap List in ErrorBoundary to handle errors with retry
            ErrorBoundary(error: $error, retry: { await viewModel.fetchAssignedTickets() }) {
                List {
                    ForEach(viewModel.tickets) { ticket in
                        NavigationLink(destination: TicketDetailView(ticket: ticket)) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(ticket.title)
                                    .font(.body)
                                    .dynamicTypeSize(.large ... .accessibility5)
                                    .accessibilityLabel("Ticket title: \(ticket.title)") // Added accessibilityLabel
                                Text(ticket.status)
                                    .font(.body)
                                    .dynamicTypeSize(.large ... .accessibility5)
                                    .foregroundColor(.secondary)
                                    .accessibilityLabel("Status: \(ticket.status)") // Added accessibilityLabel
                                Text("Store: \(ticket.storeCode)")
                                    .font(.body)
                                    .dynamicTypeSize(.large ... .accessibility5)
                                    .accessibilityLabel("Store code: \(ticket.storeCode)") // Added accessibilityLabel
                            }
                            // Background with transparency fallback for accessibility
                            .background(
                                reduceTransparency ?
                                Color(.systemBackground)
                                :
                                .ultraThinMaterial
                            , in: RoundedRectangle(cornerRadius: 12))
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
}

#Preview {
    TicketListView(userRef: "demo-user-id")
}
