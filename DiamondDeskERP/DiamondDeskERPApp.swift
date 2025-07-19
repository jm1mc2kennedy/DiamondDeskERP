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
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
