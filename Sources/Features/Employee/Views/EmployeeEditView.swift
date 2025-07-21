import SwiftUI

struct EmployeeEditView: View {
    let employee: Employee
    @ObservedObject var viewModel: EmployeeViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var firstName: String
    @State private var lastName: String
    @State private var email: String
    @State private var phone: String
    @State private var department: String
    @State private var title: String
    @State private var birthDate: Date
    @State private var includeBirthDate: Bool
    @State private var workLocation: WorkLocation
    @State private var employmentType: EmploymentType
    @State private var salaryGrade: String
    @State private var costCenter: String
    @State private var securityClearance: SecurityClearance
    
    // Address fields
    @State private var street: String
    @State private var city: String
    @State private var state: String
    @State private var zipCode: String
    @State private var country: String
    
    // Emergency contact fields
    @State private var emergencyName: String
    @State private var emergencyRelationship: String
    @State private var emergencyPhone: String
    @State private var emergencyEmail: String
    
    // Skills and certifications
    @State private var skills: [String]
    @State private var newSkill: String = ""
    @State private var certifications: [CertificationInput]
    
    // Manager selection
    @State private var selectedManager: Employee?
    @State private var showingManagerPicker = false
    
    // Profile photo
    @State private var profilePhoto: String?
    @State private var showingImagePicker = false
    
    // Form validation
    @State private var showingValidationAlert = false
    @State private var validationMessage = ""
    
    // Current form step
    @State private var currentStep: EditFormStep = .basic
    
