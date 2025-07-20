//
//  RoleManagementView.swift
//  DiamondDeskERP
//
//  Created by AI Assistant on 7/20/25.
//

import SwiftUI

/// Enhanced role management interface with full CRUD operations
struct RoleManagementView: View {
    @StateObject private var viewModel = RoleManagementViewModel()
    @State private var selectedSidebarItem: SidebarItem = .roles
    
    var body: some View {
        NavigationSplitView {
            // Sidebar
            List(selection: $selectedSidebarItem) {
                Section("Management") {
                    ForEach(SidebarItem.allCases, id: \.self) { item in
                        Label(item.title, systemImage: item.icon)
                            .tag(item)
                    }
                }
                
                Section("Quick Actions") {
                    Button(action: viewModel.createNewRole) {
                        Label("Create Role", systemImage: "plus.circle")
                    }
                    
                    if let selectedRole = viewModel.selectedRole {
                        Button(action: { viewModel.duplicateRole(selectedRole) }) {
                            Label("Duplicate Role", systemImage: "doc.on.doc")
                        }
                        
                        if viewModel.canDeleteRole {
                            Button(action: { viewModel.showingDeleteConfirmation = true }) {
                                Label("Delete Role", systemImage: "trash")
                            }
                            .foregroundColor(.red)
                        }
                    }
                }
                
                Section("Filters") {
                    RoleFiltersView(viewModel: viewModel)
                }
            }
            .navigationTitle("Role Management")
            .navigationBarTitleDisplayMode(.large)
            
        } detail: {
            // Main Content
            Group {
                switch selectedSidebarItem {
                case .roles:
                    RoleListView(viewModel: viewModel)
                case .permissions:
                    PermissionMatrixView(viewModel: viewModel)
                case .inheritance:
                    RoleInheritanceView(viewModel: viewModel)
                case .usage:
                    RoleUsageView(viewModel: viewModel)
                }
            }
        }
        .sheet(isPresented: $viewModel.showingInheritanceSelector) {
            InheritanceSelectorView(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showingPermissionDetail) {
            if let selectedRole = viewModel.selectedRole {
                PermissionDetailView(role: selectedRole)
            }
        }
        .alert("Delete Role", isPresented: $viewModel.showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                viewModel.deleteRole()
            }
        } message: {
            Text("Are you sure you want to delete this role? This action cannot be undone.")
        }
        .alert("Error", isPresented: $viewModel.showingError) {
            Button("OK") { }
        } message: {
            if let error = viewModel.error {
                Text(error.localizedDescription)
            }
        }
    }
}

// MARK: - Sidebar Items

enum SidebarItem: CaseIterable {
    case roles, permissions, inheritance, usage
    
    var title: String {
        switch self {
        case .roles: return "Roles"
        case .permissions: return "Permissions Matrix"
        case .inheritance: return "Role Inheritance"
        case .usage: return "Usage Analytics"
        }
    }
    
    var icon: String {
        switch self {
        case .roles: return "person.2.badge.key"
        case .permissions: return "grid.circle"
        case .inheritance: return "arrow.triangle.branch"
        case .usage: return "chart.bar"
        }
    }
}

// MARK: - Role List View

struct RoleListView: View {
    @ObservedObject var viewModel: RoleManagementViewModel
    
    var body: some View {
        NavigationStack {
            VStack {
                // Search and Controls
                HStack {
                    SearchBar(text: $viewModel.searchText, placeholder: "Search roles...")
                    
                    Menu {
                        ForEach(viewModel.levelOptions, id: \.self) { level in
                            Button("Level \(level)") {
                                viewModel.selectedLevel = level == viewModel.selectedLevel ? nil : level
                            }
                        }
                        
                        Divider()
                        
                        Button("Clear Filter") {
                            viewModel.selectedLevel = nil
                        }
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                    }
                }
                .padding(.horizontal)
                
                // Role List
                List(viewModel.filteredRoles, id: \.id) { role in
                    RoleRowView(role: role, viewModel: viewModel)
                        .onTapGesture {
                            viewModel.selectRole(role)
                        }
                }
                .refreshable {
                    viewModel.loadRoles()
                }
            }
            .navigationTitle("Roles (\(viewModel.filteredRoles.count))")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: viewModel.createNewRole) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $viewModel.isEditing) {
            RoleEditorView(viewModel: viewModel)
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView("Loading roles...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.1))
            }
        }
    }
}

// MARK: - Role Row View

