//
//  AuditModels.swift
//  DiamondDeskERP
//
//  Created by J.Michael McDermott on 7/20/25.
//

import Foundation
import CloudKit
import SwiftUI

// MARK: - Core Audit Models

class AuditTemplate: ObservableObject, Identifiable {
    let id: String
    @Published var name: String
    @Published var description: String
    let framework: ComplianceFramework
    let auditType: AuditType
    let scope: AuditScope
    @Published var controlObjectives: [ControlObjective]
    @Published var procedures: [AuditProcedure]
    @Published var riskAreas: [RiskArea]
    let frequency: AuditFrequency
    let createdBy: String
    let createdAt: Date
    @Published var modifiedBy: String?
    @Published var modifiedAt: Date?
    @Published var version: String
    @Published var isActive: Bool
    
    init(
        id: String,
        name: String,
        description: String,
        framework: ComplianceFramework,
        auditType: AuditType,
        scope: AuditScope,
        controlObjectives: [ControlObjective],
        procedures: [AuditProcedure],
        riskAreas: [RiskArea],
        frequency: AuditFrequency,
        createdBy: String,
        createdAt: Date,
        version: String,
        isActive: Bool
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.framework = framework
        self.auditType = auditType
        self.scope = scope
        self.controlObjectives = controlObjectives
        self.procedures = procedures
        self.riskAreas = riskAreas
        self.frequency = frequency
        self.createdBy = createdBy
        self.createdAt = createdAt
        self.version = version
        self.isActive = isActive
    }
    
    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: "AuditTemplate", recordID: CKRecord.ID(recordName: id))
        record["name"] = name
        record["description"] = description
        record["framework"] = try? JSONEncoder().encode(framework)
        record["auditType"] = auditType.rawValue
        record["scope"] = scope.rawValue
        record["controlObjectives"] = try? JSONEncoder().encode(controlObjectives)
        record["procedures"] = try? JSONEncoder().encode(procedures)
        record["riskAreas"] = try? JSONEncoder().encode(riskAreas)
        record["frequency"] = frequency.rawValue
        record["createdBy"] = createdBy
        record["createdAt"] = createdAt
        record["modifiedBy"] = modifiedBy
        record["modifiedAt"] = modifiedAt
        record["version"] = version
        record["isActive"] = isActive
        return record
    }
}

class AuditReport: ObservableObject, Identifiable {
    let id: String
    let templateId: String
    @Published var auditName: String
    let auditeeId: String
    let framework: ComplianceFramework
    let auditType: AuditType
    let scope: AuditScope
    let plannedStartDate: Date
    let plannedEndDate: Date
    @Published var actualStartDate: Date?
    @Published var actualEndDate: Date?
    let auditorIds: [String]
    @Published var status: AuditStatus
    let executedBy: String
    let createdAt: Date
    @Published var modifiedBy: String?
    @Published var modifiedAt: Date?
    @Published var controlObjectives: [ControlObjective]
    @Published var procedures: [ExecutedProcedure]
    @Published var overallRating: AuditRating
    @Published var complianceScore: Double
    @Published var statusNotes: [AuditNote]
    
