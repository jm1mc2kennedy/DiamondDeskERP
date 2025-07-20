import SwiftUI

struct DashboardFiltersView: View {
    @Environment(\.dismiss) private var dismiss
    let viewModel: DashboardViewModel
    
    @State private var selectedStores: Set<String> = []
    @State private var selectedUsers: Set<String> = []
    @State private var showOnlyMyData = false
    @State private var availableStores: [String] = []
    @State private var availableUsers: [String] = []
    
    var body: some View {
        NavigationView {
            Form {
                Section("Data Scope") {
                    Toggle("Show Only My Data", isOn: $showOnlyMyData)
                        .tint(.blue)
                }
                
                Section("Store Filters") {
                    if availableStores.isEmpty {
                        Text("Loading stores...")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(availableStores, id: \.self) { store in
                            MultiSelectRow(
                                title: store,
                                isSelected: selectedStores.contains(store)
                            ) {
                                if selectedStores.contains(store) {
                                    selectedStores.remove(store)
                                } else {
                                    selectedStores.insert(store)
                                }
                            }
                        }
                    }
                }
                
                Section("User Filters") {
                    if !showOnlyMyData {
                        if availableUsers.isEmpty {
                            Text("Loading users...")
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(availableUsers, id: \.self) { user in
                                MultiSelectRow(
                                    title: user,
                                    isSelected: selectedUsers.contains(user)
                                ) {
                                    if selectedUsers.contains(user) {
                                        selectedUsers.remove(user)
                                    } else {
                                        selectedUsers.insert(user)
                                    }
                                }
                            }
                        }
                    } else {
                        Text("User filters disabled when showing only your data")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
                
                Section("Filter Summary") {
                    VStack(alignment: .leading, spacing: 8) {
                        if showOnlyMyData {
                            HStack {
                                Image(systemName: "person.fill")
                                    .foregroundColor(.blue)
                                Text("Showing only your data")
                                    .font(.subheadline)
                            }
                        }
                        
                        if !selectedStores.isEmpty {
                            HStack {
                                Image(systemName: "building.2.fill")
                                    .foregroundColor(.green)
                                Text("\(selectedStores.count) store(s) selected")
                                    .font(.subheadline)
                            }
                        }
                        
                        if !selectedUsers.isEmpty && !showOnlyMyData {
                            HStack {
                                Image(systemName: "person.2.fill")
                                    .foregroundColor(.orange)
                                Text("\(selectedUsers.count) user(s) selected")
                                    .font(.subheadline)
                            }
                        }
                        
                        if selectedStores.isEmpty && selectedUsers.isEmpty && !showOnlyMyData {
                            HStack {
                                Image(systemName: "globe")
                                    .foregroundColor(.gray)
                                Text("Showing all data")
                                    .font(.subheadline)
                            }
                        }
                    }
                }
                
                Section {
                    Button("Reset All Filters") {
                        resetFilters()
                    }
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .navigationTitle("Dashboard Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        applyFilters()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .task {
            await loadFilterOptions()
            loadCurrentFilters()
        }
    }
    
    private func loadFilterOptions() async {
        // In a real app, these would be fetched from CloudKit or other data sources
        availableStores = [
            "Downtown Flagship",
            "Mall Location",
            "Boutique Store",
            "Airport Location",
            "Online Store"
        ]
        
        availableUsers = [
            "John Smith",
            "Sarah Johnson",
            "Michael Davis",
            "Emily Brown",
            "David Wilson",
            "Lisa Anderson",
            "Robert Taylor",
            "Jennifer Moore"
        ]
    }
    
    private func loadCurrentFilters() {
        selectedStores = viewModel.selectedStores
        selectedUsers = viewModel.selectedUsers
        showOnlyMyData = viewModel.showOnlyMyData
    }
    
    private func applyFilters() {
        viewModel.applyFilters(
            stores: selectedStores,
            users: showOnlyMyData ? [] : selectedUsers,
            showOnlyMyData: showOnlyMyData
        )
        dismiss()
    }
    
    private func resetFilters() {
        selectedStores.removeAll()
        selectedUsers.removeAll()
        showOnlyMyData = false
    }
}

struct MultiSelectRow: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(.gray)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ActivityHistoryView: View {
    @StateObject private var viewModel = ActivityHistoryViewModel()
    @State private var selectedFilter: ActivityFilter = .all
    
    var filteredActivities: [ActivityItem] {
        switch selectedFilter {
        case .all:
            return viewModel.activities
        case .tasks:
            return viewModel.activities.filter { $0.type == .task }
        case .clients:
            return viewModel.activities.filter { $0.type == .client }
        case .sales:
            return viewModel.activities.filter { $0.type == .sale }
        case .tickets:
            return viewModel.activities.filter { $0.type == .ticket }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Filter Picker
            Picker("Filter", selection: $selectedFilter) {
                ForEach(ActivityFilter.allCases, id: \.self) { filter in
                    Text(filter.displayName).tag(filter)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            // Activity List
            List {
                ForEach(groupedActivities.keys.sorted(by: >), id: \.self) { date in
                    Section(header: Text(date, style: .date).font(.subheadline)) {
                        ForEach(groupedActivities[date] ?? []) { activity in
                            ActivityDetailRow(activity: activity)
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
        }
        .navigationTitle("Activity History")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await viewModel.loadActivities()
        }
        .task {
            await viewModel.loadActivities()
        }
    }
    
    private var groupedActivities: [Date: [ActivityItem]] {
        let calendar = Calendar.current
        return Dictionary(grouping: filteredActivities) { activity in
            calendar.startOfDay(for: activity.timestamp)
        }
    }
}

struct ActivityDetailRow: View {
    let activity: ActivityItem
    
    var body: some View {
        HStack(spacing: 12) {
            // Type indicator
            RoundedRectangle(cornerRadius: 4)
                .fill(activity.type.color)
                .frame(width: 4, height: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(activity.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(activity.timestamp, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(activity.type.displayName)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(activity.type.color.opacity(0.1))
                    .foregroundColor(activity.type.color)
                    .cornerRadius(4)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Supporting Types

enum ActivityFilter: CaseIterable {
    case all
    case tasks
    case clients
    case sales
    case tickets
    
    var displayName: String {
        switch self {
        case .all: return "All"
        case .tasks: return "Tasks"
        case .clients: return "Clients"
        case .sales: return "Sales"
        case .tickets: return "Tickets"
        }
    }
}

extension ActivityType {
    var displayName: String {
        switch self {
        case .task: return "Task"
        case .client: return "Client"
        case .sale: return "Sale"
        case .ticket: return "Ticket"
        }
    }
}

@MainActor
class ActivityHistoryViewModel: ObservableObject {
    @Published var activities: [ActivityItem] = []
    @Published var isLoading = false
    
    func loadActivities() async {
        isLoading = true
        
        // In a real app, this would fetch from CloudKit or other data sources
        // For now, we'll generate sample data
        activities = generateSampleActivities()
        
        isLoading = false
    }
    
    private func generateSampleActivities() -> [ActivityItem] {
        let calendar = Calendar.current
        var activities: [ActivityItem] = []
        
        // Generate activities for the past 7 days
        for day in 0...6 {
            guard let date = calendar.date(byAdding: .day, value: -day, to: Date()) else { continue }
            
            let activitiesForDay = Int.random(in: 2...8)
            for i in 0..<activitiesForDay {
                let randomHour = Int.random(in: 9...17)
                let randomMinute = Int.random(in: 0...59)
                
                guard let activityTime = calendar.date(bySettingHour: randomHour, minute: randomMinute, second: 0, of: date) else { continue }
                
                let activityType = ActivityType.allCases.randomElement() ?? .task
                let activity = generateActivityForType(activityType, at: activityTime)
                activities.append(activity)
            }
        }
        
        return activities.sorted { $0.timestamp > $1.timestamp }
    }
    
    private func generateActivityForType(_ type: ActivityType, at timestamp: Date) -> ActivityItem {
        switch type {
        case .task:
            let taskTitles = [
                "Ring sizing completed",
                "Custom design approved",
                "Quality check performed",
                "Inventory updated",
                "Client consultation scheduled",
                "Repair work completed"
            ]
            let title = taskTitles.randomElement() ?? "Task completed"
            return ActivityItem(
                title: title,
                description: "Order #\(Int.random(in: 10000...99999))",
                timestamp: timestamp,
                type: type
            )
            
        case .client:
            let clientTitles = [
                "New client consultation",
                "Follow-up call completed",
                "Client information updated",
                "Appointment scheduled",
                "Client feedback received"
            ]
            let names = ["Sarah Johnson", "Michael Davis", "Emily Brown", "David Wilson", "Lisa Anderson"]
            let title = clientTitles.randomElement() ?? "Client activity"
            let description = names.randomElement() ?? "Client"
            return ActivityItem(
                title: title,
                description: description,
                timestamp: timestamp,
                type: type
            )
            
        case .sale:
            let amounts = ["$1,200", "$3,500", "$850", "$5,200", "$2,100", "$750"]
            let items = ["Engagement ring", "Wedding band set", "Diamond pendant", "Pearl necklace", "Watch", "Earrings"]
            let amount = amounts.randomElement() ?? "$1,000"
            let item = items.randomElement() ?? "Item"
            return ActivityItem(
                title: "Sale processed - \(amount)",
                description: item,
                timestamp: timestamp,
                type: type
            )
            
        case .ticket:
            let ticketTitles = [
                "Support ticket resolved",
                "Warranty claim processed",
                "Return request handled",
                "Repair inquiry answered",
                "Complaint resolved"
            ]
            let title = ticketTitles.randomElement() ?? "Ticket processed"
            return ActivityItem(
                title: title,
                description: "Ticket #\(Int.random(in: 1000...9999))",
                timestamp: timestamp,
                type: type
            )
        }
    }
}

extension ActivityType: CaseIterable {
    public static var allCases: [ActivityType] {
        return [.task, .client, .sale, .ticket]
    }
}
