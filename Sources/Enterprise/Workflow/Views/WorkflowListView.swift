import SwiftUI

struct WorkflowListView: View {
    @StateObject private var viewModel = WorkflowViewModel()
    @State private var navigationPath = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack(spacing: 0) {
                // Header with statistics
                WorkflowHeaderView(viewModel: viewModel)
                
                // Search and filters
                WorkflowFilterView(viewModel: viewModel)
                
                // Main content
                Group {
                    if viewModel.isLoading {
                        ProgressView("Loading Workflows...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let error = viewModel.error {
                        ErrorView(error: error) {
                            Task { await viewModel.refreshData() }
                        }
                    } else if viewModel.filteredWorkflows.isEmpty {
                        EmptyWorkflowsView {
                            viewModel.showingCreateWorkflow = true
                        }
                    } else {
                        WorkflowContentView(
                            workflows: viewModel.filteredWorkflows,
                            viewMode: viewModel.viewMode,
                            viewModel: viewModel,
                            navigationPath: $navigationPath
                        )
                    }
                }
            }
            .navigationTitle("Workflows")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Analytics") {
                            viewModel.showingAnalytics = true
                        }
                        Button("Execution History") {
                            viewModel.showingExecutionHistory = true
                        }
                        Divider()
                        Picker("View Mode", selection: $viewModel.viewMode) {
                            ForEach(WorkflowViewMode.allCases, id: \.self) { mode in
                                Label(mode.displayName, systemImage: mode.systemImage)
                                    .tag(mode)
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    
                    Button {
                        viewModel.showingCreateWorkflow = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .refreshable {
                await viewModel.refreshData()
            }
            .task {
                await viewModel.loadData()
            }
            .sheet(isPresented: $viewModel.showingCreateWorkflow) {
                WorkflowCreationView(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.showingAnalytics) {
                WorkflowAnalyticsView(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.showingExecutionHistory) {
                WorkflowExecutionHistoryView(viewModel: viewModel)
            }
            .navigationDestination(for: String.self) { workflowId in
                WorkflowDetailView(workflowId: workflowId, viewModel: viewModel)
            }
        }
    }
}

// MARK: - Supporting Views

struct WorkflowHeaderView: View {
    @ObservedObject var viewModel: WorkflowViewModel
    
    var body: some View {
        if let analytics = viewModel.analytics {
            VStack(spacing: 12) {
                HStack {
                    WorkflowStatCard(
                        title: "Total",
                        value: "\(analytics.totalWorkflows)",
                        icon: "doc.text",
                        color: .blue
                    )
                    
                    WorkflowStatCard(
                        title: "Active",
                        value: "\(analytics.activeWorkflows)",
                        icon: "play.circle.fill",
                        color: .green
                    )
                    
                    WorkflowStatCard(
                        title: "Executions",
                        value: "\(analytics.totalExecutions)",
                        icon: "bolt.fill",
                        color: .orange
                    )
                    
                    WorkflowStatCard(
                        title: "Success Rate",
                        value: "\(Int(analytics.executionSuccessRate * 100))%",
                        icon: "checkmark.circle.fill",
                        color: .green
                    )
                }
                .padding(.horizontal)
                
                if viewModel.executionInProgress {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Executing workflow...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical, 8)
            .background(Color(.systemGroupedBackground))
        }
    }
}

struct WorkflowStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

struct WorkflowFilterView: View {
    @ObservedObject var viewModel: WorkflowViewModel
    
    var body: some View {
        VStack(spacing: 8) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search workflows...", text: $viewModel.searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                if !viewModel.searchText.isEmpty {
                    Button("Clear") {
                        viewModel.searchText = ""
                    }
                    .font(.caption)
                }
            }
            .padding(.horizontal)
            
            // Filter chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(
                        title: "Active Only",
                        isSelected: viewModel.showActiveOnly
                    ) {
                        viewModel.showActiveOnly.toggle()
                    }
                    
                    ForEach(TriggerType.allCases, id: \.self) { triggerType in
                        FilterChip(
                            title: triggerType.displayName,
                            isSelected: viewModel.selectedTriggerType == triggerType
                        ) {
                            if viewModel.selectedTriggerType == triggerType {
                                viewModel.selectedTriggerType = nil
                            } else {
                                viewModel.selectedTriggerType = triggerType
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 8)
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.accentColor : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
    }
}

struct WorkflowContentView: View {
    let workflows: [Workflow]
    let viewMode: WorkflowViewMode
    @ObservedObject var viewModel: WorkflowViewModel
    @Binding var navigationPath: NavigationPath
    
    var body: some View {
        switch viewMode {
        case .list:
            List(workflows) { workflow in
                WorkflowRowView(workflow: workflow, viewModel: viewModel)
                    .onTapGesture {
                        navigationPath.append(workflow.id)
                    }
            }
        case .grid:
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 300))
                ], spacing: 16) {
                    ForEach(workflows) { workflow in
                        WorkflowCardView(workflow: workflow, viewModel: viewModel)
                            .onTapGesture {
                                navigationPath.append(workflow.id)
                            }
                    }
                }
                .padding()
            }
        case .kanban:
            WorkflowKanbanView(workflows: workflows, viewModel: viewModel)
        }
    }
}

