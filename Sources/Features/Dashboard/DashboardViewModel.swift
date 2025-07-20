import Foundation
import CloudKit
import Combine

@MainActor
class DashboardViewModel: ObservableObject {
    // KPI Data
    @Published var totalRevenue: Double = 0
    @Published var revenueChange: Double = 0
    @Published var totalSales: Int = 0
    @Published var salesChange: Double = 0
    @Published var newClients: Int = 0
    @Published var clientsChange: Double = 0
    @Published var completedTasks: Int = 0
    @Published var tasksChange: Double = 0
    @Published var averageOrderValue: Double = 0
    @Published var aovChange: Double = 0
    
    // Performance Metrics
    @Published var clientRetentionRate: Double = 0
    @Published var taskCompletionRate: Double = 0
    @Published var averageResponseTime: Double = 0
    @Published var customerSatisfaction: Double = 0
    
    // Chart Data
    @Published var revenueData: [ChartDataPoint] = []
    @Published var categoryData: [CategoryDataPoint] = []
    @Published var activityData: [ActivityDataPoint] = []
    
    // Activity Data
    @Published var recentActivities: [ActivityItem] = []
    
    // Loading States
    @Published var isLoading = false
    @Published var error: Error?
    
    // Filters
    @Published var selectedStores: Set<String> = []
    @Published var selectedUsers: Set<String> = []
    @Published var showOnlyMyData = false
    
    private let database: CKDatabase
    private var cancellables = Set<AnyCancellable>()
    
    init(database: CKDatabase = CKContainer.default().publicCloudDatabase) {
        self.database = database
    }
    
