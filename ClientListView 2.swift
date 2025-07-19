// ClientListView.swift
// Diamond Desk ERP

import SwiftUI

struct ClientListView: View {
    @StateObject private var viewModel: ClientViewModel
    
    // State variables for showing new client sheet and error handling
    @State private var showNewClientSheet = false
    @State private var error: IdentifiableError?
    
    // Environment to detect reduce transparency accessibility setting
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    
    init(userRef: String) {
        _viewModel = StateObject(wrappedValue: ClientViewModel(userRef: userRef))
    }

    var body: some View {
        NavigationView {
            // Wrap main content in ErrorBoundary to handle and display errors with retry
            ErrorBoundary(error: $error, retryAction: {
                Task {
                    await viewModel.fetchAssignedClients()
                }
            }) {
                List {
                    // Display each client with styled card and details
                    ForEach(viewModel.clients) { client in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(client.guestName)
                                .font(.headline)
                                .accessibilityLabel("Guest Name: \(client.guestName)")
                            Text("Account #: \(client.guestAcctNumber)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .accessibilityLabel("Account number: \(client.guestAcctNumber)")
                            if let followUp = client.followUpDate {
                                Text("Follow-up: \(followUp, formatter: itemFormatter)")
                                    .font(.caption)
                                    .accessibilityLabel("Follow up date: \(followUp, formatter: itemFormatter)")
                            }
                        }
                        .padding(6)
                        // Add background with ultraThinMaterial or fallback based on accessibility setting
                        .background(
                            Group {
                                if reduceTransparency {
                                    Color(.systemBackground)
                                } else {
                                    .ultraThinMaterial
                                }
                            },
                            in: RoundedRectangle(cornerRadius: 12)
                        )
                        .accessibilityElement(children: .combine)
                    }
                }
                .listStyle(.plain)
                .navigationTitle("My Clients")
                // Toolbar button to toggle new client sheet
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showNewClientSheet.toggle()
                        } label: {
                            Image(systemName: "plus")
                        }
                        .accessibilityLabel("Add New Client")
                    }
                }
                // Refresh clients asynchronously
                .refreshable {
                    do {
                        try await viewModel.fetchAssignedClients()
                    } catch {
                        self.error = IdentifiableError(error: error)
                    }
                }
                // Show loading indicator overlay while loading
                .overlay {
                    if viewModel.isLoading {
                        ProgressView()
                    }
                }
                // Present the new client sheet when toggled
                .sheet(isPresented: $showNewClientSheet) {
                    NewClientSheet(userRef: viewModel.userRef) { result in
                        switch result {
                        case .success(let newClient):
                            // On success, add new client to list and dismiss sheet
                            viewModel.clients.append(newClient)
                            showNewClientSheet = false
                        case .failure(let saveError):
                            // Show error alert if save fails
                            self.error = IdentifiableError(error: saveError)
                        }
                    }
                }
            }
        }
    }
}

// DateFormatter for follow-up date display
private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    return formatter
}()

// NewClientSheet view for adding a new client
private struct NewClientSheet: View {
    // Input fields state
    @State private var guestName = ""
    @State private var guestAcctNumber = ""
    
    // Environment to dismiss the sheet
    @Environment(\.dismiss) private var dismiss
    
    // User reference passed from parent
    let userRef: String
    
    // Completion handler to notify parent of save result
    var onSave: (Result<ClientModel, Error>) -> Void
    
    // State for error alert
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    // Repository to save new clients
    private let repo = ClientRepository()
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Client Information")) {
                    TextField("Guest Name", text: $guestName)
                        .accessibilityLabel("Guest Name Input")
                    TextField("Account Number", text: $guestAcctNumber)
                        .accessibilityLabel("Account Number Input")
                        .keyboardType(.default)
                }
            }
            .navigationTitle("New Client")
            // Toolbar with Cancel and Save buttons
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .accessibilityLabel("Cancel Adding New Client")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveClient()
                    }
                    // Enable Save only if both fields are non-empty (trimmed)
                    .disabled(guestName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || guestAcctNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .accessibilityLabel("Save New Client")
                }
            }
            .alert("Error", isPresented: $showAlert, actions: {
                Button("OK", role: .cancel) { }
            }, message: {
                Text(alertMessage)
            })
        }
    }
    
    // Save client function with validation and error handling
    private func saveClient() {
        let trimmedName = guestName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAcct = guestAcctNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty, !trimmedAcct.isEmpty else {
            alertMessage = "Please fill in all fields."
            showAlert = true
            return
        }
        
        // Create new ClientModel with current date and userRef, no followUp date initially
        let newClient = ClientModel(
            id: UUID().uuidString,
            guestName: trimmedName,
            guestAcctNumber: trimmedAcct,
            userRef: userRef,
            followUpDate: nil,
            createdDate: Date()
        )
        
        Task {
            do {
                try await repo.saveClient(newClient)
                // Notify parent of success
                onSave(.success(newClient))
            } catch {
                // Show error alert on failure
                alertMessage = error.localizedDescription
                showAlert = true
                onSave(.failure(error))
            }
        }
    }
}

// Wrapper struct to hold errors conforming to Identifiable for ErrorBoundary
struct IdentifiableError: Identifiable {
    let id = UUID()
    let error: Error
}

// ErrorBoundary view to handle and display errors with retry functionality
struct ErrorBoundary<Content: View>: View {
    @Binding var error: IdentifiableError?
    let retryAction: () -> Void
    let content: () -> Content
    
    var body: some View {
        ZStack {
            content()
                .disabled(error != nil)
                .blur(radius: error != nil ? 3 : 0)
            
            if let error = error {
                VStack(spacing: 20) {
                    Text("An error occurred:")
                        .font(.headline)
                    Text(error.error.localizedDescription)
                        .multilineTextAlignment(.center)
                    HStack {
                        Button("Retry") {
                            self.error = nil
                            retryAction()
                        }
                        .accessibilityLabel("Retry Loading Data")
                        Button("Dismiss") {
                            self.error = nil
                        }
                        .accessibilityLabel("Dismiss Error")
                    }
                }
                .padding()
                .background(.regularMaterial)
                .cornerRadius(12)
                .shadow(radius: 20)
                .padding()
                .accessibilityElement(children: .combine)
            }
        }
    }
}

#Preview {
    ClientListView(userRef: "demo-user-id")
}
