//
//  InviteUsersView.swift
//  DiamondDeskERP
//
//  Created by J.Michael McDermott on 7/20/25.
//

import SwiftUI

/// Invite Users to Document Collaboration View
/// Provides interface for inviting users to collaborate on documents
struct InviteUsersView: View {
    
    // MARK: - Properties
    
    let document: DocumentModel
    @StateObject private var collaborationService = DocumentCollaborationService.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchText = ""
    @State private var selectedUsers: Set<CollaborationUser> = []
    @State private var selectedRole: CollaborationRole = .viewer
    @State private var invitationMessage = ""
    @State private var expirationOption: ExpirationOption = .never
    @State private var customExpirationDate = Date().addingTimeInterval(604800) // 1 week
    @State private var isLoading = false
    
    // Mock users - in real implementation, this would come from user service
    @State private var availableUsers: [CollaborationUser] = [
        CollaborationUser(id: "1", name: "John Doe", email: "john@example.com", avatar: nil, isOnline: true, lastSeen: Date(), currentDocument: nil, cursorPosition: nil),
        CollaborationUser(id: "2", name: "Jane Smith", email: "jane@example.com", avatar: nil, isOnline: false, lastSeen: Date().addingTimeInterval(-3600), currentDocument: nil, cursorPosition: nil),
        CollaborationUser(id: "3", name: "Mike Johnson", email: "mike@example.com", avatar: nil, isOnline: true, lastSeen: Date(), currentDocument: nil, cursorPosition: nil),
        CollaborationUser(id: "4", name: "Sarah Wilson", email: "sarah@example.com", avatar: nil, isOnline: false, lastSeen: Date().addingTimeInterval(-7200), currentDocument: nil, cursorPosition: nil)
    ]
    
    // MARK: - Computed Properties
    
