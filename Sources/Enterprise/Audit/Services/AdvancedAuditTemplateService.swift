//
//  AdvancedAuditTemplateService.swift
//  DiamondDeskERP
//
//  Created by J.Michael McDermott on 7/20/25.
//

import Foundation
import CloudKit
import Combine

/// Advanced Audit Templates
/// Compliance and reporting capabilities with regulatory framework support
@MainActor
final class AdvancedAuditTemplateService: ObservableObject {
    
    static let shared = AdvancedAuditTemplateService()
    
    // MARK: - Published Properties
    
    @Published var auditTemplates: [AuditTemplate] = []
    @Published var complianceFrameworks: [ComplianceFramework] = []
    @Published var auditReports: [AuditReport] = []
    @Published var auditSchedules: [AuditSchedule] = []
    @Published var auditFindings: [AuditFinding] = []
    @Published var remedialActions: [RemedialAction] = []
    @Published var isLoading = false
    @Published var error: AuditError?
    
    // MARK: - Compliance Properties
    
    @Published var complianceScores: [String: ComplianceScore] = [:]
    @Published var regualtoryRequirements: [RegulatoryRequirement] = []
    @Published var complianceGaps: [ComplianceGap] = []
    @Published var certificationStatus: [CertificationStatus] = []
    
    // MARK: - Analytics Properties
    
    @Published var auditMetrics: AuditMetrics?
    @Published var trendAnalysis: TrendAnalysis?
    @Published var riskHeatMap: RiskHeatMap?
    @Published var benchmarkData: BenchmarkData?
    
    // MARK: - Private Properties
    
    private let container = CKContainer(identifier: "iCloud.com.diamonddesk.erp")
    private var database: CKDatabase { container.privateCloudDatabase }
    private var cancellables = Set<AnyCancellable>()
    private let notificationCenter = NotificationCenter.default
    
    // MARK: - Initialization
    
    private init() {
        setupDefaultTemplates()
        setupComplianceFrameworks()
        loadAuditData()
        setupNotifications()
    }
    
    // MARK: - Template Management
    
