// TicketListView.swift
// Diamond Desk ERP

import SwiftUI
import CloudKit

struct TicketListView: View {
    @StateObject private var viewModel: TicketViewModel
    @State private var selection: Set<CKRecord.ID> = [] // Multi-selection state
    @State private var showDeleteAlert = false // Controls delete confirmation alert
    @State private var deleteErrorAlertMessage: String? = nil // Error message for delete failures
    
    init(userRef: String) {
        _viewModel = StateObject(wrappedValue: TicketViewModel(userRef: userRef))
    }

    var body: some View {
        NavigationView {
            List(selection: $selection) { // Enable multi-selection in List
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
            .toolbar {
                // Toolbar Delete button, enabled only if there is a selection
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        // Show confirmation alert when delete button tapped
                        showDeleteAlert = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    .disabled(selection.isEmpty)
                    .accessibilityLabel("Delete selected tickets")
                    .accessibilityHint(selection.isEmpty ? "No tickets selected" : "Deletes the selected tickets")
                }
            }
            .alert("Delete Tickets?", isPresented: $showDeleteAlert, actions: {
                Button("Delete", role: .destructive) {
                    Task {
                        await deleteSelectedTickets()
                    }
                }
                Button("Cancel", role: .cancel) { }
            }, message: {
                Text("Are you sure you want to delete the selected tickets? This action cannot be undone.")
            })
            // Error alert for delete failures
            .alert("Error", isPresented: Binding(
                get: { deleteErrorAlertMessage != nil },
                set: { if !$0 { deleteErrorAlertMessage = nil } }
            ), actions: {
                Button("OK", role: .cancel) { }
            }, message: {
                Text(deleteErrorAlertMessage ?? "")
            })
        }
    }
    
    // Async function to delete selected tickets via viewModel/repository
    private func deleteSelectedTickets() async {
        // Guard against empty selection, though button disables itself
        guard !selection.isEmpty else { return }
        
        do {
            // Attempt to delete all selected tickets
            try await viewModel.deleteTickets(withIDs: Array(selection))
            
            // Clear selection and refresh the ticket list
            selection.removeAll()
            await viewModel.fetchAssignedTickets()
        } catch {
            // On failure, show error alert with localized message
            deleteErrorAlertMessage = error.localizedDescription
        }
    }
}

#Preview {
    TicketListView(userRef: "demo-user-id")
}
