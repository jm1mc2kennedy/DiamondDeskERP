// OnboardingView.swift
// Diamond Desk ERP
// New user onboarding for role, store, and preferences

import SwiftUI

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @State private var selectedRole: String = "Associate"
    @State private var selectedStores: Set<String> = []
    @State private var wantsNotifications: Bool = true
    @State private var availableStores: [String] = ["Store 01", "Store 02", "Store 03"] // Replace with dynamic fetch if available
    
    var onComplete: (String, [String], Bool) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Your Role")) {
                    Picker("Role", selection: $selectedRole) {
                        Text("Associate").tag("Associate")
                        Text("Store Director").tag("StoreDirector")
                        Text("Area Director").tag("AreaDirector")
                        Text("Admin").tag("Admin")
                    }
                    .accessibilityLabel("Select your role")
                }
                Section(header: Text("Assigned Stores")) {
                    ForEach(availableStores, id: \.self) { store in
                        Toggle(store, isOn: Binding(
                            get: { selectedStores.contains(store) },
                            set: { checked in
                                if checked { selectedStores.insert(store) } else { selectedStores.remove(store) }
                            })
                        )
                        .accessibilityLabel("Select store \(store)")
                    }
                }
                Section(header: Text("Preferences")) {
                    Toggle("Enable Notifications", isOn: $wantsNotifications)
                        .accessibilityLabel("Enable notifications")
                }
            }
            .navigationTitle("Welcome!")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Continue") {
                        onComplete(selectedRole, Array(selectedStores), wantsNotifications)
                        isPresented = false
                    }
                    .disabled(selectedStores.isEmpty)
                    .accessibilityLabel("Complete onboarding")
                }
            }
        }
    }
}
