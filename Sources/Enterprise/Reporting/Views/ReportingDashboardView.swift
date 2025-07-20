import SwiftUI
import Charts

// MARK: - Reporting Dashboard View

public struct ReportingDashboardView: View {
    @StateObject private var viewModel = ReportingViewModel()
    @Environment(\.colorScheme) private var colorScheme
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            TabView(selection: $viewModel.selectedTab) {
                ReportListView(viewModel: viewModel)
                    .tabItem {
                        Label("Reports", systemImage: "doc.text")
                    }
                    .tag(ReportingTab.reports)
                
                DashboardListView(viewModel: viewModel)
                    .tabItem {
                        Label("Dashboards", systemImage: "rectangle.3.group")
                    }
                    .tag(ReportingTab.dashboards)
                
                ReportingAnalyticsView(viewModel: viewModel)
                    .tabItem {
                        Label("Analytics", systemImage: "chart.bar")
                    }
                    .tag(ReportingTab.analytics)
                
                ReportBuilderWrapperView(viewModel: viewModel)
                    .tabItem {
                        Label("Builder", systemImage: "wrench.and.screwdriver")
                    }
                    .tag(ReportingTab.builder)
            }
            .navigationTitle("Business Intelligence")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            Task {
                                await viewModel.refreshData()
                            }
                        }) {
                            Label("Refresh Data", systemImage: "arrow.clockwise")
                        }
                        
                        Button(action: {
                            viewModel.showingCreateReport = true
                        }) {
                            Label("New Report", systemImage: "doc.badge.plus")
                        }
                        
                        Button(action: {
                            viewModel.showingCreateDashboard = true
                        }) {
                            Label("New Dashboard", systemImage: "rectangle.badge.plus")
                        }
                    } label: {
                        Image(systemName: "plus.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $viewModel.showingCreateReport) {
            CreateReportView(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showingCreateDashboard) {
            CreateDashboardView(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showingReportBuilder) {
            ReportBuilderView(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showingReportViewer) {
            ReportViewerView(viewModel: viewModel)
        }
        .alert("Error", isPresented: .constant(viewModel.error != nil)) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            Text(viewModel.error?.localizedDescription ?? "")
        }
        .task {
            await viewModel.loadData()
            await viewModel.loadAnalytics()
        }
    }
}

// MARK: - Report List View

public struct ReportListView: View {
    @ObservedObject var viewModel: ReportingViewModel
    @State private var sortOrder = ReportSortOrder.dateUpdated
    @State private var sortAscending = false
    
    public var body: some View {
        VStack(spacing: 0) {
            // Search and Filter Bar
            searchAndFilterBar
            
            // Content
            if viewModel.isLoading && viewModel.filteredReports.isEmpty {
                loadingView
            } else if viewModel.filteredReports.isEmpty {
                emptyStateView
            } else {
                reportList
            }
        }
        .navigationTitle("Reports")
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                if !viewModel.selectedReportIds.isEmpty {
                    Button("Actions") {
                        viewModel.showingBulkActions = true
                    }
                }
                
                Button {
                    viewModel.showingCreateReport = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $viewModel.showingReportFilters) {
            ReportFiltersView(viewModel: viewModel)
        }
        .confirmationDialog("Bulk Actions", isPresented: $viewModel.showingBulkActions) {
            ForEach(ReportBulkActionType.allCases, id: \.self) { actionType in
                Button(actionType.displayName, role: actionType.isDestructive ? .destructive : nil) {
                    Task {
                        await viewModel.performBulkAction(actionType)
                    }
                }
            }
            
            Button("Cancel", role: .cancel) {}
        }
    }
    
    private var searchAndFilterBar: some View {
        VStack(spacing: 12) {
            HStack {
                SearchBar(text: $viewModel.searchText)
                
                Button {
                    viewModel.showingReportFilters = true
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .foregroundColor(.accentColor)
                }
            }
            
            if !viewModel.selectedReportIds.isEmpty {
                HStack {
                    Text("\(viewModel.selectedReportIds.count) selected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button("Select All") {
                        viewModel.selectAllReports()
                    }
                    .font(.caption)
                    
                    Button("Deselect All") {
                        viewModel.deselectAllReports()
                    }
                    .font(.caption)
                }
                .padding(.horizontal)
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    private var loadingView: some View {
        VStack {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading reports...")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            Text("No Reports")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Create your first report to get started with business intelligence")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 12) {
                Button {
                    viewModel.showingCreateReport = true
                } label: {
                    Label("Create Report", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                
                Button {
                    viewModel.startReportBuilder()
                } label: {
                    Label("Use Builder", systemImage: "wrench.and.screwdriver")
                }
                .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var reportList: some View {
        List {
            ForEach(sortedReports) { report in
                ReportRowView(
                    report: report,
                    isSelected: viewModel.selectedReportIds.contains(report.id),
                    onTap: {
                        if !viewModel.selectedReportIds.isEmpty {
                            viewModel.toggleReportSelection(report.id)
                        } else {
                            viewModel.selectReport(report)
                        }
                    },
                    onLongPress: {
                        viewModel.toggleReportSelection(report.id)
                    },
                    onGenerate: {
                        Task {
                            await viewModel.generateReport(report)
                        }
                    }
                )
            }
        }
        .listStyle(PlainListStyle())
        .refreshable {
            await viewModel.refreshData()
        }
    }
    
    private var sortedReports: [Report] {
        let reports = viewModel.filteredReports
        
        switch sortOrder {
        case .dateCreated:
            return sortAscending ? reports.sorted { $0.createdAt < $1.createdAt } : reports.sorted { $0.createdAt > $1.createdAt }
        case .dateUpdated:
            return sortAscending ? reports.sorted { $0.updatedAt < $1.updatedAt } : reports.sorted { $0.updatedAt > $1.updatedAt }
        case .name:
            return sortAscending ? reports.sorted { $0.reportName < $1.reportName } : reports.sorted { $0.reportName > $1.reportName }
        case .category:
            return sortAscending ? reports.sorted { $0.category.rawValue < $1.category.rawValue } : reports.sorted { $0.category.rawValue > $1.category.rawValue }
        case .type:
            return sortAscending ? reports.sorted { $0.reportType.rawValue < $1.reportType.rawValue } : reports.sorted { $0.reportType.rawValue > $1.reportType.rawValue }
        }
    }
}

// MARK: - Report Row View

public struct ReportRowView: View {
    let report: Report
    let isSelected: Bool
    let onTap: () -> Void
    let onLongPress: () -> Void
    let onGenerate: () -> Void
    
    public var body: some View {
        HStack {
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.accentColor)
            }
            
            HStack(spacing: 12) {
                // Report Icon
                ReportTypeIcon(type: report.reportType, category: report.category)
                
                // Report Details
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(report.reportName)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        if report.isPublic {
                            Image(systemName: "globe")
                                .font(.caption)
                                .foregroundColor(.blue)
                        } else {
                            Image(systemName: "lock")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                    
                    HStack {
                        ReportCategoryBadge(category: report.category)
                        
                        Spacer()
                        
                        ReportStatusBadge(report: report)
                    }
                    
                    HStack {
                        Text("Updated: \(formatDate(report.updatedAt))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        if let lastGenerated = report.metadata.lastGenerated {
                            Text("Generated: \(formatDate(lastGenerated))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            // Action Button
            Button(action: onGenerate) {
                Image(systemName: "play.circle")
                    .font(.title2)
                    .foregroundColor(.accentColor)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 8)
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        .onTapGesture {
            onTap()
        }
        .onLongPressGesture {
            onLongPress()
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Report Type Icon

public struct ReportTypeIcon: View {
    let type: ReportType
    let category: ReportCategory
    
    public var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(category.color).opacity(0.2))
                .frame(width: 40, height: 40)
            
            Image(systemName: type.systemImage)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(category.color))
        }
    }
}

// MARK: - Report Category Badge

public struct ReportCategoryBadge: View {
    let category: ReportCategory
    
    public var body: some View {
        Text(category.displayName)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(category.color).opacity(0.2))
            .foregroundColor(Color(category.color))
            .clipShape(Capsule())
    }
}

// MARK: - Report Status Badge

public struct ReportStatusBadge: View {
    let report: Report
    
    public var body: some View {
        Text(report.statusDescription)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .clipShape(Capsule())
    }
    
    private var backgroundColor: Color {
        if !report.isActive {
            return .gray.opacity(0.2)
        } else if report.metadata.lastGenerated == nil {
            return .orange.opacity(0.2)
        } else {
            return .green.opacity(0.2)
        }
    }
    
    private var foregroundColor: Color {
        if !report.isActive {
            return .gray
        } else if report.metadata.lastGenerated == nil {
            return .orange
        } else {
            return .green
        }
    }
}

// MARK: - Dashboard List View

public struct DashboardListView: View {
    @ObservedObject var viewModel: ReportingViewModel
    
    public var body: some View {
        VStack(spacing: 0) {
            // Search Bar
            SearchBar(text: $viewModel.searchText)
                .padding(.horizontal)
                .padding(.top, 8)
            
            // Content
            if viewModel.isLoading && viewModel.filteredDashboards.isEmpty {
                loadingView
            } else if viewModel.filteredDashboards.isEmpty {
                emptyStateView
            } else {
                dashboardList
            }
        }
        .navigationTitle("Dashboards")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    viewModel.showingCreateDashboard = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
    }
    
    private var loadingView: some View {
        VStack {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading dashboards...")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "rectangle.3.group")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            Text("No Dashboards")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Create your first dashboard to visualize your data")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button {
                viewModel.showingCreateDashboard = true
            } label: {
                Label("Create Dashboard", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var dashboardList: some View {
        List(viewModel.filteredDashboards) { dashboard in
            DashboardRowView(dashboard: dashboard) {
                viewModel.selectDashboard(dashboard)
            }
        }
        .listStyle(PlainListStyle())
        .refreshable {
            await viewModel.refreshData()
        }
    }
}

// MARK: - Dashboard Row View

public struct DashboardRowView: View {
    let dashboard: Dashboard
    let onTap: () -> Void
    
    public var body: some View {
        HStack {
            // Dashboard Icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: "rectangle.3.group")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.blue)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(dashboard.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    if dashboard.isDefault {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                    }
                }
                
                if let description = dashboard.description {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                HStack {
                    Text("\(dashboard.widgetCount) widgets")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("Updated: \(formatDate(dashboard.updatedAt))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
        .onTapGesture {
            onTap()
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Reporting Analytics View

public struct ReportingAnalyticsView: View {
    @ObservedObject var viewModel: ReportingViewModel
    
    public var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Header
                analyticsHeader
                
                // Key metrics
                if let analytics = viewModel.reportAnalytics {
                    keyMetricsSection(analytics)
                    
                    // Category breakdown
                    categoryBreakdownSection(analytics)
                    
                    // Type breakdown
                    typeBreakdownSection(analytics)
                    
                    // Recent activity
                    recentActivitySection
                } else {
                    loadingView
                }
            }
            .padding()
        }
        .navigationTitle("Analytics")
        .task {
            await viewModel.loadAnalytics()
        }
    }
    
    private var analyticsHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Reporting Overview")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button {
                    Task {
                        await viewModel.loadAnalytics()
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.accentColor)
                }
            }
            
            Text("Business Intelligence Analytics")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading analytics...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }
    
    private func keyMetricsSection(_ analytics: ReportAnalytics) -> some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            AnalyticsCard(
                title: "Total Reports",
                value: "\(analytics.totalReports)",
                icon: "doc.text.fill",
                color: .blue
            )
            
            AnalyticsCard(
                title: "Public Reports",
                value: "\(analytics.publicReports)",
                icon: "globe",
                color: .green
            )
            
            AnalyticsCard(
                title: "Recent Reports",
                value: "\(analytics.recentReports)",
                icon: "clock.fill",
                color: .orange
            )
            
            AnalyticsCard(
                title: "Avg Generation",
                value: "\(String(format: "%.1f", analytics.averageGenerationTime))s",
                icon: "speedometer",
                color: .purple
            )
        }
    }
    
    private func categoryBreakdownSection(_ analytics: ReportAnalytics) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Reports by Category")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                ForEach(analytics.categoryCounts.sorted(by: { $0.value > $1.value }), id: \.key) { category, count in
                    CategoryBreakdownRow(
                        category: category,
                        count: count,
                        total: analytics.totalReports
                    )
                }
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func typeBreakdownSection(_ analytics: ReportAnalytics) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Reports by Type")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                ForEach(analytics.typeCounts.sorted(by: { $0.value > $1.value }), id: \.key) { type, count in
                    TypeBreakdownRow(
                        type: type,
                        count: count,
                        total: analytics.totalReports
                    )
                }
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Reports")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                ForEach(viewModel.recentReports, id: \.id) { report in
                    RecentReportRow(report: report) {
                        viewModel.selectReport(report)
                    }
                }
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Analytics Card

public struct AnalyticsCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                
                Spacer()
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Category Breakdown Row

public struct CategoryBreakdownRow: View {
    let category: ReportCategory
    let count: Int
    let total: Int
    
    private var percentage: Double {
        total > 0 ? Double(count) / Double(total) : 0
    }
    
    public var body: some View {
        HStack {
            Text(category.displayName)
                .font(.subheadline)
                .frame(width: 120, alignment: .leading)
            
            Text("\(count)")
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(width: 40, alignment: .trailing)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondary.opacity(0.2))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(category.color))
                        .frame(width: geometry.size.width * percentage, height: 8)
                }
            }
            .frame(height: 8)
            
            Text("\(Int(percentage * 100))%")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 40, alignment: .trailing)
        }
    }
}

// MARK: - Type Breakdown Row

public struct TypeBreakdownRow: View {
    let type: ReportType
    let count: Int
    let total: Int
    
    private var percentage: Double {
        total > 0 ? Double(count) / Double(total) : 0
    }
    
    public var body: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: type.systemImage)
                    .font(.caption)
                    .foregroundColor(.accentColor)
                    .frame(width: 16)
                
                Text(type.displayName)
                    .font(.subheadline)
            }
            .frame(width: 120, alignment: .leading)
            
            Text("\(count)")
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(width: 40, alignment: .trailing)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondary.opacity(0.2))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.accentColor)
                        .frame(width: geometry.size.width * percentage, height: 8)
                }
            }
            .frame(height: 8)
            
            Text("\(Int(percentage * 100))%")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 40, alignment: .trailing)
        }
    }
}

