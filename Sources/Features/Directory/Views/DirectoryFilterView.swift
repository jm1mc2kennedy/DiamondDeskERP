//
//  DirectoryFilterView.swift
//  DiamondDeskERP
//
//  Created by J.Michael McDermott on 7/20/25.
//

import SwiftUI

struct DirectoryFilterView: View {
    @StateObject var viewModel: DirectoryViewModel
    @Environment(\.dismiss) private var dismiss

    // Filtering criteria
    @State private var searchText: String = ""
    @State private var selectedDepartments: Set<String> = []
    @State private var selectedLevels: Set<EmployeeLevel> = []
    @State private var selectedLocations: Set<LocationType> = []

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Search")) {
                    TextField("Search by name or skill", text: $searchText)
                }
                
                Section(header: Text("Departments")) {
                    // TODO: Replace with dynamic department list
                    ForEach(viewModel.employees.map { $0.organizationalInfo.department.name }.unique(), id: \ .self) { dept in
                        Toggle(dept, isOn: Binding(
                            get: { selectedDepartments.contains(dept) },
                            set: { on in
                                if on { selectedDepartments.insert(dept) } else { selectedDepartments.remove(dept) }
                            }
                        ))
                    }
                }
                
                Section(header: Text("Levels")) {
                    // Dynamic levels based on loaded employees
                    let levels = viewModel.employees.map { $0.organizationalInfo.level }.unique()
                    ForEach(levels, id: \.self) { level in
                        Toggle(level.rawValue, isOn: Binding(
                            get: { selectedLevels.contains(level) },
                            set: { on in
                                if on { selectedLevels.insert(level) } else { selectedLevels.remove(level) }
                            }
                        ))
                    }
                }
                
                Section(header: Text("Locations")) {
                    // Dynamic locations based on loaded employees
                    let locs = viewModel.employees.map { $0.organizationalInfo.location.type }.unique()
                    ForEach(locs, id: \.self) { loc in
                        Toggle(loc.rawValue, isOn: Binding(
                            get: { selectedLocations.contains(loc) },
                            set: { on in
                                if on { selectedLocations.insert(loc) } else { selectedLocations.remove(loc) }
                            }
                        ))
                    }
                }
            }
            .navigationTitle("Directory Filters")
                .navigationBarItems(
                    leading: Button("Cancel") { dismiss() },
                    trailing: Button("Apply") {
                        // Build criteria and reload directory
                        let criteria = DirectorySearchCriteria(
                            searchText: searchText.isEmpty ? nil : searchText,
                            departments: Array(selectedDepartments),
                            locations: Array(selectedLocations),
                            employeeLevels: Array(selectedLevels)
                        )
                        Task {
                            await viewModel.loadEmployees(criteria: criteria)
                        }
                        dismiss()
                    }
                )
        }
    }
}

#Preview {
    DirectoryFilterView(viewModel: DirectoryViewModel())
}
