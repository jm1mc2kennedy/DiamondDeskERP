import SwiftUI
import Charts

// MARK: - Report Builder View

public struct ReportBuilderView: View {
    @ObservedObject var viewModel: ReportingViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedStep = ReportBuilderStep.basic
    @State private var showingPreview = false
    
    public var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Progress Indicator
                buildProgressIndicator
                
                // Content based on step
                ScrollView {
                    VStack(spacing: 24) {
                        switch selectedStep {
                        case .basic:
                            BasicInfoStep(viewModel: viewModel)
                        case .dataSource:
                            DataSourceStep(viewModel: viewModel)
                        case .filters:
                            FiltersStep(viewModel: viewModel)
                        case .visualizations:
                            VisualizationsStep(viewModel: viewModel)
                        case .formatting:
                            FormattingStep(viewModel: viewModel)
                        case .scheduling:
                            SchedulingStep(viewModel: viewModel)
                        case .review:
                            ReviewStep(viewModel: viewModel)
                        }
                    }
                    .padding()
                }
                
                // Navigation buttons
                buildNavigationButtons
            }
            .navigationTitle("Report Builder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if selectedStep == .review {
                        Button("Create") {
                            Task {
                                await viewModel.createReportFromBuilder()
                                dismiss()
                            }
                        }
                        .disabled(!viewModel.isBuilderValid)
                    } else {
                        Button("Preview") {
                            showingPreview = true
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingPreview) {
            ReportPreviewView(viewModel: viewModel)
        }
        .onAppear {
            viewModel.initializeReportBuilder()
        }
    }
    
    private var buildProgressIndicator: some View {
        VStack(spacing: 8) {
            HStack(spacing: 0) {
                ForEach(ReportBuilderStep.allCases, id: \.self) { step in
                    let isCompleted = step.rawValue <= selectedStep.rawValue
                    let isCurrent = step == selectedStep
                    
                    ZStack {
                        Circle()
                            .fill(isCompleted ? Color.accentColor : Color.secondary.opacity(0.3))
                            .frame(width: 24, height: 24)
                        
                        if isCompleted {
                            Image(systemName: isCurrent ? "circle.fill" : "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        } else {
                            Text("\(step.rawValue + 1)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if step != ReportBuilderStep.allCases.last {
                        Rectangle()
                            .fill(isCompleted ? Color.accentColor : Color.secondary.opacity(0.3))
                            .frame(height: 2)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(.horizontal)
            
            Text(selectedStep.displayName)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 16)
        .background(Color.secondary.opacity(0.05))
    }
    
    private var buildNavigationButtons: some View {
        HStack(spacing: 16) {
            if selectedStep != .basic {
                Button("Previous") {
                    withAnimation {
                        selectedStep = ReportBuilderStep(rawValue: selectedStep.rawValue - 1) ?? .basic
                    }
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
            }
            
            if selectedStep != .review {
                Button("Next") {
                    withAnimation {
                        selectedStep = ReportBuilderStep(rawValue: selectedStep.rawValue + 1) ?? .review
                    }
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .disabled(!viewModel.isCurrentStepValid(selectedStep))
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
    }
}

// MARK: - Basic Info Step

public struct BasicInfoStep: View {
    @ObservedObject var viewModel: ReportingViewModel
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            stepHeader(
                title: "Basic Information",
                subtitle: "Start by defining the core details of your report"
            )
            
            VStack(alignment: .leading, spacing: 16) {
                // Report Name
                VStack(alignment: .leading, spacing: 8) {
                    Text("Report Name")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    TextField("Enter report name", text: $viewModel.reportBuilderName)
                        .textFieldStyle(.roundedBorder)
                }
                
                // Description
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    TextEditor(text: $viewModel.reportBuilderDescription)
                        .frame(minHeight: 80)
                        .padding(8)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                // Category
                VStack(alignment: .leading, spacing: 8) {
                    Text("Category")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Picker("Category", selection: $viewModel.reportBuilderCategory) {
                        ForEach(ReportCategory.allCases, id: \.self) { category in
                            Text(category.displayName)
                                .tag(category)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                // Report Type
                VStack(alignment: .leading, spacing: 8) {
                    Text("Report Type")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(ReportType.allCases, id: \.self) { type in
                            ReportTypeCard(
                                type: type,
                                isSelected: viewModel.reportBuilderType == type
                            ) {
                                viewModel.reportBuilderType = type
                            }
                        }
                    }
                }
                
                // Access Level
                VStack(alignment: .leading, spacing: 8) {
                    Text("Access Level")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    HStack(spacing: 16) {
                        AccessLevelOption(
                            title: "Private",
                            description: "Only you can view this report",
                            icon: "lock.fill",
                            isSelected: !viewModel.reportBuilderIsPublic
                        ) {
                            viewModel.reportBuilderIsPublic = false
                        }
                        
                        AccessLevelOption(
                            title: "Public",
                            description: "Anyone in your organization can view",
                            icon: "globe",
                            isSelected: viewModel.reportBuilderIsPublic
                        ) {
                            viewModel.reportBuilderIsPublic = true
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Data Source Step

public struct DataSourceStep: View {
    @ObservedObject var viewModel: ReportingViewModel
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            stepHeader(
                title: "Data Source",
                subtitle: "Select the data sources for your report"
            )
            
            VStack(alignment: .leading, spacing: 16) {
                // Primary Data Source
                VStack(alignment: .leading, spacing: 8) {
                    Text("Primary Data Source")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Picker("Data Source", selection: $viewModel.reportBuilderDataSource) {
                        ForEach(ReportDataSource.allCases, id: \.self) { source in
                            Text(source.displayName)
                                .tag(source)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                // Date Range
                VStack(alignment: .leading, spacing: 8) {
                    Text("Date Range")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    DateRangePicker(
                        startDate: $viewModel.reportBuilderStartDate,
                        endDate: $viewModel.reportBuilderEndDate,
                        presetRange: $viewModel.reportBuilderDatePreset
                    )
                }
                
                // Data Fields
                VStack(alignment: .leading, spacing: 8) {
                    Text("Include Fields")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 8) {
                        ForEach(availableFields, id: \.self) { field in
                            FieldToggle(
                                field: field,
                                isSelected: viewModel.reportBuilderSelectedFields.contains(field)
                            ) {
                                viewModel.toggleBuilderField(field)
                            }
                        }
                    }
                }
                
                // Sample Data Preview
                if !viewModel.reportBuilderSelectedFields.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Data Preview")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        DataPreviewCard(
                            dataSource: viewModel.reportBuilderDataSource,
                            fields: viewModel.reportBuilderSelectedFields
                        )
                    }
                }
            }
        }
    }
    
    private var availableFields: [String] {
        switch viewModel.reportBuilderDataSource {
        case .sales:
            return ["Revenue", "Units Sold", "Customer", "Product", "Date", "Region", "Salesperson"]
        case .financial:
            return ["Amount", "Account", "Date", "Category", "Description", "Reference"]
        case .customers:
            return ["Name", "Email", "Phone", "Company", "Registration Date", "Status", "Location"]
        case .inventory:
            return ["Product", "SKU", "Quantity", "Location", "Value", "Last Updated", "Supplier"]
        case .employees:
            return ["Name", "Department", "Position", "Hire Date", "Salary", "Performance", "Manager"]
        case .tasks:
            return ["Title", "Status", "Priority", "Assignee", "Due Date", "Created Date", "Project"]
        case .tickets:
            return ["Subject", "Status", "Priority", "Customer", "Agent", "Created Date", "Category"]
        case .custom:
            return ["Field 1", "Field 2", "Field 3", "Field 4", "Field 5"]
        }
    }
}

// MARK: - Filters Step

public struct FiltersStep: View {
    @ObservedObject var viewModel: ReportingViewModel
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            stepHeader(
                title: "Filters & Criteria",
                subtitle: "Define filters to narrow down your data"
            )
            
            VStack(alignment: .leading, spacing: 16) {
                // Quick Filters
                VStack(alignment: .leading, spacing: 8) {
                    Text("Quick Filters")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 8) {
                        ForEach(quickFilterOptions, id: \.self) { filter in
                            QuickFilterToggle(
                                title: filter,
                                isSelected: viewModel.reportBuilderQuickFilters.contains(filter)
                            ) {
                                viewModel.toggleBuilderQuickFilter(filter)
                            }
                        }
                    }
                }
                
                // Custom Filters
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Custom Filters")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Button("Add Filter") {
                            viewModel.addBuilderFilter()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    
                    if viewModel.reportBuilderFilters.isEmpty {
                        Text("No custom filters added")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.secondary.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        VStack(spacing: 8) {
                            ForEach(viewModel.reportBuilderFilters.indices, id: \.self) { index in
                                CustomFilterRow(
                                    filter: $viewModel.reportBuilderFilters[index],
                                    availableFields: availableFilterFields,
                                    onDelete: {
                                        viewModel.removeBuilderFilter(at: index)
                                    }
                                )
                            }
                        }
                    }
                }
                
                // Filter Logic
                if viewModel.reportBuilderFilters.count > 1 {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Filter Logic")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Picker("Logic", selection: $viewModel.reportBuilderFilterLogic) {
                            Text("Match ALL filters (AND)").tag(FilterLogic.and)
                            Text("Match ANY filter (OR)").tag(FilterLogic.or)
                        }
                        .pickerStyle(.segmented)
                    }
                }
            }
        }
    }
    
    private var quickFilterOptions: [String] {
        switch viewModel.reportBuilderDataSource {
        case .sales:
            return ["This Month", "Last 30 Days", "Current Quarter", "Top Performers", "New Customers"]
        case .financial:
            return ["Current Month", "Pending Invoices", "Overdue", "High Value", "Recurring"]
        case .customers:
            return ["Active", "New This Month", "VIP Status", "Local", "International"]
        case .inventory:
            return ["Low Stock", "Out of Stock", "High Value", "Recently Updated", "Seasonal"]
        case .employees:
            return ["Active", "New Hires", "Management", "Full Time", "Remote"]
        case .tasks:
            return ["Overdue", "High Priority", "In Progress", "Assigned to Me", "Due This Week"]
        case .tickets:
            return ["Open", "High Priority", "Unassigned", "Escalated", "Customer Critical"]
        case .custom:
            return ["Filter 1", "Filter 2", "Filter 3", "Filter 4", "Filter 5"]
        }
    }
    
    private var availableFilterFields: [String] {
        viewModel.reportBuilderSelectedFields
    }
}

// MARK: - Visualizations Step

public struct VisualizationsStep: View {
    @ObservedObject var viewModel: ReportingViewModel
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            stepHeader(
                title: "Visualizations",
                subtitle: "Choose how to display your data"
            )
            
            VStack(alignment: .leading, spacing: 16) {
                // Primary Visualization
                VStack(alignment: .leading, spacing: 8) {
                    Text("Primary Chart Type")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(VisualizationType.allCases, id: \.self) { type in
                            VisualizationTypeCard(
                                type: type,
                                isSelected: viewModel.reportBuilderVisualizationType == type
                            ) {
                                viewModel.reportBuilderVisualizationType = type
                            }
                        }
                    }
                }
                
                // Chart Configuration
                if viewModel.reportBuilderVisualizationType != .table {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Chart Configuration")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 12) {
                            // X-Axis
                            HStack {
                                Text("X-Axis:")
                                    .frame(width: 60, alignment: .leading)
                                
                                Picker("X-Axis", selection: $viewModel.reportBuilderXAxis) {
                                    ForEach(viewModel.reportBuilderSelectedFields, id: \.self) { field in
                                        Text(field).tag(field)
                                    }
                                }
                                .pickerStyle(.menu)
                                .frame(maxWidth: .infinity)
                            }
                            
                            // Y-Axis
                            HStack {
                                Text("Y-Axis:")
                                    .frame(width: 60, alignment: .leading)
                                
                                Picker("Y-Axis", selection: $viewModel.reportBuilderYAxis) {
                                    ForEach(viewModel.reportBuilderSelectedFields, id: \.self) { field in
                                        Text(field).tag(field)
                                    }
                                }
                                .pickerStyle(.menu)
                                .frame(maxWidth: .infinity)
                            }
                            
                            // Group By (if applicable)
                            if supportsGrouping(viewModel.reportBuilderVisualizationType) {
                                HStack {
                                    Text("Group By:")
                                        .frame(width: 60, alignment: .leading)
                                    
                                    Picker("Group By", selection: $viewModel.reportBuilderGroupBy) {
                                        Text("None").tag("")
                                        ForEach(viewModel.reportBuilderSelectedFields, id: \.self) { field in
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
                
                // Additional Visualizations
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Additional Charts")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Button("Add Chart") {
                            viewModel.addBuilderVisualization()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    
                    if viewModel.reportBuilderAdditionalVisualizations.isEmpty {
                        Text("No additional charts added")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.secondary.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        VStack(spacing: 8) {
                            ForEach(viewModel.reportBuilderAdditionalVisualizations.indices, id: \.self) { index in
                                AdditionalVisualizationRow(
                                    visualization: $viewModel.reportBuilderAdditionalVisualizations[index],
                                    availableFields: viewModel.reportBuilderSelectedFields,
                                    onDelete: {
                                        viewModel.removeBuilderVisualization(at: index)
                                    }
                                )
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func supportsGrouping(_ type: VisualizationType) -> Bool {
        switch type {
        case .bar, .line, .area, .stackedBar:
            return true
        case .pie, .donut, .scatter, .table:
            return false
        }
    }
}

// MARK: - Formatting Step

public struct FormattingStep: View {
    @ObservedObject var viewModel: ReportingViewModel
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            stepHeader(
                title: "Formatting & Style",
                subtitle: "Customize the appearance of your report"
            )
            
            VStack(alignment: .leading, spacing: 16) {
                // Color Theme
                VStack(alignment: .leading, spacing: 8) {
                    Text("Color Theme")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(ColorTheme.allCases, id: \.self) { theme in
                            ColorThemeCard(
                                theme: theme,
                                isSelected: viewModel.reportBuilderColorTheme == theme
                            ) {
                                viewModel.reportBuilderColorTheme = theme
                            }
                        }
                    }
                }
                
                // Layout Options
                VStack(alignment: .leading, spacing: 8) {
                    Text("Layout")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    VStack(spacing: 12) {
                        Toggle("Show Title", isOn: $viewModel.reportBuilderShowTitle)
                        Toggle("Show Legend", isOn: $viewModel.reportBuilderShowLegend)
                        Toggle("Show Grid Lines", isOn: $viewModel.reportBuilderShowGridLines)
                        Toggle("Show Data Labels", isOn: $viewModel.reportBuilderShowDataLabels)
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                // Header Options
                VStack(alignment: .leading, spacing: 8) {
                    Text("Report Header")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    VStack(spacing: 12) {
                        Toggle("Include Logo", isOn: $viewModel.reportBuilderIncludeLogo)
                        Toggle("Include Date Range", isOn: $viewModel.reportBuilderIncludeDateRange)
                        Toggle("Include Generation Time", isOn: $viewModel.reportBuilderIncludeGenerationTime)
                        Toggle("Include Summary Stats", isOn: $viewModel.reportBuilderIncludeSummaryStats)
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                // Export Options
                VStack(alignment: .leading, spacing: 8) {
                    Text("Export Formats")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 8) {
                        ForEach(ExportFormat.allCases, id: \.self) { format in
                            ExportFormatToggle(
                                format: format,
                                isSelected: viewModel.reportBuilderExportFormats.contains(format)
                            ) {
                                viewModel.toggleBuilderExportFormat(format)
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Scheduling Step

public struct SchedulingStep: View {
    @ObservedObject var viewModel: ReportingViewModel
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            stepHeader(
                title: "Scheduling & Automation",
                subtitle: "Set up automated report generation"
            )
            
            VStack(alignment: .leading, spacing: 16) {
                // Auto-generation Toggle
                VStack(alignment: .leading, spacing: 8) {
                    Toggle("Enable Automatic Generation", isOn: $viewModel.reportBuilderEnableScheduling)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    if viewModel.reportBuilderEnableScheduling {
                        Text("This report will be automatically generated based on the schedule below")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if viewModel.reportBuilderEnableScheduling {
                    // Frequency
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Frequency")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Picker("Frequency", selection: $viewModel.reportBuilderScheduleFrequency) {
                            ForEach(ScheduleFrequency.allCases, id: \.self) { frequency in
                                Text(frequency.displayName)
                                    .tag(frequency)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    // Time
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Generation Time")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        DatePicker(
                            "Time",
                            selection: $viewModel.reportBuilderScheduleTime,
                            displayedComponents: .hourAndMinute
                        )
                        .datePickerStyle(.compact)
                    }
                    
                    // Recipients
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email Recipients")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 8) {
                            HStack {
                                TextField("Enter email address", text: $viewModel.reportBuilderNewRecipient)
                                    .textFieldStyle(.roundedBorder)
                                
                                Button("Add") {
                                    viewModel.addBuilderRecipient()
                                }
                                .buttonStyle(.bordered)
                                .disabled(viewModel.reportBuilderNewRecipient.isEmpty)
                            }
                            
                            if !viewModel.reportBuilderRecipients.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    ForEach(viewModel.reportBuilderRecipients, id: \.self) { recipient in
                                        HStack {
                                            Text(recipient)
                                                .font(.subheadline)
                                            
                                            Spacer()
                                            
                                            Button {
                                                viewModel.removeBuilderRecipient(recipient)
                                            } label: {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundColor(.red)
                                            }
                                        }
                                        .padding(.vertical, 4)
                                    }
                                }
                                .padding()
                                .background(Color.secondary.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                    
                    // Advanced Options
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Advanced Options")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 8) {
                            Toggle("Include Raw Data", isOn: $viewModel.reportBuilderIncludeRawData)
                            Toggle("Auto-Archive Old Reports", isOn: $viewModel.reportBuilderAutoArchive)
                            Toggle("Send Summary Email", isOn: $viewModel.reportBuilderSendSummary)
                        }
                        .padding()
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
        }
    }
}

// MARK: - Review Step

public struct ReviewStep: View {
    @ObservedObject var viewModel: ReportingViewModel
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            stepHeader(
                title: "Review & Create",
                subtitle: "Review your report configuration before creating"
            )
            
            VStack(alignment: .leading, spacing: 16) {
                // Basic Info Summary
                ReviewSection(title: "Basic Information") {
                    ReviewItem(label: "Name", value: viewModel.reportBuilderName)
                    ReviewItem(label: "Category", value: viewModel.reportBuilderCategory.displayName)
                    ReviewItem(label: "Type", value: viewModel.reportBuilderType.displayName)
                    ReviewItem(label: "Access", value: viewModel.reportBuilderIsPublic ? "Public" : "Private")
                }
                
                // Data Source Summary
                ReviewSection(title: "Data Source") {
                    ReviewItem(label: "Source", value: viewModel.reportBuilderDataSource.displayName)
                    ReviewItem(label: "Date Range", value: "\(formatDate(viewModel.reportBuilderStartDate)) to \(formatDate(viewModel.reportBuilderEndDate))")
                    ReviewItem(label: "Fields", value: "\(viewModel.reportBuilderSelectedFields.count) selected")
                }
                
                // Filters Summary
                if !viewModel.reportBuilderQuickFilters.isEmpty || !viewModel.reportBuilderFilters.isEmpty {
                    ReviewSection(title: "Filters") {
                        if !viewModel.reportBuilderQuickFilters.isEmpty {
                            ReviewItem(label: "Quick Filters", value: viewModel.reportBuilderQuickFilters.joined(separator: ", "))
                        }
                        if !viewModel.reportBuilderFilters.isEmpty {
                            ReviewItem(label: "Custom Filters", value: "\(viewModel.reportBuilderFilters.count) filters")
                        }
                    }
                }
                
                // Visualization Summary
                ReviewSection(title: "Visualizations") {
                    ReviewItem(label: "Primary Chart", value: viewModel.reportBuilderVisualizationType.displayName)
                    if !viewModel.reportBuilderAdditionalVisualizations.isEmpty {
                        ReviewItem(label: "Additional Charts", value: "\(viewModel.reportBuilderAdditionalVisualizations.count) charts")
                    }
                }
                
                // Scheduling Summary
                if viewModel.reportBuilderEnableScheduling {
                    ReviewSection(title: "Scheduling") {
                        ReviewItem(label: "Frequency", value: viewModel.reportBuilderScheduleFrequency.displayName)
                        ReviewItem(label: "Time", value: formatTime(viewModel.reportBuilderScheduleTime))
                        if !viewModel.reportBuilderRecipients.isEmpty {
                            ReviewItem(label: "Recipients", value: "\(viewModel.reportBuilderRecipients.count) email(s)")
                        }
                    }
                }
                
                // Validation
                if !viewModel.isBuilderValid {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Issues to Address")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                        
                        ForEach(viewModel.builderValidationErrors, id: \.self) { error in
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                
                                Text(error)
                                    .font(.subheadline)
                            }
                        }
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Views

func stepHeader(title: String, subtitle: String) -> some View {
    VStack(alignment: .leading, spacing: 4) {
        Text(title)
            .font(.title2)
            .fontWeight(.bold)
        
        Text(subtitle)
            .font(.subheadline)
            .foregroundColor(.secondary)
    }
}

// MARK: - Report Builder Step Enum

public enum ReportBuilderStep: Int, CaseIterable {
    case basic = 0
    case dataSource = 1
    case filters = 2
    case visualizations = 3
    case formatting = 4
    case scheduling = 5
    case review = 6
    
    public var displayName: String {
        switch self {
        case .basic: return "Basic Info"
        case .dataSource: return "Data Source"
        case .filters: return "Filters"
        case .visualizations: return "Visualizations"
        case .formatting: return "Formatting"
        case .scheduling: return "Scheduling"
        case .review: return "Review"
        }
    }
}
