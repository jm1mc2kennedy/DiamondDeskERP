import SwiftUI

struct ContentView: View {
    @Environment(\.currentUser) private var currentUser
    @StateObject private var consentService = AnalyticsConsentService.shared

    var body: some View {
        ZStack {
            TabView {
                DashboardView()
                    .tabItem {
                        Label("Dashboard", systemImage: "house")
                    }

                if let user = currentUser {
                    TicketListView(userRef: user.userId)
                        .tabItem {
                            Label("Tickets", systemImage: "ticket")
                        }

                    TaskListView(userRef: user.userId)
                        .tabItem {
                            Label("Tasks", systemImage: "checkmark.circle")
                        }

                    ClientListView(userRef: user.userId)
                        .tabItem {
                            Label("Clients", systemImage: "person.3")
                        }
                    
                    // AI Insights Tab (Enterprise Feature)
                    AIInsightsListView()
                        .tabItem {
                            Label("AI Insights", systemImage: "brain.head.profile")
                        }

                    if let storeCode = user.storeCodes.first {
                        KPIListView(storeCode: storeCode)
                            .tabItem {
                                Label("KPIs", systemImage: "chart.bar")
                            }
                    }
                } else {
                    ProgressView("Loading...")
                }
            }
            
            // Analytics Consent Banner
            AnalyticsConsentBanner()
        }
        .onAppear {
            // Initialize consent flow when app appears
            consentService.initializeConsentFlow()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
