//
//  NavigationDestination.swift
//  DiamondDeskERP
//
//  Created by J.Michael McDermott on 7/20/25.
//

import Foundation

/// Type-safe navigation destination definitions for the DiamondDeskERP application
/// Provides compile-time safety for navigation paths and consistent routing
enum NavigationDestination: Hashable, Codable {
    
    // MARK: - Dashboard Destinations
    
    case dashboardFilters
    case taskDetail(String)
    case ticketDetail(String)
    case kpiDetail(String)
    case activityHistory
    
    // MARK: - CRM Destinations
    
    case clientList
    case clientDetail(String)
    case crmAnalytics
    case followUpCreation
    case followUpDetail(String)
    
    // MARK: - Tasks Destinations
    
    case tasksList
    case tasksFilters
    case taskCreation
    case taskComments(String)
    
    // MARK: - Tickets Destinations
    
    case ticketsList
    case ticketsFilters
    case ticketCreation
    case ticketComments(String)
    case ticketAssignment(String)
    
    // MARK: - Documents Destinations (Enterprise)
    
    case documentsList
    case documentsFilters
    case documentCreation
    case documentDetail(String)
    case documentVersionHistory(String)
    
    // MARK: - Admin Destinations
    
    case eventQAConsole
    case conflictViewer
    case localizationDashboard
    case analyticsConsentDashboard
    case accessibilityValidation
    case performanceBaseline
    case adminSettings
    
    // MARK: - Settings Destinations
    
    case userProfile
    case appSettings
    case notificationSettings
    case privacySettings
    
    // MARK: - Search Destinations
    
    case searchResults(String)
    case globalSearch
}

// MARK: - Navigation Destination View Mapping

extension NavigationDestination {
    
    /// Human-readable title for the destination
    var title: String {
        switch self {
        // Dashboard
        case .dashboardFilters:
            return "Dashboard Filters"
        case .taskDetail:
            return "Task Details"
        case .ticketDetail:
            return "Ticket Details"
        case .kpiDetail:
            return "KPI Details"
        case .activityHistory:
            return "Activity History"
            
        // CRM
        case .clientList:
            return "Clients"
        case .clientDetail:
            return "Client Details"
        case .crmAnalytics:
            return "CRM Analytics"
        case .followUpCreation:
            return "Create Follow-up"
        case .followUpDetail:
            return "Follow-up Details"
            
        // Tasks
        case .tasksList:
            return "Tasks"
        case .tasksFilters:
            return "Task Filters"
        case .taskCreation:
            return "Create Task"
        case .taskComments:
            return "Task Comments"
            
        // Tickets
        case .ticketsList:
            return "Tickets"
        case .ticketsFilters:
            return "Ticket Filters"
        case .ticketCreation:
            return "Create Ticket"
        case .ticketComments:
            return "Ticket Comments"
        case .ticketAssignment:
            return "Assign Ticket"
            
        // Documents (Enterprise)
        case .documentsList:
            return "Documents"
        case .documentsFilters:
            return "Document Filters"
        case .documentCreation:
            return "Upload Document"
        case .documentDetail:
            return "Document Details"
        case .documentVersionHistory:
            return "Version History"
            
        // Admin
        case .eventQAConsole:
            return "Event QA Console"
        case .conflictViewer:
            return "Conflict Viewer"
        case .localizationDashboard:
            return "Localization Dashboard"
        case .analyticsConsentDashboard:
            return "Analytics Consent"
        case .accessibilityValidation:
            return "Accessibility Validation"
        case .performanceBaseline:
            return "Performance Baseline"
        case .adminSettings:
            return "Admin Settings"
            
        // Settings
        case .userProfile:
            return "User Profile"
        case .appSettings:
            return "App Settings"
        case .notificationSettings:
            return "Notifications"
        case .privacySettings:
            return "Privacy"
            
        // Search
        case .searchResults:
            return "Search Results"
        case .globalSearch:
            return "Search"
        }
    }
    
