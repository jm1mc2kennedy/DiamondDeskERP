import SwiftUI

struct CRMDashboardView: View {
    @StateObject private var followUpService = CRMFollowUpService()
    @State private var selectedTab: CRMTab = .overview
    @State private var showingFollowUpForm = false
    @State private var selectedClient: ClientModel?
    @State private var suggestions: [FollowUpSuggestion] = []
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab Bar
                CRMTabBar(selectedTab: $selectedTab)
                
                // Content
                TabView(selection: $selectedTab) {
                    // Overview Tab
                    OverviewTabView()
                        .tag(CRMTab.overview)
                    
                    // Follow-ups Tab
                    FollowUpsTabView()
                        .tag(CRMTab.followUps)
                    
                    // Reminders Tab
                    RemindersTabView()
                        .tag(CRMTab.reminders)
                    
                    // Suggestions Tab
                    SuggestionsTabView()
                        .tag(CRMTab.suggestions)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("CRM Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("New Follow-up") {
                        showingFollowUpForm = true
                    }
                }
            }
            .sheet(isPresented: $showingFollowUpForm) {
                CreateFollowUpView(followUpService: followUpService)
            }
        }
        .environmentObject(followUpService)
        .task {
            await loadSuggestions()
        }
    }
    
    // MARK: - Overview Tab
    
    @ViewBuilder
    private func OverviewTabView() -> some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Quick Stats
                QuickStatsView()
                
                // Urgent Items
                UrgentItemsView()
                
                // Recent Activity
                RecentActivityView()
            }
            .padding()
        }
        .refreshable {
            await followUpService.loadFollowUps()
            await followUpService.loadReminders()
            await loadSuggestions()
        }
    }
    
    // MARK: - Follow-ups Tab
    
    @ViewBuilder
    private func FollowUpsTabView() -> some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if !followUpService.overdueFollowUps.isEmpty {
                    FollowUpSectionView(
                        title: "Overdue",
                        followUps: followUpService.overdueFollowUps,
                        color: .red
                    )
                }
                
                if !followUpService.upcomingFollowUps.isEmpty {
                    FollowUpSectionView(
                        title: "Upcoming",
                        followUps: followUpService.upcomingFollowUps,
                        color: .blue
                    )
                }
                
                if followUpService.overdueFollowUps.isEmpty && followUpService.upcomingFollowUps.isEmpty {
                    EmptyStateView(
                        icon: "checkmark.circle.fill",
                        title: "All Caught Up!",
                        message: "No pending follow-ups at the moment."
                    )
                }
            }
            .padding()
        }
        .refreshable {
            await followUpService.loadFollowUps()
        }
    }
    
    // MARK: - Reminders Tab
    
    @ViewBuilder
    private func RemindersTabView() -> some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if !followUpService.birthdayReminders.isEmpty {
                    ReminderSectionView(
                        title: "Upcoming Birthdays",
                        reminders: followUpService.birthdayReminders,
                        color: .pink,
                        icon: "gift.fill"
                    )
                }
                
                if !followUpService.anniversaryReminders.isEmpty {
                    ReminderSectionView(
                        title: "Upcoming Anniversaries",
                        reminders: followUpService.anniversaryReminders,
                        color: .purple,
                        icon: "heart.fill"
                    )
                }
                
                if followUpService.birthdayReminders.isEmpty && followUpService.anniversaryReminders.isEmpty {
                    EmptyStateView(
                        icon: "calendar",
                        title: "No Upcoming Events",
                        message: "No birthdays or anniversaries in the next month."
                    )
                }
            }
            .padding()
        }
        .refreshable {
            await followUpService.loadReminders()
        }
    }
    
    // MARK: - Suggestions Tab
    
    @ViewBuilder
    private func SuggestionsTabView() -> some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if !suggestions.isEmpty {
                    ForEach(suggestions) { suggestion in
                        SuggestionCardView(suggestion: suggestion) {
                            await createFollowUpFromSuggestion(suggestion)
                        }
                    }
                } else if followUpService.isLoading {
                    ProgressView("Loading suggestions...")
                        .frame(maxWidth: .infinity, minHeight: 200)
                } else {
                    EmptyStateView(
                        icon: "lightbulb",
                        title: "No Suggestions",
                        message: "All clients are up to date!"
                    )
                }
            }
            .padding()
        }
        .refreshable {
            await loadSuggestions()
        }
    }
    
    private func loadSuggestions() async {
        suggestions = await followUpService.generateSmartFollowUpSuggestions()
    }
    
    private func createFollowUpFromSuggestion(_ suggestion: FollowUpSuggestion) async {
        do {
            try await followUpService.createFollowUp(
                for: suggestion.client,
                date: suggestion.suggestedDate,
                type: .general,
                notes: suggestion.suggestedAction
            )
            
            // Remove from suggestions
            suggestions.removeAll { $0.id == suggestion.id }
            
        } catch {
            print("Failed to create follow-up: \(error)")
        }
    }
}

// MARK: - Supporting Views

struct CRMTabBar: View {
    @Binding var selectedTab: CRMTab
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(CRMTab.allCases, id: \.self) { tab in
                Button(action: {
                    selectedTab = tab
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.title3)
                        Text(tab.title)
                            .font(.caption)
                    }
                    .foregroundColor(selectedTab == tab ? .blue : .gray)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
            }
        }
        .background(Color(.systemGray6))
    }
}

struct QuickStatsView: View {
    @EnvironmentObject var followUpService: CRMFollowUpService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Stats")
                .font(.headline)
            
