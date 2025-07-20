import SwiftUI

struct EditTicketView: View {
    @StateObject private var viewModel = TicketViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.currentUser) private var currentUser
    
    let ticket: TicketModel
    
    @State private var title: String
    @State private var description: String
    @State private var selectedPriority: TicketPriority
    @State private var selectedStatus: TicketStatus
    @State private var selectedCategory: String
    @State private var estimatedResolutionTime: TimeInterval
    @State private var selectedAssignee: User?
    @State private var selectedWatchers: Set<User>
    @State private var showingUserPicker = false
    @State private var showingWatcherPicker = false
    
    @State private var isUpdating = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingDeleteConfirmation = false
    @State private var showingStatusHistory = false
    
    private let categories = [
        "Technical Support",
        "Bug Report",
        "Feature Request",
        "Account Issue",
        "Billing Question",
        "Training Request",
        "General Inquiry",
        "Security Issue",
        "Performance Issue",
        "Data Issue"
    ]
    
    init(ticket: TicketModel) {
        self.ticket = ticket
        self._title = State(initialValue: ticket.title)
        self._description = State(initialValue: ticket.description)
        self._selectedPriority = State(initialValue: ticket.priority)
        self._selectedStatus = State(initialValue: ticket.status)
        self._selectedCategory = State(initialValue: ticket.category)
        self._estimatedResolutionTime = State(initialValue: ticket.estimatedResolutionTime)
        self._selectedAssignee = State(initialValue: ticket.assignee)
        self._selectedWatchers = State(initialValue: Set(ticket.watchers))
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Ticket Details") {
                    TextField("Title", text: $title)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Description")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextEditor(text: $description)
                            .frame(minHeight: 100)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                            )
                    }
                    
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                Section("Priority & Status") {
                    Picker("Priority", selection: $selectedPriority) {
                        ForEach(TicketPriority.allCases, id: \.self) { priority in
                            HStack {
                                Circle()
                                    .fill(priority.color)
                                    .frame(width: 8, height: 8)
                                Text(priority.displayName)
                            }
                            .tag(priority)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    
                    HStack {
                        Picker("Status", selection: $selectedStatus) {
                            ForEach(TicketStatus.allCases, id: \.self) { status in
                                Text(status.displayName).tag(status)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        
                        Button("History") {
                            showingStatusHistory = true
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                }
                
                Section("Assignment") {
                    HStack {
                        Text("Assignee")
                        Spacer()
                        if let assignee = selectedAssignee {
                            VStack(alignment: .trailing) {
                                Text(assignee.displayName)
                                    .foregroundColor(.secondary)
                                Text(assignee.email)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            Text("Select Assignee")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        showingUserPicker = true
                    }
                    
                    HStack {
                        Text("Watchers")
                        Spacer()
                        Text("\(selectedWatchers.count) watching")
                            .foregroundColor(.secondary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        showingWatcherPicker = true
                    }
                    
                    if !selectedWatchers.isEmpty {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 8) {
                            ForEach(Array(selectedWatchers), id: \.id) { user in
                                HStack(spacing: 4) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(user.displayName)
                                            .font(.caption)
                                            .lineLimit(1)
                                        Text(user.email)
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                    }
                                    
                                    Button(action: {
                                        selectedWatchers.remove(user)
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.secondary)
                                            .font(.caption)
                                    }
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .background(Color.secondary.opacity(0.1))
                                .cornerRadius(12)
                            }
                        }
                    }
                }
                
                Section("SLA & Timeline") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Estimated Resolution Time")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Picker("Resolution Time", selection: $estimatedResolutionTime) {
                            Text("2 hours").tag(TimeInterval(7200))
                            Text("4 hours").tag(TimeInterval(14400))
                            Text("1 day").tag(TimeInterval(86400))
                            Text("2 days").tag(TimeInterval(172800))
                            Text("1 week").tag(TimeInterval(604800))
                            Text("2 weeks").tag(TimeInterval(1209600))
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    
                    // SLA Information
                    VStack(alignment: .leading, spacing: 4) {
                        Text("SLA Information")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Text("Created:")
                            Spacer()
                            Text(ticket.createdAt.formatted(date: .abbreviated, time: .shortened))
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Last Updated:")
                            Spacer()
                            Text(ticket.updatedAt.formatted(date: .abbreviated, time: .shortened))
                                .foregroundColor(.secondary)
                        }
                        
                        if !ticket.responseDeltas.isEmpty {
                            HStack {
                                Text("Avg Response Time:")
                                Spacer()
                                Text(formatDuration(ticket.responseDeltas.reduce(0, +) / Double(ticket.responseDeltas.count)))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                Section("Metadata") {
                    HStack {
                        Text("Reporter")
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text(ticket.reporter.displayName)
                                .foregroundColor(.secondary)
                            Text(ticket.reporter.email)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack {
                        Text("Ticket ID")
                        Spacer()
                        Text(ticket.id)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    
                    if !ticket.attachments.isEmpty {
                        HStack {
                            Text("Attachments")
                            Spacer()
                            Text("\(ticket.attachments.count) files")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section("Actions") {
                    if selectedStatus != .closed && selectedStatus != .resolved {
                        Button(action: {
                            selectedStatus = .resolved
                        }) {
                            HStack {
                                Image(systemName: "checkmark.circle")
                                Text("Mark as Resolved")
                            }
                            .foregroundColor(.green)
                        }
                    }
                    
                    if selectedStatus == .resolved {
                        Button(action: {
                            selectedStatus = .closed
                        }) {
                            HStack {
                                Image(systemName: "lock.circle")
                                Text("Close Ticket")
                            }
                            .foregroundColor(.blue)
                        }
                    }
                    
                    Button(action: {
                        showingDeleteConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete Ticket")
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Edit Ticket")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        updateTicket()
                    }
                    .disabled(!isFormValid || isUpdating)
                }
            }
            .sheet(isPresented: $showingUserPicker) {
                UserPickerView(
                    selectedUser: $selectedAssignee,
                    title: "Select Assignee"
                )
            }
            .sheet(isPresented: $showingWatcherPicker) {
                MultiUserPickerView(
                    selectedUsers: $selectedWatchers,
                    title: "Select Watchers"
                )
            }
            .sheet(isPresented: $showingStatusHistory) {
                TicketStatusHistoryView(ticket: ticket)
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .alert("Delete Ticket", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteTicket()
                }
            } message: {
                Text("Are you sure you want to delete this ticket? This action cannot be undone.")
            }
            .overlay {
                if isUpdating {
                    Color.black.opacity(0.3)
                        .overlay {
                            ProgressView("Updating ticket...")
                                .padding()
                                .background(Color(.systemBackground))
                                .cornerRadius(12)
                        }
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !selectedCategory.isEmpty
    }
    
    private func updateTicket() {
        guard let user = currentUser else {
            errorMessage = "User not found"
            showingError = true
            return
        }
        
        isUpdating = true
        
        Task {
            do {
                var updatedTicket = ticket
                updatedTicket.title = title
                updatedTicket.description = description
                updatedTicket.priority = selectedPriority
                updatedTicket.status = selectedStatus
                updatedTicket.category = selectedCategory
                updatedTicket.estimatedResolutionTime = estimatedResolutionTime
                updatedTicket.assignee = selectedAssignee
                updatedTicket.watchers = Array(selectedWatchers)
                updatedTicket.updatedAt = Date()
                
                try await viewModel.updateTicket(updatedTicket)
                
                await MainActor.run {
                    isUpdating = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isUpdating = false
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
    }
    
    private func deleteTicket() {
        isUpdating = true
        
        Task {
            do {
                try await viewModel.deleteTicket(ticket)
                
                await MainActor.run {
                    isUpdating = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isUpdating = false
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration) ?? "Unknown"
    }
}

// Supporting status history view
struct TicketStatusHistoryView: View {
    let ticket: TicketModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section("Current Status") {
                    HStack {
                        Circle()
                            .fill(ticket.priority.color)
                            .frame(width: 12, height: 12)
                        VStack(alignment: .leading) {
                            Text(ticket.status.displayName)
                                .font(.headline)
                            Text("Priority: \(ticket.priority.displayName)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text(ticket.updatedAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Response Times") {
                    if ticket.responseDeltas.isEmpty {
                        Text("No response data available")
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        ForEach(Array(ticket.responseDeltas.enumerated()), id: \.offset) { index, delta in
                            HStack {
                                Text("Response \(index + 1)")
                                Spacer()
                                Text(formatDuration(delta))
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        HStack {
                            Text("Average Response Time")
                                .font(.headline)
                            Spacer()
                            Text(formatDuration(ticket.responseDeltas.reduce(0, +) / Double(ticket.responseDeltas.count)))
                                .font(.headline)
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationTitle("Status History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.day, .hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration) ?? "Unknown"
    }
}

#Preview {
    EditTicketView(ticket: TicketModel.sampleTicket)
        .environment(\.currentUser, User.sampleUser)
}