    /// System image name for the destination
    var systemImage: String {
        switch self {
        // Dashboard
        case .dashboardFilters:
            return "line.3.horizontal.decrease.circle"
        case .taskDetail:
            return "checkmark.circle"
        case .ticketDetail:
            return "ticket"
        case .kpiDetail:
            return "chart.bar"
        case .activityHistory:
            return "clock.arrow.circlepath"
            
        // CRM
        case .clientList:
            return "person.2"
        case .clientDetail:
            return "person.circle"
        case .crmAnalytics:
            return "chart.pie"
        case .followUpCreation:
            return "plus.circle"
        case .followUpDetail:
            return "calendar.circle"
            
        // Tasks
        case .tasksList:
            return "list.bullet"
        case .tasksFilters:
            return "line.3.horizontal.decrease"
        case .taskCreation:
            return "plus.square"
        case .taskComments:
            return "bubble.left.and.bubble.right"
            
        // Tickets
        case .ticketsList:
            return "ticket"
        case .ticketsFilters:
            return "line.3.horizontal.decrease"
        case .ticketCreation:
            return "plus.app"
        case .ticketComments:
            return "message"
        case .ticketAssignment:
            return "person.badge.plus"
            
        // Documents (Enterprise)
        case .documentsList:
            return "folder"
        case .documentsFilters:
            return "line.3.horizontal.decrease"
        case .documentCreation:
            return "doc.badge.plus"
        case .documentDetail:
            return "doc.text"
        case .documentVersionHistory:
            return "clock.arrow.circlepath"
            
        // Admin
        case .eventQAConsole:
            return "monitor"
        case .conflictViewer:
            return "exclamationmark.triangle"
        case .localizationDashboard:
            return "globe"
        case .analyticsConsentDashboard:
            return "chart.bar.doc.horizontal"
        case .accessibilityValidation:
            return "accessibility"
        case .performanceBaseline:
            return "speedometer"
        case .adminSettings:
            return "gear"
            
        // Settings
        case .userProfile:
            return "person.crop.circle"
        case .appSettings:
            return "gearshape"
        case .notificationSettings:
            return "bell"
        case .privacySettings:
            return "hand.raised"
            
        // Search
        case .searchResults:
            return "magnifyingglass.circle"
        case .globalSearch:
            return "magnifyingglass"
        }
    }
    
    /// Associated identifier for the destination (if applicable)
    var identifier: String? {
        switch self {
        case .taskDetail(let id),
             .ticketDetail(let id),
             .kpiDetail(let id),
             .clientDetail(let id),
             .followUpDetail(let id),
             .taskComments(let id),
             .ticketComments(let id),
             .ticketAssignment(let id):
            return id
        case .searchResults(let query):
            return query
        default:
            return nil
        }
    }
}

// MARK: - Deep Link URL Generation

extension NavigationDestination {
    
    /// Generates a deep link URL for the destination
    var deepLinkURL: URL? {
        var components = URLComponents()
        components.scheme = "diamonddesk"
        
        switch self {
        case .taskDetail(let id):
            components.host = "task"
            components.queryItems = [URLQueryItem(name: "id", value: id)]
            
        case .ticketDetail(let id):
            components.host = "ticket"
            components.queryItems = [URLQueryItem(name: "id", value: id)]
            
        case .clientDetail(let id):
            components.host = "client"
            components.queryItems = [URLQueryItem(name: "id", value: id)]
            
        case .eventQAConsole:
            components.host = "admin"
            components.path = "/events"
            
        case .conflictViewer:
            components.host = "admin"
            components.path = "/conflicts"
            
        case .localizationDashboard:
            components.host = "admin"
            components.path = "/localization"
            
        case .analyticsConsentDashboard:
            components.host = "admin"
            components.path = "/analytics"
            
        case .searchResults(let query):
            components.host = "search"
            components.queryItems = [URLQueryItem(name: "q", value: query)]
            
        default:
            return nil
        }
        
        return components.url
    }
}

// MARK: - Navigation Destination Categories

extension NavigationDestination {
    
    /// Category grouping for navigation destinations
    enum Category: String, CaseIterable {
        case dashboard
        case crm
        case tasks
        case tickets
        case admin
        case settings
        case search
    }
    
    /// Returns the category for this destination
    var category: Category {
        switch self {
        case .dashboardFilters, .taskDetail, .ticketDetail, .kpiDetail, .activityHistory:
            return .dashboard
            
        case .clientList, .clientDetail, .crmAnalytics, .followUpCreation, .followUpDetail:
            return .crm
            
        case .tasksList, .tasksFilters, .taskCreation, .taskComments:
            return .tasks
            
        case .ticketsList, .ticketsFilters, .ticketCreation, .ticketComments, .ticketAssignment:
            return .tickets
            
        case .eventQAConsole, .conflictViewer, .localizationDashboard, .analyticsConsentDashboard,
             .accessibilityValidation, .performanceBaseline, .adminSettings:
            return .admin
            
        case .userProfile, .appSettings, .notificationSettings, .privacySettings:
            return .settings
            
        case .searchResults, .globalSearch:
            return .search
        }
    }
}
