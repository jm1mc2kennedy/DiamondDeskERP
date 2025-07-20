//
//  UserAssignmentView.swift
//  DiamondDeskERP
//
//  Created by AI Assistant on 7/20/25.
//

import SwiftUI

/// User role assignment management interface
struct UserAssignmentView: View {
    @StateObject private var viewModel = UserAssignmentViewModel()
    @State private var selectedTab: AssignmentTab = .assignments
    
    var body: some View {
        NavigationStack {
            VStack {
                // Stats Header
                AssignmentStatsView(stats: viewModel.assignmentStats)
                    .padding(.horizontal)
                
                // Tab Selector
                Picker("View", selection: $selectedTab) {
                    ForEach(AssignmentTab.allCases, id: \.self) { tab in
                        Text(tab.title).tag(tab)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // Main Content
                TabView(selection: $selectedTab) {
                    AssignmentListView(viewModel: viewModel)
                        .tag(AssignmentTab.assignments)
                    
                    UserListView(viewModel: viewModel)
                        .tag(AssignmentTab.users)
                    
                    BulkOperationsView(viewModel: viewModel)
                        .tag(AssignmentTab.bulk)
                    
                    AssignmentAnalyticsView(viewModel: viewModel)
                        .tag(AssignmentTab.analytics)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("User Assignments")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { viewModel.showingAssignmentForm = true }) {
                            Label("Assign Role", systemImage: "person.badge.plus")
                        }
                        
                        Button(action: { viewModel.showingBulkAssignment = true }) {
                            Label("Bulk Assignment", systemImage: "person.2.badge.plus")
                        }
                        
                        Divider()
                        
                        Button(action: { viewModel.showingImportSheet = true }) {
                            Label("Import Assignments", systemImage: "square.and.arrow.down")
                        }
                        
                        Button(action: { 
                            if let url = viewModel.exportAssignments() {
                                viewModel.showingExportSheet = true
                            }
                        }) {
                            Label("Export Assignments", systemImage: "square.and.arrow.up")
                        }
                    } label: {
                        Image(systemName: "plus.circle")
                    }
                    
                    Button(action: viewModel.loadData) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
        .sheet(isPresented: $viewModel.showingAssignmentForm) {
            AssignmentFormView(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showingBulkAssignment) {
            BulkAssignmentView(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showingUserDetail) {
            if let selectedUser = viewModel.selectedUser {
                UserDetailView(user: selectedUser, viewModel: viewModel)
            }
        }
        .alert("Revoke Assignment", isPresented: $viewModel.showingRevokeConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Revoke", role: .destructive) {
                if let assignment = viewModel.selectedAssignmentsList.first {
                    viewModel.revokeAssignment(assignment)
                }
            }
        } message: {
            Text("Are you sure you want to revoke this role assignment?")
        }
        .alert("Bulk Revoke", isPresented: $viewModel.showingBulkRevoke) {
            Button("Cancel", role: .cancel) { }
            Button("Revoke All", role: .destructive) {
                viewModel.bulkRevokeAssignments()
            }
        } message: {
            Text("Are you sure you want to revoke \(viewModel.selectedAssignments.count) assignments?")
        }
        .alert("Error", isPresented: $viewModel.showingError) {
            Button("OK") { }
        } message: {
            if let error = viewModel.error {
                Text(error.localizedDescription)
            }
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView("Loading...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.1))
            }
        }
    }
}

// MARK: - Assignment Tabs

enum AssignmentTab: CaseIterable {
    case assignments, users, bulk, analytics
    
    var title: String {
        switch self {
        case .assignments: return "Assignments"
        case .users: return "Users"
        case .bulk: return "Bulk Ops"
        case .analytics: return "Analytics"
        }
    }
}

// MARK: - Assignment Stats View

struct AssignmentStatsView: View {
    let stats: AssignmentStats
    
    var body: some View {
        HStack(spacing: 20) {
            StatCardView(
                title: "Total",
                value: "\(stats.total)",
                color: .blue
            )
            
            StatCardView(
                title: "Active",
                value: "\(stats.active)",
                subtitle: "\(String(format: "%.1f", stats.activePercentage))%",
                color: .green
            )
            
            StatCardView(
                title: "Expired",
                value: "\(stats.expired)",
                subtitle: "\(String(format: "%.1f", stats.expiredPercentage))%",
                color: .orange
            )
            
            StatCardView(
                title: "Pending",
                value: "\(stats.pending)",
                color: .purple
            )
        }
        .padding(.vertical, 8)
    }
}

struct StatCardView: View {
    let title: String
    let value: String
    let subtitle: String?
    let color: Color
    
    init(title: String, value: String, subtitle: String? = nil, color: Color) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.color = color
    }
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Assignment List View

struct AssignmentListView: View {
    @ObservedObject var viewModel: UserAssignmentViewModel
    
    var body: some View {
        VStack {
            // Filters
            AssignmentFiltersView(viewModel: viewModel)
                .padding(.horizontal)
            
            // Assignment List
            List {
                ForEach(viewModel.filteredAssignments, id: \.id) { assignment in
                    AssignmentRowView(assignment: assignment, viewModel: viewModel)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            if viewModel.canRevokeRoles {
                                Button("Revoke") {
                                    viewModel.revokeAssignment(assignment)
                                }
                                .tint(.red)
                            }
                            
                            Button("Extend") {
                                // Show date picker for extension
                            }
                            .tint(.orange)
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            Button("Details") {
                                if let user = viewModel.users.first(where: { $0.userId == assignment.userId }) {
                                    viewModel.selectedUser = user
                                    viewModel.showingUserDetail = true
                                }
                            }
                            .tint(.blue)
                        }
                }
            }
            .refreshable {
                viewModel.loadData()
            }
        }
        .searchable(text: $viewModel.searchText, prompt: "Search assignments...")
    }
}

// MARK: - Assignment Row View

struct AssignmentRowView: View {
    let assignment: UserRoleAssignment
    @ObservedObject var viewModel: UserAssignmentViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.getUserName(for: assignment.userId))
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(viewModel.getRoleName(for: assignment.roleId))
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    StatusBadgeView(assignment: assignment)
                    
                    Text(assignment.assignedAt.formatted(.relative(presentation: .named)))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Scope and Details
            HStack {
                Label(viewModel.getScopeDisplayName(assignment.scope), systemImage: scopeIcon(assignment.scope))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if !assignment.scopeValues.isEmpty {
                    Text("• \(viewModel.formatScopeValues(assignment.scopeValues, for: assignment.scope))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                if let validUntil = assignment.validUntil {
                    Label(validUntil.formatted(.relative(presentation: .named)), systemImage: "calendar")
                        .font(.caption)
                        .foregroundColor(assignment.isExpired ? .red : .orange)
                }
            }
            
            // Assignment Details
            if let reason = assignment.reason, !reason.isEmpty {
                HStack {
                    Image(systemName: "quote.bubble")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(reason)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .italic()
                }
            }
        }
        .padding(.vertical, 4)
        .contextMenu {
            Button(action: {
                if let user = viewModel.users.first(where: { $0.userId == assignment.userId }) {
                    viewModel.selectedUser = user
                    viewModel.showingUserDetail = true
                }
            }) {
                Label("View User", systemImage: "person.circle")
            }
            
            if viewModel.canRevokeRoles {
                Button(action: { viewModel.revokeAssignment(assignment) }) {
                    Label("Revoke", systemImage: "person.badge.minus")
                }
            }
            
            Button(action: {
                let calendar = Calendar.current
                let futureDate = calendar.date(byAdding: .month, value: 1, to: Date()) ?? Date()
                viewModel.extendAssignment(assignment, until: futureDate)
            }) {
                Label("Extend 1 Month", systemImage: "calendar.badge.plus")
            }
        }
    }
    
    private func scopeIcon(_ scope: UserRoleAssignment.AssignmentScope) -> String {
        switch scope {
        case .organization: return "building.2"
        case .department: return "person.2"
        case .project: return "folder"
        case .personal: return "person"
        }
    }
}

// MARK: - Status Badge View

struct StatusBadgeView: View {
    let assignment: UserRoleAssignment
    
