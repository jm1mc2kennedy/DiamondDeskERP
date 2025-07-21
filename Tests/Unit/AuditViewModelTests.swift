//
//  AuditViewModelTests.swift
//  DiamondDeskERPTests
//
//  Created by GitHub Copilot on 1/2/2025.
//

import CloudKit
import Combine

@MainActor
struct AuditViewModelTests {
    
    // MARK: - Mock Repository Implementations
    
    class MockAuditTemplateRepository: AuditTemplateRepositoryProtocol {
        var mockTemplates: [AuditTemplate] = []
        var shouldThrowError = false
        var fetchAllCallCount = 0
        var saveCallCount = 0
        
        func fetchAll() async throws -> [AuditTemplate] {
            fetchAllCallCount += 1
            if shouldThrowError { throw CKError(.networkFailure) }
            return mockTemplates
        }
        
        func fetchActive() async throws -> [AuditTemplate] {
            if shouldThrowError { throw CKError(.networkFailure) }
            return mockTemplates.filter { $0.isActive }
        }
        
        func fetchByCategory(_ category: String) async throws -> [AuditTemplate] {
            if shouldThrowError { throw CKError(.networkFailure) }
            return mockTemplates.filter { $0.category == category }
        }
        
        func save(_ template: AuditTemplate) async throws -> AuditTemplate {
            saveCallCount += 1
            if shouldThrowError { throw CKError(.quotaExceeded) }
            mockTemplates.removeAll { $0.id == template.id }
            mockTemplates.append(template)
            return template
        }
        
        func delete(_ template: AuditTemplate) async throws {
            if shouldThrowError { throw CKError(.networkFailure) }
            mockTemplates.removeAll { $0.id == template.id }
        }
        
        func publish(_ template: AuditTemplate) async throws -> AuditTemplate {
            if shouldThrowError { throw CKError(.quotaExceeded) }
            var updatedTemplate = template
            updatedTemplate.status = .published
            updatedTemplate.publishedAt = Date()
            mockTemplates.removeAll { $0.id == template.id }
            mockTemplates.append(updatedTemplate)
            return updatedTemplate
        }
        
        func archive(_ template: AuditTemplate) async throws -> AuditTemplate {
            if shouldThrowError { throw CKError(.quotaExceeded) }
            var updatedTemplate = template
            updatedTemplate.status = .archived
            mockTemplates.removeAll { $0.id == template.id }
            mockTemplates.append(updatedTemplate)
            return updatedTemplate
        }
    }
    
    class MockAuditRepository: AuditRepositoryProtocol {
        var mockAudits: [Audit] = []
        var shouldThrowError = false
        var fetchAllCallCount = 0
        var saveCallCount = 0
        
        func fetchAll() async throws -> [Audit] {
            fetchAllCallCount += 1
            if shouldThrowError { throw CKError(.networkFailure) }
            return mockAudits
        }
        
        func fetchByStatus(_ status: Audit.AuditStatus) async throws -> [Audit] {
            if shouldThrowError { throw CKError(.networkFailure) }
            return mockAudits.filter { $0.status == status }
        }
        
        func fetchByTemplate(_ templateId: CKRecord.ID) async throws -> [Audit] {
            if shouldThrowError { throw CKError(.networkFailure) }
            return mockAudits.filter { $0.templateRef.recordID == templateId }
        }
        
        func fetchByStore(_ storeCode: String) async throws -> [Audit] {
            if shouldThrowError { throw CKError(.networkFailure) }
            return mockAudits.filter { $0.storeCode == storeCode }
        }
        
        func fetchByAuditor(_ auditorId: CKRecord.Reference) async throws -> [Audit] {
            if shouldThrowError { throw CKError(.networkFailure) }
            return mockAudits.filter { $0.assignedAuditorRef?.recordID == auditorId.recordID }
        }
        
        func fetchByDateRange(_ startDate: Date, _ endDate: Date) async throws -> [Audit] {
            if shouldThrowError { throw CKError(.networkFailure) }
            return mockAudits.filter { audit in
                audit.scheduledDate >= startDate && audit.scheduledDate <= endDate
            }
        }
        
