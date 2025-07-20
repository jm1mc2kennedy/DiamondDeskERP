//
//  AIInsightsAnalyticsView.swift
//  DiamondDeskERP
//
//  Created by J.Michael McDermott on 7/20/25.
//

import SwiftUI
import Charts

/// Comprehensive analytics view for AI insights system
/// Displays usage metrics, effectiveness data, and performance analytics
struct AIInsightsAnalyticsView: View {
    
    // MARK: - Properties
    
    @StateObject private var viewModel = AIInsightsViewModel()
    @State private var selectedTimeRange: TimeRange = .last30Days
    @State private var selectedMetric: AnalyticsMetric = .engagement
    
    // MARK: - Enums
    
    enum TimeRange: String, CaseIterable {
        case last7Days = "Last 7 Days"
        case last30Days = "Last 30 Days"
        case last90Days = "Last 90 Days"
        case lastYear = "Last Year"
        
        var days: Int {
            switch self {
            case .last7Days: return 7
            case .last30Days: return 30
            case .last90Days: return 90
            case .lastYear: return 365
            }
        }
    }
    
    enum AnalyticsMetric: String, CaseIterable {
        case engagement = "User Engagement"
        case effectiveness = "Insight Effectiveness"
        case generation = "Generation Performance"
        case feedback = "User Feedback"
    }
    
    // MARK: - View Body
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Analytics Controls
                    analyticsControls
                    
                    // Key Metrics Cards
                    keyMetricsSection
                    
                    // Charts Section
                    chartsSection
                    
                    // Detailed Analytics
                    detailedAnalyticsSection
                    