    var body: some View {
        Text(statusText)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(statusColor.opacity(0.2))
            .foregroundColor(statusColor)
            .cornerRadius(4)
    }
    
    private var statusText: String {
        if !assignment.isActive {
            return "Inactive"
        } else if assignment.isExpired {
            return "Expired"
        } else {
            return "Active"
        }
    }
    
    private var statusColor: Color {
        if !assignment.isActive {
            return .gray
        } else if assignment.isExpired {
            return .red
        } else {
            return .green
        }
    }
}

// MARK: - Assignment Filters View

struct AssignmentFiltersView: View {
    @ObservedObject var viewModel: UserAssignmentViewModel
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // Role Filter
                Menu {
                    Button("All Roles") {
                        viewModel.selectedRoleFilter = nil
                    }
                    
                    ForEach(viewModel.roles, id: \.id) { role in
                        Button(role.displayName) {
                            viewModel.selectedRoleFilter = role.id
                        }
                    }
                } label: {
                    FilterChipView(
                        title: viewModel.selectedRoleFilter != nil ? "Role: \(viewModel.getRoleName(for: viewModel.selectedRoleFilter!))" : "All Roles",
                        isActive: viewModel.selectedRoleFilter != nil
                    )
                }
                
                // Scope Filter
                Menu {
                    Button("All Scopes") {
                        viewModel.selectedScopeFilter = nil
                    }
                    
                    ForEach(viewModel.availableScopes, id: \.self) { scope in
                        Button(viewModel.getScopeDisplayName(scope)) {
                            viewModel.selectedScopeFilter = scope
                        }
                    }
                } label: {
                    FilterChipView(
                        title: viewModel.selectedScopeFilter != nil ? "Scope: \(viewModel.getScopeDisplayName(viewModel.selectedScopeFilter!))" : "All Scopes",
                        isActive: viewModel.selectedScopeFilter != nil
                    )
                }
                
