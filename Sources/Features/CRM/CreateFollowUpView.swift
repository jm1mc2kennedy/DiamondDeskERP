import SwiftUI

struct CreateFollowUpView: View {
    @Environment(\.dismiss) private var dismiss
    let followUpService: CRMFollowUpService
    
    @State private var selectedClient: ClientModel?
    @State private var followUpDate = Date()
    @State private var followUpType: FollowUpType = .general
    @State private var notes = ""
    @State private var isLoading = false
    @State private var searchText = ""
    @State private var clients: [ClientModel] = []
    @State private var showingClientPicker = false
    
    var filteredClients: [ClientModel] {
        if searchText.isEmpty {
            return clients
        } else {
            return clients.filter { client in
                client.fullName.localizedCaseInsensitiveContains(searchText) ||
                client.email.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Client") {
                    if let client = selectedClient {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(client.fullName)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                Text(client.email)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button("Change") {
                                showingClientPicker = true
                            }
                            .font(.caption)
                        }
                    } else {
                        Button("Select Client") {
                            showingClientPicker = true
                        }
                        .foregroundColor(.blue)
                    }
                }
                
                Section("Follow-up Details") {
                    DatePicker("Date", selection: $followUpDate, displayedComponents: [.date, .hourAndMinute])
                    
                    Picker("Type", selection: $followUpType) {
                        Text("General").tag(FollowUpType.general)
                        Text("Post Purchase").tag(FollowUpType.postPurchase)
                        Text("Re-engagement").tag(FollowUpType.reengagement)
                        Text("VIP Check-in").tag(FollowUpType.vipCheckIn)
                        Text("Seasonal").tag(FollowUpType.seasonal)
                    }
                }
                
                Section("Notes") {
                    TextField("Add notes about this follow-up...", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section {
                    Button("Create Follow-up") {
                        createFollowUp()
                    }
                    .disabled(selectedClient == nil || isLoading)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .navigationTitle("New Follow-up")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingClientPicker) {
                ClientPickerView(
                    clients: filteredClients,
                    searchText: $searchText,
                    selectedClient: $selectedClient,
                    onDismiss: { showingClientPicker = false }
                )
            }
            .task {
                await loadClients()
            }
        }
    }
    
    private func loadClients() async {
        do {
            let repository = ClientRepository()
            clients = try await repository.fetchAll()
        } catch {
            print("Failed to load clients: \(error)")
        }
    }
    
    private func createFollowUp() {
        guard let client = selectedClient else { return }
        
        isLoading = true
        
        Task {
            do {
                try await followUpService.createFollowUp(
                    for: client,
                    date: followUpDate,
                    type: followUpType,
                    notes: notes
                )
                
                await MainActor.run {
                    dismiss()
                }
            } catch {
                print("Failed to create follow-up: \(error)")
                isLoading = false
            }
        }
    }
}

struct ClientPickerView: View {
    let clients: [ClientModel]
    @Binding var searchText: String
    @Binding var selectedClient: ClientModel?
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationView {
            VStack {
                SearchBar(text: $searchText, placeholder: "Search clients...")
                
                List(clients) { client in
                    ClientRowView(client: client) {
                        selectedClient = client
                        onDismiss()
                    }
                }
            }
            .navigationTitle("Select Client")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        onDismiss()
                    }
                }
            }
        }
    }
}

struct ClientRowView: View {
    let client: ClientModel
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(client.fullName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(client.email)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let phone = client.phoneNumber {
                        Text(phone)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if let lastContact = client.lastContactDate {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Last Contact")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Text(lastContact, style: .date)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text("New Client")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(4)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SearchBar: View {
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
        .padding(.horizontal)
    }
}

struct CompleteFollowUpView: View {
    @Environment(\.dismiss) private var dismiss
    let followUp: ClientFollowUp
    let followUpService: CRMFollowUpService
    
    @State private var selectedOutcome: FollowUpOutcome = .contacted
    @State private var notes = ""
    @State private var scheduleNext = false
    @State private var nextDate = Date()
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Client") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(followUp.client.fullName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text("Follow-up from \(followUp.followUpDate, style: .date)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if !followUp.notes.isEmpty {
                            Text("Original notes: \(followUp.notes)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .italic()
                        }
                    }
                }
                
                Section("Outcome") {
                    Picker("What happened?", selection: $selectedOutcome) {
                        ForEach(FollowUpOutcome.allCases, id: \.self) { outcome in
                            Text(outcome.displayName).tag(outcome)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                Section("Notes") {
                    TextField("What happened during this follow-up?", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Next Follow-up") {
                    Toggle("Schedule Next Follow-up", isOn: $scheduleNext)
                    
                    if scheduleNext {
                        DatePicker("Next Date", selection: $nextDate, displayedComponents: [.date, .hourAndMinute])
                    }
                }
                
                Section {
                    HStack {
                        Button("Snooze") {
                            snoozeFollowUp()
                        }
                        .foregroundColor(.orange)
                        
                        Spacer()
                        
                        Button("Complete") {
                            completeFollowUp()
                        }
                        .disabled(isLoading)
                    }
                }
            }
            .navigationTitle("Complete Follow-up")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func completeFollowUp() {
        isLoading = true
        
        Task {
            do {
                let nextFollowUpDate = scheduleNext ? nextDate : nil
                
                try await followUpService.completeFollowUp(
                    followUp,
                    outcome: selectedOutcome,
                    nextDate: nextFollowUpDate,
                    notes: notes
                )
                
                await MainActor.run {
                    dismiss()
                }
            } catch {
                print("Failed to complete follow-up: \(error)")
                isLoading = false
            }
        }
    }
    
    private func snoozeFollowUp() {
        isLoading = true
        
        Task {
            do {
                let snoozeDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
                
                try await followUpService.snoozeFollowUp(followUp, until: snoozeDate)
                
                await MainActor.run {
                    dismiss()
                }
            } catch {
                print("Failed to snooze follow-up: \(error)")
                isLoading = false
            }
        }
    }
}

// MARK: - Extensions

extension FollowUpOutcome {
    var displayName: String {
        switch self {
        case .contacted:
            return "Successfully Contacted"
        case .leftMessage:
            return "Left Message"
        case .scheduled:
            return "Appointment Scheduled"
        case .notInterested:
            return "Not Interested"
        case .purchaseMade:
            return "Purchase Made"
        case .needsCallback:
            return "Needs Callback"
        }
    }
}