struct RoleRowView: View {
    let role: UserRole
    @ObservedObject var viewModel: RoleManagementViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(role.displayName)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        if role.isSystemRole {
                            Text("SYSTEM")
                                .font(.caption)
                                .fontWeight(.bold)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.2))
                                .foregroundColor(.blue)
                                .cornerRadius(4)
                        }
                        
                        Spacer()
                        
                        Text("Level \(role.level)")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(levelColor(role.level).opacity(0.2))
                            .foregroundColor(levelColor(role.level))
                            .cornerRadius(4)
                    }
                    
                    Text(role.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            
            // Permission Summary
            HStack {
                Label("\(role.permissions.count)", systemImage: "key.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let inheritanceCount = getInheritanceCount(role) {
                    Label("+\(inheritanceCount)", systemImage: "arrow.down.right")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                
                Spacer()
                
                let usageCount = viewModel.getRoleUsageCount(role.id)
                if usageCount > 0 {
                    Label("\(usageCount) users", systemImage: "person.2")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                
                Text(role.createdAt.formatted(.relative(presentation: .named)))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Top Permissions Preview
            if !role.permissions.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(Array(role.permissions.prefix(5)), id: \.self) { permission in
                            PermissionPillView(permission: permission)
                        }
                        
                        if role.permissions.count > 5 {
                            Text("+\(role.permissions.count - 5) more")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(3)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding(.vertical, 4)
        .contextMenu {
            if !role.isSystemRole {
                Button(action: { viewModel.selectRole(role); viewModel.isEditing = true }) {
                    Label("Edit", systemImage: "pencil")
                }
                
                Button(action: { viewModel.duplicateRole(role) }) {
                    Label("Duplicate", systemImage: "doc.on.doc")
                }
                
                if viewModel.canDeleteRole {
                    Divider()
                    Button(action: { 
                        viewModel.selectRole(role)
                        viewModel.showingDeleteConfirmation = true 
                    }) {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
            
            Divider()
            
            Button(action: { 
                let definition = viewModel.exportRoleDefinition(role)
                UIPasteboard.general.string = definition
            }) {
                Label("Copy Definition", systemImage: "doc.on.clipboard")
            }
        }
    }
    
    private func levelColor(_ level: Int) -> Color {
        switch level {
        case 1...2: return .red
        case 3...4: return .orange
        case 5...6: return .yellow
        case 7...8: return .green
        case 9...10: return .blue
        default: return .gray
        }
    }
    
    private func getInheritanceCount(_ role: UserRole) -> Int? {
        guard let inheritFromId = role.inheritsFrom else { return nil }
        let parentRole = viewModel.roles.first { $0.id == inheritFromId }
        return parentRole?.permissions.count
    }
}

// MARK: - Permission Pill View

struct PermissionPillView: View {
    let permission: Permission
    
    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: actionIcon)
                .font(.caption2)
            
            Text(permission.action.rawValue)
                .font(.caption2)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .background(resourceColor.opacity(0.2))
        .foregroundColor(resourceColor)
        .cornerRadius(3)
    }
    
    private var actionIcon: String {
        switch permission.action {
        case .read: return "eye"
        case .create: return "plus"
        case .update: return "pencil"
        case .delete: return "trash"
        case .assign: return "person.badge.plus"
        case .revoke: return "person.badge.minus"
        case .audit: return "doc.text"
        case .export: return "square.and.arrow.up"
        case .import: return "square.and.arrow.down"
        case .bulkAssign: return "person.2.badge.plus"
        }
    }
    
    private var resourceColor: Color {
        switch permission.resource {
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
}

// MARK: - Role Filters View

struct RoleFiltersView: View {
    @ObservedObject var viewModel: RoleManagementViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle("System Roles", isOn: $viewModel.showSystemRoles)
            Toggle("Custom Roles", isOn: $viewModel.showCustomRoles)
            
            if viewModel.selectedLevel != nil {
                HStack {
                    Text("Level: \(viewModel.selectedLevel!)")
                        .font(.caption)
                    
                    Spacer()
                    
                    Button("Clear") {
                        viewModel.selectedLevel = nil
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
        }
        .font(.subheadline)
    }
}

// MARK: - Role Editor View

struct RoleEditorView: View {
    @ObservedObject var viewModel: RoleManagementViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Information") {
                    if viewModel.selectedRole == nil {
                        TextField("Role Name", text: $viewModel.roleName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    TextField("Display Name", text: $viewModel.displayName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Description", text: $viewModel.description, axis: .vertical)
                        .lineLimit(3...6)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Stepper("Level: \(viewModel.level)", value: $viewModel.level, in: 1...10)
                }
                
                Section("Inheritance") {
                    if viewModel.availableParentRoles.isEmpty {
                        Text("No available parent roles")
                            .foregroundColor(.secondary)
                    } else {
                        Picker("Inherit From", selection: $viewModel.inheritFromRole) {
                            Text("None").tag(nil as UUID?)
                            
                            ForEach(viewModel.availableParentRoles, id: \.id) { role in
                                Text(role.displayName).tag(role.id as UUID?)
                            }
                        }
                    }
                }
                
                Section("Permissions") {
                    Text("Permission Count: \(viewModel.totalPermissionCount)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Coverage: \(String(format: "%.1f", viewModel.permissionCoverage))%")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button("Configure Permissions") {
                        // This would open a detailed permission matrix
                    }
                    .foregroundColor(.blue)
                }
                
                if let selectedRole = viewModel.selectedRole {
                    Section("Effective Permissions") {
                        Text("\(viewModel.effectivePermissions.count) total permissions")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Button("View Details") {
                            viewModel.showingPermissionDetail = true
                        }
                        .foregroundColor(.blue)
                    }
                }
            }
            .navigationTitle(viewModel.selectedRole == nil ? "Create Role" : "Edit Role")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        viewModel.cancelEditing()
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        viewModel.saveRole()
                        dismiss()
                    }
                    .disabled(viewModel.displayName.isEmpty || viewModel.isLoading)
                }
            }
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView("Saving...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.1))
            }
        }
    }
}

// MARK: - Supporting Views

struct SearchBar: View {
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField(placeholder, text: $text)
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}
