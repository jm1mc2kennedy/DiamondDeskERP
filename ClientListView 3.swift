// ClientListView.swift
// Diamond Desk ERP

import SwiftUI

struct ClientListView: View {
    @StateObject private var viewModel: ClientViewModel
    
    // --- Advanced Filtering & Search ---
    @State private var searchText: String = ""
    @State private var selectedStore: String? = nil
    @State private var followUpFilter: FollowUpFilter = .all
    @State private var showFilters: Bool = false
    
    // Assume we have these store codes available, or use actual store list from viewModel if exists
    private let storeCodes = ["Store A", "Store B", "Store C"]
    
    enum FollowUpFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case due = "Due"
        case notDue = "Not Due"
        
        var id: String { self.rawValue }
    }
    
    init(userRef: String) {
        _viewModel = StateObject(wrappedValue: ClientViewModel(userRef: userRef))
    }
    
    var filteredClients: [Client] {
        viewModel.clients.filter { client in
            // Filter by search text (name or account number)
            let matchesSearch = searchText.isEmpty || client.guestName.localizedCaseInsensitiveContains(searchText) || client.guestAcctNumber.localizedCaseInsensitiveContains(searchText)
            
            // Filter by selected store if any
            let matchesStore = selectedStore == nil || client.storeName == selectedStore
            
            // Filter by follow-up status according to followUpFilter
            let matchesFollowUp: Bool
            switch followUpFilter {
            case .all:
                matchesFollowUp = true
            case .due:
                // Assuming "due" means followUpDate is not nil and is today or earlier
                if let followUp = client.followUpDate {
                    matchesFollowUp = followUp <= Date()
                } else {
                    matchesFollowUp = false
                }
            case .notDue:
                // "Not due" means followUpDate is nil or followUpDate is in future
                if let followUp = client.followUpDate {
                    matchesFollowUp = followUp > Date()
                } else {
                    matchesFollowUp = true
                }
            }
            
            return matchesSearch && matchesStore && matchesFollowUp
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(filteredClients) { client in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(client.guestName)
                            .font(.headline)
                        Text("Account #: \(client.guestAcctNumber)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        if let followUp = client.followUpDate {
                            Text("Follow-up: \(followUp, formatter: itemFormatter)")
                                .font(.caption)
                        }
                    }
                    .padding(6)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
            }
            .listStyle(.plain)
            .navigationTitle("My Clients")
            .refreshable {
                await viewModel.fetchAssignedClients()
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                }
            }
            // Add searchable modifier with accessibility label/hint
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic))
            .accessibilityLabel("Search Clients")
            .accessibilityHint("Search clients by name or account number")
            // Toolbar with Filters menu
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        // Filter by Store Picker
                        Picker("Store", selection: Binding(
                            get: { selectedStore ?? "" },
                            set: { newValue in selectedStore = newValue.isEmpty ? nil : newValue }
                        )) {
                            Text("All Stores").tag("")
                            ForEach(storeCodes, id: \.self) { store in
                                Text(store).tag(store)
                            }
                        }
                        .accessibilityLabel("Select Store Filter")
                        .accessibilityHint("Filter clients by their assigned store")
                        Divider()
                        // Filter by Follow-up Status Picker
                        Picker("Follow-up", selection: $followUpFilter) {
                            ForEach(FollowUpFilter.allCases) { filter in
                                Text(filter.rawValue).tag(filter)
                            }
                        }
                        .accessibilityLabel("Select Follow-up Filter")
                        .accessibilityHint("Filter clients by follow-up status")
                    } label: {
                        Label("Filters", systemImage: "line.horizontal.3.decrease.circle")
                    }
                    .background {
                        // Background with ultraThinMaterial and rounded rectangle with fallback for accessibility
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.ultraThinMaterial)
                            .opacity(0.8)
                    }
                    .accessibilityLabel("Filters Menu")
                    .accessibilityHint("Open filter options for clients list")
                }
            }
        }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    return formatter
}()

#Preview {
    ClientListView(userRef: "demo-user-id")
}
