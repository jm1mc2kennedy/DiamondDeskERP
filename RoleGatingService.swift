import Foundation

enum Feature {
    case manageUsers
    case assignStores
    case createTasksAllStores
    case closeTickets
    case viewAllSalesKPIs
    case uploadTraining
    case approveMarketingContent
}

class RoleGatingService {
    static func hasPermission(for role: UserRole, to access: Feature) -> Bool {
        switch access {
        case .manageUsers:
            return role == .admin
        case .assignStores:
            return role == .admin || role == .areaDirector
        case .createTasksAllStores:
            return role == .admin || role == .areaDirector
        case .closeTickets:
            return [.admin, .areaDirector, .storeDirector, .departmentHead, .agent].contains(role)
        case .viewAllSalesKPIs:
            return role == .admin || role == .areaDirector
        case .uploadTraining:
            return [.admin, .areaDirector, .departmentHead, .agent].contains(role)
        case .approveMarketingContent:
            return [.admin, .areaDirector, .storeDirector, .departmentHead, .agent].contains(role)
        }
    }
}
