//
//  AdaptiveNavigationView.swift
//  DiamondDeskERP
//
//  Created by J.Michael McDermott on 7/20/25.
//

import SwiftUI

/// Adaptive navigation component that provides optimal navigation experience
/// across iPhone and iPad devices using modern iOS 16+ navigation APIs
struct AdaptiveNavigationView<Sidebar: View, Content: View>: View {
    
    // MARK: - Properties
    
    let sidebar: Sidebar
    let content: Content
    let isAdminView: Bool
    
    @StateObject private var router = NavigationRouter.shared
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    // MARK: - Initialization
    
    init(
        isAdminView: Bool = false,
        @ViewBuilder sidebar: () -> Sidebar,
        @ViewBuilder content: () -> Content
    ) {
        self.isAdminView = isAdminView
        self.sidebar = sidebar()
        self.content = content()
    }
    
    // MARK: - Body
    
    var body: some View {
        Group {
            if shouldUseSplitView {
                NavigationSplitView {
                    sidebar
                        .navigationSplitViewColumnWidth(min: 250, ideal: 300, max: 350)
                } detail: {
                    content
                        .navigationBarTitleDisplayMode(.large)
                }
                .navigationSplitViewStyle(.balanced)
            } else {
                NavigationStack {
                    content
                        .navigationBarTitleDisplayMode(.large)
                }
            }
        }
        .tint(.accentColor)
        .environment(\.navigationRouter, router)
    }
    
    // MARK: - Computed Properties
    
    private var shouldUseSplitView: Bool {
        // Use split view on iPad in regular horizontal size class
        // or when explicitly configured for admin views
        return UIDevice.current.userInterfaceIdiom == .pad && 
               horizontalSizeClass == .regular ||
               (isAdminView && horizontalSizeClass == .regular)
    }
}

// MARK: - Simple Adaptive Navigation (No Sidebar)

struct SimpleAdaptiveNavigationView<Content: View>: View {
    
    let content: Content
    let path: Binding<NavigationPath>
    
    @StateObject private var router = NavigationRouter.shared
    
    init(
        path: Binding<NavigationPath>,
        @ViewBuilder content: () -> Content
    ) {
        self.path = path
        self.content = content()
    }
    
    var body: some View {
        NavigationStack(path: path) {
            content
                .navigationBarTitleDisplayMode(.large)
        }
        .tint(.accentColor)
        .environment(\.navigationRouter, router)
    }
}

// MARK: - Tab-Based Adaptive Navigation

struct TabAdaptiveNavigationView: View {
    
    @StateObject private var router = NavigationRouter.shared
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var body: some View {
        Group {
            if shouldUseTabView {
                TabView(selection: $router.selectedTab) {
                    DashboardTabView()
                        .tabItem {
                            Image(systemName: NavigationRouter.NavigationTab.dashboard.systemImage)
                            Text(NavigationRouter.NavigationTab.dashboard.title)
                        }
                        .tag(NavigationRouter.NavigationTab.dashboard)
                    
                    TasksTabView()
                        .tabItem {
                            Image(systemName: NavigationRouter.NavigationTab.tasks.systemImage)
                            Text(NavigationRouter.NavigationTab.tasks.title)
                        }
                        .tag(NavigationRouter.NavigationTab.tasks)
                    
                    TicketsTabView()
                        .tabItem {
                            Image(systemName: NavigationRouter.NavigationTab.tickets.systemImage)
                            Text(NavigationRouter.NavigationTab.tickets.title)
                        }
                        .tag(NavigationRouter.NavigationTab.tickets)
                    
                    DocumentsTabView()
                        .tabItem {
                            Image(systemName: NavigationRouter.NavigationTab.documents.systemImage)
                            Text(NavigationRouter.NavigationTab.documents.title)
                        }
                        .tag(NavigationRouter.NavigationTab.documents)
                    
                    CRMTabView()
                        .tabItem {
                            Image(systemName: NavigationRouter.NavigationTab.crm.systemImage)
                            Text(NavigationRouter.NavigationTab.crm.title)
                        }
                        .tag(NavigationRouter.NavigationTab.crm)
                    
                    AdminTabView()
                        .tabItem {
                            Image(systemName: NavigationRouter.NavigationTab.admin.systemImage)
                            Text(NavigationRouter.NavigationTab.admin.title)
                        }
                        .tag(NavigationRouter.NavigationTab.admin)
                }
                .tint(.accentColor)
            } else {
                // iPad split view with sidebar navigation
                NavigationSplitView {
                    MainSidebarView()
                        .navigationSplitViewColumnWidth(min: 250, ideal: 300, max: 350)
                } detail: {
                    MainDetailView()
                }
                .navigationSplitViewStyle(.balanced)
                .tint(.accentColor)
            }
        }
        .environment(\.navigationRouter, router)
    }
    
