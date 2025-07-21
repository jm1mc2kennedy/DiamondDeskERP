import SwiftUI
import Combine

/// Main productivity suite interface combining Project Management, Personal To-Dos, and OKRs
/// Features modern tab-based navigation with unified search and filtering
struct ProductivityView: View {
    
    @StateObject private var viewModel: ProductivityViewModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedTab: ProductivityModule = .projects
    @State private var showingQuickAdd = false
    
    init(viewModel: ProductivityViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Liquid Glass background
                backgroundView
                
                VStack(spacing: 0) {
                    // Header with unified search and filters
                    headerSection
                    
                    // Module tab picker
                    moduleTabPicker
                    
                    // Main content area
                    mainContentArea
                }
            }
            .navigationTitle("Productivity Suite")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    toolbarMenu
                }
            }
            .searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always))
            .refreshable {
                await viewModel.refreshModule(selectedTab)
            }
            .sheet(isPresented: $viewModel.showingFilters) {
                ProductivityFiltersView(filters: $viewModel.selectedFilters)
            }
            .sheet(isPresented: $showingQuickAdd) {
                QuickAddSheet(module: selectedTab, viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.showingExportOptions) {
                ExportOptionsSheet(viewModel: viewModel)
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.clearError()
                }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
        }
        .onChange(of: selectedTab) { newTab in
            viewModel.selectedModule = newTab
            Task {
                await viewModel.refreshModule(newTab)
            }
        }
    }
    
    // MARK: - Background
    
    private var backgroundView: some View {
        ZStack {
            // Base liquid glass gradient
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.1),
                    Color.purple.opacity(0.05),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Subtle texture overlay
            if colorScheme == .light {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .opacity(0.3)
            }
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            // Productivity overview cards
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ProductivityMetricCard(
                        title: "Active Projects",
                        value: "\(viewModel.productivityOverview.totalProjectBoards)",
                        icon: "square.stack.3d.up.fill",
                        color: .blue
                    )
                    
                    ProductivityMetricCard(
                        title: "Pending To-Dos",
                        value: "\(viewModel.productivityOverview.activeTodos)",
                        icon: "checklist",
                        color: .orange
                    )
                    
                    ProductivityMetricCard(
                        title: "OKR Progress",
                        value: "\(Int(viewModel.okrProgress.averageProgress))%",
                        icon: "target",
                        color: .green
                    )
                    
                    ProductivityMetricCard(
                        title: "Completion Rate",
                        value: "\(Int(viewModel.todoCompletionRate * 100))%",
                        icon: "checkmark.circle.fill",
                        color: .purple
                    )
                }
                .padding(.horizontal)
            }
            
            // Quick filters bar
            if hasActiveFilters {
                quickFiltersBar
            }
        }
        .padding(.top)
    }
    
    private var hasActiveFilters: Bool {
        !viewModel.selectedFilters.storeCodes.isEmpty ||
        !viewModel.selectedFilters.departments.isEmpty ||
        !viewModel.selectedFilters.taskStatuses.isEmpty ||
        viewModel.selectedFilters.dueDateRange != nil ||
        viewModel.selectedFilters.showOnlyAssignedToMe ||
        viewModel.selectedFilters.hideCompletedTodos
    }
    
    private var quickFiltersBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(activeFilterTags, id: \.self) { tag in
                    FilterTagView(text: tag) {
                        removeFilter(tag)
                    }
                }
                
                Button("Clear All") {
                    viewModel.resetFilters()
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
        }
    }
    
    private var activeFilterTags: [String] {
        var tags: [String] = []
        
        tags.append(contentsOf: viewModel.selectedFilters.storeCodes.map { "Store: \($0)" })
        tags.append(contentsOf: viewModel.selectedFilters.departments.map { "Dept: \($0)" })
        tags.append(contentsOf: viewModel.selectedFilters.taskStatuses.map { "Status: \($0.rawValue)" })
        
        if viewModel.selectedFilters.showOnlyAssignedToMe {
            tags.append("Assigned to Me")
        }
        
        if viewModel.selectedFilters.hideCompletedTodos {
            tags.append("Hide Completed")
        }
        
        if viewModel.selectedFilters.dueDateRange != nil {
            tags.append("Due Date Filter")
        }
        
        return tags
    }
    
    private func removeFilter(_ tag: String) {
        // Implementation to remove specific filter
        if tag.hasPrefix("Store:") {
            let store = String(tag.dropFirst(7))
            viewModel.selectedFilters.storeCodes.removeAll { $0 == store }
        } else if tag.hasPrefix("Dept:") {
            let dept = String(tag.dropFirst(6))
            viewModel.selectedFilters.departments.removeAll { $0 == dept }
        } else if tag == "Assigned to Me" {
            viewModel.selectedFilters.showOnlyAssignedToMe = false
        } else if tag == "Hide Completed" {
            viewModel.selectedFilters.hideCompletedTodos = false
        } else if tag == "Due Date Filter" {
            viewModel.selectedFilters.dueDateRange = nil
        }
    }
    
    // MARK: - Module Tab Picker
    
    private var moduleTabPicker: some View {
        Picker("Module", selection: $selectedTab) {
            ForEach(ProductivityModule.allCases, id: \.self) { module in
                HStack {
                    Image(systemName: module.systemImage)
                    Text(module.rawValue)
                }
                .tag(module)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    // MARK: - Main Content Area
    
    private var mainContentArea: some View {
        Group {
            if viewModel.isLoading && (
                viewModel.projectBoards.isEmpty ||
                viewModel.personalTodos.isEmpty ||
                viewModel.objectives.isEmpty
            ) {
                LoadingStateView(message: "Loading \(selectedTab.rawValue.lowercased())...")
            } else {
                switch selectedTab {
                case .projects:
                    ProjectManagementView(viewModel: viewModel)
                case .todos:
                    PersonalTodosView(viewModel: viewModel)
                case .okrs:
                    OKRTrackingView(viewModel: viewModel)
                }
            }
        }
        .transition(.opacity.combined(with: .move(edge: .trailing)))
        .animation(.easeInOut(duration: 0.3), value: selectedTab)
    }
    
    // MARK: - Toolbar Menu
    
    private var toolbarMenu: some View {
        Menu {
            Button {
                showingQuickAdd = true
            } label: {
                Label("Quick Add", systemImage: "plus")
            }
            
            Button {
                viewModel.showingFilters = true
            } label: {
                Label("Filters", systemImage: "line.3.horizontal.decrease.circle")
            }
            
            Button {
                viewModel.showingExportOptions = true
            } label: {
                Label("Export", systemImage: "square.and.arrow.up")
            }
            
            Divider()
            
            Button {
                Task {
                    await viewModel.refreshAllData()
                }
            } label: {
                Label("Refresh All", systemImage: "arrow.clockwise")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .foregroundStyle(.primary)
        }
    }
}

// MARK: - Supporting Views

struct ProductivityMetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .font(.title2)
                
                Spacer()
                
                Text(value)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
            }
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .frame(width: 140, height: 80)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

struct FilterTagView: View {
    let text: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(text)
                .font(.caption)
            
            Button {
                onRemove()
            } label: {
                Image(systemName: "xmark")
                    .font(.caption2)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.quaternary, in: Capsule())
        .foregroundStyle(.secondary)
    }
}

struct LoadingStateView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
    }
}