struct WorkflowRowView: View {
    let workflow: Workflow
    @ObservedObject var viewModel: WorkflowViewModel
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(workflow.name)
                        .font(.headline)
                    
                    Spacer()
                    
                    WorkflowStatusBadge(isActive: workflow.isActive)
                }
                
                if let description = workflow.description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                HStack {
                    Label(workflow.triggerType.displayName, systemImage: workflow.triggerType.systemImage)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(workflow.executionCount) executions")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            VStack {
                Button {
                    Task {
                        await viewModel.executeWorkflow(workflow)
                    }
                } label: {
                    Image(systemName: "play.circle.fill")
                        .font(.title2)
                        .foregroundColor(workflow.isActive ? .green : .gray)
                }
                .disabled(!workflow.isActive || viewModel.executionInProgress)
                
                Menu {
                    Button("Edit") {
                        viewModel.selectedWorkflow = workflow
                        viewModel.showingCreateWorkflow = true
                    }
                    
                    Button(workflow.isActive ? "Deactivate" : "Activate") {
                        Task {
                            await viewModel.toggleWorkflowStatus(workflow)
                        }
                    }
                    
                    Divider()
                    
                    Button("Delete", role: .destructive) {
                        Task {
                            await viewModel.deleteWorkflow(workflow)
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct WorkflowCardView: View {
    let workflow: Workflow
    @ObservedObject var viewModel: WorkflowViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(workflow.name)
                    .font(.headline)
                    .lineLimit(1)
                
                Spacer()
                
                WorkflowStatusBadge(isActive: workflow.isActive)
            }
            
            if let description = workflow.description {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }
            
            HStack {
                Label(workflow.triggerType.displayName, systemImage: workflow.triggerType.systemImage)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            HStack {
                Button {
                    Task {
                        await viewModel.executeWorkflow(workflow)
                    }
                } label: {
                    Label("Execute", systemImage: "play.fill")
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(workflow.isActive ? Color.green : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(!workflow.isActive || viewModel.executionInProgress)
                
                Spacer()
                
                Text("\(workflow.executionCount)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct WorkflowStatusBadge: View {
    let isActive: Bool
    
    var body: some View {
        Text(isActive ? "Active" : "Inactive")
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(isActive ? Color.green.opacity(0.2) : Color.gray.opacity(0.2))
            .foregroundColor(isActive ? .green : .gray)
            .cornerRadius(8)
    }
}

struct WorkflowKanbanView: View {
    let workflows: [Workflow]
    @ObservedObject var viewModel: WorkflowViewModel
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 16) {
                ForEach(TriggerType.allCases, id: \.self) { triggerType in
                    WorkflowKanbanColumn(
                        title: triggerType.displayName,
                        workflows: workflows.filter { $0.triggerType == triggerType },
                        viewModel: viewModel
                    )
                }
            }
            .padding()
        }
    }
}

struct WorkflowKanbanColumn: View {
    let title: String
    let workflows: [Workflow]
    @ObservedObject var viewModel: WorkflowViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.headline)
                
                Spacer()
                
                Text("\(workflows.count)")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray5))
                    .cornerRadius(8)
            }
            
            ForEach(workflows) { workflow in
                WorkflowCardView(workflow: workflow, viewModel: viewModel)
            }
            
            if workflows.isEmpty {
                Text("No workflows")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
        .frame(width: 300)
        .padding()
        .background(Color(.systemGroupedBackground))
        .cornerRadius(12)
    }
}

struct EmptyWorkflowsView: View {
    let createAction: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.below.ecg")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            Text("No Workflows Found")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Create your first workflow to automate business processes")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Create Workflow") {
                createAction()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Extensions

extension WorkflowViewMode {
    var systemImage: String {
        switch self {
        case .list: return "list.bullet"
        case .grid: return "square.grid.2x2"
        case .kanban: return "rectangle.split.3x1"
        }
    }
}

extension TriggerType {
    var systemImage: String {
        switch self {
        case .manual: return "hand.tap"
        case .scheduled: return "clock"
        case .dataChange: return "arrow.triangle.2.circlepath"
        case .webhook: return "network"
        case .userAction: return "person.circle"
        case .systemEvent: return "gear"
        case .conditional: return "questionmark.diamond"
        }
    }
}

#Preview {
    WorkflowListView()
}
