//
//  AuditRepositoryTests.swift
//  DiamondDeskERPTests
//
//  Created by GitHub Copilot on 1/2/2025.
//

import Testing
import CloudKit
import Combine
@testable import DiamondDeskERP

@MainActor
struct AuditRepositoryTests {
    
    // MARK: - Mock CloudKit Database
    
    class MockCKDatabase: CKDatabase {
        var shouldFailFetch = false
        var shouldFailSave = false
        var mockRecords: [CKRecord] = []
        var fetchCallCount = 0
        var saveCallCount = 0
        var deleteCallCount = 0
        
        override func fetch(withRecordID recordID: CKRecord.ID) async throws -> CKRecord {
            fetchCallCount += 1
            if shouldFailFetch {
                throw CKError(.networkFailure)
            }
            
            guard let record = mockRecords.first(where: { $0.recordID == recordID }) else {
                throw CKError(.unknownItem)
            }
            return record
        }
        
        override func records(matching query: CKQuery) async throws -> (matchResults: [(CKRecord.ID, Result<CKRecord, Error>)], queryCursor: CKQueryOperation.Cursor?) {
            fetchCallCount += 1
            if shouldFailFetch {
                throw CKError(.networkFailure)
            }
            
            let matchResults: [(CKRecord.ID, Result<CKRecord, Error>)] = mockRecords.map { record in
                (record.recordID, .success(record))
            }
            
            return (matchResults, nil)
        }
        
        override func save(_ record: CKRecord) async throws -> CKRecord {
            saveCallCount += 1
            if shouldFailSave {
                throw CKError(.quotaExceeded)
            }
            
            mockRecords.removeAll { $0.recordID == record.recordID }
            mockRecords.append(record)
            return record
        }
        
        override func deleteRecord(withID recordID: CKRecord.ID) async throws -> CKRecord.ID {
            deleteCallCount += 1
            guard let index = mockRecords.firstIndex(where: { $0.recordID == recordID }) else {
                throw CKError(.unknownItem)
            }
            mockRecords.remove(at: index)
            return recordID
        }
    }
    
    class MockCKContainer: CKContainer {
        let mockDatabase: MockCKDatabase
        
        init() {
            self.mockDatabase = MockCKDatabase()
        }
        
        override var publicCloudDatabase: CKDatabase {
            return mockDatabase
        }
        
        override var privateCloudDatabase: CKDatabase {
            return mockDatabase
        }
    }
    
    // MARK: - Mock Repository Implementation
    
    class MockAuditTemplateRepository: AuditTemplateRepositoryProtocol {
        var mockTemplates: [AuditTemplate] = []
        var shouldThrowError = false
        
