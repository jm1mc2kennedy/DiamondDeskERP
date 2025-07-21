//
//  AIInsightsListView.swift
//  DiamondDeskERP
//
//  Created by AI Assistant on 7/20/25.
//  Copyright © 2025 Diamond Desk. All rights reserved.
//

import SwiftUI

/// Main view for displaying AI insights with filtering and interaction capabilities
struct AIInsightsListView: View {
    @StateObject private var viewModel = AIInsightsViewModel()
    @State private var showingFilterSheet = false
    @State private var selectedInsight: AIInsight?
    @State private var navigationPath = NavigationPath()
    
    var body: some View {
        SimpleAdaptiveNavigationView(path: $navigationPath) {
            VStack(spacing: 0) {
                // Quick Filters
                quickFiltersSection
                
                // Insights List
                insightsListSection
            }
            .navigationTitle("AI Insights")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    refreshButton
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        filterButton
                        generateButton
                    }
                }
            }
            .sheet(isPresented: $showingFilterSheet) {
                AIInsightsFilterView(viewModel: viewModel)
            }
            .sheet(item: $selectedInsight) { insight in
                AIInsightDetailView(insight: insight, viewModel: viewModel)
            }
            .alert("Error", isPresented: $viewModel.showingError) {
                Button("OK") { }
            } message: {
                Text(viewModel.error ?? "An unknown error occurred")
            }
            .task {
                await viewModel.loadInsights()
            }
        }
    }
    
    // MARK: - Quick Filters Section
    
    private var quickFiltersSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(QuickFilter.allCases, id: \.self) { filter in
                    quickFilterButton(filter)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color(.systemGroupedBackground))
    }
    
    private func quickFilterButton(_ filter: QuickFilter) -> some View {
        Button {
            viewModel.applyQuickFilter(filter)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: filter.icon)
                    .font(.caption)
                Text(filter.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(filter.color.opacity(0.1))
            .foregroundColor(filter.color)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(filter.color.opacity(0.3), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Insights List Section
    
    private var insightsListSection: some View {
        Group {
            if viewModel.isLoading {
                loadingView
            } else if viewModel.filteredInsights.isEmpty {
                emptyStateView
            } else {
                insightsList
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading AI Insights...")
                .foregroundColor(.secondary)
                .font(.subheadline)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("No Insights Available")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(viewModel.hasActiveFilters ? 
                     "No insights match your current filters" : 
                     "Generate insights to see AI recommendations")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            if viewModel.hasActiveFilters {
                Button("Clear Filters") {
                    viewModel.clearFilters()
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button("Generate Insights") {
                    Task {
                        await viewModel.generateInsights()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isGenerating)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
    
    private var insightsList: some View {
        List {
            // Critical Insights Section
            if !viewModel.criticalInsights.isEmpty {
                Section {
                    ForEach(viewModel.criticalInsights) { insight in
                        AIInsightRowView(insight: insight) {
                            selectedInsight = insight
                        }
                    }
                } header: {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text("Critical")
                            .fontWeight(.semibold)
                    }
                }
            }
            
            // Actionable Insights Section
            if !viewModel.actionableInsights.isEmpty {
                Section {
                    ForEach(viewModel.actionableInsights.filter { $0.priority != .critical }) { insight in
                        AIInsightRowView(insight: insight) {
                            selectedInsight = insight
                        }
                    }
                } header: {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Actionable")
                            .fontWeight(.semibold)
                    }
                }
            }
            
            // All Other Insights
            let otherInsights = viewModel.filteredInsights.filter { insight in
                insight.priority != .critical && 
                (insight.actionRecommendations.isEmpty || insight.isActionTaken)
            }
            
            if !otherInsights.isEmpty {
                Section("Other Insights") {
                    ForEach(otherInsights) { insight in
                        AIInsightRowView(insight: insight) {
                            selectedInsight = insight
                        }
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .refreshable {
            await viewModel.loadInsights()
        }
    }
    
    // MARK: - Toolbar Buttons
    
    private var refreshButton: some View {
        Button {
            Task {
                await viewModel.loadInsights()
            }
        } label: {
            Image(systemName: "arrow.clockwise")
        }
        .disabled(viewModel.isLoading)
    }
    
    private var filterButton: some View {
        Button {
            showingFilterSheet = true
        } label: {
            Image(systemName: viewModel.hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                .foregroundColor(viewModel.hasActiveFilters ? .accentColor : .primary)
        }
    }
    
    private var generateButton: some View {
        Button {
            Task {
                await viewModel.generateInsights()
            }
        } label: {
            if viewModel.isGenerating {
                ProgressView()
                    .scaleEffect(0.8)
            } else {
                Image(systemName: "brain.head.profile")
            }
        }
        .disabled(viewModel.isGenerating || viewModel.isLoading)
    }
}

// MARK: - Individual Insight Row

struct AIInsightRowView: View {
    let insight: AIInsight
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // Header
                HStack {
                    // Priority indicator
                    priorityIndicator
                    
                    // Type and category
                    VStack(alignment: .leading, spacing: 2) {
                        Text(insight.type.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        Text(insight.category.displayName)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Confidence score
                    confidenceIndicator
                    
                    // Action status
                    if insight.isActionTaken {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                    } else if !insight.actionRecommendations.isEmpty {
                        Image(systemName: "arrow.right.circle")
                            .foregroundColor(.blue)
                            .font(.caption)
                    }
                }
                
                // Title and description
                VStack(alignment: .leading, spacing: 4) {
                    Text(insight.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.leading)
                    
                    Text(insight.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                
                // Action recommendations preview
                if !insight.actionRecommendations.isEmpty && !insight.isActionTaken {
                    HStack {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.yellow)
                            .font(.caption2)
                        
                        Text("\(insight.actionRecommendations.count) recommendation\(insight.actionRecommendations.count == 1 ? "" : "s")")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Footer
                HStack {
                    // Tags
                    if !insight.tags.isEmpty {
                        HStack(spacing: 4) {
                            ForEach(insight.tags.prefix(3), id: \.self) { tag in
                                Text(tag)
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color(.systemGray5))
                                    .foregroundColor(.secondary)
                                    .clipShape(Capsule())
                            }
                            
                            if insight.tags.count > 3 {
                                Text("+\(insight.tags.count - 3)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Time ago
                    Text(insight.createdAt.timeAgoDisplay)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var priorityIndicator: some View {
        Circle()
            .fill(insight.priority.color)
            .frame(width: 8, height: 8)
    }
    
    private var confidenceIndicator: some View {
        HStack(spacing: 2) {
            Text("\(Int(insight.confidence * 100))%")
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            Circle()
                .fill(confidenceColor)
                .frame(width: 6, height: 6)
        }
    }
    
    private var confidenceColor: Color {
        if insight.confidence >= 0.8 { return .green }
        else if insight.confidence >= 0.6 { return .yellow }
        else { return .orange }
    }
}

// MARK: - Extensions

extension InsightType {
    var displayName: String {
        switch self {
        case .documentRecommendation: return "Document"
        case .taskOptimization: return "Task"
        case .performancePrediction: return "Performance"
        case .riskAssessment: return "Risk"
        case .resourceOptimization: return "Resource"
        case .clientEngagement: return "Client"
        case .auditScheduling: return "Audit"
        case .trainingRecommendation: return "Training"
        case .workflowImprovement: return "Workflow"
        case .complianceAlert: return "Compliance"
        }
    }
}

extension InsightCategory {
    var displayName: String {
        switch self {
        case .productivity: return "Productivity"
        case .compliance: return "Compliance"
        case .performance: return "Performance"
        case .risk: return "Risk"
        case .engagement: return "Engagement"
        case .optimization: return "Optimization"
        case .prediction: return "Prediction"
        case .recommendation: return "Recommendation"
        }
    }
}

extension InsightPriority {
    var color: Color {
        switch self {
        case .critical: return .red
        case .high: return .orange
        case .medium: return .yellow
        case .low: return .blue
        case .informational: return .gray
        }
    }
}

extension Date {
    var timeAgoDisplay: String {
        let now = Date()
        let components = Calendar.current.dateComponents([.minute, .hour, .day], from: self, to: now)
        
        if let days = components.day, days > 0 {
            return "\(days)d ago"
        } else if let hours = components.hour, hours > 0 {
            return "\(hours)h ago"
        } else if let minutes = components.minute, minutes > 0 {
            return "\(minutes)m ago"
        } else {
            return "Just now"
        }
    }
}

// MARK: - Preview

struct AIInsightsListView_Previews: PreviewProvider {
    static var previews: some View {
        AIInsightsListView()
    }
}

