//
//  NavigationRouter.swift
//  DiamondDeskERP
//
//  Created by J.Michael McDermott on 7/20/25.
//

import SwiftUI
import CloudKit

/// Central navigation coordinator for the DiamondDeskERP application
/// Provides type-safe navigation paths and centralized navigation state management
@MainActor
final class NavigationRouter: ObservableObject {
    
    // MARK: - Navigation Paths
    
    @Published var dashboardPath = NavigationPath()
    @Published var crmPath = NavigationPath()
    @Published var tasksPath = NavigationPath()
    @Published var ticketsPath = NavigationPath()
    @Published var documentsPath = NavigationPath()
    @Published var adminPath = NavigationPath()
    
    // MARK: - Sheet Presentation State
    
    @Published var isCreateTaskPresented = false
    @Published var isCreateTicketPresented = false
    @Published var isCreateFollowUpPresented = false
    @Published var isAnalyticsConsentPresented = false
    
    // MARK: - Selected Items for Detail Views
    
    @Published var selectedTask: TaskModel?
    @Published var selectedTicket: TicketModel?
    @Published var selectedClient: ClientModel?
    @Published var selectedKPI: KPIModel?
    @Published var selectedDocument: DocumentModel?
    
    // MARK: - Singleton
    
    static let shared = NavigationRouter()
    
    private init() {}
    
    // MARK: - Dashboard Navigation
    
    func navigateToTaskDetail(_ task: TaskModel) {
        selectedTask = task
        dashboardPath.append(NavigationDestination.taskDetail(task.id.recordName))
    }
    
    func navigateToTicketDetail(_ ticket: TicketModel) {
        selectedTicket = ticket
        dashboardPath.append(NavigationDestination.ticketDetail(ticket.id.recordName))
    }
    
    func navigateToKPIDetail(_ kpi: KPIModel) {
        selectedKPI = kpi
        dashboardPath.append(NavigationDestination.kpiDetail(kpi.id.recordName))
    }
    
    func navigateToDashboardFilters() {
        dashboardPath.append(NavigationDestination.dashboardFilters)
    }
    
    // MARK: - CRM Navigation
    
    func navigateToClientDetail(_ client: ClientModel) {
        selectedClient = client
        crmPath.append(NavigationDestination.clientDetail(client.id.recordName))
    }
    
    func navigateToClientList() {
        crmPath.append(NavigationDestination.clientList)
    }
    
    func navigateToCRMAnalytics() {
        crmPath.append(NavigationDestination.crmAnalytics)
    }
    
    // MARK: - Tasks Navigation
    
    func navigateToTasksList() {
        tasksPath.append(NavigationDestination.tasksList)
    }
    
    func navigateToTaskDetailFromTasks(_ task: TaskModel) {
        selectedTask = task
        tasksPath.append(NavigationDestination.taskDetail(task.id.recordName))
    }
    
    // MARK: - Tickets Navigation
    
    func navigateToTicketsList() {
        ticketsPath.append(NavigationDestination.ticketsList)
    }
    
    func navigateToTicketDetailFromTickets(_ ticket: TicketModel) {
        selectedTicket = ticket
        ticketsPath.append(NavigationDestination.ticketDetail(ticket.id.recordName))
    }
    
    // MARK: - Documents Navigation (Enterprise)
    
    func navigateToDocuments() {
        documentsPath.append(NavigationDestination.documentsList)
    }
    
    func navigateToDocumentDetail(_ document: DocumentModel) {
        selectedDocument = document
        documentsPath.append(NavigationDestination.documentDetail(document.id.uuidString))
    }
    
    func navigateToDocumentDetailFromDashboard(_ document: DocumentModel) {
        selectedDocument = document
        dashboardPath.append(NavigationDestination.documentDetail(document.id.uuidString))
    }
    
    func navigateToDocumentFilters() {
        documentsPath.append(NavigationDestination.documentsFilters)
    }
    
    func navigateToDocumentVersionHistory(_ document: DocumentModel) {
        selectedDocument = document
        documentsPath.append(NavigationDestination.documentVersionHistory(document.id.uuidString))
    }
    
    func presentCreateDocument() {
        documentsPath.append(NavigationDestination.documentCreation)
    }
    
    // MARK: - Admin Navigation
    
    func navigateToEventQAConsole() {
        adminPath.append(NavigationDestination.eventQAConsole)
    }
    
