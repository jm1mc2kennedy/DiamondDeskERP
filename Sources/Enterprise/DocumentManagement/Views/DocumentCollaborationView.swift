//
//  DocumentCollaborationView.swift
//  DiamondDeskERP
//
//  Created by J.Michael McDermott on 7/20/25.
//

import SwiftUI

/// Enterprise Document Collaboration View
/// Provides comprehensive collaboration interface with real-time features
struct DocumentCollaborationView: View {
    
    // MARK: - Properties
    
    let document: DocumentModel
    @StateObject private var collaborationService = DocumentCollaborationService.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    @State private var selectedTab = CollaborationTab.overview
    @State private var showingShareSheet = false
    @State private var showingInviteUsers = false
    @State private var showingComments = false
    @State private var newComment = ""
    @State private var selectedUser: CollaborationUser?
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header Section
                collaborationHeader
                
                // Tab Navigation
                collaborationTabs
                
                // Content Area
                TabView(selection: $selectedTab) {
                    collaborationOverviewView
                        .tag(CollaborationTab.overview)
                    
                    activeUsersView
                        .tag(CollaborationTab.users)
                    
                    commentsView
                        .tag(CollaborationTab.comments)
                    
                    sharingView
                        .tag(CollaborationTab.sharing)
                    
                    analyticsView
                        .tag(CollaborationTab.analytics)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("Collaboration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        showingInviteUsers = true
                    } label: {
                        Image(systemName: "person.badge.plus")
                    }
                    
                    Button {
                        showingShareSheet = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
        .sheet(isPresented: $showingInviteUsers) {
            InviteUsersView(document: document)
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareDocumentView(document: document)
        }
        .alert("Error", isPresented: .constant(collaborationService.error != nil)) {
            Button("OK") {
                collaborationService.error = nil
            }
        } message: {
            Text(collaborationService.error?.localizedDescription ?? "")
        }
        .task {
            await loadCollaborationData()
        }
    }
    
    // MARK: - Collaboration Header
    
    @ViewBuilder
    private var collaborationHeader: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                // Document Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(document.fileType.color.opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: document.fileType.systemImage)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(document.fileType.color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(document.title)
                        .font(.headline.weight(.semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(document.fileName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    HStack(spacing: 12) {
                        // Active collaborators count
                        HStack(spacing: 4) {
                            Image(systemName: "person.2.fill")
                                .font(.caption)
                            Text("\(collaborationService.activeCollaborations.filter { $0.documentId == document.id }.count)")
                                .font(.caption.weight(.medium))
                        }
                        .foregroundColor(.accentColor)
                        
                        // Live status
                        if !collaborationService.documentPresence[document.id]?.isEmpty ?? true {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(.green)
                                    .frame(width: 6, height: 6)
                                Text("Live")
                                    .font(.caption.weight(.medium))
                            }
                            .foregroundColor(.green)
                        }
                    }
                }
                
                Spacer()
                
                // Online users avatars
                activeUserAvatars
            }
            .padding(.horizontal)
            
            Divider()
        }
        .background(Color(UIColor.systemGroupedBackground))
    }
    
    @ViewBuilder
    private var activeUserAvatars: some View {
        HStack(spacing: -8) {
            ForEach(collaborationService.documentPresence[document.id]?.prefix(3) ?? [], id: \.id) { user in
                AsyncImage(url: user.avatar.flatMap(URL.init)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(Color.accentColor.opacity(0.2))
                        .overlay {
                            Text(user.name.prefix(1))
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.accentColor)
                        }
                }
                .frame(width: 32, height: 32)
                .clipShape(Circle())
                .overlay {
                    Circle()
                        .stroke(.white, lineWidth: 2)
                }
            }
            
            if let extraCount = collaborationService.documentPresence[document.id]?.count, extraCount > 3 {
                Circle()
                    .fill(Color(UIColor.tertiarySystemFill))
                    .frame(width: 32, height: 32)
                    .overlay {
                        Text("+\(extraCount - 3)")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.secondary)
                    }
            }
        }
    }
    
    // MARK: - Collaboration Tabs
    
    @ViewBuilder
    private var collaborationTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(CollaborationTab.allCases, id: \.self) { tab in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            selectedTab = tab
                        }
                    } label: {
                        VStack(spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: tab.systemImage)
                                    .font(.subheadline.weight(.medium))
                                
                                Text(tab.title)
                                    .font(.subheadline.weight(.medium))
                                
                                if let count = tab.badgeCount(for: document.id, service: collaborationService) {
                                    Text("\(count)")
                                        .font(.caption.weight(.bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.red)
                                        .clipShape(Capsule())
                                }
                            }
                            .foregroundColor(selectedTab == tab ? .accentColor : .secondary)
                            
                            Rectangle()
                                .fill(selectedTab == tab ? Color.accentColor : Color.clear)
                                .frame(height: 2)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
    }
    
    // MARK: - Tab Content Views
    
    @ViewBuilder
    private var collaborationOverviewView: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Quick Stats
                collaborationStatsGrid
                
                // Recent Activity
                recentActivitySection
                
                // Active Locks
                if !collaborationService.documentLocks.isEmpty {
                    activeLocksSection
                }
                
                // Quick Actions
                quickActionsSection
            }
            .padding()
        }
    }
    
    @ViewBuilder
    private var collaborationStatsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            CollaborationStatCard(
                title: "Active Users",
                value: "\(collaborationService.documentPresence[document.id]?.count ?? 0)",
                icon: "person.2.fill",
                color: .blue
            )
            
            CollaborationStatCard(
                title: "Total Comments",
                value: "\(collaborationService.liveComments[document.id]?.count ?? 0)",
                icon: "bubble.left.fill",
                color: .green
            )
            
            CollaborationStatCard(
                title: "Shares",
                value: "\(collaborationService.sharedDocuments.filter { $0.documentId == document.id }.count)",
                icon: "square.and.arrow.up",
                color: .orange
            )
            
            CollaborationStatCard(
                title: "Live Sessions",
                value: "\(collaborationService.activeCollaborations.filter { $0.documentId == document.id && $0.status == .active }.count)",
                icon: "wifi",
                color: .purple
            )
        }
    }
    
    @ViewBuilder
    private var activeUsersView: some View {
        List {
            Section("Currently Online") {
                ForEach(collaborationService.documentPresence[document.id] ?? [], id: \.id) { user in
                    ActiveUserRow(
                        user: user,
                        collaboration: collaborationService.activeCollaborations.first { 
                            $0.documentId == document.id && $0.userId == user.id 
                        }
                    ) {
                        selectedUser = user
                    }
                }
            }
            
            Section("All Collaborators") {
                ForEach(collaborationService.activeCollaborations.filter { $0.documentId == document.id }, id: \.id) { collaboration in
                    CollaboratorRow(
                        collaboration: collaboration,
                        isOnline: collaborationService.documentPresence[document.id]?.contains { $0.id == collaboration.userId } ?? false
                    )
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
    }
    
    @ViewBuilder
    private var commentsView: some View {
        VStack(spacing: 0) {
            // Comments List
            List {
                ForEach(collaborationService.liveComments[document.id] ?? [], id: \.id) { comment in
                    CommentRow(
                        comment: comment,
                        currentUserId: getCurrentUserId()
                    )
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }
            }
            .listStyle(PlainListStyle())
            
            // Comment Input
            commentInputView
        }
    }
    
    @ViewBuilder
    private var commentInputView: some View {
        VStack(spacing: 12) {
            Divider()
            
            HStack(spacing: 12) {
                TextField("Add a comment...", text: $newComment, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .lineLimit(1...4)
                
                Button {
                    Task {
                        await addComment()
                    }
                } label: {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.white)
                        .padding(8)
                        .background(newComment.isEmpty ? Color.gray : Color.accentColor)
                        .clipShape(Circle())
                }
                .disabled(newComment.isEmpty)
            }
            .padding()
        }
        .background(Color(UIColor.systemGroupedBackground))
    }
    
    @ViewBuilder
    private var sharingView: some View {
        List {
            Section("Active Shares") {
                ForEach(collaborationService.sharedDocuments.filter { $0.documentId == document.id }, id: \.id) { share in
                    SharedDocumentRow(sharedDocument: share)
                }
            }
            
            Section("Share Settings") {
                shareSettingsRows
            }
        }
        .listStyle(InsetGroupedListStyle())
    }
    
    @ViewBuilder
    private var shareSettingsRows: some View {
        Button {
            showingInviteUsers = true
        } label: {
            Label("Invite Users", systemImage: "person.badge.plus")
        }
        
        Button {
            showingShareSheet = true
        } label: {
            Label("Share Link", systemImage: "link")
        }
        
        Button {
            Task {
                await createPublicShare()
            }
        } label: {
            Label("Create Public Link", systemImage: "globe")
        }
    }
    
    @ViewBuilder
    private var analyticsView: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                if let metrics = collaborationService.collaborationMetrics {
                    CollaborationAnalyticsView(metrics: metrics)
                } else {
                    ProgressView("Loading analytics...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .padding()
        }
        .task {
            await loadAnalytics()
        }
    }
    
    @ViewBuilder
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activity")
                .font(.headline.weight(.semibold))
            
            VStack(spacing: 8) {
                // Mock recent activities - in real implementation, this would come from service
                ActivityRow(
                    icon: "person.badge.plus",
                    title: "John Doe joined collaboration",
                    timestamp: Date().addingTimeInterval(-300),
                    color: .green
                )
                
                ActivityRow(
                    icon: "bubble.left.fill",
                    title: "New comment added",
                    timestamp: Date().addingTimeInterval(-600),
                    color: .blue
                )
                
                ActivityRow(
                    icon: "square.and.arrow.up",
                    title: "Document shared with team",
                    timestamp: Date().addingTimeInterval(-1200),
                    color: .orange
                )
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    @ViewBuilder
    private var activeLocksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Active Locks")
                .font(.headline.weight(.semibold))
            
            VStack(spacing: 8) {
                ForEach(collaborationService.documentLocks.values.filter { $0.documentId == document.id && $0.isActive }, id: \.id) { lock in
                    LockRow(lock: lock)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    @ViewBuilder
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline.weight(.semibold))
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                QuickActionButton(
                    title: "Start Video Call",
                    icon: "video.fill",
                    color: .blue
                ) {
                    // Start video call
                }
                
                QuickActionButton(
                    title: "Create Meeting",
                    icon: "calendar.badge.plus",
                    color: .green
                ) {
                    // Create meeting
                }
                
                QuickActionButton(
                    title: "Send Message",
                    icon: "message.fill",
                    color: .purple
                ) {
                    // Send message
                }
                
                QuickActionButton(
                    title: "Schedule Review",
                    icon: "clock.badge.checkmark",
                    color: .orange
                ) {
                    // Schedule review
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Actions
    
    private func loadCollaborationData() async {
        do {
            try await collaborationService.joinDocumentSession(documentId: document.id)
        } catch {
            print("Failed to join collaboration session: \(error)")
        }
    }
    
    private func addComment() async {
        guard !newComment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        do {
            _ = try await collaborationService.addDocumentComment(
                documentId: document.id,
                content: newComment
            )
            newComment = ""
        } catch {
            print("Failed to add comment: \(error)")
        }
    }
    
    private func createPublicShare() async {
        // Implementation for creating public share
    }
    
    private func loadAnalytics() async {
        do {
            try await collaborationService.loadCollaborationMetrics()
        } catch {
            print("Failed to load analytics: \(error)")
        }
    }
    
    private func getCurrentUserId() -> String {
        return "current-user-id" // Replace with actual user ID
    }
}

// MARK: - Supporting Views

struct CollaborationStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2.weight(.bold))
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct ActiveUserRow: View {
    let user: CollaborationUser
    let collaboration: DocumentCollaboration?
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                AsyncImage(url: user.avatar.flatMap(URL.init)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(Color.accentColor.opacity(0.2))
                        .overlay {
                            Text(user.name.prefix(1))
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.accentColor)
                        }
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
                .overlay(alignment: .bottomTrailing) {
                    Circle()
                        .fill(.green)
                        .frame(width: 12, height: 12)
                        .overlay {
                            Circle()
                                .stroke(.white, lineWidth: 2)
                        }
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(user.name)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.primary)
                    
                    Text(collaboration?.role.displayName ?? "Viewer")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Circle()
                        .fill(.green)
                        .frame(width: 8, height: 8)
                    
                    Text("Online")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CollaboratorRow: View {
    let collaboration: DocumentCollaboration
    let isOnline: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.accentColor.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay {
                    Text("U")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.accentColor)
                }
                .overlay(alignment: .bottomTrailing) {
                    if isOnline {
                        Circle()
                            .fill(.green)
                            .frame(width: 12, height: 12)
                            .overlay {
                                Circle()
                                    .stroke(.white, lineWidth: 2)
                            }
                    }
                }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("User \(collaboration.userId)")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.primary)
                
                Text(collaboration.role.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(isOnline ? "Online" : "Offline")
                    .font(.caption.weight(.medium))
                    .foregroundColor(isOnline ? .green : .secondary)
                
                Text(collaboration.lastActiveAt.formatted(.relative(presentation: .numeric)))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct CommentRow: View {
    let comment: DocumentComment
    let currentUserId: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.accentColor.opacity(0.2))
                    .frame(width: 32, height: 32)
                    .overlay {
                        Text(comment.authorName.prefix(1))
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.accentColor)
                    }
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(comment.authorName)
                            .font(.subheadline.weight(.medium))
                        
                        if comment.isEdited {
                            Text("• edited")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text(comment.createdAt.formatted(.relative(presentation: .numeric)))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(comment.content)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
}

struct SharedDocumentRow: View {
    let sharedDocument: SharedDocument
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Shared with \(sharedDocument.recipients.count) users")
                        .font(.subheadline.weight(.medium))
                    
                    Text(sharedDocument.createdAt.formatted(.dateTime.month().day().hour().minute()))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(sharedDocument.status.displayName)
                    .font(.caption.weight(.medium))
                    .foregroundColor(sharedDocument.status == .active ? .green : .secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(sharedDocument.status == .active ? Color.green.opacity(0.1) : Color.gray.opacity(0.1))
                    .clipShape(Capsule())
            }
            
            if !sharedDocument.recipients.isEmpty {
                HStack(spacing: -4) {
                    ForEach(sharedDocument.recipients.prefix(3), id: \.id) { user in
                        Circle()
                            .fill(Color.accentColor.opacity(0.2))
                            .frame(width: 24, height: 24)
                            .overlay {
                                Text(user.name.prefix(1))
                                    .font(.caption2.weight(.semibold))
                                    .foregroundColor(.accentColor)
                            }
                    }
                    
                    if sharedDocument.recipients.count > 3 {
                        Text("+\(sharedDocument.recipients.count - 3)")
                            .font(.caption2.weight(.semibold))
                            .foregroundColor(.secondary)
                            .padding(.leading, 8)
                    }
                }
            }
        }
    }
}

struct ActivityRow: View {
    let icon: String
    let title: String
    let timestamp: Date
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Text(timestamp.formatted(.relative(presentation: .numeric)))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct LockRow: View {
    let lock: DocumentLock
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "lock.fill")
                .foregroundColor(.orange)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Section locked by \(lock.userName)")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Text("Expires \(lock.expiresAt.formatted(.relative(presentation: .numeric)))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption.weight(.medium))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(UIColor.tertiarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Supporting Types

enum CollaborationTab: String, CaseIterable {
    case overview
    case users
    case comments
    case sharing
    case analytics
    
    var title: String {
        switch self {
        case .overview: return "Overview"
        case .users: return "Users"
        case .comments: return "Comments"
        case .sharing: return "Sharing"
        case .analytics: return "Analytics"
        }
    }
    
    var systemImage: String {
        switch self {
        case .overview: return "chart.bar.fill"
        case .users: return "person.2.fill"
        case .comments: return "bubble.left.fill"
        case .sharing: return "square.and.arrow.up"
        case .analytics: return "chart.line.uptrend.xyaxis"
        }
    }
    
    func badgeCount(for documentId: String, service: DocumentCollaborationService) -> Int? {
        switch self {
        case .comments:
            let count = service.liveComments[documentId]?.count ?? 0
            return count > 0 ? count : nil
        case .users:
            let count = service.documentPresence[documentId]?.count ?? 0
            return count > 0 ? count : nil
        default:
            return nil
        }
    }
}

// MARK: - Preview

#Preview {
    DocumentCollaborationView(
        document: DocumentModel(
            id: "1",
            title: "Q4 Financial Report",
            fileName: "Q4_Report.pdf",
            fileType: .pdf,
            category: .financial,
            accessLevel: .internal,
            size: 2048000,
            createdAt: Date(),
            modifiedAt: Date(),
            tags: ["financial", "quarterly", "2024"],
            description: "Quarterly financial analysis and projections"
        )
    )
}
