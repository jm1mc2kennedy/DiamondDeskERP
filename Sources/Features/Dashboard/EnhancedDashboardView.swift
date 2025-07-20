import SwiftUI
import Charts

struct EnhancedDashboardView: View {
    @StateObject private var dashboardViewModel = DashboardViewModel()
    @Environment(\.navigationRouter) private var router
    @State private var selectedTimeRange: TimeRange = .thisMonth
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Time Range Selector
                TimeRangePicker(selectedRange: $selectedTimeRange)
                    .padding(.horizontal)
                    .onChange(of: selectedTimeRange) { _ in
                        Task {
                            await dashboardViewModel.loadData(for: selectedTimeRange)
                        }
                    }
                
                // KPI Overview
                KPIOverviewSection()
                
                // Charts Section
                ChartsSection()
                
                // Performance Metrics
                PerformanceMetricsSection()
                
                // Quick Actions
                QuickActionsSection()
                
                // Recent Activity
                RecentActivitySection()
            }
            .padding(.bottom, 20)
        }
        .navigationTitle("Dashboard")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Filters") {
                    router.navigateToDashboardFilters()
                }
            }
        }
            .refreshable {
                await dashboardViewModel.loadData(for: selectedTimeRange)
            }
        }
        .environmentObject(dashboardViewModel)
        .task {
            await dashboardViewModel.loadData(for: selectedTimeRange)
        }
    }
    
    // MARK: - KPI Overview Section
    
    @ViewBuilder
    private func KPIOverviewSection() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Key Performance Indicators", icon: "chart.bar.fill")
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    KPICardView(
                        title: "Revenue",
                        value: dashboardViewModel.totalRevenue.formatted(.currency(code: "USD")),
                        change: dashboardViewModel.revenueChange,
                        color: .green,
                        icon: "dollarsign.circle.fill"
                    )
                    
                    KPICardView(
                        title: "Sales",
                        value: "\(dashboardViewModel.totalSales)",
                        change: dashboardViewModel.salesChange,
                        color: .blue,
                        icon: "cart.fill"
                    )
                    
                    KPICardView(
                        title: "New Clients",
                        value: "\(dashboardViewModel.newClients)",
                        change: dashboardViewModel.clientsChange,
                        color: .purple,
                        icon: "person.badge.plus"
                    )
                    
                    KPICardView(
                        title: "Tasks Completed",
                        value: "\(dashboardViewModel.completedTasks)",
                        change: dashboardViewModel.tasksChange,
                        color: .orange,
                        icon: "checkmark.circle.fill"
                    )
                    
                    KPICardView(
                        title: "Avg. Order Value",
                        value: dashboardViewModel.averageOrderValue.formatted(.currency(code: "USD")),
                        change: dashboardViewModel.aovChange,
                        color: .teal,
                        icon: "chart.line.uptrend.xyaxis"
                    )
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Charts Section
    
    @ViewBuilder
    private func ChartsSection() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Analytics", icon: "chart.xyaxis.line")
            
            VStack(spacing: 16) {
                // Revenue Chart
                ChartCardView(title: "Revenue Trend") {
                    Chart(dashboardViewModel.revenueData) { data in
                        LineMark(
                            x: .value("Date", data.date),
                            y: .value("Revenue", data.value)
                        )
                        .foregroundStyle(.green)
                        .interpolationMethod(.catmullRom)
                        
                        AreaMark(
                            x: .value("Date", data.date),
                            y: .value("Revenue", data.value)
                        )
                        .foregroundStyle(.green.opacity(0.2))
                        .interpolationMethod(.catmullRom)
                    }
                    .frame(height: 180)
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                            AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                        }
                    }
                    .chartYAxis {
                        AxisMarks { _ in
                            AxisValueLabel()
                        }
                    }
                }
                
                // Sales by Category
                ChartCardView(title: "Sales by Category") {
                    Chart(dashboardViewModel.categoryData) { data in
                        BarMark(
                            x: .value("Category", data.category),
                            y: .value("Sales", data.value)
                        )
                        .foregroundStyle(by: .value("Category", data.category))
                    }
                    .frame(height: 180)
                    .chartXAxis {
                        AxisMarks { _ in
                            AxisValueLabel()
                        }
                    }
                    .chartAngleSelection(value: .constant(nil))
                }
                
                // Client Activity Heatmap
                ChartCardView(title: "Client Activity") {
                    Chart(dashboardViewModel.activityData) { data in
                        RectangleMark(
                            x: .value("Hour", data.hour),
                            y: .value("Day", data.dayOfWeek)
                        )
                        .foregroundStyle(by: .value("Activity", data.activityLevel))
                    }
                    .frame(height: 140)
                    .chartXAxis {
                        AxisMarks(values: [0, 6, 12, 18, 23]) { value in
                            AxisValueLabel {
                                if let hour = value.as(Int.self) {
                                    Text("\(hour):00")
                                }
                            }
                        }
                    }
                    .chartYAxis {
                        AxisMarks { value in
                            AxisValueLabel {
                                if let day = value.as(String.self) {
                                    Text(day)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Performance Metrics Section
    
    @ViewBuilder
    private func PerformanceMetricsSection() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Performance Metrics", icon: "speedometer")
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                MetricCardView(
                    title: "Client Retention",
                    value: "\(dashboardViewModel.clientRetentionRate, specifier: "%.1f")%",
                    subtitle: "30-day retention",
                    color: .blue,
                    icon: "person.2.fill"
                )
                
                MetricCardView(
                    title: "Task Completion",
                    value: "\(dashboardViewModel.taskCompletionRate, specifier: "%.1f")%",
                    subtitle: "On-time completion",
                    color: .green,
                    icon: "checkmark.circle.fill"
                )
                
                MetricCardView(
                    title: "Response Time",
                    value: "\(dashboardViewModel.averageResponseTime, specifier: "%.1f")h",
                    subtitle: "Avg. response time",
                    color: .orange,
                    icon: "clock.fill"
                )
                
                MetricCardView(
                    title: "Customer Satisfaction",
                    value: "\(dashboardViewModel.customerSatisfaction, specifier: "%.1f")/5",
                    subtitle: "Avg. rating",
                    color: .yellow,
                    icon: "star.fill"
                )
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Quick Actions Section
    
    @ViewBuilder
    private func QuickActionsSection() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Quick Actions", icon: "bolt.fill")
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    QuickActionButton(
                        title: "New Task",
                        icon: "plus.circle.fill",
                        color: .blue
                    ) {
                        router.presentCreateTask()
                    }
                    
                    QuickActionButton(
                        title: "Add Client",
                        icon: "person.badge.plus",
                        color: .green
                    ) {
                        router.navigateToClientList()
                    }
                    
                    QuickActionButton(
                        title: "Create Ticket",
                        icon: "ticket.fill",
                        color: .orange
                    ) {
                        router.presentCreateTicket()
                    }
                    
                    QuickActionButton(
                        title: "Schedule Follow-up",
                        icon: "calendar.badge.plus",
                        color: .purple
                    ) {
                        router.presentCreateFollowUp()
                    }
                    
                    QuickActionButton(
                        title: "Documents",
                        icon: "folder.fill",
                        color: .indigo
                    ) {
                        router.navigateToDocuments()
                    }
                    
                    QuickActionButton(
                        title: "Generate Report",
                        icon: "doc.text.fill",
                        color: .teal
                    ) {
                        // TODO: Navigate to reports when implemented
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Recent Activity Section
    
    @ViewBuilder
    private func RecentActivitySection() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Recent Activity", icon: "clock.fill")
            
            VStack(spacing: 12) {
                ForEach(dashboardViewModel.recentActivities.prefix(5)) { activity in
                    ActivityRowView(activity: activity)
                }
                
                if dashboardViewModel.recentActivities.count > 5 {
                    Button("View All Activity") {
                        router.dashboardPath.append(NavigationDestination.activityHistory)
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                    .padding(.top, 8)
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Supporting Views

struct TimeRangePicker: View {
    @Binding var selectedRange: TimeRange
    
    var body: some View {
        Picker("Time Range", selection: $selectedRange) {
            ForEach(TimeRange.allCases, id: \.self) { range in
                Text(range.displayName).tag(range)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
    }
}

struct SectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            Spacer()
        }
        .padding(.horizontal)
    }
}

struct KPICardView: View {
    let title: String
    let value: String
    let change: Double
    let color: Color
    let icon: String
    
    private var changeColor: Color {
        change >= 0 ? .green : .red
    }
    
    private var changeIcon: String {
        change >= 0 ? "arrow.up.right" : "arrow.down.right"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: changeIcon)
                        .font(.caption)
                    Text("\(abs(change), specifier: "%.1f")%")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(changeColor)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(changeColor.opacity(0.1))
                .cornerRadius(4)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(width: 160, height: 100)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct ChartCardView<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
            
            content
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct MetricCardView: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            VStack(spacing: 4) {
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.1), radius: 4, x: 0, y: 2)
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
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
            }
            .frame(width: 80, height: 80)
            .background(color.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ActivityRowView: View {
    let activity: ActivityItem
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(activity.type.color)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(activity.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(activity.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(activity.timestamp, style: .relative)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - Supporting Types

enum TimeRange: CaseIterable {
    case today
    case thisWeek
    case thisMonth
    case thisQuarter
    case thisYear
    
    var displayName: String {
        switch self {
        case .today: return "Today"
        case .thisWeek: return "This Week"
        case .thisMonth: return "This Month"
        case .thisQuarter: return "This Quarter"
        case .thisYear: return "This Year"
        }
    }
    
    var dateRange: (start: Date, end: Date) {
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .today:
            return (calendar.startOfDay(for: now), now)
        case .thisWeek:
            let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
            return (startOfWeek, now)
        case .thisMonth:
            let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
            return (startOfMonth, now)
        case .thisQuarter:
            let quarter = calendar.component(.quarter, from: now)
            let startOfQuarter = calendar.date(from: DateComponents(year: calendar.component(.year, from: now), quarter: quarter)) ?? now
            return (startOfQuarter, now)
        case .thisYear:
            let startOfYear = calendar.dateInterval(of: .year, for: now)?.start ?? now
            return (startOfYear, now)
        }
    }
}

struct ChartDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

struct CategoryDataPoint: Identifiable {
    let id = UUID()
    let category: String
    let value: Double
}

struct ActivityDataPoint: Identifiable {
    let id = UUID()
    let hour: Int
    let dayOfWeek: String
    let activityLevel: Double
}

struct ActivityItem: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let timestamp: Date
    let type: ActivityType
}

enum ActivityType {
    case task
    case client
    case sale
    case ticket
    
    var color: Color {
        switch self {
        case .task: return .blue
        case .client: return .green
        case .sale: return .orange
        case .ticket: return .red
        }
    }
}
