import SwiftUI
import Charts

/// ProjectPortfolioView - Comprehensive portfolio management dashboard
/// Implements PT3VS1 specifications for enterprise project portfolio management
public struct ProjectPortfolioView: View {
    
    @StateObject private var portfolioService = ProjectPortfolioService()
    @State private var selectedTab: PortfolioTab = .dashboard
    @State private var searchText = ""
    @State private var selectedProject: ProjectModel?
    @State private var showingCreateProject = false
    @State private var showingProjectDetails = false
    @State private var showingResourceOptimization = false
    @State private var showingRiskAnalysis = false
    @State private var showingTimelineAnalysis = false
    @State private var showingPortfolioReport = false
    
    // Filter states
    @State private var selectedStatus: ProjectStatus?
    @State private var selectedPriority: ProjectPriority?
    @State private var selectedHealth: ProjectHealth?
    @State private var dateRange: DateInterval?
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Top Navigation Tabs
                portfolioTabBar
                
                // Main Content
                TabView(selection: $selectedTab) {
                    dashboardView
                        .tag(PortfolioTab.dashboard)
                    
                    projectsListView
                        .tag(PortfolioTab.projects)
                    
                    resourceManagementView
                        .tag(PortfolioTab.resources)
                    
                    timelineAnalysisView
                        .tag(PortfolioTab.timeline)
                    
                    riskManagementView
                        .tag(PortfolioTab.risks)
                    
                    reportsView
                        .tag(PortfolioTab.reports)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("Project Portfolio")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("New Project") {
                            showingCreateProject = true
                        }
                        Button("Refresh Data") {
                            Task {
                                await portfolioService.loadProjects()
                            }
                        }
                        Button("Export Report") {
                            showingPortfolioReport = true
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .task {
            await portfolioService.loadProjects()
        }
        .sheet(isPresented: $showingCreateProject) {
            CreateProjectView { project in
                Task {
                    await portfolioService.createProject(project)
                }
            }
        }
        .sheet(isPresented: $showingProjectDetails) {
            if let project = selectedProject {
                ProjectDetailsView(project: project) { updatedProject in
                    Task {
                        await portfolioService.updateProject(updatedProject)
                    }
                }
            }
        }
        .sheet(isPresented: $showingResourceOptimization) {
            ResourceOptimizationView(portfolioService: portfolioService)
        }
        .sheet(isPresented: $showingRiskAnalysis) {
            RiskAnalysisView(portfolioService: portfolioService)
        }
        .sheet(isPresented: $showingTimelineAnalysis) {
            TimelineAnalysisView(portfolioService: portfolioService)
        }
        .sheet(isPresented: $showingPortfolioReport) {
            PortfolioReportView(portfolioService: portfolioService)
        }
    }
    
    // MARK: - Portfolio Tab Bar
    
    private var portfolioTabBar: some View {
        HStack {
            ForEach(PortfolioTab.allCases, id: \.self) { tab in
                Button(action: {
                    selectedTab = tab
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: tab.iconName)
                            .font(.system(size: 20))
                        Text(tab.title)
                            .font(.caption)
                    }
                    .foregroundColor(selectedTab == tab ? .blue : .gray)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
    }
    
    // MARK: - Dashboard View
    
    private var dashboardView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Portfolio Overview Cards
                portfolioOverviewCards
                
                // Performance Charts
                performanceChartsSection
                
                // Risk and Resource Summary
                HStack(spacing: 16) {
                    riskSummaryCard
                    resourceSummaryCard
                }
                
                // Recent Activity
                recentActivitySection
                
                // Quick Actions
                quickActionsSection
            }
            .padding()
        }
        .refreshable {
            await portfolioService.loadProjects()
        }
    }
    
    private var portfolioOverviewCards: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
            PortfolioMetricCard(
                title: "Total Projects",
                value: "\(portfolioService.portfolioDashboard.totalProjects)",
                subtitle: "\(portfolioService.portfolioDashboard.activeProjects) Active",
                color: .blue,
                trend: .stable
            )
            
            PortfolioMetricCard(
                title: "Portfolio ROI",
                value: String(format: "%.1f%%", portfolioService.portfolioDashboard.portfolioROI),
                subtitle: "vs 12% target",
                color: portfolioService.portfolioDashboard.portfolioROI >= 12 ? .green : .orange,
                trend: .improving
            )
            
