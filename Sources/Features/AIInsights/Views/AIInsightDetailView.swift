//
//  AIInsightDetailView.swift
//  DiamondDeskERP
//
//  Created by AI Assistant on 7/20/25.
//  Copyright © 2025 Diamond Desk. All rights reserved.
//

import SwiftUI

/// Detailed view for displaying individual AI insight with actions and feedback
struct AIInsightDetailView: View {
    let insight: AIInsight
    let viewModel: AIInsightsViewModel
    
    @State private var showingFeedbackSheet = false
    @State private var feedbackRating = 3
    @State private var feedbackComment = ""
    @State private var feedbackHelpful = true
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header Section
                    headerSection
                    
                    // Description Section
                    descriptionSection
                    
                    // Action Recommendations Section
                    if !insight.actionRecommendations.isEmpty {
                        actionRecommendationsSection
                    }
                    
                    // Supporting Data Section
                    if !insight.supportingData.isEmpty {
                        supportingDataSection
                    }
                    
                    // Feedback Section
                    feedbackSection
                    
                    // Metadata Section
                    metadataSection
                }
                .padding()
            }
            .navigationTitle("Insight Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Provide Feedback") {
                            showingFeedbackSheet = true
                        }
                        
                        Button("Dismiss Insight") {
                            Task {
                                await viewModel.dismissInsight(insight)
                                dismiss()
                            }
                        }
                        
                        Button("Share") {
                            // TODO: Implement sharing
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingFeedbackSheet) {
                feedbackSheet
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Priority and Type
            HStack {
                priorityBadge
                typeBadge
                categoryBadge
                Spacer()
                confidenceBadge
            }
            
            // Title
            Text(insight.title)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.leading)
            
            // Status indicators
            HStack {
                if insight.isActionTaken {
                    statusBadge("Action Taken", color: .green, icon: "checkmark.circle.fill")
                } else if !insight.actionRecommendations.isEmpty {
                    statusBadge("Action Available", color: .blue, icon: "arrow.right.circle.fill")
                }
                
                if let feedback = insight.feedback {
                    statusBadge("Rated \(feedback.rating)/5", color: .purple, icon: "star.fill")
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Description Section
    
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Description")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(insight.description)
                .font(.body)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Action Recommendations Section
    
    private var actionRecommendationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recommended Actions")
                .font(.headline)
                .fontWeight(.semibold)
            
            ForEach(insight.actionRecommendations) { action in
                actionRecommendationCard(action)
            }
        }
    }
    
    private func actionRecommendationCard(_ action: ActionRecommendation) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Action header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(action.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text(action.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if action.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title3)
                } else {
                    actionButton(action)
                }
            }
            
            // Action metadata
            HStack {
                effortBadge(action.estimatedEffort)
                impactBadge(action.estimatedImpact)
                Spacer()
                
                if let completedAt = action.completedAt {
                    Text("Completed \(completedAt.timeAgoDisplay)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private func actionButton(_ action: ActionRecommendation) -> some View {
        Button {
            Task {
                await viewModel.markActionTaken(insight, action: action)
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: actionTypeIcon(action.actionType))
                    .font(.caption)
                Text(actionTypeTitle(action.actionType))
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.accentColor)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Supporting Data Section
    
    private var supportingDataSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Supporting Data")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(Array(insight.supportingData.keys), id: \.self) { key in
                    dataCard(key: key, value: "\(insight.supportingData[key] ?? "")")
                }
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func dataCard(key: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(key.capitalized.replacingOccurrences(of: "_", with: " "))
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
    
    // MARK: - Feedback Section
    
    private var feedbackSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Feedback")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if insight.feedback == nil {
                    Button("Provide Feedback") {
                        showingFeedbackSheet = true
                    }
                    .font(.caption)
                    .foregroundColor(.accentColor)
                }
            }
            
            if let feedback = insight.feedback {
                existingFeedbackView(feedback)
            } else {
                Text("No feedback provided yet")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func existingFeedbackView(_ feedback: InsightFeedback) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Star rating
                HStack(spacing: 2) {
                    ForEach(1...5, id: \.self) { star in
                        Image(systemName: star <= feedback.rating ? "star.fill" : "star")
                            .foregroundColor(star <= feedback.rating ? .yellow : .gray)
                            .font(.caption)
                    }
                }
                
                Spacer()
                
                // Helpful indicator
                HStack(spacing: 4) {
                    Image(systemName: feedback.isHelpful ? "hand.thumbsup.fill" : "hand.thumbsdown.fill")
                        .foregroundColor(feedback.isHelpful ? .green : .red)
                        .font(.caption)
                    
                    Text(feedback.isHelpful ? "Helpful" : "Not Helpful")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            if let comment = feedback.comment, !comment.isEmpty {
                Text(comment)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
            }
            
            Text("Submitted \(feedback.submittedAt.timeAgoDisplay)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Metadata Section
    
    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Metadata")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 6) {
                metadataRow("Created", value: insight.createdAt.formatted())
                
                if let expiresAt = insight.expiresAt {
                    metadataRow("Expires", value: expiresAt.formatted())
                }
                
                metadataRow("Target", value: "\(insight.targetEntityType): \(insight.targetEntityId)")
                
                if !insight.tags.isEmpty {
                    HStack {
                        Text("Tags:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 80, alignment: .leading)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(insight.tags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.caption2)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color(.systemGray5))
                                        .foregroundColor(.secondary)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func metadataRow(_ label: String, value: String) -> some View {
        HStack {
            Text("\(label):")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
            
            Spacer()
        }
    }
    
    // MARK: - Feedback Sheet
    
    private var feedbackSheet: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                // Rating
                VStack(alignment: .leading, spacing: 8) {
                    Text("How helpful was this insight?")
                        .font(.headline)
                    
                    HStack {
                        ForEach(1...5, id: \.self) { rating in
                            Button {
                                feedbackRating = rating
                            } label: {
                                Image(systemName: rating <= feedbackRating ? "star.fill" : "star")
                                    .foregroundColor(rating <= feedbackRating ? .yellow : .gray)
                                    .font(.title2)
                            }
                        }
                        
                        Spacer()
                    }
                }
                
                // Helpful toggle
                VStack(alignment: .leading, spacing: 8) {
                    Text("Was this insight helpful?")
                        .font(.headline)
                    
                    Picker("Helpful", selection: $feedbackHelpful) {
                        Text("Yes").tag(true)
                        Text("No").tag(false)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                // Comment
                VStack(alignment: .leading, spacing: 8) {
                    Text("Additional Comments (Optional)")
                        .font(.headline)
                    
                    TextEditor(text: $feedbackComment)
                        .frame(height: 100)
                        .padding(8)
                        .background(Color(.systemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Provide Feedback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showingFeedbackSheet = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Submit") {
                        Task {
                            await viewModel.provideFeedback(
                                insight, 
                                rating: feedbackRating, 
                                isHelpful: feedbackHelpful, 
                                comment: feedbackComment.isEmpty ? nil : feedbackComment
                            )
                            showingFeedbackSheet = false
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Views and Functions
    
    private var priorityBadge: some View {
        Text(insight.priority.rawValue.capitalized)
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(insight.priority.color.opacity(0.2))
            .foregroundColor(insight.priority.color)
            .clipShape(Capsule())
    }
    
    private var typeBadge: some View {
        Text(insight.type.displayName)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.blue.opacity(0.2))
            .foregroundColor(.blue)
            .clipShape(Capsule())
    }
    
    private var categoryBadge: some View {
        Text(insight.category.displayName)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.purple.opacity(0.2))
            .foregroundColor(.purple)
            .clipShape(Capsule())
    }
    
    private var confidenceBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(confidenceColor)
                .frame(width: 6, height: 6)
            
            Text("\(Int(insight.confidence * 100))% confident")
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
    }
    
    private var confidenceColor: Color {
        if insight.confidence >= 0.8 { return .green }
        else if insight.confidence >= 0.6 { return .yellow }
        else { return .orange }
    }
    
    private func statusBadge(_ text: String, color: Color, icon: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(text)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.2))
        .foregroundColor(color)
        .clipShape(Capsule())
    }
    
    private func effortBadge(_ effort: ActionRecommendation.EffortLevel) -> some View {
        Text(effort.rawValue.capitalized)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(effortColor(effort).opacity(0.2))
            .foregroundColor(effortColor(effort))
            .clipShape(Capsule())
    }
    
    private func impactBadge(_ impact: Double) -> some View {
        Text("\(Int(impact * 100))% impact")
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(impactColor(impact).opacity(0.2))
            .foregroundColor(impactColor(impact))
            .clipShape(Capsule())
    }
    
    private func effortColor(_ effort: ActionRecommendation.EffortLevel) -> Color {
        switch effort {
        case .minimal: return .green
        case .low: return .blue
        case .medium: return .yellow
        case .high: return .orange
        case .planning: return .red
        }
    }
    
    private func impactColor(_ impact: Double) -> Color {
        if impact >= 0.8 { return .green }
        else if impact >= 0.6 { return .blue }
        else if impact >= 0.4 { return .yellow }
        else { return .orange }
    }
    
    private func actionTypeIcon(_ type: ActionRecommendation.ActionType) -> String {
        switch type {
        case .navigate: return "arrow.right"
        case .create: return "plus"
        case .update: return "pencil"
        case .review: return "eye"
        case .schedule: return "calendar"
        case .assign: return "person.badge.plus"
        case .notify: return "bell"
        case .archive: return "archivebox"
        }
    }
    
    private func actionTypeTitle(_ type: ActionRecommendation.ActionType) -> String {
        switch type {
        case .navigate: return "Go"
        case .create: return "Create"
        case .update: return "Update"
        case .review: return "Review"
        case .schedule: return "Schedule"
        case .assign: return "Assign"
        case .notify: return "Notify"
        case .archive: return "Archive"
        }
    }
}

// MARK: - Preview

struct AIInsightDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleInsight = AIInsight(
            id: "sample",
            type: .documentRecommendation,
            title: "Related Document Found",
            description: "Based on your work with 'Sales Training Manual', you might find 'Customer Service Guidelines' helpful.",
            confidence: 0.85,
            priority: .high,
            category: .recommendation,
            targetEntityType: "Document",
            targetEntityId: "doc123",
            actionRecommendations: [
                ActionRecommendation(
                    id: "action1",
                    title: "View Document",
                    description: "Open the recommended document",
                    actionType: .navigate,
                    estimatedImpact: 0.8,
                    estimatedEffort: .minimal,
                    targetUrl: "/documents/doc123",
                    parameters: ["documentId": "doc123"],
                    isCompleted: false,
                    completedAt: nil
                )
            ],
            supportingData: [
                "similarityScore": 0.85,
                "commonTopics": "sales, training, customer service"
            ],
            createdAt: Date(),
            expiresAt: Calendar.current.date(byAdding: .day, value: 7, to: Date()),
            isActionTaken: false,
            feedback: nil,
            tags: ["document", "recommendation", "similarity"]
        )
        
        AIInsightDetailView(insight: sampleInsight, viewModel: AIInsightsViewModel())
    }
}
