//
//  DirectoryListView.swift
//  DiamondDeskERP
//
//  Created by J.Michael McDermott on 7/20/25.
//

import SwiftUI

struct DirectoryListView: View {
    @StateObject var viewModel: DirectoryViewModel
    // Show creation and filter sheets
    @State private var showingCreation = false
    @State private var showingFilter = false
    @State private var navigationPath = NavigationPath()

    var body: some View {
        SimpleAdaptiveNavigationView(path: $navigationPath) {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading Directory...")
                } else if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                } else if viewModel.employees.isEmpty {
                    Text("No employees found.")
                        .foregroundColor(.secondary)
                } else {
                    List(viewModel.employees) { employee in
                        Button(action: {
                            NavigationRouter.shared.selectedEmployee = employee
                            NavigationRouter.shared.dashboardPath.append(.employeeDetail(employee.id.uuidString))
                        }) {
                            HStack {
                                Image(systemName: "person.crop.circle")
                                    .font(.title2)
                                VStack(alignment: .leading) {
                                    Text(employee.personalInfo.displayName)
                                        .font(.headline)
                                    Text(employee.organizationalInfo.jobTitle)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Directory")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingFilter = true }) {
                        Image(systemName: "line.horizontal.3.decrease.circle")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingCreation = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            // Filter sheet
            .sheet(isPresented: $showingFilter) {
                DirectoryFilterView(viewModel: viewModel)
            }
            // Creation sheet
            .sheet(isPresented: $showingCreation) {
                EmployeeCreationView(viewModel: viewModel)
            }
            .task {
                await viewModel.loadEmployees()
            }
        }
    }
}

#Preview {
    DirectoryListView(viewModel: DirectoryViewModel())
}
