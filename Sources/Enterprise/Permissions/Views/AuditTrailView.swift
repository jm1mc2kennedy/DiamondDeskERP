//
//  AuditTrailView.swift
//  DiamondDeskERP
//
//  Created by AI Assistant on 7/20/25.
//

import SwiftUI
import Charts

/// Comprehensive audit trail management interface
struct AuditTrailView: View {
    @StateObject private var viewModel = AuditTrailViewModel()
    @State private var selectedTab: AuditTab = .entries
    
    var body: some View {
        NavigationStack {
            VStack {
                // Header Stats
                AuditStatsHeaderView(stats: viewModel.entryStats)
                    .padding(.horizontal)
                
                // Tab Navigation
                Picker("View", selection: $selectedTab) {
                    ForEach(AuditTab.allCases, id: \.self) { tab in
                        Text(tab.title).tag(tab)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // Main Content
                TabView(selection: $selectedTab) {
                    AuditEntriesView(viewModel: viewModel)
                        .tag(AuditTab.entries)
                    
                    AuditAnalyticsView(viewModel: viewModel)
                        .tag(AuditTab.analytics)
                    
                    AuditFiltersView(viewModel: viewModel)
                        .tag(AuditTab.filters)
                    
                    AuditReportsView(viewModel: viewModel)
                        .tag(AuditTab.reports)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("Audit Trail")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Menu {
                        ForEach(QuickFilter.allCases, id: \.self) { filter in
                            Button(filter.displayName) {
                                viewModel.applyQuickFilter(filter)
                            }
                        }
                        
                        Divider()
                        
                        Button("Clear Filters") {
                            viewModel.clearFilters()
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                    
                    Menu {
                        Button("Refresh") {
                            viewModel.refreshEntries()
                        }
                        
                        if viewModel.canExportAudit {
                            Divider()
                            
                            Button("Export CSV") {
                                viewModel.exportFormat = .csv
                                if let _ = viewModel.exportAuditTrail() {
                                    viewModel.showingExportOptions = true
                                }
                            }
                            
                            Button("Export JSON") {
                                viewModel.exportFormat = .json
                                if let _ = viewModel.exportAuditTrail() {
                                    viewModel.showingExportOptions = true
                                }
                            }
                            
                            Button("Generate Report") {
                                viewModel.exportFormat = .pdf
                                if let _ = viewModel.exportAuditTrail() {
                                    viewModel.showingExportOptions = true
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $viewModel.showingEntryDetail) {
            if let selectedEntry = viewModel.selectedEntry {
                AuditEntryDetailView(entry: selectedEntry, context: viewModel.getEntryContext(selectedEntry))
            }
        }
        .sheet(isPresented: $viewModel.showingAnalytics) {
            AuditAnalyticsDetailView(analytics: viewModel.analyticsData)
        }
        .alert("Error", isPresented: $viewModel.showingError) {
            Button("OK") { }
        } message: {
            if let error = viewModel.error {
                Text(error.localizedDescription)
            }
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView("Loading audit trail...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.1))
            }
        }
        .onAppear {
            if viewModel.auditEntries.isEmpty {
                viewModel.loadData()
            }
        }
    }
}

// MARK: - Audit Tabs

enum AuditTab: CaseIterable {
    case entries, analytics, filters, reports
    
    var title: String {
        switch self {
        case .entries: return "Entries"
        case .analytics: return "Analytics"
        case .filters: return "Filters"
        case .reports: return "Reports"
        }
    }
}

// MARK: - Audit Stats Header

struct AuditStatsHeaderView: View {
    let stats: AuditStats
    
    var body: some View {
        HStack(spacing: 15) {
            AuditStatCard(
                title: "Total",
                value: "\(stats.total)",
                color: .blue,
                icon: "doc.text"
            )
            
            AuditStatCard(
                title: "Success Rate",
                value: "\(String(format: "%.1f", stats.successRate))%",
                color: stats.successRate > 90 ? .green : stats.successRate > 70 ? .orange : .red,
                icon: "checkmark.circle"
            )
            
            AuditStatCard(
                title: "Users",
                value: "\(stats.uniqueUsers)",
                color: .purple,
                icon: "person.2"
            )
            
            AuditStatCard(
                title: "Resources",
                value: "\(stats.uniqueResources)",
                color: .orange,
                icon: "folder"
            )
        }
        .padding(.vertical, 12)
    }
}

struct AuditStatCard: View {
    let title: String
    let value: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Audit Entries View

struct AuditEntriesView: View {
    @ObservedObject var viewModel: AuditTrailViewModel
    
    var body: some View {
        VStack {
            // Time Range Selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(TimeRangeFilter.allCases, id: \.self) { range in
                        Button(range.displayName) {
                            viewModel.applyTimeRange(range)
                        }
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(viewModel.timeRange == range ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                        .foregroundColor(viewModel.timeRange == range ? .blue : .primary)
                        .cornerRadius(16)
                    }
                }
                .padding(.horizontal)
            }
            
            // Entries List
            List {
                ForEach(viewModel.filteredEntries, id: \.id) { entry in
                    AuditEntryRowView(entry: entry, viewModel: viewModel)
                        .onTapGesture {
                            viewModel.selectEntry(entry)
                        }
                        .onAppear {
                            // Load more entries when near the end
                            if entry.id == viewModel.filteredEntries.last?.id {
                                viewModel.loadMoreEntries()
                            }
                        }
                }
                
                if viewModel.isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                            .padding()
                        Spacer()
                    }
                }
            }
            .searchable(text: $viewModel.searchText, prompt: "Search audit entries...")
            .refreshable {
                viewModel.refreshEntries()
            }
        }
    }
}

// MARK: - Audit Entry Row

struct AuditEntryRowView: View {
    let entry: PermissionAuditEntry
    @ObservedObject var viewModel: AuditTrailViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Action Icon
                Image(systemName: viewModel.getActionIcon(entry.action))
                    .font(.title3)
                    .foregroundColor(entry.success ? .green : .red)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(entry.action.rawValue.capitalized)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text(viewModel.formatTimestamp(entry.timestamp))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text(viewModel.getUserName(for: entry.userId))
                            .font(.subheadline)
                            .foregroundColor(.blue)
                        
                        Text("•")
                            .foregroundColor(.secondary)
                        
                        Text(entry.resource.rawValue.capitalized)
                            .font(.subheadline)
                            .foregroundColor(.orange)
                        
                        Spacer()
                        
                        StatusIndicatorView(success: entry.success)
                    }
                }
            }
            
            // Additional Details
            if let reason = entry.reason, !reason.isEmpty {
                HStack {
                    Image(systemName: "quote.bubble")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(reason)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .italic()
                }
                .padding(.leading, 32)
            }
            
            // Risk and Context
            let context = viewModel.getEntryContext(entry)
            HStack {
                RiskLevelBadge(level: context.riskLevel)
                
                if context.userRecentActivity > 5 {
                    Text("High Activity")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.2))
                        .foregroundColor(.orange)
                        .cornerRadius(4)
                }
                
                if context.relatedActivity > 10 {
                    Text("Related Events")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.purple.opacity(0.2))
                        .foregroundColor(.purple)
                        .cornerRadius(4)
                }
                
                Spacer()
                
                if let ipAddress = entry.ipAddress {
                    Text(ipAddress)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.leading, 32)
        }
        .padding(.vertical, 4)
        .contextMenu {
            Button(action: { viewModel.selectEntry(entry) }) {
                Label("View Details", systemImage: "info.circle")
            }
            
            Button(action: {
                viewModel.selectedUser = entry.userId
            }) {
                Label("Filter by User", systemImage: "person.circle")
            }
            
            Button(action: {
                viewModel.selectedResource = entry.resource
            }) {
                Label("Filter by Resource", systemImage: "folder.circle")
            }
            
            Button(action: {
                UIPasteboard.general.string = "\(entry.timestamp): \(entry.userId) \(entry.action.rawValue) \(entry.resource.rawValue) - \(entry.success ? "Success" : "Failed")"
            }) {
                Label("Copy Entry", systemImage: "doc.on.clipboard")
            }
        }
    }
}

