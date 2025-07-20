//
//  AIInsightsFilterView.swift
//  DiamondDeskERP
//
//  Created by AI Assistant on 7/20/25.
//  Copyright © 2025 Diamond Desk. All rights reserved.
//

import SwiftUI

/// Filter view for AI insights with comprehensive filtering options
struct AIInsightsFilterView: View {
    @ObservedObject var viewModel: AIInsightsViewModel
    @State private var navigationPath = NavigationPath()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        SimpleAdaptiveNavigationView(path: $navigationPath) {
            List {
                // Search Section
                searchSection
                
                // Type Filters
                typeFiltersSection
                
                // Priority Filters
                priorityFiltersSection
                
                // Category Filters
                categoryFiltersSection
                
                // Special Filters
                specialFiltersSection
            }
            .navigationTitle("Filter Insights")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Clear All") {
                        viewModel.clearFilters()
                    }
                    .disabled(!viewModel.hasActiveFilters)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Search Section
    
    private var searchSection: some View {
        Section {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search insights...", text: $viewModel.searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !viewModel.searchText.isEmpty {
                    Button {
                        viewModel.searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.vertical, 4)
        } header: {
            Text("Search")
        }
    }
    
    // MARK: - Type Filters Section
    
    private var typeFiltersSection: some View {
        Section {
            ForEach(InsightType.allCases, id: \.self) { type in
                typeFilterRow(type)
            }
        } header: {
            HStack {
                Text("Insight Types")
                Spacer()
                if !viewModel.selectedTypes.isEmpty {
                    Text("\(viewModel.selectedTypes.count) selected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private func typeFilterRow(_ type: InsightType) -> some View {
        HStack {
            Image(systemName: typeIcon(type))
                .foregroundColor(typeColor(type))
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(type.displayName)
                    .font(.subheadline)
                
                Text(typeDescription(type))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if viewModel.selectedTypes.contains(type) {
                Image(systemName: "checkmark")
                    .foregroundColor(.accentColor)
                    .font(.body.weight(.semibold))
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if viewModel.selectedTypes.contains(type) {
                viewModel.selectedTypes.remove(type)
            } else {
                viewModel.selectedTypes.insert(type)
            }
        }
    }
    
    // MARK: - Priority Filters Section
    
    private var priorityFiltersSection: some View {
        Section {
            ForEach(InsightPriority.allCases, id: \.self) { priority in
                priorityFilterRow(priority)
            }
        } header: {
            HStack {
                Text("Priority Levels")
                Spacer()
                if !viewModel.selectedPriorities.isEmpty {
                    Text("\(viewModel.selectedPriorities.count) selected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private func priorityFilterRow(_ priority: InsightPriority) -> some View {
        HStack {
            Circle()
                .fill(priority.color)
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(priority.rawValue.capitalized)
                    .font(.subheadline)
                
                Text(priorityDescription(priority))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if viewModel.selectedPriorities.contains(priority) {
                Image(systemName: "checkmark")
                    .foregroundColor(.accentColor)
                    .font(.body.weight(.semibold))
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if viewModel.selectedPriorities.contains(priority) {
                viewModel.selectedPriorities.remove(priority)
            } else {
                viewModel.selectedPriorities.insert(priority)
            }
        }
    }
    
    // MARK: - Category Filters Section
    
    private var categoryFiltersSection: some View {
        Section {
            ForEach(InsightCategory.allCases, id: \.self) { category in
                categoryFilterRow(category)
            }
        } header: {
            HStack {
                Text("Categories")
                Spacer()
                if !viewModel.selectedCategories.isEmpty {
                    Text("\(viewModel.selectedCategories.count) selected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private func categoryFilterRow(_ category: InsightCategory) -> some View {
        HStack {
            Image(systemName: categoryIcon(category))
                .foregroundColor(categoryColor(category))
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(category.displayName)
                    .font(.subheadline)
                
                Text(categoryDescription(category))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if viewModel.selectedCategories.contains(category) {
                Image(systemName: "checkmark")
                    .foregroundColor(.accentColor)
                    .font(.body.weight(.semibold))
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if viewModel.selectedCategories.contains(category) {
                viewModel.selectedCategories.remove(category)
            } else {
                viewModel.selectedCategories.insert(category)
            }
        }
    }
    
    // MARK: - Special Filters Section
    
    private var specialFiltersSection: some View {
        Section {
            // Show only actionable
            HStack {
                Image(systemName: "bolt.fill")
                    .foregroundColor(.orange)
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Actionable Only")
                        .font(.subheadline)
                    
                    Text("Show only insights with available actions")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Toggle("", isOn: $viewModel.showOnlyActionable)
                    .labelsHidden()
            }
        } header: {
            Text("Special Filters")
        }
    }
    
    // MARK: - Helper Functions
    
    private func typeIcon(_ type: InsightType) -> String {
        switch type {
        case .documentRecommendation: return "doc.text.fill"
        case .taskOptimization: return "checkmark.circle.fill"
        case .performancePrediction: return "chart.line.uptrend.xyaxis"
        case .riskAssessment: return "shield.fill"
        case .resourceOptimization: return "speedometer"
        case .clientEngagement: return "person.2.fill"
        case .auditScheduling: return "calendar.circle.fill"
        case .trainingRecommendation: return "graduationcap.fill"
        case .workflowImprovement: return "arrow.triangle.2.circlepath"
        case .complianceAlert: return "exclamationmark.triangle.fill"
        }
    }
    
    private func typeColor(_ type: InsightType) -> Color {
        switch type {
        case .documentRecommendation: return .blue
        case .taskOptimization: return .green
        case .performancePrediction: return .purple
        case .riskAssessment: return .red
        case .resourceOptimization: return .teal
        case .clientEngagement: return .pink
        case .auditScheduling: return .orange
        case .trainingRecommendation: return .indigo
        case .workflowImprovement: return .cyan
        case .complianceAlert: return .yellow
        }
    }
    
    private func typeDescription(_ type: InsightType) -> String {
        switch type {
        case .documentRecommendation: return "Suggested documents based on your activity"
        case .taskOptimization: return "Ways to improve task efficiency"
        case .performancePrediction: return "Forecasts of performance metrics"
        case .riskAssessment: return "Potential risks and mitigation strategies"
        case .resourceOptimization: return "Resource allocation improvements"
        case .clientEngagement: return "Client relationship recommendations"
        case .auditScheduling: return "Optimal audit timing suggestions"
        case .trainingRecommendation: return "Personalized training suggestions"
        case .workflowImprovement: return "Process enhancement opportunities"
        case .complianceAlert: return "Compliance issues and requirements"
        }
    }
    
    private func priorityDescription(_ priority: InsightPriority) -> String {
        switch priority {
        case .critical: return "Requires immediate attention"
        case .high: return "Important, address soon"
        case .medium: return "Moderate importance"
        case .low: return "Low priority, when convenient"
        case .informational: return "For your information only"
        }
    }
    
    private func categoryIcon(_ category: InsightCategory) -> String {
        switch category {
        case .productivity: return "bolt.fill"
        case .compliance: return "shield.checkerboard"
        case .performance: return "chart.bar.fill"
        case .risk: return "exclamationmark.triangle.fill"
        case .engagement: return "heart.fill"
        case .optimization: return "speedometer"
        case .prediction: return "crystal.ball.fill"
        case .recommendation: return "lightbulb.fill"
        }
    }
    
    private func categoryColor(_ category: InsightCategory) -> Color {
        switch category {
        case .productivity: return .green
        case .compliance: return .blue
        case .performance: return .purple
        case .risk: return .red
        case .engagement: return .pink
        case .optimization: return .teal
        case .prediction: return .indigo
        case .recommendation: return .yellow
        }
    }
    
    private func categoryDescription(_ category: InsightCategory) -> String {
        switch category {
        case .productivity: return "Insights to boost productivity"
        case .compliance: return "Regulatory and policy compliance"
        case .performance: return "Performance-related insights"
        case .risk: return "Risk management and mitigation"
        case .engagement: return "User and client engagement"
        case .optimization: return "Process and resource optimization"
        case .prediction: return "Predictive analytics and forecasts"
        case .recommendation: return "AI-powered recommendations"
        }
    }
}

// MARK: - Preview

struct AIInsightsFilterView_Previews: PreviewProvider {
    static var previews: some View {
        AIInsightsFilterView(viewModel: AIInsightsViewModel())
    }
}