    init(
        id: String,
        templateId: String,
        auditName: String,
        auditeeId: String,
        framework: ComplianceFramework,
        auditType: AuditType,
        scope: AuditScope,
        plannedStartDate: Date,
        plannedEndDate: Date,
        actualStartDate: Date?,
        actualEndDate: Date?,
        auditorIds: [String],
        status: AuditStatus,
        executedBy: String,
        createdAt: Date,
        controlObjectives: [ControlObjective],
        procedures: [ExecutedProcedure],
        overallRating: AuditRating,
        complianceScore: Double
    ) {
        self.id = id
        self.templateId = templateId
        self.auditName = auditName
        self.auditeeId = auditeeId
        self.framework = framework
        self.auditType = auditType
        self.scope = scope
        self.plannedStartDate = plannedStartDate
        self.plannedEndDate = plannedEndDate
        self.actualStartDate = actualStartDate
        self.actualEndDate = actualEndDate
        self.auditorIds = auditorIds
        self.status = status
        self.executedBy = executedBy
        self.createdAt = createdAt
        self.controlObjectives = controlObjectives
        self.procedures = procedures
        self.overallRating = overallRating
        self.complianceScore = complianceScore
        self.statusNotes = []
    }
    
    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: "AuditReport", recordID: CKRecord.ID(recordName: id))
        record["templateId"] = templateId
        record["auditName"] = auditName
        record["auditeeId"] = auditeeId
        record["framework"] = try? JSONEncoder().encode(framework)
        record["auditType"] = auditType.rawValue
        record["scope"] = scope.rawValue
        record["plannedStartDate"] = plannedStartDate
        record["plannedEndDate"] = plannedEndDate
        record["actualStartDate"] = actualStartDate
        record["actualEndDate"] = actualEndDate
        record["auditorIds"] = auditorIds
        record["status"] = status.rawValue
        record["executedBy"] = executedBy
        record["createdAt"] = createdAt
        record["modifiedBy"] = modifiedBy
        record["modifiedAt"] = modifiedAt
        record["controlObjectives"] = try? JSONEncoder().encode(controlObjectives)
        record["procedures"] = try? JSONEncoder().encode(procedures)
        record["overallRating"] = overallRating.rawValue
        record["complianceScore"] = complianceScore
        record["statusNotes"] = try? JSONEncoder().encode(statusNotes)
        return record
    }
}

struct ComplianceFramework: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let version: String
    let requirements: [RegulatoryRequirement]
    let certificationBody: String
    let isActive: Bool
    
    static let `default` = ComplianceFramework(
        id: "default",
        name: "Generic Framework",
        description: "Default compliance framework",
        version: "1.0",
        requirements: [],
        certificationBody: "Internal",
        isActive: true
    )
}

struct ControlObjective: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let category: String
    let riskLevel: RiskLevel
}

struct AuditProcedure: Codable, Identifiable {
    let id: String
    let controlObjectiveId: String
    let title: String
    let description: String
    let steps: [String]
    let evidenceRequired: [String]
    let estimatedHours: Double
}

struct ExecutedProcedure: Codable, Identifiable {
    let id = UUID().uuidString
    let procedure: AuditProcedure
    var status: ProcedureStatus
    var assignedTo: String
    var evidence: [AuditEvidence]
    var findings: [AuditFinding]
    var notes: String
    var completedAt: Date?
    var actualHours: Double?
}

struct AuditFinding: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let category: String
    let riskLevel: RiskLevel
    let controlObjectiveIds: [String]
    var status: FindingStatus
    let identifiedBy: String
    let identifiedAt: Date
    var resolution: String?
    var resolvedBy: String?
    var resolvedAt: Date?
    let recommendation: String?
    
    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: "AuditFinding", recordID: CKRecord.ID(recordName: id))
        record["title"] = title
        record["description"] = description
        record["category"] = category
        record["riskLevel"] = riskLevel.rawValue
        record["controlObjectiveIds"] = controlObjectiveIds
        record["status"] = status.rawValue
        record["identifiedBy"] = identifiedBy
        record["identifiedAt"] = identifiedAt
        record["resolution"] = resolution
        record["resolvedBy"] = resolvedBy
        record["resolvedAt"] = resolvedAt
        record["recommendation"] = recommendation
        return record
    }
}

struct AuditEvidence: Codable, Identifiable {
    let id: String
    let type: EvidenceType
    let title: String
    let description: String
    let fileURL: URL?
    let collectedBy: String
    let collectedAt: Date
    let hash: String?
}

struct AuditNote: Codable, Identifiable {
    let id: String
    let content: String
    let createdBy: String
    let createdAt: Date
    let type: NoteType
}

