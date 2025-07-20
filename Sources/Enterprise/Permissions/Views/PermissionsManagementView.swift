//
//  PermissionsManagementView.swift
//  DiamondDeskERP
//
//  Created by J.Michael McDermott on 7/20/25.
//

import SwiftUI
import CloudKit

/// Main permissions management interface
struct PermissionsManagementView: View {
    @StateObject private var permissionsService = UnifiedPermissionsService.shared
    @State private var selectedTab = 0
    @State private var showingCreatePolicy = false
    @State private var showingCreateRole = false
    @State private var showingAssignRole = false
    @State private var searchText = ""
    
    var body: some View {
        NavigationStack {
            TabView(selection: $selectedTab) {
                // Roles Tab
                RolesManagementView()
                    .tabItem {
                        Label("Roles", systemImage: "person.2.badge.key")
                    }
                    .tag(0)
                
                // Policies Tab
                PoliciesManagementView()
                    .tabItem {
                        Label("Policies", systemImage: "doc.text.magnifyingglass")
                    }
                    .tag(1)
                
                // Users Tab
                UserPermissionsView()
                    .tabItem {
                        Label("Users", systemImage: "person.3")
                    }
                    .tag(2)
                
                // Resources Tab
                ResourcePermissionsView()
                    .tabItem {
                        Label("Resources", systemImage: "folder.badge.gearshape")
                    }
                    .tag(3)
                
                // Audit Tab
                PermissionsAuditView()
                    .tabItem {
                        Label("Audit", systemImage: "doc.text.image")
                    }
                    .tag(4)
            }
            .navigationTitle("Permissions")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showingCreateRole = true }) {
                            Label("Create Role", systemImage: "plus.circle")
                        }
                        
                        Button(action: { showingCreatePolicy = true }) {
                            Label("Create Policy", systemImage: "doc.badge.plus")
                        }
                        
                        Button(action: { showingAssignRole = true }) {
                            Label("Assign Role", systemImage: "person.badge.plus")
                        }
                        
                        Divider()
                        
                        Button(action: { generateSecurityReport() }) {
                            Label("Security Report", systemImage: "doc.text.magnifyingglass")
                        }
                    } label: {
                        Image(systemName: "plus.circle")
                    }
                }
            }
            .sheet(isPresented: $showingCreateRole) {
                CreateRoleView()
            }
            .sheet(isPresented: $showingCreatePolicy) {
                CreatePolicyView()
            }
            .sheet(isPresented: $showingAssignRole) {
                AssignRoleView()
            }
        }
        .environmentObject(permissionsService)
    }
    
    private func generateSecurityReport() {
        Task {
            do {
                let report = try await permissionsService.generateSecurityAuditReport(
                    timeRange: .lastMonth,
                    includePermissionChanges: true,
                    includeAccessAttempts: true,
                    includeViolations: true
                )
                // Handle report display
            } catch {
                print("Failed to generate security report: \(error)")
            }
        }
    }
}

// MARK: - Roles Management View

struct RolesManagementView: View {
    @EnvironmentObject private var permissionsService: UnifiedPermissionsService
    @State private var searchText = ""
    @State private var selectedRole: RoleDefinition?
    
    var filteredRoles: [RoleDefinition] {
        if searchText.isEmpty {
            return permissionsService.roleDefinitions
        } else {
            return permissionsService.roleDefinitions.filter { role in
                role.name.localizedCaseInsensitiveContains(searchText) ||
                role.description.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredRoles) { role in
                    RoleRow(role: role, selectedRole: $selectedRole)
                        .onTapGesture {
                            selectedRole = role
                        }
                }
            }
            .searchable(text: $searchText, prompt: "Search roles...")
            .navigationTitle("Roles")
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: $selectedRole) { role in
                RoleDetailView(role: role)
            }
        }
    }
}

struct RoleRow: View {
    let role: RoleDefinition
    @Binding var selectedRole: RoleDefinition?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(role.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(role.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    if role.isSystemRole {
                        Text("System")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.2))
                            .foregroundColor(.blue)
                            .cornerRadius(4)
                    }
                    
