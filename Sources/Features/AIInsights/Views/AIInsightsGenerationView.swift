//
//  AIInsightsGenerationView.swift
//  DiamondDeskERP
//
//  Created by J.Michael McDermott on 7/20/25.
//

import SwiftUI

/// View for generating new AI insights with customizable parameters
/// Allows users to trigger insight generation and configure ML models
struct AIInsightsGenerationView: View {
    
    // MARK: - Properties
    
    @StateObject private var viewModel = AIInsightsViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedGenerationType: GenerationType = .comprehensive
    @State private var selectedScope: GenerationScope = .allData
    @State private var selectedInsightTypes: Set<InsightType> = []
    @State private var selectedPriority: InsightPriority = .medium
    @State private var includeMLPredictions = true
    @State private var includeRiskAssessment = true
    @State private var includeOptimizations = true
    @State private var customPrompt = ""
    @State private var isGenerating = false
    @State private var generationProgress: Double = 0.0
    @State private var showingAdvancedOptions = false
    
    // MARK: - Enums
    
    enum GenerationType: String, CaseIterable {
        case quick = "Quick Insights"
        case comprehensive = "Comprehensive Analysis"
        case targeted = "Targeted Recommendations"
        case predictive = "Predictive Analytics"
        
        var description: String {
            switch self {
            case .quick:
                return "Generate basic insights quickly for immediate use"
            case .comprehensive:
                return "Deep analysis across all data sources with detailed recommendations"
            case .targeted:
                return "Focus on specific areas with customized insight types"
            case .predictive:
                return "Advanced ML predictions and forecasting"
            }
        }
        
        var estimatedTime: String {
            switch self {
            case .quick: return "< 1 minute"
            case .comprehensive: return "3-5 minutes"
            case .targeted: return "1-2 minutes"
            case .predictive: return "2-4 minutes"
            }
        }
    }
    
    enum GenerationScope: String, CaseIterable {
        case allData = "All Data"
        case recent = "Recent Data (30 days)"
        case specific = "Specific Timeframe"
        case userDefined = "User-Defined"
        
        var description: String {
            switch self {
            case .allData:
                return "Analyze all available data for comprehensive insights"
            case .recent:
                return "Focus on recent activities and trends"
            case .specific:
                return "Analyze data from a custom date range"
            case .userDefined:
                return "Use custom criteria and filters"
            }
        }
    }
    
    // MARK: - View Body
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Section
                    headerSection
                    
                    // Generation Type Selection
                    generationTypeSection
                    
                    // Scope Selection
                    scopeSection
                    
                    // Insight Types Selection
                    insightTypesSection
                    
                    // Priority and Options
                    optionsSection
                    
                    // Advanced Options
                    if showingAdvancedOptions {
                        advancedOptionsSection
                    }
                    
                    // Custom Prompt
                    customPromptSection
                    
                    // Generate Button
                    generateButtonSection
                    
