// TicketListView.swift
// Diamond Desk ERP

import SwiftUI

struct TicketListView: View {
    @StateObject private var viewModel: TicketViewModel
    
    // MARK: - Advanced Filtering & Search State
    @State private var searchText = ""
    @State private var selectedStatus: TicketStatusFilter? = nil
    @State private var showFilters = false
    
    init(userRef: String) {
        _viewModel = StateObject(wrappedValue: TicketViewModel(userRef: userRef))
    }
    
    var filteredTickets: [Ticket] {
        viewModel.tickets.filter { ticket in
            // Filter by search text matching title or description (case insensitive)
            let matchesSearchText = searchText.isEmpty ||
            ticket.title.localizedCaseInsensitiveContains(searchText) ||
            ticket.description.localizedCaseInsensitiveContains(searchText)
            
            // Filter by selected status if any
            let matchesStatus = selectedStatus == nil || ticket.status == selectedStatus!.rawValue
            
            return matchesSearchText && matchesStatus
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(filteredTickets) { ticket in
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
            .searchable(text: $searchText, placement: .navigationBarDrawer) // Search bar for filtering by text
            .navigationTitle("Assigned Tickets")
            .refreshable {
                await viewModel.fetchAssignedTickets()
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                }
            }
            .toolbar {
                // Toolbar with Filters button
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        // Filter Status Picker in Menu
                        Picker("Status", selection: $selectedStatus) {
                            Text("All").tag(TicketStatusFilter?.none)
                            ForEach(TicketStatusFilter.allCases) { status in
                                Text(status.rawValue).tag(Optional(status))
                            }
                        }
                        .pickerStyle(.inline)
                        .accessibilityLabel("Filter by ticket status")
                        .accessibilityHint("Choose a status to filter the ticket list")
                    } label: {
                        Label("Filters", systemImage: "line.3.horizontal.decrease.circle")
                    }
                    .accessibilityLabel("Filters menu")
                    .accessibilityHint("Open filters menu to filter tickets by status")
                    .background(
                        // Visual polish background with fallback for accessibility
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemBackground).opacity(0.5))
                            .background(.ultraThinMaterial)
                    )
                }
            }
        }
    }
}

// MARK: - Filter Status Enum for better type safety
enum TicketStatusFilter: String, CaseIterable, Identifiable {
    case open = "Open"
    case inProgress = "In Progress"
    case closed = "Closed"
    
    var id: String { rawValue }
}

// MARK: - Preview
#Preview {
    TicketListView(userRef: "demo-user-id")
}