struct RiskArea: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
}

struct AuditSchedule: Codable, Identifiable {
    let id: String
    let templateId: String
    let frequency: AuditFrequency
    let startDate: Date
    var nextAuditDate: Date
    let auditeeId: String
    let auditorIds: [String]
    var isActive: Bool
    let scheduledBy: String
    let createdAt: Date
    
    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: "AuditSchedule", recordID: CKRecord.ID(recordName: id))
        record["templateId"] = templateId
        record["frequency"] = frequency.rawValue
        record["startDate"] = startDate
        record["nextAuditDate"] = nextAuditDate
        record["auditeeId"] = auditeeId
        record["auditorIds"] = auditorIds
        record["isActive"] = isActive
        record["scheduledBy"] = scheduledBy
        record["createdAt"] = createdAt
        return record
    }
}

class RemedialAction: ObservableObject, Identifiable {
    let id: String
    let findingId: String
    let reportId: String
    @Published var title: String
    @Published var description: String
    @Published var priority: ActionPriority
    @Published var assignedTo: String
    @Published var dueDate: Date
    @Published var status: ActionStatus
    let createdBy: String
    let createdAt: Date
    @Published var completedBy: String?
    @Published var completedAt: Date?
    @Published var notes: String?
    
    init(
        id: String,
        findingId: String,
        reportId: String,
        title: String,
        description: String,
        priority: ActionPriority,
        assignedTo: String,
        dueDate: Date,
        status: ActionStatus,
        createdBy: String,
        createdAt: Date
    ) {
        self.id = id
        self.findingId = findingId
        self.reportId = reportId
        self.title = title
        self.description = description
        self.priority = priority
        self.assignedTo = assignedTo
        self.dueDate = dueDate
        self.status = status
        self.createdBy = createdBy
        self.createdAt = createdAt
    }
    
    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: "RemedialAction", recordID: CKRecord.ID(recordName: id))
        record["findingId"] = findingId
        record["reportId"] = reportId
        record["title"] = title
        record["description"] = description
        record["priority"] = priority.rawValue
        record["assignedTo"] = assignedTo
        record["dueDate"] = dueDate
        record["status"] = status.rawValue
        record["createdBy"] = createdBy
        record["createdAt"] = createdAt
        record["completedBy"] = completedBy
        record["completedAt"] = completedAt
        record["notes"] = notes
        return record
    }
}

struct RegulatoryRequirement: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let category: String
    let mandatory: Bool
}

// MARK: - Compliance Models

struct ComplianceScore: Codable {
    let frameworkId: String
    let score: Double
    let lastAssessment: Date
    let trend: ComplianceTrend
    let riskAreas: [String]
}

struct ComplianceGap: Codable, Identifiable {
    let id: String
    let frameworkId: String
    let requirementId: String
    let requirementTitle: String
    let gapDescription: String
    let riskLevel: RiskLevel
    let identifiedAt: Date
    var status: GapStatus
    let recommendations: [String]
}

struct ComplianceGapAnalysis: Codable, Identifiable {
    let id: String
    let frameworkId: String
    let generatedAt: Date
    let totalRequirements: Int
    let compliantRequirements: Int
    let gaps: [ComplianceGap]
    let overallRiskLevel: RiskLevel
    let recommendedActions: [String]
}

// MARK: - Reporting Models

struct ComprehensiveAuditReport: Codable, Identifiable {
    let id: String
    let auditReport: AuditReport
    let generatedAt: Date
    let format: ReportFormat
    let executiveSummary: String?
    let detailedFindings: String?
    let recommendations: String?
    let appendices: [String]
    let certificationStatement: String
    
    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: "ComprehensiveAuditReport", recordID: CKRecord.ID(recordName: id))
        record["auditReport"] = try? JSONEncoder().encode(auditReport)
        record["generatedAt"] = generatedAt
        record["format"] = format.rawValue
        record["executiveSummary"] = executiveSummary
        record["detailedFindings"] = detailedFindings
        record["recommendations"] = recommendations
        record["appendices"] = appendices
        record["certificationStatement"] = certificationStatement
        return record
    }
}

