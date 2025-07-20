//
//  TaskCompletionBreakdownView.swift
//  DiamondDeskERP
//
//  Created by AI Assistant on 7/20/25.
//  Copyright © 2025 Diamond Desk. All rights reserved.
//

import SwiftUI

/// Task completion breakdown view with detailed progress analysis
struct TaskCompletionBreakdownView: View {
    let completionLogs: [TaskCompletionLog]
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedBreakdownType: BreakdownType = .byStore
    
    enum BreakdownType: String, CaseIterable {
        case byStore = "By Store"
        case byUser = "By User"
        case byTask = "By Task"
        case byCompletion = "By Completion Rate"
        
        var icon: String {
            switch self {
            case .byStore: return "building.2"
            case .byUser: return "person.2"
            case .byTask: return "checkmark.square"
            case .byCompletion: return "chart.bar"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title2)
                
                Text("Task Completion Analysis")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            // Breakdown Type Picker
            Picker("Breakdown", selection: $selectedBreakdownType) {
                ForEach(BreakdownType.allCases, id: \.self) { type in
                    Label(type.rawValue, systemImage: type.icon).tag(type)
                }
            }
            .pickerStyle(.segmented)
            
            // Content based on selected breakdown
            Group {
                switch selectedBreakdownType {
                case .byStore:
                    storeBreakdownView
                case .byUser:
                    userBreakdownView
                case .byTask:
                    taskBreakdownView
                case .byCompletion:
                    completionRateBreakdownView
                }
            }
        }
        .padding()
        .background(liquidGlassBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Store Breakdown View
    
    private var storeBreakdownView: some View {
        LazyVStack(spacing: 12) {
            let storeGroups = Dictionary(grouping: completionLogs, by: \.storeCode)
            
            ForEach(storeGroups.keys.sorted(), id: \.self) { storeCode in
                let logs = storeGroups[storeCode] ?? []
                let uniqueTasks = Set(logs.map(\.taskId)).count
                let uniqueUsers = Set(logs.map(\.userId)).count
                let avgCompletion = calculateAverageCompletion(logs: logs)
                
                TaskStoreBreakdownCard(
                    storeCode: storeCode,
                    uniqueTasks: uniqueTasks,
                    uniqueUsers: uniqueUsers,
                    averageCompletion: avgCompletion,
                    logs: logs
                )
            }
            
            if storeGroups.isEmpty {
                EmptyStateView(
                    icon: "building.2",
                    title: "No Store Data",
                    message: "No task completion data available for the selected period."
                )
            }
        }
    }
    
    // MARK: - User Breakdown View
    
    private var userBreakdownView: some View {
        LazyVStack(spacing: 12) {
            let userGroups = Dictionary(grouping: completionLogs, by: \.userId)
            
            ForEach(userGroups.keys.sorted(), id: \.self) { userId in
                let logs = userGroups[userId] ?? []
                let uniqueTasks = Set(logs.map(\.taskId)).count
                let stores = Set(logs.map(\.storeCode))
                let avgCompletion = calculateAverageCompletion(logs: logs)
                let completedTasks = logs.filter { $0.currentProgress >= 1.0 }.count
                
                TaskUserBreakdownCard(
                    userId: userId,
                    uniqueTasks: uniqueTasks,
                    completedTasks: completedTasks,
                    stores: stores,
                    averageCompletion: avgCompletion,
                    logs: logs
                )
            }
            
            if userGroups.isEmpty {
                EmptyStateView(
                    icon: "person.2",
                    title: "No User Data",
                    message: "No user task activity available for the selected period."
                )
            }
        }
    }
    
    // MARK: - Task Breakdown View
    
    private var taskBreakdownView: some View {
        LazyVStack(spacing: 12) {
            let taskGroups = Dictionary(grouping: completionLogs, by: \.taskId)
            
            ForEach(taskGroups.keys.sorted(), id: \.self) { taskId in
                let logs = taskGroups[taskId] ?? []
                let uniqueUsers = Set(logs.map(\.userId)).count
                let stores = Set(logs.map(\.storeCode))
                let avgCompletion = calculateAverageCompletion(logs: logs)
                let completionRate = calculateTaskCompletionRate(logs: logs)
                
                TaskBreakdownCard(
                    taskId: taskId,
                    uniqueUsers: uniqueUsers,
                    stores: stores,
                    averageCompletion: avgCompletion,
                    completionRate: completionRate,
                    logs: logs
                )
            }
            
            if taskGroups.isEmpty {
                EmptyStateView(
                    icon: "checkmark.square",
                    title: "No Task Data",
                    message: "No task completion data available for the selected period."
                )
            }
        }
    }
    
    // MARK: - Completion Rate Breakdown View
    
    private var completionRateBreakdownView: some View {
        VStack(spacing: 16) {
            // Completion Rate Distribution
            CompletionRateDistributionView(logs: completionLogs)
            
            // Top Performers
            TopPerformersView(logs: completionLogs)
            
            // Completion Trends
            CompletionTrendsView(logs: completionLogs)
        }
    }
    
    // MARK: - Computed Properties
    
    private var liquidGlassBackground: some ShapeStyle {
        if colorScheme == .dark {
            return AnyShapeStyle(.regularMaterial)
        } else {
            return AnyShapeStyle(.thickMaterial)
        }
    }
    
    // MARK: - Helper Methods
    
    private func calculateAverageCompletion(logs: [TaskCompletionLog]) -> Double {
        guard !logs.isEmpty else { return 0.0 }
        let totalProgress = logs.reduce(0.0) { $0 + $1.currentProgress }
        return totalProgress / Double(logs.count)
    }
    
    private func calculateTaskCompletionRate(logs: [TaskCompletionLog]) -> Double {
        guard !logs.isEmpty else { return 0.0 }
        let completedCount = logs.filter { $0.currentProgress >= 1.0 }.count
        return Double(completedCount) / Double(logs.count) * 100
    }
}

// MARK: - Task Store Breakdown Card

struct TaskStoreBreakdownCard: View {
    let storeCode: String
    let uniqueTasks: Int
    let uniqueUsers: Int
    let averageCompletion: Double
    let logs: [TaskCompletionLog]
    
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 12) {
            // Header
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Store \(storeCode)")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text("\(uniqueTasks) tasks • \(uniqueUsers) users")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(Int(averageCompletion * 100))%")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(averageCompletion >= 0.8 ? .green : averageCompletion >= 0.5 ? .orange : .red)
                        