// MARK: - Status Indicator

struct StatusIndicatorView: View {
    let success: Bool
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(success ? Color.green : Color.red)
                .frame(width: 8, height: 8)
            
            Text(success ? "Success" : "Failed")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(success ? .green : .red)
        }
    }
}

// MARK: - Risk Level Badge

struct RiskLevelBadge: View {
    let level: RiskLevel
    
    var body: some View {
        Text(level.displayName)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(backgroundColor.opacity(0.2))
            .foregroundColor(backgroundColor)
            .cornerRadius(4)
    }
    
    private var backgroundColor: Color {
        switch level {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        case .critical: return .purple
        }
    }
}

// MARK: - Audit Analytics View

struct AuditAnalyticsView: View {
    @ObservedObject var viewModel: AuditTrailViewModel
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Analytics Period Selector
                Picker("Period", selection: $viewModel.selectedAnalyticsPeriod) {
                    ForEach(AnalyticsPeriod.allCases, id: \.self) { period in
                        Text(period.displayName).tag(period)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                if let analytics = viewModel.analyticsData {
                    // Success Rate Trend
                    GroupBox("Success Rate Trend") {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("\(String(format: "%.1f", analytics.successRate))%")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(analytics.successRate > 90 ? .green : .orange)
                                
                                Spacer()
                                
                                Text("Overall Success Rate")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            // Chart placeholder
                            Rectangle()
                                .fill(Color.blue.opacity(0.1))
                                .frame(height: 120)
                                .cornerRadius(8)
                                .overlay(
                                    Text("Success Rate Chart")
                                        .foregroundColor(.secondary)
                                )
                        }
                    }
                    
                    // Activity Volume
                    GroupBox("Activity Volume") {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("\(analytics.totalEntries) total entries")
                                .font(.headline)
                            
                            // Hourly distribution chart placeholder
                            Rectangle()
                                .fill(Color.green.opacity(0.1))
                                .frame(height: 100)
                                .cornerRadius(8)
                                .overlay(
                                    Text("Hourly Activity Chart")
                                        .foregroundColor(.secondary)
                                )
                        }
                    }
                    
                    // Top Users
                    GroupBox("Most Active Users") {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(analytics.topUsers.prefix(5), id: \.0) { user, count in
                                HStack {
                                    Text(viewModel.getUserName(for: user))
                                        .font(.subheadline)
                                    
                                    Spacer()
                                    
                                    Text("\(count)")
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                    
                    // Top Resources
                    GroupBox("Most Accessed Resources") {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(analytics.topResources.prefix(5), id: \.0.rawValue) { resource, count in
                                HStack {
                                    Text(resource.rawValue.capitalized)
                                        .font(.subheadline)
                                    
                                    Spacer()
                                    
                                    Text("\(count)")
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.orange)
                                }
                            }
                        }
                    }
                    
                    // Risk Metrics
                    GroupBox("Risk Analysis") {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Risk Score")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Text("\(String(format: "%.1f", analytics.riskMetrics.overallRiskScore))")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(riskScoreColor(analytics.riskMetrics.overallRiskScore))
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing) {
                                    Text("Failed Attempts")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Text("\(analytics.riskMetrics.failedAttempts)")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.red)
                                }
                            }
                            
