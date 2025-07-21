import SwiftUI

struct EmployeeDetailView: View {
    let employee: Employee
    @ObservedObject var viewModel: EmployeeViewModel
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var selectedTab: DetailTab = .overview
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header Section
                EmployeeHeaderView(employee: employee)
                
                // Tab Selector
                Picker("Section", selection: $selectedTab) {
                    ForEach(DetailTab.allCases, id: \.self) { tab in
                        Text(tab.title).tag(tab)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // Tab Content
                TabView(selection: $selectedTab) {
                    OverviewTab(employee: employee, viewModel: viewModel)
                        .tag(DetailTab.overview)
                    
                    ContactTab(employee: employee)
                        .tag(DetailTab.contact)
                    
                    OrganizationTab(employee: employee, viewModel: viewModel)
                        .tag(DetailTab.organization)
                    
                    PerformanceTab(employee: employee, viewModel: viewModel)
                        .tag(DetailTab.performance)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle(employee.fullName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showingEditSheet = true }) {
                            Label("Edit Employee", systemImage: "pencil")
                        }
                        
                        Divider()
                        
                        if employee.isActive {
                            Button(action: { 
                                Task { await viewModel.deactivateEmployee(employee) }
                                dismiss()
                            }) {
                                Label("Deactivate", systemImage: "person.slash")
                            }
                        } else {
                            Button(action: { 
                                Task { await viewModel.reactivateEmployee(employee) }
                                dismiss()
                            }) {
                                Label("Reactivate", systemImage: "person.check")
                            }
                        }
                        
                        Divider()
                        
                        Button(role: .destructive, action: { showingDeleteAlert = true }) {
                            Label("Delete Employee", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingEditSheet) {
                EmployeeEditView(employee: employee, viewModel: viewModel)
            }
            .alert("Delete Employee", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    Task {
                        await viewModel.deleteEmployee(employee)
                        dismiss()
                    }
                }
            } message: {
                Text("Are you sure you want to delete \(employee.fullName)? This action cannot be undone.")
            }
        }
        .task {
            await viewModel.loadPerformanceMetrics(for: employee)
        }
    }
}

// MARK: - Header View

struct EmployeeHeaderView: View {
    let employee: Employee
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                // Profile Image
                AsyncImage(url: employee.profilePhoto.flatMap(URL.init)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "person.crop.circle.fill")
                        .foregroundColor(.gray)
                }
                .frame(width: 80, height: 80)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color(.systemGray5), lineWidth: 2)
                )
                
                // Basic Info
                VStack(alignment: .leading, spacing: 8) {
                    Text(employee.fullName)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(employee.title)
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Label(employee.department, systemImage: "building.2")
                        
                        Spacer()
                        
                        StatusBadge(isActive: employee.isActive)
                    }
                    .font(.subheadline)
                }
                
                Spacer()
            }
            
            // Quick Stats
            HStack(spacing: 20) {
                QuickStat(
                    title: "Employee #",
                    value: employee.employeeNumber,
                    icon: "number"
                )
                
                QuickStat(
                    title: "Hire Date",
                    value: formatDate(employee.hireDate),
                    icon: "calendar"
                )
                
                QuickStat(
                    title: "Tenure",
                    value: formatTenure(employee.hireDate),
                    icon: "clock"
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func formatTenure(_ hireDate: Date) -> String {
        let components = Calendar.current.dateComponents([.year, .month], from: hireDate, to: Date())
        let years = components.year ?? 0
        let months = components.month ?? 0
        
        if years > 0 {
            return "\(years)y \(months)m"
        } else {
            return "\(months)m"
        }
    }
}

struct StatusBadge: View {
    let isActive: Bool
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: isActive ? "checkmark.circle.fill" : "xmark.circle.fill")
            Text(isActive ? "Active" : "Inactive")
        }
        .font(.caption)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(isActive ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
        .foregroundColor(isActive ? .green : .red)
        .cornerRadius(8)
    }
}

struct QuickStat: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Detail Tabs

enum DetailTab: String, CaseIterable {
    case overview = "Overview"
    case contact = "Contact"
    case organization = "Organization"
    case performance = "Performance"
    
    var title: String {
        return rawValue
    }
    
    var icon: String {
        switch self {
        case .overview: return "person.text.rectangle"
        case .contact: return "phone"
        case .organization: return "building.2"
        case .performance: return "chart.line.uptrend.xyaxis"
        }
    }
}

// MARK: - Overview Tab

struct OverviewTab: View {
    let employee: Employee
    @ObservedObject var viewModel: EmployeeViewModel
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Personal Information
                PersonalInfoSection(employee: employee)
                
                // Employment Information
                EmploymentInfoSection(employee: employee)
                
                // Skills & Certifications
                SkillsSection(employee: employee)
                
