//
//  PermissionMatrixView.swift
//  DiamondDeskERP
//
//  Created by AI Assistant on 7/20/25.
//

import SwiftUI

/// Permission matrix view for role management
struct PermissionMatrixView: View {
    @ObservedObject var viewModel: RoleManagementViewModel
    @State private var selectedResource: PermissionResource?
    @State private var selectedScope: PermissionScope = .organization
    @State private var showingHelp = false
    
    var body: some View {
        NavigationStack {
            VStack {
                // Role Selector
                if !viewModel.roles.isEmpty {
                    Picker("Select Role", selection: $viewModel.selectedRole) {
                        Text("Select a role to edit").tag(nil as UserRole?)
                        
                        ForEach(viewModel.roles, id: \.id) { role in
                            Text(role.displayName).tag(role as UserRole?)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding(.horizontal)
                }
                
                if let selectedRole = viewModel.selectedRole {
                    VStack {
                        // Permission Summary
                        PermissionSummaryView(viewModel: viewModel, role: selectedRole)
                            .padding(.horizontal)
                        
                        // Scope Selector
                        Picker("Scope", selection: $selectedScope) {
                            ForEach(PermissionScope.allCases, id: \.self) { scope in
                                Text(scope.rawValue.capitalized).tag(scope)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.horizontal)
                        
                        // Permission Matrix
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(PermissionResource.allCases, id: \.self) { resource in
                                    PermissionResourceRowView(
                                        resource: resource,
                                        scope: selectedScope,
                                        viewModel: viewModel,
                                        selectedResource: $selectedResource
                                    )
                                }
                            }
                            .padding()
                        }
                    }
                } else {
                    ContentUnavailableView(
                        "Select a Role",
                        systemImage: "person.badge.key",
                        description: Text("Choose a role to view and edit its permissions")
                    )
                }
            }
            .navigationTitle("Permission Matrix")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    if viewModel.selectedRole != nil {
                        Button(action: { showingHelp = true }) {
                            Image(systemName: "questionmark.circle")
                        }
                        
                        Menu {
                            Button("Grant All Permissions") {
                                grantAllPermissions()
                            }
                            
                            Button("Revoke All Permissions") {
                                revokeAllPermissions()
                            }
                            
                            Divider()
                            
                            Button("Apply Admin Template") {
                                applyTemplate(.admin)
                            }
                            
                            Button("Apply Manager Template") {
                                applyTemplate(.manager)
                            }
                            
                            Button("Apply User Template") {
                                applyTemplate(.user)
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingHelp) {
            PermissionMatrixHelpView()
        }
        .sheet(item: $selectedResource) { resource in
            ResourcePermissionDetailView(resource: resource, viewModel: viewModel)
        }
    }
    
    private func grantAllPermissions() {
        for resource in PermissionResource.allCases {
            for action in PermissionAction.allCases {
                viewModel.setPermission(resource: resource, action: action, enabled: true)
            }
        }
    }
    
    private func revokeAllPermissions() {
        for resource in PermissionResource.allCases {
            for action in PermissionAction.allCases {
                viewModel.setPermission(resource: resource, action: action, enabled: false)
            }
        }
    }
    
    private func applyTemplate(_ template: SystemRoleType) {
        let permissions = viewModel.buildPermissionSet(for: template)
        
        // Clear all permissions first
        revokeAllPermissions()
        
        // Apply template permissions
        for permission in permissions {
            viewModel.setPermission(
                resource: permission.resource,
                action: permission.action,
                enabled: true
            )
        }
    }
}

// MARK: - Permission Summary View

struct PermissionSummaryView: View {
    @ObservedObject var viewModel: RoleManagementViewModel
    let role: UserRole
    
    var body: some View {
        GroupBox {
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(role.displayName)
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        Text(role.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Level \(role.level)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.2))
                            .foregroundColor(.blue)
                            .cornerRadius(4)
                        
                        if role.isSystemRole {
                            Text("SYSTEM")
                                .font(.caption)
                                .fontWeight(.bold)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.2))
                                .foregroundColor(.orange)
                                .cornerRadius(4)
                        }
                    }
                }
                
                // Permission Statistics
                HStack(spacing: 20) {
                    PermissionStatView(
                        title: "Direct",
                        count: viewModel.totalPermissionCount,
                        total: PermissionResource.allCases.count * PermissionAction.allCases.count,
                        color: .blue
                    )
                    
                    if let inheritanceCount = getInheritedPermissionCount() {
                        PermissionStatView(
                            title: "Inherited",
                            count: inheritanceCount,
                            total: nil,
                            color: .orange
                        )
                        
                        PermissionStatView(
                            title: "Total",
                            count: viewModel.effectivePermissions.count,
                            total: nil,
                            color: .green
                        )
                    } else {
                        PermissionStatView(
                            title: "Coverage",
                            count: Int(viewModel.permissionCoverage),
                            total: 100,
                            color: .green,
                            isPercentage: true
                        )
                    }
                }
            }
        }
    }
    
    private func getInheritedPermissionCount() -> Int? {
        guard let inheritFromId = role.inheritsFrom,
              let parentRole = viewModel.roles.first(where: { $0.id == inheritFromId }) else {
            return nil
        }
        return parentRole.permissions.count
    }
}

