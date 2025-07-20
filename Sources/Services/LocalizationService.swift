import Foundation

// MARK: - Localization Wrapper Service
/// Production localization wrapper that integrates validation and provides typed string access
final class LocalizationService: ObservableObject {
    
    // MARK: - Shared Instance
    static let shared = LocalizationService()
    
    // MARK: - Properties
    private let validationService = LocalizationValidationService.shared
    
    // MARK: - Initialization
    private init() {}
    
    // MARK: - Core Localization Methods
    
    /// Get localized string with automatic validation tracking
    func string(for key: LocalizationKey, defaultValue: String? = nil) -> String {
        return validationService.localizedString(for: key.rawValue, defaultValue: defaultValue)
    }
    
    /// Get localized string with formatted arguments
    func string(for key: LocalizationKey, arguments: CVarArg...) -> String {
        let format = validationService.localizedString(for: key.rawValue)
        return String(format: format, arguments: arguments)
    }
    
    /// Get localized string with explicit format validation
    func formattedString(for key: LocalizationKey, _ arguments: CVarArg...) -> String {
        let format = validationService.localizedString(for: key.rawValue)
        
        // Validate format string has correct number of placeholders
        let formatSpecifierCount = format.components(separatedBy: "%").count - 1
        
        if formatSpecifierCount != arguments.count {
            print("⚠️ Localization format mismatch for key '\(key.rawValue)': expected \(formatSpecifierCount) arguments, got \(arguments.count)")
        }
        
        return String(format: format, arguments: arguments)
    }
}

// MARK: - Localization Keys Enumeration
/// Typed enumeration of all localization keys used in the app
/// This ensures compile-time safety and prevents string key typos
enum LocalizationKey: String, CaseIterable {
    
    // MARK: - Navigation
    case navDashboard = "nav.dashboard"
    case navTasks = "nav.tasks"
    case navTickets = "nav.tickets"
    case navClients = "nav.clients"
    case navKPIs = "nav.kpis"
    case navSettings = "nav.settings"
    
    // MARK: - Common Actions
    case actionSave = "action.save"
    case actionCancel = "action.cancel"
    case actionDelete = "action.delete"
    case actionEdit = "action.edit"
    case actionCreate = "action.create"
    case actionAssign = "action.assign"
    case actionComplete = "action.complete"
    case actionFilter = "action.filter"
    case actionSearch = "action.search"
    case actionRefresh = "action.refresh"
    case actionExport = "action.export"
    
    // MARK: - Status Labels
    case statusPending = "status.pending"
    case statusInProgress = "status.in_progress"
    case statusCompleted = "status.completed"
    case statusCancelled = "status.cancelled"
    case statusOpen = "status.open"
    case statusClosed = "status.closed"
    case statusResolved = "status.resolved"
    
    // MARK: - Priority Labels
    case priorityLow = "priority.low"
    case priorityMedium = "priority.medium"
    case priorityHigh = "priority.high"
    case priorityCritical = "priority.critical"
    
    // MARK: - Form Labels
    case formTitle = "form.title"
    case formDescription = "form.description"
    case formDueDate = "form.due_date"
    case formAssignedTo = "form.assigned_to"
    case formPriority = "form.priority"
    case formCategory = "form.category"
    case formDepartment = "form.department"
    case formStore = "form.store"
    case formNotes = "form.notes"
    case formAttachments = "form.attachments"
    
    // MARK: - Error Messages
    case errorNetwork = "error.network"
    case errorValidation = "error.validation"
    case errorPermission = "error.permission"
    case errorUnknown = "error.unknown"
    case errorRequiredField = "error.required_field"
    case errorInvalidFormat = "error.invalid_format"
    case errorSaveFailed = "error.save_failed"
    case errorLoadFailed = "error.load_failed"
    