// MARK: - Recent Report Row

public struct RecentReportRow: View {
    let report: Report
    let onTap: () -> Void
    
    public var body: some View {
        HStack {
            ReportTypeIcon(type: report.reportType, category: report.category)
                .scaleEffect(0.8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(report.reportName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text(report.formattedCreatedDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            ReportCategoryBadge(category: report.category)
                .scaleEffect(0.9)
        }
        .padding(.vertical, 4)
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - Report Builder Wrapper View

public struct ReportBuilderWrapperView: View {
    @ObservedObject var viewModel: ReportingViewModel
    
    public var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "wrench.and.screwdriver")
                .font(.system(size: 64))
                .foregroundColor(.accentColor)
            
            Text("Report Builder")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Create custom reports with our intuitive builder")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button {
                viewModel.startReportBuilder()
            } label: {
                Label("Start Building", systemImage: "play.fill")
                    .font(.title3)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .navigationTitle("Builder")
    }
}

// MARK: - Search Bar

public struct SearchBar: View {
    @Binding var text: String
    
    public var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search reports and dashboards...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.secondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Supporting Types

public enum ReportSortOrder: String, CaseIterable {
    case dateCreated = "date_created"
    case dateUpdated = "date_updated"
    case name = "name"
    case category = "category"
    case type = "type"
    
    public var displayName: String {
        switch self {
        case .dateCreated: return "Date Created"
        case .dateUpdated: return "Date Updated"
        case .name: return "Name"
        case .category: return "Category"
        case .type: return "Type"
        }
    }
}