                    Text("\(role.permissions.count) permissions")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Permission summary
            if !role.permissions.isEmpty {
                HStack {
                    ForEach(Array(role.permissions.prefix(3)), id: \.action) { permission in
                        Text(permission.action.displayName)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(permission.isGranted ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                            .foregroundColor(permission.isGranted ? .green : .red)
                            .cornerRadius(3)
                    }
                    
                    if role.permissions.count > 3 {
                        Text("+\(role.permissions.count - 3) more")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Role Detail View

struct RoleDetailView: View {
    let role: RoleDefinition
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var permissionsService: UnifiedPermissionsService
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(role.name)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            if role.isSystemRole {
                                Text("System Role")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.2))
                                    .foregroundColor(.blue)
                                    .cornerRadius(6)
                            }
                        }
                        
                        Text(role.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Permissions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Permissions")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        LazyVStack(spacing: 8) {
                            ForEach(role.permissions, id: \.action) { permission in
                                PermissionRow(permission: permission)
                            }
                        }
                    }
                    
                    // Role Statistics
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Statistics")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 8) {
                            StatRow(title: "Total Permissions", value: "\(role.permissions.count)")
                            StatRow(title: "Granted Permissions", value: "\(role.permissions.filter { $0.isGranted }.count)")
                            StatRow(title: "Denied Permissions", value: "\(role.permissions.filter { !$0.isGranted }.count)")
                            StatRow(title: "Created", value: DateFormatter.medium.string(from: role.createdAt))
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle("Role Details")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Edit Role") {
                            // Edit role action
                        }
                        
                        Button("Duplicate Role") {
                            // Duplicate role action
                        }
                        
                        if !role.isSystemRole {
                            Divider()
                            
                            Button("Delete Role", role: .destructive) {
                                // Delete role action
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
    }
}

struct PermissionRow: View {
    let permission: Permission
    
    var body: some View {
        HStack {
            Image(systemName: permission.isGranted ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(permission.isGranted ? .green : .red)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(permission.action.displayName)
                    .font(.body)
                    .fontWeight(.medium)
                
                Text(permission.resource.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(permission.isGranted ? "Allow" : "Deny")
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(permission.isGranted ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                .foregroundColor(permission.isGranted ? .green : .red)
                .cornerRadius(6)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(.systemGray4), lineWidth: 0.5)
        )
    }
}

struct StatRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Policies Management View

struct PoliciesManagementView: View {
    @EnvironmentObject private var permissionsService: UnifiedPermissionsService
    @State private var searchText = ""
    @State private var selectedPolicy: PermissionPolicy?
    
    var filteredPolicies: [PermissionPolicy] {
        if searchText.isEmpty {
            return permissionsService.permissionPolicies
        } else {
            return permissionsService.permissionPolicies.filter { policy in
                policy.name.localizedCaseInsensitiveContains(searchText) ||
                policy.description.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredPolicies) { policy in
                    PolicyRow(policy: policy)
                        .onTapGesture {
                            selectedPolicy = policy
                        }
                }
            }
            .searchable(text: $searchText, prompt: "Search policies...")
            .navigationTitle("Policies")
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: $selectedPolicy) { policy in
                PolicyDetailView(policy: policy)
            }
        }
    }
}

struct PolicyRow: View {
    @ObservedObject var policy: PermissionPolicy
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(policy.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(policy.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(policy.priority.displayName)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(priorityColor(policy.priority).opacity(0.2))
                        .foregroundColor(priorityColor(policy.priority))
                        .cornerRadius(4)
                    
                    Text("\(policy.rules.count) rules")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Circle()
                        .fill(policy.isActive ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                }
            }
            
            HStack {
                Text(policy.scope.displayName)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.2))
                    .foregroundColor(.blue)
                    .cornerRadius(3)
                
                Spacer()
                
                Text("Created by \(policy.createdBy)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func priorityColor(_ priority: PolicyPriority) -> Color {
        switch priority {
        case .low: return .blue
        case .normal: return .primary
        case .high: return .orange
        case .critical: return .red
        }
    }
}

// MARK: - User Permissions View

struct UserPermissionsView: View {
    @EnvironmentObject private var permissionsService: UnifiedPermissionsService
    @State private var searchText = ""
    @State private var selectedUserId: String?
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(Array(permissionsService.userPermissions.keys), id: \.self) { userId in
                    if let userPerms = permissionsService.userPermissions[userId] {
                        UserPermissionRow(userPermissions: userPerms)
                            .onTapGesture {
                                selectedUserId = userId
                            }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search users...")
            .navigationTitle("User Permissions")
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: Binding<UserPermissionsWrapper?>(
                get: {
                    guard let userId = selectedUserId,
                          let userPerms = permissionsService.userPermissions[userId] else { return nil }
                    return UserPermissionsWrapper(userPermissions: userPerms)
                },
                set: { _ in selectedUserId = nil }
            )) { wrapper in
                UserPermissionDetailView(userPermissions: wrapper.userPermissions)
            }
        }
    }
}

