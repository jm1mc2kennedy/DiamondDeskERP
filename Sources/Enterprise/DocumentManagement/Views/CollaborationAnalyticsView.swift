//
//  CollaborationAnalyticsView.swift
//  DiamondDeskERP
//
//  Created by J.Michael McDermott on 7/20/25.
//

import SwiftUI
import Charts

/// Collaboration Analytics View
/// Provides comprehensive analytics and insights for document collaboration
struct CollaborationAnalyticsView: View {
    
    // MARK: - Properties
    
    let metrics: CollaborationMetrics
    @State private var selectedTimeRange: TimeRange = .lastMonth
    @State private var selectedMetric: AnalyticsMetric = .activeUsers
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            analyticsHeader
            
            // Key Metrics Grid
            keyMetricsGrid
            
            // Chart Section
            chartSection
            
            // Top Collaborators
            topCollaboratorsSection
            
            // Activity Timeline
            activityTimelineSection
        }
    }
    
    // MARK: - Analytics Header
    
    @ViewBuilder
    private var analyticsHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Collaboration Analytics")
                .font(.title2.weight(.bold))
            
            Picker("Time Range", selection: $selectedTimeRange) {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    Text(range.displayName).tag(range)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
    }
    
    // MARK: - Key Metrics Grid
    
    @ViewBuilder
    private var keyMetricsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            AnalyticsMetricCard(
                title: "Total Collaborations",
                value: "\(metrics.totalCollaborations)",
                trend: .positive,
                trendValue: "+12%",
                icon: "person.2.fill",
                color: .blue
            )
            
            AnalyticsMetricCard(
                title: "Active Users",
                value: "\(metrics.activeUsers)",
                trend: .positive,
                trendValue: "+8%",
                icon: "person.badge.clock",
                color: .green
            )
            
            AnalyticsMetricCard(
                title: "Documents Shared",
                value: "\(metrics.documentsShared)",
                trend: .neutral,
                trendValue: "0%",
                icon: "square.and.arrow.up",
                color: .orange
            )
            
            AnalyticsMetricCard(
                title: "Comments Added",
                value: "\(metrics.commentsAdded)",
                trend: .positive,
                trendValue: "+15%",
                icon: "bubble.left.fill",
                color: .purple
            )
        }
    }
    
    // MARK: - Chart Section
    
    @ViewBuilder
    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Activity Trends")
                    .font(.headline.weight(.semibold))
                
                Spacer()
                
                Picker("Metric", selection: $selectedMetric) {
                    ForEach(AnalyticsMetric.allCases, id: \.self) { metric in
                        Text(metric.displayName).tag(metric)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
            
            // Chart
            if #available(iOS 16.0, *) {
                activityChart
                    .frame(height: 200)
            } else {
                // Fallback for older iOS versions
                Text("Charts require iOS 16+")
                    .foregroundColor(.secondary)
                    .frame(height: 200)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    @available(iOS 16.0, *)
    @ViewBuilder
    private var activityChart: some View {
        Chart(metrics.activityTimeline, id: \.date) { point in
            switch selectedMetric {
            case .activeUsers:
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Active Users", point.activeUsers)
                )
                .foregroundStyle(.blue)
                .symbol(Circle())
                
            case .documentsShared:
                BarMark(
                    x: .value("Date", point.date),
                    y: .value("Documents Shared", point.documentsShared)
                )
                .foregroundStyle(.orange)
                
            case .comments:
                AreaMark(
                    x: .value("Date", point.date),
                    y: .value("Comments", point.comments)
                )
                .foregroundStyle(.purple.opacity(0.3))
                .interpolationMethod(.catmullRom)
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { _ in
                AxisGridLine()
                AxisTick()
                AxisValueLabel(format: .dateTime.month().day())
            }
        }
        .chartYAxis {
            AxisMarks { _ in
                AxisGridLine()
                AxisTick()
                AxisValueLabel()
            }
        }
    }
    
    // MARK: - Top Collaborators Section
    
    @ViewBuilder
    private var topCollaboratorsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Top Collaborators")
                .font(.headline.weight(.semibold))
            
            VStack(spacing: 12) {
                ForEach(Array(metrics.topCollaborators.enumerated()), id: \.element.userId) { index, collaborator in
                    TopCollaboratorRow(
                        rank: index + 1,
                        collaborator: collaborator
                    )
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Activity Timeline Section
    
    @ViewBuilder
    private var activityTimelineSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Activity Summary")
                .font(.headline.weight(.semibold))
            
            VStack(spacing: 16) {
                ActivitySummaryRow(
                    title: "Average Session Duration",
                    value: formatDuration(metrics.averageSessionDuration),
                    icon: "clock.fill",
                    color: .blue
                )
                
                ActivitySummaryRow(
                    title: "Peak Activity Time",
                    value: "2:00 PM - 4:00 PM",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .green
                )
                
                ActivitySummaryRow(
                    title: "Most Active Day",
                    value: "Wednesday",
                    icon: "calendar.badge.clock",
                    color: .orange
                )
                
                ActivitySummaryRow(
                    title: "Collaboration Score",
                    value: "85/100",
                    icon: "star.fill",
                    color: .purple
                )
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Helper Methods
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Supporting Views

struct AnalyticsMetricCard: View {
    let title: String
    let value: String
    let trend: TrendDirection
    let trendValue: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: trend.systemImage)
                        .font(.caption)
                    Text(trendValue)
                        .font(.caption.weight(.medium))
                }
                .foregroundColor(trend.color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title.weight(.bold))
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct TopCollaboratorRow: View {
    let rank: Int
    let collaborator: CollaboratorMetric
    
    var body: some View {
        HStack(spacing: 12) {
            // Rank Badge
            ZStack {
                Circle()
                    .fill(rankColor.opacity(0.2))
                    .frame(width: 32, height: 32)
                
                Text("\(rank)")
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(rankColor)
            }
            
            // User Info
            VStack(alignment: .leading, spacing: 2) {
                Text(collaborator.userName)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.primary)
                
                Text("\(collaborator.collaborationCount) collaborations")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Stats
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(collaborator.commentsCount)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)
                
                Text("comments")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var rankColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return .accentColor
        }
    }
}

struct ActivitySummaryRow: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Text(value)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Supporting Types

enum AnalyticsMetric: String, CaseIterable {
    case activeUsers
    case documentsShared
    case comments
    
    var displayName: String {
        switch self {
        case .activeUsers: return "Active Users"
        case .documentsShared: return "Shared Docs"
        case .comments: return "Comments"
        }
    }
}

enum TrendDirection {
    case positive
    case negative
    case neutral
    
    var color: Color {
        switch self {
        case .positive: return .green
        case .negative: return .red
        case .neutral: return .gray
        }
    }
    
    var systemImage: String {
        switch self {
        case .positive: return "arrow.up"
        case .negative: return "arrow.down"
        case .neutral: return "minus"
        }
    }
}

// MARK: - Preview

#Preview {
    CollaborationAnalyticsView(
        metrics: CollaborationMetrics(
            totalCollaborations: 156,
            activeUsers: 24,
            documentsShared: 89,
            commentsAdded: 342,
            averageSessionDuration: 1800, // 30 minutes
            topCollaborators: [
                CollaboratorMetric(
                    userId: "1",
                    userName: "John Doe",
                    collaborationCount: 25,
                    commentsCount: 87,
                    lastActive: Date()
                ),
                CollaboratorMetric(
                    userId: "2",
                    userName: "Jane Smith",
                    collaborationCount: 22,
                    commentsCount: 65,
                    lastActive: Date().addingTimeInterval(-3600)
                ),
                CollaboratorMetric(
                    userId: "3",
                    userName: "Mike Johnson",
                    collaborationCount: 18,
                    commentsCount: 54,
                    lastActive: Date().addingTimeInterval(-7200)
                )
            ],
            activityTimeline: (0..<30).map { day in
                ActivityPoint(
                    date: Calendar.current.date(byAdding: .day, value: -day, to: Date()) ?? Date(),
                    activeUsers: Int.random(in: 5...25),
                    documentsShared: Int.random(in: 0...8),
                    comments: Int.random(in: 2...15)
                )
            }.reversed()
        )
    )
    .padding()
}