                // Status Filters
                FilterChipView(
                    title: "Active Only",
                    isActive: viewModel.showActiveOnly
                ) {
                    viewModel.showActiveOnly.toggle()
                }
                
                FilterChipView(
                    title: "Show Expired",
                    isActive: viewModel.showExpiredAssignments
                ) {
                    viewModel.showExpiredAssignments.toggle()
                }
            }
            .padding(.horizontal)
        }
    }
}

struct FilterChipView: View {
    let title: String
    let isActive: Bool
    let action: (() -> Void)?
    
    init(title: String, isActive: Bool, action: (() -> Void)? = nil) {
        self.title = title
        self.isActive = isActive
        self.action = action
    }
    
    var body: some View {
        Button(action: action ?? {}) {
            Text(title)
                .font(.caption)
                .fontWeight(isActive ? .medium : .regular)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isActive ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                .foregroundColor(isActive ? .blue : .primary)
                .cornerRadius(16)
        }
        .disabled(action == nil)
    }
}

// MARK: - User List View

struct UserListView: View {
    @ObservedObject var viewModel: UserAssignmentViewModel
    
    var body: some View {
        List {
            ForEach(viewModel.filteredUsers, id: \.userId) { user in
                UserRowView(user: user, viewModel: viewModel)
                    .onTapGesture {
                        viewModel.selectUser(user)
                        viewModel.showingUserDetail = true
                    }
            }
        }
        .searchable(text: $viewModel.searchText, prompt: "Search users...")
        .refreshable {
            viewModel.loadData()
        }
    }
}

// MARK: - User Row View

