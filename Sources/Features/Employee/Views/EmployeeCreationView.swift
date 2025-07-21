import SwiftUI

struct EmployeeCreationView: View {
    @ObservedObject var viewModel: EmployeeViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var employeeNumber: String = ""
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var email: String = ""
    @State private var phone: String = ""
    @State private var department: String = ""
    @State private var title: String = ""
    @State private var hireDate: Date = Date()
    @State private var birthDate: Date = Date()
    @State private var includeBirthDate: Bool = false
    @State private var workLocation: WorkLocation = .office
    @State private var employmentType: EmploymentType = .fullTime
    @State private var salaryGrade: String = ""
    @State private var costCenter: String = ""
    @State private var securityClearance: SecurityClearance = .none
    
    // Address fields
    @State private var street: String = ""
    @State private var city: String = ""
    @State private var state: String = ""
    @State private var zipCode: String = ""
    @State private var country: String = "United States"
    
    // Emergency contact fields
    @State private var emergencyName: String = ""
    @State private var emergencyRelationship: String = ""
    @State private var emergencyPhone: String = ""
    @State private var emergencyEmail: String = ""
    
    // Skills and certifications
    @State private var skills: [String] = []
    @State private var newSkill: String = ""
    @State private var certifications: [CertificationInput] = []
    
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
    @State private var currentStep: FormStep = .basic
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress indicator
                ProgressIndicator(currentStep: currentStep)
                