    private var filteredUsers: [CollaborationUser] {
        if searchText.isEmpty {
            return availableUsers
        } else {
            return availableUsers.filter { user in
                user.name.localizedCaseInsensitiveContains(searchText) ||
                user.email.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    private var canSendInvitations: Bool {
        !selectedUsers.isEmpty && !isLoading
    }
    
    private var expirationDate: Date? {
        switch expirationOption {
        case .never: return nil
        case .oneDay: return Date().addingTimeInterval(86400)
        case .oneWeek: return Date().addingTimeInterval(604800)
        case .oneMonth: return Date().addingTimeInterval(2592000)
        case .custom: return customExpirationDate
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar
                searchSection
                
                // Role Selection
                roleSelectionSection
                
                // Users List
                usersList
                
                // Invitation Options
                invitationOptionsSection
                
                // Send Button
                sendInvitationsButton
            }
            .navigationTitle("Invite Users")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Error", isPresented: .constant(collaborationService.error != nil)) {
            Button("OK") {
                collaborationService.error = nil
            }
        } message: {
            Text(collaborationService.error?.localizedDescription ?? "")
        }
    }
    
    // MARK: - Search Section
    
    @ViewBuilder
    private var searchSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search users...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
            }
            .padding()
            .background(Color(UIColor.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
            
            if !selectedUsers.isEmpty {
                selectedUsersPreview
            }
        }
        .padding(.top)
    }
    
    @ViewBuilder
    private var selectedUsersPreview: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Array(selectedUsers), id: \.id) { user in
                    SelectedUserChip(user: user) {
                        selectedUsers.remove(user)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Role Selection Section
    
    @ViewBuilder
    private var roleSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Role for Invited Users")
                .font(.headline.weight(.medium))
                .padding(.horizontal)
            
            Picker("Role", selection: $selectedRole) {
                ForEach(CollaborationRole.allCases, id: \.self) { role in
                    Text(role.displayName).tag(role)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            
            Text(roleDescription)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)
        }
        .padding(.vertical)
    }
    
    private var roleDescription: String {
        switch selectedRole {
        case .viewer:
            return "Can view and download the document"
        case .commenter:
            return "Can view, download, and add comments"
        case .editor:
            return "Can view, download, edit, and comment on the document"
        case .admin:
            return "Full access including sharing and deletion permissions"
        }
    }
    
    // MARK: - Users List
    
    @ViewBuilder
    private var usersList: some View {
        List {
            ForEach(filteredUsers, id: \.id) { user in
                UserInviteRow(
                    user: user,
                    isSelected: selectedUsers.contains(user)
                ) {
                    if selectedUsers.contains(user) {
                        selectedUsers.remove(user)
                    } else {
                        selectedUsers.insert(user)
                    }
                }
            }
        }
        .listStyle(PlainListStyle())
    }
    
    // MARK: - Invitation Options Section
    
    @ViewBuilder
    private var invitationOptionsSection: some View {
        VStack(spacing: 16) {
            Divider()
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Invitation Options")
                    .font(.headline.weight(.medium))
                
                // Personal Message
                VStack(alignment: .leading, spacing: 8) {
                    Text("Personal Message (Optional)")
                        .font(.subheadline.weight(.medium))
                    
                    TextField("Add a personal message...", text: $invitationMessage, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(1...3)
                }
                
                // Expiration
                VStack(alignment: .leading, spacing: 8) {
                    Text("Access Expiration")
                        .font(.subheadline.weight(.medium))
                    
                    Picker("Expiration", selection: $expirationOption) {
                        ForEach(ExpirationOption.allCases, id: \.self) { option in
                            Text(option.displayName).tag(option)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    
                    if expirationOption == .custom {
                        DatePicker(
                            "Expiration Date",
                            selection: $customExpirationDate,
                            in: Date()...,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .datePickerStyle(CompactDatePickerStyle())
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Send Invitations Button
    
    @ViewBuilder
    private var sendInvitationsButton: some View {
        VStack(spacing: 16) {
            Divider()
            
            Button {
                Task {
                    await sendInvitations()
                }
            } label: {
                HStack {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: "paperplane.fill")
                    }
                    
                    Text(isLoading ? "Sending..." : "Send \(selectedUsers.count) Invitation\(selectedUsers.count == 1 ? "" : "s")")
                        .font(.headline.weight(.semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(canSendInvitations ? Color.accentColor : Color.gray)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(!canSendInvitations)
            .padding(.horizontal)
        }
        .background(Color(UIColor.systemGroupedBackground))
    }
    
    // MARK: - Actions
    
    private func sendInvitations() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            for user in selectedUsers {
                _ = try await collaborationService.createDocumentShare(
                    documentId: document.id,
                    recipients: [user],
                    permissions: selectedRole.permissions,
                    expirationDate: expirationDate,
                    message: invitationMessage.isEmpty ? nil : invitationMessage
                )
            }
            
            dismiss()
            
        } catch {
            print("Failed to send invitations: \(error)")
        }
    }
}

// MARK: - Supporting Views

struct SelectedUserChip: View {
    let user: CollaborationUser
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 6) {
            AsyncImage(url: user.avatar.flatMap(URL.init)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(Color.accentColor.opacity(0.2))
                    .overlay {
                        Text(user.name.prefix(1))
                            .font(.caption2.weight(.semibold))
                            .foregroundColor(.accentColor)
                    }
            }
            .frame(width: 20, height: 20)
            .clipShape(Circle())
            
            Text(user.name)
                .font(.caption.weight(.medium))
                .lineLimit(1)
            
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.caption2.weight(.bold))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(Capsule())
    }
}

struct UserInviteRow: View {
    let user: CollaborationUser
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                // Selection Indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .accentColor : .secondary)
                    .font(.title3)
                
                // User Avatar
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
                    if user.isOnline {
                        Circle()
                            .fill(.green)
                            .frame(width: 12, height: 12)
                            .overlay {
                                Circle()
                                    .stroke(.white, lineWidth: 2)
                            }
                    }
                }
                
                // User Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(user.name)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.primary)
                    
                    Text(user.email)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Online Status
                if user.isOnline {
                    Text("Online")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.1))
                        .clipShape(Capsule())
                } else {
                    Text("Last seen \(user.lastSeen.formatted(.relative(presentation: .numeric)))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Supporting Types

enum ExpirationOption: String, CaseIterable {
    case never
    case oneDay
    case oneWeek
    case oneMonth
    case custom
    
    var displayName: String {
        switch self {
        case .never: return "Never"
        case .oneDay: return "1 Day"
        case .oneWeek: return "1 Week"
        case .oneMonth: return "1 Month"
        case .custom: return "Custom"
        }
    }
}

// MARK: - Preview

#Preview {
    InviteUsersView(
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
