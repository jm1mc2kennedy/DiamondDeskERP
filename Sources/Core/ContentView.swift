import SwiftUI

struct ContentView: View {
    @Environment(\.currentUser) private var currentUser

    var body: some View {
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
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