    func navigateToConflictViewer() {
        adminPath.append(NavigationDestination.conflictViewer)
    }
    
    func navigateToLocalizationDashboard() {
        adminPath.append(NavigationDestination.localizationDashboard)
    }
    
    func navigateToAnalyticsConsentDashboard() {
        adminPath.append(NavigationDestination.analyticsConsentDashboard)
    }
    
    func navigateToAccessibilityValidation() {
        adminPath.append(NavigationDestination.accessibilityValidation)
    }
    
    // MARK: - Sheet Presentation
    
    func presentCreateTask() {
        isCreateTaskPresented = true
    }
    
    func presentCreateTicket() {
        isCreateTicketPresented = true
    }
    
    func presentCreateFollowUp() {
        isCreateFollowUpPresented = true
    }
    
    func presentAnalyticsConsent() {
        isAnalyticsConsentPresented = true
    }
    
    // MARK: - Path Management
    
    func clearDashboardPath() {
        dashboardPath = NavigationPath()
    }
    
    func clearCRMPath() {
        crmPath = NavigationPath()
    }
    
    func clearTasksPath() {
        tasksPath = NavigationPath()
    }
    
    func clearTicketsPath() {
        ticketsPath = NavigationPath()
    }
    
    func clearDocumentsPath() {
        documentsPath = NavigationPath()
    }
    
    func clearAdminPath() {
        adminPath = NavigationPath()
    }
    
    func clearAllPaths() {
        dashboardPath = NavigationPath()
        crmPath = NavigationPath()
        tasksPath = NavigationPath()
        ticketsPath = NavigationPath()
        documentsPath = NavigationPath()
        adminPath = NavigationPath()
    }
    
    // MARK: - Dismissal
    
    func dismissCreateTask() {
        isCreateTaskPresented = false
    }
    
    func dismissCreateTicket() {
        isCreateTicketPresented = false
    }
    
    func dismissCreateFollowUp() {
        isCreateFollowUpPresented = false
    }
    
    func dismissAnalyticsConsent() {
        isAnalyticsConsentPresented = false
    }
    
    // MARK: - Deep Linking Support
    
    func handleDeepLink(_ url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let host = components.host else { return }
        
        switch host {
        case "task":
            if let taskId = components.queryItems?.first(where: { $0.name == "id" })?.value {
                dashboardPath.append(NavigationDestination.taskDetail(taskId))
            }
        case "ticket":
            if let ticketId = components.queryItems?.first(where: { $0.name == "id" })?.value {
                ticketsPath.append(NavigationDestination.ticketDetail(ticketId))
            }
        case "client":
            if let clientId = components.queryItems?.first(where: { $0.name == "id" })?.value {
                crmPath.append(NavigationDestination.clientDetail(clientId))
            }
        case "document":
            if let documentId = components.queryItems?.first(where: { $0.name == "id" })?.value {
                documentsPath.append(NavigationDestination.documentDetail(documentId))
            }
        case "admin":
            guard let path = components.path.split(separator: "/").first else { return }
            switch path {
            case "events":
                navigateToEventQAConsole()
            case "conflicts":
                navigateToConflictViewer()
            case "localization":
                navigateToLocalizationDashboard()
            case "analytics":
                navigateToAnalyticsConsentDashboard()
            default:
                break
            }
        default:
            break
        }
    }
}

// MARK: - Navigation Tab Management

extension NavigationRouter {
    
    enum NavigationTab: String, CaseIterable {
        case dashboard = "dashboard"
        case tasks = "tasks"
        case tickets = "tickets"
        case documents = "documents"
        case crm = "crm"
        case admin = "admin"
        
        var title: String {
            switch self {
            case .dashboard: return "Dashboard"
            case .tasks: return "Tasks"
            case .tickets: return "Tickets"
            case .documents: return "Documents"
            case .crm: return "CRM"
            case .admin: return "Admin"
            }
        }
        
        var systemImage: String {
            switch self {
            case .dashboard: return "chart.bar.fill"
            case .tasks: return "checkmark.circle.fill"
            case .tickets: return "ticket.fill"
            case .documents: return "folder.fill"
            case .crm: return "person.2.fill"
            case .admin: return "gear.circle.fill"
            }
        }
    }
    
    @Published var selectedTab: NavigationTab = .dashboard
    
    func selectTab(_ tab: NavigationTab) {
        selectedTab = tab
    }
}