// MARK: - Analytics Models

struct AuditMetrics: Codable {
    let totalAudits: Int
    let completedAudits: Int
    let inProgressAudits: Int
    let plannedAudits: Int
    let averageComplianceScore: Double
    let totalFindings: Int
    let criticalFindings: Int
    let resolvedFindings: Int
    let averageAuditDuration: TimeInterval
    let complianceByFramework: [String: Double]
}

struct TrendAnalysis: Codable {
    let complianceScoreTrend: TrendDirection
    let findingsCountTrend: TrendDirection
    let auditDurationTrend: TrendDirection
    let riskLevelTrend: TrendDirection
}

struct RiskHeatMap: Codable {
    let riskAreas: [RiskHeatMapArea]
    let riskLevels: [String: RiskLevel]
    let lastUpdated: Date
}

struct RiskHeatMapArea: Codable, Identifiable {
    let id: String
    let name: String
    let riskLevel: RiskLevel
    let findingsCount: Int
}

struct BenchmarkData: Codable {
    let industryAverageCompliance: Double
    let peerComparisonScore: Double
    let bestPracticeGap: Double
    let industryRanking: Int
}

// MARK: - Activity Logging

struct AuditActivityLog: Codable, Identifiable {
    let id: String
    let activity: AuditActivity
    let templateId: String?
    let userId: String
    let details: String
    let timestamp: Date
    
    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: "AuditActivityLog", recordID: CKRecord.ID(recordName: id))
        record["activity"] = activity.rawValue
        record["templateId"] = templateId
        record["userId"] = userId
        record["details"] = details
        record["timestamp"] = timestamp
        return record
    }
}

struct CertificationStatus: Codable, Identifiable {
    let id: String
    let frameworkId: String
    let status: CertificationState
    let issueDate: Date?
    let expiryDate: Date?
    let certifyingBody: String?
    let certificateNumber: String?
}

// MARK: - Enums

enum AuditType: String, CaseIterable, Codable {
    case compliance = "compliance"
    case financial = "financial"
    case operational = "operational"
    case security = "security"
    case performance = "performance"
    case quality = "quality"
    case environmental = "environmental"
    case safety = "safety"
    
    var displayName: String {
        switch self {
        case .compliance: return "Compliance"
        case .financial: return "Financial"
        case .operational: return "Operational"
        case .security: return "Security"
        case .performance: return "Performance"
        case .quality: return "Quality"
        case .environmental: return "Environmental"
        case .safety: return "Safety"
        }
    }
    
    var icon: String {
        switch self {
        case .compliance: return "checkmark.shield"
        case .financial: return "dollarsign.circle"
        case .operational: return "gearshape"
        case .security: return "lock.shield"
        case .performance: return "speedometer"
        case .quality: return "star.circle"
        case .environmental: return "leaf"
        case .safety: return "shield.lefthalf.filled"
        }
    }
}

enum AuditScope: String, CaseIterable, Codable {
    case organizational = "organizational"
    case departmental = "departmental"
    case process = "process"
    case system = "system"
    case project = "project"
    case financial = "financial"
    case dataProtection = "data_protection"
    case operational = "operational"
    
    var displayName: String {
        switch self {
        case .organizational: return "Organizational"
        case .departmental: return "Departmental"
        case .process: return "Process"
        case .system: return "System"
        case .project: return "Project"
        case .financial: return "Financial"
        case .dataProtection: return "Data Protection"
        case .operational: return "Operational"
        }
    }
}

enum AuditFrequency: String, CaseIterable, Codable {
    case monthly = "monthly"
    case quarterly = "quarterly"
    case semiAnnual = "semi_annual"
    case annual = "annual"
    case biennial = "biennial"
    case adhoc = "adhoc"
    
