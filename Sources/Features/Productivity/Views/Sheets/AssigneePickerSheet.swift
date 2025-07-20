//
//  AssigneePickerSheet.swift
//  DiamondDeskERP
//
//  Created by AI Assistant on 7/20/25.
//

import SwiftUI

struct AssigneePickerSheet: View {
    let projectBoardId: String
    @Binding var selectedAssignees: Set<String>
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AssigneePickerViewModel()
    
    @State private var searchText = ""
    @State private var showingAllUsers = false
    
    var body: some View {
        NavigationStack {
            VStack {
                if viewModel.isLoading {
                    loadingView
                } else {
                    assigneeContent
                }
            }
            .navigationTitle("Assign Team Members")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search team members...")
            .onAppear {
                loadAssignees()
            }
        }
    }
    
    // MARK: - Content Views
    
    private var assigneeContent: some View {
        List {
            if !selectedAssignees.isEmpty {
                selectedSection
            }
            
            availableSection
            
            if !showingAllUsers && viewModel.allUsers.count > viewModel.boardMembers.count {
                allUsersSection
            }
        }
        .listStyle(.insetGrouped)
    }
    
    private var selectedSection: some View {
        Section {
            ForEach(Array(selectedAssignees), id: \.self) { assigneeId in
                if let member = viewModel.memberById(assigneeId) {
                    AssigneeRow(
                        member: member,
                        isSelected: true,
                        showRole: true
                    ) {
                        selectedAssignees.remove(assigneeId)
                    }
                }
            }
        } header: {
            Text("Selected (\(selectedAssignees.count))")
        }
    }
    
    private var availableSection: some View {
        Section {
            ForEach(filteredBoardMembers, id: \.id) { member in
                AssigneeRow(
                    member: member,
                    isSelected: selectedAssignees.contains(member.id),
                    showRole: true
                ) {
                    toggleSelection(member.id)
                }
            }
            
            if filteredBoardMembers.isEmpty && !searchText.isEmpty {
                Text("No board members found")
                    .foregroundColor(.secondary)
                    .italic()
            }
        } header: {
            Text("Board Members")
        }
    }
    
    private var allUsersSection: some View {
        Section {
            Button("Show All Organization Members") {
                showingAllUsers = true
                Task {
                    await viewModel.loadAllUsers()
                }
            }
            .foregroundColor(.accentColor)
            
            if showingAllUsers {
                ForEach(filteredAllUsers, id: \.id) { user in
                    AssigneeRow(
                        member: user,
                        isSelected: selectedAssignees.contains(user.id),
                        showRole: false
                    ) {
                        toggleSelection(user.id)
                    }
                }
            }
        } header: {
            if showingAllUsers {
                Text("All Organization Members")
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading team members...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Computed Properties
    
    private var filteredBoardMembers: [TeamMember] {
        if searchText.isEmpty {
            return viewModel.boardMembers
        } else {
            return viewModel.boardMembers.filter { member in
                member.name.localizedCaseInsensitiveContains(searchText) ||
                member.email.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    private var filteredAllUsers: [TeamMember] {
        let nonBoardMembers = viewModel.allUsers.filter { user in
            !viewModel.boardMembers.contains { $0.id == user.id }
        }
        
        if searchText.isEmpty {
            return nonBoardMembers
        } else {
            return nonBoardMembers.filter { user in
                user.name.localizedCaseInsensitiveContains(searchText) ||
                user.email.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    // MARK: - Actions
    
    private func toggleSelection(_ memberId: String) {
        if selectedAssignees.contains(memberId) {
            selectedAssignees.remove(memberId)
        } else {
            selectedAssignees.insert(memberId)
        }
    }
    
    private func loadAssignees() {
        Task {
            await viewModel.loadBoardMembers(for: projectBoardId)
        }
    }
}

// MARK: - Assignee Row

struct AssigneeRow: View {
    let member: TeamMember
    let isSelected: Bool
    let showRole: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                // Avatar
                AsyncImage(url: member.avatarUrl.flatMap(URL.init)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(Color.accentColor)
                        .overlay {
                            Text(member.initials)
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
                
                // Member Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(member.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(member.email)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if showRole {
                        Text(member.role.displayName)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(member.role.color.opacity(0.2))
                            .foregroundColor(member.role.color)
                            .clipShape(Capsule())
                    }
                }
                
                Spacer()
                
                // Selection Indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.accentColor)
                } else {
                    Image(systemName: "circle")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(member.name), \(member.email)")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

// MARK: - Assignee Picker ViewModel

@MainActor
class AssigneePickerViewModel: ObservableObject {
    @Published var boardMembers: [TeamMember] = []
    @Published var allUsers: [TeamMember] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func loadBoardMembers(for projectBoardId: String) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // In real implementation, fetch board members
            boardMembers = try await fetchBoardMembers(for: projectBoardId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func loadAllUsers() async {
        do {
            allUsers = try await fetchAllOrganizationUsers()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func memberById(_ id: String) -> TeamMember? {
        boardMembers.first { $0.id == id } ?? allUsers.first { $0.id == id }
    }
    
    // MARK: - Mock Data
    
    private func fetchBoardMembers(for projectBoardId: String) async throws -> [TeamMember] {
        // Mock implementation - replace with actual API call
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
        
        return [
            TeamMember(
                id: "user1",
                name: "John Doe",
                email: "john.doe@company.com",
                role: .owner,
                avatarUrl: nil
            ),
            TeamMember(
                id: "user2",
                name: "Jane Smith",
                email: "jane.smith@company.com",
                role: .editor,
                avatarUrl: nil
            ),
            TeamMember(
                id: "user3",
                name: "Mike Johnson",
                email: "mike.johnson@company.com",
                role: .viewer,
                avatarUrl: nil
            )
        ]
    }
    
    private func fetchAllOrganizationUsers() async throws -> [TeamMember] {
        // Mock implementation - replace with actual API call
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
        
        return [
            TeamMember(
                id: "user4",
                name: "Sarah Wilson",
                email: "sarah.wilson@company.com",
                role: .editor,
                avatarUrl: nil
            ),
            TeamMember(
                id: "user5",
                name: "David Brown",
                email: "david.brown@company.com",
                role: .viewer,
                avatarUrl: nil
            ),
            TeamMember(
                id: "user6",
                name: "Emily Davis",
                email: "emily.davis@company.com",
                role: .editor,
                avatarUrl: nil
            )
        ]
    }
}

// MARK: - Extensions

extension TeamMember {
    var initials: String {
        let components = name.components(separatedBy: " ")
        let firstInitial = components.first?.prefix(1).uppercased() ?? ""
        let lastInitial = components.count > 1 ? components.last?.prefix(1).uppercased() ?? "" : ""
        return firstInitial + lastInitial
    }
}

extension ProjectMemberRole {
    var displayName: String {
        switch self {
        case .owner: return "Owner"
        case .editor: return "Editor"
        case .viewer: return "Viewer"
        }
    }
    
    var color: Color {
        switch self {
        case .owner: return .purple
        case .editor: return .blue
        case .viewer: return .green
        }
    }
}

#Preview {
    AssigneePickerSheet(
        projectBoardId: "board1",
        selectedAssignees: .constant(Set(["user1", "user2"]))
    )
}
