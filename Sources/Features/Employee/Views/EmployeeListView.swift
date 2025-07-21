import SwiftUI

struct EmployeeListView: View {
    @StateObject private var viewModel = EmployeeViewModel()
    @State private var showingFilters = false
    @State private var selectedEmployee: Employee?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Stats Header
                if let stats = viewModel.employeeStats {
                    EmployeeStatsHeader(stats: stats)
                        .padding(.horizontal)
                }
                
                // Search and Filter Bar
                SearchFilterBar(viewModel: viewModel, showingFilters: $showingFilters)
                
                // Main Content
                Group {
                    switch viewModel.viewMode {
                    case .list:
                        EmployeeListContent(viewModel: viewModel)
                    case .grid:
                        EmployeeGridContent(viewModel: viewModel)
                    case .table:
                        EmployeeTableContent(viewModel: viewModel)
                    }
                }
                .refreshable {
                    await viewModel.refreshData()
                }
            }
            .navigationTitle("Employees")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Menu {
                        Picker("View Mode", selection: $viewModel.viewMode) {
                            ForEach(EmployeeViewMode.allCases, id: \.self) { mode in
                                Label(mode.rawValue, systemImage: mode.icon)
                                    .tag(mode)
                            }
                        }
                        
                        Divider()
                        
                        Button(action: { showingFilters = true }) {
                            Label("Filters", systemImage: "line.3.horizontal.decrease.circle")
                        }
                        
                        Button(action: { viewModel.clearFilters() }) {
                            Label("Clear Filters", systemImage: "xmark.circle")
                        }
                        
                        Divider()
                        
                        Button(action: { Task { await viewModel.refreshData() } }) {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    
                    Button(action: { viewModel.showingCreateEmployee = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .searchable(text: $viewModel.searchText, prompt: "Search employees...")
            .sheet(isPresented: $viewModel.showingCreateEmployee) {
                EmployeeCreationView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingFilters) {
                EmployeeFiltersView(viewModel: viewModel)
            }
            .sheet(item: $selectedEmployee) { employee in
                EmployeeDetailView(employee: employee, viewModel: viewModel)
            }
            .alert("Error", isPresented: $viewModel.showingError) {
                Button("OK") {
                    viewModel.clearError()
                }
            } message: {
                Text(viewModel.error?.localizedDescription ?? "Unknown error occurred")
            }
        }
        .task {
            await viewModel.loadEmployees()
        }
    }
}

// MARK: - Stats Header

struct EmployeeStatsHeader: View {
    let stats: EmployeeStatistics
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 20) {
                StatItem(
                    title: "Total",
                    value: "\(stats.totalEmployees)",
                    icon: "person.2",
                    color: .blue
                )
                
                StatItem(
                    title: "Active",
                    value: "\(stats.activeEmployees)",
                    icon: "person.check",
                    color: .green
                )
                
                StatItem(
                    title: "Inactive",
                    value: "\(stats.inactiveEmployees)",
                    icon: "person.slash",
                    color: .orange
                )
                
                StatItem(
                    title: "Avg Tenure",
                    value: String(format: "%.1f years", stats.averageTenure),
                    icon: "calendar",
                    color: .purple
                )
            }
            
            if stats.newHiresThisMonth > 0 || stats.upcomingReviews > 0 || stats.birthdaysThisWeek > 0 {
                HStack(spacing: 16) {
                    if stats.newHiresThisMonth > 0 {
                        AlertItem(
                            title: "New Hires",
                            value: "\(stats.newHiresThisMonth)",
                            icon: "person.badge.plus",
                            color: .green
                        )
                    }
                    
                    if stats.upcomingReviews > 0 {
                        AlertItem(
                            title: "Reviews Due",
                            value: "\(stats.upcomingReviews)",
                            icon: "doc.text",
                            color: .orange
                        )
                    }
                    
                    if stats.birthdaysThisWeek > 0 {
                        AlertItem(
                            title: "Birthdays",
                            value: "\(stats.birthdaysThisWeek)",
                            icon: "gift",
                            color: .pink
                        )
                    }
                }
                .font(.caption)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct StatItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct AlertItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(color)
            
            Text("\(value) \(title)")
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Search and Filter Bar

struct SearchFilterBar: View {
    @ObservedObject var viewModel: EmployeeViewModel
    @Binding var showingFilters: Bool
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // Department Filter
                if let selectedDepartment = viewModel.selectedDepartment {
                    FilterChip(
                        title: "Dept: \(selectedDepartment)",
                        isActive: true
                    ) {
                        viewModel.selectedDepartment = nil
                    }
                }
                
                // Role Filter
                if let selectedRole = viewModel.selectedRole {
                    FilterChip(
                        title: "Role: \(selectedRole.displayName)",
                        isActive: true
                    ) {
                        viewModel.selectedRole = nil
                    }
                }
                
                // Status Filter
                if viewModel.selectedStatus != .active {
                    FilterChip(
                        title: "Status: \(viewModel.selectedStatus.rawValue)",
                        isActive: true
                    ) {
                        viewModel.selectedStatus = .active
                    }
                }
                
                // Sort Order
                FilterChip(
                    title: viewModel.sortOrder.rawValue,
                    isActive: false
                ) {
                    // Open sort menu
                }
                
                // More Filters Button
                Button(action: { showingFilters = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "line.3.horizontal.decrease")
                        Text("Filters")
                    }
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
}

struct FilterChip: View {
    let title: String
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(title)
                
                if isActive {
                    Image(systemName: "xmark")
                        .font(.caption2)
                }
            }
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(isActive ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
            .foregroundColor(isActive ? .blue : .primary)
            .cornerRadius(12)
        }
    }
}