                // Recent Activity
                RecentActivitySection(employee: employee)
            }
            .padding()
        }
    }
}

struct PersonalInfoSection: View {
    let employee: Employee
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Personal Information")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                InfoRow(title: "Full Name", value: employee.fullName)
                InfoRow(title: "Email", value: employee.email)
                
                if let phone = employee.phone {
                    InfoRow(title: "Phone", value: phone)
                }
                
                if let birthDate = employee.birthDate {
                    InfoRow(title: "Date of Birth", value: formatDate(birthDate))
                }
                
                InfoRow(title: "Work Location", value: employee.workLocation.displayName)
                InfoRow(title: "Employment Type", value: employee.employmentType.displayName)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 1)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }
}

struct EmploymentInfoSection: View {
    let employee: Employee
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Employment Information")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                InfoRow(title: "Employee Number", value: employee.employeeNumber)
                InfoRow(title: "Job Title", value: employee.title)
                InfoRow(title: "Department", value: employee.department)
                InfoRow(title: "Hire Date", value: formatDate(employee.hireDate))
                
                if let salaryGrade = employee.salaryGrade {
                    InfoRow(title: "Salary Grade", value: salaryGrade)
                }
                
                if let securityClearance = employee.securityClearance {
                    InfoRow(title: "Security Clearance", value: securityClearance.displayName)
                }
                
                if let lastReviewDate = employee.lastReviewDate {
                    InfoRow(title: "Last Review", value: formatDate(lastReviewDate))
                }
                
                if let nextReviewDate = employee.nextReviewDate {
                    InfoRow(title: "Next Review", value: formatDate(nextReviewDate))
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 1)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct SkillsSection: View {
    let employee: Employee
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Skills & Certifications")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 12) {
                if !employee.skills.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Skills")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        FlowLayout(spacing: 8) {
                            ForEach(employee.skills, id: \.self) { skill in
                                SkillTag(skill: skill)
                            }
                        }
                    }
                }
                
                if !employee.certifications.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Certifications")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        ForEach(employee.certifications, id: \.id) { certification in
                            CertificationRow(certification: certification)
                        }
                    }
                }
                
                if employee.skills.isEmpty && employee.certifications.isEmpty {
                    Text("No skills or certifications listed")
                        .foregroundColor(.secondary)
                        .italic()
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 1)
    }
}

struct SkillTag: View {
    let skill: String
    
    var body: some View {
        Text(skill)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.blue.opacity(0.1))
            .foregroundColor(.blue)
            .cornerRadius(8)
    }
}

struct CertificationRow: View {
    let certification: Certification
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(certification.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(certification.issuingOrganization)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                if certification.isActive {
                    Label("Active", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                } else {
                    Label("Expired", systemImage: "xmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                
                if let expirationDate = certification.expirationDate {
                    Text("Expires: \(formatDate(expirationDate))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

struct RecentActivitySection: View {
    let employee: Employee
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Activity")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                if let lastLoginAt = employee.lastLoginAt {
                    ActivityItem(
                        icon: "person.badge.clock",
                        title: "Last Login",
                        subtitle: formatDateTime(lastLoginAt),
                        color: .blue
                    )
                }
                
                ActivityItem(
                    icon: "calendar.badge.plus",
                    title: "Hired",
                    subtitle: formatDate(employee.hireDate),
                    color: .green
                )
                
                if let lastReviewDate = employee.lastReviewDate {
                    ActivityItem(
                        icon: "doc.text",
                        title: "Last Performance Review",
                        subtitle: formatDate(lastReviewDate),
                        color: .orange
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 1)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct ActivityItem: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Contact Tab

struct ContactTab: View {
    let employee: Employee
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Contact Information
                ContactInfoSection(employee: employee)
                
                // Address Information
                AddressInfoSection(employee: employee)
                
                // Emergency Contact
                EmergencyContactSection(employee: employee)
            }
            .padding()
        }
    }
}

struct ContactInfoSection: View {
    let employee: Employee
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Contact Information")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                ContactRow(
                    icon: "envelope",
                    title: "Email",
                    value: employee.email,
                    action: { openEmail(employee.email) }
                )
                
                if let phone = employee.phone {
                    ContactRow(
                        icon: "phone",
                        title: "Phone",
                        value: phone,
                        action: { openPhone(phone) }
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 1)
    }
    
    private func openEmail(_ email: String) {
        if let url = URL(string: "mailto:\(email)") {
            UIApplication.shared.open(url)
        }
    }
    
    private func openPhone(_ phone: String) {
        let cleanPhone = phone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        if let url = URL(string: "tel:\(cleanPhone)") {
            UIApplication.shared.open(url)
        }
    }
}

struct ContactRow: View {
    let icon: String
    let title: String
    let value: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(value)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct AddressInfoSection: View {
    let employee: Employee
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Address")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(employee.address.street)
                Text("\(employee.address.city), \(employee.address.state) \(employee.address.zipCode)")
                Text(employee.address.country)
            }
            .font(.subheadline)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 1)
    }
}

struct EmergencyContactSection: View {
    let employee: Employee
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Emergency Contact")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                InfoRow(title: "Name", value: employee.emergencyContact.name)
                InfoRow(title: "Relationship", value: employee.emergencyContact.relationship)
                
                ContactRow(
                    icon: "phone",
                    title: "Phone",
                    value: employee.emergencyContact.phone,
                    action: { openPhone(employee.emergencyContact.phone) }
                )
                
                if let email = employee.emergencyContact.email {
                    ContactRow(
                        icon: "envelope",
                        title: "Email",
                        value: email,
                        action: { openEmail(email) }
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 1)
    }
    
    private func openEmail(_ email: String) {
        if let url = URL(string: "mailto:\(email)") {
            UIApplication.shared.open(url)
        }
    }
    
    private func openPhone(_ phone: String) {
        let cleanPhone = phone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        if let url = URL(string: "tel:\(cleanPhone)") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Organization Tab

struct OrganizationTab: View {
    let employee: Employee
    @ObservedObject var viewModel: EmployeeViewModel
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Organizational Structure
                OrganizationStructureSection(employee: employee, viewModel: viewModel)
                
                // Direct Reports
                DirectReportsSection(employee: employee, viewModel: viewModel)
                
                // Hierarchy Chain
                HierarchyChainSection(employee: employee, viewModel: viewModel)
            }
            .padding()
        }
    }
}

struct OrganizationStructureSection: View {
    let employee: Employee
    @ObservedObject var viewModel: EmployeeViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Organizational Information")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                InfoRow(title: "Department", value: employee.department)
                InfoRow(title: "Job Title", value: employee.title)
                