// MARK: - Module Content Views (Placeholders)

struct ProjectManagementView: View {
    @ObservedObject var viewModel: ProductivityViewModel
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if viewModel.filteredProjectBoards.isEmpty {
                    EmptyStateView(
                        icon: "square.stack.3d.up",
                        title: "No Project Boards",
                        message: "Create your first project board to get started",
                        actionTitle: "Create Board"
                    ) {
                        viewModel.showingCreateBoard = true
                    }
                } else {
                    ForEach(viewModel.filteredProjectBoards) { board in
                        ProjectBoardCard(board: board, viewModel: viewModel)
                    }
                }
            }
            .padding()
        }
        .sheet(isPresented: $viewModel.showingCreateBoard) {
            CreateProjectBoardSheet(viewModel: viewModel)
        }
    }
}

struct PersonalTodosView: View {
    @ObservedObject var viewModel: ProductivityViewModel
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if viewModel.filteredPersonalTodos.isEmpty {
                    EmptyStateView(
                        icon: "checklist",
                        title: "No To-Dos",
                        message: "Add your first personal task to get organized",
                        actionTitle: "Add To-Do"
                    ) {
                        viewModel.showingCreateTodo = true
                    }
                } else {
                    ForEach(viewModel.filteredPersonalTodos) { todo in
                        PersonalTodoCard(todo: todo, viewModel: viewModel)
                    }
                }
            }
            .padding()
        }
        .sheet(isPresented: $viewModel.showingCreateTodo) {
            CreatePersonalTodoSheet(viewModel: viewModel)
        }
    }
}