            PortfolioMetricCard(
                title: "Budget Utilization",
                value: String(format: "%.1f%%", portfolioService.portfolioDashboard.budgetUtilization),
                subtitle: String(format: "$%.1fM spent", portfolioService.portfolioDashboard.totalActualCost / 1_000_000),
                color: .purple,
                trend: .stable
            )
            
            PortfolioMetricCard(
                title: "On-Time Delivery",
                value: String(format: "%.1f%%", portfolioService.portfolioDashboard.onTimeDelivery),
                subtitle: "Last 12 months",
                color: portfolioService.portfolioDashboard.onTimeDelivery >= 85 ? .green : .red,
                trend: .improving
            )
        }
    }
    
    private var performanceChartsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Performance Trends")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    // Progress Chart
                    progressTrendChart
                    
                    // Budget Chart
                    budgetTrendChart
                    
                    // Risk Chart
                    riskTrendChart
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var progressTrendChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Project Progress")
                .font(.subheadline)
                .fontWeight(.medium)
            
            Chart {
                ForEach(portfolioService.portfolioDashboard.trendData.filter { $0.metric == .progress }) { dataPoint in
                    LineMark(
                        x: .value("Date", dataPoint.date),
                        y: .value("Progress", dataPoint.value)
                    )
                    .foregroundStyle(.blue)
                }
            }
            .frame(width: 200, height: 120)
            .chartYScale(domain: 0...100)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private var budgetTrendChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Budget Performance")
                .font(.subheadline)
                .fontWeight(.medium)
            
            Chart {
                ForEach(portfolioService.portfolioDashboard.trendData.filter { $0.metric == .budget }) { dataPoint in
                    BarMark(
                        x: .value("Date", dataPoint.date),
                        y: .value("Budget", dataPoint.value)
                    )
                    .foregroundStyle(.green)
                }
            }
            .frame(width: 200, height: 120)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private var riskTrendChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Risk Level")
                .font(.subheadline)
                .fontWeight(.medium)
            
            Chart {
                ForEach(portfolioService.portfolioDashboard.trendData.filter { $0.metric == .risks }) { dataPoint in
                    AreaMark(
                        x: .value("Date", dataPoint.date),
                        y: .value("Risk", dataPoint.value)
                    )
                    .foregroundStyle(.red.opacity(0.3))
                }
            }
            .frame(width: 200, height: 120)
            .chartYScale(domain: 0...10)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private var riskSummaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Risk Overview")
                    .font(.headline)
                Spacer()
                Button("View Details") {
                    showingRiskAnalysis = true
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            VStack(spacing: 8) {
                HStack {
                    Text("High Risk Projects")
                    Spacer()
                    Text("\(portfolioService.riskOverview.highRisks)")
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                }
                
                HStack {
                    Text("Critical Risks")
                    Spacer()
                    Text("\(portfolioService.riskOverview.criticalRisks)")
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                }
                
                HStack {
                    Text("Overall Risk Score")
                    Spacer()
                    Text(String(format: "%.1f", portfolioService.riskOverview.overallRiskScore))
                        .fontWeight(.semibold)
                        .foregroundColor(riskScoreColor(portfolioService.riskOverview.overallRiskScore))
                }
            }
            .font(.subheadline)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private var resourceSummaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Resource Status")
                    .font(.headline)
                Spacer()
                Button("Optimize") {
                    showingResourceOptimization = true
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            VStack(spacing: 8) {
                HStack {
                    Text("Utilization Rate")
                    Spacer()
                    Text(String(format: "%.1f%%", portfolioService.resourceOptimization.utilizationRate))
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
                
                HStack {
                    Text("Conflicts")
                    Spacer()
                    Text("\(portfolioService.resourceOptimization.conflicts.count)")
                        .fontWeight(.semibold)
                        .foregroundColor(portfolioService.resourceOptimization.conflicts.isEmpty ? .green : .orange)
                }
                
                HStack {
                    Text("Optimization Score")
                    Spacer()
                    Text("85%") // Placeholder
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
            }
            .font(.subheadline)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activity")
                .font(.headline)
                .padding(.horizontal)
            
            LazyVStack(spacing: 8) {
                ForEach(recentActivityItems, id: \.id) { item in
                    ActivityItemView(item: item)
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
                .padding(.horizontal)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                QuickActionButton(
                    title: "New Project",
                    icon: "plus.circle",
                    color: .blue
                ) {
                    showingCreateProject = true
                }
                
                QuickActionButton(
                    title: "Timeline View",
                    icon: "calendar",
                    color: .green
                ) {
                    showingTimelineAnalysis = true
                }
                
                QuickActionButton(
                    title: "Resource Plan",
                    icon: "person.3",
                    color: .orange
                ) {
                    showingResourceOptimization = true
                }
                
                QuickActionButton(
                    title: "Risk Assessment",
                    icon: "exclamationmark.triangle",
                    color: .red
                ) {
                    showingRiskAnalysis = true
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Projects List View
    
    private var projectsListView: some View {
        VStack(spacing: 0) {
            // Search and Filters
            projectFiltersSection
            
            // Projects List
            if portfolioService.isLoading {
                ProgressView("Loading projects...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(filteredProjects) { project in
                        ProjectRowView(project: project) {
                            selectedProject = project
                            showingProjectDetails = true
                        }
                    }
                    .onDelete(perform: deleteProjects)
                }
                .listStyle(PlainListStyle())
            }
        }
    }
    
    private var projectFiltersSection: some View {
        VStack(spacing: 12) {
            // Search Bar
            SearchBar(text: $searchText, placeholder: "Search projects...")
            
            // Filter Pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterPill(
                        title: "All Status",
                        isSelected: selectedStatus == nil,
                        action: { selectedStatus = nil }
                    )
                    
                    ForEach(ProjectStatus.allCases, id: \.self) { status in
                        FilterPill(
                            title: status.displayName,
                            isSelected: selectedStatus == status,
                            action: { selectedStatus = status }
                        )
                    }
                }
                .padding(.horizontal)
            }
            
            // Priority and Health Filters
            HStack {
                Picker("Priority", selection: $selectedPriority) {
                    Text("All Priorities").tag(ProjectPriority?.none)
                    ForEach(ProjectPriority.allCases, id: \.self) { priority in
                        Text(priority.rawValue.capitalized).tag(ProjectPriority?.some(priority))
                    }
                }
                .pickerStyle(MenuPickerStyle())
                
                Spacer()
                
                Picker("Health", selection: $selectedHealth) {
                    Text("All Health").tag(ProjectHealth?.none)
                    ForEach([ProjectHealth.green, ProjectHealth.yellow, ProjectHealth.red], id: \.self) { health in
                        Text(health.displayName).tag(ProjectHealth?.some(health))
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
    }
    
    // MARK: - Resource Management View
    
    private var resourceManagementView: some View {
        ResourceOptimizationView(portfolioService: portfolioService)
    }
    
    // MARK: - Timeline Analysis View
    
    private var timelineAnalysisView: some View {
        TimelineAnalysisView(portfolioService: portfolioService)
    }
    
    // MARK: - Risk Management View
    
    private var riskManagementView: some View {
        RiskAnalysisView(portfolioService: portfolioService)
    }
    
    // MARK: - Reports View
    
    private var reportsView: some View {
        PortfolioReportView(portfolioService: portfolioService)
    }
    
    // MARK: - Helper Methods
    
    private var filteredProjects: [ProjectModel] {
        portfolioService.searchProjects(
            query: searchText.isEmpty ? nil : searchText,
            status: selectedStatus,
            priority: selectedPriority,
            health: selectedHealth,
            dateRange: dateRange
        )
    }
    
    private var recentActivityItems: [ActivityItem] {
        // Mock data - in real implementation, this would come from a service
        [
            ActivityItem(id: "1", title: "Project Alpha milestone completed", timestamp: Date(), type: .milestone),
            ActivityItem(id: "2", title: "Resource conflict detected in Project Beta", timestamp: Date().addingTimeInterval(-3600), type: .warning),
            ActivityItem(id: "3", title: "Budget variance alert for Project Gamma", timestamp: Date().addingTimeInterval(-7200), type: .alert),
            ActivityItem(id: "4", title: "New project Delta created", timestamp: Date().addingTimeInterval(-10800), type: .project)
        ]
    }
    
    private func riskScoreColor(_ score: Double) -> Color {
        switch score {
        case 0..<3: return .green
        case 3..<6: return .orange
        default: return .red
        }
    }
    
    private func deleteProjects(offsets: IndexSet) {
        for index in offsets {
            let project = filteredProjects[index]
            Task {
                await portfolioService.deleteProject(project)
            }
        }
    }
}

// MARK: - Portfolio Tab Enum

enum PortfolioTab: String, CaseIterable {
    case dashboard = "Dashboard"
    case projects = "Projects"
    case resources = "Resources"
    case timeline = "Timeline"
    case risks = "Risks"
    case reports = "Reports"
    
    var title: String { rawValue }
    
    var iconName: String {
        switch self {
        case .dashboard: return "square.grid.2x2"
        case .projects: return "folder"
        case .resources: return "person.3"
        case .timeline: return "calendar"
        case .risks: return "exclamationmark.triangle"
        case .reports: return "chart.bar.doc.horizontal"
        }
    }
}

// MARK: - Supporting Views

struct PortfolioMetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let trend: TrendDirection
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Image(systemName: trendIcon)
                    .font(.caption)
                    .foregroundColor(trendColor)
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private var trendIcon: String {
        switch trend {
        case .improving: return "arrow.up.right"
        case .stable: return "arrow.right"
        case .declining: return "arrow.down.right"
        }
    }
    
    private var trendColor: Color {
        switch trend {
        case .improving: return .green
        case .stable: return .gray
        case .declining: return .red
        }
    }
}

struct ActivityItemView: View {
    let item: ActivityItem
    
    var body: some View {
        HStack {
            Image(systemName: item.type.iconName)
                .foregroundColor(item.type.color)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.subheadline)
                
                Text(item.timestamp.formatted(.relative(presentation: .named)))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .frame(height: 60)
            .frame(maxWidth: .infinity)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 2)
        }
    }
}

struct ProjectRowView: View {
    let project: ProjectModel
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(project.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    ProjectStatusBadge(status: project.status)
                }
                
                Text(project.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack {
                    ProgressBar(progress: project.progress / 100)
                        .frame(height: 6)
                    
                    Text("\(Int(project.progress))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Label(project.projectManager, systemImage: "person")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Label(project.endDate.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ProjectHealthIndicator(health: project.overallHealth)
                }
            }
            .padding()
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ProjectStatusBadge: View {
    let status: ProjectStatus
    
    var body: some View {
        Text(status.displayName)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(status.color).opacity(0.2))
            .foregroundColor(Color(status.color))
            .cornerRadius(8)
    }
}

struct ProjectHealthIndicator: View {
    let health: ProjectHealth
    
    var body: some View {
        Circle()
            .fill(Color(health.rawValue))
            .frame(width: 8, height: 8)
    }
}

struct ProgressBar: View {
    let progress: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                
                Rectangle()
                    .fill(Color.blue)
                    .frame(width: geometry.size.width * progress)
            }
        }
        .cornerRadius(3)
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
                .textFieldStyle(PlainTextFieldStyle())
            
            if !text.isEmpty {
                Button("Clear") {
                    text = ""
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .padding(.horizontal)
    }
}

struct FilterPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
    }
}

// MARK: - Supporting Data Structures

struct ActivityItem: Identifiable {
    let id: String
    let title: String
    let timestamp: Date
    let type: ActivityType
}

enum ActivityType {
    case milestone, warning, alert, project
    
    var iconName: String {
        switch self {
        case .milestone: return "flag.checkered"
        case .warning: return "exclamationmark.triangle"
        case .alert: return "bell"
        case .project: return "folder.badge.plus"
        }
    }
    
    var color: Color {
        switch self {
        case .milestone: return .green
        case .warning: return .orange
        case .alert: return .red
        case .project: return .blue
        }
    }
}

// MARK: - Placeholder Views for Complex Features

struct CreateProjectView: View {
    let onSave: (ProjectModel) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Text("Create Project View")
            .navigationTitle("New Project")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
    }
}

struct ProjectDetailsView: View {
    let project: ProjectModel
    let onSave: (ProjectModel) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Text("Project Details View")
            .navigationTitle(project.name)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
    }
}

struct ResourceOptimizationView: View {
    let portfolioService: ProjectPortfolioService
    
    var body: some View {
        Text("Resource Optimization View")
            .navigationTitle("Resource Management")
    }
}

struct TimelineAnalysisView: View {
    let portfolioService: ProjectPortfolioService
    
    var body: some View {
        Text("Timeline Analysis View")
            .navigationTitle("Timeline Analysis")
    }
}

struct RiskAnalysisView: View {
    let portfolioService: ProjectPortfolioService
    
    var body: some View {
        Text("Risk Analysis View")
            .navigationTitle("Risk Management")
    }
}

struct PortfolioReportView: View {
    let portfolioService: ProjectPortfolioService
    
    var body: some View {
        Text("Portfolio Report View")
            .navigationTitle("Portfolio Reports")
    }
}

#if DEBUG
struct ProjectPortfolioView_Previews: PreviewProvider {
    static var previews: some View {
        ProjectPortfolioView()
    }
}
#endif