        func save(_ audit: Audit) async throws -> Audit {
            saveCallCount += 1
            if shouldThrowError { throw CKError(.quotaExceeded) }
            mockAudits.removeAll { $0.id == audit.id }
            mockAudits.append(audit)
            return audit
        }
        
        func delete(_ audit: Audit) async throws {
            if shouldThrowError { throw CKError(.networkFailure) }
            mockAudits.removeAll { $0.id == audit.id }
        }
        
        func addResponse(_ audit: Audit, response: Audit.QuestionResponse) async throws -> Audit {
            if shouldThrowError { throw CKError(.quotaExceeded) }
            var updatedAudit = audit
            updatedAudit.responses.append(response)
            mockAudits.removeAll { $0.id == audit.id }
            mockAudits.append(updatedAudit)
            return updatedAudit
        }
        
        func complete(_ audit: Audit, score: Double) async throws -> Audit {
            if shouldThrowError { throw CKError(.quotaExceeded) }
            var updatedAudit = audit
            updatedAudit.status = .completed
            updatedAudit.completedAt = Date()
            updatedAudit.finalScore = score
            mockAudits.removeAll { $0.id == audit.id }
            mockAudits.append(updatedAudit)
            return updatedAudit
        }
        
        func submit(_ audit: Audit) async throws -> Audit {
            if shouldThrowError { throw CKError(.quotaExceeded) }
            var updatedAudit = audit
            updatedAudit.status = .submitted
            updatedAudit.submittedAt = Date()
            mockAudits.removeAll { $0.id == audit.id }
            mockAudits.append(updatedAudit)
            return updatedAudit
        }
    }
    
    // MARK: - AuditTemplateViewModel Tests
    
    @Test("AuditTemplateViewModel initializes with empty state")
    func testAuditTemplateViewModelInitialization() async throws {
        let mockRepository = MockAuditTemplateRepository()
        let viewModel = AuditTemplateViewModel(repository: mockRepository)
        
        #expect(viewModel.templates.isEmpty)
        #expect(viewModel.selectedTemplate == nil)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.error == nil)
        #expect(viewModel.searchText.isEmpty)
    }
    
    @Test("AuditTemplateViewModel loads templates successfully")
    func testAuditTemplateViewModelLoadTemplates() async throws {
        let mockRepository = MockAuditTemplateRepository()
        let template = AuditTemplate(
            id: CKRecord.ID(recordName: "template-1"),
            templateName: "Safety Audit",
            category: "Safety",
            description: "Safety audit template",
            sections: [],
            version: "1.0",
            status: .published,
            isActive: true,
            createdByRef: CKRecord.Reference(recordID: CKRecord.ID(recordName: "user-1"), action: .none),
            createdAt: Date(),
            updatedAt: Date(),
            publishedAt: Date()
        )
        
        mockRepository.mockTemplates = [template]
        let viewModel = AuditTemplateViewModel(repository: mockRepository)
        
        viewModel.loadTemplates()
        
        // Wait for async operation
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        #expect(mockRepository.fetchAllCallCount == 1)
        #expect(viewModel.templates.count == 1)
        #expect(viewModel.templates.first?.templateName == "Safety Audit")
        #expect(viewModel.isLoading == false)
    }
    
    @Test("AuditTemplateViewModel filters templates by search text")
    func testAuditTemplateViewModelFiltering() async throws {
        let mockRepository = MockAuditTemplateRepository()
        
        let safetyTemplate = AuditTemplate(
            id: CKRecord.ID(recordName: "safety-template"),
            templateName: "Safety Audit",
            category: "Safety",
            description: "Safety audit template",
            sections: [],
            version: "1.0",
            status: .published,
            isActive: true,
            createdByRef: CKRecord.Reference(recordID: CKRecord.ID(recordName: "user-1"), action: .none),
            createdAt: Date(),
            updatedAt: Date(),
            publishedAt: Date()
        )
        
        let qualityTemplate = AuditTemplate(
            id: CKRecord.ID(recordName: "quality-template"),
            templateName: "Quality Control",
            category: "Quality",
            description: "Quality control template",
            sections: [],
            version: "1.0",
            status: .published,
            isActive: true,
            createdByRef: CKRecord.Reference(recordID: CKRecord.ID(recordName: "user-1"), action: .none),
            createdAt: Date(),
            updatedAt: Date(),
            publishedAt: Date()
        )
        
        let viewModel = AuditTemplateViewModel(repository: mockRepository)
        viewModel.templates = [safetyTemplate, qualityTemplate]
        
        // Test search filtering
        viewModel.searchText = "safety"
        let filteredBySafety = viewModel.filteredTemplates
        #expect(filteredBySafety.count == 1)
        #expect(filteredBySafety.first?.templateName == "Safety Audit")
        
        // Test category filtering
        viewModel.searchText = ""
        viewModel.selectedCategory = "Quality"
        let filteredByCategory = viewModel.filteredTemplates
        #expect(filteredByCategory.count == 1)
        #expect(filteredByCategory.first?.templateName == "Quality Control")
    }
    