struct OKRTrackingView: View {
    @ObservedObject var viewModel: ProductivityViewModel
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if viewModel.filteredObjectives.isEmpty {
                    EmptyStateView(
                        icon: "target",
                        title: "No Objectives",
                        message: "Set your first OKR to track strategic goals",
                        actionTitle: "Create Objective"
                    ) {
                        viewModel.showingCreateObjective = true
                    }
                } else {
                    ForEach(viewModel.filteredObjectives) { objective in
                        ObjectiveCard(objective: objective, viewModel: viewModel)
                    }
                }
            }
            .padding()
        }
        .sheet(isPresented: $viewModel.showingCreateObjective) {
            CreateObjectiveSheet(viewModel: viewModel)
        }
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(message)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: action) {
                Text(actionTitle)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding()
                    .background(.blue, in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(.vertical, 60)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Placeholder Card Views

struct ProjectBoardCard: View {
    let board: ProjectBoard
    @ObservedObject var viewModel: ProductivityViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(board.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Text(board.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Image(systemName: board.viewType.icon)
                    .foregroundStyle(.blue)
                    .font(.title2)
            }
            
            HStack {
                Label("\(board.storeCodes.count) stores", systemImage: "building.2")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text(board.updatedAt, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .onTapGesture {
            Task {
                await viewModel.selectBoard(board)
            }
        }
    }
}

struct PersonalTodoCard: View {
    let todo: PersonalTodo
    @ObservedObject var viewModel: ProductivityViewModel
    
    var body: some View {
        HStack(spacing: 12) {
            Button {
                Task {
                    await viewModel.toggleTodoCompletion(todo)
                }
            } label: {
                Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(todo.isCompleted ? .green : .secondary)
                    .font(.title2)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(todo.title)
                    .font(.body)
                    .strikethrough(todo.isCompleted)
                    .foregroundStyle(todo.isCompleted ? .secondary : .primary)
                
                if !todo.notes.isEmpty {
                    Text(todo.notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                
                HStack {
                    if let dueDate = todo.dueDate {
                        Label(dueDate, style: .date)
                            .font(.caption)
                            .foregroundStyle(dueDate < Date() && !todo.isCompleted ? .red : .secondary)
                    }
                    
                    if todo.priority != .medium {
                        Text(todo.priority.rawValue.capitalized)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(todo.priority.color.opacity(0.2), in: Capsule())
                            .foregroundStyle(todo.priority.color)
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct ObjectiveCard: View {
    let objective: Objective
    @ObservedObject var viewModel: ProductivityViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(objective.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Text(objective.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(objective.progressPercentage))%")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    
                    Text(objective.status.rawValue.capitalized)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(objective.status.color.opacity(0.2), in: Capsule())
                        .foregroundStyle(objective.status.color)
                }
            }
            
            ProgressView(value: objective.progressPercentage / 100.0)
                .tint(objective.status.color)
            
            HStack {
                Label(objective.level.rawValue.capitalized, systemImage: objective.level.icon)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text(objective.quarterYear)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .onTapGesture {
            viewModel.selectedObjective = objective
        }
    }
}

// MARK: - Extensions for UI Support

extension BoardViewType {
    var icon: String {
        switch self {
        case .kanban: return "rectangle.stack"
        case .table: return "tablecells"
        case .calendar: return "calendar"
        case .timeline: return "timeline.selection"
        }
    }
}

extension TaskPriority {
    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        case .urgent: return .red
        }
    }
}

extension OKRStatus {
    var color: Color {
        switch self {
        case .draft: return .gray
        case .active: return .blue
        case .onTrack: return .green
        case .atRisk: return .orange
        case .completed: return .purple
        case .cancelled: return .red
        }
    }
}

extension OKRLevel {
    var icon: String {
        switch self {
        case .company: return "building.2"
        case .store: return "storefront"
        case .individual: return "person"
        }
    }
}

// MARK: - Preview

#Preview {
    let mockUser = User(
        id: "user1",
        email: "test@company.com",
        displayName: "Test User",
        role: .storeDirector,
        storeCodes: ["08"],
        departments: ["Sales"],
        isActive: true,
        createdAt: Date(),
        lastLoginAt: Date()
    )
    
    let mockCloudKitService = CloudKitService()
    let mockApolloClient = ApolloClient()
    
    let productivityService = ProductivityService(
        cloudKitService: mockCloudKitService,
        apolloClient: mockApolloClient,
        currentUser: mockUser
    )
    
    let projectTaskService = ProjectTaskService(
        cloudKitService: mockCloudKitService,
        apolloClient: mockApolloClient,
        currentUser: mockUser
    )
    
    let viewModel = ProductivityViewModel(
        productivityService: productivityService,
        projectTaskService: projectTaskService,
        currentUser: mockUser
    )
    
    return ProductivityView(viewModel: viewModel)
}
