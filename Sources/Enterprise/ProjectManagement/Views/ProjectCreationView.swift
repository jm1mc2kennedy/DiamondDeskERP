//
//  ProjectCreationView.swift
//  DiamondDeskERP
//
//  Created by J.Michael McDermott on 7/20/25.
//

import SwiftUI

struct ProjectCreationView: View {
    @ObservedObject var viewModel: ProjectListViewModel
    @State private var name: String = ""
    @State private var description: String = ""
    @State private var startDate: Date = Date()
    @State private var endDate: Date? = nil
    @State private var status: ProjectStatus = .planning
    @State private var navigationPath = NavigationPath()
    @Environment(\.dismiss) private var dismiss
    @State private var showError = false

    var body: some View {
        SimpleAdaptiveNavigationView(path: $navigationPath) {
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
                    Task {
                        await viewModel.saveNewProject(
                            name: name,
                            description: description.isEmpty ? nil : description,
                            startDate: startDate,
                            endDate: endDate,
                            status: status
                        )
                        if viewModel.errorMessage != nil {
                            showError = true
                        } else {
                            dismiss()
                        }
                    }
                }
                .disabled(name.isEmpty)
            )
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { showError = false }
            } message: {
                Text(viewModel.errorMessage ?? "Unknown error")
            }
        }
        }
    }
}

#Preview {
    ProjectCreationView()
}
