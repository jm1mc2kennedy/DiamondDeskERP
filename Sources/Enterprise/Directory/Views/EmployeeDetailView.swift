//
//  EmployeeDetailView.swift
//  DiamondDeskERP
//
//  Created by J.Michael McDermott on 7/20/25.
//

import SwiftUI

struct EmployeeDetailView: View {
    let employeeId: String
    @StateObject private var viewModel = DirectoryViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Loading Employee...")
            } else if let employee = viewModel.employees.first(where: { $0.id.uuidString == employeeId }) {
                ScrollView {
                    VStack(spacing: 16) {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .frame(width: 100, height: 100)
                            .padding()
                        Text(employee.personalInfo.fullName)
                            .font(.title)
                            .fontWeight(.bold)
                        Text(employee.organizationalInfo.jobTitle)
                            .font(.headline)
                            .foregroundColor(.secondary)
                        // TODO: Display further employee details
                    }
                    .padding()
                }
            } else {
                Text("Employee not found.")
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Employee Profile")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadEmployees()
        }
    }
}

#Preview {
    EmployeeDetailView(employeeId: UUID().uuidString)
}
