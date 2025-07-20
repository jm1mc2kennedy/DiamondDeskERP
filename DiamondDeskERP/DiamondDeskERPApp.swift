//
//  DiamondDeskERPApp.swift
//  DiamondDeskERP
//
//  Created by J.Michael McDermott on 7/18/25.
//

import SwiftUI
import CoreData
#if DEBUG
import os
#endif
import CloudKit
import Foundation

@main
struct DiamondDeskERPApp: App {
    @StateObject private var userProvisioningService = UserProvisioningService()

    var body: some Scene {
        WindowGroup {
            if let user = userProvisioningService.currentUser {
                ContentView()
                    .environment(\.currentUser, user)
            } else {
                ProgressView("Provisioning User...")
                    .onAppear {
                        Task {
                            // In a real app, you'd get the user's real ID from Sign In with Apple
                            await userProvisioningService.provisionUser(userId: "testUser123", email: "test@example.com", displayName: "Test User")
                        }
                    }
            }
        }
    }
}
