//
//  EventQAConsoleView.swift
//  DiamondDeskERP
//
//  Created by AI Assistant on 7/20/25.
//

import SwiftUI
import Combine

/// Administrative Event QA Console for real-time monitoring and debugging
/// Provides comprehensive event monitoring, error tracking, and system metrics
struct EventQAConsoleView: View {
    @StateObject private var eventQAService = EventQAService.shared
    @State private var selectedTab: ConsoleTab = .events
    @State private var isExporting = false
    @State private var showingAlert = false
    @State private var searchText = ""
    @State private var navigationPath = NavigationPath()
    
    enum ConsoleTab: String, CaseIterable {
        case events = "Events"
        case errors = "Errors"
        case metrics = "Metrics"
        case alerts = "Alerts"
    }
    
    var body: some View {
        SimpleAdaptiveNavigationView(path: $navigationPath) {
            VStack(spacing: 0) {
                // Header with controls
                headerView
                
                // Tab picker
                tabPickerView
                
                // Content area
                contentView
            }
            .navigationTitle("Event QA Console")
            .navigationBarTitleDisplayMode(.large)
            .background(Color(.systemGroupedBackground))
            .alert("Export Complete", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text("Event log has been exported to clipboard")
            }
        }
        .onAppear {
            if !eventQAService.isMonitoring {
                eventQAService.startMonitoring()
            }
        }
    }
    
    // MARK: - Header View
    