    /// Creates a new audit template
    func createAuditTemplate(
        name: String,
        description: String,
        framework: ComplianceFramework,
        auditType: AuditType,
        scope: AuditScope,
        controlObjectives: [ControlObjective],
        procedures: [AuditProcedure],
        riskAreas: [RiskArea],
        frequency: AuditFrequency,
        createdBy: String
    ) async throws -> AuditTemplate {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let template = AuditTemplate(
                id: UUID().uuidString,
                name: name,
                description: description,
                framework: framework,
                auditType: auditType,
                scope: scope,
                controlObjectives: controlObjectives,
                procedures: procedures,
                riskAreas: riskAreas,
                frequency: frequency,
                createdBy: createdBy,
                createdAt: Date(),
                version: "1.0",
                isActive: true
            )
            
            // Validate template
            try validateTemplate(template)
            
            // Save to CloudKit
            try await saveAuditTemplate(template)
            
            // Update local state
            auditTemplates.append(template)
            
            // Log template creation
            await logAuditActivity(
                .templateCreated,
                templateId: template.id,
                userId: createdBy,
                details: "Audit template '\(name)' created for \(framework.name)"
            )
            
            return template
            
        } catch {
            await handleError(AuditError.templateCreationFailed(error))
            throw error
        }
    }
    
    /// Updates an existing audit template
    func updateAuditTemplate(
        templateId: String,
        name: String? = nil,
        description: String? = nil,
        controlObjectives: [ControlObjective]? = nil,
        procedures: [AuditProcedure]? = nil,
        riskAreas: [RiskArea]? = nil,
        modifiedBy: String
    ) async throws {
        guard let template = auditTemplates.first(where: { $0.id == templateId }) else {
            throw AuditError.templateNotFound
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Create new version
            let newVersion = incrementVersion(template.version)
            
            // Update template properties
            if let name = name { template.name = name }
            if let description = description { template.description = description }
            if let controlObjectives = controlObjectives { template.controlObjectives = controlObjectives }
            if let procedures = procedures { template.procedures = procedures }
            if let riskAreas = riskAreas { template.riskAreas = riskAreas }
            
            template.version = newVersion
            template.modifiedBy = modifiedBy
            template.modifiedAt = Date()
            
            // Validate updated template
            try validateTemplate(template)
            
            // Save to CloudKit
            try await saveAuditTemplate(template)
            
            // Log template update
            await logAuditActivity(
                .templateUpdated,
                templateId: template.id,
                userId: modifiedBy,
                details: "Audit template '\(template.name)' updated to version \(newVersion)"
            )
            
        } catch {
            await handleError(AuditError.templateUpdateFailed(error))
            throw error
        }
    }
    
    // MARK: - Audit Execution
    
    /// Executes an audit based on a template
    func executeAudit(
        templateId: String,
        auditName: String,
        auditeeId: String,
        plannedStartDate: Date,
        plannedEndDate: Date,
        auditorIds: [String],
        executedBy: String
    ) async throws -> AuditReport {
        guard let template = auditTemplates.first(where: { $0.id == templateId }) else {
            throw AuditError.templateNotFound
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let report = AuditReport(
                id: UUID().uuidString,
                templateId: templateId,
                auditName: auditName,
                auditeeId: auditeeId,
                framework: template.framework,
                auditType: template.auditType,
                scope: template.scope,
                plannedStartDate: plannedStartDate,
                plannedEndDate: plannedEndDate,
                actualStartDate: nil,
                actualEndDate: nil,
                auditorIds: auditorIds,
                status: .planned,
                executedBy: executedBy,
                createdAt: Date(),
                controlObjectives: template.controlObjectives,
                procedures: template.procedures.map { procedure in
                    ExecutedProcedure(
                        procedure: procedure,
                        status: .notStarted,
                        assignedTo: auditorIds.first ?? executedBy,
                        evidence: [],
                        findings: [],
                        notes: ""
                    )
                },
                overallRating: .notAssessed,
                complianceScore: 0.0
            )
            
            // Save to CloudKit
            try await saveAuditReport(report)
            
            // Update local state
            auditReports.append(report)
            
            // Schedule notifications
            await scheduleAuditNotifications(report)
            
            // Log audit execution
            await logAuditActivity(
                .auditExecuted,
                templateId: templateId,
                userId: executedBy,
                details: "Audit '\(auditName)' executed based on template '\(template.name)'"
            )
            
            return report
            
        } catch {
            await handleError(AuditError.auditExecutionFailed(error))
            throw error
        }
    }
    
    /// Updates audit status and progress
    func updateAuditStatus(
        reportId: String,
        status: AuditStatus,
        updatedBy: String,
        notes: String? = nil
    ) async throws {
        guard let report = auditReports.first(where: { $0.id == reportId }) else {
            throw AuditError.auditReportNotFound
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let previousStatus = report.status
            report.status = status
            report.modifiedBy = updatedBy
            report.modifiedAt = Date()
            
            // Update timestamps
            switch status {
            case .inProgress:
                if report.actualStartDate == nil {
                    report.actualStartDate = Date()
                }
            case .completed:
                report.actualEndDate = Date()
                // Calculate final compliance score
                await calculateComplianceScore(report)
            case .cancelled, .onHold:
                // Additional logic for these statuses
                break
            default:
                break
            }
            
            // Add status change note
            if let notes = notes {
                report.statusNotes.append(AuditNote(
                    id: UUID().uuidString,
                    content: notes,
                    createdBy: updatedBy,
                    createdAt: Date(),
                    type: .statusChange
                ))
            }
            
            // Save to CloudKit
            try await saveAuditReport(report)
            
            // Send notifications
            await sendStatusChangeNotification(report, previousStatus: previousStatus)
            
            // Log status change
            await logAuditActivity(
                .statusChanged,
                templateId: report.templateId,
                userId: updatedBy,
                details: "Audit '\(report.auditName)' status changed from \(previousStatus.displayName) to \(status.displayName)"
            )
            
        } catch {
            await handleError(AuditError.statusUpdateFailed(error))
            throw error
        }
    }
    
    // MARK: - Findings Management
    
    /// Adds a finding to an audit report
    func addAuditFinding(
        reportId: String,
        procedureId: String,
        finding: AuditFinding,
        addedBy: String
    ) async throws {
        guard let report = auditReports.first(where: { $0.id == reportId }) else {
            throw AuditError.auditReportNotFound
        }
        
        guard let procedureIndex = report.procedures.firstIndex(where: { $0.procedure.id == procedureId }) else {
            throw AuditError.procedureNotFound
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Add finding to procedure
            report.procedures[procedureIndex].findings.append(finding)
            
            // Add to global findings list
            auditFindings.append(finding)
            
            // Update report compliance score
            await calculateComplianceScore(report)
            
            // Create remedial action if high risk
            if finding.riskLevel == .high || finding.riskLevel == .critical {
                let action = try await createRemedialAction(
                    findingId: finding.id,
                    reportId: reportId,
                    createdBy: addedBy
                )
                remedialActions.append(action)
            }
            
            // Save to CloudKit
            try await saveAuditReport(report)
            try await saveAuditFinding(finding)
            
            // Send notifications
            await sendFindingNotification(finding, reportId: reportId)
            
            // Log finding addition
            await logAuditActivity(
                .findingAdded,
                templateId: report.templateId,
                userId: addedBy,
                details: "Finding '\(finding.title)' added to audit '\(report.auditName)'"
            )
            
        } catch {
            await handleError(AuditError.findingCreationFailed(error))
            throw error
        }
    }
    
    /// Updates finding status
    func updateFindingStatus(
        findingId: String,
        status: FindingStatus,
        resolution: String? = nil,
        updatedBy: String
    ) async throws {
        guard let findingIndex = auditFindings.firstIndex(where: { $0.id == findingId }) else {
            throw AuditError.findingNotFound
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            auditFindings[findingIndex].status = status
            auditFindings[findingIndex].resolution = resolution
            auditFindings[findingIndex].resolvedBy = status == .resolved ? updatedBy : nil
            auditFindings[findingIndex].resolvedAt = status == .resolved ? Date() : nil
            
            // Save to CloudKit
            try await saveAuditFinding(auditFindings[findingIndex])
            
            // Update related remedial actions
            if status == .resolved {
                await closeRelatedRemedialActions(findingId: findingId, closedBy: updatedBy)
            }
            
            // Log finding update
            await logAuditActivity(
                .findingUpdated,
                templateId: nil,
                userId: updatedBy,
                details: "Finding '\(auditFindings[findingIndex].title)' status updated to \(status.displayName)"
            )
            
        } catch {
            await handleError(AuditError.findingUpdateFailed(error))
            throw error
        }
    }
    
    // MARK: - Compliance Analysis
    
    /// Calculates compliance score for an audit report
    func calculateComplianceScore(_ report: AuditReport) async {
        let totalProcedures = report.procedures.count
        let completedProcedures = report.procedures.filter { $0.status == .completed }.count
        let passedProcedures = report.procedures.filter { $0.findings.isEmpty || $0.findings.allSatisfy { $0.status == .resolved } }.count
        
        // Base compliance score
        let baseScore = totalProcedures > 0 ? Double(passedProcedures) / Double(totalProcedures) * 100 : 0
        
        // Adjust for finding severity
        let findings = report.procedures.flatMap { $0.findings }
        let criticalFindings = findings.filter { $0.riskLevel == .critical }.count
        let highFindings = findings.filter { $0.riskLevel == .high }.count
        let mediumFindings = findings.filter { $0.riskLevel == .medium }.count
        
        let severityPenalty = Double(criticalFindings * 20 + highFindings * 10 + mediumFindings * 5)
        
        report.complianceScore = max(0, baseScore - severityPenalty)
        
        // Update compliance score in tracking
        complianceScores[report.framework.id] = ComplianceScore(
            frameworkId: report.framework.id,
            score: report.complianceScore,
            lastAssessment: Date(),
            trend: calculateTrend(frameworkId: report.framework.id),
            riskAreas: identifyRiskAreas(findings)
        )
    }
    
    /// Generates compliance gap analysis
    func generateComplianceGapAnalysis(
        frameworkId: String,
        includeRecommendations: Bool = true
    ) async throws -> ComplianceGapAnalysis {
        guard let framework = complianceFrameworks.first(where: { $0.id == frameworkId }) else {
            throw AuditError.frameworkNotFound
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let relatedReports = auditReports.filter { $0.framework.id == frameworkId }
            let allFindings = relatedReports.flatMap { $0.procedures.flatMap { $0.findings } }
            
            // Identify gaps by control objective
            var gaps: [ComplianceGap] = []
            
            for requirement in framework.requirements {
                let relevantFindings = allFindings.filter { finding in
                    finding.controlObjectiveIds.contains(requirement.id)
                }
                
                if !relevantFindings.isEmpty {
                    let gap = ComplianceGap(
                        id: UUID().uuidString,
                        frameworkId: frameworkId,
                        requirementId: requirement.id,
                        requirementTitle: requirement.title,
                        gapDescription: generateGapDescription(findings: relevantFindings),
                        riskLevel: determineGapRiskLevel(findings: relevantFindings),
                        identifiedAt: Date(),
                        status: .open,
                        recommendations: includeRecommendations ? generateRecommendations(for: relevantFindings) : []
                    )
                    
                    gaps.append(gap)
                }
            }
            
            let analysis = ComplianceGapAnalysis(
                id: UUID().uuidString,
                frameworkId: frameworkId,
                generatedAt: Date(),
                totalRequirements: framework.requirements.count,
                compliantRequirements: framework.requirements.count - gaps.count,
                gaps: gaps,
                overallRiskLevel: determineOverallRisk(gaps: gaps),
                recommendedActions: includeRecommendations ? generateOverallRecommendations(gaps: gaps) : []
            )
            
            return analysis
            
        } catch {
            await handleError(AuditError.gapAnalysisFailed(error))
            throw error
        }
    }
    
    // MARK: - Reporting
    
    /// Generates comprehensive audit report
    func generateComprehensiveReport(
        reportId: String,
        includeExecutiveSummary: Bool = true,
        includeDetailedFindings: Bool = true,
        includeRecommendations: Bool = true,
        format: ReportFormat = .pdf
    ) async throws -> ComprehensiveAuditReport {
        guard let report = auditReports.first(where: { $0.id == reportId }) else {
            throw AuditError.auditReportNotFound
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let comprehensiveReport = ComprehensiveAuditReport(
                id: UUID().uuidString,
                auditReport: report,
                generatedAt: Date(),
                format: format,
                executiveSummary: includeExecutiveSummary ? generateExecutiveSummary(report) : nil,
                detailedFindings: includeDetailedFindings ? generateDetailedFindings(report) : nil,
                recommendations: includeRecommendations ? generateReportRecommendations(report) : nil,
                appendices: generateAppendices(report),
                certificationStatement: generateCertificationStatement(report)
            )
            
            // Save report
            try await saveComprehensiveReport(comprehensiveReport)
            
            return comprehensiveReport
            
        } catch {
            await handleError(AuditError.reportGenerationFailed(error))
            throw error
        }
    }
    
    /// Generates dashboard metrics
    func generateAuditMetrics(timeRange: TimeRange = .lastQuarter) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let filteredReports = auditReports.filter { report in
                report.createdAt >= timeRange.startDate && report.createdAt <= timeRange.endDate
            }
            
            let metrics = AuditMetrics(
                totalAudits: filteredReports.count,
                completedAudits: filteredReports.filter { $0.status == .completed }.count,
                inProgressAudits: filteredReports.filter { $0.status == .inProgress }.count,
                plannedAudits: filteredReports.filter { $0.status == .planned }.count,
                averageComplianceScore: calculateAverageComplianceScore(filteredReports),
                totalFindings: auditFindings.filter { finding in
                    finding.identifiedAt >= timeRange.startDate && finding.identifiedAt <= timeRange.endDate
                }.count,
                criticalFindings: auditFindings.filter { finding in
                    finding.riskLevel == .critical &&
                    finding.identifiedAt >= timeRange.startDate &&
                    finding.identifiedAt <= timeRange.endDate
                }.count,
                resolvedFindings: auditFindings.filter { finding in
                    finding.status == .resolved &&
                    finding.resolvedAt ?? Date.distantPast >= timeRange.startDate &&
                    finding.resolvedAt ?? Date.distantPast <= timeRange.endDate
                }.count,
                averageAuditDuration: calculateAverageAuditDuration(filteredReports),
                complianceByFramework: calculateComplianceByFramework(filteredReports)
            )
            
            self.auditMetrics = metrics
            
            // Generate trend analysis
            self.trendAnalysis = generateTrendAnalysis(filteredReports)
            
            // Generate risk heat map
            self.riskHeatMap = generateRiskHeatMap(filteredReports)
            
        } catch {
            await handleError(AuditError.metricsGenerationFailed(error))
            throw error
        }
    }
    
    // MARK: - Scheduling
    
    /// Schedules recurring audits
    func scheduleRecurringAudit(
        templateId: String,
        frequency: AuditFrequency,
        startDate: Date,
        auditeeId: String,
        auditorIds: [String],
        scheduledBy: String
    ) async throws -> AuditSchedule {
        guard let template = auditTemplates.first(where: { $0.id == templateId }) else {
            throw AuditError.templateNotFound
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let schedule = AuditSchedule(
                id: UUID().uuidString,
                templateId: templateId,
                frequency: frequency,
                startDate: startDate,
                nextAuditDate: calculateNextAuditDate(from: startDate, frequency: frequency),
                auditeeId: auditeeId,
                auditorIds: auditorIds,
                isActive: true,
                scheduledBy: scheduledBy,
                createdAt: Date()
            )
            
            // Save to CloudKit
            try await saveAuditSchedule(schedule)
            
            // Update local state
            auditSchedules.append(schedule)
            
            // Schedule notifications
            await scheduleRecurringNotifications(schedule)
            
            // Log schedule creation
            await logAuditActivity(
                .scheduleCreated,
                templateId: templateId,
                userId: scheduledBy,
                details: "Recurring audit scheduled for template '\(template.name)' with \(frequency.displayName) frequency"
            )
            
            return schedule
            
        } catch {
            await handleError(AuditError.scheduleCreationFailed(error))
            throw error
        }
    }
    
    // MARK: - Private Implementation
    
    private func setupDefaultTemplates() {
        // ISO 27001 Template
        let iso27001 = createISO27001Template()
        auditTemplates.append(iso27001)
        
        // SOX Template
        let sox = createSOXTemplate()
        auditTemplates.append(sox)
        
        // GDPR Template
        let gdpr = createGDPRTemplate()
        auditTemplates.append(gdpr)
        
        // Internal Controls Template
        let internalControls = createInternalControlsTemplate()
        auditTemplates.append(internalControls)
    }
    
    private func setupComplianceFrameworks() {
        complianceFrameworks = [
            ComplianceFramework(
                id: "iso27001",
                name: "ISO 27001",
                description: "Information Security Management Systems",
                version: "2013",
                requirements: createISO27001Requirements(),
                certificationBody: "ISO",
                isActive: true
            ),
            ComplianceFramework(
                id: "sox",
                name: "Sarbanes-Oxley Act",
                description: "Financial reporting and internal controls",
                version: "2002",
                requirements: createSOXRequirements(),
                certificationBody: "SEC",
                isActive: true
            ),
            ComplianceFramework(
                id: "gdpr",
                name: "GDPR",
                description: "General Data Protection Regulation",
                version: "2018",
                requirements: createGDPRRequirements(),
                certificationBody: "EU",
                isActive: true
            ),
            ComplianceFramework(
                id: "hipaa",
                name: "HIPAA",
                description: "Health Insurance Portability and Accountability Act",
                version: "1996",
                requirements: createHIPAARequirements(),
                certificationBody: "HHS",
                isActive: true
            )
        ]
    }
    
    private func loadAuditData() {
        Task {
            do {
                // Load audit data from CloudKit
                let templates = try await fetchAuditTemplates()
                let reports = try await fetchAuditReports()
                let findings = try await fetchAuditFindings()
                let schedules = try await fetchAuditSchedules()
                
                await MainActor.run {
                    self.auditTemplates.append(contentsOf: templates)
                    self.auditReports = reports
                    self.auditFindings = findings
                    self.auditSchedules = schedules
                }
            } catch {
                await handleError(AuditError.loadFailed(error))
            }
        }
    }
    
    private func setupNotifications() {
        // Setup local notifications for audit reminders
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("Notification authorization granted")
            }
        }
    }
    
    // MARK: - Validation
    
    private func validateTemplate(_ template: AuditTemplate) throws {
        guard !template.name.isEmpty else {
            throw AuditError.invalidTemplateName
        }
        
        guard !template.controlObjectives.isEmpty else {
            throw AuditError.missingControlObjectives
        }
        
        guard !template.procedures.isEmpty else {
            throw AuditError.missingProcedures
        }
        
        // Validate that all procedures have associated control objectives
        for procedure in template.procedures {
            guard template.controlObjectives.contains(where: { $0.id == procedure.controlObjectiveId }) else {
                throw AuditError.invalidProcedureMapping
            }
        }
    }
    
    // MARK: - CloudKit Operations
    
    private func saveAuditTemplate(_ template: AuditTemplate) async throws {
        let record = template.toCKRecord()
        try await database.save(record)
    }
    
    private func saveAuditReport(_ report: AuditReport) async throws {
        let record = report.toCKRecord()
        try await database.save(record)
    }
    
    private func saveAuditFinding(_ finding: AuditFinding) async throws {
        let record = finding.toCKRecord()
        try await database.save(record)
    }
    
    private func saveAuditSchedule(_ schedule: AuditSchedule) async throws {
        let record = schedule.toCKRecord()
        try await database.save(record)
    }
    
    private func saveComprehensiveReport(_ report: ComprehensiveAuditReport) async throws {
        let record = report.toCKRecord()
        try await database.save(record)
    }
    
    // MARK: - Fetch Operations
    
    private func fetchAuditTemplates() async throws -> [AuditTemplate] {
        // CloudKit fetch implementation
        return []
    }
    
    private func fetchAuditReports() async throws -> [AuditReport] {
        // CloudKit fetch implementation
        return []
    }
    
    private func fetchAuditFindings() async throws -> [AuditFinding] {
        // CloudKit fetch implementation
        return []
    }
    
    private func fetchAuditSchedules() async throws -> [AuditSchedule] {
        // CloudKit fetch implementation
        return []
    }
    
    // MARK: - Helper Methods
    
    private func incrementVersion(_ version: String) -> String {
        let components = version.split(separator: ".").compactMap { Int($0) }
        if components.count >= 2 {
            return "\(components[0]).\(components[1] + 1)"
        }
        return "1.1"
    }
    
    private func calculateNextAuditDate(from startDate: Date, frequency: AuditFrequency) -> Date {
        switch frequency {
        case .monthly:
            return Calendar.current.date(byAdding: .month, value: 1, to: startDate) ?? startDate
        case .quarterly:
            return Calendar.current.date(byAdding: .month, value: 3, to: startDate) ?? startDate
        case .semiAnnual:
            return Calendar.current.date(byAdding: .month, value: 6, to: startDate) ?? startDate
        case .annual:
            return Calendar.current.date(byAdding: .year, value: 1, to: startDate) ?? startDate
        case .biennial:
            return Calendar.current.date(byAdding: .year, value: 2, to: startDate) ?? startDate
        case .adhoc:
            return startDate
        }
    }
    
    private func calculateTrend(frameworkId: String) -> ComplianceTrend {
        // Implementation would analyze historical compliance scores
        return .stable
    }
    
    private func identifyRiskAreas(_ findings: [AuditFinding]) -> [String] {
        return findings.filter { $0.riskLevel == .high || $0.riskLevel == .critical }
                      .map { $0.category }
                      .uniqued()
    }
    
    private func generateGapDescription(findings: [AuditFinding]) -> String {
        if findings.isEmpty { return "No gaps identified" }
        
        let criticalCount = findings.filter { $0.riskLevel == .critical }.count
        let highCount = findings.filter { $0.riskLevel == .high }.count
        
        if criticalCount > 0 {
            return "Critical compliance gaps identified requiring immediate attention"
        } else if highCount > 0 {
            return "High-risk compliance gaps requiring priority remediation"
        } else {
            return "Minor compliance gaps identified"
        }
    }
    
    private func determineGapRiskLevel(findings: [AuditFinding]) -> RiskLevel {
        if findings.contains(where: { $0.riskLevel == .critical }) {
            return .critical
        } else if findings.contains(where: { $0.riskLevel == .high }) {
            return .high
        } else if findings.contains(where: { $0.riskLevel == .medium }) {
            return .medium
        } else {
            return .low
        }
    }
    
    private func determineOverallRisk(gaps: [ComplianceGap]) -> RiskLevel {
        if gaps.contains(where: { $0.riskLevel == .critical }) {
            return .critical
        } else if gaps.contains(where: { $0.riskLevel == .high }) {
            return .high
        } else if gaps.contains(where: { $0.riskLevel == .medium }) {
            return .medium
        } else {
            return .low
        }
    }
    
    private func generateRecommendations(for findings: [AuditFinding]) -> [String] {
        return findings.compactMap { $0.recommendation }.uniqued()
    }
    
    private func generateOverallRecommendations(gaps: [ComplianceGap]) -> [String] {
        var recommendations: [String] = []
        
        let criticalGaps = gaps.filter { $0.riskLevel == .critical }
        if !criticalGaps.isEmpty {
            recommendations.append("Immediately address critical compliance gaps")
            recommendations.append("Implement emergency controls and monitoring")
        }
        
        let highGaps = gaps.filter { $0.riskLevel == .high }
        if !highGaps.isEmpty {
            recommendations.append("Develop remediation plans for high-risk gaps")
            recommendations.append("Increase audit frequency for affected areas")
        }
        
        return recommendations
    }
    
    private func createRemedialAction(
        findingId: String,
        reportId: String,
        createdBy: String
    ) async throws -> RemedialAction {
        let action = RemedialAction(
            id: UUID().uuidString,
            findingId: findingId,
            reportId: reportId,
            title: "Remedial Action Required",
            description: "Address finding identified in audit",
            priority: .high,
            assignedTo: createdBy,
            dueDate: Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date(),
            status: .open,
            createdBy: createdBy,
            createdAt: Date()
        )
        
        try await saveRemedialAction(action)
        return action
    }
    
    private func saveRemedialAction(_ action: RemedialAction) async throws {
        let record = action.toCKRecord()
        try await database.save(record)
    }
    
    private func closeRelatedRemedialActions(findingId: String, closedBy: String) async {
        let relatedActions = remedialActions.filter { $0.findingId == findingId && $0.status != .completed }
        
        for action in relatedActions {
            action.status = .completed
            action.completedBy = closedBy
            action.completedAt = Date()
            
            try? await saveRemedialAction(action)
        }
    }
    
    private func calculateAverageComplianceScore(_ reports: [AuditReport]) -> Double {
        let completedReports = reports.filter { $0.status == .completed }
        guard !completedReports.isEmpty else { return 0 }
        
        let totalScore = completedReports.reduce(0) { $0 + $1.complianceScore }
        return totalScore / Double(completedReports.count)
    }
    
    private func calculateAverageAuditDuration(_ reports: [AuditReport]) -> TimeInterval {
        let completedReports = reports.filter { 
            $0.status == .completed && 
            $0.actualStartDate != nil && 
            $0.actualEndDate != nil 
        }
        
        guard !completedReports.isEmpty else { return 0 }
        
        let totalDuration = completedReports.reduce(0.0) { total, report in
            guard let start = report.actualStartDate,
                  let end = report.actualEndDate else { return total }
            return total + end.timeIntervalSince(start)
        }
        
        return totalDuration / Double(completedReports.count)
    }
    
    private func calculateComplianceByFramework(_ reports: [AuditReport]) -> [String: Double] {
        let frameworkGroups = Dictionary(grouping: reports.filter { $0.status == .completed }) { $0.framework.id }
        
        return frameworkGroups.mapValues { reports in
            let totalScore = reports.reduce(0) { $0 + $1.complianceScore }
            return reports.isEmpty ? 0 : totalScore / Double(reports.count)
        }
    }
    
    private func generateTrendAnalysis(_ reports: [AuditReport]) -> TrendAnalysis {
        // Implementation would analyze trends over time
        return TrendAnalysis(
            complianceScoreTrend: .improving,
            findingsCountTrend: .stable,
            auditDurationTrend: .improving,
            riskLevelTrend: .improving
        )
    }
    
    private func generateRiskHeatMap(_ reports: [AuditReport]) -> RiskHeatMap {
        // Implementation would create risk heat map data
        return RiskHeatMap(
            riskAreas: [],
            riskLevels: [:],
            lastUpdated: Date()
        )
    }
    
    private func generateExecutiveSummary(_ report: AuditReport) -> String {
        return """
        EXECUTIVE SUMMARY
        
        Audit: \(report.auditName)
        Framework: \(report.framework.name)
        Compliance Score: \(String(format: "%.1f", report.complianceScore))%
        
        This audit was conducted to assess compliance with \(report.framework.name) requirements.
        The overall compliance score of \(String(format: "%.1f", report.complianceScore))% indicates 
        \(report.complianceScore >= 80 ? "strong" : report.complianceScore >= 60 ? "adequate" : "insufficient") 
        compliance with the framework requirements.
        """
    }
    
    private func generateDetailedFindings(_ report: AuditReport) -> String {
        let allFindings = report.procedures.flatMap { $0.findings }
        
        if allFindings.isEmpty {
            return "No findings identified during this audit."
        }
        
        var details = "DETAILED FINDINGS\n\n"
        
        for (index, finding) in allFindings.enumerated() {
            details += """
            Finding \(index + 1): \(finding.title)
            Risk Level: \(finding.riskLevel.displayName)
            Category: \(finding.category)
            Description: \(finding.description)
            
            """
        }
        
        return details
    }
    
    private func generateReportRecommendations(_ report: AuditReport) -> String {
        let allFindings = report.procedures.flatMap { $0.findings }
        let recommendations = allFindings.compactMap { $0.recommendation }.uniqued()
        
        if recommendations.isEmpty {
            return "No specific recommendations at this time."
        }
        
        var content = "RECOMMENDATIONS\n\n"
        
        for (index, recommendation) in recommendations.enumerated() {
            content += "\(index + 1). \(recommendation)\n"
        }
        
        return content
    }
    
    private func generateAppendices(_ report: AuditReport) -> [String] {
        return [
            "Appendix A: Audit Methodology",
            "Appendix B: Evidence Documentation",
            "Appendix C: Risk Assessment Matrix"
        ]
    }
    
    private func generateCertificationStatement(_ report: AuditReport) -> String {
        return """
        CERTIFICATION STATEMENT
        
        We certify that this audit was conducted in accordance with applicable auditing standards
        and that the findings and conclusions presented in this report are based on sufficient
        appropriate audit evidence.
        
        Audit Team Lead: [Auditor Name]
        Date: \(DateFormatter.medium.string(from: Date()))
        """
    }
    
    // MARK: - Notification Methods
    
    private func scheduleAuditNotifications(_ report: AuditReport) async {
        let center = UNUserNotificationCenter.current()
        
        // Reminder 1 day before planned start
        if let reminderDate = Calendar.current.date(byAdding: .day, value: -1, to: report.plannedStartDate) {
            let content = UNMutableNotificationContent()
            content.title = "Audit Reminder"
            content.body = "Audit '\(report.auditName)' is scheduled to start tomorrow"
            content.sound = .default
            
            let trigger = UNCalendarNotificationTrigger(
                dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate),
                repeats: false
            )
            
            let request = UNNotificationRequest(identifier: "audit-reminder-\(report.id)", content: content, trigger: trigger)
            try? await center.add(request)
        }
    }
    
    private func scheduleRecurringNotifications(_ schedule: AuditSchedule) async {
        // Implementation for recurring audit notifications
    }
    
    private func sendStatusChangeNotification(_ report: AuditReport, previousStatus: AuditStatus) async {
        // Implementation for status change notifications
    }
    
    private func sendFindingNotification(_ finding: AuditFinding, reportId: String) async {
        // Implementation for finding notifications
    }
    
    // MARK: - Logging
    
    private func logAuditActivity(
        _ activity: AuditActivity,
        templateId: String?,
        userId: String,
        details: String
    ) async {
        let log = AuditActivityLog(
            id: UUID().uuidString,
            activity: activity,
            templateId: templateId,
            userId: userId,
            details: details,
            timestamp: Date()
        )
        
        // Save audit activity log
        try? await saveAuditActivityLog(log)
    }
    
    private func saveAuditActivityLog(_ log: AuditActivityLog) async throws {
        let record = log.toCKRecord()
        try await database.save(record)
    }
    
    private func handleError(_ error: AuditError) async {
        await MainActor.run {
            self.error = error
        }
    }
    
    // MARK: - Template Creation Methods
    
    private func createISO27001Template() -> AuditTemplate {
        return AuditTemplate(
            id: "iso27001-template",
            name: "ISO 27001 Information Security Management",
            description: "Comprehensive audit template for ISO 27001 compliance",
            framework: complianceFrameworks.first { $0.id == "iso27001" } ?? ComplianceFramework.default,
            auditType: .compliance,
            scope: .organizational,
            controlObjectives: createISO27001ControlObjectives(),
            procedures: createISO27001Procedures(),
            riskAreas: [
                RiskArea(id: "access-control", name: "Access Control", description: "User access management"),
                RiskArea(id: "data-protection", name: "Data Protection", description: "Information security"),
                RiskArea(id: "incident-response", name: "Incident Response", description: "Security incident handling")
            ],
            frequency: .annual,
            createdBy: "system",
            createdAt: Date(),
            version: "1.0",
            isActive: true
        )
    }
    
    private func createSOXTemplate() -> AuditTemplate {
        return AuditTemplate(
            id: "sox-template",
            name: "Sarbanes-Oxley Compliance Audit",
            description: "Financial controls and reporting audit template",
            framework: complianceFrameworks.first { $0.id == "sox" } ?? ComplianceFramework.default,
            auditType: .financial,
            scope: .financial,
            controlObjectives: createSOXControlObjectives(),
            procedures: createSOXProcedures(),
            riskAreas: [
                RiskArea(id: "financial-reporting", name: "Financial Reporting", description: "Accuracy of financial statements"),
                RiskArea(id: "internal-controls", name: "Internal Controls", description: "Control effectiveness"),
                RiskArea(id: "disclosure", name: "Disclosure", description: "Material disclosure requirements")
            ],
            frequency: .annual,
            createdBy: "system",
            createdAt: Date(),
            version: "1.0",
            isActive: true
        )
    }
    
    private func createGDPRTemplate() -> AuditTemplate {
        return AuditTemplate(
            id: "gdpr-template",
            name: "GDPR Privacy Compliance Audit",
            description: "Data protection and privacy audit template",
            framework: complianceFrameworks.first { $0.id == "gdpr" } ?? ComplianceFramework.default,
            auditType: .compliance,
            scope: .dataProtection,
            controlObjectives: createGDPRControlObjectives(),
            procedures: createGDPRProcedures(),
            riskAreas: [
                RiskArea(id: "data-processing", name: "Data Processing", description: "Lawful processing of personal data"),
                RiskArea(id: "consent", name: "Consent Management", description: "Consent collection and management"),
                RiskArea(id: "data-rights", name: "Data Subject Rights", description: "Individual rights compliance")
            ],
            frequency: .annual,
            createdBy: "system",
            createdAt: Date(),
            version: "1.0",
            isActive: true
        )
    }
    
    private func createInternalControlsTemplate() -> AuditTemplate {
        return AuditTemplate(
            id: "internal-controls-template",
            name: "Internal Controls Assessment",
            description: "Operational and financial internal controls audit",
            framework: ComplianceFramework.default,
            auditType: .operational,
            scope: .operational,
            controlObjectives: createInternalControlObjectives(),
            procedures: createInternalControlProcedures(),
            riskAreas: [
                RiskArea(id: "segregation-duties", name: "Segregation of Duties", description: "Proper segregation of responsibilities"),
                RiskArea(id: "authorization", name: "Authorization Controls", description: "Approval processes"),
                RiskArea(id: "documentation", name: "Documentation", description: "Process documentation and evidence")
            ],
            frequency: .quarterly,
            createdBy: "system",
            createdAt: Date(),
            version: "1.0",
            isActive: true
        )
    }
    
    // MARK: - Control Objectives and Procedures Creation
    
    private func createISO27001ControlObjectives() -> [ControlObjective] {
        return [
            ControlObjective(
                id: "iso-access-1",
                title: "Access Control Management",
                description: "Ensure appropriate access controls are implemented",
                category: "Access Control",
                riskLevel: .high
            ),
            ControlObjective(
                id: "iso-info-1",
                title: "Information Classification",
                description: "Ensure information is properly classified and protected",
                category: "Information Security",
                riskLevel: .medium
            )
        ]
    }
    
    private func createISO27001Procedures() -> [AuditProcedure] {
        return [
            AuditProcedure(
                id: "iso-proc-1",
                controlObjectiveId: "iso-access-1",
                title: "Review User Access Controls",
                description: "Review and test user access control mechanisms",
                steps: [
                    "Review access control policy",
                    "Test user authentication mechanisms",
                    "Verify privileged access controls",
                    "Document findings"
                ],
                evidenceRequired: ["Access control policy", "User access reports", "Authentication logs"],
                estimatedHours: 4.0
            )
        ]
    }
    
    private func createSOXControlObjectives() -> [ControlObjective] {
        return [
            ControlObjective(
                id: "sox-financial-1",
                title: "Financial Reporting Accuracy",
                description: "Ensure accuracy of financial reporting",
                category: "Financial Reporting",
                riskLevel: .critical
            )
        ]
    }
    
    private func createSOXProcedures() -> [AuditProcedure] {
        return [
            AuditProcedure(
                id: "sox-proc-1",
                controlObjectiveId: "sox-financial-1",
                title: "Test Financial Controls",
                description: "Test key financial reporting controls",
                steps: [
                    "Review financial close process",
                    "Test journal entry controls",
                    "Verify management review controls",
                    "Document control deficiencies"
                ],
                evidenceRequired: ["Financial statements", "Journal entries", "Management reviews"],
                estimatedHours: 8.0
            )
        ]
    }
    
    private func createGDPRControlObjectives() -> [ControlObjective] {
        return [
            ControlObjective(
                id: "gdpr-data-1",
                title: "Data Processing Compliance",
                description: "Ensure lawful processing of personal data",
                category: "Data Protection",
                riskLevel: .high
            )
        ]
    }
    
    private func createGDPRProcedures() -> [AuditProcedure] {
        return [
            AuditProcedure(
                id: "gdpr-proc-1",
                controlObjectiveId: "gdpr-data-1",
                title: "Review Data Processing Activities",
                description: "Review data processing lawfulness and documentation",
                steps: [
                    "Review data processing register",
                    "Verify legal basis for processing",
                    "Check consent mechanisms",
                    "Assess data retention policies"
                ],
                evidenceRequired: ["Data processing register", "Consent records", "Privacy policies"],
                estimatedHours: 6.0
            )
        ]
    }
    
    private func createInternalControlObjectives() -> [ControlObjective] {
        return [
            ControlObjective(
                id: "ic-segregation-1",
                title: "Segregation of Duties",
                description: "Ensure proper segregation of duties in key processes",
                category: "Internal Controls",
                riskLevel: .high
            )
        ]
    }
    
    private func createInternalControlProcedures() -> [AuditProcedure] {
        return [
            AuditProcedure(
                id: "ic-proc-1",
                controlObjectiveId: "ic-segregation-1",
                title: "Test Segregation of Duties",
                description: "Test segregation of duties in key business processes",
                steps: [
                    "Map key business processes",
                    "Identify critical duties and responsibilities",
                    "Test for proper segregation",
                    "Document any conflicts"
                ],
                evidenceRequired: ["Process documentation", "Role definitions", "User access reports"],
                estimatedHours: 3.0
            )
        ]
    }
    
    // MARK: - Requirements Creation
    
    private func createISO27001Requirements() -> [RegulatoryRequirement] {
        return [
            RegulatoryRequirement(
                id: "iso-req-1",
                title: "A.9.1.1 Access control policy",
                description: "An access control policy shall be established, documented and reviewed",
                category: "Access Control",
                mandatory: true
            )
        ]
    }
    
    private func createSOXRequirements() -> [RegulatoryRequirement] {
        return [
            RegulatoryRequirement(
                id: "sox-req-1",
                title: "Section 302 - Corporate Responsibility",
                description: "CEO and CFO must certify financial reports",
                category: "Management Certification",
                mandatory: true
            )
        ]
    }
    
    private func createGDPRRequirements() -> [RegulatoryRequirement] {
        return [
            RegulatoryRequirement(
                id: "gdpr-req-1",
                title: "Article 6 - Lawfulness of processing",
                description: "Processing shall be lawful only if at least one legal basis applies",
                category: "Legal Basis",
                mandatory: true
            )
        ]
    }
    
    private func createHIPAARequirements() -> [RegulatoryRequirement] {
        return [
            RegulatoryRequirement(
                id: "hipaa-req-1",
                title: "164.306 Security Standards",
                description: "Implement administrative, physical, and technical safeguards",
                category: "Security",
                mandatory: true
            )
        ]
    }
}

// MARK: - Array Extension

extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}