                // Form content
                TabView(selection: $currentStep) {
                    BasicInfoForm()
                        .tag(FormStep.basic)
                    
                    ContactInfoForm()
                        .tag(FormStep.contact)
                    
                    EmploymentInfoForm()
                        .tag(FormStep.employment)
                    
                    SkillsForm()
                        .tag(FormStep.skills)
                    
                    ReviewForm()
                        .tag(FormStep.review)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                
                // Navigation buttons
                NavigationButtons()
            }
            .navigationTitle("New Employee")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if currentStep == .review {
                        Button("Create") {
                            createEmployee()
                        }
                        .disabled(viewModel.isLoading)
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
                generateEmployeeNumber()
            }
        }
    }
    
    // MARK: - Form Steps
    
    @ViewBuilder
    private func BasicInfoForm() -> some View {
        ScrollView {
            VStack(spacing: 20) {
                FormSection(title: "Basic Information") {
                    VStack(spacing: 16) {
                        FormField(title: "Employee Number", text: $employeeNumber)
                            .disabled(true)
                        
                        FormField(title: "First Name", text: $firstName, isRequired: true)
                        
                        FormField(title: "Last Name", text: $lastName, isRequired: true)
                        
                        FormField(title: "Email", text: $email, isRequired: true)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                        
                        FormField(title: "Phone", text: $phone)
                            .keyboardType(.phonePad)
                        
                        DateField(title: "Hire Date", date: $hireDate, isRequired: true)
                        
                        Toggle("Include Birth Date", isOn: $includeBirthDate)
                        
                        if includeBirthDate {
                            DateField(title: "Birth Date", date: $birthDate)
                        }
                    }
                }
                
                ProfilePhotoSection()
            }
            .padding()
        }
    }
    
    @ViewBuilder
    private func ContactInfoForm() -> some View {
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
    private func EmploymentInfoForm() -> some View {
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
    private func SkillsForm() -> some View {
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
    private func ReviewForm() -> some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Review Employee Information")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.bottom)
                
                ReviewSection(title: "Basic Information") {
                    ReviewRow(label: "Employee Number", value: employeeNumber)
                    ReviewRow(label: "Name", value: "\(firstName) \(lastName)")
                    ReviewRow(label: "Email", value: email)
                    if !phone.isEmpty {
                        ReviewRow(label: "Phone", value: phone)
                    }
                    ReviewRow(label: "Hire Date", value: formatDate(hireDate))
                    if includeBirthDate {
                        ReviewRow(label: "Birth Date", value: formatDate(birthDate))
                    }
                }
                
                ReviewSection(title: "Employment") {
                    ReviewRow(label: "Department", value: department)
                    ReviewRow(label: "Title", value: title)
                    ReviewRow(label: "Work Location", value: workLocation.displayName)
                    ReviewRow(label: "Employment Type", value: employmentType.displayName)
                    if !salaryGrade.isEmpty {
                        ReviewRow(label: "Salary Grade", value: salaryGrade)
                    }
                    if !costCenter.isEmpty {
                        ReviewRow(label: "Cost Center", value: costCenter)
                    }
                    ReviewRow(label: "Security Clearance", value: securityClearance.displayName)
                    if let manager = selectedManager {
                        ReviewRow(label: "Manager", value: manager.fullName)
                    }
                }
                
                ReviewSection(title: "Contact Information") {
                    ReviewRow(label: "Address", value: "\(street), \(city), \(state) \(zipCode)")
                    ReviewRow(label: "Emergency Contact", value: "\(emergencyName) (\(emergencyRelationship))")
                    ReviewRow(label: "Emergency Phone", value: emergencyPhone)
                    if !emergencyEmail.isEmpty {
                        ReviewRow(label: "Emergency Email", value: emergencyEmail)
                    }
                }
                
                if !skills.isEmpty {
                    ReviewSection(title: "Skills") {
                        FlowLayout(spacing: 8) {
                            ForEach(skills, id: \.self) { skill in
                                Text(skill)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundColor(.blue)
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
                
                if !certifications.isEmpty {
                    ReviewSection(title: "Certifications") {
                        ForEach(certifications, id: \.id) { cert in
                            ReviewRow(label: cert.name, value: cert.issuingOrganization)
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Supporting Views
    
    @ViewBuilder
    private func ProfilePhotoSection() -> some View {
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
                
                Button("Select Photo") {
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
    private func NavigationButtons() -> some View {
        HStack(spacing: 20) {
            if currentStep != .basic {
                Button("Previous") {
                    withAnimation {
                        currentStep = FormStep(rawValue: currentStep.rawValue - 1) ?? .basic
                    }
                }
                .buttonStyle(.bordered)
            }
            
            Spacer()
            
            if currentStep != .review {
                Button("Next") {
                    if validateCurrentStep() {
                        withAnimation {
                            currentStep = FormStep(rawValue: currentStep.rawValue + 1) ?? .review
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
    
    // MARK: - Helper Methods
    
    private func generateEmployeeNumber() {
        // Generate a unique employee number
        let existingNumbers = viewModel.employees.map { $0.employeeNumber }
        var number = 1
        
        while existingNumbers.contains("EMP\(String(format: "%03d", number))") {
            number += 1
        }
        
        employeeNumber = "EMP\(String(format: "%03d", number))"
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
    
    private func createEmployee() {
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
            
            let employee = Employee(
                employeeNumber: employeeNumber,
                firstName: firstName,
                lastName: lastName,
                email: email,
                phone: phone.isEmpty ? nil : phone,
                department: department,
                title: title,
                hireDate: hireDate,
                birthDate: includeBirthDate ? birthDate : nil,
                address: address,
                emergencyContact: emergencyContact,
                workLocation: workLocation,
                employmentType: employmentType,
                salaryGrade: salaryGrade.isEmpty ? nil : salaryGrade,
                costCenter: costCenter.isEmpty ? nil : costCenter,
                manager: selectedManager?.id,
                skills: skills,
                certifications: certificationsData,
                profilePhoto: profilePhoto,
                securityClearance: securityClearance == .none ? nil : securityClearance
            )
            
            await viewModel.createEmployee(employee)
            dismiss()
        }
    }
}

// MARK: - Supporting Types and Views

enum FormStep: Int, CaseIterable {
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

struct ProgressIndicator: View {
    let currentStep: FormStep
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(FormStep.allCases, id: \.self) { step in
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
                
                if step != FormStep.allCases.last {
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

struct FormSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            
            content
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 1)
    }
}

struct FormField: View {
    let title: String
    @Binding var text: String
    let isRequired: Bool
    
    init(title: String, text: Binding<String>, isRequired: Bool = false) {
        self.title = title
        self._text = text
        self.isRequired = isRequired
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if isRequired {
                    Text("*")
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            
            TextField(title, text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
}

struct DateField: View {
    let title: String
    @Binding var date: Date
    let isRequired: Bool
    
    init(title: String, date: Binding<Date>, isRequired: Bool = false) {
        self.title = title
        self._date = date
        self.isRequired = isRequired
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if isRequired {
                    Text("*")
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            
            DatePicker("", selection: $date, displayedComponents: .date)
                .datePickerStyle(CompactDatePickerStyle())
                .labelsHidden()
        }
    }
}

struct SkillTag: View {
    let skill: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(skill)
                .font(.caption)
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.blue.opacity(0.1))
        .foregroundColor(.blue)
        .cornerRadius(8)
    }
}

struct CertificationInput: Identifiable {
    let id = UUID()
    var name: String = ""
    var issuingOrganization: String = ""
    var issueDate: Date = Date()
    var hasExpiration: Bool = false
    var expirationDate: Date = Date()
}

struct CertificationInputView: View {
    @Binding var certification: CertificationInput
    let onRemove: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Certification")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Button(action: onRemove) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
            }
            
            FormField(title: "Certification Name", text: $certification.name)
            FormField(title: "Issuing Organization", text: $certification.issuingOrganization)
            DateField(title: "Issue Date", date: $certification.issueDate)
            
            Toggle("Has Expiration Date", isOn: $certification.hasExpiration)
            
            if certification.hasExpiration {
                DateField(title: "Expiration Date", date: $certification.expirationDate)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct ReviewSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            
            content
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 1)
    }
}

struct ReviewRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .fontWeight(.medium)
                .multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
    }
}

struct ManagerPickerView: View {
    @Binding var selectedManager: Employee?
    let employees: [Employee]
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    
    var filteredEmployees: [Employee] {
        if searchText.isEmpty {
            return employees
        } else {
            return employees.filter { employee in
                employee.fullName.localizedCaseInsensitiveContains(searchText) ||
                employee.department.localizedCaseInsensitiveContains(searchText) ||
                employee.title.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredEmployees, id: \.id) { employee in
                    Button(action: {
                        selectedManager = employee
                        dismiss()
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(employee.fullName)
                                    .fontWeight(.medium)
                                
                                Text(employee.title)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text(employee.department)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if selectedManager?.id == employee.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .searchable(text: $searchText, prompt: "Search employees...")
            .navigationTitle("Select Manager")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Clear") {
                        selectedManager = nil
                        dismiss()
                    }
                    .disabled(selectedManager == nil)
                }
            }
        }
    }
}

#Preview {
    EmployeeCreationView(viewModel: EmployeeViewModel())
}