                            if !analytics.riskMetrics.highRiskUsers.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("High Risk Users:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    ForEach(analytics.riskMetrics.highRiskUsers.prefix(3), id: \.self) { userId in
                                        Text(viewModel.getUserName(for: userId))
                                            .font(.caption)
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .refreshable {
            Task {
                await viewModel.generateAnalytics()
            }
        }
    }
    
    private func riskScoreColor(_ score: Double) -> Color {
        switch score {
        case 0...25: return .green
        case 25...50: return .yellow
        case 50...75: return .orange
        default: return .red
        }
    }
}

// MARK: - Audit Filters View

struct AuditFiltersView: View {
    @ObservedObject var viewModel: AuditTrailViewModel
    
    var body: some View {
        Form {
            Section("User Filter") {
                Picker("Select User", selection: $viewModel.selectedUser) {
                    Text("All Users").tag(nil as String?)
                    
                    ForEach(viewModel.availableUsers, id: \.self) { userId in
                        Text(viewModel.getUserName(for: userId)).tag(userId as String?)
                    }
                }
            }
            
            Section("Resource Filter") {
                Picker("Select Resource", selection: $viewModel.selectedResource) {
                    Text("All Resources").tag(nil as PermissionResource?)
                    
                    ForEach(viewModel.availableResources, id: \.self) { resource in
                        Text(resource.rawValue.capitalized).tag(resource as PermissionResource?)
                    }
                }
            }
            
            Section("Action Filter") {
                Picker("Select Action", selection: $viewModel.selectedAuditAction) {
                    Text("All Actions").tag(nil as PermissionAuditEntry.AuditAction?)
                    
                    ForEach(viewModel.availableActions, id: \.self) { action in
                        Text(action.rawValue.capitalized).tag(action as PermissionAuditEntry.AuditAction?)
                    }
                }
            }
            
            Section("Success Filter") {
                Picker("Success Status", selection: $viewModel.selectedSuccess) {
                    Text("All").tag(nil as Bool?)
                    Text("Success Only").tag(true as Bool?)
                    Text("Failed Only").tag(false as Bool?)
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            Section("Time Range") {
                Picker("Time Range", selection: $viewModel.timeRange) {
                    ForEach(TimeRangeFilter.allCases, id: \.self) { range in
                        Text(range.displayName).tag(range)
                    }
                }
                
                if viewModel.timeRange == .custom, let dateRange = viewModel.dateRange {
                    DatePicker("From", selection: .constant(dateRange.lowerBound), displayedComponents: [.date, .hourAndMinute])
                        .disabled(true)
                    
                    DatePicker("To", selection: .constant(dateRange.upperBound), displayedComponents: [.date, .hourAndMinute])
                        .disabled(true)
                }
            }
            
            Section {
                Button("Clear All Filters") {
                    viewModel.clearFilters()
                }
                .foregroundColor(.blue)
            }
        }
    }
}

// MARK: - Audit Reports View

struct AuditReportsView: View {
    @ObservedObject var viewModel: AuditTrailViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Generate Reports")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top)
            
            // Export Options
            GroupBox("Export Options") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Choose export format:")
                        .font(.headline)
                    
                    Picker("Format", selection: $viewModel.exportFormat) {
                        ForEach(ExportFormat.allCases, id: \.self) { format in
                            Text(format.displayName).tag(format)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    Toggle("Include User Details", isOn: $viewModel.includeUserDetails)
                    Toggle("Include Timestamps", isOn: $viewModel.includeTimestamps)
                    Toggle("Include Metadata", isOn: $viewModel.includeMetadata)
                    
                    Button("Export Audit Trail") {
                        if let url = viewModel.exportAuditTrail() {
                            viewModel.showingExportOptions = true
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!viewModel.canExportAudit)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // Quick Reports
            GroupBox("Quick Reports") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Generate predefined reports:")
                        .font(.headline)
                    
                    VStack(spacing: 8) {
                        Button("Security Summary Report") {
                            // Generate security summary
                        }
                        .buttonStyle(.bordered)
                        .frame(maxWidth: .infinity)
                        
                        Button("Failed Attempts Report") {
                            viewModel.selectedSuccess = false
                            if let url = viewModel.exportAuditTrail() {
                                viewModel.showingExportOptions = true
                            }
                        }
                        .buttonStyle(.bordered)
                        .frame(maxWidth: .infinity)
                        
                        Button("User Activity Report") {
                            // Generate user activity report
                        }
                        .buttonStyle(.bordered)
                        .frame(maxWidth: .infinity)
                        
                        Button("Risk Analysis Report") {
                            // Generate risk analysis
                        }
                        .buttonStyle(.bordered)
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - Audit Entry Detail View

struct AuditEntryDetailView: View {
    let entry: PermissionAuditEntry
    let context: AuditEntryContext
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section("Entry Details") {
                    DetailRowView(label: "Timestamp", value: entry.timestamp.formatted(.dateTime))
                    DetailRowView(label: "User ID", value: entry.userId)
                    DetailRowView(label: "Action", value: entry.action.rawValue.capitalized)
                    DetailRowView(label: "Resource", value: entry.resource.rawValue.capitalized)
                    DetailRowView(label: "Success", value: entry.success ? "Yes" : "No", valueColor: entry.success ? .green : .red)
                    
                    if let reason = entry.reason {
                        DetailRowView(label: "Reason", value: reason)
                    }
                }
                
                if entry.ipAddress != nil || entry.userAgent != nil {
                    Section("Technical Details") {
                        if let ipAddress = entry.ipAddress {
                            DetailRowView(label: "IP Address", value: ipAddress)
                        }
                        
                        if let userAgent = entry.userAgent {
                            DetailRowView(label: "User Agent", value: userAgent)
                        }
                    }
                }
                
                Section("Context Analysis") {
                    DetailRowView(label: "Risk Level", value: context.riskLevel.displayName, valueColor: riskLevelColor(context.riskLevel))
                    DetailRowView(label: "User Recent Activity", value: "\(context.userRecentActivity) events")
                    DetailRowView(label: "Related Activity", value: "\(context.relatedActivity) events")
                }
                
                if !entry.metadata.isEmpty {
                    Section("Metadata") {
                        ForEach(Array(entry.metadata.keys.sorted()), id: \.self) { key in
                            DetailRowView(label: key, value: entry.metadata[key] ?? "")
                        }
                    }
                }
            }
            .navigationTitle("Audit Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func riskLevelColor(_ level: RiskLevel) -> Color {
        switch level {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        case .critical: return .purple
        }
    }
}

struct DetailRowView: View {
    let label: String
    let value: String
    let valueColor: Color?
    
    init(label: String, value: String, valueColor: Color? = nil) {
        self.label = label
        self.value = value
        self.valueColor = valueColor
    }
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(valueColor ?? .primary)
                .multilineTextAlignment(.trailing)
        }
    }
}

// MARK: - Analytics Detail View

struct AuditAnalyticsDetailView: View {
    let analytics: AuditAnalytics?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Group {
                if let analytics = analytics {
                    List {
                        Section("Overview") {
                            DetailRowView(label: "Period", value: analytics.period.displayName)
                            DetailRowView(label: "Total Entries", value: "\(analytics.totalEntries)")
                            DetailRowView(label: "Success Rate", value: "\(String(format: "%.1f", analytics.successRate))%")
                        }
                        
                        Section("Top Users") {
                            ForEach(analytics.topUsers.prefix(10), id: \.0) { user, count in
                                HStack {
                                    Text(user)
                                    Spacer()
                                    Text("\(count)")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        
                        Section("Top Resources") {
                            ForEach(analytics.topResources.prefix(10), id: \.0.rawValue) { resource, count in
                                HStack {
                                    Text(resource.rawValue.capitalized)
                                    Spacer()
                                    Text("\(count)")
                                        .foregroundColor(.orange)
                                }
                            }
                        }
                        
                        Section("Risk Metrics") {
                            DetailRowView(label: "Overall Risk Score", value: "\(String(format: "%.1f", analytics.riskMetrics.overallRiskScore))")
                            DetailRowView(label: "Failed Attempts", value: "\(analytics.riskMetrics.failedAttempts)")
                            DetailRowView(label: "Critical Actions", value: "\(analytics.riskMetrics.criticalActions)")
                            DetailRowView(label: "High Risk Users", value: "\(analytics.riskMetrics.highRiskUsers.count)")
                        }
                    }
                } else {
                    ContentUnavailableView("No Analytics Data", systemImage: "chart.bar.xaxis", description: Text("Analytics data is not available"))
                }
            }
            .navigationTitle("Analytics Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
