//
//  AIInsightDetailByIdView.swift
//  DiamondDeskERP
//
//  Created by J.Michael McDermott on 7/20/25.
//

import SwiftUI
import CloudKit

/// View that loads and displays an AI insight by ID
/// Provides loading states and error handling for insight retrieval
struct AIInsightDetailByIdView: View {
    
    // MARK: - Properties
    
    let insightId: String
    @StateObject private var viewModel = AIInsightsViewModel()
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - View Body
    
    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.insights.isEmpty {
                loadingView
            } else if let insight = viewModel.insights.first(where: { $0.id.uuidString == insightId }) {
                AIInsightDetailView(insight: insight)
            } else {
                errorView
            }
        }
        .navigationBarBackButtonHidden(false)
        .task {
            await loadInsight()
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading AI Insight...")
                .font(.title3)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Error View
    
    private var errorView: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            Text("AI Insight Not Found")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("The requested AI insight could not be found or may have been deleted.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: {
                dismiss()
            }) {
                Text("Go Back")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            
            Button(action: {
                Task {
                    await loadInsight()
                }
            }) {
                Text("Try Again")
                    .font(.headline)
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
            }
            .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Helper Methods
    
    private func loadInsight() async {
        // Try to find the insight in the current list first
        if viewModel.insights.first(where: { $0.id.uuidString == insightId }) != nil {
            return
        }
        
        // If not found, reload all insights
        await viewModel.loadInsights()
        
        // If still not found, try to fetch the specific insight
        if viewModel.insights.first(where: { $0.id.uuidString == insightId }) == nil {
            await fetchSpecificInsight()
        }
    }
    
    private func fetchSpecificInsight() async {
        guard let uuid = UUID(uuidString: insightId) else { return }
        
        do {
            let recordID = CKRecord.ID(recordName: uuid.uuidString)
            let record = try await CKContainer.default().privateCloudDatabase.record(for: recordID)
            
            if let insight = AIInsight.fromCloudKitRecord(record) {
                DispatchQueue.main.async {
                    viewModel.insights.append(insight)
                }
            }
        } catch {
            // Error is handled by showing the error view
            print("Failed to fetch AI insight: \(error)")
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AIInsightDetailByIdView(insightId: UUID().uuidString)
    }
}