    var displayName: String {
        switch self {
        case .monthly: return "Monthly"
        case .quarterly: return "Quarterly"
        case .semiAnnual: return "Semi-Annual"
        case .annual: return "Annual"
        case .biennial: return "Biennial"
        case .adhoc: return "Ad-hoc"
        }
    }
}

enum AuditStatus: String, CaseIterable, Codable {
    case planned = "planned"
    case inProgress = "in_progress"
    case completed = "completed"
    case cancelled = "cancelled"
    case onHold = "on_hold"
    case draft = "draft"
    
    var displayName: String {
        switch self {
        case .planned: return "Planned"
        case .inProgress: return "In Progress"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        case .onHold: return "On Hold"
        case .draft: return "Draft"
        }
    }
    
    var color: Color {
        switch self {
        case .planned: return .blue
        case .inProgress: return .orange
        case .completed: return .green
        case .cancelled: return .red
        case .onHold: return .yellow
        case .draft: return .gray
        }
    }
}

enum ProcedureStatus: String, CaseIterable, Codable {
    case notStarted = "not_started"
    case inProgress = "in_progress"
    case completed = "completed"
    case skipped = "skipped"
    case blocked = "blocked"
    
    var displayName: String {
        switch self {
        case .notStarted: return "Not Started"
        case .inProgress: return "In Progress"
        case .completed: return "Completed"
        case .skipped: return "Skipped"
        case .blocked: return "Blocked"
        }
    }
    
    var color: Color {
        switch self {
        case .notStarted: return .gray
        case .inProgress: return .blue
        case .completed: return .green
        case .skipped: return .yellow
        case .blocked: return .red
        }
    }
}

enum FindingStatus: String, CaseIterable, Codable {
    case open = "open"
    case inRemediation = "in_remediation"
    case resolved = "resolved"
    case closed = "closed"
    case disputed = "disputed"
    
    var displayName: String {
        switch self {
        case .open: return "Open"
        case .inRemediation: return "In Remediation"
        case .resolved: return "Resolved"
        case .closed: return "Closed"
        case .disputed: return "Disputed"
        }
    }
    
    var color: Color {
        switch self {
        case .open: return .red
        case .inRemediation: return .orange
        case .resolved: return .green
        case .closed: return .gray
        case .disputed: return .purple
        }
    }
}

enum RiskLevel: String, CaseIterable, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
    
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .critical: return "Critical"
        }
    }
    
    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .orange
        case .critical: return .red
        }
    }
    
    var priority: Int {
        switch self {
        case .low: return 1
        case .medium: return 2
        case .high: return 3
        case .critical: return 4
        }
    }
}

enum AuditRating: String, CaseIterable, Codable {
    case excellent = "excellent"
    case good = "good"
    case satisfactory = "satisfactory"
    case needsImprovement = "needs_improvement"
    case unsatisfactory = "unsatisfactory"
    case notAssessed = "not_assessed"
    
    var displayName: String {
        switch self {
        case .excellent: return "Excellent"
        case .good: return "Good"
        case .satisfactory: return "Satisfactory"
        case .needsImprovement: return "Needs Improvement"
        case .unsatisfactory: return "Unsatisfactory"
        case .notAssessed: return "Not Assessed"
        }
    }
    
    var color: Color {
        switch self {
        case .excellent: return .green
        case .good: return .blue
        case .satisfactory: return .yellow
        case .needsImprovement: return .orange
        case .unsatisfactory: return .red
        case .notAssessed: return .gray
        }
    }
}

enum EvidenceType: String, CaseIterable, Codable {
    case document = "document"
    case screenshot = "screenshot"
    case interview = "interview"
    case observation = "observation"
    case systemOutput = "system_output"
    case sample = "sample"
    case photo = "photo"
    case video = "video"
    