                        Text("avg completion")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .animation(.easeInOut(duration: 0.2), value: isExpanded)
                }
            }
            .buttonStyle(.plain)
            
            // Expanded Details
            if isExpanded {
                VStack(spacing: 12) {
                    // Progress Distribution
                    TaskProgressDistribution(logs: logs)
                    
                    // Recent Completions
                    RecentTaskCompletions(logs: Array(logs.prefix(5)))
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.quaternary.opacity(0.5))
        )
    }
}

// MARK: - Task User Breakdown Card

struct TaskUserBreakdownCard: View {
    let userId: String
    let uniqueTasks: Int
    let completedTasks: Int
    let stores: Set<String>
    let averageCompletion: Double
    let logs: [TaskCompletionLog]
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("User \(userId)")
                    .font(.body)
                    .fontWeight(.medium)
                
                Text("\(completedTasks)/\(uniqueTasks) tasks completed")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("Active in \(stores.count) store\(stores.count == 1 ? "" : "s")")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(averageCompletion * 100))%")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(averageCompletion >= 0.8 ? .green : averageCompletion >= 0.5 ? .orange : .red)
                
                Text("avg progress")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.quaternary.opacity(0.3))
        )
    }
}

// MARK: - Task Breakdown Card

struct TaskBreakdownCard: View {
    let taskId: String
    let uniqueUsers: Int
    let stores: Set<String>
    let averageCompletion: Double
    let completionRate: Double
    let logs: [TaskCompletionLog]
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Task \(taskId.prefix(8))...")
                    .font(.body)
                    .fontWeight(.medium)
                