// MARK: - List Content

struct EmployeeListContent: View {
    @ObservedObject var viewModel: EmployeeViewModel
    
    var body: some View {
        List {
            if viewModel.isLoading && viewModel.employees.isEmpty {
                ForEach(0..<10, id: \.self) { _ in
                    EmployeeRowSkeleton()
                }
            } else if viewModel.filteredEmployees.isEmpty {
                EmptyStateView(
                    icon: "person.3",
                    title: "No Employees Found",
                    subtitle: viewModel.searchText.isEmpty ? 
                        "Add your first employee to get started" : 
                        "Try adjusting your search or filters"
                ) {
                    if viewModel.searchText.isEmpty {
                        Button("Add Employee") {
                            viewModel.showingCreateEmployee = true
                        }
                        .buttonStyle(.borderedProminent)
                    } else {
                        Button("Clear Search") {
                            viewModel.searchText = ""
                        }
                        .buttonStyle(.bordered)
                    }
                }
            } else {
                ForEach(viewModel.filteredEmployees, id: \.id) { employee in
                    EmployeeRow(employee: employee, viewModel: viewModel)
                        .onTapGesture {
                            viewModel.selectEmployee(employee)
                            viewModel.showingEmployeeDetail = true
                        }
                }
            }
        }
        .listStyle(PlainListStyle())
    }
}

struct EmployeeRow: View {
    let employee: Employee
    @ObservedObject var viewModel: EmployeeViewModel
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile Image
            AsyncImage(url: employee.profilePhoto.flatMap(URL.init)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Image(systemName: "person.crop.circle.fill")
                    .foregroundColor(.gray)
            }
            .frame(width: 50, height: 50)
            .clipShape(Circle())
            
            // Employee Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(employee.fullName)
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    if !employee.isActive {
                        Text("Inactive")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red.opacity(0.1))
                            .foregroundColor(.red)
                            .cornerRadius(4)
                    }
                }
                
                Text(employee.title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    Label(employee.department, systemImage: "building.2")
                    
                    Spacer()
                    
                    Label(employee.employeeNumber, systemImage: "number")
                }
                .font(.caption)
                .foregroundColor(.secondary)
                
                if !employee.skills.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 4) {
                            ForEach(employee.skills.prefix(3), id: \.self) { skill in
                                Text(skill)
                                    .font(.caption2)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 2)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundColor(.blue)
                                    .cornerRadius(3)
                            }
                            
                            if employee.skills.count > 3 {
                                Text("+\(employee.skills.count - 3)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .contextMenu {
            Button(action: { 
                viewModel.selectEmployee(employee)
                viewModel.showingEmployeeDetail = true 
            }) {
                Label("View Details", systemImage: "info.circle")
            }
            
            Button(action: { 
                viewModel.selectEmployee(employee)
                viewModel.showingEditEmployee = true 
            }) {
                Label("Edit", systemImage: "pencil")
            }
            
            Divider()
            
            if employee.isActive {
                Button(action: { 
                    Task { await viewModel.deactivateEmployee(employee) }
                }) {
                    Label("Deactivate", systemImage: "person.slash")
                }
            } else {
                Button(action: { 
                    Task { await viewModel.reactivateEmployee(employee) }
                }) {
                    Label("Reactivate", systemImage: "person.check")
                }
            }
        }
    }
}

