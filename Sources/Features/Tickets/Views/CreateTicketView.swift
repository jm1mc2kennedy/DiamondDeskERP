import SwiftUI

struct CreateTicketView: View {
    @StateObject private var viewModel = TicketViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.currentUser) private var currentUser
    
    @State private var title = ""
    @State private var description = ""
    @State private var selectedPriority: TicketPriority = .medium
    @State private var selectedStatus: TicketStatus = .open
    @State private var selectedCategory = ""
    @State private var estimatedResolutionTime: TimeInterval = 86400 // 24 hours default
    @State private var selectedAssignee: User?
    @State private var selectedWatchers: Set<User> = []
    @State private var showingUserPicker = false
    @State private var showingWatcherPicker = false
    @State private var initialComment = ""
    
    @State private var isCreating = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    private let categories = [
        "Technical Support",
        "Bug Report",
        "Feature Request",
        "Account Issue",
        "Billing Question",
        "Training Request",
        "General Inquiry"
    ]
    
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
                    
                    Picker("Status", selection: $selectedStatus) {
                        ForEach(TicketStatus.allCases, id: \.self) { status in
                            Text(status.displayName).tag(status)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                Section("Assignment") {
                    HStack {
                        Text("Assignee")
                        Spacer()
                        if let assignee = selectedAssignee {
                            Text(assignee.displayName)
                                .foregroundColor(.secondary)
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
                        Text("\(selectedWatchers.count) selected")
                            .foregroundColor(.secondary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        showingWatcherPicker = true
                    }
                    
                    if !selectedWatchers.isEmpty {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
                            ForEach(Array(selectedWatchers), id: \.id) { user in
                                HStack(spacing: 4) {
                                    Text(user.displayName)
                                        .font(.caption)
                                    Button(action: {
                                        selectedWatchers.remove(user)
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.secondary)
                                            .font(.caption)
                                    }
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
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
                            Text("4 hours").tag(TimeInterval(14400))
                            Text("1 day").tag(TimeInterval(86400))
                            Text("2 days").tag(TimeInterval(172800))
                            Text("1 week").tag(TimeInterval(604800))
                            Text("2 weeks").tag(TimeInterval(1209600))
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                }
                
                Section("Initial Comment") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Add initial comment (optional)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextEditor(text: $initialComment)
                            .frame(minHeight: 80)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                            )
                    }
                }
            }
            .navigationTitle("Create Ticket")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createTicket()
                    }
                    .disabled(!isFormValid || isCreating)
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
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .overlay {
                if isCreating {
                    Color.black.opacity(0.3)
                        .overlay {
                            ProgressView("Creating ticket...")
                                .padding()
                                .background(Color(.systemBackground))
                                .cornerRadius(12)
                        }
                }
            }
        }
        .onAppear {
            selectedCategory = categories.first ?? ""
        }
    }
    
    private var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !selectedCategory.isEmpty
    }
    
    private func createTicket() {
        guard let user = currentUser else {
            errorMessage = "User not found"
            showingError = true
            return
        }
        
        isCreating = true
        
        Task {
            do {
                let ticket = await viewModel.createTicket(
                    title: title,
                    description: description,
                    priority: selectedPriority,
                    status: selectedStatus,
                    category: selectedCategory,
                    estimatedResolutionTime: estimatedResolutionTime,
                    assignee: selectedAssignee,
                    watchers: Array(selectedWatchers),
                    reporter: user,
                    initialComment: initialComment.isEmpty ? nil : initialComment
                )
                
                await MainActor.run {
                    isCreating = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isCreating = false
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
    }
}

// Supporting picker views
struct UserPickerView: View {
    @Binding var selectedUser: User?
    let title: String
    @Environment(\.dismiss) private var dismiss
    @StateObject private var userService = UserService()
    
    var body: some View {
        NavigationView {
            List {
                ForEach(userService.users) { user in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(user.displayName)
                                .font(.headline)
                            Text(user.email)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if selectedUser?.id == user.id {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedUser = user
                        dismiss()
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .task {
            await userService.loadUsers()
        }
    }
}

struct MultiUserPickerView: View {
    @Binding var selectedUsers: Set<User>
    let title: String
    @Environment(\.dismiss) private var dismiss
    @StateObject private var userService = UserService()
    
    var body: some View {
        NavigationView {
            List {
                ForEach(userService.users) { user in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(user.displayName)
                                .font(.headline)
                            Text(user.email)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if selectedUsers.contains(user) {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if selectedUsers.contains(user) {
                            selectedUsers.remove(user)
                        } else {
                            selectedUsers.insert(user)
                        }
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .task {
            await userService.loadUsers()
        }
    }
}

#Preview {
    CreateTicketView()
        .environment(\.currentUser, User.sampleUser)
}