    private var shouldUseTabView: Bool {
        return UIDevice.current.userInterfaceIdiom == .phone || 
               horizontalSizeClass == .compact
    }
}

// MARK: - Tab Content Views

private struct DashboardTabView: View {
    @StateObject private var router = NavigationRouter.shared
    
    var body: some View {
        SimpleAdaptiveNavigationView(path: $router.dashboardPath) {
            EnhancedDashboardView()
        }
    }
}

private struct TasksTabView: View {
    @StateObject private var router = NavigationRouter.shared
    
    var body: some View {
        SimpleAdaptiveNavigationView(path: $router.tasksPath) {
            TaskListView()
        }
    }
}

private struct TicketsTabView: View {
    @StateObject private var router = NavigationRouter.shared
    
    var body: some View {
        SimpleAdaptiveNavigationView(path: $router.ticketsPath) {
            TicketListView()
        }
    }
}

private struct CRMTabView: View {
    @StateObject private var router = NavigationRouter.shared
    
    var body: some View {
        SimpleAdaptiveNavigationView(path: $router.crmPath) {
            CRMDashboardView()
        }
    }
}

private struct DocumentsTabView: View {
    @StateObject private var router = NavigationRouter.shared
    
    var body: some View {
        SimpleAdaptiveNavigationView(path: $router.documentsPath) {
            DocumentListView()
        }
    }
}

private struct AdminTabView: View {
    @StateObject private var router = NavigationRouter.shared
    
    var body: some View {
        SimpleAdaptiveNavigationView(path: $router.adminPath) {
            AdminDashboardView()
        }
    }
}

// MARK: - iPad Sidebar Views

private struct MainSidebarView: View {
    @StateObject private var router = NavigationRouter.shared
    
    var body: some View {
        List(NavigationRouter.NavigationTab.allCases, id: \.self, selection: $router.selectedTab) { tab in
            NavigationLink(value: tab) {
                Label(tab.title, systemImage: tab.systemImage)
            }
        }
        .navigationTitle("DiamondDesk ERP")
        .navigationBarTitleDisplayMode(.large)
    }
}

private struct MainDetailView: View {
    @StateObject private var router = NavigationRouter.shared
    
    var body: some View {
        Group {
            switch router.selectedTab {
            case .dashboard:
                SimpleAdaptiveNavigationView(path: $router.dashboardPath) {
                    EnhancedDashboardView()
                }
            case .tasks:
                SimpleAdaptiveNavigationView(path: $router.tasksPath) {
                    TaskListView()
                }
            case .tickets:
                SimpleAdaptiveNavigationView(path: $router.ticketsPath) {
                    TicketListView()
                }
            case .documents:
                SimpleAdaptiveNavigationView(path: $router.documentsPath) {
                    DocumentListView()
                }
            case .crm:
                SimpleAdaptiveNavigationView(path: $router.crmPath) {
                    CRMDashboardView()
                }
            case .admin:
                SimpleAdaptiveNavigationView(path: $router.adminPath) {
                    AdminDashboardView()
                }
            }
        }
    }
}

// MARK: - Admin Dashboard Placeholder

private struct AdminDashboardView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Admin Dashboard")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Administrative tools and system monitoring")
                .font(.title2)
                .foregroundColor(.secondary)
            
            // Admin navigation options will be implemented during view migration
            Text("Event QA Console, Conflict Viewer, and other admin tools will be accessible here")
                .font(.caption)
                .multilineTextAlignment(.center)
                .padding()
        }
        .padding()
        .navigationTitle("Admin")
    }
}

// MARK: - Environment Key for Navigation Router

private struct NavigationRouterKey: EnvironmentKey {
    static let defaultValue = NavigationRouter.shared
}

extension EnvironmentValues {
    var navigationRouter: NavigationRouter {
        get { self[NavigationRouterKey.self] }
        set { self[NavigationRouterKey.self] = newValue }
    }
}
