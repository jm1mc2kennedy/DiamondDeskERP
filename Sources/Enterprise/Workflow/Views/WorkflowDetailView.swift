import SwiftUI

struct WorkflowDetailView: View {
    let workflowId: String
    @ObservedObject var viewModel: WorkflowViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    
    private var workflow: Workflow? {
        viewModel.workflows.first { $0.id == workflowId }
    }
    
    var body: some View {
        Group {
            if let workflow = workflow {
                ScrollView {
                    VStack(spacing: 20) {
                        // Header Section
                        WorkflowHeaderSection(workflow: workflow, viewModel: viewModel)
                        
                        // Quick Actions
                        WorkflowActionsSection(workflow: workflow, viewModel: viewModel)
                        
                        // Configuration Section
                        WorkflowConfigurationSection(workflow: workflow)
                        
                        // Execution History
                        WorkflowExecutionSection(workflow: workflow, viewModel: viewModel)
                        
                        // Performance Metrics
                        WorkflowMetricsSection(workflow: workflow)
                    }
                    .padding()
                }
            } else {
                ProgressView("Loading workflow...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle(workflow?.name ?? "Workflow")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                if let workflow = workflow {
                    Menu {
                        Button("Edit") {
                            showingEditSheet = true
                        }
                        
                        Button(workflow.isActive ? "Deactivate" : "Activate") {
                            Task {
                                await viewModel.toggleWorkflowStatus(workflow)
                            }
                        }
                        
                        Divider()
                        
                        Button("Delete", role: .destructive) {
                            showingDeleteAlert = true
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            if let workflow = workflow {
                WorkflowCreationView(viewModel: viewModel, editingWorkflow: workflow)
            }
        }
        .alert("Delete Workflow", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deleteWorkflow(workflow!)
                    dismiss()
                }
            }
        } message: {
            Text("Are you sure you want to delete this workflow? This action cannot be undone.")
        }
    }
}

// MARK: - Supporting Sections

struct WorkflowHeaderSection: View {
    let workflow: Workflow
    @ObservedObject var viewModel: WorkflowViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(workflow.name)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        WorkflowStatusBadge(isActive: workflow.isActive)
                    }
                    
                    if let description = workflow.description {
                        Text(description)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Label(workflow.triggerType.displayName, systemImage: workflow.triggerType.systemImage)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("Created by \(workflow.createdBy)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Statistics Cards
            HStack(spacing: 12) {
                StatCard(
                    title: "Executions",
                    value: "\(workflow.executionCount)",
                    icon: "bolt.circle.fill",
                    color: .orange
                )
                
                StatCard(
                    title: "Last Run",
                    value: workflow.lastExecuted?.formatted(.relative(presentation: .named)) ?? "Never",
                    icon: "clock.circle.fill",
                    color: .blue
                )
                
                StatCard(
                    title: "Created",
                    value: workflow.createdAt.formatted(.dateTime.day().month().year()),
                    icon: "calendar.circle.fill",
                    color: .green
                )
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .cornerRadius(12)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

struct WorkflowActionsSection: View {
    let workflow: Workflow
    @ObservedObject var viewModel: WorkflowViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Actions")
                    .font(.headline)
                Spacer()
            }
            
            HStack(spacing: 12) {
                Button {
                    Task {
                        await viewModel.executeWorkflow(workflow)
                    }
                } label: {
                    Label("Execute Now", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(workflow.isActive ? Color.green : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(!workflow.isActive || viewModel.executionInProgress)
                
                Button {
                    // TODO: Schedule execution
                } label: {
                    Label("Schedule", systemImage: "calendar.badge.plus")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(!workflow.isActive)
            }
            
            if viewModel.executionInProgress {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Executing workflow...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
            
            if let lastResult = viewModel.lastExecutionResult, lastResult.workflowId == workflow.id {
                ExecutionResultView(execution: lastResult)
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .cornerRadius(12)
    }
}

struct ExecutionResultView: View {
    let execution: WorkflowExecution
    
    var body: some View {
        HStack {
            Image(systemName: execution.status.systemImage)
                .foregroundColor(execution.status.color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Last Execution")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(execution.status.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if let completedAt = execution.completedAt {
                    Text("Completed \(completedAt.formatted(.relative(presentation: .named)))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if let duration = execution.completedAt?.timeIntervalSince(execution.startedAt) {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Duration")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(String(format: "%.1fs", duration))
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

struct WorkflowConfigurationSection: View {
    let workflow: Workflow
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Configuration")
                    .font(.headline)
                Spacer()
            }
            
            VStack(spacing: 8) {
                ConfigurationRow(
                    label: "Trigger Type",
                    value: workflow.triggerType.displayName,
                    icon: workflow.triggerType.systemImage
                )
                
                ConfigurationRow(
                    label: "Conditions",
                    value: "\(workflow.triggerConditions.count) configured",
                    icon: "list.bullet.circle"
                )
                
                ConfigurationRow(
                    label: "Action Steps",
                    value: "\(workflow.actionSteps.count) steps",
                    icon: "arrow.right.circle"
                )
                
                ConfigurationRow(
                    label: "Error Handling",
                    value: workflow.errorHandling.continueOnError ? "Continue on error" : "Stop on error",
                    icon: "exclamationmark.triangle"
                )
                
                if !workflow.tags.isEmpty {
                    ConfigurationRow(
                        label: "Tags",
                        value: workflow.tags.joined(separator: ", "),
                        icon: "tag"
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .cornerRadius(12)
    }
}

struct ConfigurationRow: View {
    let label: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .frame(width: 20)
            
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .padding(.vertical, 4)
    }
}

struct WorkflowExecutionSection: View {
    let workflow: Workflow
    @ObservedObject var viewModel: WorkflowViewModel
    @State private var executions: [WorkflowExecution] = []
    @State private var isLoadingExecutions = false
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Recent Executions")
                    .font(.headline)
                
                Spacer()
                
                Button("View All") {
                    // TODO: Navigate to full execution history
                }
                .font(.caption)
            }
            
            if isLoadingExecutions {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if executions.isEmpty {
                Text("No executions yet")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                ForEach(executions.prefix(5), id: \.id) { execution in
                    ExecutionHistoryRow(execution: execution)
                }
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .cornerRadius(12)
        .task {
            await loadExecutions()
        }
    }
    
    private func loadExecutions() async {
        isLoadingExecutions = true
        do {
            let fetchedExecutions = try await viewModel.workflowService.fetchWorkflowExecutions(workflowId: workflow.id, limit: 10)
            await MainActor.run {
                executions = fetchedExecutions
                isLoadingExecutions = false
            }
        } catch {
            await MainActor.run {
                isLoadingExecutions = false
            }
        }
    }
}

struct ExecutionHistoryRow: View {
    let execution: WorkflowExecution
    
    var body: some View {
        HStack {
            Image(systemName: execution.status.systemImage)
                .foregroundColor(execution.status.color)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(execution.status.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text(execution.startedAt.formatted(.dateTime.hour().minute()))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let triggeredBy = execution.triggeredBy {
                    Text("Triggered by \(triggeredBy)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if let duration = execution.completedAt?.timeIntervalSince(execution.startedAt) {
                Text(String(format: "%.1fs", duration))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct WorkflowMetricsSection: View {
    let workflow: Workflow
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Performance")
                    .font(.headline)
                Spacer()
            }
            
            // TODO: Add performance charts and metrics
            HStack {
                Text("Detailed performance metrics will be displayed here")
                    .font(.body)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(8)
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .cornerRadius(12)
    }
}

// MARK: - Extensions

extension ExecutionStatus {
    var systemImage: String {
        switch self {
        case .queued: return "clock"
        case .running: return "play.circle.fill"
        case .completed: return "checkmark.circle.fill"
        case .failed: return "xmark.circle.fill"
        case .cancelled: return "stop.circle.fill"
        case .paused: return "pause.circle.fill"
        case .skipped: return "forward.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .queued: return .orange
        case .running: return .blue
        case .completed: return .green
        case .failed: return .red
        case .cancelled: return .gray
        case .paused: return .yellow
        case .skipped: return .purple
        }
    }
}

#Preview {
    NavigationStack {
        WorkflowDetailView(
            workflowId: "sample-id",
            viewModel: WorkflowViewModel()
        )
    }
}