    @Test("AuditTemplateViewModel groups templates by category")
    func testAuditTemplateViewModelGrouping() async throws {
        let mockRepository = MockAuditTemplateRepository()
        
        let safetyTemplate = AuditTemplate(
            id: CKRecord.ID(recordName: "safety-template"),
            templateName: "Safety Audit",
            category: "Safety",
            description: "Safety audit template",
            sections: [],
            version: "1.0",
            status: .published,
            isActive: true,
            createdByRef: CKRecord.Reference(recordID: CKRecord.ID(recordName: "user-1"), action: .none),
            createdAt: Date(),
            updatedAt: Date(),
            publishedAt: Date()
        )
        
        let qualityTemplate = AuditTemplate(
            id: CKRecord.ID(recordName: "quality-template"),
            templateName: "Quality Control",
            category: "Quality",
            description: "Quality control template",
            sections: [],
            version: "1.0",
            status: .published,
            isActive: true,
            createdByRef: CKRecord.Reference(recordID: CKRecord.ID(recordName: "user-1"), action: .none),
            createdAt: Date(),
            updatedAt: Date(),
            publishedAt: Date()
        )
        
        let viewModel = AuditTemplateViewModel(repository: mockRepository)
        viewModel.templates = [safetyTemplate, qualityTemplate]
        
        let templatesByCategory = viewModel.templatesByCategory
        
        #expect(templatesByCategory.keys.count == 2)
        #expect(templatesByCategory["Safety"]?.count == 1)
        #expect(templatesByCategory["Quality"]?.count == 1)
        #expect(templatesByCategory["Safety"]?.first?.templateName == "Safety Audit")
    }
    
    @Test("AuditTemplateViewModel publishes template successfully")
    func testAuditTemplateViewModelPublishTemplate() async throws {
        let mockRepository = MockAuditTemplateRepository()
        
        let draftTemplate = AuditTemplate(
            id: CKRecord.ID(recordName: "draft-template"),
            templateName: "Draft Template",
            category: "Safety",
            description: "Draft template",
            sections: [],
            version: "1.0",
            status: .draft,
            isActive: false,
            createdByRef: CKRecord.Reference(recordID: CKRecord.ID(recordName: "user-1"), action: .none),
            createdAt: Date(),
            updatedAt: Date(),
            publishedAt: nil
        )
        
        mockRepository.mockTemplates = [draftTemplate]
        let viewModel = AuditTemplateViewModel(repository: mockRepository)
        viewModel.templates = [draftTemplate]
        
        viewModel.publishTemplate(draftTemplate)
        
        // Wait for async operation
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        #expect(viewModel.templates.first?.status == .published)
        #expect(viewModel.templates.first?.publishedAt != nil)
    }
    
    @Test("AuditTemplateViewModel handles loading errors")
    func testAuditTemplateViewModelLoadingError() async throws {
        let mockRepository = MockAuditTemplateRepository()
        mockRepository.shouldThrowError = true
        
        let viewModel = AuditTemplateViewModel(repository: mockRepository)
        
        viewModel.loadTemplates()
        
        // Wait for async operation
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        #expect(viewModel.error != nil)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.templates.isEmpty)
    }
    
    // MARK: - AuditViewModel Tests
    