                    // Progress Section
                    if isGenerating {
                        progressSection
                    }
                }
                .padding()
            }
            .navigationTitle("Generate AI Insights")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarBackButtonHidden(false)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 48))
                .foregroundColor(.blue)
            
            Text("AI Insights Generation")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Configure and generate intelligent insights using advanced machine learning algorithms")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Generation Type Section
    
    private var generationTypeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Generation Type")
                .font(.headline)
                .foregroundColor(.primary)
            
            ForEach(GenerationType.allCases, id: \.self) { type in
                GenerationTypeCard(
                    type: type,
                    isSelected: selectedGenerationType == type,
                    onSelect: { selectedGenerationType = type }
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Scope Section
    
    private var scopeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Analysis Scope")
                .font(.headline)
                .foregroundColor(.primary)
            
            ForEach(GenerationScope.allCases, id: \.self) { scope in
                ScopeCard(
                    scope: scope,
                    isSelected: selectedScope == scope,
                    onSelect: { selectedScope = scope }
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Insight Types Section
    
    private var insightTypesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Insight Types")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(selectedInsightTypes.count == InsightType.allCases.count ? "Deselect All" : "Select All") {
                    if selectedInsightTypes.count == InsightType.allCases.count {
                        selectedInsightTypes.removeAll()
                    } else {
                        selectedInsightTypes = Set(InsightType.allCases)
                    }
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(InsightType.allCases, id: \.self) { type in
                    InsightTypeToggle(
                        type: type,
                        isSelected: selectedInsightTypes.contains(type),
                        onToggle: { isSelected in
                            if isSelected {
                                selectedInsightTypes.insert(type)
                            } else {
                                selectedInsightTypes.remove(type)
                            }
                        }
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Options Section
    
    private var optionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Options")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                // Priority Selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("Priority Level")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Picker("Priority", selection: $selectedPriority) {
                        ForEach(InsightPriority.allCases, id: \.self) { priority in
                            Text(priority.displayName).tag(priority)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Divider()
                
                // Feature Toggles
                VStack(spacing: 8) {
                    Toggle("Include ML Predictions", isOn: $includeMLPredictions)
                        .font(.subheadline)
                    
                    Toggle("Include Risk Assessment", isOn: $includeRiskAssessment)
                        .font(.subheadline)
                    
                    Toggle("Include Optimizations", isOn: $includeOptimizations)
                        .font(.subheadline)
                }
                
                Divider()
                
                // Advanced Options Toggle
                Button(action: {
                    withAnimation {
                        showingAdvancedOptions.toggle()
                    }
                }) {
                    HStack {
                        Text("Advanced Options")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Image(systemName: showingAdvancedOptions ? "chevron.down" : "chevron.right")
                            .font(.caption)
                    }
                }
                .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Advanced Options Section
    
    private var advancedOptionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Advanced Configuration")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                // Model Configuration
                VStack(alignment: .leading, spacing: 8) {
                    Text("ML Model Configuration")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("Configure advanced machine learning parameters for insight generation")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // Mock advanced options
                    HStack {
                        Text("Confidence Threshold")
                        Spacer()
                        Text("85%")
                            .foregroundColor(.secondary)
                    }
                    .font(.caption)
                    
                    HStack {
                        Text("Training Data Size")
                        Spacer()
                        Text("Full Dataset")
                            .foregroundColor(.secondary)
                    }
                    .font(.caption)
                }
                
                Divider()
                
                // Performance Options
                VStack(alignment: .leading, spacing: 8) {
                    Text("Performance Options")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Toggle("Parallel Processing", isOn: .constant(true))
                        .font(.caption)
                        .disabled(true)
                    
                    Toggle("Cache Results", isOn: .constant(true))
                        .font(.caption)
                        .disabled(true)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        .transition(.slide)
    }
    
    // MARK: - Custom Prompt Section
    
    private var customPromptSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Custom Instructions")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Additional Context (Optional)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                TextEditor(text: $customPrompt)
                    .frame(minHeight: 100)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
                
                Text("Provide specific instructions or context to guide the AI insight generation process")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Generate Button Section
    
    private var generateButtonSection: some View {
        VStack(spacing: 16) {
            Button(action: generateInsights) {
                HStack {
                    if isGenerating {
                        ProgressView()
                            .scaleEffect(0.8)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "wand.and.stars")
                            .font(.headline)
                    }
                    
                    Text(isGenerating ? "Generating..." : "Generate Insights")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(isGenerating ? Color.gray : Color.blue)
                .cornerRadius(12)
            }
            .disabled(isGenerating || selectedInsightTypes.isEmpty)
            
            if !selectedInsightTypes.isEmpty {
                VStack(spacing: 4) {
                    Text("Estimated Time: \(selectedGenerationType.estimatedTime)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(selectedInsightTypes.count) insight type(s) selected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Progress Section
    
    private var progressSection: some View {
        VStack(spacing: 16) {
            Text("Generating AI Insights")
                .font(.headline)
                .fontWeight(.semibold)
            
            ProgressView(value: generationProgress, total: 1.0)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                .frame(height: 8)
            
            Text(getProgressDescription())
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Helper Methods
    
    private func generateInsights() {
        guard !selectedInsightTypes.isEmpty else { return }
        
        isGenerating = true
        generationProgress = 0.0
        
        // Simulate insight generation with progress updates
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
            generationProgress += 0.1
            
            if generationProgress >= 1.0 {
                timer.invalidate()
                completeGeneration()
            }
        }
    }
    
    private func completeGeneration() {
        Task {
            await viewModel.generateInsights(
                types: selectedInsightTypes,
                priority: selectedPriority,
                includeML: includeMLPredictions,
                includeRisk: includeRiskAssessment,
                includeOptimizations: includeOptimizations,
                customInstructions: customPrompt.isEmpty ? nil : customPrompt
            )
            
            DispatchQueue.main.async {
                isGenerating = false
                generationProgress = 0.0
                dismiss()
            }
        }
    }
    
    private func getProgressDescription() -> String {
        let progress = Int(generationProgress * 100)
        
        switch progress {
        case 0..<20:
            return "Analyzing data sources..."
        case 20..<40:
            return "Processing machine learning models..."
        case 40..<60:
            return "Generating insights..."
        case 60..<80:
            return "Validating recommendations..."
        case 80..<100:
            return "Finalizing insights..."
        default:
            return "Completing generation..."
        }
    }
}

// MARK: - Supporting Views

struct GenerationTypeCard: View {
    let type: AIInsightsGenerationView.GenerationType
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(type.rawValue)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.blue)
                    }
                }
                
                Text(type.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                
                HStack {
                    Spacer()
                    Text(type.estimatedTime)
                        .font(.caption)
                        .foregroundColor(.blue)
                        .fontWeight(.medium)
                }
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ScopeCard: View {
    let scope: AIInsightsGenerationView.GenerationScope
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(scope.rawValue)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text(scope.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct InsightTypeToggle: View {
    let type: InsightType
    let isSelected: Bool
    let onToggle: (Bool) -> Void
    
    var body: some View {
        Button(action: { onToggle(!isSelected) }) {
            VStack(spacing: 8) {
                Image(systemName: type.iconName)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .blue)
                
                Text(type.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? Color.blue : Color(.systemGray6))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - ViewModel Extension

extension AIInsightsViewModel {
    func generateInsights(
        types: Set<InsightType>,
        priority: InsightPriority,
        includeML: Bool,
        includeRisk: Bool,
        includeOptimizations: Bool,
        customInstructions: String?
    ) async {
        // Simulate insight generation
        for type in types {
            let insight = createMockInsight(
                type: type,
                priority: priority,
                includeML: includeML,
                includeRisk: includeRisk,
                includeOptimizations: includeOptimizations,
                customInstructions: customInstructions
            )
            
            await MainActor.run {
                insights.append(insight)
            }
        }
    }
    
    private func createMockInsight(
        type: InsightType,
        priority: InsightPriority,
        includeML: Bool,
        includeRisk: Bool,
        includeOptimizations: Bool,
        customInstructions: String?
    ) -> AIInsight {
        return AIInsight(
            id: UUID(),
            type: type,
            title: "Generated \(type.displayName)",
            description: "AI-generated insight based on your configuration",
            priority: priority,
            confidence: 0.85,
            recommendations: [
                ActionRecommendation(
                    id: UUID(),
                    title: "Recommended Action",
                    description: "Take this action based on the insight",
                    actionType: .review,
                    estimatedImpact: .medium,
                    estimatedEffort: .low
                )
            ],
            supportingData: [:],
            createdAt: Date(),
            expiresAt: Calendar.current.date(byAdding: .day, value: 30, to: Date()),
            metadata: InsightMetadata(
                source: .mlModel,
                version: "1.0",
                confidence: 0.85,
                processingTime: 2.5,
                dataSourcesUsed: ["tasks", "documents", "analytics"]
            ),
            analytics: InsightAnalytics(
                viewsCount: 0,
                actionsCount: 0,
                feedbackCount: 0,
                averageRating: 0.0,
                effectivenessScore: 0.0
            )
        )
    }
}

// MARK: - Preview

#Preview {
    AIInsightsGenerationView()
}