struct EmployeeRowSkeleton: View {
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 50, height: 50)
            
            VStack(alignment: .leading, spacing: 4) {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 16)
                    .cornerRadius(8)
                
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 14)
                    .cornerRadius(7)
                
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 100, height: 12)
                    .cornerRadius(6)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
        .redacted(reason: .placeholder)
    }
}

// MARK: - Grid Content

struct EmployeeGridContent: View {
    @ObservedObject var viewModel: EmployeeViewModel
    
    private let columns = [
        GridItem(.adaptive(minimum: 160, maximum: 200), spacing: 16)
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                if viewModel.isLoading && viewModel.employees.isEmpty {
                    ForEach(0..<10, id: \.self) { _ in
                        EmployeeCardSkeleton()
                    }
                } else {
                    ForEach(viewModel.filteredEmployees, id: \.id) { employee in
                        EmployeeCard(employee: employee, viewModel: viewModel)
                            .onTapGesture {
                                viewModel.selectEmployee(employee)
                                viewModel.showingEmployeeDetail = true
                            }
                    }
                }
            }
            .padding()
        }
    }
}

struct EmployeeCard: View {
    let employee: Employee
    @ObservedObject var viewModel: EmployeeViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            // Profile Image
            AsyncImage(url: employee.profilePhoto.flatMap(URL.init)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Image(systemName: "person.crop.circle.fill")
                    .foregroundColor(.gray)
            }
            .frame(width: 60, height: 60)
            .clipShape(Circle())
            
            // Employee Info
            VStack(spacing: 4) {
                Text(employee.fullName)
                    .font(.headline)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                
                Text(employee.title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                
                Text(employee.department)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            // Status Badge
            HStack {
                if employee.isActive {
                    Label("Active", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                } else {
                    Label("Inactive", systemImage: "xmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .contentShape(Rectangle())
    }
}

struct EmployeeCardSkeleton: View {
    var body: some View {
        VStack(spacing: 12) {
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 60, height: 60)
            
            VStack(spacing: 4) {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 16)
                    .cornerRadius(8)
                
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 14)
                    .cornerRadius(7)
                
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 12)
                    .cornerRadius(6)
            }
            
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 12)
                .cornerRadius(6)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .redacted(reason: .placeholder)
    }
}

// MARK: - Table Content

struct EmployeeTableContent: View {
    @ObservedObject var viewModel: EmployeeViewModel
    
    var body: some View {
        Table(viewModel.filteredEmployees) {
            TableColumn("Name") { employee in
                HStack {
                    AsyncImage(url: employee.profilePhoto.flatMap(URL.init)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Image(systemName: "person.crop.circle.fill")
                            .foregroundColor(.gray)
                    }
                    .frame(width: 30, height: 30)
                    .clipShape(Circle())
                    
                    Text(employee.fullName)
                }
            }
            
            TableColumn("Title", value: \.title)
            TableColumn("Department", value: \.department)
            TableColumn("Employee #", value: \.employeeNumber)
            
            TableColumn("Status") { employee in
                Text(employee.isActive ? "Active" : "Inactive")
                    .foregroundColor(employee.isActive ? .green : .red)
            }
            
            TableColumn("Hire Date") { employee in
                Text(employee.hireDate, style: .date)
            }
        }
    }
}

// MARK: - Empty State

struct EmptyStateView<ActionView: View>: View {
    let icon: String
    let title: String
    let subtitle: String
    let actionView: ActionView
    
    init(icon: String, title: String, subtitle: String, @ViewBuilder actionView: () -> ActionView) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.actionView = actionView()
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(subtitle)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            actionView
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    EmployeeListView()
}
