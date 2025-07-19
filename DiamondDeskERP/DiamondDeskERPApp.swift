//
//  DiamondDeskERPApp.swift
//  DiamondDeskERP
//
//  Created by J.Michael McDermott on 7/18/25.
//

import SwiftUI
import CoreData

@main
struct DiamondDeskERPApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            PublicMessageBoardView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

/*
struct DiamondDeskERPMessageBoardApp: App {
    var body: some Scene {
        WindowGroup {
            PublicMessageBoardView()
        }
    }
}
*/