    var displayName: String {
        switch self {
        case .document: return "Document"
        case .screenshot: return "Screenshot"
        case .interview: return "Interview"
        case .observation: return "Observation"
        case .systemOutput: return "System Output"
        case .sample: return "Sample"
        case .photo: return "Photo"
        case .video: return "Video"
        }
    }
    
    var icon: String {
        switch self {
        case .document: return "doc.text"
        case .screenshot: return "camera.viewfinder"
        case .interview: return "person.2.wave.2"
        case .observation: return "eye"
        case .systemOutput: return "terminal"
        case .sample: return "square.grid.3x3"
        case .photo: return "photo"
        case .video: return "video"
        }
    }
}

enum NoteType: String, CaseIterable, Codable {
    case general = "general"
    case statusChange = "status_change"
    case finding = "finding"
    case recommendation = "recommendation"
    case followUp = "follow_up"
    
    var displayName: String {
        switch self {
        case .general: return "General"
        case .statusChange: return "Status Change"
        case .finding: return "Finding"
        case .recommendation: return "Recommendation"
        case .followUp: return "Follow Up"
        }
    }
}

enum ActionPriority: String, CaseIterable, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case urgent = "urgent"
    
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .urgent: return "Urgent"
        }
    }
    
    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .orange
        case .urgent: return .red
        }
    }
}

enum ActionStatus: String, CaseIterable, Codable {
    case open = "open"
    case inProgress = "in_progress"
    case completed = "completed"
    case cancelled = "cancelled"
    case overdue = "overdue"
    
    var displayName: String {
        switch self {
        case .open: return "Open"
        case .inProgress: return "In Progress"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        case .overdue: return "Overdue"
        }
    }
    
    var color: Color {
        switch self {
        case .open: return .blue
        case .inProgress: return .orange
        case .completed: return .green
        case .cancelled: return .gray
        case .overdue: return .red
        }
    }
}

enum ComplianceTrend: String, CaseIterable, Codable {
    case improving = "improving"
    case stable = "stable"
    case declining = "declining"
    
    var displayName: String {
        switch self {
        case .improving: return "Improving"
        case .stable: return "Stable"
        case .declining: return "Declining"
        }
    }
    
    var color: Color {
        switch self {
        case .improving: return .green
        case .stable: return .blue
        case .declining: return .red
        }
    }
    
    var icon: String {
        switch self {
        case .improving: return "arrow.up.right"
        case .stable: return "arrow.right"
        case .declining: return "arrow.down.right"
        }
    }
}

enum GapStatus: String, CaseIterable, Codable {
    case open = "open"
    case inRemediation = "in_remediation"
    case closed = "closed"
    case accepted = "accepted"
    
    var displayName: String {
        switch self {
        case .open: return "Open"
        case .inRemediation: return "In Remediation"
        case .closed: return "Closed"
        case .accepted: return "Accepted"
        }
    }
}

enum TrendDirection: String, CaseIterable, Codable {
    case up = "up"
    case down = "down"
    case stable = "stable"
    
    var displayName: String {
        switch self {
        case .up: return "Up"
        case .down: return "Down"
        case .stable: return "Stable"
        }
    }
    
    var icon: String {
        switch self {
        case .up: return "arrow.up"
        case .down: return "arrow.down"
        case .stable: return "arrow.right"
        }
    }
}

enum ReportFormat: String, CaseIterable, Codable {
    case pdf = "pdf"
    case word = "word"
    case html = "html"
    case excel = "excel"
    
    var displayName: String {
        switch self {
        case .pdf: return "PDF"
        case .word: return "Word Document"
        case .html: return "HTML"
        case .excel: return "Excel Spreadsheet"
        }
    }
}

enum AuditActivity: String, CaseIterable, Codable {
    case templateCreated = "template_created"
    case templateUpdated = "template_updated"
    case auditExecuted = "audit_executed"
    case statusChanged = "status_changed"
    case findingAdded = "finding_added"
    case findingUpdated = "finding_updated"
    case scheduleCreated = "schedule_created"
    
