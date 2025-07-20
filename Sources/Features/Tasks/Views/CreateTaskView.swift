import SwiftUI
import CloudKit

struct CreateTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.currentUser) private var currentUser
    @ObservedObject var taskViewModel: TaskViewModel
    
    @State private var title = ""
    @State private var description = ""
    @State private var dueDate = Date()
    @State private var isGroupTask = false
    @State private var completionMode: TaskCompletionMode = .individual
    @State private var requiresAck = false
    @State private var selectedStoreCodes: Set<String> = []
    @State private var selectedDepartments: Set<String> = []
    @State private var selectedAssignees: Set<String> = []
    
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingError = false
    
    // Sample data - should be injected or fetched
    private let availableStores = ["08", "10", "12", "15"]
    private let availableDepartments = ["HR", "LP", "Ops", "Marketing", "Inventory"]
    private let availableUsers = ["user1", "user2", "user3", "user4"]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Task Details") {
                    TextField("Title", text: $title)
                        .accessibilityLabel("Task title")
                    
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                        .accessibilityLabel("Task description")
                    
                    DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                        .accessibilityLabel("Task due date")
                }
                
                Section("Task Type") {
                    Toggle("Group Task", isOn: $isGroupTask)
                        .accessibilityLabel("Mark as group task")
                    
                    Picker("Completion Mode", selection: $completionMode) {
                        ForEach(TaskCompletionMode.allCases) { mode in
                            Text(mode.rawValue.capitalized).tag(mode)
                        }
                    }
                    .accessibilityLabel("Completion mode")
                    
                    Toggle("Requires Acknowledgment", isOn: $requiresAck)
                        .accessibilityLabel("Requires acknowledgment")
                }
                
                Section("Scope") {
                    MultiSelectionView(
                        title: "Store Codes",
                        options: availableStores,
                        selections: $selectedStoreCodes
                    )
                    
                    MultiSelectionView(
                        title: "Departments",
                        options: availableDepartments,
                        selections: $selectedDepartments
                    )
                }
                
                Section("Assignment") {
                    MultiSelectionView(
                        title: "Assignees",
                        options: availableUsers,
                        selections: $selectedAssignees
                    )
                }
            }
            .navigationTitle("Create Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createTask()
                    }
                    .disabled(isLoading || title.isEmpty || selectedAssignees.isEmpty)
                }
            }
            .disabled(isLoading)
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage ?? "An error occurred")
            }
        }
    }
    
    private func createTask() {
        guard let currentUser = currentUser else {
            errorMessage = "User not found"
            showingError = true
            return
        }
        
        isLoading = true
        
        // Create task data structure
        let taskData: [String: Any] = [
            "title": title,
            "description": description,
            "status": TaskStatus.notStarted.rawValue,
            "dueDate": dueDate,
            "isGroupTask": isGroupTask,
            "completionMode": completionMode.rawValue,
            "requiresAck": requiresAck,
            "storeCodes": Array(selectedStoreCodes),
            "departments": Array(selectedDepartments),
            "assignedUserIds": Array(selectedAssignees),
            "createdAt": Date()
        ]
        
        Task {
            do {
                try await taskViewModel.createTask(data: taskData, createdBy: currentUser)
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
    }
}

struct MultiSelectionView: View {
    let title: String
    let options: [String]
    @Binding var selections: Set<String>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(options, id: \.self) { option in
                    Button(action: {
                        if selections.contains(option) {
                            selections.remove(option)
                        } else {
                            selections.insert(option)
                        }
                    }) {
                        HStack {
                            Image(systemName: selections.contains(option) ? "checkmark.square.fill" : "square")
                            Text(option)
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .foregroundColor(selections.contains(option) ? .accentColor : .primary)
                }
            }
        }
    }
}

#Preview {
    CreateTaskView(taskViewModel: TaskViewModel())
}
