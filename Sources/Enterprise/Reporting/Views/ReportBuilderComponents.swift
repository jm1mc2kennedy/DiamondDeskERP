import SwiftUI

// MARK: - Report Builder Supporting Views

// MARK: - Report Type Card

public struct ReportTypeCard: View {
    let type: ReportType
    let isSelected: Bool
    let onTap: () -> Void
    
    public var body: some View {
        VStack(spacing: 8) {
            Image(systemName: type.systemImage)
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(isSelected ? .white : .accentColor)
            
            Text(type.displayName)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .primary)
                .multilineTextAlignment(.center)
        }
        .frame(height: 80)
        .frame(maxWidth: .infinity)
        .background(isSelected ? Color.accentColor : Color.secondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
        )
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - Access Level Option

public struct AccessLevelOption: View {
    let title: String
    let description: String
    let icon: String
    let isSelected: Bool
    let onTap: () -> Void
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .accentColor)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            
            Text(description)
                .font(.caption)
                .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                .multilineTextAlignment(.leading)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isSelected ? Color.accentColor : Color.secondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
        )
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - Date Range Picker

public struct DateRangePicker: View {
    @Binding var startDate: Date
    @Binding var endDate: Date
    @Binding var presetRange: DatePreset
    
    public var body: some View {
        VStack(spacing: 12) {
            // Preset Ranges
            Picker("Date Range", selection: $presetRange) {
                ForEach(DatePreset.allCases, id: \.self) { preset in
                    Text(preset.displayName)
                        .tag(preset)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: presetRange) { _, newValue in
                let (start, end) = newValue.dateRange
                startDate = start
                endDate = end
            }
            
            // Custom Date Range (if custom is selected)
            if presetRange == .custom {
                VStack(spacing: 8) {
                    HStack {
                        Text("From:")
                            .frame(width: 50, alignment: .leading)
                        
                        DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                            .datePickerStyle(.compact)
                    }
                    
                    HStack {
                        Text("To:")
                            .frame(width: 50, alignment: .leading)
                        
                        DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                            .datePickerStyle(.compact)
                    }
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
}

// MARK: - Field Toggle

public struct FieldToggle: View {
    let field: String
    let isSelected: Bool
    let onTap: () -> Void
    
    public var body: some View {
        HStack {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isSelected ? .accentColor : .secondary)
            
            Text(field)
                .font(.subheadline)
                .foregroundColor(isSelected ? .primary : .secondary)
            
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - Data Preview Card

public struct DataPreviewCard: View {
    let dataSource: ReportDataSource
    let fields: [String]
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Sample Data")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(sampleData.count) rows")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 4) {
                    // Header
                    HStack(spacing: 0) {
                        ForEach(fields, id: \.self) { field in
                            Text(field)
                                .font(.caption)
                                .fontWeight(.bold)
                                .frame(minWidth: 80, alignment: .leading)
                                .padding(.horizontal, 4)
                        }
                    }
                    .padding(.bottom, 4)
                    
                    // Sample rows
                    ForEach(sampleData.indices, id: \.self) { index in
                        HStack(spacing: 0) {
                            ForEach(fields, id: \.self) { field in
                                Text(sampleData[index][field] ?? "—")
                                    .font(.caption)
                                    .frame(minWidth: 80, alignment: .leading)
                                    .padding(.horizontal, 4)
                            }
                        }
                        .padding(.vertical, 2)
                        .background(index % 2 == 0 ? Color.clear : Color.secondary.opacity(0.05))
                    }
                }
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private var sampleData: [[String: String]] {
        switch dataSource {
        case .sales:
            return [
                ["Revenue": "$5,200", "Units Sold": "15", "Customer": "Acme Corp", "Product": "Widget A", "Date": "2024-01-15", "Region": "North", "Salesperson": "John Doe"],
                ["Revenue": "$3,800", "Units Sold": "12", "Customer": "Tech Co", "Product": "Widget B", "Date": "2024-01-14", "Region": "South", "Salesperson": "Jane Smith"],
                ["Revenue": "$7,100", "Units Sold": "22", "Customer": "Global Inc", "Product": "Widget A", "Date": "2024-01-13", "Region": "East", "Salesperson": "Bob Johnson"]
            ]
        case .financial:
            return [
                ["Amount": "$2,500.00", "Account": "Revenue", "Date": "2024-01-15", "Category": "Sales", "Description": "Product sales", "Reference": "INV-001"],
                ["Amount": "$850.00", "Account": "Expenses", "Date": "2024-01-14", "Category": "Office", "Description": "Office supplies", "Reference": "EXP-002"],
                ["Amount": "$1,200.00", "Account": "Revenue", "Date": "2024-01-13", "Category": "Services", "Description": "Consulting", "Reference": "INV-003"]
            ]
        case .customers:
            return [
                ["Name": "Alice Johnson", "Email": "alice@example.com", "Phone": "(555) 123-4567", "Company": "ABC Corp", "Registration Date": "2024-01-10", "Status": "Active", "Location": "New York"],
                ["Name": "Bob Smith", "Email": "bob@example.com", "Phone": "(555) 987-6543", "Company": "XYZ Inc", "Registration Date": "2024-01-08", "Status": "Active", "Location": "California"],
                ["Name": "Carol Davis", "Email": "carol@example.com", "Phone": "(555) 456-7890", "Company": "123 LLC", "Registration Date": "2024-01-05", "Status": "Pending", "Location": "Texas"]
            ]
        case .inventory:
            return [
                ["Product": "Widget A", "SKU": "WA-001", "Quantity": "150", "Location": "Warehouse A", "Value": "$3,750", "Last Updated": "2024-01-15", "Supplier": "Supplier Co"],
                ["Product": "Widget B", "SKU": "WB-002", "Quantity": "75", "Location": "Warehouse B", "Value": "$2,250", "Last Updated": "2024-01-14", "Supplier": "Parts Inc"],
                ["Product": "Widget C", "SKU": "WC-003", "Quantity": "200", "Location": "Warehouse A", "Value": "$5,000", "Last Updated": "2024-01-13", "Supplier": "Global Supply"]
            ]
        case .employees:
            return [
                ["Name": "John Doe", "Department": "Sales", "Position": "Sales Manager", "Hire Date": "2023-03-15", "Salary": "$75,000", "Performance": "Excellent", "Manager": "Sarah Wilson"],
                ["Name": "Jane Smith", "Department": "Marketing", "Position": "Marketing Specialist", "Hire Date": "2023-06-01", "Salary": "$60,000", "Performance": "Good", "Manager": "Mike Brown"],
                ["Name": "Bob Johnson", "Department": "Engineering", "Position": "Software Engineer", "Hire Date": "2023-01-10", "Salary": "$90,000", "Performance": "Excellent", "Manager": "Lisa Chen"]
            ]
        case .tasks:
            return [
                ["Title": "Update website", "Status": "In Progress", "Priority": "High", "Assignee": "John Doe", "Due Date": "2024-01-20", "Created Date": "2024-01-10", "Project": "Website Redesign"],
                ["Title": "Review contracts", "Status": "Pending", "Priority": "Medium", "Assignee": "Jane Smith", "Due Date": "2024-01-18", "Created Date": "2024-01-08", "Project": "Legal Review"],
                ["Title": "Database backup", "Status": "Completed", "Priority": "High", "Assignee": "Bob Johnson", "Due Date": "2024-01-15", "Created Date": "2024-01-05", "Project": "IT Maintenance"]
            ]
        case .tickets:
            return [
                ["Subject": "Login issue", "Status": "Open", "Priority": "High", "Customer": "Alice Johnson", "Agent": "Support Agent 1", "Created Date": "2024-01-15", "Category": "Technical"],
                ["Subject": "Billing question", "Status": "Resolved", "Priority": "Medium", "Customer": "Bob Smith", "Agent": "Support Agent 2", "Created Date": "2024-01-14", "Category": "Billing"],
                ["Subject": "Feature request", "Status": "In Progress", "Priority": "Low", "Customer": "Carol Davis", "Agent": "Support Agent 3", "Created Date": "2024-01-13", "Category": "Enhancement"]
            ]
        case .custom:
            return [
                ["Field 1": "Value 1A", "Field 2": "Value 2A", "Field 3": "Value 3A", "Field 4": "Value 4A", "Field 5": "Value 5A"],
                ["Field 1": "Value 1B", "Field 2": "Value 2B", "Field 3": "Value 3B", "Field 4": "Value 4B", "Field 5": "Value 5B"],
                ["Field 1": "Value 1C", "Field 2": "Value 2C", "Field 3": "Value 3C", "Field 4": "Value 4C", "Field 5": "Value 5C"]
            ]
        }
    }
}

// MARK: - Quick Filter Toggle

public struct QuickFilterToggle: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void
    
    public var body: some View {
        Text(title)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.accentColor : Color.secondary.opacity(0.2))
            .foregroundColor(isSelected ? .white : .primary)
            .clipShape(Capsule())
            .onTapGesture {
                onTap()
            }
    }
}

// MARK: - Custom Filter Row

public struct CustomFilterRow: View {
    @Binding var filter: CustomFilter
    let availableFields: [String]
    let onDelete: () -> Void
    
    public var body: some View {
        VStack(spacing: 8) {
            HStack {
                // Field Picker
                Picker("Field", selection: $filter.field) {
                    ForEach(availableFields, id: \.self) { field in
                        Text(field).tag(field)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity)
                
                // Operator Picker
                Picker("Operator", selection: $filter.operator) {
                    ForEach(FilterOperator.allCases, id: \.self) { op in
                        Text(op.displayName).tag(op)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity)
                
                // Delete Button
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
            }
            
            // Value Input
            TextField("Filter value", text: $filter.value)
                .textFieldStyle(.roundedBorder)
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Visualization Type Card

public struct VisualizationTypeCard: View {
    let type: VisualizationType
    let isSelected: Bool
    let onTap: () -> Void
    
    public var body: some View {
        VStack(spacing: 8) {
            Image(systemName: type.systemImage)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(isSelected ? .white : .accentColor)
            
            Text(type.displayName)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .primary)
                .multilineTextAlignment(.center)
        }
        .frame(height: 60)
        .frame(maxWidth: .infinity)
        .background(isSelected ? Color.accentColor : Color.secondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
        )
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - Additional Visualization Row

public struct AdditionalVisualizationRow: View {
    @Binding var visualization: AdditionalVisualization
    let availableFields: [String]
    let onDelete: () -> Void
    
    public var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Chart \(visualization.id.uuidString.prefix(8))")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
            }
            
            HStack {
                Picker("Type", selection: $visualization.type) {
                    ForEach(VisualizationType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity)
                
                if visualization.type != .table {
                    Picker("X-Axis", selection: $visualization.xAxis) {
                        ForEach(availableFields, id: \.self) { field in
                            Text(field).tag(field)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity)
                    
                    Picker("Y-Axis", selection: $visualization.yAxis) {
                        ForEach(availableFields, id: \.self) { field in
                            Text(field).tag(field)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Color Theme Card

public struct ColorThemeCard: View {
    let theme: ColorTheme
    let isSelected: Bool
    let onTap: () -> Void
    
    public var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                ForEach(theme.colors, id: \.self) { color in
                    Circle()
                        .fill(Color(color))
                        .frame(width: 12, height: 12)
                }
            }
            
            Text(theme.displayName)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .primary)
        }
        .frame(height: 60)
        .frame(maxWidth: .infinity)
        .background(isSelected ? Color.accentColor : Color.secondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
        )
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - Export Format Toggle

public struct ExportFormatToggle: View {
    let format: ExportFormat
    let isSelected: Bool
    let onTap: () -> Void
    
    public var body: some View {
        HStack {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isSelected ? .accentColor : .secondary)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(format.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(format.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - Review Section

public struct ReviewSection<Content: View>: View {
    let title: String
    let content: Content
    
    public init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 4) {
                content
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

// MARK: - Review Item

public struct ReviewItem: View {
    let label: String
    let value: String
    
    public var body: some View {
        HStack {
            Text(label + ":")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 100, alignment: .leading)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Spacer()
        }
    }
}

// MARK: - Report Filters View

public struct ReportFiltersView: View {
    @ObservedObject var viewModel: ReportingViewModel
    @Environment(\.dismiss) private var dismiss
    
    public var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Category Filter
                VStack(alignment: .leading, spacing: 8) {
                    Text("Category")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 8) {
                        ForEach(ReportCategory.allCases, id: \.self) { category in
                            QuickFilterToggle(
                                title: category.displayName,
                                isSelected: viewModel.categoryFilter == category
                            ) {
                                viewModel.categoryFilter = viewModel.categoryFilter == category ? nil : category
                            }
                        }
                    }
                }
                
                // Type Filter
                VStack(alignment: .leading, spacing: 8) {
                    Text("Type")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 8) {
                        ForEach(ReportType.allCases, id: \.self) { type in
                            QuickFilterToggle(
                                title: type.displayName,
                                isSelected: viewModel.typeFilter == type
                            ) {
                                viewModel.typeFilter = viewModel.typeFilter == type ? nil : type
                            }
                        }
                    }
                }
                
                // Status Filter
                VStack(alignment: .leading, spacing: 8) {
                    Text("Status")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    HStack(spacing: 12) {
                        QuickFilterToggle(
                            title: "Active Only",
                            isSelected: viewModel.showActiveOnly
                        ) {
                            viewModel.showActiveOnly.toggle()
                        }
                        
                        QuickFilterToggle(
                            title: "Public Only",
                            isSelected: viewModel.showPublicOnly
                        ) {
                            viewModel.showPublicOnly.toggle()
                        }
                        
                        Spacer()
                    }
                }
                
                Spacer()
                
                // Action Buttons
                HStack(spacing: 16) {
                    Button("Clear All") {
                        viewModel.clearFilters()
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
                    
                    Button("Apply") {
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                }
            }
            .padding()
            .navigationTitle("Filters")
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

// MARK: - Create Report View

public struct CreateReportView: View {
    @ObservedObject var viewModel: ReportingViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var reportName = ""
    @State private var reportDescription = ""
    @State private var selectedCategory = ReportCategory.sales
    @State private var selectedType = ReportType.standard
    @State private var isPublic = false
    
    public var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Report Name")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        TextField("Enter report name", text: $reportName)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        TextEditor(text: $reportDescription)
                            .frame(minHeight: 80)
                            .padding(8)
                            .background(Color.secondary.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Category")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Picker("Category", selection: $selectedCategory) {
                            ForEach(ReportCategory.allCases, id: \.self) { category in
                                Text(category.displayName)
                                    .tag(category)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Type")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Picker("Type", selection: $selectedType) {
                            ForEach(ReportType.allCases, id: \.self) { type in
                                Text(type.displayName)
                                    .tag(type)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    
                    Toggle("Make Public", isOn: $isPublic)
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                HStack(spacing: 16) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
                    
                    Button("Create") {
                        Task {
                            await viewModel.createQuickReport(
                                name: reportName,
                                description: reportDescription,
                                category: selectedCategory,
                                type: selectedType,
                                isPublic: isPublic
                            )
                            dismiss()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                    .disabled(reportName.isEmpty)
                }
            }
            .padding()
            .navigationTitle("Create Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Create Dashboard View

public struct CreateDashboardView: View {
    @ObservedObject var viewModel: ReportingViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var dashboardName = ""
    @State private var dashboardDescription = ""
    @State private var isDefault = false
    
    public var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Dashboard Name")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        TextField("Enter dashboard name", text: $dashboardName)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        TextEditor(text: $dashboardDescription)
                            .frame(minHeight: 80)
                            .padding(8)
                            .background(Color.secondary.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    
                    Toggle("Set as Default Dashboard", isOn: $isDefault)
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                HStack(spacing: 16) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
                    
                    Button("Create") {
                        Task {
                            await viewModel.createDashboard(
                                name: dashboardName,
                                description: dashboardDescription.isEmpty ? nil : dashboardDescription,
                                isDefault: isDefault
                            )
                            dismiss()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                    .disabled(dashboardName.isEmpty)
                }
            }
            .padding()
            .navigationTitle("Create Dashboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Report Preview View

public struct ReportPreviewView: View {
    @ObservedObject var viewModel: ReportingViewModel
    @Environment(\.dismiss) private var dismiss
    
    public var body: some View {
        NavigationView {
            VStack {
                Text("Report Preview")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding()
                
                Text("Preview functionality will show a sample of your report based on current settings")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Spacer()
            }
            .navigationTitle("Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}