            HStack(spacing: 16) {
                StatCardView(
                    title: "Overdue",
                    value: "\(followUpService.overdueFollowUps.count)",
                    color: .red,
                    icon: "exclamationmark.triangle.fill"
                )
                
                StatCardView(
                    title: "This Week",
                    value: "\(followUpService.upcomingFollowUps.count)",
                    color: .blue,
                    icon: "calendar"
                )
                
                StatCardView(
                    title: "Birthdays",
                    value: "\(followUpService.birthdayReminders.count)",
                    color: .pink,
                    icon: "gift.fill"
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct StatCardView: View {
    let title: String
    let value: String
    let color: Color
    let icon: String
    
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
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct UrgentItemsView: View {
    @EnvironmentObject var followUpService: CRMFollowUpService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Urgent Items")
                .font(.headline)
            
            if followUpService.overdueFollowUps.isEmpty {
                Text("No urgent items")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(followUpService.overdueFollowUps.prefix(3)) { followUp in
                    UrgentItemRow(followUp: followUp)
                }
                
                if followUpService.overdueFollowUps.count > 3 {
                    Text("And \(followUpService.overdueFollowUps.count - 3) more...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct UrgentItemRow: View {
    let followUp: ClientFollowUp
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(followUp.client.fullName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("\(followUp.daysSinceDate) days overdue")
                    .font(.caption)
                    .foregroundColor(.red)
            }
            
            Spacer()
            
            Image(systemName: "phone.fill")
                .foregroundColor(.blue)
        }
        .padding(.vertical, 4)
    }
}

struct RecentActivityView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activity")
                .font(.headline)
            
            Text("Activity tracking coming soon...")
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct FollowUpSectionView: View {
    let title: String
    let followUps: [ClientFollowUp]
    let color: Color
    @EnvironmentObject var followUpService: CRMFollowUpService
    @State private var showingCompletionSheet = false
    @State private var selectedFollowUp: ClientFollowUp?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(color)
                
                Spacer()
                
                Text("\(followUps.count)")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(color.opacity(0.2))
                    .cornerRadius(8)
            }
            
            ForEach(followUps) { followUp in
                FollowUpCardView(followUp: followUp) {
                    selectedFollowUp = followUp
                    showingCompletionSheet = true
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.1), radius: 4, x: 0, y: 2)
        .sheet(isPresented: $showingCompletionSheet) {
            if let followUp = selectedFollowUp {
                CompleteFollowUpView(followUp: followUp, followUpService: followUpService)
            }
        }
    }
}

struct FollowUpCardView: View {
    let followUp: ClientFollowUp
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(followUp.client.fullName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(followUp.followUpDate, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if !followUp.notes.isEmpty {
                        Text(followUp.notes)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                VStack(spacing: 4) {
                    Circle()
                        .fill(followUp.priority.color)
                        .frame(width: 8, height: 8)
                    
                    if followUp.isOverdue {
                        Text("\(followUp.daysSinceDate)d")
                            .font(.caption2)
                            .foregroundColor(.red)
                    }
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ReminderSectionView: View {
    let title: String
    let reminders: [ClientReminder]
    let color: Color
    let icon: String
    @EnvironmentObject var followUpService: CRMFollowUpService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.headline)
                    .foregroundColor(color)
                
                Spacer()
                
                Text("\(reminders.count)")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(color.opacity(0.2))
                    .cornerRadius(8)
            }
            
            ForEach(reminders) { reminder in
                ReminderCardView(reminder: reminder) {
                    Task {
                        await followUpService.markReminderAsHandled(reminder)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct ReminderCardView: View {
    let reminder: ClientReminder
    let onMarkHandled: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(reminder.client.fullName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(reminder.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if reminder.daysUntil == 0 {
                    Text("Today!")
                        .font(.caption)
                        .foregroundColor(.red)
                        .fontWeight(.medium)
                } else {
                    Text("In \(reminder.daysUntil) days")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Button("Mark Handled", action: onMarkHandled)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .cornerRadius(8)
        }
        .padding(.vertical, 8)
    }
}

struct SuggestionCardView: View {
    let suggestion: FollowUpSuggestion
    let onAccept: () async -> Void
    @State private var isLoading = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(suggestion.client.fullName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(suggestion.reason)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Circle()
                    .fill(suggestion.priority.color)
                    .frame(width: 8, height: 8)
            }
            
            Text(suggestion.suggestedAction)
                .font(.caption)
                .foregroundColor(.primary)
                .padding(.vertical, 4)
            
            HStack {
                Text(suggestion.suggestedDate, style: .date)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button("Accept") {
                    isLoading = true
                    Task {
                        await onAccept()
                        isLoading = false
                    }
                }
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Color.green.opacity(0.1))
                .foregroundColor(.green)
                .cornerRadius(8)
                .disabled(isLoading)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.gray)
            
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .padding()
    }
}

// MARK: - Supporting Types

enum CRMTab: CaseIterable {
    case overview
    case followUps
    case reminders
    case suggestions
    
    var title: String {
        switch self {
        case .overview: return "Overview"
        case .followUps: return "Follow-ups"
        case .reminders: return "Reminders"
        case .suggestions: return "Suggestions"
        }
    }
    
    var icon: String {
        switch self {
        case .overview: return "chart.bar.fill"
        case .followUps: return "person.2.fill"
        case .reminders: return "bell.fill"
        case .suggestions: return "lightbulb.fill"
        }
    }
}

extension SuggestionPriority {
    var color: Color {
        switch self {
        case .low: return .blue
        case .medium: return .orange
        case .high: return .red
        }
    }
}