    var displayName: String {
        switch self {
        case .templateCreated: return "Template Created"
        case .templateUpdated: return "Template Updated"
        case .auditExecuted: return "Audit Executed"
        case .statusChanged: return "Status Changed"
        case .findingAdded: return "Finding Added"
        case .findingUpdated: return "Finding Updated"
        case .scheduleCreated: return "Schedule Created"
        }
    }
}

enum CertificationState: String, CaseIterable, Codable {
    case notCertified = "not_certified"
    case inProgress = "in_progress"
    case certified = "certified"
    case expired = "expired"
    case suspended = "suspended"
    
    var displayName: String {
        switch self {
        case .notCertified: return "Not Certified"
        case .inProgress: return "In Progress"
        case .certified: return "Certified"
        case .expired: return "Expired"
        case .suspended: return "Suspended"
        }
    }
    
    var color: Color {
        switch self {
        case .notCertified: return .gray
        case .inProgress: return .blue
        case .certified: return .green
        case .expired: return .red
        case .suspended: return .orange
        }
    }
}

// MARK: - Error Types

enum AuditError: LocalizedError {
    case templateCreationFailed(Error)
    case templateUpdateFailed(Error)
    case templateNotFound
    case auditExecutionFailed(Error)
    case auditReportNotFound
    case statusUpdateFailed(Error)
    case procedureNotFound
    case findingCreationFailed(Error)
    case findingUpdateFailed(Error)
    case findingNotFound
    case frameworkNotFound
    case gapAnalysisFailed(Error)
    case reportGenerationFailed(Error)
    case metricsGenerationFailed(Error)
    case scheduleCreationFailed(Error)
    case loadFailed(Error)
    case invalidTemplateName
    case missingControlObjectives
    case missingProcedures
    case invalidProcedureMapping
    
    var errorDescription: String? {
        switch self {
        case .templateCreationFailed(let error):
            return "Failed to create audit template: \(error.localizedDescription)"
        case .templateUpdateFailed(let error):
            return "Failed to update audit template: \(error.localizedDescription)"
        case .templateNotFound:
            return "Audit template not found"
        case .auditExecutionFailed(let error):
            return "Failed to execute audit: \(error.localizedDescription)"
        case .auditReportNotFound:
            return "Audit report not found"
        case .statusUpdateFailed(let error):
            return "Failed to update audit status: \(error.localizedDescription)"
        case .procedureNotFound:
            return "Audit procedure not found"
        case .findingCreationFailed(let error):
            return "Failed to create audit finding: \(error.localizedDescription)"
        case .findingUpdateFailed(let error):
            return "Failed to update audit finding: \(error.localizedDescription)"
        case .findingNotFound:
            return "Audit finding not found"
        case .frameworkNotFound:
            return "Compliance framework not found"
        case .gapAnalysisFailed(let error):
            return "Failed to generate gap analysis: \(error.localizedDescription)"
        case .reportGenerationFailed(let error):
            return "Failed to generate audit report: \(error.localizedDescription)"
        case .metricsGenerationFailed(let error):
            return "Failed to generate audit metrics: \(error.localizedDescription)"
        case .scheduleCreationFailed(let error):
            return "Failed to create audit schedule: \(error.localizedDescription)"
        case .loadFailed(let error):
            return "Failed to load audit data: \(error.localizedDescription)"
        case .invalidTemplateName:
            return "Template name is required"
        case .missingControlObjectives:
            return "At least one control objective is required"
        case .missingProcedures:
            return "At least one audit procedure is required"
        case .invalidProcedureMapping:
            return "All procedures must be mapped to valid control objectives"
        }
    }
}

// MARK: - Extensions

extension DateFormatter {
    static let auditDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}

#Preview {
    Text("Audit Models Preview")
}