struct PermissionStatView: View {
    let title: String
    let count: Int
    let total: Int?
    let color: Color
    let isPercentage: Bool
    
    init(title: String, count: Int, total: Int?, color: Color, isPercentage: Bool = false) {
        self.title = title
        self.count = count
        self.total = total
        self.color = color
        self.isPercentage = isPercentage
    }
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            if let total = total {
                Text("\(count)/\(total)")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(color)
            } else {
                Text(isPercentage ? "\(count)%" : "\(count)")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(color)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Permission Resource Row

struct PermissionResourceRowView: View {
    let resource: PermissionResource
    let scope: PermissionScope
    @ObservedObject var viewModel: RoleManagementViewModel
    @Binding var selectedResource: PermissionResource?
    
    var body: some View {
        GroupBox {
            VStack(spacing: 12) {
                // Resource Header
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: resourceIcon)
                            .font(.title3)
                            .foregroundColor(resourceColor)
                            .frame(width: 24, height: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(resource.rawValue.capitalized)
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text(resourceDescription)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        let enabledCount = viewModel.getPermissionCount(resource)
                        let totalCount = PermissionAction.allCases.count
                        
                        Text("\(enabledCount)/\(totalCount)")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(enabledCount > 0 ? .green : .gray)
                        
                        Button("Details") {
                            selectedResource = resource
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                }
                
                // Permission Actions Grid
                LazyVGrid(columns: createGridColumns(), spacing: 8) {
                    ForEach(PermissionAction.allCases, id: \.self) { action in
                        PermissionActionToggle(
                            resource: resource,
                            action: action,
                            scope: scope,
                            viewModel: viewModel
                        )
                    }
                }
                
                // Quick Actions
                HStack {
                    Button("Grant All") {
                        viewModel.setAllResourcePermissions(resource, enabled: true)
                    }
                    .font(.caption)
                    .buttonStyle(.bordered)
                    .disabled(!viewModel.canEditRole)
                    
                    Button("Revoke All") {
                        viewModel.setAllResourcePermissions(resource, enabled: false)
                    }
                    .font(.caption)
                    .buttonStyle(.bordered)
                    .disabled(!viewModel.canEditRole)
                    
                    Spacer()
                    
                    if viewModel.hasAnyPermission(resource) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                }
            }
        }
    }
    
    private func createGridColumns() -> [GridItem] {
        let columns = min(PermissionAction.allCases.count, 3)
        return Array(repeating: GridItem(.flexible()), count: columns)
    }
    
    private var resourceIcon: String {
        switch resource {
        case .tasks: return "checkmark.circle"
        case .projects: return "folder"
        case .documents: return "doc.text"
        case .users: return "person.2"
        case .roles: return "person.badge.key"
        case .calendar: return "calendar"
        case .reports: return "chart.bar"
        case .analytics: return "chart.line.uptrend.xyaxis"
        case .settings: return "gearshape"
        case .notifications: return "bell"
        case .integrations: return "link"
        case .billing: return "creditcard"
        case .support: return "questionmark.circle"
        case .audit: return "doc.text.magnifyingglass"
        case .backup: return "externaldrive"
        }
    }
    
    private var resourceColor: Color {
        switch resource {
        case .tasks: return .blue
        case .projects: return .green
        case .documents: return .orange
        case .users: return .purple
        case .roles: return .red
        case .calendar: return .cyan
        case .reports: return .brown
        case .analytics: return .pink
        case .settings: return .gray
        case .notifications: return .indigo
        case .integrations: return .mint
        case .billing: return .yellow
        case .support: return .teal
        case .audit: return .black
        case .backup: return .secondary
        }
    }
    
    private var resourceDescription: String {
        switch resource {
        case .tasks: return "Task management and assignments"
        case .projects: return "Project planning and execution"
        case .documents: return "Document storage and sharing"
        case .users: return "User management and profiles"
        case .roles: return "Role and permission management"
        case .calendar: return "Calendar and scheduling"
        case .reports: return "Report generation and viewing"
        case .analytics: return "Analytics and insights"
        case .settings: return "System configuration"
        case .notifications: return "Notification management"
        case .integrations: return "Third-party integrations"
        case .billing: return "Billing and payments"
        case .support: return "Support and help desk"
        case .audit: return "Audit trails and logs"
        case .backup: return "Backup and recovery"
        }
    }
}

// MARK: - Permission Action Toggle

struct PermissionActionToggle: View {
    let resource: PermissionResource
    let action: PermissionAction
    let scope: PermissionScope
    @ObservedObject var viewModel: RoleManagementViewModel
    
    private var isEnabled: Bool {
        viewModel.getResourcePermissions(resource)[action] ?? false
    }
    
    var body: some View {
        Button(action: {
            if viewModel.canEditRole {
                viewModel.togglePermission(resource: resource, action: action, scope: scope)
            }
        }) {
            VStack(spacing: 4) {
                Image(systemName: actionIcon)
                    .font(.system(size: 14))
                    .foregroundColor(isEnabled ? .white : actionColor)
                
                Text(action.rawValue)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(isEnabled ? .white : actionColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(height: 50)
            .frame(maxWidth: .infinity)
            .background(isEnabled ? actionColor : actionColor.opacity(0.1))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(actionColor.opacity(0.3), lineWidth: 1)
            )
        }
        .disabled(!viewModel.canEditRole)
        .scaleEffect(isEnabled ? 1.0 : 0.95)
        .animation(.easeInOut(duration: 0.2), value: isEnabled)
    }
    
    private var actionIcon: String {
        switch action {
        case .read: return "eye"
        case .create: return "plus"
        case .update: return "pencil"
        case .delete: return "trash"
        case .assign: return "person.badge.plus"
        case .revoke: return "person.badge.minus"
        case .audit: return "doc.text.magnifyingglass"
        case .export: return "square.and.arrow.up"
        case .import: return "square.and.arrow.down"
        case .bulkAssign: return "person.2.badge.plus"
        }
    }
    
    private var actionColor: Color {
        switch action {
        case .read: return .blue
        case .create: return .green
        case .update: return .orange
        case .delete: return .red
        case .assign: return .purple
        case .revoke: return .pink
        case .audit: return .brown
        case .export: return .cyan
        case .import: return .indigo
        case .bulkAssign: return .mint
        }
    }
}

// MARK: - Resource Permission Detail View

struct ResourcePermissionDetailView: View {
    let resource: PermissionResource
    @ObservedObject var viewModel: RoleManagementViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section("Resource Information") {
                    HStack {
                        Image(systemName: resourceIcon)
                            .font(.title2)
                            .foregroundColor(resourceColor)
                            .frame(width: 40, height: 40)
                            .background(resourceColor.opacity(0.1))
                            .cornerRadius(8)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(resource.rawValue.capitalized)
                                .font(.headline)
                            
                            Text(resourceDescription)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
                
                Section("Available Actions") {
                    ForEach(PermissionAction.allCases, id: \.self) { action in
                        PermissionActionDetailRow(
                            action: action,
                            resource: resource,
                            viewModel: viewModel
                        )
                    }
                }
                
                if let selectedRole = viewModel.selectedRole {
                    Section("Role Context") {
                        HStack {
                            Text("Current Role")
                            Spacer()
                            Text(selectedRole.displayName)
                                .foregroundColor(.blue)
                        }
                        
                        HStack {
                            Text("Role Level")
                            Spacer()
                            Text("\(selectedRole.level)")
                                .foregroundColor(.orange)
                        }
                        
                        HStack {
                            Text("Permissions for this Resource")
                            Spacer()
                            Text("\(viewModel.getPermissionCount(resource))/\(PermissionAction.allCases.count)")
                                .foregroundColor(.green)
                        }
                    }
                }
                
                Section("Recommended Permissions") {
                    VStack(alignment: .leading, spacing: 8) {
                        RecommendationView(
                            title: "Basic User",
                            actions: [.read],
                            description: "Read-only access"
                        )
                        
                        RecommendationView(
                            title: "Content Creator",
                            actions: [.read, .create, .update],
                            description: "Can create and modify content"
                        )
                        
                        RecommendationView(
                            title: "Manager",
                            actions: [.read, .create, .update, .assign],
                            description: "Full management capabilities"
                        )
                        
                        RecommendationView(
                            title: "Administrator",
                            actions: PermissionAction.allCases,
                            description: "Complete control"
                        )
                    }
                }
            }
            .navigationTitle("Resource Details")
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
    
    private var resourceIcon: String {
        switch resource {
        case .tasks: return "checkmark.circle"
        case .projects: return "folder"
        case .documents: return "doc.text"
        case .users: return "person.2"
        case .roles: return "person.badge.key"
        case .calendar: return "calendar"
        case .reports: return "chart.bar"
        case .analytics: return "chart.line.uptrend.xyaxis"
        case .settings: return "gearshape"
        case .notifications: return "bell"
        case .integrations: return "link"
        case .billing: return "creditcard"
        case .support: return "questionmark.circle"
        case .audit: return "doc.text.magnifyingglass"
        case .backup: return "externaldrive"
        }
    }
    
    private var resourceColor: Color {
        switch resource {
        case .tasks: return .blue
        case .projects: return .green
        case .documents: return .orange
        case .users: return .purple
        case .roles: return .red
        case .calendar: return .cyan
        case .reports: return .brown
        case .analytics: return .pink
        case .settings: return .gray
        case .notifications: return .indigo
        case .integrations: return .mint
        case .billing: return .yellow
        case .support: return .teal
        case .audit: return .black
        case .backup: return .secondary
        }
    }
    
    private var resourceDescription: String {
        switch resource {
        case .tasks: return "Manage tasks, assignments, and project workflow"
        case .projects: return "Create and manage projects, milestones, and deliverables"
        case .documents: return "Store, share, and collaborate on documents"
        case .users: return "Manage user accounts, profiles, and access"
        case .roles: return "Define and manage user roles and permissions"
        case .calendar: return "Schedule events, meetings, and manage calendars"
        case .reports: return "Generate and view business reports and analytics"
        case .analytics: return "Access insights, metrics, and data visualizations"
        case .settings: return "Configure system settings and preferences"
        case .notifications: return "Manage alerts, notifications, and communication"
        case .integrations: return "Connect with third-party services and APIs"
        case .billing: return "Manage payments, invoices, and financial transactions"
        case .support: return "Access help desk, tickets, and customer support"
        case .audit: return "View security logs, audit trails, and compliance reports"
        case .backup: return "Manage data backups, recovery, and archival"
        }
    }
}

// MARK: - Permission Action Detail Row

struct PermissionActionDetailRow: View {
    let action: PermissionAction
    let resource: PermissionResource
    @ObservedObject var viewModel: RoleManagementViewModel
    
    private var isEnabled: Bool {
        viewModel.getResourcePermissions(resource)[action] ?? false
    }
    
    var body: some View {
        HStack {
            Toggle("", isOn: Binding(
                get: { isEnabled },
                set: { _ in
                    if viewModel.canEditRole {
                        viewModel.togglePermission(resource: resource, action: action)
                    }
                }
            ))
            .disabled(!viewModel.canEditRole)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(action.rawValue.capitalized)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(actionDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: actionIcon)
                .foregroundColor(isEnabled ? .green : .gray)
        }
        .padding(.vertical, 4)
    }
    
    private var actionIcon: String {
        switch action {
        case .read: return "eye"
        case .create: return "plus.circle"
        case .update: return "pencil.circle"
        case .delete: return "trash.circle"
        case .assign: return "person.badge.plus"
        case .revoke: return "person.badge.minus"
        case .audit: return "doc.text.magnifyingglass"
        case .export: return "square.and.arrow.up"
        case .import: return "square.and.arrow.down"
        case .bulkAssign: return "person.2.badge.plus"
        }
    }
    
    private var actionDescription: String {
        switch action {
        case .read: return "View and access \(resource.rawValue)"
        case .create: return "Create new \(resource.rawValue)"
        case .update: return "Modify existing \(resource.rawValue)"
        case .delete: return "Remove \(resource.rawValue)"
        case .assign: return "Assign \(resource.rawValue) to users"
        case .revoke: return "Remove \(resource.rawValue) from users"
        case .audit: return "View audit logs for \(resource.rawValue)"
        case .export: return "Export \(resource.rawValue) data"
        case .import: return "Import \(resource.rawValue) data"
        case .bulkAssign: return "Bulk assign \(resource.rawValue)"
        }
    }
}

// MARK: - Recommendation View

struct RecommendationView: View {
    let title: String
    let actions: [PermissionAction]
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("\(actions.count) actions")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(actions, id: \.self) { action in
                        Text(action.rawValue)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(4)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Permission Matrix Help View

struct PermissionMatrixHelpView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Group {
                        HelpSectionView(
                            title: "Understanding Permissions",
                            content: "Permissions control what actions users can perform on specific resources. Each permission consists of an action (like read, create, update) and a resource (like tasks, documents, users)."
                        )
                        
                        HelpSectionView(
                            title: "Permission Scope",
                            content: "Permissions can be scoped to different organizational levels:\n\n• Organization: Full access across the entire organization\n• Department: Access limited to specific departments\n• Project: Access limited to specific projects\n• Personal: Access limited to user's own items"
                        )
                        
                        HelpSectionView(
                            title: "Role Inheritance",
                            content: "Roles can inherit permissions from parent roles. When a role inherits from another, it automatically receives all permissions from the parent role, plus any additional permissions defined directly on the child role."
                        )
                        
                        HelpSectionView(
                            title: "Permission Actions",
                            content: """
                            • Read: View and access resources
                            • Create: Add new resources
                            • Update: Modify existing resources
                            • Delete: Remove resources
                            • Assign: Grant resources to other users
                            • Revoke: Remove resources from other users
                            • Audit: View audit logs and security information
                            • Export: Download or export resource data
                            • Import: Upload or import resource data
                            • Bulk Assign: Perform bulk assignment operations
                            """
                        )
                    }
                    
                    Group {
                        HelpSectionView(
                            title: "Best Practices",
                            content: """
                            • Follow the principle of least privilege
                            • Use role inheritance to reduce duplication
                            • Regularly audit and review permissions
                            • Create role templates for common use cases
                            • Document permission decisions and changes
                            • Test permissions thoroughly before deployment
                            """
                        )
                        
                        HelpSectionView(
                            title: "Security Considerations",
                            content: """
                            • Critical actions (like delete, audit) should be restricted
                            • Avoid granting excessive permissions
                            • Monitor failed permission attempts
                            • Use time-limited role assignments when appropriate
                            • Regular security reviews and compliance checks
                            """
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Permission Matrix Help")
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

struct HelpSectionView: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .fontWeight(.bold)
            
            Text(content)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Role Inheritance View

struct RoleInheritanceView: View {
    @ObservedObject var viewModel: RoleManagementViewModel
    
    var body: some View {
        NavigationStack {
            VStack {
                if let selectedRole = viewModel.selectedRole {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Current Role
                            RoleInheritanceCard(
                                role: selectedRole,
                                level: 0,
                                isSelected: true
                            )
                            
                            // Inheritance Chain
                            let chain = viewModel.getInheritanceChain(for: selectedRole)
                            if chain.count > 1 {
                                ForEach(Array(chain.dropFirst().enumerated()), id: \.offset) { index, role in
                                    VStack {
                                        Image(systemName: "arrow.up")
                                            .foregroundColor(.secondary)
                                        
                                        RoleInheritanceCard(
                                            role: role,
                                            level: index + 1,
                                            isSelected: false
                                        )
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                } else {
                    ContentUnavailableView(
                        "Select a Role",
                        systemImage: "arrow.triangle.branch",
                        description: Text("Choose a role to view its inheritance chain")
                    )
                }
            }
            .navigationTitle("Role Inheritance")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct RoleInheritanceCard: View {
    let role: UserRole
    let level: Int
    let isSelected: Bool
    
    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(role.displayName)
                            .font(.headline)
                            .fontWeight(isSelected ? .bold : .medium)
                        
                        Text(role.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(level == 0 ? "Current Role" : "Parent Role")
                            .font(.caption)
                            .foregroundColor(isSelected ? .blue : .secondary)
                        
                        Text("Level \(role.level)")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.2))
                            .foregroundColor(.orange)
                            .cornerRadius(4)
                    }
                }
                
                HStack {
                    Text("\(role.permissions.count) permissions")
                        .font(.caption)
                        .foregroundColor(.green)
                    
                    Spacer()
                    
                    if role.isSystemRole {
                        Text("SYSTEM ROLE")
                            .font(.caption)
                            .fontWeight(.bold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red.opacity(0.2))
                            .foregroundColor(.red)
                            .cornerRadius(4)
                    }
                }
            }
        }
        .background(isSelected ? Color.blue.opacity(0.05) : Color.clear)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
    }
}

// MARK: - Role Usage View

struct RoleUsageView: View {
    @ObservedObject var viewModel: RoleManagementViewModel
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.roles, id: \.id) { role in
                    RoleUsageRowView(role: role, viewModel: viewModel)
                }
            }
            .navigationTitle("Role Usage")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct RoleUsageRowView: View {
    let role: UserRole
    @ObservedObject var viewModel: RoleManagementViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(role.displayName)
                    .font(.headline)
                
                Spacer()
                
                let usageCount = viewModel.getRoleUsageCount(role.id)
                Text("\(usageCount) users")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(usageCount > 0 ? .green : .gray)
            }
            
            HStack {
                Text("Level \(role.level)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("•")
                    .foregroundColor(.secondary)
                
                Text("\(role.permissions.count) permissions")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if role.isSystemRole {
                    Text("• System Role")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                
                Spacer()
                
                Text(role.createdAt.formatted(.relative(presentation: .named)))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
