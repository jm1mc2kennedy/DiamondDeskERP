//
//  AuditTrailViewModel.swift
//  DiamondDeskERP
//
//  Created by AI Assistant on 7/20/25.
//

import Foundation
import SwiftUI
import Combine

/// ViewModel for permissions audit trail
/// Handles audit log viewing, filtering, and analysis
@MainActor
final class AuditTrailViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var auditEntries: [PermissionAuditEntry] = []
    @Published var selectedEntry: PermissionAuditEntry?
    @Published var users: [UserProfile] = []
    
    // MARK: - Filtering
    
    @Published var searchText = ""
    @Published var selectedUser: String?
    @Published var selectedResource: PermissionResource?
    @Published var selectedAction: PermissionAuditEntry.AuditAction?
    @Published var selectedSuccess: Bool?
    @Published var dateRange: ClosedRange<Date>?
    @Published var timeRange: TimeRangeFilter = .lastWeek
    
    // MARK: - UI State
    
    @Published var isLoading = false
    @Published var showingEntryDetail = false
    @Published var showingExportOptions = false
    @Published var showingAnalytics = false
    @Published var showingFilters = false
    @Published var error: PermissionError?
    @Published var showingError = false
    
    // MARK: - Analytics
    
    @Published var analyticsData: AuditAnalytics?
    @Published var selectedAnalyticsPeriod: AnalyticsPeriod = .week
    @Published var selectedAnalyticsMetric: AnalyticsMetric = .successRate
    
    // MARK: - Export
    
    @Published var exportFormat: ExportFormat = .csv
    @Published var includeUserDetails = true
    @Published var includeTimestamps = true
    @Published var includeMetadata = false
    
    // MARK: - Private Properties
    
    private let permissionsService = UnifiedPermissionsService.shared
    private let userProvisioningService = UserProvisioningService.shared
    private var cancellables = Set<AnyCancellable>()
    private let pageSize = 100
    private var currentPage = 0
    private var hasMoreEntries = true
    
    // MARK: - Computed Properties
    
    var filteredEntries: [PermissionAuditEntry] {
        var entries = auditEntries
        
        // User filter
        if let selectedUser = selectedUser {
            entries = entries.filter { $0.userId == selectedUser }
        }
        
        // Resource filter
        if let selectedResource = selectedResource {
            entries = entries.filter { $0.resource == selectedResource }
        }
        
        // Action filter
        if let selectedAction = selectedAction {
            entries = entries.filter { $0.action == selectedAction }
        }
        
        // Success filter
        if let selectedSuccess = selectedSuccess {
            entries = entries.filter { $0.success == selectedSuccess }
        }
        
        // Date range filter
        let effectiveDateRange = dateRange ?? timeRange.dateRange
        entries = entries.filter { effectiveDateRange.contains($0.timestamp) }
        
        // Search filter
        if !searchText.isEmpty {
            entries = entries.filter {
                $0.userId.localizedCaseInsensitiveContains(searchText) ||
                $0.reason?.localizedCaseInsensitiveContains(searchText) == true ||
                $0.resource.rawValue.localizedCaseInsensitiveContains(searchText) ||
                $0.action.rawValue.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return entries.sorted { $0.timestamp > $1.timestamp }
    }
    
    var availableActions: [PermissionAuditEntry.AuditAction] {
        Array(Set(auditEntries.map { $0.action })).sorted { $0.rawValue < $1.rawValue }
    }
    
    var availableResources: [PermissionResource] {
        Array(Set(auditEntries.map { $0.resource })).sorted { $0.rawValue < $1.rawValue }
    }
    
    var availableUsers: [String] {
        Array(Set(auditEntries.map { $0.userId })).sorted()
    }
    
    var canViewAudit: Bool {
        Task {
            return await permissionsService.hasPermission(.audit, on: .audit)
        }
        return false // Placeholder
    }
    
    var canExportAudit: Bool {
        Task {
            return await permissionsService.hasPermission(.export, on: .audit)
        }
        return false // Placeholder
    }
    
    var entryStats: AuditStats {
        let total = filteredEntries.count
        let successful = filteredEntries.filter { $0.success }.count
        let failed = total - successful
        
        let uniqueUsers = Set(filteredEntries.map { $0.userId }).count
        let uniqueResources = Set(filteredEntries.map { $0.resource }).count
        
        return AuditStats(
            total: total,
            successful: successful,
            failed: failed,
            uniqueUsers: uniqueUsers,
            uniqueResources: uniqueResources,
            successRate: total > 0 ? Double(successful) / Double(total) * 100 : 0
        )
    }
    
    // MARK: - Initialization
    
    init() {
        observeServices()
        loadData()
        setupAnalytics()
    }
    
    // MARK: - Data Loading
    
    func loadData() {
        Task {
            await withTaskGroup(of: Void.self) { group in
                group.addTask { await self.loadAuditEntries() }
                group.addTask { await self.loadUsers() }
                group.addTask { await self.generateAnalytics() }
            }
        }
    }
    
    func loadAuditEntries(reset: Bool = false) async {
        guard !isLoading else { return }
        
        if reset {
            currentPage = 0
            hasMoreEntries = true
            await MainActor.run {
                self.auditEntries = []
            }
        }
        
        guard hasMoreEntries else { return }
        
        do {
            await MainActor.run { self.isLoading = true }
            
            let entries = await permissionsService.getAuditTrail(
                limit: pageSize,
                offset: currentPage * pageSize
            )
            
            await MainActor.run {
                if reset {
                    self.auditEntries = entries
                } else {
                    self.auditEntries.append(contentsOf: entries)
                }
                
                self.hasMoreEntries = entries.count == self.pageSize
                self.currentPage += 1
                self.isLoading = false
            }
            
        } catch {
            await MainActor.run {
                self.handleError(error)
                self.isLoading = false
            }
        }
    }
    
    func loadUsers() async {
        do {
            let userProfiles = try await userProvisioningService.getAllUsers()
            await MainActor.run {
                self.users = userProfiles
            }
        } catch {
            // Users are optional for audit trail
        }
    }
    
    func loadMoreEntries() {
        Task {
            await loadAuditEntries(reset: false)
        }
    }
    
    func refreshEntries() {
        Task {
            await loadAuditEntries(reset: true)
            await generateAnalytics()
        }
    }
    
    // MARK: - Filtering
    
    func applyTimeRange(_ range: TimeRangeFilter) {
        timeRange = range
        dateRange = nil // Clear custom date range
    }
    
    func applyCustomDateRange(_ range: ClosedRange<Date>) {
        dateRange = range
        timeRange = .custom // Set to custom
    }
    
    func clearFilters() {
        searchText = ""
        selectedUser = nil
        selectedResource = nil
        selectedAction = nil
        selectedSuccess = nil
        dateRange = nil
        timeRange = .lastWeek
    }
    
    func applyQuickFilter(_ filter: QuickFilter) {
        clearFilters()
        
        switch filter {
        case .failedAttempts:
            selectedSuccess = false
        case .roleAssignments:
            selectedAction = .roleAssigned
        case .permissionDenied:
            selectedAction = .permissionDenied
        case .lastHour:
            timeRange = .lastHour
        case .criticalActions:
            selectedResource = .roles
        }
    }
    
    // MARK: - Entry Detail
    
    func selectEntry(_ entry: PermissionAuditEntry) {
        selectedEntry = entry
        showingEntryDetail = true
    }
    
    func getEntryContext(_ entry: PermissionAuditEntry) -> AuditEntryContext {
        let userEntries = auditEntries.filter { $0.userId == entry.userId }
        let recentEntries = userEntries.filter {
            abs($0.timestamp.timeIntervalSince(entry.timestamp)) < 3600 // 1 hour
        }
        
        let relatedEntries = auditEntries.filter {
            $0.resource == entry.resource &&
            abs($0.timestamp.timeIntervalSince(entry.timestamp)) < 1800 // 30 minutes
        }
        
        return AuditEntryContext(
            entry: entry,
            userRecentActivity: recentEntries.count,
            relatedActivity: relatedEntries.count,
            riskLevel: calculateRiskLevel(entry, context: recentEntries)
        )
    }
    
    // MARK: - Analytics
    
    func generateAnalytics() async {
        let entries = filteredEntries
        let period = selectedAnalyticsPeriod
        
        let analytics = AuditAnalytics(
            period: period,
            totalEntries: entries.count,
            successRate: calculateSuccessRate(entries),
            topUsers: getTopUsers(entries, limit: 10),
            topResources: getTopResources(entries, limit: 10),
            topActions: getTopActions(entries, limit: 10),
            hourlyDistribution: getHourlyDistribution(entries),
            dailyTrend: getDailyTrend(entries, period: period),
            riskMetrics: calculateRiskMetrics(entries)
        )
        
        await MainActor.run {
            self.analyticsData = analytics
        }
    }
    
    // MARK: - Export
    
    func exportAuditTrail() -> URL? {
        switch exportFormat {
        case .csv:
            return exportAsCSV()
        case .json:
            return exportAsJSON()
        case .pdf:
            return exportAsPDF()
        }
    }
    
    func exportAsCSV() -> URL? {
        var csv = "Timestamp,User ID,User Name,Action,Resource,Success,Reason,IP Address,User Agent\n"
        
        for entry in filteredEntries {
            let userName = getUserName(for: entry.userId)
            let reason = entry.reason?.replacingOccurrences(of: ",", with: ";") ?? ""
            let ipAddress = entry.ipAddress ?? ""
            let userAgent = entry.userAgent?.replacingOccurrences(of: ",", with: ";") ?? ""
            
            csv += "\(entry.timestamp.ISO8601Format()),\(entry.userId),\(userName),\(entry.action.rawValue),\(entry.resource.rawValue),\(entry.success),\(reason),\(ipAddress),\(userAgent)\n"
        }
        
        return saveToFile(content: csv, filename: "audit_trail.csv")
    }
    
    func exportAsJSON() -> URL? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            let data = try encoder.encode(filteredEntries)
            let jsonString = String(data: data, encoding: .utf8) ?? ""
            return saveToFile(content: jsonString, filename: "audit_trail.json")
        } catch {
            handleError(error)
            return nil
        }
    }
    
    func exportAsPDF() -> URL? {
        let report = generateAuditReport()
        return saveToFile(content: report, filename: "audit_report.html")
    }
    
    // MARK: - Utility
    
    func getUserName(for userId: String) -> String {
        return users.first { $0.userId == userId }?.displayName ?? userId
    }
    
    func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
    
    func getRiskLevelColor(_ level: RiskLevel) -> Color {
        switch level {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        case .critical: return .purple
        }
    }
    
    func getActionIcon(_ action: PermissionAuditEntry.AuditAction) -> String {
        switch action {
        case .permissionChecked: return "checkmark.shield"
        case .permissionGranted: return "shield.fill"
        case .permissionDenied: return "shield.slash"
        case .roleAssigned: return "person.badge.plus"
        case .roleRevoked: return "person.badge.minus"
        case .roleCreated: return "plus.circle"
        case .roleUpdated: return "pencil.circle"
        case .roleDeleted: return "trash.circle"
        }
    }
    
    // MARK: - Private Methods
    
    private func observeServices() {
        permissionsService.$auditEntries
            .sink { [weak self] entries in
                if !entries.isEmpty {
                    self?.auditEntries = entries
                }
            }
            .store(in: &cancellables)
        
        permissionsService.$error
            .sink { [weak self] error in
                if let error = error {
                    self?.handleError(error)
                }
            }
            .store(in: &cancellables)
    }
    
    private func setupAnalytics() {
        // Subscribe to changes that should trigger analytics regeneration
        Publishers.CombineLatest4(
            $selectedAnalyticsPeriod,
            $selectedUser,
            $selectedResource,
            $timeRange
        )
        .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
        .sink { [weak self] _ in
            Task {
                await self?.generateAnalytics()
            }
        }
        .store(in: &cancellables)
    }
    
    private func handleError(_ error: Error) {
        self.error = error as? PermissionError ?? PermissionError.loadFailed(error)
        showingError = true
    }
    
    private func calculateSuccessRate(_ entries: [PermissionAuditEntry]) -> Double {
        guard !entries.isEmpty else { return 0 }
        let successful = entries.filter { $0.success }.count
        return Double(successful) / Double(entries.count) * 100
    }
    
    private func getTopUsers(_ entries: [PermissionAuditEntry], limit: Int) -> [(String, Int)] {
        let userCounts = Dictionary(grouping: entries, by: { $0.userId })
            .mapValues { $0.count }
        
        return Array(userCounts.sorted { $0.value > $1.value }.prefix(limit))
    }
    
    private func getTopResources(_ entries: [PermissionAuditEntry], limit: Int) -> [(PermissionResource, Int)] {
        let resourceCounts = Dictionary(grouping: entries, by: { $0.resource })
            .mapValues { $0.count }
        
        return Array(resourceCounts.sorted { $0.value > $1.value }.prefix(limit))
    }
    
    private func getTopActions(_ entries: [PermissionAuditEntry], limit: Int) -> [(PermissionAuditEntry.AuditAction, Int)] {
        let actionCounts = Dictionary(grouping: entries, by: { $0.action })
            .mapValues { $0.count }
        
        return Array(actionCounts.sorted { $0.value > $1.value }.prefix(limit))
    }
    
    private func getHourlyDistribution(_ entries: [PermissionAuditEntry]) -> [Int: Int] {
        let calendar = Calendar.current
        return Dictionary(grouping: entries) { entry in
            calendar.component(.hour, from: entry.timestamp)
        }.mapValues { $0.count }
    }
    
    private func getDailyTrend(_ entries: [PermissionAuditEntry], period: AnalyticsPeriod) -> [Date: Int] {
        let calendar = Calendar.current
        return Dictionary(grouping: entries) { entry in
            calendar.startOfDay(for: entry.timestamp)
        }.mapValues { $0.count }
    }
    
    private func calculateRiskMetrics(_ entries: [PermissionAuditEntry]) -> RiskMetrics {
        let failedAttempts = entries.filter { !$0.success }.count
        let criticalActions = entries.filter { 
            $0.resource == .roles || $0.resource == .audit 
        }.count
        
        let riskScore = calculateOverallRiskScore(entries)
        
        return RiskMetrics(
            failedAttempts: failedAttempts,
            criticalActions: criticalActions,
            overallRiskScore: riskScore,
            highRiskUsers: getHighRiskUsers(entries)
        )
    }
    
    private func calculateRiskLevel(_ entry: PermissionAuditEntry, context: [PermissionAuditEntry]) -> RiskLevel {
        var score = 0
        
        // Failed permission check
        if !entry.success { score += 2 }
        
        // Critical resource
        if entry.resource == .roles || entry.resource == .audit { score += 1 }
        
        // High frequency activity
        if context.count > 10 { score += 1 }
        
        // Failed attempts in context
        let failedInContext = context.filter { !$0.success }.count
        if failedInContext > 3 { score += 2 }
        
        switch score {
        case 0...1: return .low
        case 2...3: return .medium
        case 4...5: return .high
        default: return .critical
        }
    }
    
    private func calculateOverallRiskScore(_ entries: [PermissionAuditEntry]) -> Double {
        guard !entries.isEmpty else { return 0 }
        
        let weights: [PermissionAuditEntry.AuditAction: Double] = [
            .permissionDenied: 2.0,
            .roleRevoked: 1.5,
            .roleDeleted: 3.0,
            .roleCreated: 1.0,
            .roleAssigned: 0.5,
            .permissionGranted: 0.1,
            .permissionChecked: 0.1,
            .roleUpdated: 0.8
        ]
        
        let totalWeight = entries.reduce(0.0) { sum, entry in
            let weight = weights[entry.action] ?? 1.0
            let multiplier = entry.success ? 1.0 : 3.0 // Failed attempts are riskier
            return sum + (weight * multiplier)
        }
        
        return min(totalWeight / Double(entries.count) * 10, 100) // Normalize to 0-100
    }
    
    private func getHighRiskUsers(_ entries: [PermissionAuditEntry]) -> [String] {
        let userRiskScores = Dictionary(grouping: entries, by: { $0.userId })
            .mapValues { userEntries in
                calculateOverallRiskScore(userEntries)
            }
        
        return userRiskScores
            .filter { $0.value > 50 } // High risk threshold
            .sorted { $0.value > $1.value }
            .map { $0.key }
    }
    
    private func saveToFile(content: String, filename: String) -> URL? {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent("\(filename)_\(Date().timeIntervalSince1970)")
        
        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            handleError(error)
            return nil
        }
    }
    
    private func generateAuditReport() -> String {
        let stats = entryStats
        let analytics = analyticsData
        
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <title>Audit Trail Report</title>
            <style>
                body { font-family: Arial, sans-serif; margin: 20px; }
                .header { border-bottom: 2px solid #333; padding-bottom: 10px; }
                .stats { display: flex; justify-content: space-around; margin: 20px 0; }
                .stat { text-align: center; }
                .entries { margin-top: 20px; }
                table { width: 100%; border-collapse: collapse; }
                th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
                th { background-color: #f2f2f2; }
                .success { color: green; }
                .failed { color: red; }
            </style>
        </head>
        <body>
            <div class="header">
                <h1>Audit Trail Report</h1>
                <p>Generated: \(Date().formatted())</p>
                <p>Period: \(timeRange.displayName)</p>
                <p>Total Entries: \(stats.total)</p>
            </div>
            
            <div class="stats">
                <div class="stat">
                    <h3>Success Rate</h3>
                    <p>\(String(format: "%.1f", stats.successRate))%</p>
                </div>
                <div class="stat">
                    <h3>Unique Users</h3>
                    <p>\(stats.uniqueUsers)</p>
                </div>
                <div class="stat">
                    <h3>Resources Accessed</h3>
                    <p>\(stats.uniqueResources)</p>
                </div>
            </div>
            
            <div class="entries">
                <h2>Recent Entries</h2>
                <table>
                    <tr>
                        <th>Timestamp</th>
                        <th>User</th>
                        <th>Action</th>
                        <th>Resource</th>
                        <th>Status</th>
                        <th>Reason</th>
                    </tr>
                    \(filteredEntries.prefix(50).map { entry in
                        let status = entry.success ? "success" : "failed"
                        let statusText = entry.success ? "Success" : "Failed"
                        return """
                        <tr>
                            <td>\(formatTimestamp(entry.timestamp))</td>
                            <td>\(getUserName(for: entry.userId))</td>
                            <td>\(entry.action.rawValue)</td>
                            <td>\(entry.resource.rawValue)</td>
                            <td class="\(status)">\(statusText)</td>
                            <td>\(entry.reason ?? "")</td>
                        </tr>
                        """
                    }.joined())
                </table>
            </div>
        </body>
        </html>
        """
    }
}

// MARK: - Supporting Types

enum TimeRangeFilter: CaseIterable {
    case lastHour, lastDay, lastWeek, lastMonth, lastQuarter, lastYear, custom
    
    var displayName: String {
        switch self {
        case .lastHour: return "Last Hour"
        case .lastDay: return "Last Day"
        case .lastWeek: return "Last Week"
        case .lastMonth: return "Last Month"
        case .lastQuarter: return "Last Quarter"
        case .lastYear: return "Last Year"
        case .custom: return "Custom Range"
        }
    }
    
    var dateRange: ClosedRange<Date> {
        let now = Date()
        let calendar = Calendar.current
        
        switch self {
        case .lastHour:
            return calendar.date(byAdding: .hour, value: -1, to: now)!...now
        case .lastDay:
            return calendar.date(byAdding: .day, value: -1, to: now)!...now
        case .lastWeek:
            return calendar.date(byAdding: .weekOfYear, value: -1, to: now)!...now
        case .lastMonth:
            return calendar.date(byAdding: .month, value: -1, to: now)!...now
        case .lastQuarter:
            return calendar.date(byAdding: .month, value: -3, to: now)!...now
        case .lastYear:
            return calendar.date(byAdding: .year, value: -1, to: now)!...now
        case .custom:
            return now...now // Will be overridden
        }
    }
}

enum QuickFilter: CaseIterable {
    case failedAttempts, roleAssignments, permissionDenied, lastHour, criticalActions
    
    var displayName: String {
        switch self {
        case .failedAttempts: return "Failed Attempts"
        case .roleAssignments: return "Role Assignments"
        case .permissionDenied: return "Permission Denied"
        case .lastHour: return "Last Hour"
        case .criticalActions: return "Critical Actions"
        }
    }
}

enum AnalyticsPeriod: CaseIterable {
    case day, week, month, quarter, year
    
    var displayName: String {
        switch self {
        case .day: return "Daily"
        case .week: return "Weekly"
        case .month: return "Monthly"
        case .quarter: return "Quarterly"
        case .year: return "Yearly"
        }
    }
}

enum AnalyticsMetric: CaseIterable {
    case successRate, activityVolume, userDistribution, resourceAccess
    
    var displayName: String {
        switch self {
        case .successRate: return "Success Rate"
        case .activityVolume: return "Activity Volume"
        case .userDistribution: return "User Distribution"
        case .resourceAccess: return "Resource Access"
        }
    }
}

enum ExportFormat: CaseIterable {
    case csv, json, pdf
    
    var displayName: String {
        switch self {
        case .csv: return "CSV"
        case .json: return "JSON"
        case .pdf: return "PDF Report"
        }
    }
}

enum RiskLevel: CaseIterable {
    case low, medium, high, critical
    
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .critical: return "Critical"
        }
    }
}

struct AuditStats {
    let total: Int
    let successful: Int
    let failed: Int
    let uniqueUsers: Int
    let uniqueResources: Int
    let successRate: Double
}

struct AuditAnalytics {
    let period: AnalyticsPeriod
    let totalEntries: Int
    let successRate: Double
    let topUsers: [(String, Int)]
    let topResources: [(PermissionResource, Int)]
    let topActions: [(PermissionAuditEntry.AuditAction, Int)]
    let hourlyDistribution: [Int: Int]
    let dailyTrend: [Date: Int]
    let riskMetrics: RiskMetrics
}

struct RiskMetrics {
    let failedAttempts: Int
    let criticalActions: Int
    let overallRiskScore: Double
    let highRiskUsers: [String]
}

struct AuditEntryContext {
    let entry: PermissionAuditEntry
    let userRecentActivity: Int
    let relatedActivity: Int
    let riskLevel: RiskLevel
}