struct UserPermissionsWrapper: Identifiable {
    let id = UUID()
    let userPermissions: UserPermissions
}

struct UserPermissionRow: View {
    let userPermissions: UserPermissions
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("User: \(userPermissions.userId)")
                    .font(.headline)
                
                Spacer()
                
                Text("\(userPermissions.roleIds.count) roles")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("Roles: \(userPermissions.roleIds.joined(separator: ", "))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Spacer()
                
                Text("Updated: \(DateFormatter.short.string(from: userPermissions.lastUpdated))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Resource Permissions View

struct ResourcePermissionsView: View {
    @EnvironmentObject private var permissionsService: UnifiedPermissionsService
    @State private var searchText = ""
    @State private var selectedResourceId: String?
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(Array(permissionsService.resourcePermissions.keys), id: \.self) { resourceId in
                    if let resourcePerms = permissionsService.resourcePermissions[resourceId] {
                        ResourcePermissionRow(resourcePermissions: resourcePerms)
                            .onTapGesture {
                                selectedResourceId = resourceId
                            }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search resources...")
            .navigationTitle("Resource Permissions")
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: Binding<ResourcePermissionsWrapper?>(
                get: {
                    guard let resourceId = selectedResourceId,
                          let resourcePerms = permissionsService.resourcePermissions[resourceId] else { return nil }
                    return ResourcePermissionsWrapper(resourcePermissions: resourcePerms)
                },
                set: { _ in selectedResourceId = nil }
            )) { wrapper in
                ResourcePermissionDetailView(resourcePermissions: wrapper.resourcePermissions)
            }
        }
    }
}

struct ResourcePermissionsWrapper: Identifiable {
    let id = UUID()
    let resourcePermissions: ResourcePermissions
}

struct ResourcePermissionRow: View {
    let resourcePermissions: ResourcePermissions
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(resourcePermissions.resourceId)
                    .font(.headline)
                    .lineLimit(1)
                
                Spacer()
                
                Text(resourcePermissions.resourceType.displayName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.2))
                    .foregroundColor(.blue)
                    .cornerRadius(4)
            }
            
            HStack {
                Text("\(resourcePermissions.permissions.count) permissions")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if resourcePermissions.inheritFromParent {
                    Image(systemName: "arrow.down.circle")
                        .foregroundColor(.blue)
                        .font(.caption)
                }
                
                Text("Set by \(resourcePermissions.setBy)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Permissions Audit View

struct PermissionsAuditView: View {
    @EnvironmentObject private var permissionsService: UnifiedPermissionsService
    @State private var selectedTimeRange: TimeRange = .lastWeek
    @State private var showingSecurityReport = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Time Range Selector
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Time Range")
                            .font(.headline)
                        
                        Picker("Time Range", selection: $selectedTimeRange) {
                            Text("Last 24 Hours").tag(TimeRange.lastDay)
                            Text("Last Week").tag(TimeRange.lastWeek)
                            Text("Last Month").tag(TimeRange.lastMonth)
                            Text("Last 3 Months").tag(TimeRange.lastQuarter)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Security Metrics
                    if let metrics = permissionsService.securityMetrics {
                        SecurityMetricsView(metrics: metrics)
                    }
                    
                    // Recent Audit Logs
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Recent Activity")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Spacer()
                            
                            Button("View All") {
                                // Show all audit logs
                            }
                            .font(.caption)
                        }
                        
                        LazyVStack(spacing: 8) {
                            ForEach(Array(permissionsService.permissionAuditLogs.prefix(10)), id: \.id) { log in
                                AuditLogRow(log: log)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Security Audit")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Generate Report") {
                        showingSecurityReport = true
                    }
                }
            }
            .sheet(isPresented: $showingSecurityReport) {
                SecurityReportView()
            }
            .task {
                do {
                    try await permissionsService.loadSecurityMetrics(timeRange: selectedTimeRange)
                } catch {
                    print("Failed to load security metrics: \(error)")
                }
            }
        }
    }
}