                if let manager = employee.manager,
                   let managerEmployee = viewModel.employees.first(where: { $0.id == manager }) {
                    InfoRow(title: "Manager", value: managerEmployee.fullName)
                }
                
                InfoRow(title: "Direct Reports", value: "\(employee.directReports.count)")
                
                if let costCenter = employee.costCenter {
                    InfoRow(title: "Cost Center", value: costCenter)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 1)
    }
}

struct DirectReportsSection: View {
    let employee: Employee
    @ObservedObject var viewModel: EmployeeViewModel
    
    var directReports: [Employee] {
        viewModel.getDirectReports(for: employee)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Direct Reports")
                .font(.headline)
                .fontWeight(.semibold)
            
            if directReports.isEmpty {
                Text("No direct reports")
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                ForEach(directReports, id: \.id) { report in
                    DirectReportRow(employee: report)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 1)
    }
}

struct DirectReportRow: View {
    let employee: Employee
    
    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: employee.profilePhoto.flatMap(URL.init)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Image(systemName: "person.crop.circle.fill")
                    .foregroundColor(.gray)
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(employee.fullName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(employee.title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct HierarchyChainSection: View {
    let employee: Employee
    @ObservedObject var viewModel: EmployeeViewModel
    
    var managerChain: [Employee] {
        viewModel.getManagerChain(for: employee)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Reporting Chain")
                .font(.headline)
                .fontWeight(.semibold)
            
            if managerChain.isEmpty {
                Text("Top of hierarchy")
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(managerChain.enumerated()), id: \.offset) { index, manager in
                        HStack {
                            Text(String(repeating: "  ", count: index))
                                .font(.caption)
                            
                            Text("↳ \(manager.fullName)")
                                .font(.subheadline)
                            
                            Text("(\(manager.title))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 1)
    }
}

// MARK: - Performance Tab

struct PerformanceTab: View {
    let employee: Employee
    @ObservedObject var viewModel: EmployeeViewModel
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Performance Metrics
                PerformanceMetricsSection(employee: employee, viewModel: viewModel)
                
                // Performance History
                PerformanceHistorySection(employee: employee)
                
                // Goals and Development
                GoalsSection(employee: employee)
            }
            .padding()
        }
    }
}

struct PerformanceMetricsSection: View {
    let employee: Employee
    @ObservedObject var viewModel: EmployeeViewModel
    
    var metrics: PerformanceMetrics? {
        viewModel.performanceMetrics[employee.id]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Performance Metrics")
                .font(.headline)
                .fontWeight(.semibold)
            
            if let metrics = metrics {
                VStack(spacing: 12) {
                    MetricRow(
                        title: "Average Score",
                        value: String(format: "%.1f", metrics.averageScore),
                        icon: "chart.bar",
                        color: .blue
                    )
                    
                    if let latestScore = metrics.latestScore {
                        MetricRow(
                            title: "Latest Score",
                            value: String(format: "%.1f", latestScore),
                            icon: "star",
                            color: .green
                        )
                    }
                    
                    MetricRow(
                        title: "Goal Achievement",
                        value: String(format: "%.0f%%", metrics.goalAchievementRate * 100),
                        icon: "target",
                        color: .orange
                    )
                    
                    MetricRow(
                        title: "Total Reviews",
                        value: "\(metrics.totalReviews)",
                        icon: "doc.text",
                        color: .purple
                    )
                }
            } else {
                ProgressView("Loading performance metrics...")
                    .frame(maxWidth: .infinity)
                    .padding()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 1)
    }
}

struct MetricRow: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
            
            Text(title)
                .font(.subheadline)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
}

struct PerformanceHistorySection: View {
    let employee: Employee
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Performance History")
                .font(.headline)
                .fontWeight(.semibold)
            
            if employee.performanceHistory.isEmpty {
                Text("No performance reviews on record")
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                ForEach(employee.performanceHistory.prefix(5), id: \.id) { review in
                    PerformanceReviewRow(review: review)
                }
                
                if employee.performanceHistory.count > 5 {
                    Button("View All Reviews (\(employee.performanceHistory.count))") {
                        // Navigate to full review history
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 1)
    }
}

struct PerformanceReviewRow: View {
    let review: PerformanceReview
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Review Period")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                RatingBadge(rating: review.overallRating)
            }
            
            Text("\(formatDate(review.reviewPeriodStart)) - \(formatDate(review.reviewPeriodEnd))")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(review.reviewerComments)
                .font(.caption)
                .lineLimit(3)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(.separator)),
            alignment: .bottom
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

struct RatingBadge: View {
    let rating: PerformanceRating
    
    var body: some View {
        Text(rating.displayName)
            .font(.caption)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(colorForRating(rating).opacity(0.2))
            .foregroundColor(colorForRating(rating))
            .cornerRadius(4)
    }
    
    private func colorForRating(_ rating: PerformanceRating) -> Color {
        switch rating {
        case .exceptional:
            return .green
        case .exceeds:
            return .blue
        case .meets:
            return .orange
        case .needs:
            return .red
        case .unsatisfactory:
            return .red
        }
    }
}

struct GoalsSection: View {
    let employee: Employee
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Current Goals")
                .font(.headline)
                .fontWeight(.semibold)
            
            // This would typically show current goals from the latest review
            Text("Goals and development items would be displayed here")
                .foregroundColor(.secondary)
                .italic()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 1)
    }
}

// MARK: - Supporting Views

struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .multilineTextAlignment(.trailing)
        }
    }
}

