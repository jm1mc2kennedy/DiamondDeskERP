//
//  NavigationDestinationHandler.swift
//  DiamondDeskERP
//
//  Created by J.Michael McDermott on 7/20/25.
//

import SwiftUI

/// Handles navigation destination routing for type-safe navigation
/// Provides centralized view mapping for navigation destinations
struct NavigationDestinationHandler: ViewModifier {
    
    @StateObject private var router = NavigationRouter.shared
    
    func body(content: Content) -> some View {
        content
            .navigationDestination(for: NavigationDestination.self) { destination in
                destinationView(for: destination)
            }
            .sheet(isPresented: $router.isCreateTaskPresented) {
                CreateTaskSheet()
            }
            .sheet(isPresented: $router.isCreateTicketPresented) {
                CreateTicketSheet()
            }
            .sheet(isPresented: $router.isCreateFollowUpPresented) {
                CreateFollowUpSheet()
            }
            .sheet(isPresented: $router.isAnalyticsConsentPresented) {
                AnalyticsConsentSheet()
            }
    }
    
    @ViewBuilder
    private func destinationView(for destination: NavigationDestination) -> some View {
        switch destination {
        
        // MARK: - Dashboard Destinations
        
        case .dashboardFilters:
            DashboardFiltersView()
            
        case .taskDetail(let taskId):
            if let task = router.selectedTask {
                TaskDetailView(task: task)
            } else {
                TaskDetailView(taskId: taskId)
            }
            
        case .ticketDetail(let ticketId):
            if let ticket = router.selectedTicket {
                TicketDetailView(ticket: ticket)
            } else {
                TicketDetailView(ticketId: ticketId)
            }
            
        case .kpiDetail(let kpiId):
            if let kpi = router.selectedKPI {
                KPIDetailView(kpi: kpi)
            } else {
                KPIDetailView(kpiId: kpiId)
            }
            
        case .activityHistory:
            ActivityHistoryView()
            
        // MARK: - CRM Destinations
        
        case .clientList:
            ClientListView()
            
        case .clientDetail(let clientId):
            if let client = router.selectedClient {
                ClientDetailView(client: client)
            } else {
                ClientDetailView(clientId: clientId)
            }
            
        case .crmAnalytics:
            CRMAnalyticsView()
            
        case .followUpCreation:
            CreateFollowUpView()
            
        case .followUpDetail(let followUpId):
            FollowUpDetailView(followUpId: followUpId)
            
        // MARK: - Tasks Destinations
        
        case .tasksList:
            TaskListView()
            
        case .tasksFilters:
            TaskFiltersView()
            
        case .taskCreation:
            CreateTaskView()
            
        case .taskComments(let taskId):
            TaskCommentsView(taskId: taskId)
            
        // MARK: - Tickets Destinations
        
        case .ticketsList:
            TicketListView()
            
        case .ticketsFilters:
            TicketFiltersView()
            
        case .ticketCreation:
            CreateTicketView()
            
        case .ticketComments(let ticketId):
            TicketCommentsView(ticketId: ticketId)
            
        case .ticketAssignment(let ticketId):
            TicketAssignmentView(ticketId: ticketId)
            
        // MARK: - Documents Destinations (Enterprise)
        
        case .documentsList:
            DocumentListView()
            
        case .documentsFilters:
            DocumentFilterView(viewModel: DocumentViewModel())
            
        case .documentCreation:
            CreateDocumentView(viewModel: DocumentViewModel())
            
        case .documentDetail(let documentId):
            if let document = router.selectedDocument {
                DocumentDetailView(document: document, viewModel: DocumentViewModel())
            } else {
                DocumentDetailByIdView(documentId: documentId)
            }
            
        case .documentVersionHistory(let documentId):
            if let document = router.selectedDocument {
                DocumentVersionHistoryView(document: document)
            } else {
                DocumentVersionHistoryByIdView(documentId: documentId)
            }
            
        // MARK: - Admin Destinations
        
        case .eventQAConsole:
            EventQAConsoleView()
            
        case .conflictViewer:
            ConflictViewer()
            
        case .localizationDashboard:
            LocalizationValidationDashboard()
            
        case .analyticsConsentDashboard:
            AnalyticsConsentDashboard()
            
        case .accessibilityValidation:
            AccessibilityValidationDashboard()
            
        case .performanceBaseline:
            PerformanceBaselineDashboard()
            
        case .adminSettings:
            AdminSettingsView()
            
        // MARK: - Settings Destinations
        
        case .userProfile:
            UserProfileView()
            
        case .appSettings:
            AppSettingsView()
            
        case .notificationSettings:
            NotificationSettingsView()
            
        case .privacySettings:
            PrivacySettingsView()
            
        // MARK: - Search Destinations
        
        case .searchResults(let query):
            SearchResultsView(query: query)
            
        case .globalSearch:
            GlobalSearchView()
        }
    }
}

// MARK: - Sheet Content Views

private struct CreateTaskSheet: View {
    @StateObject private var router = NavigationRouter.shared
    
