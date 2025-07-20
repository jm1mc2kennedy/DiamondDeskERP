import Foundation
import CloudKit
import Combine

// MARK: - AuditTemplate Repository Protocol
protocol AuditTemplateRepositoryProtocol {
    func fetchAll() async throws -> [AuditTemplate]
    func fetchActive() async throws -> [AuditTemplate]
    func fetchByCategory(_ category: AuditTemplate.AuditCategory) async throws -> [AuditTemplate]
    func fetchByStoreCode(_ storeCode: String) async throws -> [AuditTemplate]
    func fetch(byId id: CKRecord.ID) async throws -> AuditTemplate?
    func save(_ template: AuditTemplate) async throws -> AuditTemplate
    func delete(_ template: AuditTemplate) async throws
    func publish(_ template: AuditTemplate) async throws -> AuditTemplate
    func archive(_ template: AuditTemplate) async throws -> AuditTemplate
}

// MARK: - CloudKit AuditTemplate Repository
class CloudKitAuditTemplateRepository: AuditTemplateRepositoryProtocol {
    private let database: CKDatabase
    
    init(database: CKDatabase = CKContainer.default().publicCloudDatabase) {
        self.database = database
    }
    
    func fetchAll() async throws -> [AuditTemplate] {
        let query = CKQuery(recordType: "AuditTemplate", predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        
        let (results, _) = try await database.records(matching: query)
        return results.compactMap { (_, result) in
            switch result {
            case .success(let record):
                return AuditTemplate(record: record)
            case .failure:
                return nil
            }
        }
    }
    
    func fetchActive() async throws -> [AuditTemplate] {
        let predicate = NSPredicate(format: "status == %@ AND isActive == YES", AuditTemplate.TemplateStatus.published.rawValue)
        let query = CKQuery(recordType: "AuditTemplate", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        
        let (results, _) = try await database.records(matching: query)
        return results.compactMap { (_, result) in
            switch result {
            case .success(let record):
                return AuditTemplate(record: record)
            case .failure:
                return nil
            }
        }
    }
    
    func fetchByCategory(_ category: AuditTemplate.AuditCategory) async throws -> [AuditTemplate] {
        let predicate = NSPredicate(format: "category == %@ AND isActive == YES", category.rawValue)
        let query = CKQuery(recordType: "AuditTemplate", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        
        let (results, _) = try await database.records(matching: query)
        return results.compactMap { (_, result) in
            switch result {
            case .success(let record):
                return AuditTemplate(record: record)
            case .failure:
                return nil
            }
        }
    }
    
    func fetchByStoreCode(_ storeCode: String) async throws -> [AuditTemplate] {
        let predicate = NSPredicate(format: "applicableStores CONTAINS %@ AND status == %@ AND isActive == YES", 
                                  storeCode, AuditTemplate.TemplateStatus.published.rawValue)
        let query = CKQuery(recordType: "AuditTemplate", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "priority", ascending: false)]
        
        let (results, _) = try await database.records(matching: query)
        return results.compactMap { (_, result) in
            switch result {
            case .success(let record):
                return AuditTemplate(record: record)
            case .failure:
                return nil
            }
        }
    }
    
    func fetch(byId id: CKRecord.ID) async throws -> AuditTemplate? {
        let record = try await database.record(for: id)
        return AuditTemplate(record: record)
    }
    
    func save(_ template: AuditTemplate) async throws -> AuditTemplate {
        let record = template.toRecord()
        let savedRecord = try await database.save(record)
        return AuditTemplate(record: savedRecord) ?? template
    }
    
    func delete(_ template: AuditTemplate) async throws {
        try await database.deleteRecord(withID: template.id)
    }
    
    func publish(_ template: AuditTemplate) async throws -> AuditTemplate {
        let publishedTemplate = template.publish()
        return try await save(publishedTemplate)
    }
    
    func archive(_ template: AuditTemplate) async throws -> AuditTemplate {
        let archivedTemplate = template.archive()
        return try await save(archivedTemplate)
    }
}

// MARK: - Audit Repository Protocol
protocol AuditRepositoryProtocol {
    func fetchAll() async throws -> [Audit]
    func fetchByStoreCode(_ storeCode: String) async throws -> [Audit]
    func fetchByTemplate(_ templateId: CKRecord.ID) async throws -> [Audit]
    func fetchByStatus(_ status: Audit.AuditStatus) async throws -> [Audit]
    func fetchInProgress() async throws -> [Audit]
    func fetch(byId id: CKRecord.ID) async throws -> Audit?
    func save(_ audit: Audit) async throws -> Audit
    func delete(_ audit: Audit) async throws
    func addResponse(_ audit: Audit, response: Audit.AuditResponse) async throws -> Audit
    func complete(_ audit: Audit, finalScore: Double, maxScore: Double) async throws -> Audit
    func submit(_ audit: Audit) async throws -> Audit
}

// MARK: - CloudKit Audit Repository
class CloudKitAuditRepository: AuditRepositoryProtocol {
    private let database: CKDatabase
    
    init(database: CKDatabase = CKContainer.default().publicCloudDatabase) {
        self.database = database
    }
    
    func fetchAll() async throws -> [Audit] {
        let query = CKQuery(recordType: "Audit", predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "startedAt", ascending: false)]
        
        let (results, _) = try await database.records(matching: query)
        return results.compactMap { (_, result) in
            switch result {
            case .success(let record):
                return Audit(record: record)
            case .failure:
                return nil
            }
        }
    }
    
    func fetchByStoreCode(_ storeCode: String) async throws -> [Audit] {
        let predicate = NSPredicate(format: "storeCode == %@", storeCode)
        let query = CKQuery(recordType: "Audit", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "startedAt", ascending: false)]
        
        let (results, _) = try await database.records(matching: query)
        return results.compactMap { (_, result) in
            switch result {
            case .success(let record):
                return Audit(record: record)
            case .failure:
                return nil
            }
        }
    }
    