                    // Insights Breakdown
                    insightsBreakdownSection
                }
                .padding()
            }
            .navigationTitle("AI Insights Analytics")
            .navigationBarTitleDisplayMode(.large)
            .background(Color(.systemGroupedBackground))
            .task {
                await viewModel.loadAnalytics()
            }
        }
    }
    
    // MARK: - Analytics Controls
    
    private var analyticsControls: some View {
        VStack(spacing: 16) {
            // Time Range Picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Time Range")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Picker("Time Range", selection: $selectedTimeRange) {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            // Metric Picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Focus Metric")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Picker("Metric", selection: $selectedMetric) {
                    ForEach(AnalyticsMetric.allCases, id: \.self) { metric in
                        Text(metric.rawValue).tag(metric)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Key Metrics Section
    
    private var keyMetricsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Key Metrics")
                .font(.title2)
                .fontWeight(.bold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                MetricCard(
                    title: "Total Insights",
                    value: "\(viewModel.insights.count)",
                    icon: "lightbulb.fill",
                    color: .blue
                )
                
                MetricCard(
                    title: "Actions Taken",
                    value: "\(calculateActionsTaken())",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
                
                MetricCard(
                    title: "Avg. Rating",
                    value: String(format: "%.1f", calculateAverageRating()),
                    icon: "star.fill",
                    color: .orange
                )
                
                MetricCard(
                    title: "Engagement",
                    value: "\(Int(calculateEngagementRate() * 100))%",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .purple
                )
            }
        }
    }
    
    // MARK: - Charts Section
    
    private var chartsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Trends")
                .font(.title2)
                .fontWeight(.bold)
            
            // Engagement Chart
            if #available(iOS 16.0, *) {
                engagementChart
            } else {
                Text("Charts require iOS 16+")
                    .foregroundColor(.secondary)
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            }
            
            // Insight Type Distribution
            insightTypeChart
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    @available(iOS 16.0, *)
    private var engagementChart: some View {
        Chart {
            ForEach(generateEngagementData(), id: \.day) { data in
                LineMark(
                    x: .value("Day", data.day),
                    y: .value("Engagement", data.engagement)
                )
                .foregroundStyle(.blue)
                .interpolationMethod(.catmullRom)
            }
        }
        .frame(height: 200)
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 5))
        }
        .chartYAxis {
            AxisMarks(values: .automatic(desiredCount: 4))
        }
        .overlay(
            VStack {
                HStack {
                    Text("Daily Engagement")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                }
                Spacer()
            }
            .padding()
        )
    }
    
    private var insightTypeChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Insight Types Distribution")
                .font(.headline)
            
            let typeData = calculateInsightTypeDistribution()
            
            ForEach(typeData, id: \.type) { data in
                HStack {
                    Circle()
                        .fill(colorForInsightType(data.type))
                        .frame(width: 12, height: 12)
                    
                    Text(data.type.displayName)
                        .font(.body)
                    
                    Spacer()
                    
                    Text("\(data.count)")
                        .font(.body)
                        .fontWeight(.semibold)
                    
                    Text("(\(Int(data.percentage))%)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    // MARK: - Detailed Analytics Section
    
    private var detailedAnalyticsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Performance Details")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 12) {
                PerformanceRow(
                    title: "Most Effective Insight Type",
                    value: getMostEffectiveInsightType(),
                    icon: "trophy.fill",
                    color: .gold
                )
                
                PerformanceRow(
                    title: "Average Response Time",
                    value: String(format: "%.1fs", calculateAverageResponseTime()),
                    icon: "clock.fill",
                    color: .blue
                )
                
                PerformanceRow(
                    title: "Success Rate",
                    value: "\(Int(calculateSuccessRate() * 100))%",
                    icon: "checkmark.seal.fill",
                    color: .green
                )
                
                PerformanceRow(
                    title: "User Satisfaction",
                    value: String(format: "%.1f/5.0", calculateUserSatisfaction()),
                    icon: "heart.fill",
                    color: .red
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Insights Breakdown Section
    
    private var insightsBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Insights Performance")
                .font(.title2)
                .fontWeight(.bold)
            
            LazyVStack(spacing: 12) {
                ForEach(viewModel.insights.prefix(10), id: \.id) { insight in
                    InsightPerformanceRow(insight: insight)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Helper Methods
    
    private func calculateActionsTaken() -> Int {
        return viewModel.insights.reduce(0) { total, insight in
            total + insight.analytics.actionsCount
        }
    }
    
    private func calculateAverageRating() -> Double {
        let insights = viewModel.insights.filter { $0.analytics.averageRating > 0 }
        guard !insights.isEmpty else { return 0.0 }
        
        let totalRating = insights.reduce(0.0) { total, insight in
            total + insight.analytics.averageRating
        }
        
        return totalRating / Double(insights.count)
    }
    
    private func calculateEngagementRate() -> Double {
        guard !viewModel.insights.isEmpty else { return 0.0 }
        
        let engagedInsights = viewModel.insights.filter { $0.analytics.viewsCount > 0 }
        return Double(engagedInsights.count) / Double(viewModel.insights.count)
    }
    
    private func generateEngagementData() -> [EngagementData] {
        let days = selectedTimeRange.days
        var data: [EngagementData] = []
        
        for i in 0..<days {
            let day = Calendar.current.date(byAdding: .day, value: -i, to: Date()) ?? Date()
            let engagement = Double.random(in: 0.2...1.0) // Mock data
            data.append(EngagementData(day: day, engagement: engagement))
        }
        
        return data.reversed()
    }
    
    private func calculateInsightTypeDistribution() -> [InsightTypeData] {
        let total = viewModel.insights.count
        guard total > 0 else { return [] }
        
        let grouped = Dictionary(grouping: viewModel.insights, by: { $0.type })
        
        return grouped.map { type, insights in
            InsightTypeData(
                type: type,
                count: insights.count,
                percentage: Double(insights.count) / Double(total) * 100
            )
        }.sorted { $0.count > $1.count }
    }
    
    private func colorForInsightType(_ type: InsightType) -> Color {
        switch type {
        case .documentRecommendation: return .blue
        case .performancePrediction: return .green
        case .riskAssessment: return .red
        case .taskOptimization: return .orange
        case .workflowSuggestion: return .purple
        case .resourceAllocation: return .teal
        case .complianceAlert: return .yellow
        case .efficiencyImprovement: return .pink
        }
    }
    
    private func getMostEffectiveInsightType() -> String {
        let typeData = calculateInsightTypeDistribution()
        guard let mostEffective = typeData.max(by: { $0.count < $1.count }) else {
            return "N/A"
        }
        return mostEffective.type.displayName
    }
    
    private func calculateAverageResponseTime() -> Double {
        let responseTimes = viewModel.insights.map { insight in
            insight.metadata.confidence // Using confidence as mock response time
        }
        
        guard !responseTimes.isEmpty else { return 0.0 }
        return responseTimes.reduce(0, +) / Double(responseTimes.count)
    }
    
    private func calculateSuccessRate() -> Double {
        let successfulInsights = viewModel.insights.filter { $0.analytics.actionsCount > 0 }
        guard !viewModel.insights.isEmpty else { return 0.0 }
        
        return Double(successfulInsights.count) / Double(viewModel.insights.count)
    }
    
    private func calculateUserSatisfaction() -> Double {
        return calculateAverageRating()
    }
}

// MARK: - Supporting Views

struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                
                Spacer()
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct PerformanceRow: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)
                .frame(width: 24)
            
            Text(title)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(value)
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
        .padding(.vertical, 8)
    }
}

struct InsightPerformanceRow: View {
    let insight: AIInsight
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(insight.title)
                    .font(.headline)
                    .lineLimit(1)
                
                Spacer()
                
                Text("\(insight.analytics.viewsCount) views")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                    
                    Text(String(format: "%.1f", insight.analytics.averageRating))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text("\(insight.analytics.actionsCount) actions")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - Data Models

struct EngagementData {
    let day: Date
    let engagement: Double
}

struct InsightTypeData {
    let type: InsightType
    let count: Int
    let percentage: Double
}

// MARK: - Color Extension

extension Color {
    static let gold = Color(red: 1.0, green: 0.84, blue: 0.0)
}

// MARK: - Preview

#Preview {
    AIInsightsAnalyticsView()
}
