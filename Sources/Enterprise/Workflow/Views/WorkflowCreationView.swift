import SwiftUI

struct WorkflowCreationView: View {
    @ObservedObject var viewModel: WorkflowViewModel
    let editingWorkflow: Workflow?
    
    @Environment(\.dismiss) private var dismiss
    
    // Form state
    @State private var name = ""
    @State private var description = ""
    @State private var triggerType: TriggerType = .manual
    @State private var isActive = true
    @State private var tags: [String] = []
    @State private var newTag = ""
    
    // Validation
    @State private var showingValidationAlert = false
    @State private var validationMessage = ""
    
    init(viewModel: WorkflowViewModel, editingWorkflow: Workflow? = nil) {
        self.viewModel = viewModel
        self.editingWorkflow = editingWorkflow
        
        // Initialize form with existing workflow data if editing
        if let workflow = editingWorkflow {
            _name = State(initialValue: workflow.name)
            _description = State(initialValue: workflow.description ?? "")
            _triggerType = State(initialValue: workflow.triggerType)
            _isActive = State(initialValue: workflow.isActive)
            _tags = State(initialValue: workflow.tags)
        }
    }
    
    var isEditing: Bool {
        editingWorkflow != nil
    }
    
    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Information") {
                    TextField("Workflow Name", text: $name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Description (Optional)", text: $description, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(3...6)
                }
                
                Section("Configuration") {
                    Picker("Trigger Type", selection: $triggerType) {
                        ForEach(TriggerType.allCases, id: \.self) { type in
                            Label(type.displayName, systemImage: type.systemImage)
                                .tag(type)
                        }
                    }
                    
                    Toggle("Active", isOn: $isActive)
                }
                
                Section("Tags") {
                    if !tags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(tags, id: \.self) { tag in
                                    TagView(tag: tag) {
                                        tags.removeAll { $0 == tag }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    HStack {
                        TextField("Add tag", text: $newTag)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onSubmit {
                                addTag()
                            }
                        
                        Button("Add") {
                            addTag()
                        }
                        .disabled(newTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
                
                if !isEditing {
                    Section("Advanced Configuration") {
                        NavigationLink("Configure Trigger Conditions") {
                            TriggerConditionConfigView()
                        }
                        
                        NavigationLink("Configure Action Steps") {
                            ActionStepsConfigView()
                        }
                        
                        NavigationLink("Configure Error Handling") {
                            ErrorHandlingConfigView()
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Workflow" : "New Workflow")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isEditing ? "Save" : "Create") {
                        createOrUpdateWorkflow()
                    }
                    .disabled(!isValid || viewModel.isLoading)
                }
            }
            .alert("Validation Error", isPresented: $showingValidationAlert) {
                Button("OK") { }
            } message: {
                Text(validationMessage)
            }
        }
    }
    
    private func addTag() {
        let trimmedTag = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedTag.isEmpty && !tags.contains(trimmedTag) {
            tags.append(trimmedTag)
            newTag = ""
        }
    }
    
    private func createOrUpdateWorkflow() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty else {
            validationMessage = "Workflow name is required"
            showingValidationAlert = true
            return
        }
        
        let workflow: Workflow
        
        if let editingWorkflow = editingWorkflow {
            // Update existing workflow
            workflow = Workflow(
                id: editingWorkflow.id,
                name: trimmedName,
                description: description.isEmpty ? nil : description,
                triggerType: triggerType,
                isActive: isActive,
                createdBy: editingWorkflow.createdBy,
                createdAt: editingWorkflow.createdAt,
                lastExecuted: editingWorkflow.lastExecuted,
                executionCount: editingWorkflow.executionCount,
                triggerConditions: editingWorkflow.triggerConditions,
                actionSteps: editingWorkflow.actionSteps,
                errorHandling: editingWorkflow.errorHandling,
                executionHistory: editingWorkflow.executionHistory,
                tags: tags
            )
            
            Task {
                await viewModel.updateWorkflow(workflow)
                if viewModel.error == nil {
                    dismiss()
                }
            }
        } else {
            // Create new workflow
            workflow = Workflow(
                name: trimmedName,
                description: description.isEmpty ? nil : description,
                triggerType: triggerType,
                isActive: isActive,
                createdBy: "current_user", // TODO: Get from auth context
                tags: tags
            )
            
            Task {
                await viewModel.createWorkflow(workflow)
                if viewModel.error == nil {
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct TagView: View {
    let tag: String
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(tag)
                .font(.caption)
            
            Button {
                onDelete()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption2)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.systemGray5))
        .cornerRadius(12)
    }
}

// MARK: - Configuration Views (Placeholder)

struct TriggerConditionConfigView: View {
    var body: some View {
        VStack {
            Text("Trigger Condition Configuration")
                .font(.title2)
                .padding()
            
            Text("Configure when this workflow should be triggered")
                .foregroundColor(.secondary)
                .padding()
            
            // TODO: Implement trigger condition configuration UI
            Spacer()
        }
        .navigationTitle("Trigger Conditions")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ActionStepsConfigView: View {
    var body: some View {
        VStack {
            Text("Action Steps Configuration")
                .font(.title2)
                .padding()
            
            Text("Define the steps this workflow will execute")
                .foregroundColor(.secondary)
                .padding()
            
            // TODO: Implement action steps configuration UI
            Spacer()
        }
        .navigationTitle("Action Steps")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ErrorHandlingConfigView: View {
    var body: some View {
        VStack {
            Text("Error Handling Configuration")
                .font(.title2)
                .padding()
            
            Text("Configure how errors should be handled during execution")
                .foregroundColor(.secondary)
                .padding()
            
            // TODO: Implement error handling configuration UI
            Spacer()
        }
        .navigationTitle("Error Handling")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    WorkflowCreationView(viewModel: WorkflowViewModel())
}