    func fetchByTemplate(_ templateId: CKRecord.ID) async throws -> [Audit] {
        let templateRef = CKRecord.Reference(recordID: templateId, action: .none)
        let predicate = NSPredicate(format: "templateRef == %@", templateRef)
        let query = CKQuery(recordType: "Audit", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "startedAt", ascending: false)]
        
        let (results, _) = try await database.records(matching: query)
        return results.compactMap { (_, result) in
            switch result {
            case .success(let record):
                return Audit(record: record)
            case .failure:
                return nil
            }
        }
    }
    
    func fetchByStatus(_ status: Audit.AuditStatus) async throws -> [Audit] {
        let predicate = NSPredicate(format: "status == %@", status.rawValue)
        let query = CKQuery(recordType: "Audit", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "startedAt", ascending: false)]
        
        let (results, _) = try await database.records(matching: query)
        return results.compactMap { (_, result) in
            switch result {
            case .success(let record):
                return Audit(record: record)
            case .failure:
                return nil
            }
        }
    }
    
    func fetchInProgress() async throws -> [Audit] {
        let predicate = NSPredicate(format: "status IN %@", [
            Audit.AuditStatus.inProgress.rawValue,
            Audit.AuditStatus.paused.rawValue
        ])
        let query = CKQuery(recordType: "Audit", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "startedAt", ascending: false)]
        
        let (results, _) = try await database.records(matching: query)
        return results.compactMap { (_, result) in
            switch result {
            case .success(let record):
                return Audit(record: record)
            case .failure:
                return nil
            }
        }
    }
    
    func fetch(byId id: CKRecord.ID) async throws -> Audit? {
        let record = try await database.record(for: id)
        return Audit(record: record)
    }
    
    func save(_ audit: Audit) async throws -> Audit {
        let record = audit.toRecord()
        let savedRecord = try await database.save(record)
        return Audit(record: savedRecord) ?? audit
    }
    
    func delete(_ audit: Audit) async throws {
        try await database.deleteRecord(withID: audit.id)
    }
    
    func addResponse(_ audit: Audit, response: Audit.AuditResponse) async throws -> Audit {
        let updatedAudit = audit.addResponse(response)
        return try await save(updatedAudit)
    }
    
    func complete(_ audit: Audit, finalScore: Double, maxScore: Double) async throws -> Audit {
        let completedAudit = audit.complete(finalScore: finalScore, maxScore: maxScore)
        return try await save(completedAudit)
    }
    
    func submit(_ audit: Audit) async throws -> Audit {
        let submittedAudit = audit.submit()
        return try await save(submittedAudit)
    }
}

// MARK: - Repository Factory
class AuditRepositoryFactory {
    static func makeAuditTemplateRepository() -> AuditTemplateRepositoryProtocol {
        return CloudKitAuditTemplateRepository()
    }
    
    static func makeAuditRepository() -> AuditRepositoryProtocol {
        return CloudKitAuditRepository()
    }
}