struct SecurityMetricsView: View {
    let metrics: SecurityMetrics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Security Overview")
                .font(.title2)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                MetricCard(
                    title: "Total Checks",
                    value: "\(metrics.totalPermissionChecks)",
                    icon: "checkmark.shield",
                    color: .blue
                )
                
                MetricCard(
                    title: "Success Rate",
                    value: "\(Int((Double(metrics.successfulChecks) / Double(metrics.totalPermissionChecks)) * 100))%",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .green
                )
                
                MetricCard(
                    title: "Security Score",
                    value: "\(Int(metrics.securityScore))",
                    icon: "shield.checkerboard",
                    color: .orange
                )
                
                MetricCard(
                    title: "Risk Level",
                    value: metrics.riskLevel.displayName,
                    icon: "exclamationmark.triangle",
                    color: metrics.riskLevel.color
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

struct AuditLogRow: View {
    let log: PermissionAuditLog
    
    var body: some View {
        HStack {
            Image(systemName: log.result == .granted ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(log.result == .granted ? .green : .red)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(log.action.displayName)
                    .font(.body)
                    .fontWeight(.medium)
                
                Text("User: \(log.userId)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(log.result.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(log.result == .granted ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                    .foregroundColor(log.result == .granted ? .green : .red)
                    .cornerRadius(4)
                
                Text(DateFormatter.shortTime.string(from: log.timestamp))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(.systemGray4), lineWidth: 0.5)
        )
    }
}

// MARK: - Create Views

struct CreateRoleView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var permissionsService: UnifiedPermissionsService
    @State private var roleName = ""
    @State private var roleDescription = ""
    @State private var selectedPermissions: Set<PermissionAction> = []
    @State private var isSystemRole = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Role Information") {
                    TextField("Role Name", text: $roleName)
                    TextField("Description", text: $roleDescription, axis: .vertical)
                        .lineLimit(3...6)
                    
                    Toggle("System Role", isOn: $isSystemRole)
                }
                
                Section("Permissions") {
                    ForEach(PermissionAction.allCases, id: \.self) { action in
                        Toggle(action.displayName, isOn: Binding(
                            get: { selectedPermissions.contains(action) },
                            set: { isSelected in
                                if isSelected {
                                    selectedPermissions.insert(action)
                                } else {
                                    selectedPermissions.remove(action)
                                }
                            }
                        ))
                    }
                }
            }
            .navigationTitle("Create Role")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createRole()
                    }
                    .disabled(roleName.isEmpty || roleDescription.isEmpty)
                }
            }
        }
    }
    
    private func createRole() {
        let permissions = selectedPermissions.map { action in
            Permission(
                action: action,
                resource: .any,
                isGranted: true
            )
        }
        
        // Create role logic would go here
        dismiss()
    }
}

struct CreatePolicyView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var permissionsService: UnifiedPermissionsService
    @State private var policyName = ""
    @State private var policyDescription = ""
    @State private var selectedScope: PermissionScope = .global
    @State private var selectedPriority: PolicyPriority = .normal
    @State private var isActive = true
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Policy Information") {
                    TextField("Policy Name", text: $policyName)
                    TextField("Description", text: $policyDescription, axis: .vertical)
                        .lineLimit(3...6)
                    
                    Picker("Scope", selection: $selectedScope) {
                        ForEach(PermissionScope.allCases, id: \.self) { scope in
                            Text(scope.displayName).tag(scope)
                        }
                    }
                    
                    Picker("Priority", selection: $selectedPriority) {
                        ForEach(PolicyPriority.allCases, id: \.self) { priority in
                            Text(priority.displayName).tag(priority)
                        }
                    }
                    
                    Toggle("Active", isOn: $isActive)
                }
                
                Section("Rules") {
                    // Policy rules would be configured here
                    Text("Policy rules configuration would go here")
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Create Policy")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createPolicy()
                    }
                    .disabled(policyName.isEmpty || policyDescription.isEmpty)
                }
            }
        }
    }
    
    private func createPolicy() {
        Task {
            do {
                _ = try await permissionsService.createPermissionPolicy(
                    name: policyName,
                    description: policyDescription,
                    rules: [], // Would be populated from UI
                    scope: selectedScope,
                    priority: selectedPriority,
                    isActive: isActive,
                    createdBy: "current_user" // Would be actual user ID
                )
                dismiss()
            } catch {
                print("Failed to create policy: \(error)")
            }
        }
    }
}

