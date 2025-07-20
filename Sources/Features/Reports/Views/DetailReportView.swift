//
//  DetailReportView.swift
//  DiamondDeskERP
//
//  Created by AI Assistant on 7/20/25.
//  Copyright © 2025 Diamond Desk. All rights reserved.
//

import SwiftUI

/// Enterprise reporting dashboard for message reads and task completions
/// Provides Store Ops-Center style breakdowns by region, store, and user
struct DetailReportView: View {
    
    // MARK: - Properties
    
    @StateObject private var trackingService = AcknowledgmentTrackingService()
    @State private var selectedDateRange: DateRange = .last7Days
    @State private var selectedStoreCode: String?
    @State private var reportData: AcknowledgmentReport?
    @State private var isLoading = false
    @State private var showingExportSheet = false
    @State private var exportFormat: ExportFormat = .csv
    
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    // MARK: - Enums
    
    enum DateRange: String, CaseIterable {
        case today = "Today"
        case last7Days = "Last 7 Days"
        case last30Days = "Last 30 Days"
        case thisMonth = "This Month"
        case custom = "Custom Range"
        
        var dateRange: ClosedRange<Date> {
            let calendar = Calendar.current
            let now = Date()
            
            switch self {
            case .today:
                return calendar.startOfDay(for: now)...now
            case .last7Days:
                return calendar.date(byAdding: .day, value: -7, to: now)!...now
            case .last30Days:
                return calendar.date(byAdding: .day, value: -30, to: now)!...now
            case .thisMonth:
                let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
                return startOfMonth...now
            case .custom:
                return now...now // Will be overridden by custom picker
            }
        }
    }
    
    enum ExportFormat: String, CaseIterable {
        case csv = "CSV"
        case json = "JSON"
        
        var fileExtension: String {
            switch self {
            case .csv: return "csv"
            case .json: return "json"
            }
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        SimpleAdaptiveNavigationView(path: .constant(NavigationPath())) {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Filter Controls
                    filterControlsSection
                    
                    // Summary Cards
                    if let reportData = reportData {
                        summaryCardsSection(reportData: reportData)
                    }
                    
                    // Detailed Breakdowns
                    if let reportData = reportData {
                        detailedBreakdownsSection(reportData: reportData)
                    }
                    
                    // Export Section
                    exportSection
                }
                .padding()
            }
            .navigationTitle("Acknowledgment Reports")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Export") {
                        showingExportSheet = true
                    }
                    .disabled(reportData == nil)
                }
            }
            .sheet(isPresented: $showingExportSheet) {
                ExportOptionsSheet(
                    readLogs: reportData?.messageReadLogs ?? [],
                    completionLogs: reportData?.taskCompletionLogs ?? []
                )
            }
            .task {
                await loadReportData()
            }
            .overlay {
                if isLoading {
                    LoadingOverlay()
                }
            }
        }
    }
    
    // MARK: - Filter Controls Section
    
    private var filterControlsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Report Filters")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            VStack(spacing: 12) {
                // Date Range Picker
                Picker("Date Range", selection: $selectedDateRange) {
                    ForEach(DateRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: selectedDateRange) { _ in
                    Task { await loadReportData() }
                }
                
                // Store Filter (Optional)
                HStack {
                    Text("Store:")
                        .font(.body)
                        .fontWeight(.medium)
                    
                    Picker("Store", selection: $selectedStoreCode) {
                        Text("All Stores").tag(String?.none)
                        // Would populate with actual store codes
                        Text("Store 01").tag(String?.some("01"))
                        Text("Store 02").tag(String?.some("02"))
                        Text("Store 08").tag(String?.some("08"))
                    }
                    .pickerStyle(.menu)
                    .onChange(of: selectedStoreCode) { _ in
                        Task { await loadReportData() }
                    }
                    
                    Spacer()
                }
            }
        }
        .padding()
        .background(liquidGlassBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Summary Cards Section
    
    private func summaryCardsSection(reportData: AcknowledgmentReport) -> some View {
        VStack(spacing: 16) {
            HStack {
                Text("Summary")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                SummaryCard(
                    title: "Messages Tracked",
                    value: "\(reportData.totalMessagesTracked)",
                    icon: "envelope.circle.fill",
                    color: .blue
                )
                
                SummaryCard(
                    title: "Tasks Tracked", 
                    value: "\(reportData.totalTasksTracked)",
                    icon: "checklist.circle.fill",
                    color: .green
                )
                
                SummaryCard(
                    title: "Active Users",
                    value: "\(reportData.uniqueUsersInvolved)",
                    icon: "person.2.circle.fill",
                    color: .orange
                )
                
                SummaryCard(
                    title: "Stores Reporting",
                    value: "\(Set(reportData.messageReadLogs.map(\.storeCode)).count)",
                    icon: "building.2.circle.fill",
                    color: .purple
                )
            }
        }
        .padding()
        .background(liquidGlassBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Detailed Breakdowns Section
    
    private func detailedBreakdownsSection(reportData: AcknowledgmentReport) -> some View {
        VStack(spacing: 20) {
            // Message Read Breakdown
            MessageReadBreakdownView(readLogs: reportData.messageReadLogs)
            
            // Task Completion Breakdown
            TaskCompletionBreakdownView(completionLogs: reportData.taskCompletionLogs)
        }
    }
    
    // MARK: - Export Section
    
    private var exportSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Export Options")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            HStack {
                Picker("Format", selection: $exportFormat) {
                    ForEach(ExportFormat.allCases, id: \.self) { format in
                        Text(format.rawValue).tag(format)
                    }
                }
                .pickerStyle(.segmented)
                
                Spacer()
                
                Button("Export Report") {
                    showingExportSheet = true
                }
                .buttonStyle(.borderedProminent)
                .disabled(reportData == nil)
            }
        }
        .padding()
        .background(liquidGlassBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Computed Properties
    
    private var liquidGlassBackground: some ShapeStyle {
        if colorScheme == .dark {
            return AnyShapeStyle(.regularMaterial)
        } else {
            return AnyShapeStyle(.thickMaterial)
        }
    }
    
    // MARK: - Actions
    
    private func loadReportData() async {
        isLoading = true
        
        do {
            let report = try await trackingService.generateAcknowledgmentReport(
                for: selectedDateRange.dateRange,
                storeCode: selectedStoreCode
            )
            
            await MainActor.run {
                reportData = report
                isLoading = false
            }
        } catch {
            await MainActor.run {
                trackingService.errorMessage = "Failed to load report: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
}

// MARK: - Summary Card

struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                
                Spacer()
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(value)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text(title)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(colorScheme == .dark ? 0.15 : 0.1))
        )
    }
}

// MARK: - Loading Overlay

struct LoadingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.2)
                
                Text("Loading Report...")
                    .foregroundColor(.white)
                    .font(.headline)
            }
            .padding(24)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}

// MARK: - Preview

#Preview {
    DetailReportView()
}
