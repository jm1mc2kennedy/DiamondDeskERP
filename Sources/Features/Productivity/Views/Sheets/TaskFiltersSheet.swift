//
//  TaskFiltersSheet.swift
//  DiamondDeskERP
//
//  Created by AI Assistant on 7/20/25.
//

import SwiftUI

struct TaskFiltersSheet: View {
    @Binding var selectedAssignee: String?
    @Binding var selectedPriority: TaskPriority?
    @Binding var selectedStatus: TaskStatus?
    @Binding var selectedTag: String?
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = TaskFiltersViewModel()
    
    @State private var dueDateFilter: DueDateFilter = .any
    @State private var completionFilter: CompletionFilter = .any
    @State private var customDateRange: DateInterval?
    @State private var showingCustomDatePicker = false
    
    var body: some View {
        NavigationStack {
            Form {
                assigneeSection
                statusAndPrioritySection
                dueDateSection
                tagsSection
                completionSection
                
                Section {
                    Button("Clear All Filters") {
                        clearAllFilters()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Filter Tasks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        applyFilters()
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadFilterData()
            }
            .sheet(isPresented: $showingCustomDatePicker) {
                CustomDateRangeSheet(dateRange: $customDateRange)
            }
        }
    }
    
    // MARK: - Form Sections
    
    private var assigneeSection: some View {
        Section {
            Picker("Assignee", selection: $selectedAssignee) {
                Text("Any Assignee").tag(String?.none)
                Text("Unassigned").tag("unassigned")
                
                ForEach(viewModel.availableAssignees, id: \.id) { assignee in
                    HStack {
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 20, height: 20)
                            .overlay {
                                Text(assignee.initials)
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                        
                        Text(assignee.name)
                    }
                    .tag(assignee.id as String?)
                }
            }
            .pickerStyle(.navigationLink)
        } header: {
            Text("Assignee")
        }
    }
    
    private var statusAndPrioritySection: some View {
        Section {
            // Status Filter
            Picker("Status", selection: $selectedStatus) {
                Text("Any Status").tag(TaskStatus?.none)
                
                ForEach(TaskStatus.allCases, id: \.self) { status in
                    HStack {
                        Circle()
                            .fill(status.color)
                            .frame(width: 12, height: 12)
                        
                        Text(status.displayName)
                    }
                    .tag(status as TaskStatus?)
                }
            }
            .pickerStyle(.navigationLink)
            
            // Priority Filter
            Picker("Priority", selection: $selectedPriority) {
                Text("Any Priority").tag(TaskPriority?.none)
                
                ForEach(TaskPriority.allCases, id: \.self) { priority in
                    HStack {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(priority.color)
                            .frame(width: 12, height: 12)
                        
                        Text(priority.displayName)
                    }
                    .tag(priority as TaskPriority?)
                }
            }
            .pickerStyle(.navigationLink)
        } header: {
            Text("Status & Priority")
        }
    }
    
    private var dueDateSection: some View {
        Section {
            Picker("Due Date", selection: $dueDateFilter) {
                ForEach(DueDateFilter.allCases, id: \.self) { filter in
                    Text(filter.displayName).tag(filter)
                }
            }
            .pickerStyle(.navigationLink)
            
            if dueDateFilter == .customRange {
                Button(action: { showingCustomDatePicker = true }) {
                    HStack {
                        Text("Date Range")
                        Spacer()
                        if let range = customDateRange {
                            Text("\(range.start, style: .date) - \(range.end, style: .date)")
                                .foregroundColor(.secondary)
                        } else {
                            Text("Select Range")
                                .foregroundColor(.accentColor)
                        }
                    }
                }
            }
        } header: {
            Text("Due Date")
        }
    }
    
    private var tagsSection: some View {
        Section {
            if viewModel.availableTags.isEmpty {
                Text("No tags available")
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                    ForEach(viewModel.availableTags, id: \.self) { tag in
                        TagFilterChip(
                            tag: tag,
                            isSelected: selectedTag == tag
                        ) {
                            if selectedTag == tag {
                                selectedTag = nil
                            } else {
                                selectedTag = tag
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        } header: {
            Text("Tags")
        }
    }
    
    private var completionSection: some View {
        Section {
            Picker("Completion Status", selection: $completionFilter) {
                ForEach(CompletionFilter.allCases, id: \.self) { filter in
                    Text(filter.displayName).tag(filter)
                }
            }
            .pickerStyle(.segmented)
        } header: {
            Text("Completion")
        }
    }
    
    // MARK: - Actions
    
    private func clearAllFilters() {
        selectedAssignee = nil
        selectedPriority = nil
        selectedStatus = nil
        selectedTag = nil
        dueDateFilter = .any
        completionFilter = .any
        customDateRange = nil
    }
    
    private func applyFilters() {
        // Apply additional filter logic based on dueDateFilter and completionFilter
        // This could be handled in the parent view or viewModel
    }
    
    private func loadFilterData() {
        Task {
            await viewModel.loadAvailableFilters()
        }
    }
}

// MARK: - Tag Filter Chip

struct TagFilterChip: View {
    let tag: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(tag)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.accentColor : Color.gray.opacity(0.2))
                .foregroundColor(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Filter by \(tag)")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

// MARK: - Custom Date Range Sheet

struct CustomDateRangeSheet: View {
    @Binding var dateRange: DateInterval?
    @Environment(\.dismiss) private var dismiss
    
    @State private var startDate = Date()
    @State private var endDate: Date
    
    init(dateRange: Binding<DateInterval?>) {
        self._dateRange = dateRange
        let initialEnd = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
        self._endDate = State(initialValue: initialEnd)
        
        if let range = dateRange.wrappedValue {
            self._startDate = State(initialValue: range.start)
            self._endDate = State(initialValue: range.end)
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                } header: {
                    Text("Date Range")
                } footer: {
                    Text("Select the date range for filtering tasks by due date.")
                }
                
                Section {
                    Button("Clear Date Range") {
                        dateRange = nil
                        dismiss()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Custom Date Range")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        if startDate <= endDate {
                            dateRange = DateInterval(start: startDate, end: endDate)
                        }
                        dismiss()
                    }
                    .disabled(startDate > endDate)
                }
            }
        }
    }
}

// MARK: - Filter Enums

enum DueDateFilter: String, CaseIterable {
    case any = "any"
    case overdue = "overdue"
    case today = "today"
    case thisWeek = "thisWeek"
    case thisMonth = "thisMonth"
    case nextWeek = "nextWeek"
    case nextMonth = "nextMonth"
    case noDueDate = "noDueDate"
    case customRange = "customRange"
    
    var displayName: String {
        switch self {
        case .any: return "Any Date"
        case .overdue: return "Overdue"
        case .today: return "Due Today"
        case .thisWeek: return "Due This Week"
        case .thisMonth: return "Due This Month"
        case .nextWeek: return "Due Next Week"
        case .nextMonth: return "Due Next Month"
        case .noDueDate: return "No Due Date"
        case .customRange: return "Custom Range"
        }
    }
}

enum CompletionFilter: String, CaseIterable {
    case any = "any"
    case incomplete = "incomplete"
    case complete = "complete"
    
    var displayName: String {
        switch self {
        case .any: return "All"
        case .incomplete: return "Incomplete"
        case .complete: return "Complete"
        }
    }
}

// MARK: - Task Filters ViewModel

@MainActor
class TaskFiltersViewModel: ObservableObject {
    @Published var availableAssignees: [TeamMember] = []
    @Published var availableTags: [String] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func loadAvailableFilters() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            async let assignees = fetchAvailableAssignees()
            async let tags = fetchAvailableTags()
            
            let (loadedAssignees, loadedTags) = try await (assignees, tags)
            
            self.availableAssignees = loadedAssignees
            self.availableTags = loadedTags
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Mock Data
    
    private func fetchAvailableAssignees() async throws -> [TeamMember] {
        // Mock implementation - replace with actual API call
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 second delay
        
        return [
            TeamMember(
                id: "user1",
                name: "John Doe",
                email: "john.doe@company.com",
                role: .editor,
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
    
    private func fetchAvailableTags() async throws -> [String] {
        // Mock implementation - replace with actual API call
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 second delay
        
        return [
            "Frontend", "Backend", "Design", "Testing", "Documentation",
            "Bug", "Feature", "Urgent", "Research", "Review",
            "Database", "API", "Mobile", "Security", "Performance"
        ]
    }
}

#Preview {
    TaskFiltersSheet(
        selectedAssignee: .constant(nil),
        selectedPriority: .constant(nil),
        selectedStatus: .constant(nil),
        selectedTag: .constant(nil)
    )
}
