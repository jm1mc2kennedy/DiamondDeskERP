import Foundation
import CloudKit
import Combine
import SwiftUI

// MARK: - AuditTemplate ViewModel
@MainActor
class AuditTemplateViewModel: ObservableObject {
    @Published var templates: [AuditTemplate] = []
    @Published var activeTemplates: [AuditTemplate] = []
    @Published var selectedTemplate: AuditTemplate?
    @Published var isLoading = false
    @Published var error: Error?
    @Published var searchText = ""
    @Published var selectedCategory: AuditTemplate.AuditCategory?
    @Published var selectedStoreCode: String?
    
    private let repository: AuditTemplateRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // Computed properties for reactive filtering
    var filteredTemplates: [AuditTemplate] {
        var filtered = templates
        
        if !searchText.isEmpty {
            filtered = filtered.filter { template in
                template.title.localizedCaseInsensitiveContains(searchText) ||
                template.description.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        if let category = selectedCategory {
            filtered = filtered.filter { $0.category == category }
        }
        
        if let storeCode = selectedStoreCode {
            filtered = filtered.filter { $0.applicableStores.contains(storeCode) }
        }
        
        return filtered
    }
    
    var templatesByCategory: [AuditTemplate.AuditCategory: [AuditTemplate]] {
        Dictionary(grouping: filteredTemplates) { $0.category }
    }
    
    init(repository: AuditTemplateRepositoryProtocol = AuditRepositoryFactory.makeAuditTemplateRepository()) {
        self.repository = repository
        setupBindings()
    }
    
    private func setupBindings() {
        // Auto-refresh when search text changes
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    func loadTemplates() {
        isLoading = true
        error = nil
        
        Task {
            do {
                let fetchedTemplates = try await repository.fetchAll()
                templates = fetchedTemplates
                activeTemplates = fetchedTemplates.filter { $0.status == .published && $0.isActive }
                isLoading = false
            } catch {
                self.error = error
                isLoading = false
            }
        }
    }
    
    func loadActiveTemplates() {
        isLoading = true
        error = nil
        
        Task {
            do {
                activeTemplates = try await repository.fetchActive()
                isLoading = false
            } catch {
                self.error = error
                isLoading = false
            }
        }
    }
    
    func loadTemplates(for storeCode: String) {
        isLoading = true
        error = nil
        
        Task {
            do {
                let storeTemplates = try await repository.fetchByStoreCode(storeCode)
                templates = storeTemplates
                isLoading = false
            } catch {
                self.error = error
                isLoading = false
            }
        }
    }
    
    func loadTemplates(for category: AuditTemplate.AuditCategory) {
        isLoading = true
        error = nil
        
        Task {
            do {
                let categoryTemplates = try await repository.fetchByCategory(category)
                templates = categoryTemplates
                isLoading = false
            } catch {
                self.error = error
                isLoading = false
            }
        }
    }
    
    func createTemplate(_ template: AuditTemplate) {
        Task {
            do {
                let savedTemplate = try await repository.save(template)
                if let index = templates.firstIndex(where: { $0.id == savedTemplate.id }) {
                    templates[index] = savedTemplate
                } else {
                    templates.append(savedTemplate)
                }
            } catch {
                self.error = error
            }
        }
    }
    
    func updateTemplate(_ template: AuditTemplate) {
        Task {
            do {
                let updatedTemplate = try await repository.save(template)
                if let index = templates.firstIndex(where: { $0.id == updatedTemplate.id }) {
                    templates[index] = updatedTemplate
                }
            } catch {
                self.error = error
            }
        }
    }
    
    func publishTemplate(_ template: AuditTemplate) {
        Task {
            do {
                let publishedTemplate = try await repository.publish(template)
                if let index = templates.firstIndex(where: { $0.id == publishedTemplate.id }) {
                    templates[index] = publishedTemplate
                }
                if !activeTemplates.contains(where: { $0.id == publishedTemplate.id }) {
                    activeTemplates.append(publishedTemplate)
                }
            } catch {
                self.error = error
            }
        }
    }
    
    func archiveTemplate(_ template: AuditTemplate) {
        Task {
            do {
                let archivedTemplate = try await repository.archive(template)
                if let index = templates.firstIndex(where: { $0.id == archivedTemplate.id }) {
                    templates[index] = archivedTemplate
                }
                activeTemplates.removeAll { $0.id == archivedTemplate.id }
            } catch {
                self.error = error
            }
        }
    }
    
    func deleteTemplate(_ template: AuditTemplate) {
        Task {
            do {
                try await repository.delete(template)
                templates.removeAll { $0.id == template.id }
                activeTemplates.removeAll { $0.id == template.id }
            } catch {
                self.error = error
            }
        }
    }
    
    func selectTemplate(_ template: AuditTemplate) {
        selectedTemplate = template
    }
    
    func clearSelection() {
        selectedTemplate = nil
    }
    
    func clearFilters() {
        searchText = ""
        selectedCategory = nil
        selectedStoreCode = nil
    }
}

// MARK: - Audit ViewModel
@MainActor
class AuditViewModel: ObservableObject {
    @Published var audits: [Audit] = []
    @Published var currentAudit: Audit?
    @Published var inProgressAudits: [Audit] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var searchText = ""
    @Published var selectedStatus: Audit.AuditStatus?
    @Published var selectedStoreCode: String?
    
    private let repository: AuditRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // Computed properties for reactive filtering
    var filteredAudits: [Audit] {
        var filtered = audits
        
        if !searchText.isEmpty {
            filtered = filtered.filter { audit in
                audit.templateTitle.localizedCaseInsensitiveContains(searchText) ||
                audit.storeCode.localizedCaseInsensitiveContains(searchText) ||
                audit.startedByName.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        if let status = selectedStatus {
            filtered = filtered.filter { $0.status == status }
        }
        
        if let storeCode = selectedStoreCode {
            filtered = filtered.filter { $0.storeCode == storeCode }
        }
        
        return filtered
    }
    
    var auditsByStatus: [Audit.AuditStatus: [Audit]] {
        Dictionary(grouping: filteredAudits) { $0.status }
    }
    
    var recentAudits: [Audit] {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        return filteredAudits.filter { $0.startedAt >= thirtyDaysAgo }
    }
    
    var completedAudits: [Audit] {
        return filteredAudits.filter { $0.status.isComplete }
    }
    
    init(repository: AuditRepositoryProtocol = AuditRepositoryFactory.makeAuditRepository()) {
        self.repository = repository
        setupBindings()
    }
    
    private func setupBindings() {
        // Auto-refresh when search text changes
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    func loadAudits() {
        isLoading = true
        error = nil
        
        Task {
            do {
                audits = try await repository.fetchAll()
                inProgressAudits = try await repository.fetchInProgress()
                isLoading = false
            } catch {
                self.error = error
                isLoading = false
            }
        }
    }
    
    func loadAudits(for storeCode: String) {
        isLoading = true
        error = nil
        
        Task {
            do {
                audits = try await repository.fetchByStoreCode(storeCode)
                isLoading = false
            } catch {
                self.error = error
                isLoading = false
            }
        }
    }
    
    func loadAudits(for template: AuditTemplate) {
        isLoading = true
        error = nil
        
        Task {
            do {
                audits = try await repository.fetchByTemplate(template.id)
                isLoading = false
            } catch {
                self.error = error
                isLoading = false
            }
        }
    }
    
    func loadInProgressAudits() {
        Task {
            do {
                inProgressAudits = try await repository.fetchInProgress()
            } catch {
                self.error = error
            }
        }
    }
    
    func startAudit(template: AuditTemplate, storeCode: String, storeName: String?, startedBy: CKRecord.Reference, startedByName: String) {
        let newAudit = Audit.create(
            templateRef: CKRecord.Reference(recordID: template.id, action: .none),
            templateTitle: template.title,
            storeCode: storeCode,
            storeName: storeName,
            startedBy: startedBy,
            startedByName: startedByName,
            totalQuestions: template.totalQuestions
        )
        
        currentAudit = newAudit
        
        Task {
            do {
                let savedAudit = try await repository.save(newAudit)
                currentAudit = savedAudit
                if !audits.contains(where: { $0.id == savedAudit.id }) {
                    audits.append(savedAudit)
                }
                inProgressAudits.append(savedAudit)
            } catch {
                self.error = error
                currentAudit = nil
            }
        }
    }
    
    func saveAudit(_ audit: Audit) {
        Task {
            do {
                let savedAudit = try await repository.save(audit)
                if let index = audits.firstIndex(where: { $0.id == savedAudit.id }) {
                    audits[index] = savedAudit
                } else {
                    audits.append(savedAudit)
                }
                
                if currentAudit?.id == savedAudit.id {
                    currentAudit = savedAudit
                }
            } catch {
                self.error = error
            }
        }
    }
    
    func addResponse(to audit: Audit, response: Audit.AuditResponse) {
        Task {
            do {
                let updatedAudit = try await repository.addResponse(audit, response: response)
                if let index = audits.firstIndex(where: { $0.id == updatedAudit.id }) {
                    audits[index] = updatedAudit
                }
                
                if currentAudit?.id == updatedAudit.id {
                    currentAudit = updatedAudit
                }
            } catch {
                self.error = error
            }
        }
    }
    
    func completeAudit(_ audit: Audit, finalScore: Double, maxScore: Double) {
        Task {
            do {
                let completedAudit = try await repository.complete(audit, finalScore: finalScore, maxScore: maxScore)
                if let index = audits.firstIndex(where: { $0.id == completedAudit.id }) {
                    audits[index] = completedAudit
                }
                
                if currentAudit?.id == completedAudit.id {
                    currentAudit = completedAudit
                }
                
                inProgressAudits.removeAll { $0.id == completedAudit.id }
            } catch {
                self.error = error
            }
        }
    }
    
    func submitAudit(_ audit: Audit) {
        Task {
            do {
                let submittedAudit = try await repository.submit(audit)
                if let index = audits.firstIndex(where: { $0.id == submittedAudit.id }) {
                    audits[index] = submittedAudit
                }
                
                if currentAudit?.id == submittedAudit.id {
                    currentAudit = submittedAudit
                }
                
                inProgressAudits.removeAll { $0.id == submittedAudit.id }
            } catch {
                self.error = error
            }
        }
    }
    
    func deleteAudit(_ audit: Audit) {
        Task {
            do {
                try await repository.delete(audit)
                audits.removeAll { $0.id == audit.id }
                inProgressAudits.removeAll { $0.id == audit.id }
                
                if currentAudit?.id == audit.id {
                    currentAudit = nil
                }
            } catch {
                self.error = error
            }
        }
    }
    
    func selectAudit(_ audit: Audit) {
        currentAudit = audit
    }
    
    func clearCurrentAudit() {
        currentAudit = nil
    }
    
    func clearFilters() {
        searchText = ""
        selectedStatus = nil
        selectedStoreCode = nil
    }
    
    // Helper methods for audit statistics
    func completionRate(for storeCode: String) -> Double {
        let storeAudits = audits.filter { $0.storeCode == storeCode }
        guard !storeAudits.isEmpty else { return 0 }
        
        let completed = storeAudits.filter { $0.status.isComplete }.count
        return (Double(completed) / Double(storeAudits.count)) * 100
    }
    
    func averageScore(for storeCode: String) -> Double {
        let completedAudits = audits.filter { 
            $0.storeCode == storeCode && $0.status.isComplete && $0.percentage != nil
        }
        
        guard !completedAudits.isEmpty else { return 0 }
        
        let totalScore = completedAudits.compactMap { $0.percentage }.reduce(0, +)
        return totalScore / Double(completedAudits.count)
    }
    
    func criticalIssuesCount() -> Int {
        return audits.flatMap { $0.criticalFlags }.count
    }
}