    // MARK: - Accessibility Labels
    case accessibilityTaskCard = "accessibility.task_card"
    case accessibilityTicketCard = "accessibility.ticket_card"
    case accessibilityClientCard = "accessibility.client_card"
    case accessibilityKPICard = "accessibility.kpi_card"
    case accessibilityCreateButton = "accessibility.create_button"
    case accessibilityFilterButton = "accessibility.filter_button"
    case accessibilitySearchButton = "accessibility.search_button"
    case accessibilityRefreshButton = "accessibility.refresh_button"
    
    // MARK: - Tasks Module
    case tasksTitle = "tasks.title"
    case tasksCreate = "tasks.create"
    case tasksAssignees = "tasks.assignees"
    case tasksProgress = "tasks.progress"
    case tasksOverdue = "tasks.overdue"
    
    // MARK: - Tickets Module
    case ticketsTitle = "tickets.title"
    case ticketsCreate = "tickets.create"
    case ticketsAssignee = "tickets.assignee"
    case ticketsReporter = "tickets.reporter"
    case ticketsResolution = "tickets.resolution"
    
    // MARK: - Clients Module
    case clientsTitle = "clients.title"
    case clientsCreate = "clients.create"
    case clientsContact = "clients.contact"
    case clientsHistory = "clients.history"
    case clientsPreferences = "clients.preferences"
    
    // MARK: - KPIs Module
    case kpisTitle = "kpis.title"
    case kpisMetrics = "kpis.metrics"
    case kpisTargets = "kpis.targets"
    case kpisProgress = "kpis.progress"
    
    // MARK: - Dashboard
    case dashboardWelcome = "dashboard.welcome"
    case dashboardOverview = "dashboard.overview"
    case dashboardRecentActivity = "dashboard.recent_activity"
    case dashboardQuickActions = "dashboard.quick_actions"
    
    // MARK: - Settings
    case settingsTitle = "settings.title"
    case settingsProfile = "settings.profile"
    case settingsNotifications = "settings.notifications"
    case settingsPrivacy = "settings.privacy"
    case settingsSupport = "settings.support"
    
    // MARK: - Notifications
    case notificationTaskAssigned = "notification.task_assigned"
    case notificationTicketUpdated = "notification.ticket_updated"
    case notificationFollowUpDue = "notification.followup_due"
    
    // MARK: - Validation Messages
    case validationTitleRequired = "validation.title_required"
    case validationDescriptionRequired = "validation.description_required"
    case validationDueDateInvalid = "validation.due_date_invalid"
    case validationAssigneeRequired = "validation.assignee_required"
    
    // MARK: - Confirmation Messages
    case confirmationDeleteTask = "confirmation.delete_task"
    case confirmationDeleteTicket = "confirmation.delete_ticket"
    case confirmationDeleteClient = "confirmation.delete_client"
    case confirmationMarkComplete = "confirmation.mark_complete"
    
    // MARK: - Success Messages
    case successTaskCreated = "success.task_created"
    case successTicketCreated = "success.ticket_created"
    case successClientCreated = "success.client_created"
    case successChangeSaved = "success.change_saved"
    
    // MARK: - Analytics Consent
    case consentBannerTitle = "consent.banner.title"
    case consentBannerMessage = "consent.banner.message"
    case consentBannerDetails = "consent.banner.details"
    case consentAcceptAll = "consent.accept_all"
    case consentDecline = "consent.decline"
    case consentDeclineAll = "consent.decline_all"
    case consentCustomize = "consent.customize"
    case consentCustomizeTitle = "consent.customize.title"
    case consentSavePreferences = "consent.save_preferences"
    case consentReset = "consent.reset"
    case consentResetTitle = "consent.reset.title"
    case consentResetMessage = "consent.reset.message"
    
    // MARK: - Consent Status
    case consentStatusUnknown = "consent.status.unknown"
    case consentStatusGranted = "consent.status.granted"
    case consentStatusDenied = "consent.status.denied"
    case consentStatusRevoked = "consent.status.revoked"
    case consentStatusExpired = "consent.status.expired"
    