    @ViewBuilder
    private var headerView: some View {
        HStack {
            // Monitoring status
            HStack(spacing: 8) {
                Circle()
                    .fill(eventQAService.isMonitoring ? .green : .red)
                    .frame(width: 8, height: 8)
                
                Text(eventQAService.isMonitoring ? "Monitoring Active" : "Monitoring Inactive")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Controls
            HStack(spacing: 12) {
                // Toggle monitoring
                Button(action: toggleMonitoring) {
                    Image(systemName: eventQAService.isMonitoring ? "pause.circle" : "play.circle")
                        .foregroundStyle(.blue)
                }
                
                // Clear history
                Button(action: clearHistory) {
                    Image(systemName: "trash.circle")
                        .foregroundStyle(.red)
                }
                
                // Export log
                Button(action: exportLog) {
                    Image(systemName: "square.and.arrow.up.circle")
                        .foregroundStyle(.green)
                }
            }
            .font(.title2)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Tab Picker
    
    @ViewBuilder
    private var tabPickerView: some View {
        HStack(spacing: 0) {
            ForEach(ConsoleTab.allCases, id: \.self) { tab in
                Button(action: { selectedTab = tab }) {
                    VStack(spacing: 4) {
                        HStack(spacing: 4) {
                            Text(tab.rawValue)
                                .font(.subheadline)
                                .fontWeight(selectedTab == tab ? .semibold : .regular)
                            
                            // Badge for counts
                            if let count = tabBadgeCount(for: tab), count > 0 {
                                Text("\(count)")
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(badgeColor(for: tab), in: Capsule())
                            }
                        }
                        
                        Rectangle()
                            .fill(selectedTab == tab ? .blue : .clear)
                            .frame(height: 2)
                    }
                }
                .foregroundStyle(selectedTab == tab ? .primary : .secondary)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal)
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Content View
    
    @ViewBuilder
    private var contentView: some View {
        VStack(spacing: 0) {
            // Search bar for events and errors
            if selectedTab == .events || selectedTab == .errors {
                searchBarView
            }
            
            // Tab content
            switch selectedTab {
            case .events:
                eventsView
            case .errors:
                errorsView
            case .metrics:
                metricsView
            case .alerts:
                alertsView
            }
        }
    }
    
    // MARK: - Search Bar
    
    @ViewBuilder
    private var searchBarView: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            
            TextField("Search \(selectedTab.rawValue.lowercased())...", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !searchText.isEmpty {
                Button("Clear") {
                    searchText = ""
                }
                .font(.caption)
                .foregroundStyle(.blue)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Events View
    
    @ViewBuilder
    private var eventsView: some View {
        List {
            ForEach(filteredEvents) { event in
                EventRowView(event: event)
            }
        }
        .listStyle(PlainListStyle())
        .refreshable {
            // Refresh events
        }
    }
    
    // MARK: - Errors View
    
    @ViewBuilder
    private var errorsView: some View {
        List {
            ForEach(filteredErrors) { error in
                ErrorRowView(error: error)
            }
        }
        .listStyle(PlainListStyle())
        .refreshable {
            // Refresh errors
        }
    }
    
    // MARK: - Metrics View
    
    @ViewBuilder
    private var metricsView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // System metrics cards
                systemMetricsCards
                
                // Event type distribution
                eventTypeDistributionCard
                
                // Timeline chart placeholder
                timelineChartCard
            }
            .padding()
        }
    }
    
    // MARK: - Alerts View
    
    @ViewBuilder
    private var alertsView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Alert summary
                alertSummaryCard
                
                // Recent critical events
                criticalEventsCard
                
                // Performance alerts
                performanceAlertsCard
            }
            .padding()
        }
    }
    
    // MARK: - System Metrics Cards
    
    @ViewBuilder
    private var systemMetricsCards: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            MetricCard(
                title: "Memory Usage",
                value: "\(eventQAService.systemMetrics.memoryUsageMB) MB",
                icon: "memorychip",
                color: .blue
            )
            
            MetricCard(
                title: "CPU Usage",
                value: String(format: "%.1f%%", eventQAService.systemMetrics.cpuUsagePercent),
                icon: "cpu",
                color: .orange
            )
            
            MetricCard(
                title: "Active Events",
                value: "\(eventQAService.systemMetrics.activeEvents)",
                icon: "list.bullet",
                color: .green
            )
            
            MetricCard(
                title: "Error Count",
                value: "\(eventQAService.systemMetrics.errorCount)",
                icon: "exclamationmark.triangle",
                color: .red
            )
        }
    }
    
    // MARK: - Event Type Distribution Card
    
    @ViewBuilder
    private var eventTypeDistributionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Event Type Distribution")
                .font(.headline)
            
            let eventTypeCounts = Dictionary(grouping: eventQAService.eventHistory, by: { $0.type })
                .mapValues { $0.count }
            
            ForEach(EventType.allCases, id: \.self) { type in
                let count = eventTypeCounts[type] ?? 0
                HStack {
                    Circle()
                        .fill(colorForEventType(type))
                        .frame(width: 8, height: 8)
                    
                    Text(type.rawValue.capitalized)
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Text("\(count)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Timeline Chart Card
    
    @ViewBuilder
    private var timelineChartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Event Timeline")
                .font(.headline)
            
            // Placeholder for chart
            RoundedRectangle(cornerRadius: 8)
                .fill(.ultraThinMaterial)
                .frame(height: 120)
                .overlay(
                    Text("Event Timeline Chart\n(Chart implementation pending)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                )
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Alert Summary Card
    
    @ViewBuilder
    private var alertSummaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Alert Summary")
                    .font(.headline)
                
                Spacer()
                
                if eventQAService.alertSummary.hasCriticalIssues {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                }
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                AlertMetricCard(
                    title: "Critical",
                    count: eventQAService.alertSummary.criticalErrors,
                    color: .red
                )
                
                AlertMetricCard(
                    title: "High",
                    count: eventQAService.alertSummary.highErrors,
                    color: .orange
                )
                
                AlertMetricCard(
                    title: "Medium",
                    count: eventQAService.alertSummary.mediumErrors,
                    color: .yellow
                )
                
                AlertMetricCard(
                    title: "Low",
                    count: eventQAService.alertSummary.lowErrors,
                    color: .blue
                )
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Critical Events Card
    
    @ViewBuilder
    private var criticalEventsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Critical Events")
                .font(.headline)
            
            let criticalErrors = eventQAService.errorHistory
                .filter { $0.severity == .critical || $0.severity == .high }
                .prefix(5)
            
            if criticalErrors.isEmpty {
                Text("No critical events")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(Array(criticalErrors), id: \.id) { error in
                    CriticalEventRow(error: error)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Performance Alerts Card
    
    @ViewBuilder
    private var performanceAlertsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Performance Alerts")
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Performance Issues")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(eventQAService.alertSummary.performanceAlerts)")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("CloudKit Issues")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(eventQAService.alertSummary.cloudKitAlerts)")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Helper Views
    
    @ViewBuilder
    private func MetricCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    @ViewBuilder
    private func AlertMetricCard(title: String, count: Int, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(color)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
    }
    
    // MARK: - Helper Properties
    
    private var filteredEvents: [EventEntry] {
        let events = eventQAService.eventHistory
        if searchText.isEmpty {
            return events
        }
        return events.filter { event in
            event.category.localizedCaseInsensitiveContains(searchText) ||
            event.action.localizedCaseInsensitiveContains(searchText) ||
            event.details.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    private var filteredErrors: [ErrorEntry] {
        let errors = eventQAService.errorHistory
        if searchText.isEmpty {
            return errors
        }
        return errors.filter { error in
            error.category.localizedCaseInsensitiveContains(searchText) ||
            error.message.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    private func tabBadgeCount(for tab: ConsoleTab) -> Int? {
        switch tab {
        case .events:
            return eventQAService.eventHistory.count > 0 ? eventQAService.eventHistory.count : nil
        case .errors:
            return eventQAService.errorHistory.count > 0 ? eventQAService.errorHistory.count : nil
        case .metrics:
            return nil
        case .alerts:
            let total = eventQAService.alertSummary.totalErrors
            return total > 0 ? total : nil
        }
    }
    
    private func badgeColor(for tab: ConsoleTab) -> Color {
        switch tab {
        case .events:
            return .blue
        case .errors:
            return .red
        case .metrics:
            return .green
        case .alerts:
            return eventQAService.alertSummary.hasCriticalIssues ? .red : .orange
        }
    }
    
    private func colorForEventType(_ type: EventType) -> Color {
        switch type {
        case .system:
            return .blue
        case .user:
            return .green
        case .cloudkit:
            return .purple
        case .performance:
            return .orange
        case .error:
            return .red
        case .security:
            return .pink
        case .analytics:
            return .teal
        case .metrics:
            return .indigo
        }
    }
    
    // MARK: - Actions
    
    private func toggleMonitoring() {
        if eventQAService.isMonitoring {
            eventQAService.stopMonitoring()
        } else {
            eventQAService.startMonitoring()
        }
    }
    
    private func clearHistory() {
        eventQAService.clearHistory()
    }
    
    private func exportLog() {
        isExporting = true
        let logContent = eventQAService.exportEventLog()
        UIPasteboard.general.string = logContent
        isExporting = false
        showingAlert = true
    }
}

// MARK: - Supporting Views

struct EventRowView: View {
    let event: EventEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Circle()
                    .fill(colorForEventType(event.type))
                    .frame(width: 8, height: 8)
                
                Text(event.category)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text(event.timestamp.formatted(.relative(presentation: .named)))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Text(event.action)
                .font(.subheadline)
                .fontWeight(.medium)
            
            if !event.details.isEmpty {
                Text(event.details)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func colorForEventType(_ type: EventType) -> Color {
        switch type {
        case .system: return .blue
        case .user: return .green
        case .cloudkit: return .purple
        case .performance: return .orange
        case .error: return .red
        case .security: return .pink
        case .analytics: return .teal
        case .metrics: return .indigo
        }
    }
}

struct ErrorRowView: View {
    let error: ErrorEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: iconForSeverity(error.severity))
                    .foregroundStyle(colorForSeverity(error.severity))
                
                Text(error.category)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text(error.timestamp.formatted(.relative(presentation: .named)))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Text(error.message)
                .font(.subheadline)
                .fontWeight(.medium)
            
            if let errorDescription = error.errorDescription {
                Text(errorDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func iconForSeverity(_ severity: ErrorSeverity) -> String {
        switch severity {
        case .low: return "info.circle"
        case .medium: return "exclamationmark.triangle"
        case .high: return "exclamationmark.triangle.fill"
        case .critical: return "xmark.octagon.fill"
        }
    }
    
    private func colorForSeverity(_ severity: ErrorSeverity) -> Color {
        switch severity {
        case .low: return .blue
        case .medium: return .yellow
        case .high: return .orange
        case .critical: return .red
        }
    }
}

struct CriticalEventRow: View {
    let error: ErrorEntry
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(error.message)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text(error.timestamp.formatted(.relative(presentation: .named)))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    EventQAConsoleView()
}