        func fetchAll() async throws -> [AuditTemplate] {
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
        
        func fetchAll() async throws -> [Audit] {
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
    
    // MARK: - AuditTemplate Repository Tests
    
    @Test("AuditTemplateRepository fetchAll returns all templates")
    func testAuditTemplateRepositoryFetchAll() async throws {
        let mockRepository = MockAuditTemplateRepository()
        
        let template = AuditTemplate(
            id: CKRecord.ID(recordName: "template-1"),
            templateName: "Test Template",
            category: "Safety",
            description: "Test Description",
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
        
        let templates = try await mockRepository.fetchAll()
        
        #expect(templates.count == 1)
        #expect(templates.first?.templateName == "Test Template")
        #expect(templates.first?.category == "Safety")
    }
    
    @Test("AuditTemplateRepository fetchActive returns only active templates")
    func testAuditTemplateRepositoryFetchActive() async throws {
        let mockRepository = MockAuditTemplateRepository()
        
        let activeTemplate = AuditTemplate(
            id: CKRecord.ID(recordName: "active-template"),
            templateName: "Active Template",
            category: "Safety",
            description: "Active Description",
            sections: [],
            version: "1.0",
            status: .published,
            isActive: true,
            createdByRef: CKRecord.Reference(recordID: CKRecord.ID(recordName: "user-1"), action: .none),
            createdAt: Date(),
            updatedAt: Date(),
            publishedAt: Date()
        )
        
        let inactiveTemplate = AuditTemplate(
            id: CKRecord.ID(recordName: "inactive-template"),
            templateName: "Inactive Template",
            category: "Safety",
            description: "Inactive Description",
            sections: [],
            version: "1.0",
            status: .archived,
            isActive: false,
            createdByRef: CKRecord.Reference(recordID: CKRecord.ID(recordName: "user-1"), action: .none),
            createdAt: Date(),
            updatedAt: Date(),
            publishedAt: nil
        )
        
        mockRepository.mockTemplates = [activeTemplate, inactiveTemplate]
        
        let activeTemplates = try await mockRepository.fetchActive()
        
        #expect(activeTemplates.count == 1)
        #expect(activeTemplates.first?.isActive == true)
        #expect(activeTemplates.first?.templateName == "Active Template")
    }
    
    @Test("AuditTemplateRepository publish updates template status")
    func testAuditTemplateRepositoryPublish() async throws {
        let mockRepository = MockAuditTemplateRepository()
        
        let template = AuditTemplate(
            id: CKRecord.ID(recordName: "draft-template"),
            templateName: "Draft Template",
            category: "Safety",
            description: "Draft Description",
            sections: [],
            version: "1.0",
            status: .draft,
            isActive: false,
            createdByRef: CKRecord.Reference(recordID: CKRecord.ID(recordName: "user-1"), action: .none),
            createdAt: Date(),
            updatedAt: Date(),
            publishedAt: nil
        )
        
        mockRepository.mockTemplates = [template]
        
        let publishedTemplate = try await mockRepository.publish(template)
        
        #expect(publishedTemplate.status == .published)
        #expect(publishedTemplate.publishedAt != nil)
        #expect(mockRepository.mockTemplates.first?.status == .published)
    }
    
    // MARK: - Audit Repository Tests
    
    @Test("AuditRepository fetchByStatus returns audits with correct status")
    func testAuditRepositoryFetchByStatus() async throws {
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
        
        mockRepository.mockAudits = [pendingAudit, completedAudit]
        
        let pendingAudits = try await mockRepository.fetchByStatus(.pending)
        
        #expect(pendingAudits.count == 1)
        #expect(pendingAudits.first?.status == .pending)
        #expect(pendingAudits.first?.storeCode == "001")
    }
    
    @Test("AuditRepository complete updates audit status and score")
    func testAuditRepositoryComplete() async throws {
        let mockRepository = MockAuditRepository()
        
        let audit = Audit(
            id: CKRecord.ID(recordName: "in-progress-audit"),
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
        
        let completedAudit = try await mockRepository.complete(audit, score: 92.5)
        
        #expect(completedAudit.status == .completed)
        #expect(completedAudit.finalScore == 92.5)
        #expect(completedAudit.completedAt != nil)
        #expect(mockRepository.mockAudits.first?.status == .completed)
    }
    
    @Test("AuditRepository addResponse adds response to audit")
    func testAuditRepositoryAddResponse() async throws {
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
        
        let updatedAudit = try await mockRepository.addResponse(audit, response: response)
        
        #expect(updatedAudit.responses.count == 1)
        #expect(updatedAudit.responses.first?.questionId == "q1")
        #expect(updatedAudit.responses.first?.answer == "Yes")
        #expect(mockRepository.mockAudits.first?.responses.count == 1)
    }
    
    // MARK: - Error Handling Tests
    
    @Test("AuditTemplateRepository handles network errors")
    func testAuditTemplateRepositoryNetworkError() async throws {
        let mockRepository = MockAuditTemplateRepository()
        mockRepository.shouldThrowError = true
        
        do {
            _ = try await mockRepository.fetchAll()
            #expect(Bool(false), "Expected error to be thrown")
        } catch {
            #expect(error is CKError)
        }
    }
    
    @Test("AuditRepository handles save errors")
    func testAuditRepositorySaveError() async throws {
        let mockRepository = MockAuditRepository()
        mockRepository.shouldThrowError = true
        
        let audit = Audit(
            id: CKRecord.ID(recordName: "test-audit"),
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
        
        do {
            _ = try await mockRepository.save(audit)
            #expect(Bool(false), "Expected error to be thrown")
        } catch {
            #expect(error is CKError)
        }
    }
}
