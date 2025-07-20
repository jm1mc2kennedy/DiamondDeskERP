//
//  EmployeeCreationView.swift
//  DiamondDeskERP
//
//  Created by J.Michael McDermott on 7/20/25.
//

import SwiftUI

struct EmployeeCreationView: View {
    @ObservedObject var viewModel: DirectoryViewModel
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var jobTitle: String = ""
    @State private var department: Department?
    @State private var email: String = ""
    @State private var mobilePhone: String = ""
    @State private var profileImageURL: String = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Personal Info")) {
                    TextField("First Name", text: $firstName)
                    TextField("Last Name", text: $lastName)
                }
                Section(header: Text("Work Info")) {
                    TextField("Job Title", text: $jobTitle)
                    // Department picker based on existing departments
                    Picker("Department", selection: $department) {
                        Text("Select Department").tag(Department?.none)
                        ForEach(viewModel.employees.map { $0.organizationalInfo.department }.unique(), id: \.id) { dept in
                            Text(dept.name).tag(Optional(dept))
                        }
                    }
                Section(header: Text("Contact")) {
                    TextField("Email", text: $email)
                    TextField("Mobile Phone", text: $mobilePhone)
                    TextField("Profile Image URL", text: $profileImageURL)
                }
            }
            .navigationTitle("Add Employee")
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Save") {
                    Task {
                        await viewModel.saveNewEmployee(
                            firstName: firstName,
                            lastName: lastName,
                            jobTitle: jobTitle,
                            department: department,
                            email: email,
                            mobilePhone: mobilePhone.isEmpty ? nil : mobilePhone,
                            profileImageURL: profileImageURL.isEmpty ? nil : profileImageURL
                        )
                        dismiss()
                    }
                }
                .disabled(firstName.isEmpty || lastName.isEmpty || department == nil)
            )
            // Show error alert if save fails
            .alert("Error", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { _ in viewModel.errorMessage = nil }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "Unknown error")
            }
            )
        }
    }
}

#Preview {
    EmployeeCreationView()
}