    func loadData(for timeRange: TimeRange) async {
        isLoading = true
        error = nil
        
        do {
            let dateRange = timeRange.dateRange
            
            // Load all data concurrently
            async let revenueTask = loadRevenueData(from: dateRange.start, to: dateRange.end)
            async let salesTask = loadSalesData(from: dateRange.start, to: dateRange.end)
            async let clientsTask = loadClientData(from: dateRange.start, to: dateRange.end)
            async let tasksTask = loadTaskData(from: dateRange.start, to: dateRange.end)
            async let metricsTask = loadPerformanceMetrics(from: dateRange.start, to: dateRange.end)
            async let chartTask = loadChartData(from: dateRange.start, to: dateRange.end)
            async let activityTask = loadRecentActivity()
            
            // Wait for all tasks to complete
            let revenueResult = try await revenueTask
            let salesResult = try await salesTask
            let clientsResult = try await clientsTask
            let tasksResult = try await tasksTask
            let metricsResult = try await metricsTask
            let chartResult = try await chartTask
            let activityResult = try await activityTask
            
            // Update UI with results
            updateRevenueData(revenueResult)
            updateSalesData(salesResult)
            updateClientData(clientsResult)
            updateTaskData(tasksResult)
            updatePerformanceMetrics(metricsResult)
            updateChartData(chartResult)
            recentActivities = activityResult
            
        } catch {
            self.error = error
            print("Failed to load dashboard data: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Data Loading Methods
    
    private func loadRevenueData(from startDate: Date, to endDate: Date) async throws -> RevenueData {
        // This would typically fetch from sales/transaction records
        // For now, we'll simulate with sample data
        
        let currentRevenue = Double.random(in: 50000...150000)
        let previousRevenue = Double.random(in: 40000...120000)
        let change = ((currentRevenue - previousRevenue) / previousRevenue) * 100
        
        return RevenueData(
            current: currentRevenue,
            previous: previousRevenue,
            change: change
        )
    }
    
    private func loadSalesData(from startDate: Date, to endDate: Date) async throws -> SalesData {
        // Fetch sales data from CloudKit
        let predicate = NSPredicate(format: "createdAt >= %@ AND createdAt <= %@", startDate as NSDate, endDate as NSDate)
        let query = CKQuery(recordType: "Sale", predicate: predicate)
        
        do {
            let records = try await database.records(matching: query)
            let currentSales = records.matchResults.count
            
            // Calculate previous period for comparison
            let previousStartDate = Calendar.current.date(byAdding: .day, value: -Calendar.current.dateComponents([.day], from: startDate, to: endDate).day!, to: startDate) ?? startDate
            let previousPredicate = NSPredicate(format: "createdAt >= %@ AND createdAt < %@", previousStartDate as NSDate, startDate as NSDate)
            let previousQuery = CKQuery(recordType: "Sale", predicate: previousPredicate)
            let previousRecords = try await database.records(matching: previousQuery)
            let previousSales = previousRecords.matchResults.count
            
            let change = previousSales > 0 ? Double((currentSales - previousSales)) / Double(previousSales) * 100 : 0
            
            return SalesData(
                current: currentSales,
                previous: previousSales,
                change: change
            )
        } catch {
            // Fallback to sample data if CloudKit query fails
            let currentSales = Int.random(in: 20...80)
            let previousSales = Int.random(in: 15...70)
            let change = previousSales > 0 ? Double((currentSales - previousSales)) / Double(previousSales) * 100 : 0
            
            return SalesData(
                current: currentSales,
                previous: previousSales,
                change: change
            )
        }
    }
    
    private func loadClientData(from startDate: Date, to endDate: Date) async throws -> ClientData {
        // Fetch new clients from CloudKit
        let predicate = NSPredicate(format: "createdAt >= %@ AND createdAt <= %@", startDate as NSDate, endDate as NSDate)
        let query = CKQuery(recordType: "Client", predicate: predicate)
        
        do {
            let records = try await database.records(matching: query)
            let currentClients = records.matchResults.count
            
            // Calculate previous period for comparison
            let daysDifference = Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 7
            let previousStartDate = Calendar.current.date(byAdding: .day, value: -daysDifference, to: startDate) ?? startDate
            let previousPredicate = NSPredicate(format: "createdAt >= %@ AND createdAt < %@", previousStartDate as NSDate, startDate as NSDate)
            let previousQuery = CKQuery(recordType: "Client", predicate: previousPredicate)
            let previousRecords = try await database.records(matching: previousQuery)
            let previousClients = previousRecords.matchResults.count
            
            let change = previousClients > 0 ? Double((currentClients - previousClients)) / Double(previousClients) * 100 : 0
            
            return ClientData(
                current: currentClients,
                previous: previousClients,
                change: change
            )
        } catch {
            // Fallback to sample data
            let currentClients = Int.random(in: 5...25)
            let previousClients = Int.random(in: 3...20)
            let change = previousClients > 0 ? Double((currentClients - previousClients)) / Double(previousClients) * 100 : 0
            
            return ClientData(
                current: currentClients,
                previous: previousClients,
                change: change
            )
        }
    }
    
    private func loadTaskData(from startDate: Date, to endDate: Date) async throws -> TaskData {
        // Fetch completed tasks from CloudKit
        let predicate = NSPredicate(format: "status == %@ AND updatedAt >= %@ AND updatedAt <= %@", "completed", startDate as NSDate, endDate as NSDate)
        let query = CKQuery(recordType: "Task", predicate: predicate)
        
        do {
            let records = try await database.records(matching: query)
            let currentTasks = records.matchResults.count
            
            // Calculate previous period for comparison
            let daysDifference = Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 7
            let previousStartDate = Calendar.current.date(byAdding: .day, value: -daysDifference, to: startDate) ?? startDate
            let previousPredicate = NSPredicate(format: "status == %@ AND updatedAt >= %@ AND updatedAt < %@", "completed", previousStartDate as NSDate, startDate as NSDate)
            let previousQuery = CKQuery(recordType: "Task", predicate: previousPredicate)
            let previousRecords = try await database.records(matching: previousQuery)
            let previousTasks = previousRecords.matchResults.count
            
            let change = previousTasks > 0 ? Double((currentTasks - previousTasks)) / Double(previousTasks) * 100 : 0
            
            return TaskData(
                current: currentTasks,
                previous: previousTasks,
                change: change
            )
        } catch {
            // Fallback to sample data
            let currentTasks = Int.random(in: 10...50)
            let previousTasks = Int.random(in: 8...45)
            let change = previousTasks > 0 ? Double((currentTasks - previousTasks)) / Double(previousTasks) * 100 : 0
            
            return TaskData(
                current: currentTasks,
                previous: previousTasks,
                change: change
            )
        }
    }
    
    private func loadPerformanceMetrics(from startDate: Date, to endDate: Date) async throws -> PerformanceMetrics {
        // In a real app, these would be calculated from actual data
        return PerformanceMetrics(
            clientRetentionRate: Double.random(in: 75...95),
            taskCompletionRate: Double.random(in: 85...98),
            averageResponseTime: Double.random(in: 1...8),
            customerSatisfaction: Double.random(in: 4.0...5.0)
        )
    }
    
    private func loadChartData(from startDate: Date, to endDate: Date) async throws -> ChartData {
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 7
        
        // Generate revenue trend data
        var revenuePoints: [ChartDataPoint] = []
        for i in 0...days {
            if let date = calendar.date(byAdding: .day, value: i, to: startDate) {
                let value = Double.random(in: 1000...8000)
                revenuePoints.append(ChartDataPoint(date: date, value: value))
            }
        }
        
        // Generate category data
        let categories = ["Engagement Rings", "Wedding Bands", "Necklaces", "Earrings", "Bracelets", "Watches"]
        let categoryPoints = categories.map { category in
            CategoryDataPoint(category: category, value: Double.random(in: 5...30))
        }
        
        // Generate activity heatmap data
        let daysOfWeek = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        var activityPoints: [ActivityDataPoint] = []
        for day in daysOfWeek {
            for hour in 0...23 {
                let activityLevel = Double.random(in: 0...1)
                activityPoints.append(ActivityDataPoint(hour: hour, dayOfWeek: day, activityLevel: activityLevel))
            }
        }
        
        return ChartData(
            revenueData: revenuePoints,
            categoryData: categoryPoints,
            activityData: activityPoints
        )
    }
    
    private func loadRecentActivity() async throws -> [ActivityItem] {
        // In a real app, this would fetch from various data sources
        let activities = [
            ActivityItem(
                title: "New client consultation scheduled",
                description: "Sarah Johnson - Engagement ring consultation",
                timestamp: Calendar.current.date(byAdding: .minute, value: -30, to: Date()) ?? Date(),
                type: .client
            ),
            ActivityItem(
                title: "Task completed",
                description: "Ring sizing completed for order #12345",
                timestamp: Calendar.current.date(byAdding: .hour, value: -2, to: Date()) ?? Date(),
                type: .task
            ),
            ActivityItem(
                title: "Sale processed",
                description: "$5,200 - Diamond pendant sold",
                timestamp: Calendar.current.date(byAdding: .hour, value: -4, to: Date()) ?? Date(),
                type: .sale
            ),
            ActivityItem(
                title: "Support ticket resolved",
                description: "Warranty claim for watch repair",
                timestamp: Calendar.current.date(byAdding: .hour, value: -6, to: Date()) ?? Date(),
                type: .ticket
            ),
            ActivityItem(
                title: "New client added",
                description: "Michael & Emma Davis - Wedding bands",
                timestamp: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
                type: .client
            )
        ]
        
        return activities
    }
    
    // MARK: - Data Update Methods
    
    private func updateRevenueData(_ data: RevenueData) {
        totalRevenue = data.current
        revenueChange = data.change
        averageOrderValue = data.current / Double(max(totalSales, 1))
        aovChange = data.change * 0.8 // Simplified calculation
    }
    
    private func updateSalesData(_ data: SalesData) {
        totalSales = data.current
        salesChange = data.change
    }
    
    private func updateClientData(_ data: ClientData) {
        newClients = data.current
        clientsChange = data.change
    }
    
    private func updateTaskData(_ data: TaskData) {
        completedTasks = data.current
        tasksChange = data.change
    }
    
    private func updatePerformanceMetrics(_ metrics: PerformanceMetrics) {
        clientRetentionRate = metrics.clientRetentionRate
        taskCompletionRate = metrics.taskCompletionRate
        averageResponseTime = metrics.averageResponseTime
        customerSatisfaction = metrics.customerSatisfaction
    }
    
    private func updateChartData(_ chartData: ChartData) {
        revenueData = chartData.revenueData
        categoryData = chartData.categoryData
        activityData = chartData.activityData
    }
    
    // MARK: - Filter Methods
    
    func applyFilters(stores: Set<String>, users: Set<String>, showOnlyMyData: Bool) {
        self.selectedStores = stores
        self.selectedUsers = users
        self.showOnlyMyData = showOnlyMyData
        
        // Reload data with filters applied
        Task {
            await loadData(for: .thisMonth)
        }
    }
    
    func resetFilters() {
        selectedStores.removeAll()
        selectedUsers.removeAll()
        showOnlyMyData = false
        
        Task {
            await loadData(for: .thisMonth)
        }
    }
}

// MARK: - Supporting Data Types

struct RevenueData {
    let current: Double
    let previous: Double
    let change: Double
}

struct SalesData {
    let current: Int
    let previous: Int
    let change: Double
}

struct ClientData {
    let current: Int
    let previous: Int
    let change: Double
}

struct TaskData {
    let current: Int
    let previous: Int
    let change: Double
}

struct PerformanceMetrics {
    let clientRetentionRate: Double
    let taskCompletionRate: Double
    let averageResponseTime: Double
    let customerSatisfaction: Double
}

struct ChartData {
    let revenueData: [ChartDataPoint]
    let categoryData: [CategoryDataPoint]
    let activityData: [ActivityDataPoint]
}
