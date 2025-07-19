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
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            PublicMessageBoardView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .task { 
                    await runSeederIfNeeded() 
                    // --- CloudKit Notification Integration ---
                    // After user provisioning (when userId is known), call:
                    // await NotificationService.shared.registerSubscriptions(for: userId)
                    // If using AppDelegate or SceneDelegate, ensure push notifications received are passed to NotificationService.shared.handleNotification(_:)
                }
        }
    }

    #if DEBUG
    private func runSeederIfNeeded() async {
        do {
            try await Seeder.runIfNeeded()
            os_log("[Seeder] Completed")
        } catch {
            os_log("[Seeder] Error: %{public}@", String(describing: error))
        }
    }
    #else
    private func runSeederIfNeeded() async {}
    #endif
}
