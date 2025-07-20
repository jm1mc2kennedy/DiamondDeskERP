//
//  AIInsightsViewModel.swift
//  DiamondDeskERP
//
//  Created by AI Assistant on 7/20/25.
//  Copyright © 2025 Diamond Desk. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

/// ViewModel for managing AI insights UI state and operations
@MainActor
final class AIInsightsViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var insights: [AIInsight] = []
    @Published var filteredInsights: [AIInsight] = []
    @Published var predictions: [PerformancePrediction] = []
    @Published var analytics: InsightAnalytics?
    
    @Published var isLoading = false
    @Published var isGenerating = false
    @Published var error: String?
    @Published var showingError = false
    
    // Filter states
    @Published var selectedTypes: Set<InsightType> = []
    @Published var selectedPriorities: Set<InsightPriority> = []
    @Published var selectedCategories: Set<InsightCategory> = []
    @Published var searchText = ""
    @Published var showOnlyActionable = false
    
    // UI states
    @Published var selectedInsight: AIInsight?
    @Published var showingInsightDetail = false
    @Published var showingFilters = false
    @Published var showingAnalytics = false
    @Published var showingFeedbackSheet = false
    
    // MARK: - Private Properties
    
    private let aiInsightsService: AIInsightsService
    private let repository: AIInsightsRepository
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(aiInsightsService: AIInsightsService = AIInsightsService(), 
         repository: AIInsightsRepository = AIInsightsRepository()) {
        self.aiInsightsService = aiInsightsService
        self.repository = repository
        
        setupBindings()
        setupFiltering()
    }
    
    // MARK: - Public Interface
    
    /// Load insights from service
    func loadInsights() async {
        isLoading = true
        error = nil
        
        do {
            await aiInsightsService.loadInsights()
            insights = aiInsightsService.insights
            predictions = aiInsightsService.predictions
            
            // Generate analytics for the last 30 days
            let period = DateInterval(
                start: Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date(),
                end: Date()
            )
            await aiInsightsService.generateAnalytics(period: period)
            analytics = aiInsightsService.analytics
            
        } catch {
            self.error = error.localizedDescription
            showingError = true
        }
        
        isLoading = false
    }
    
    /// Generate new insights
    func generateInsights() async {
        isGenerating = true
        error = nil
        
        do {
            await aiInsightsService.generateInsights()
            insights = aiInsightsService.insights
            predictions = aiInsightsService.predictions
            
        } catch {
            self.error = error.localizedDescription
            showingError = true
        }
        
        isGenerating = false
    }
    
    /// Mark insight action as taken
    func markActionTaken(_ insight: AIInsight, action: ActionRecommendation) async {
        do {
            await aiInsightsService.markActionTaken(insight, action: action)
            await loadInsights() // Refresh data
            
        } catch {
            self.error = error.localizedDescription
            showingError = true
        }
    }
    
    /// Provide feedback on insight
    func provideFeedback(_ insight: AIInsight, rating: Int, isHelpful: Bool, comment: String?) async {
        let feedback = InsightFeedback(
            rating: rating,
            isHelpful: isHelpful,
            comment: comment,
            actionTaken: insight.isActionTaken,
            submittedAt: Date(),
            submittedBy: UserProvisioningService.shared.currentUserId ?? "unknown"
        )
        
        do {
            await aiInsightsService.provideFeedback(insight, feedback: feedback)
            await loadInsights() // Refresh data
            
        } catch {
            self.error = error.localizedDescription
            showingError = true
        }
    }
    
    /// Dismiss an insight
    func dismissInsight(_ insight: AIInsight) async {
        do {
            // Record interaction
            let interaction = InsightInteraction(
                insightId: insight.id,
                userId: UserProvisioningService.shared.currentUserId ?? "unknown",
                interactionType: .dismissed,
                timestamp: Date(),
                durationSeconds: nil,
                metadata: [:]
            )
            
            try await repository.recordInteraction(interaction)
            
            // Remove from local array
            insights.removeAll { $0.id == insight.id }
            
        } catch {
            self.error = error.localizedDescription
            showingError = true
        }
    }
    
    /// Show insight detail
    func showInsightDetail(_ insight: AIInsight) {
        selectedInsight = insight
        showingInsightDetail = true
        
        // Record view interaction
        Task {
            let interaction = InsightInteraction(
                insightId: insight.id,
                userId: UserProvisioningService.shared.currentUserId ?? "unknown",
                interactionType: .viewed,
                timestamp: Date(),
                durationSeconds: nil,
                metadata: [:]
            )
            
            try? await repository.recordInteraction(interaction)
        }
    }
    
    /// Clear all filters
    func clearFilters() {
        selectedTypes.removeAll()
        selectedPriorities.removeAll()
        selectedCategories.removeAll()
        searchText = ""
        showOnlyActionable = false
    }
    
    /// Apply quick filter
    func applyQuickFilter(_ filter: QuickFilter) {
        clearFilters()
        
        switch filter {
        case .highPriority:
            selectedPriorities.insert(.critical)
            selectedPriorities.insert(.high)
        case .actionable:
            showOnlyActionable = true
        case .recommendations:
            selectedTypes.insert(.documentRecommendation)
            selectedTypes.insert(.trainingRecommendation)
        case .predictions:
            selectedTypes.insert(.performancePrediction)
            selectedCategories.insert(.prediction)
        case .risks:
            selectedTypes.insert(.riskAssessment)
            selectedCategories.insert(.risk)
        case .optimizations:
            selectedTypes.insert(.taskOptimization)
            selectedTypes.insert(.resourceOptimization)
            selectedCategories.insert(.optimization)
        }
    }
    
    // MARK: - Computed Properties
    
    var hasActiveFilters: Bool {
        !selectedTypes.isEmpty || 
        !selectedPriorities.isEmpty || 
        !selectedCategories.isEmpty || 
        !searchText.isEmpty || 
        showOnlyActionable
    }
    
    var insightsByPriority: [InsightPriority: [AIInsight]] {
        Dictionary(grouping: filteredInsights) { $0.priority }
    }
    
    var criticalInsights: [AIInsight] {
        filteredInsights.filter { $0.priority == .critical }
    }
    
    var actionableInsights: [AIInsight] {
        filteredInsights.filter { !$0.actionRecommendations.isEmpty && !$0.isActionTaken }
    }
    
    var recentPredictions: [PerformancePrediction] {
        predictions.filter { 
            Calendar.current.dateInterval(of: .day, for: Date())?.contains($0.createdAt) ?? false 
        }
    }
    
    // MARK: - Private Methods
    
    private func setupBindings() {
        // Bind service state
        aiInsightsService.$insights
            .receive(on: DispatchQueue.main)
            .assign(to: \.insights, on: self)
            .store(in: &cancellables)
        
        aiInsightsService.$predictions
            .receive(on: DispatchQueue.main)
            .assign(to: \.predictions, on: self)
            .store(in: &cancellables)
        
        aiInsightsService.$analytics
            .receive(on: DispatchQueue.main)
            .assign(to: \.analytics, on: self)
            .store(in: &cancellables)
        
        aiInsightsService.$isProcessing
            .receive(on: DispatchQueue.main)
            .assign(to: \.isLoading, on: self)
            .store(in: &cancellables)
        
        aiInsightsService.$error
            .receive(on: DispatchQueue.main)
            .map { $0?.localizedDescription }
            .assign(to: \.error, on: self)
            .store(in: &cancellables)
    }
    
    private func setupFiltering() {
        // Combine all filter publishers
        Publishers.CombineLatest4(
            $insights,
            Publishers.CombineLatest3($selectedTypes, $selectedPriorities, $selectedCategories),
            $searchText.debounce(for: .milliseconds(300), scheduler: DispatchQueue.main),
            $showOnlyActionable
        )
        .map { insights, filters, searchText, showOnlyActionable in
            self.filterInsights(
                insights: insights,
                types: filters.0,
                priorities: filters.1,
                categories: filters.2,
                searchText: searchText,
                showOnlyActionable: showOnlyActionable
            )
        }
        .receive(on: DispatchQueue.main)
        .assign(to: \.filteredInsights, on: self)
        .store(in: &cancellables)
    }
    
    private func filterInsights(
        insights: [AIInsight],
        types: Set<InsightType>,
        priorities: Set<InsightPriority>,
        categories: Set<InsightCategory>,
        searchText: String,
        showOnlyActionable: Bool
    ) -> [AIInsight] {
        
        return insights.filter { insight in
            // Type filter
            if !types.isEmpty && !types.contains(insight.type) {
                return false
            }
            
            // Priority filter
            if !priorities.isEmpty && !priorities.contains(insight.priority) {
                return false
            }
            
            // Category filter
            if !categories.isEmpty && !categories.contains(insight.category) {
                return false
            }
            
            // Actionable filter
            if showOnlyActionable && (insight.actionRecommendations.isEmpty || insight.isActionTaken) {
                return false
            }
            
            // Search text filter
            if !searchText.isEmpty {
                let searchLower = searchText.lowercased()
                let titleMatch = insight.title.lowercased().contains(searchLower)
                let descriptionMatch = insight.description.lowercased().contains(searchLower)
                let tagsMatch = insight.tags.contains { $0.lowercased().contains(searchLower) }
                
                if !titleMatch && !descriptionMatch && !tagsMatch {
                    return false
                }
            }
            
            return true
        }
        .sorted { lhs, rhs in
            // Sort by priority first, then by creation date
            if lhs.priority.sortOrder != rhs.priority.sortOrder {
                return lhs.priority.sortOrder < rhs.priority.sortOrder
            }
            return lhs.createdAt > rhs.createdAt
        }
    }
}

// MARK: - Supporting Types

enum QuickFilter: String, CaseIterable {
    case highPriority = "High Priority"
    case actionable = "Actionable"
    case recommendations = "Recommendations"
    case predictions = "Predictions"
    case risks = "Risks"
    case optimizations = "Optimizations"
    
    var icon: String {
        switch self {
        case .highPriority: return "exclamationmark.triangle.fill"
        case .actionable: return "checkmark.circle.fill"
        case .recommendations: return "lightbulb.fill"
        case .predictions: return "chart.line.uptrend.xyaxis"
        case .risks: return "shield.fill"
        case .optimizations: return "speedometer"
        }
    }
    
    var color: Color {
        switch self {
        case .highPriority: return .red
        case .actionable: return .green
        case .recommendations: return .blue
        case .predictions: return .purple
        case .risks: return .orange
        case .optimizations: return .teal
        }
    }
}