    @Test("AuditViewModel initializes with empty state")
    func testAuditViewModelInitialization() async throws {
        let mockRepository = MockAuditRepository()
        let viewModel = AuditViewModel(repository: mockRepository)
        
        #expect(viewModel.audits.isEmpty)
        #expect(viewModel.selectedAudit == nil)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.error == nil)
        #expect(viewModel.searchText.isEmpty)
    }
    
    @Test("AuditViewModel loads audits successfully")
    func testAuditViewModelLoadAudits() async throws {
        let mockRepository = MockAuditRepository()
        
        let audit = Audit(
            id: CKRecord.ID(recordName: "audit-1"),
            templateRef: CKRecord.Reference(recordID: CKRecord.ID(recordName: "template-1"), action: .none),
            storeCode: "001",
            status: .pending,
            scheduledDate: Date(),
            assignedAuditorRef: nil,
            responses: [],
            createdByRef: CKRecord.Reference(recordID: CKRecord.ID(recordName: "user-1"), action: .none),
            createdAt: Date(),
            updatedAt: Date()
        )
        
        mockRepository.mockAudits = [audit]
        let viewModel = AuditViewModel(repository: mockRepository)
        
        viewModel.loadAudits()
        
        // Wait for async operation
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        #expect(mockRepository.fetchAllCallCount == 1)
        #expect(viewModel.audits.count == 1)
        #expect(viewModel.audits.first?.storeCode == "001")
        #expect(viewModel.isLoading == false)
    }
    
    @Test("AuditViewModel filters audits by status")
    func testAuditViewModelFilterByStatus() async throws {
        let mockRepository = MockAuditRepository()
        
        let pendingAudit = Audit(
            id: CKRecord.ID(recordName: "pending-audit"),
            templateRef: CKRecord.Reference(recordID: CKRecord.ID(recordName: "template-1"), action: .none),
            storeCode: "001",
            status: .pending,
            scheduledDate: Date(),
            assignedAuditorRef: nil,
            responses: [],
            createdByRef: CKRecord.Reference(recordID: CKRecord.ID(recordName: "user-1"), action: .none),
            createdAt: Date(),
            updatedAt: Date()
        )
        
        let completedAudit = Audit(
            id: CKRecord.ID(recordName: "completed-audit"),
            templateRef: CKRecord.Reference(recordID: CKRecord.ID(recordName: "template-1"), action: .none),
            storeCode: "002",
            status: .completed,
            scheduledDate: Date(),
            assignedAuditorRef: nil,
            responses: [],
            createdByRef: CKRecord.Reference(recordID: CKRecord.ID(recordName: "user-1"), action: .none),
            createdAt: Date(),
            updatedAt: Date(),
            completedAt: Date(),
            finalScore: 85.0
        )
        
        let viewModel = AuditViewModel(repository: mockRepository)
        viewModel.audits = [pendingAudit, completedAudit]
        
        // Test status filtering
        viewModel.selectedStatus = .pending
        let filteredAudits = viewModel.filteredAudits
        
        #expect(filteredAudits.count == 1)
        #expect(filteredAudits.first?.status == .pending)
        #expect(filteredAudits.first?.storeCode == "001")
    }
    