struct UserRowView: View {
    let user: UserProfile
    @ObservedObject var viewModel: UserAssignmentViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                AsyncImage(url: URL(string: user.avatarURL ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(.gray)
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(user.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(user.email)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    let assignments = viewModel.getUserAssignments(user.userId)
                    Text("\(assignments.count) roles")
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    if user.isActive {
                        Text("Active")
                            .font(.caption)
                            .foregroundColor(.green)
                    } else {
                        Text("Inactive")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
            
            // Role Summary
            let userRoles = viewModel.getUserEffectiveRoles(user.userId)
            if !userRoles.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(userRoles.prefix(3), id: \.id) { role in
                            Text(role.displayName)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.2))
                                .foregroundColor(.blue)
                                .cornerRadius(3)
                        }
                        
                        if userRoles.count > 3 {
                            Text("+\(userRoles.count - 3)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .contextMenu {
            Button(action: {
                viewModel.selectUser(user)
                viewModel.showingAssignmentForm = true
            }) {
                Label("Assign Role", systemImage: "person.badge.plus")
            }
            
            Button(action: {
                viewModel.selectUser(user)
                viewModel.showingUserDetail = true
            }) {
                Label("View Details", systemImage: "info.circle")
            }
        }
    }
}

// MARK: - Assignment Form View

struct AssignmentFormView: View {
    @ObservedObject var viewModel: UserAssignmentViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section("User") {
                    if viewModel.selectedUser != nil {
                        HStack {
                            Text(viewModel.selectedUser!.displayName)
                            Spacer()
                            Text(viewModel.selectedUser!.email)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Picker("Select User", selection: $viewModel.assignmentUserId) {
                            Text("Choose User").tag("")
                            
                            ForEach(viewModel.users, id: \.userId) { user in
                                Text(user.displayName).tag(user.userId)
                            }
                        }
                    }
                }
                
                Section("Role") {
                    Picker("Select Role", selection: $viewModel.assignmentRoleId) {
                        Text("Choose Role").tag(nil as UUID?)
                        
                        ForEach(viewModel.roles, id: \.id) { role in
                            Text(role.displayName).tag(role.id as UUID?)
                        }
                    }
                }
                
                Section("Scope") {
                    Picker("Assignment Scope", selection: $viewModel.assignmentScope) {
                        ForEach(viewModel.availableScopes, id: \.self) { scope in
                            Text(viewModel.getScopeDisplayName(scope)).tag(scope)
                        }
                    }
                    
                    if viewModel.assignmentScope != .organization {
                        TextField("Scope Values (comma-separated)", text: .init(
                            get: { viewModel.assignmentScopeValues.joined(separator: ", ") },
                            set: { viewModel.assignmentScopeValues = $0.components(separatedBy: ", ").map { $0.trimmingCharacters(in: .whitespaces) } }
                        ))
                    }
                }
                
                Section("Validity") {
                    Toggle("Set Expiration", isOn: .init(
                        get: { viewModel.assignmentValidUntil != nil },
                        set: { if $0 { viewModel.assignmentValidUntil = Calendar.current.date(byAdding: .month, value: 3, to: Date()) } else { viewModel.assignmentValidUntil = nil } }
                    ))
                    
                    if viewModel.assignmentValidUntil != nil {
                        DatePicker("Valid Until", selection: Binding($viewModel.assignmentValidUntil)!, displayedComponents: [.date, .hourAndMinute])
                    }
                }
                
                Section("Reason") {
                    TextField("Assignment Reason (optional)", text: $viewModel.assignmentReason, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Assign Role")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Assign") {
                        viewModel.assignRole()
                        dismiss()
                    }
                    .disabled(!canAssign || viewModel.isLoading)
                }
            }
        }
    }
    
    private var canAssign: Bool {
        !viewModel.assignmentUserId.isEmpty &&
        viewModel.assignmentRoleId != nil &&
        viewModel.canAssignRoles
    }
}

// MARK: - User Detail View