struct AssignRoleView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var permissionsService: UnifiedPermissionsService
    @State private var selectedUserId = ""
    @State private var selectedRoleId = ""
    @State private var selectedScope: PermissionScope = .global
    @State private var expirationDate: Date?
    @State private var hasExpiration = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Assignment Details") {
                    TextField("User ID", text: $selectedUserId)
                    
                    Picker("Role", selection: $selectedRoleId) {
                        Text("Select Role").tag("")
                        ForEach(permissionsService.roleDefinitions) { role in
                            Text(role.name).tag(role.id)
                        }
                    }
                    
                    Picker("Scope", selection: $selectedScope) {
                        ForEach(PermissionScope.allCases, id: \.self) { scope in
                            Text(scope.displayName).tag(scope)
                        }
                    }
                }
                
                Section("Expiration") {
                    Toggle("Set Expiration", isOn: $hasExpiration)
                    
                    if hasExpiration {
                        DatePicker("Expires On", selection: Binding(
                            get: { expirationDate ?? Date().addingTimeInterval(86400 * 30) },
                            set: { expirationDate = $0 }
                        ), displayedComponents: [.date, .hourAndMinute])
                    }
                }
            }
            .navigationTitle("Assign Role")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Assign") {
                        assignRole()
                    }
                    .disabled(selectedUserId.isEmpty || selectedRoleId.isEmpty)
                }
            }
        }
    }
    
    private func assignRole() {
        Task {
            do {
                try await permissionsService.assignRole(
                    userId: selectedUserId,
                    roleId: selectedRoleId,
                    scope: selectedScope,
                    expirationDate: hasExpiration ? expirationDate : nil,
                    assignedBy: "current_user" // Would be actual user ID
                )
                dismiss()
            } catch {
                print("Failed to assign role: \(error)")
            }
        }
    }
}

// MARK: - Detail Views

struct PolicyDetailView: View {
    @ObservedObject var policy: PermissionPolicy
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Policy header details would go here
                    Text("Policy Details View")
                        .font(.title)
                }
                .padding()
            }
            .navigationTitle("Policy Details")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct UserPermissionDetailView: View {
    let userPermissions: UserPermissions
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // User permission details would go here
                    Text("User Permission Details View")
                        .font(.title)
                }
                .padding()
            }
            .navigationTitle("User Permissions")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ResourcePermissionDetailView: View {
    let resourcePermissions: ResourcePermissions
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Resource permission details would go here
                    Text("Resource Permission Details View")
                        .font(.title)
                }
                .padding()
            }
            .navigationTitle("Resource Permissions")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct SecurityReportView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var permissionsService: UnifiedPermissionsService
    @State private var report: SecurityAuditReport?
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Generating Report...")
                } else if let report = report {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            // Security report details would go here
                            Text("Security Audit Report")
                                .font(.title)
                            
                            Text("Total Checks: \(report.totalPermissionChecks)")
                            Text("Successful: \(report.successfulChecks)")
                            Text("Denied: \(report.deniedChecks)")
                        }
                        .padding()
                    }
                } else {
                    Text("No report available")
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Security Report")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                await generateReport()
            }
        }
    }
    
    private func generateReport() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            report = try await permissionsService.generateSecurityAuditReport(
                timeRange: .lastMonth,
                includePermissionChanges: true,
                includeAccessAttempts: true,
                includeViolations: true
            )
        } catch {
            print("Failed to generate report: \(error)")
        }
    }
}

// MARK: - Extensions

extension TimeRange {
    static let lastDay = TimeRange(startDate: Calendar.current.date(byAdding: .day, value: -1, to: Date())!)
    static let lastWeek = TimeRange(startDate: Calendar.current.date(byAdding: .weekOfYear, value: -1, to: Date())!)
    static let lastMonth = TimeRange(startDate: Calendar.current.date(byAdding: .month, value: -1, to: Date())!)
    static let lastQuarter = TimeRange(startDate: Calendar.current.date(byAdding: .month, value: -3, to: Date())!)
}

struct TimeRange {
    let startDate: Date
    let endDate: Date = Date()
}

extension DateFormatter {
    static let medium: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    static let short: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()
    
    static let shortTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
}

struct ComplianceViolation {
    let id: String
    let type: String
    let severity: String
    let description: String
    let detectedAt: Date
}

#Preview {
    PermissionsManagementView()
        .environmentObject(UnifiedPermissionsService.shared)
}