    var body: some View {
        NavigationStack {
            CreateTaskView()
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            router.dismissCreateTask()
                        }
                    }
                }
        }
    }
}

private struct CreateTicketSheet: View {
    @StateObject private var router = NavigationRouter.shared
    
    var body: some View {
        NavigationStack {
            CreateTicketView()
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            router.dismissCreateTicket()
                        }
                    }
                }
        }
    }
}

private struct CreateFollowUpSheet: View {
    @StateObject private var router = NavigationRouter.shared
    
    var body: some View {
        NavigationStack {
            CreateFollowUpView()
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            router.dismissCreateFollowUp()
                        }
                    }
                }
        }
    }
}

private struct AnalyticsConsentSheet: View {
    @StateObject private var router = NavigationRouter.shared
    
    var body: some View {
        NavigationStack {
            AnalyticsConsentView()
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            router.dismissAnalyticsConsent()
                        }
                    }
                }
        }
    }
}

// MARK: - Detail View Variants

// These provide fallback implementations when models aren't available in router
private struct TaskDetailView: View {
    let task: TaskModel?
    let taskId: String?
    
    init(task: TaskModel) {
        self.task = task
        self.taskId = nil
    }
    
    init(taskId: String) {
        self.task = nil
        self.taskId = taskId
    }
    
    var body: some View {
        Group {
            if let task = task {
                // Use existing TaskDetailView with task model
                Text("Task Detail: \(task.title)")
            } else if let taskId = taskId {
                // Load task by ID and display
                TaskDetailByIdView(taskId: taskId)
            } else {
                ContentUnavailableView("Task Not Found", systemImage: "exclamationmark.triangle")
            }
        }
        .navigationTitle("Task Details")
        .navigationBarTitleDisplayMode(.large)
    }
}

private struct TicketDetailView: View {
    let ticket: TicketModel?
    let ticketId: String?
    
    init(ticket: TicketModel) {
        self.ticket = ticket
        self.ticketId = nil
    }
    
    init(ticketId: String) {
        self.ticket = nil
        self.ticketId = ticketId
    }
    
    var body: some View {
        Group {
            if let ticket = ticket {
                Text("Ticket Detail: \(ticket.title)")
            } else if let ticketId = ticketId {
                TicketDetailByIdView(ticketId: ticketId)
            } else {
                ContentUnavailableView("Ticket Not Found", systemImage: "exclamationmark.triangle")
            }
        }
        .navigationTitle("Ticket Details")
        .navigationBarTitleDisplayMode(.large)
    }
}

private struct ClientDetailView: View {
    let client: ClientModel?
    let clientId: String?
    
    init(client: ClientModel) {
        self.client = client
        self.clientId = nil
    }
    
    init(clientId: String) {
        self.client = nil
        self.clientId = clientId
    }
    
    var body: some View {
        Group {
            if let client = client {
                Text("Client Detail: \(client.name)")
            } else if let clientId = clientId {
                ClientDetailByIdView(clientId: clientId)
            } else {
                ContentUnavailableView("Client Not Found", systemImage: "exclamationmark.triangle")
            }
        }
        .navigationTitle("Client Details")
        .navigationBarTitleDisplayMode(.large)
    }
}

private struct KPIDetailView: View {
    let kpi: KPIModel?
    let kpiId: String?
    
    init(kpi: KPIModel) {
        self.kpi = kpi
        self.kpiId = nil
    }
    
    init(kpiId: String) {
        self.kpi = nil
        self.kpiId = kpiId
    }
    
    var body: some View {
        Group {
            if let kpi = kpi {
                Text("KPI Detail: \(kpi.title)")
            } else if let kpiId = kpiId {
                KPIDetailByIdView(kpiId: kpiId)
            } else {
                ContentUnavailableView("KPI Not Found", systemImage: "exclamationmark.triangle")
            }
        }
        .navigationTitle("KPI Details")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Placeholder Detail Views by ID

private struct TaskDetailByIdView: View {
    let taskId: String
    
    var body: some View {
        VStack {
            ProgressView("Loading task...")
            Text("Task ID: \(taskId)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .task {
            // TODO: Load task by ID from repository
        }
    }
}

private struct TicketDetailByIdView: View {
    let ticketId: String
    
    var body: some View {
        VStack {
            ProgressView("Loading ticket...")
            Text("Ticket ID: \(ticketId)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .task {
            // TODO: Load ticket by ID from repository
        }
    }
}

private struct ClientDetailByIdView: View {
    let clientId: String
    
    var body: some View {
        VStack {
            ProgressView("Loading client...")
            Text("Client ID: \(clientId)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .task {
            // TODO: Load client by ID from repository
        }
    }
}

private struct KPIDetailByIdView: View {
    let kpiId: String
    
    var body: some View {
        VStack {
            ProgressView("Loading KPI...")
            Text("KPI ID: \(kpiId)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .task {
            // TODO: Load KPI by ID from repository
        }
    }
}

// MARK: - ViewModifier Extension

extension View {
    func navigationDestinationHandler() -> some View {
        modifier(NavigationDestinationHandler())
    }
}