    @Test("AuditViewModel calculates completion rate correctly")
    func testAuditViewModelCompletionRate() async throws {
        let mockRepository = MockAuditRepository()
        
        let pendingAudit = Audit(
            id: CKRecord.ID(recordName: "pending-audit"),
            templateRef: CKRecord.Reference(recordID: CKRecord.ID(recordName: "template-1"), action: .none),
            storeCode: "001",
            status: .pending,
            scheduledDate: Date(),
            assignedAuditorRef: nil,
            responses: [],
            createdByRef: CKRecord.Reference(recordID: CKRecord.ID(recordName: "user-1"), action: .none),
            createdAt: Date(),
            updatedAt: Date()
        )
        
        let completedAudit1 = Audit(
            id: CKRecord.ID(recordName: "completed-audit-1"),
            templateRef: CKRecord.Reference(recordID: CKRecord.ID(recordName: "template-1"), action: .none),
            storeCode: "002",
            status: .completed,
            scheduledDate: Date(),
            assignedAuditorRef: nil,
            responses: [],
            createdByRef: CKRecord.Reference(recordID: CKRecord.ID(recordName: "user-1"), action: .none),
            createdAt: Date(),
            updatedAt: Date(),
            completedAt: Date(),
            finalScore: 85.0
        )
        
        let completedAudit2 = Audit(
            id: CKRecord.ID(recordName: "completed-audit-2"),
            templateRef: CKRecord.Reference(recordID: CKRecord.ID(recordName: "template-1"), action: .none),
            storeCode: "003",
            status: .completed,
            scheduledDate: Date(),
            assignedAuditorRef: nil,
            responses: [],
            createdByRef: CKRecord.Reference(recordID: CKRecord.ID(recordName: "user-1"), action: .none),
            createdAt: Date(),
            updatedAt: Date(),
            completedAt: Date(),
            finalScore: 92.0
        )
        
        let viewModel = AuditViewModel(repository: mockRepository)
        viewModel.audits = [pendingAudit, completedAudit1, completedAudit2]
        
        let completionRate = viewModel.completionRate
        
        #expect(completionRate == 66.67) // 2 out of 3 completed, rounded to 2 decimal places
    }
    
    @Test("AuditViewModel adds response to audit")
    func testAuditViewModelAddResponse() async throws {
        let mockRepository = MockAuditRepository()
        
        let audit = Audit(
            id: CKRecord.ID(recordName: "audit-1"),
            templateRef: CKRecord.Reference(recordID: CKRecord.ID(recordName: "template-1"), action: .none),
            storeCode: "001",
            status: .inProgress,
            scheduledDate: Date(),
            assignedAuditorRef: CKRecord.Reference(recordID: CKRecord.ID(recordName: "auditor-1"), action: .none),
            responses: [],
            createdByRef: CKRecord.Reference(recordID: CKRecord.ID(recordName: "user-1"), action: .none),
            createdAt: Date(),
            updatedAt: Date()
        )
        
        let response = Audit.QuestionResponse(
            questionId: "q1",
            answer: "Yes",
            score: 10,
            notes: "Good compliance",
            photosData: [],
            timestamp: Date()
        )
        
        mockRepository.mockAudits = [audit]
        let viewModel = AuditViewModel(repository: mockRepository)
        viewModel.audits = [audit]
        
        viewModel.addResponse(to: audit, response: response)
        
        // Wait for async operation
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        #expect(viewModel.audits.first?.responses.count == 1)
        #expect(viewModel.audits.first?.responses.first?.questionId == "q1")
    }
    
    @Test("AuditViewModel completes audit with score")
    func testAuditViewModelCompleteAudit() async throws {
        let mockRepository = MockAuditRepository()
        
        let audit = Audit(
            id: CKRecord.ID(recordName: "audit-1"),
            templateRef: CKRecord.Reference(recordID: CKRecord.ID(recordName: "template-1"), action: .none),
            storeCode: "001",
            status: .inProgress,
            scheduledDate: Date(),
            assignedAuditorRef: CKRecord.Reference(recordID: CKRecord.ID(recordName: "auditor-1"), action: .none),
            responses: [],
            createdByRef: CKRecord.Reference(recordID: CKRecord.ID(recordName: "user-1"), action: .none),
            createdAt: Date(),
            updatedAt: Date()
        )
        
        mockRepository.mockAudits = [audit]
        let viewModel = AuditViewModel(repository: mockRepository)
        viewModel.audits = [audit]
        
        viewModel.completeAudit(audit, score: 88.5)
        
        // Wait for async operation
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        #expect(viewModel.audits.first?.status == .completed)
        #expect(viewModel.audits.first?.finalScore == 88.5)
        #expect(viewModel.audits.first?.completedAt != nil)
    }
    
    @Test("AuditViewModel handles audit errors")
    func testAuditViewModelAuditError() async throws {
        let mockRepository = MockAuditRepository()
        mockRepository.shouldThrowError = true
        
        let viewModel = AuditViewModel(repository: mockRepository)
        
        viewModel.loadAudits()
        
        // Wait for async operation
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        #expect(viewModel.error != nil)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.audits.isEmpty)
    }
}
