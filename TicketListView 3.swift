// TicketListView.swift
// Diamond Desk ERP

import SwiftUI

struct TicketListView: View {
    @StateObject private var viewModel: TicketViewModel
    
    // State vars for showing the ticket sheet and editing a ticket
    @State private var showTicketSheet = false
    @State private var editingTicket: TicketModel?
    
    // State vars for alert management in TicketSheet
    @State private var alertItem: AlertItem?
    
    init(userRef: String) {
        _viewModel = StateObject(wrappedValue: TicketViewModel(userRef: userRef))
    }

    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.tickets) { ticket in
                    // Wrap ticket cell in a button to open editing sheet
                    Button {
                        editingTicket = ticket
                        showTicketSheet = true
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(ticket.title)
                                .font(.headline)
                            Text(ticket.status)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("Store: \(ticket.storeCode)")
                                .font(.caption)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Edit Ticket")
                        .accessibilityHint("Opens form to edit this ticket")
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("Assigned Tickets")
            .refreshable {
                await viewModel.fetchAssignedTickets()
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                        .accessibilityLabel("Loading tickets")
                }
            }
            // Toolbar button for new ticket creation
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        editingTicket = nil
                        showTicketSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("New Ticket")
                    .accessibilityHint("Opens form to create a new ticket")
                }
            }
            // Present sheet for ticket creation/editing
            .sheet(isPresented: $showTicketSheet) {
                TicketSheet(
                    ticketToEdit: editingTicket,
                    onSave: { saved in
                        showTicketSheet = false
                        Task {
                            await viewModel.fetchAssignedTickets()
                        }
                    },
                    onError: { errorMessage in
                        alertItem = AlertItem(title: "Error", message: errorMessage)
                    }
                )
            }
            // Alert for errors in TicketSheet
            .alert(item: $alertItem) { alert in
                Alert(title: Text(alert.title),
                      message: Text(alert.message),
                      dismissButton: .default(Text("OK")))
            }
        }
    }
}

/// Alert item model for alert presentation
struct AlertItem: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}


/// TicketSheet view for creating or editing a ticket
struct TicketSheet: View {
    
    @Environment(\.dismiss) private var dismiss
    
    var ticketToEdit: TicketModel?
    var onSave: (TicketModel) -> Void
    var onError: (String) -> Void
    
    // Editable fields with initial values from ticketToEdit or defaults
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var status: String = "Open"
    @State private var storeCode: String = ""
    @State private var department: String = ""
    
    // Loading & error state for save action
    @State private var isSaving = false
    
    // Status options for picker
    private let statusOptions = ["Open", "In Progress", "Closed", "On Hold"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Ticket Information")) {
                    TextField("Title", text: $title)
                        .accessibilityLabel("Title")
                        .accessibilityHint("Enter the ticket title")
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                        .accessibilityLabel("Description")
                        .accessibilityHint("Enter the ticket description")
                    Picker("Status", selection: $status) {
                        ForEach(statusOptions, id: \.self) { option in
                            Text(option)
                        }
                    }
                    .pickerStyle(.menu)
                    .accessibilityLabel("Status")
                    .accessibilityHint("Select the ticket status")
                }
                
                Section(header: Text("Additional Details")) {
                    TextField("Store Code", text: $storeCode)
                        .accessibilityLabel("Store Code")
                        .accessibilityHint("Enter the store code")
                    TextField("Department", text: $department)
                        .accessibilityLabel("Department")
                        .accessibilityHint("Enter the department")
                }
                
                if isSaving {
                    Section {
                        HStack {
                            Spacer()
                            ProgressView()
                                .accessibilityLabel("Saving ticket")
                            Spacer()
                        }
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle(ticketToEdit == nil ? "New Ticket" : "Edit Ticket")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .accessibilityLabel("Cancel")
                    .accessibilityHint("Dismiss the ticket form without saving")
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveTicket()
                    }
                    .disabled(isSaving)
                    .accessibilityLabel("Save")
                    .accessibilityHint("Save the ticket")
                }
            }
            .onAppear {
                if let ticket = ticketToEdit {
                    // Populate fields for editing
                    title = ticket.title
                    description = ticket.description
                    status = ticket.status
                    storeCode = ticket.storeCode
                    department = ticket.department
                }
            }
        }
    }
    
    /// Validate inputs and save the ticket using repository, then call onSave or onError
    private func saveTicket() {
        // Validate required fields
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            onError("Title cannot be empty.")
            return
        }
        guard !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            onError("Description cannot be empty.")
            return
        }
        guard !storeCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            onError("Store Code cannot be empty.")
            return
        }
        guard !department.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            onError("Department cannot be empty.")
            return
        }
        
        isSaving = true
        
        // Create new ticket or update existing
        var ticket = ticketToEdit ?? TicketModel()
        ticket.title = title
        ticket.description = description
        ticket.status = status
        ticket.storeCode = storeCode
        ticket.department = department
        
        Task {
            do {
                try await TicketRepository.shared.save(ticket: ticket)
                DispatchQueue.main.async {
                    isSaving = false
                    onSave(ticket)
                }
            } catch {
                DispatchQueue.main.async {
                    isSaving = false
                    onError("Failed to save ticket. Please try again.")
                }
            }
        }
    }
}

#Preview {
    TicketListView(userRef: "demo-user-id")
}