struct FlowLayout: Layout {
    let spacing: CGFloat
    
    init(spacing: CGFloat = 8) {
        self.spacing = spacing
    }
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        return CGSize(
            width: proposal.width ?? 0,
            height: rows.reduce(0) { $0 + $1.maxHeight } + CGFloat(max(0, rows.count - 1)) * spacing
        )
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        var y = bounds.minY
        
        for row in rows {
            var x = bounds.minX
            
            for subview in row.subviews {
                subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(subview.sizeThatFits(.unspecified)))
                x += subview.sizeThatFits(.unspecified).width + spacing
            }
            
            y += row.maxHeight + spacing
        }
    }
    
    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [Row] {
        var rows: [Row] = []
        var currentRow = Row()
        var x: CGFloat = 0
        let width = proposal.width ?? .infinity
        
        for subview in subviews {
            let subviewSize = subview.sizeThatFits(.unspecified)
            
            if x + subviewSize.width > width && !currentRow.subviews.isEmpty {
                rows.append(currentRow)
                currentRow = Row()
                x = 0
            }
            
            currentRow.subviews.append(subview)
            currentRow.maxHeight = max(currentRow.maxHeight, subviewSize.height)
            x += subviewSize.width + spacing
        }
        
        if !currentRow.subviews.isEmpty {
            rows.append(currentRow)
        }
        
        return rows
    }
    
    private struct Row {
        var subviews: [LayoutSubview] = []
        var maxHeight: CGFloat = 0
    }
}

#Preview {
    EmployeeDetailView(
        employee: Employee(
            employeeNumber: "EMP001",
            firstName: "John",
            lastName: "Doe",
            email: "john.doe@company.com",
            department: "Engineering",
            title: "Senior Developer",
            hireDate: Date(),
            address: Address(street: "123 Main St", city: "San Francisco", state: "CA", zipCode: "94105"),
            emergencyContact: EmergencyContact(name: "Jane Doe", relationship: "Spouse", phone: "555-0123"),
            workLocation: .office,
            employmentType: .fullTime
        ),
        viewModel: EmployeeViewModel()
    )
}
