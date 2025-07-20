//
//  MessageReadBreakdownView.swift
//  DiamondDeskERP
//
//  Created by AI Assistant on 7/20/25.
//  Copyright © 2025 Diamond Desk. All rights reserved.
//

import SwiftUI

/// Message read breakdown view with store/user level reporting
struct MessageReadBreakdownView: View {
    let readLogs: [MessageReadLog]
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedBreakdownType: BreakdownType = .byStore
    
    enum BreakdownType: String, CaseIterable {
        case byStore = "By Store"
        case byUser = "By User"
        case byMessage = "By Message"
        
        var icon: String {
            switch self {
            case .byStore: return "building.2"
            case .byUser: return "person.2"
            case .byMessage: return "envelope"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "envelope.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
                
                Text("Message Read Analysis")
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
                case .byMessage:
                    messageBreakdownView
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
            let storeGroups = Dictionary(grouping: readLogs, by: \.storeCode)
            
            ForEach(storeGroups.keys.sorted(), id: \.self) { storeCode in
                let logs = storeGroups[storeCode] ?? []
                let uniqueMessages = Set(logs.map(\.messageId)).count
                let uniqueUsers = Set(logs.map(\.userId)).count
                let totalReads = logs.count
                
                StoreBreakdownCard(
                    storeCode: storeCode,
                    uniqueMessages: uniqueMessages,
                    uniqueUsers: uniqueUsers,
                    totalReads: totalReads,
                    logs: logs
                )
            }
            
            if storeGroups.isEmpty {
                EmptyStateView(
                    icon: "building.2",
                    title: "No Store Data",
                    message: "No message read data available for the selected period."
                )
            }
        }
    }
    
    // MARK: - User Breakdown View
    
    private var userBreakdownView: some View {
        LazyVStack(spacing: 12) {
            let userGroups = Dictionary(grouping: readLogs, by: \.userId)
            
            ForEach(userGroups.keys.sorted(), id: \.self) { userId in
                let logs = userGroups[userId] ?? []
                let uniqueMessages = Set(logs.map(\.messageId)).count
                let stores = Set(logs.map(\.storeCode))
                let totalReads = logs.count
                
                UserBreakdownCard(
                    userId: userId,
                    uniqueMessages: uniqueMessages,
                    stores: stores,
                    totalReads: totalReads,
                    logs: logs
                )
            }
            
            if userGroups.isEmpty {
                EmptyStateView(
                    icon: "person.2",
                    title: "No User Data",
                    message: "No user activity data available for the selected period."
                )
            }
        }
    }
    
    // MARK: - Message Breakdown View
    
    private var messageBreakdownView: some View {
        LazyVStack(spacing: 12) {
            let messageGroups = Dictionary(grouping: readLogs, by: \.messageId)
            
            ForEach(messageGroups.keys.sorted(), id: \.self) { messageId in
                let logs = messageGroups[messageId] ?? []
                let uniqueUsers = Set(logs.map(\.userId)).count
                let stores = Set(logs.map(\.storeCode))
                let readPercentage = calculateReadPercentage(logs: logs)
                
                MessageBreakdownCard(
                    messageId: messageId,
                    uniqueUsers: uniqueUsers,
                    stores: stores,
                    readPercentage: readPercentage,
                    logs: logs
                )
            }
            
            if messageGroups.isEmpty {
                EmptyStateView(
                    icon: "envelope",
                    title: "No Message Data",
                    message: "No message tracking data available for the selected period."
                )
            }
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
    
    private func calculateReadPercentage(logs: [MessageReadLog]) -> Double {
        // This would need to be enhanced with actual message assignment data
        // For now, using a simplified calculation
        let uniqueReaders = Set(logs.map(\.userId)).count
        return Double(uniqueReaders) / max(Double(uniqueReaders), 1.0) * 100
    }
}

// MARK: - Store Breakdown Card

struct StoreBreakdownCard: View {
    let storeCode: String
    let uniqueMessages: Int
    let uniqueUsers: Int
    let totalReads: Int
    let logs: [MessageReadLog]
    
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
                        
                        Text("\(uniqueMessages) messages • \(uniqueUsers) users • \(totalReads) reads")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .animation(.easeInOut(duration: 0.2), value: isExpanded)
                }
            }
            .buttonStyle(.plain)
            
            // Expanded Details
            if isExpanded {
                VStack(spacing: 8) {
                    HStack {
                        VStack(spacing: 4) {
                            Text("\(uniqueMessages)")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("Messages")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        VStack(spacing: 4) {
                            Text("\(uniqueUsers)")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("Users")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        VStack(spacing: 4) {
                            Text("\(totalReads)")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("Total Reads")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 8)
                    
                    // Recent Activity Timeline
                    RecentActivityTimeline(logs: Array(logs.prefix(5)))
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

// MARK: - User Breakdown Card

struct UserBreakdownCard: View {
    let userId: String
    let uniqueMessages: Int
    let stores: Set<String>
    let totalReads: Int
    let logs: [MessageReadLog]
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("User \(userId)")
                    .font(.body)
                    .fontWeight(.medium)
                
                Text("\(uniqueMessages) messages across \(stores.count) store\(stores.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(totalReads)")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Text("reads")
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

// MARK: - Message Breakdown Card

struct MessageBreakdownCard: View {
    let messageId: String
    let uniqueUsers: Int
    let stores: Set<String>
    let readPercentage: Double
    let logs: [MessageReadLog]
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Message \(messageId.prefix(8))...")
                    .font(.body)
                    .fontWeight(.medium)
                
                Text("\(uniqueUsers) users • \(stores.count) stores")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(readPercentage))%")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(readPercentage >= 80 ? .green : readPercentage >= 50 ? .orange : .red)
                
                Text("read rate")
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

// MARK: - Recent Activity Timeline

struct RecentActivityTimeline: View {
    let logs: [MessageReadLog]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Recent Activity")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            ForEach(logs.sorted { $0.timestamp > $1.timestamp }, id: \.id) { log in
                HStack(spacing: 8) {
                    Circle()
                        .fill(.blue)
                        .frame(width: 6, height: 6)
                    
                    Text("User \(log.userId) read at \(log.formattedTimestamp)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
            }
        }
        .padding(.top, 4)
    }
}

// MARK: - Empty State View

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text(message)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 32)
    }
}
