//
//  ContentView.swift
//  DiamondDeskERP
//
//  Created by J.Michael McDermott on 7/18/25.
//

import SwiftUI
import CloudKit

struct ContentView: View {
    // Changed to optional and initially nil to represent loading state of user ID
    @State var currentUserId: String? = nil
    // New state variable to hold the list of store codes for the user, initially nil (loading)
    @State var userStoreCodes: [String]? = nil
    
    // Notification banner state object
    @StateObject var notificationService = NotificationService.shared
    // Internal state to control banner visibility timing
    @State private var showBanner: Bool = false
    
    // MARK: - Onboarding UI Integration
    // State to control showing onboarding sheet
    @State private var showOnboarding: Bool = false

    var body: some View {
        ZStack(alignment: .top) {
            TabView {
                VStack {
                    Text("Dashboard Placeholder")
                        .font(.largeTitle)
                        .padding()
                    Spacer()
                }
                .tabItem {
                    Label("Dashboard", systemImage: "house")
                }

                // Tickets module
                Group {
                    if let userId = currentUserId {
                        TicketListView(userRef: userId)
                    } else {
                        ProgressView()
                    }
                }
                .tabItem {
                    Label("Tickets", systemImage: "ticket")
                }

                // Show ProgressView if currentUserId is nil (loading), else show TaskListView
                Group {
                    if let userId = currentUserId {
                        TaskListView(userRef: userId)
                    } else {
                        VStack {
                            ProgressView()
                            Text("Loading user data...")
                                .padding(.top, 8)
                        }
                    }
                }
                .tabItem {
                    Label("Tasks", systemImage: "checkmark.circle")
                }

                // New Clients tab
                Group {
                    if let userId = currentUserId {
                        ClientListView(userRef: userId)
                    } else {
                        ProgressView()
                    }
                }
                .tabItem {
                    Label("Clients", systemImage: "person.3")
                }

                // New KPIs tab
                Group {
                    if let storeCodes = userStoreCodes, !storeCodes.isEmpty {
                        KPIListView(storeCode: storeCodes[0])
                    } else {
                        ProgressView()
                    }
                }
                .tabItem {
                    Label("KPIs", systemImage: "chart.bar")
                }
                
                // --- Reporting Integration ---
                Group {
                    if let storeCodes = userStoreCodes, !storeCodes.isEmpty {
                        StoreReportListView(storeCode: storeCodes[0])
                    } else {
                        ProgressView()
                    }
                }
                .tabItem {
                    Label("Reports", systemImage: "chart.bar")
                }
            }
            
            // MARK: - In-App Notification Banner
            if let message = notificationService.latestMessage, showBanner {
                VStack {
                    Text(message)
                        .font(.callout)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(.ultraThinMaterial)
                        .accessibilityLabel("Notification: \(message)")
                        .cornerRadius(10)
                        .shadow(radius: 5)
                        .padding(.horizontal)
                        .padding(.top, 8)
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(1)
            }
        }
        .onChange(of: notificationService.latestMessage) { newValue in
            // Show the banner when a new message arrives
            withAnimation {
                showBanner = newValue != nil
            }
            // Hide the banner after 3 seconds
            if newValue != nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation {
                        showBanner = false
                    }
                }
            }
        }
        .sheet(isPresented: $showOnboarding) {
            // Present the onboarding view modally
            OnboardingView(isPresented: $showOnboarding) { selectedRole, selectedStores in
                Task {
                    guard let userId = currentUserId else { return }
                    do {
                        // Fetch the User record for updating
                        let predicate = NSPredicate(format: "userId == %@", userId)
                        let query = CKQuery(recordType: "User", predicate: predicate)
                        let database = CKContainer.default().publicCloudDatabase
                        let (results, _) = try await database.records(matching: query)
                        if let record = results.compactMap({ $0.1 }).first {
                            // Update role and storeCodes fields
                            record["role"] = selectedRole
                            record["storeCodes"] = selectedStores
                            try await database.save(record)
                            
                            // Update local state with new store codes
                            await MainActor.run {
                                userStoreCodes = selectedStores
                            }
                        } else {
                            // If no record exists, optionally create one (not specified)
                        }
                        // Mark onboarding as complete in UserDefaults
                        UserDefaults.standard.set(true, forKey: "onboardingComplete")
                    } catch {
                        print("Failed to save onboarding data: \(error)")
                    }
                }
            }
        }
        .task {
            // Asynchronously fetch or create the user ID on appear
            let fetchedUserId = await UserProvisioningService.shared.fetchOrCreateUserId()
            
            // Fetch the User record and extract storeCodes
            var fetchedStoreCodes: [String]? = nil
            do {
                let predicate = NSPredicate(format: "userId == %@", fetchedUserId)
                let query = CKQuery(recordType: "User", predicate: predicate)
                let database = CKContainer.default().publicCloudDatabase
                let (results, _) = try await database.records(matching: query)
                if let record = results.compactMap({ $0.1 }).first {
                    fetchedStoreCodes = record["storeCodes"] as? [String]
                }
            } catch {
                print("Failed to fetch User record or storeCodes: \(error)")
            }
            
            // Assign the fetched user ID and store codes to state variables on the main actor to update UI
            await MainActor.run {
                currentUserId = fetchedUserId
                userStoreCodes = fetchedStoreCodes
                
                // Show onboarding sheet if user hasn't completed onboarding
                let onboardingComplete = UserDefaults.standard.bool(forKey: "onboardingComplete")
                if !onboardingComplete {
                    showOnboarding = true
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