    init(employee: Employee, viewModel: EmployeeViewModel) {
        self.employee = employee
        self.viewModel = viewModel
        
        // Initialize state with employee data
        _firstName = State(initialValue: employee.firstName)
        _lastName = State(initialValue: employee.lastName)
        _email = State(initialValue: employee.email)
        _phone = State(initialValue: employee.phone ?? "")
        _department = State(initialValue: employee.department)
        _title = State(initialValue: employee.title)
        _birthDate = State(initialValue: employee.birthDate ?? Date())
        _includeBirthDate = State(initialValue: employee.birthDate != nil)
        _workLocation = State(initialValue: employee.workLocation)
        _employmentType = State(initialValue: employee.employmentType)
        _salaryGrade = State(initialValue: employee.salaryGrade ?? "")
        _costCenter = State(initialValue: employee.costCenter ?? "")
        _securityClearance = State(initialValue: employee.securityClearance ?? .none)
        
        _street = State(initialValue: employee.address.street)
        _city = State(initialValue: employee.address.city)
        _state = State(initialValue: employee.address.state)
        _zipCode = State(initialValue: employee.address.zipCode)
        _country = State(initialValue: employee.address.country)
        
        _emergencyName = State(initialValue: employee.emergencyContact.name)
        _emergencyRelationship = State(initialValue: employee.emergencyContact.relationship)
        _emergencyPhone = State(initialValue: employee.emergencyContact.phone)
        _emergencyEmail = State(initialValue: employee.emergencyContact.email ?? "")
        
        _skills = State(initialValue: employee.skills)
        _certifications = State(initialValue: employee.certifications.map { cert in
            CertificationInput(
                name: cert.name,
                issuingOrganization: cert.issuingOrganization,
                issueDate: cert.issueDate,
                hasExpiration: cert.expirationDate != nil,
                expirationDate: cert.expirationDate ?? Date()
            )
        })
        
        _profilePhoto = State(initialValue: employee.profilePhoto)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress indicator
                EditProgressIndicator(currentStep: currentStep)
                
                // Form content
                TabView(selection: $currentStep) {
                    BasicInfoEditForm()
                        .tag(EditFormStep.basic)
                    
                    ContactInfoEditForm()
                        .tag(EditFormStep.contact)
                    
                    EmploymentInfoEditForm()
                        .tag(EditFormStep.employment)
                    
                    SkillsEditForm()
                        .tag(EditFormStep.skills)
                    
                    ReviewEditForm()
                        .tag(EditFormStep.review)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                
                // Navigation buttons
                EditNavigationButtons()
            }
            .navigationTitle("Edit \(employee.firstName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if currentStep == .review {
                        Button("Save") {
                            saveChanges()
                        }
                        .disabled(viewModel.isLoading || !hasChanges())
                    }
                }
            }
            .alert("Validation Error", isPresented: $showingValidationAlert) {
                Button("OK") { }
            } message: {
                Text(validationMessage)
            }
            .sheet(isPresented: $showingManagerPicker) {
                ManagerPickerView(selectedManager: $selectedManager, employees: viewModel.employees)
            }
            .onAppear {
                loadManagerSelection()
            }
        }
    }
    
    // MARK: - Form Steps
    
    @ViewBuilder
    private func BasicInfoEditForm() -> some View {
        ScrollView {
            VStack(spacing: 20) {
                FormSection(title: "Basic Information") {
                    VStack(spacing: 16) {
                        HStack {
                            Text("Employee Number")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(employee.employeeNumber)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        FormField(title: "First Name", text: $firstName, isRequired: true)
                        
                        FormField(title: "Last Name", text: $lastName, isRequired: true)
                        
                        FormField(title: "Email", text: $email, isRequired: true)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                        
                        FormField(title: "Phone", text: $phone)
                            .keyboardType(.phonePad)
                        
                        HStack {
                            Text("Hire Date")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(formatDate(employee.hireDate))
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        Toggle("Include Birth Date", isOn: $includeBirthDate)
                        
                        if includeBirthDate {
                            DateField(title: "Birth Date", date: $birthDate)
                        }
                    }
                }
                
                ProfilePhotoEditSection()
            }
            .padding()
        }
    }
    
    @ViewBuilder
    private func ContactInfoEditForm() -> some View {
        ScrollView {
            VStack(spacing: 20) {
                FormSection(title: "Address") {
                    VStack(spacing: 16) {
                        FormField(title: "Street Address", text: $street, isRequired: true)
                        
                        HStack(spacing: 12) {
                            FormField(title: "City", text: $city, isRequired: true)
                            FormField(title: "State", text: $state, isRequired: true)
                        }
                        
                        HStack(spacing: 12) {
                            FormField(title: "ZIP Code", text: $zipCode, isRequired: true)
                                .keyboardType(.numberPad)
                            FormField(title: "Country", text: $country, isRequired: true)
                        }
                    }
                }
                
                FormSection(title: "Emergency Contact") {
                    VStack(spacing: 16) {
                        FormField(title: "Full Name", text: $emergencyName, isRequired: true)
                        
                        FormField(title: "Relationship", text: $emergencyRelationship, isRequired: true)
                        
                        FormField(title: "Phone Number", text: $emergencyPhone, isRequired: true)
                            .keyboardType(.phonePad)
                        
                        FormField(title: "Email (Optional)", text: $emergencyEmail)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                    }
                }
            }
            .padding()
        }
    }
    
    @ViewBuilder
    private func EmploymentInfoEditForm() -> some View {
        ScrollView {
            VStack(spacing: 20) {
                FormSection(title: "Employment Details") {
                    VStack(spacing: 16) {
                        FormField(title: "Department", text: $department, isRequired: true)
                        
                        FormField(title: "Job Title", text: $title, isRequired: true)
                        
                        Picker("Work Location", selection: $workLocation) {
                            ForEach(WorkLocation.allCases, id: \.self) { location in
                                Text(location.displayName).tag(location)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Picker("Employment Type", selection: $employmentType) {
                            ForEach(EmploymentType.allCases, id: \.self) { type in
                                Text(type.displayName).tag(type)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        FormField(title: "Salary Grade (Optional)", text: $salaryGrade)
                        
                        FormField(title: "Cost Center (Optional)", text: $costCenter)
                        
                        Picker("Security Clearance", selection: $securityClearance) {
                            ForEach(SecurityClearance.allCases, id: \.self) { clearance in
                                Text(clearance.displayName).tag(clearance)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                
                FormSection(title: "Reporting Structure") {
                    VStack(spacing: 16) {
                        Button(action: { showingManagerPicker = true }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Manager")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Text(selectedManager?.fullName ?? "Select Manager")
                                        .foregroundColor(selectedManager == nil ? .secondary : .primary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        if selectedManager != nil {
                            Button("Remove Manager") {
                                selectedManager = nil
                            }
                            .foregroundColor(.red)
                            .font(.caption)
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    @ViewBuilder
    private func SkillsEditForm() -> some View {
        ScrollView {
            VStack(spacing: 20) {
                FormSection(title: "Skills") {
                    VStack(spacing: 16) {
                        HStack {
                            TextField("Add skill", text: $newSkill)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            Button("Add") {
                                addSkill()
                            }
                            .disabled(newSkill.isEmpty)
                        }
                        
                        if !skills.isEmpty {
                            FlowLayout(spacing: 8) {
                                ForEach(skills, id: \.self) { skill in
                                    SkillTag(skill: skill) {
                                        removeSkill(skill)
                                    }
                                }
                            }
                        }
                    }
                }
                
                FormSection(title: "Certifications") {
                    VStack(spacing: 16) {
                        Button("Add Certification") {
                            addCertification()
                        }
                        .foregroundColor(.blue)
                        
                        ForEach(certifications.indices, id: \.self) { index in
                            CertificationInputView(certification: $certifications[index]) {
                                certifications.remove(at: index)
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    @ViewBuilder
    private func ReviewEditForm() -> some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Review Changes")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.bottom)
                
                // Show what has changed
                if hasChanges() {
                    ChangesSummarySection()
                    
                    Divider()
                }
                
                ReviewSection(title: "Basic Information") {
                    ReviewRow(label: "Employee Number", value: employee.employeeNumber)
                    ReviewRow(label: "Name", value: "\(firstName) \(lastName)", 
                             hasChanged: firstName != employee.firstName || lastName != employee.lastName)
                    ReviewRow(label: "Email", value: email, hasChanged: email != employee.email)
                    if !phone.isEmpty {
                        ReviewRow(label: "Phone", value: phone, hasChanged: phone != (employee.phone ?? ""))
                    }
                    ReviewRow(label: "Hire Date", value: formatDate(employee.hireDate))
                    if includeBirthDate {
                        ReviewRow(label: "Birth Date", value: formatDate(birthDate), 
                                 hasChanged: includeBirthDate != (employee.birthDate != nil))
                    }
                }
                
                ReviewSection(title: "Employment") {
                    ReviewRow(label: "Department", value: department, hasChanged: department != employee.department)
                    ReviewRow(label: "Title", value: title, hasChanged: title != employee.title)
                    ReviewRow(label: "Work Location", value: workLocation.displayName, 
                             hasChanged: workLocation != employee.workLocation)
                    ReviewRow(label: "Employment Type", value: employmentType.displayName, 
                             hasChanged: employmentType != employee.employmentType)
                    if !salaryGrade.isEmpty {
                        ReviewRow(label: "Salary Grade", value: salaryGrade, 
                                 hasChanged: salaryGrade != (employee.salaryGrade ?? ""))
                    }
                    if !costCenter.isEmpty {
                        ReviewRow(label: "Cost Center", value: costCenter, 
                                 hasChanged: costCenter != (employee.costCenter ?? ""))
                    }
                    ReviewRow(label: "Security Clearance", value: securityClearance.displayName, 
                             hasChanged: securityClearance != (employee.securityClearance ?? .none))
                    if let manager = selectedManager {
                        ReviewRow(label: "Manager", value: manager.fullName, 
                                 hasChanged: selectedManager?.id != employee.manager)
                    }
                }
                
                ReviewSection(title: "Contact Information") {
                    let addressChanged = street != employee.address.street || 
                                       city != employee.address.city || 
                                       state != employee.address.state || 
                                       zipCode != employee.address.zipCode
                    ReviewRow(label: "Address", value: "\(street), \(city), \(state) \(zipCode)", 
                             hasChanged: addressChanged)
                    
                    let emergencyChanged = emergencyName != employee.emergencyContact.name || 
                                         emergencyRelationship != employee.emergencyContact.relationship
                    ReviewRow(label: "Emergency Contact", value: "\(emergencyName) (\(emergencyRelationship))", 
                             hasChanged: emergencyChanged)
                    ReviewRow(label: "Emergency Phone", value: emergencyPhone, 
                             hasChanged: emergencyPhone != employee.emergencyContact.phone)
                    if !emergencyEmail.isEmpty {
                        ReviewRow(label: "Emergency Email", value: emergencyEmail, 
                                 hasChanged: emergencyEmail != (employee.emergencyContact.email ?? ""))
                    }
                }
                
                if !skills.isEmpty {
                    ReviewSection(title: "Skills") {
                        FlowLayout(spacing: 8) {
                            ForEach(skills, id: \.self) { skill in
                                let isNew = !employee.skills.contains(skill)
                                Text(skill)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background((isNew ? Color.green : Color.blue).opacity(0.1))
                                    .foregroundColor(isNew ? .green : .blue)
                                    .cornerRadius(8)
                                    .overlay(
                                        isNew ? 
                                        Text("NEW")
                                            .font(.caption2)
                                            .foregroundColor(.green)
                                            .padding(.leading, 2) : nil,
                                        alignment: .topTrailing
                                    )
                            }
                        }
                    }
                }
                
                if !certifications.isEmpty {
                    ReviewSection(title: "Certifications") {
                        ForEach(certifications, id: \.id) { cert in
                            let isNew = !employee.certifications.contains { $0.name == cert.name }
                            HStack {
                                ReviewRow(label: cert.name, value: cert.issuingOrganization)
                                if isNew {
                                    Text("NEW")
                                        .font(.caption2)
                                        .foregroundColor(.green)
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 2)
                                        .background(Color.green.opacity(0.1))
                                        .cornerRadius(4)
                                }
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Supporting Views
    
    @ViewBuilder
    private func ProfilePhotoEditSection() -> some View {
        FormSection(title: "Profile Photo") {
            VStack(spacing: 12) {
                if let profilePhoto = profilePhoto, let url = URL(string: profilePhoto) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        ProgressView()
                    }
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                } else {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                }
                
                Button("Change Photo") {
                    showingImagePicker = true
                }
                .foregroundColor(.blue)
                
                if profilePhoto != nil {
                    Button("Remove Photo") {
                        profilePhoto = nil
                    }
                    .foregroundColor(.red)
                    .font(.caption)
                }
            }
        }
    }
    
    @ViewBuilder
    private func EditNavigationButtons() -> some View {
        HStack(spacing: 20) {
            if currentStep != .basic {
                Button("Previous") {
                    withAnimation {
                        currentStep = EditFormStep(rawValue: currentStep.rawValue - 1) ?? .basic
                    }
                }
                .buttonStyle(.bordered)
            }
            
            Spacer()
            
            if currentStep != .review {
                Button("Next") {
                    if validateCurrentStep() {
                        withAnimation {
                            currentStep = EditFormStep(rawValue: currentStep.rawValue + 1) ?? .review
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
    
    @ViewBuilder
    private func ChangesSummarySection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Summary of Changes")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                let changes = getChanges()
                if changes.isEmpty {
                    Text("No changes made")
                        .foregroundColor(.secondary)
                        .italic()
                } else {
                    ForEach(changes, id: \.self) { change in
                        HStack {
                            Image(systemName: "circle.fill")
                                .font(.caption2)
                                .foregroundColor(.blue)
                            
                            Text(change)
                                .font(.subheadline)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Helper Methods
    
    private func loadManagerSelection() {
        if let managerId = employee.manager {
            selectedManager = viewModel.employees.first { $0.id == managerId }
        }
    }
    
    private func addSkill() {
        let trimmed = newSkill.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty && !skills.contains(trimmed) {
            skills.append(trimmed)
            newSkill = ""
        }
    }
    
    private func removeSkill(_ skill: String) {
        skills.removeAll { $0 == skill }
    }
    
    private func addCertification() {
        certifications.append(CertificationInput())
    }
    
    private func validateCurrentStep() -> Bool {
        switch currentStep {
        case .basic:
            return validateBasicInfo()
        case .contact:
            return validateContactInfo()
        case .employment:
            return validateEmploymentInfo()
        case .skills:
            return true // Skills are optional
        case .review:
            return true
        }
    }
    
    private func validateBasicInfo() -> Bool {
        if firstName.isEmpty {
            showValidationError("First name is required")
            return false
        }
        
        if lastName.isEmpty {
            showValidationError("Last name is required")
            return false
        }
        
        if email.isEmpty {
            showValidationError("Email is required")
            return false
        }
        
        if !isValidEmail(email) {
            showValidationError("Please enter a valid email address")
            return false
        }
        
        return true
    }
    
    private func validateContactInfo() -> Bool {
        if street.isEmpty {
            showValidationError("Street address is required")
            return false
        }
        
        if city.isEmpty {
            showValidationError("City is required")
            return false
        }
        
        if state.isEmpty {
            showValidationError("State is required")
            return false
        }
        
        if zipCode.isEmpty {
            showValidationError("ZIP code is required")
            return false
        }
        
        if emergencyName.isEmpty {
            showValidationError("Emergency contact name is required")
            return false
        }
        
        if emergencyRelationship.isEmpty {
            showValidationError("Emergency contact relationship is required")
            return false
        }
        
        if emergencyPhone.isEmpty {
            showValidationError("Emergency contact phone is required")
            return false
        }
        
        return true
    }
    
    private func validateEmploymentInfo() -> Bool {
        if department.isEmpty {
            showValidationError("Department is required")
            return false
        }
        
        if title.isEmpty {
            showValidationError("Job title is required")
            return false
        }
        
        return true
    }
    
    private func showValidationError(_ message: String) {
        validationMessage = message
        showingValidationAlert = true
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func hasChanges() -> Bool {
        return firstName != employee.firstName ||
               lastName != employee.lastName ||
               email != employee.email ||
               phone != (employee.phone ?? "") ||
               department != employee.department ||
               title != employee.title ||
               includeBirthDate != (employee.birthDate != nil) ||
               workLocation != employee.workLocation ||
               employmentType != employee.employmentType ||
               salaryGrade != (employee.salaryGrade ?? "") ||
               costCenter != (employee.costCenter ?? "") ||
               securityClearance != (employee.securityClearance ?? .none) ||
               street != employee.address.street ||
               city != employee.address.city ||
               state != employee.address.state ||
               zipCode != employee.address.zipCode ||
               country != employee.address.country ||
               emergencyName != employee.emergencyContact.name ||
               emergencyRelationship != employee.emergencyContact.relationship ||
               emergencyPhone != employee.emergencyContact.phone ||
               emergencyEmail != (employee.emergencyContact.email ?? "") ||
               skills != employee.skills ||
               selectedManager?.id != employee.manager ||
               profilePhoto != employee.profilePhoto
    }
    
    private func getChanges() -> [String] {
        var changes: [String] = []
        
        if firstName != employee.firstName || lastName != employee.lastName {
            changes.append("Name updated")
        }
        
        if email != employee.email {
            changes.append("Email updated")
        }
        
        if phone != (employee.phone ?? "") {
            changes.append("Phone number updated")
        }
        
        if department != employee.department {
            changes.append("Department updated")
        }
        
        if title != employee.title {
            changes.append("Job title updated")
        }
        
        if workLocation != employee.workLocation {
            changes.append("Work location updated")
        }
        
        if employmentType != employee.employmentType {
            changes.append("Employment type updated")
        }
        
        if street != employee.address.street || city != employee.address.city || 
           state != employee.address.state || zipCode != employee.address.zipCode {
            changes.append("Address updated")
        }
        
        if emergencyName != employee.emergencyContact.name || 
           emergencyRelationship != employee.emergencyContact.relationship ||
           emergencyPhone != employee.emergencyContact.phone {
            changes.append("Emergency contact updated")
        }
        
        if skills != employee.skills {
            let added = skills.filter { !employee.skills.contains($0) }
            let removed = employee.skills.filter { !skills.contains($0) }
            
            if !added.isEmpty {
                changes.append("Added \(added.count) skill(s)")
            }
            if !removed.isEmpty {
                changes.append("Removed \(removed.count) skill(s)")
            }
        }
        
        if selectedManager?.id != employee.manager {
            if selectedManager == nil {
                changes.append("Manager removed")
            } else if employee.manager == nil {
                changes.append("Manager assigned")
            } else {
                changes.append("Manager changed")
            }
        }
        
        return changes
    }
    
    private func saveChanges() {
        Task {
            let address = Address(
                street: street,
                city: city,
                state: state,
                zipCode: zipCode,
                country: country
            )
            
            let emergencyContact = EmergencyContact(
                name: emergencyName,
                relationship: emergencyRelationship,
                phone: emergencyPhone,
                email: emergencyEmail.isEmpty ? nil : emergencyEmail
            )
            
            let certificationsData = certifications.compactMap { cert -> Certification? in
                guard !cert.name.isEmpty && !cert.issuingOrganization.isEmpty else { return nil }
                
                return Certification(
                    name: cert.name,
                    issuingOrganization: cert.issuingOrganization,
                    issueDate: cert.issueDate,
                    expirationDate: cert.hasExpiration ? cert.expirationDate : nil
                )
            }
            
            var updatedEmployee = employee
            updatedEmployee.firstName = firstName
            updatedEmployee.lastName = lastName
            updatedEmployee.email = email
            updatedEmployee.phone = phone.isEmpty ? nil : phone
            updatedEmployee.department = department
            updatedEmployee.title = title
            updatedEmployee.birthDate = includeBirthDate ? birthDate : nil
            updatedEmployee.address = address
            updatedEmployee.emergencyContact = emergencyContact
            updatedEmployee.workLocation = workLocation
            updatedEmployee.employmentType = employmentType
            updatedEmployee.salaryGrade = salaryGrade.isEmpty ? nil : salaryGrade
            updatedEmployee.costCenter = costCenter.isEmpty ? nil : costCenter
            updatedEmployee.manager = selectedManager?.id
            updatedEmployee.skills = skills
            updatedEmployee.certifications = certificationsData
            updatedEmployee.profilePhoto = profilePhoto
            updatedEmployee.securityClearance = securityClearance == .none ? nil : securityClearance
            
            await viewModel.updateEmployee(updatedEmployee)
            dismiss()
        }
    }
}

// MARK: - Supporting Types

enum EditFormStep: Int, CaseIterable {
    case basic = 0
    case contact = 1
    case employment = 2
    case skills = 3
    case review = 4
    
    var title: String {
        switch self {
        case .basic: return "Basic"
        case .contact: return "Contact"
        case .employment: return "Employment"
        case .skills: return "Skills"
        case .review: return "Review"
        }
    }
}

struct EditProgressIndicator: View {
    let currentStep: EditFormStep
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(EditFormStep.allCases, id: \.self) { step in
                VStack(spacing: 8) {
                    Circle()
                        .fill(step.rawValue <= currentStep.rawValue ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: 20, height: 20)
                        .overlay(
                            Text("\(step.rawValue + 1)")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(step.rawValue <= currentStep.rawValue ? .white : .gray)
                        )
                    
                    Text(step.title)
                        .font(.caption)
                        .foregroundColor(step.rawValue <= currentStep.rawValue ? .blue : .gray)
                }
                
                if step != EditFormStep.allCases.last {
                    Rectangle()
                        .fill(step.rawValue < currentStep.rawValue ? Color.blue : Color.gray.opacity(0.3))
                        .frame(height: 2)
                        .padding(.horizontal, 8)
                }
            }
        }
        .padding()
    }
}

struct ReviewRow: View {
    let label: String
    let value: String
    let hasChanged: Bool
    
    init(label: String, value: String, hasChanged: Bool = false) {
        self.label = label
        self.value = value
        self.hasChanged = hasChanged
    }
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            
            Spacer()
            
            HStack(spacing: 4) {
                Text(value)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.trailing)
                    .foregroundColor(hasChanged ? .blue : .primary)
                
                if hasChanged {
                    Image(systemName: "circle.fill")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
            }
        }
        .font(.subheadline)
    }
}

#Preview {
    EmployeeEditView(
        employee: Employee(
            employeeNumber: "EMP001",
            firstName: "John",
            lastName: "Doe",
            email: "john.doe@company.com",
            department: "Engineering",
            title: "Senior Developer",
            hireDate: Date(),
            address: Address(street: "123 Main St", city: "San Francisco", state: "CA", zipCode: "94105"),
            emergencyContact: EmergencyContact(name: "Jane Doe", relationship: "Spouse", phone: "555-0123"),
            workLocation: .office,
            employmentType: .fullTime
        ),
        viewModel: EmployeeViewModel()
    )
}
