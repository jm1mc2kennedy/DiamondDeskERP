//
//  TaskStepView.swift
//  DiamondDeskERP
//
//  Created by AI Assistant on 7/20/25.
//  Copyright © 2025 Diamond Desk. All rights reserved.
//

import SwiftUI

/// Step-based task completion view with enterprise tracking
/// Supports Liquid Glass design system with accessibility compliance
struct TaskStepView: View {
    
    // MARK: - Properties
    
    let taskId: String
    let steps: [TaskStep]
    @State private var completedSteps: Set<String> = []
    @StateObject private var trackingService = AcknowledgmentTrackingService()
    @Environment(\.currentUser) private var currentUser
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    // MARK: - Computed Properties
    
    private var completionPercentage: Double {
        guard !steps.isEmpty else { return 0.0 }
        let requiredSteps = steps.filter { $0.isRequired }
        let completedRequiredSteps = completedSteps.filter { stepId in
            requiredSteps.contains { $0.id == stepId }
        }
        return Double(completedRequiredSteps.count) / Double(requiredSteps.count)
    }
    
    private var isFullyComplete: Bool {
        return TaskCompletionLog.isTaskComplete(
            completedSteps: Array(completedSteps),
            totalSteps: steps
        )
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 16) {
            // Progress Header
            progressHeaderSection
            
            // Steps List
            stepsListSection
            
            // Completion Actions
            if isFullyComplete {
                completionActionsSection
            }
        }
        .padding()
        .background(liquidGlassBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .task {
            await loadExistingProgress()
        }
    }
    
    // MARK: - Progress Header Section
    
    private var progressHeaderSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Task Progress")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(Int(completionPercentage * 100))%")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(progressColor)
            }
            
            // Progress Bar
            ProgressView(value: completionPercentage)
                .progressViewStyle(LiquidGlassProgressStyle())
                .animation(reduceMotion ? .none : .easeInOut(duration: 0.3), value: completionPercentage)
                .accessibilityLabel("Task completion progress")
                .accessibilityValue("\(Int(completionPercentage * 100)) percent complete")
        }
    }
    
    // MARK: - Steps List Section
    
    private var stepsListSection: some View {
        LazyVStack(spacing: 12) {
            ForEach(steps.sorted { $0.order < $1.order }) { step in
                TaskStepRowView(
                    step: step,
                    isCompleted: completedSteps.contains(step.id),
                    onToggle: { isCompleted in
                        await toggleStepCompletion(step: step, isCompleted: isCompleted)
                    }
                )
            }
        }
    }
    
    // MARK: - Completion Actions Section
    
    private var completionActionsSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title2)
                
                Text("Task Complete!")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
                
                Spacer()
            }
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.green.opacity(0.1))
            )
            
            // Optional: Add completion confirmation or notes
            if !reduceMotion {
                Text("Great work! This task has been marked as complete.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .transition(.opacity)
            }
        }
    }
    
    // MARK: - Computed Styles
    
    private var liquidGlassBackground: some ShapeStyle {
        if colorScheme == .dark {
            return AnyShapeStyle(.regularMaterial)
        } else {
            return AnyShapeStyle(.thickMaterial)
        }
    }
    
    private var progressColor: Color {
        switch completionPercentage {
        case 0.0..<0.3:
            return .red
        case 0.3..<0.7:
            return .orange
        case 0.7..<1.0:
            return .blue
        default:
            return .green
        }
    }
    
    // MARK: - Actions
    
    private func toggleStepCompletion(step: TaskStep, isCompleted: Bool) async {
        guard let currentUser = currentUser else { return }
        
        if isCompleted {
            completedSteps.insert(step.id)
        } else {
            completedSteps.remove(step.id)
        }
        
        // Log the completion to tracking service
        do {
            try await trackingService.logTaskStepComplete(
                taskId: taskId,
                stepId: step.id,
                userId: currentUser.userId,
                storeCode: currentUser.storeCodes.first ?? "",
                allSteps: steps
            )
        } catch {
            // Handle error - could show alert or retry mechanism
            print("Failed to log step completion: \(error)")
        }
    }
    
    private func loadExistingProgress() async {
        guard let currentUser = currentUser else { return }
        
        do {
            let logs = try await trackingService.getTaskCompletionLogs(for: taskId)
            if let userLog = logs.first(where: { $0.userId == currentUser.userId }) {
                await MainActor.run {
                    completedSteps = Set(userLog.stepIdsCompleted)
                }
            }
        } catch {
            print("Failed to load existing progress: \(error)")
        }
    }
}

// MARK: - Task Step Row View

struct TaskStepRowView: View {
    let step: TaskStep
    let isCompleted: Bool
    let onToggle: (Bool) async -> Void
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isToggling = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Checkbox
            Button {
                Task {
                    isToggling = true
                    await onToggle(!isCompleted)
                    isToggling = false
                }
            } label: {
                Image(systemName: isCompleted ? "checkmark.square.fill" : "square")
                    .foregroundColor(isCompleted ? .green : .secondary)
                    .font(.title3)
                    .opacity(isToggling ? 0.6 : 1.0)
            }
            .disabled(isToggling)
            .accessibilityLabel(isCompleted ? "Completed step" : "Incomplete step")
            .accessibilityHint("Tap to toggle completion")
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(step.title)
                        .font(.body)
                        .fontWeight(isCompleted ? .medium : .regular)
                        .strikethrough(isCompleted)
                        .foregroundColor(isCompleted ? .secondary : .primary)
                    
                    if step.isRequired {
                        Text("Required")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.orange.opacity(0.2))
                            .foregroundColor(.orange)
                            .clipShape(Capsule())
                    }
                    
                    Spacer()
                    
                    if let estimatedMinutes = step.estimatedMinutes {
                        Text("\(estimatedMinutes) min")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if let description = step.description, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isCompleted ? .green.opacity(0.05) : .clear)
        )
        .animation(reduceMotion ? .none : .easeInOut(duration: 0.2), value: isCompleted)
    }
}

// MARK: - Liquid Glass Progress Style

struct LiquidGlassProgressStyle: ProgressViewStyle {
    func makeBody(configuration: Configuration) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 4)
                    .fill(.quaternary)
                    .frame(height: 8)
                
                // Progress fill
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * (configuration.fractionCompleted ?? 0), height: 8)
                    .overlay(
                        // Liquid glass effect
                        RoundedRectangle(cornerRadius: 4)
                            .fill(.white.opacity(0.3))
                            .frame(height: 2)
                            .offset(y: -1)
                    )
            }
        }
        .frame(height: 8)
    }
}

// MARK: - Preview

#Preview {
    TaskStepView(
        taskId: "sample-task-1",
        steps: [
            TaskStep(title: "Review documentation", order: 1, estimatedMinutes: 10),
            TaskStep(title: "Complete setup", description: "Follow the setup guide carefully", order: 2, estimatedMinutes: 15),
            TaskStep(title: "Test functionality", order: 3, isRequired: false, estimatedMinutes: 5),
            TaskStep(title: "Submit report", order: 4, estimatedMinutes: 5)
        ]
    )
    .padding()
    .background(.gray.opacity(0.1))
}
