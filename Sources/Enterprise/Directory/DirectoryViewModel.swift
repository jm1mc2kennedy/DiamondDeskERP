//
//  DirectoryViewModel.swift
//  DiamondDeskERP
//
//  Created by J.Michael McDermott on 7/20/25.
//

import Foundation
import Combine

@MainActor
class DirectoryViewModel: ObservableObject {
    @Published var employees: [Employee] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var service = DirectoryService.shared

    func loadEmployees(criteria: DirectorySearchCriteria = DirectorySearchCriteria()) async {
        isLoading = true
        errorMessage = nil
        do {
            let result = try await service.fetchEmployees(criteria: criteria)
            employees = result
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    /// Save new employee (placeholder for building Employee and calling service.saveEmployee)
    /// Save new employee and reload list
    func saveNewEmployee(
        firstName: String,
        lastName: String,
        jobTitle: String,
        department: Department?,
        email: String,
        mobilePhone: String?,
        profileImageURL: String?
    ) async {
        isLoading = true
        defer { isLoading = false }
        errorMessage = nil
        do {
            // Build minimal Employee and save
            guard let dept = department else {
                throw NSError(domain: "DirectoryViewModel", code: 0, userInfo: [NSLocalizedDescriptionKey: "Department is required"])
            }
            let personalInfo = PersonalInfo(
                firstName: firstName,
                lastName: lastName,
                middleName: nil,
                preferredName: nil,
                profileImageURL: nil,
                dateOfBirth: nil,
                personalStatement: nil,
                pronouns: nil,
                languages: []
            )
            let contactInfo = ContactInfo(
                workEmail: email,
                personalEmail: nil,
                workPhone: nil,
                mobilePhone: nil,
                emergencyContact: nil,
                workAddress: nil,
                homeAddress: nil,
                socialProfiles: []
            )
            let location = WorkLocation(type: .office, officeName: nil, address: nil, timeZone: TimeZone.current.identifier, coordinates: nil)
            let orgInfo = OrganizationalInfo(
                department: dept,
                jobTitle: jobTitle,
                level: .associate,
                managerEmployeeId: nil,
                directReports: [],
                costCenter: nil,
                location: location,
                employmentType: .fullTime,
                startDate: Date(),
                endDate: nil,
                probationEndDate: nil,
                workSchedule: WorkSchedule(
                    type: .standard,
                    hoursPerWeek: 40,
                    workDays: [.monday, .tuesday, .wednesday, .thursday, .friday],
                    startTime: nil,
                    endTime: nil,
                    flexibleHours: false,
                    coreHours: nil
                )
            )
            let mentoringAvailability = MentoringAvailability(hoursPerMonth: 0, preferredMeetingType: .flexible, timeZones: [], languages: [])
            let mentoringInfo = MentoringInfo(isActiveMentor: false, isActiveMentee: false, mentors: [], mentees: [], mentoringAreas: [], availability: mentoringAvailability, experience: .none)
            let professionalInfo = ProfessionalInfo(skills: [], certifications: [], education: [], workExperience: [], projects: [], performanceReviews: [], goals: [], mentoring: mentoringInfo)
            let securitySettings = SecuritySettings(twoFactorEnabled: false, biometricEnabled: false, sessionTimeout: 30, passwordLastChanged: nil, securityQuestions: [], trustedDevices: [], allowedIPRanges: [])
            let notificationSettings = NotificationSettings(emailNotifications: true, pushNotifications: true, smsNotifications: false, digestFrequency: .daily, notificationTypes: Dictionary(uniqueKeysWithValues: NotificationType.allCases.map { ($0, true) }), quietHours: nil)
            let systemInfo = SystemInfo(cloudKitRecordId: nil, lastLoginDate: nil, accountStatus: .active, accessLevel: .read, deviceInfo: [], loginHistory: [], securitySettings: securitySettings, notificationSettings: notificationSettings)
            let permissions = EmployeePermissions(canViewDirectory: true, canEditOwnProfile: true, canAssignTasks: false, canViewPerformanceTargets: false, canManageProjects: false)
            let newEmployee = Employee(
                employeeId: UUID().uuidString,
                personalInfo: personalInfo,
                contactInfo: contactInfo,
                organizationalInfo: orgInfo,
                professionalInfo: professionalInfo,
                systemInfo: systemInfo,
                permissions: permissions
            )
            try await DirectoryService.shared.saveEmployee(newEmployee)
            await loadEmployees()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