struct UserDetailView: View {
    let user: UserProfile
    @ObservedObject var viewModel: UserAssignmentViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section("User Information") {
                    HStack {
                        AsyncImage(url: URL(string: user.avatarURL ?? "")) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Image(systemName: "person.circle.fill")
                                .foregroundColor(.gray)
                        }
                        .frame(width: 60, height: 60)
                        .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(user.displayName)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text(user.email)
                                .foregroundColor(.secondary)
                            
                            Text(user.isActive ? "Active" : "Inactive")
                                .font(.caption)
                                .foregroundColor(user.isActive ? .green : .red)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
                
                Section("Role Assignments") {
                    let assignments = viewModel.getUserAssignments(user.userId)
                    
                    if assignments.isEmpty {
                        Text("No active role assignments")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(assignments, id: \.id) { assignment in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(viewModel.getRoleName(for: assignment.roleId))
                                        .font(.headline)
                                    
                                    Spacer()
                                    
                                    StatusBadgeView(assignment: assignment)
                                }
                                
                                Text(viewModel.getScopeDisplayName(assignment.scope))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text("Assigned \(assignment.assignedAt.formatted(.relative(presentation: .named)))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                Section("Effective Permissions") {
                    Button("View Permission Summary") {
                        Task {
                            let permissions = await viewModel.getUserPermissionSummary(user.userId)
                            // Show permissions detail
                        }
                    }
                }
            }
            .navigationTitle("User Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Bulk Operations View

struct BulkOperationsView: View {
    @ObservedObject var viewModel: UserAssignmentViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Bulk Operations")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top)
            
            // Bulk Assignment
            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    Label("Bulk Role Assignment", systemImage: "person.2.badge.plus")
                        .font(.headline)
                    
                    Text("Assign a role to multiple users at once")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button("Start Bulk Assignment") {
                        viewModel.showingBulkAssignment = true
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // Bulk Revocation
            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    Label("Bulk Revocation", systemImage: "person.2.badge.minus")
                        .font(.headline)
                    
                    Text("Revoke roles from multiple users")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button("Select Assignments to Revoke") {
                        // Navigate to selection mode
                    }
                    .buttonStyle(.bordered)
                    .disabled(viewModel.selectedAssignments.isEmpty)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // Import/Export
            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    Label("Import/Export", systemImage: "arrow.up.arrow.down")
                        .font(.headline)
                    
                    Text("Import assignments from CSV or export current assignments")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Button("Import CSV") {
                            viewModel.showingImportSheet = true
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Export CSV") {
                            if let url = viewModel.exportAssignments() {
                                viewModel.showingExportSheet = true
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - Bulk Assignment View

struct BulkAssignmentView: View {
    @ObservedObject var viewModel: UserAssignmentViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Users") {
                    Text("Select \(viewModel.bulkSelectedUsers.count) of \(viewModel.users.count) users")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    ForEach(viewModel.users, id: \.userId) { user in
                        HStack {
                            Image(systemName: viewModel.bulkSelectedUsers.contains(user.userId) ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(viewModel.bulkSelectedUsers.contains(user.userId) ? .blue : .gray)
                            
                            Text(user.displayName)
                            
                            Spacer()
                            
                            Text(user.email)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if viewModel.bulkSelectedUsers.contains(user.userId) {
                                viewModel.bulkSelectedUsers.remove(user.userId)
                            } else {
                                viewModel.bulkSelectedUsers.insert(user.userId)
                            }
                        }
                    }
                }
                
                Section("Role Assignment") {
                    Picker("Role", selection: $viewModel.bulkRoleId) {
                        Text("Choose Role").tag(nil as UUID?)
                        
                        ForEach(viewModel.roles, id: \.id) { role in
                            Text(role.displayName).tag(role.id as UUID?)
                        }
                    }
                    
                    Picker("Scope", selection: $viewModel.bulkScope) {
                        ForEach(viewModel.availableScopes, id: \.self) { scope in
                            Text(viewModel.getScopeDisplayName(scope)).tag(scope)
                        }
                    }
                    
                    TextField("Reason", text: $viewModel.bulkReason)
                }
            }
            .navigationTitle("Bulk Assignment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Assign") {
                        viewModel.bulkAssignRoles()
                        dismiss()
                    }
                    .disabled(!canBulkAssign || viewModel.isLoading)
                }
            }
        }
    }
    
    private var canBulkAssign: Bool {
        !viewModel.bulkSelectedUsers.isEmpty &&
        viewModel.bulkRoleId != nil &&
        viewModel.canBulkAssign
    }
}

// MARK: - Assignment Analytics View

struct AssignmentAnalyticsView: View {
    @ObservedObject var viewModel: UserAssignmentViewModel
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                Text("Assignment Analytics")
                    .font(.title2)
                    .fontWeight(.bold)
                
                // Role Distribution Chart
                GroupBox("Role Distribution") {
                    // Chart implementation would go here
                    Text("Role distribution chart placeholder")
                        .foregroundColor(.secondary)
                        .frame(height: 200)
                }
                
                // Assignment Timeline
                GroupBox("Assignment Timeline") {
                    Text("Assignment timeline chart placeholder")
                        .foregroundColor(.secondary)
                        .frame(height: 200)
                }
                
                // User Activity
                GroupBox("Most Active Users") {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(viewModel.users.prefix(5), id: \.userId) { user in
                            HStack {
                                Text(user.displayName)
                                Spacer()
                                Text("\(viewModel.getUserAssignments(user.userId).count) roles")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }
}