    // MARK: - Analytics Categories
    case analyticsCategoryEssential = "analytics.category.essential"
    case analyticsCategoryPerformance = "analytics.category.performance"
    case analyticsCategoryFunctional = "analytics.category.functional"
    case analyticsCategoryTargeting = "analytics.category.targeting"
    case analyticsCategoryCrashes = "analytics.category.crashes"
    
    // MARK: - Analytics Category Descriptions
    case analyticsCategoryEssentialDesc = "analytics.category.essential.desc"
    case analyticsCategoryPerformanceDesc = "analytics.category.performance.desc"
    case analyticsCategoryFunctionalDesc = "analytics.category.functional.desc"
    case analyticsCategoryTargetingDesc = "analytics.category.targeting.desc"
    case analyticsCategoryCrashesDesc = "analytics.category.crashes.desc"
    
    // MARK: - Consent Settings
    case consentSettingsTitle = "consent.settings.title"
    case consentCurrentStatus = "consent.current_status"
    case consentCategories = "consent.categories"
    case consentCategoriesFooter = "consent.categories.footer"
    case consentActions = "consent.actions"
    case consentInformation = "consent.information"
    case consentPrivacyPolicy = "consent.privacy_policy"
    case consentDataUsage = "consent.data_usage"
    case consentVersion = "consent.version"
    
    // MARK: - Privacy Policy Content
    case privacyPolicyContent = "privacy.policy.content"
    case dataUsageContent = "data.usage.content"
}

// MARK: - SwiftUI Integration
extension LocalizationService {
    
    /// SwiftUI Text view with localized content
    func text(for key: LocalizationKey) -> Text {
        Text(string(for: key))
    }
    
    /// SwiftUI Text view with formatted arguments
    func text(for key: LocalizationKey, arguments: CVarArg...) -> Text {
        let localizedString = formattedString(for: key, arguments)
        return Text(localizedString)
    }
}

// MARK: - View Extensions for Localization
extension Text {
    /// Create Text with localized key
    init(_ key: LocalizationKey) {
        self.init(LocalizationService.shared.string(for: key))
    }
    
    /// Create Text with localized key and arguments
    init(_ key: LocalizationKey, arguments: CVarArg...) {
        let localizedString = LocalizationService.shared.formattedString(for: key, arguments)
        self.init(localizedString)
    }
}

extension String {
    /// Create String with localized key
    init(_ key: LocalizationKey) {
        self = LocalizationService.shared.string(for: key)
    }
    
    /// Create String with localized key and arguments
    init(_ key: LocalizationKey, arguments: CVarArg...) {
        self = LocalizationService.shared.formattedString(for: key, arguments)
    }
}

// MARK: - Accessibility Extensions
extension LocalizationService {
    
    /// Get accessibility label for UI element
    func accessibilityLabel(for element: AccessibilityElement) -> String {
        switch element {
        case .taskCard(let title):
            return formattedString(for: .accessibilityTaskCard, title)
        case .ticketCard(let title):
            return formattedString(for: .accessibilityTicketCard, title)
        case .clientCard(let name):
            return formattedString(for: .accessibilityClientCard, name)
        case .kpiCard(let metric):
            return formattedString(for: .accessibilityKPICard, metric)
        case .createButton(let type):
            return formattedString(for: .accessibilityCreateButton, type)
        case .filterButton:
            return string(for: .accessibilityFilterButton)
        case .searchButton:
            return string(for: .accessibilitySearchButton)
        case .refreshButton:
            return string(for: .accessibilityRefreshButton)
        }
    }
}

// MARK: - Accessibility Element Types
enum AccessibilityElement {
    case taskCard(title: String)
    case ticketCard(title: String)
    case clientCard(name: String)
    case kpiCard(metric: String)
    case createButton(type: String)
    case filterButton
    case searchButton
    case refreshButton
}