                Text("\(uniqueUsers) users • \(stores.count) stores")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 8) {
                    VStack(spacing: 2) {
                        Text("\(Int(averageCompletion * 100))%")
                            .font(.subheadline)
                            .fontWeight(.bold)
                        
                        Text("avg")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(spacing: 2) {
                        Text("\(Int(completionRate))%")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(completionRate >= 80 ? .green : completionRate >= 50 ? .orange : .red)
                        
                        Text("complete")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.quaternary.opacity(0.3))
        )
    }
}

// MARK: - Completion Rate Distribution View

struct CompletionRateDistributionView: View {
    let logs: [TaskCompletionLog]
    
    private var distributionData: [(range: String, count: Int, color: Color)] {
        let ranges = [
            ("0-25%", 0.0..<0.25, Color.red),
            ("25-50%", 0.25..<0.5, Color.orange),
            ("50-75%", 0.5..<0.75, Color.yellow),
            ("75-100%", 0.75...1.0, Color.green)
        ]
        
        return ranges.map { (label, range, color) in
            let count = logs.filter { range.contains($0.currentProgress) }.count
            return (label, count, color)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Completion Rate Distribution")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 12) {
                ForEach(distributionData, id: \.range) { data in
                    VStack(spacing: 4) {
                        Text("\(data.count)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(data.color)
                        
                        Text(data.range)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(data.color.opacity(0.1))
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.quaternary.opacity(0.3))
        )
    }
}

// MARK: - Top Performers View

struct TopPerformersView: View {
    let logs: [TaskCompletionLog]
    
    private var topPerformers: [(userId: String, score: Double)] {
        let userGroups = Dictionary(grouping: logs, by: \.userId)
        return userGroups.compactMap { (userId, userLogs) in
            let avgCompletion = userLogs.reduce(0.0) { $0 + $1.currentProgress } / Double(userLogs.count)
            return (userId, avgCompletion)
        }
        .sorted { $0.score > $1.score }
        .prefix(5)
        .map { $0 }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Top Performers")
                .font(.headline)
                .fontWeight(.semibold)
            
            ForEach(Array(topPerformers.enumerated()), id: \.offset) { index, performer in
                HStack {
                    Text("\(index + 1)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .frame(width: 20, height: 20)
                        .background(Circle().fill(.blue))
                        .foregroundColor(.white)
                    
                    Text("User \(performer.userId)")
                        .font(.body)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text("\(Int(performer.score * 100))%")
                        .font(.body)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.quaternary.opacity(0.3))
        )
    }
}

// MARK: - Completion Trends View

struct CompletionTrendsView: View {
    let logs: [TaskCompletionLog]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Completion Trends")
                .font(.headline)
                .fontWeight(.semibold)
            
            // This would be enhanced with actual trend calculation and visualization
            Text("Trend analysis coming soon...")
                .font(.body)
                .foregroundColor(.secondary)
                .italic()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.quaternary.opacity(0.3))
        )
    }
}

// MARK: - Task Progress Distribution

struct TaskProgressDistribution: View {
    let logs: [TaskCompletionLog]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Progress Distribution")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            HStack(spacing: 4) {
                ForEach(0..<10, id: \.self) { segment in
                    let range = Double(segment) * 0.1..<Double(segment + 1) * 0.1
                    let count = logs.filter { range.contains($0.currentProgress) }.count
                    let isActive = count > 0
                    
                    Rectangle()
                        .fill(isActive ? .blue : .gray.opacity(0.3))
                        .frame(height: 8)
                        .overlay(
                            Text("\(count)")
                                .font(.caption2)
                                .foregroundColor(isActive ? .white : .clear)
                        )
                }
            }
        }
    }
}

// MARK: - Recent Task Completions

struct RecentTaskCompletions: View {
    let logs: [TaskCompletionLog]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Recent Activity")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            ForEach(logs.sorted { $0.timestamp > $1.timestamp }, id: \.id) { log in
                HStack(spacing: 8) {
                    Circle()
                        .fill(log.currentProgress >= 1.0 ? .green : .blue)
                        .frame(width: 6, height: 6)
                    
                    Text("User \(log.userId) - \(Int(log.currentProgress * 100))% progress")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
            }
        }
        .padding(.top, 4)
    }
}
