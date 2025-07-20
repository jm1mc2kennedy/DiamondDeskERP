//
//  ProjectCreationView.swift
//  DiamondDeskERP
//
//  Created by J.Michael McDermott on 7/20/25.
//

import SwiftUI

struct ProjectCreationView: View {
    @State private var name: String = ""
    @State private var description: String = ""
    @State private var startDate: Date = Date()
    @State private var endDate: Date? = nil
    @State private var status: ProjectStatus = .planning
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Project Info")) {
                    TextField("Name", text: $name)
                    TextEditor(text: $description)
                        .frame(height: 100)
                }
                Section(header: Text("Timeline")) {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    DatePicker("End Date", selection: Binding(get: { endDate ?? Date() }, set: { endDate = $0 }), displayedComponents: .date)
                        .environment(\.defaultMinDate, startDate)
                }
                Section(header: Text("Status")) {
                    Picker("Status", selection: $status) {
                        ForEach(ProjectStatus.allCases, id: \.self) { status in
                            Text(status.rawValue).tag(status)
                        }
                    }
                }
            }
            .navigationTitle("New Project")
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Save") {
                    // TODO: Save project
                    dismiss()
                }.disabled(name.isEmpty)
            )
        }
    }
}

#Preview {
    ProjectCreationView()
}
