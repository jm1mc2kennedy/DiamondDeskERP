import Foundation
import CloudKit

/// CRM Intake report for customer lead processing and conversion tracking
public struct CRMIntakeReport: Identifiable, Codable {
    public let id: CKRecord.ID
    public let storeCode: String
    public let reportPeriod: ReportPeriod
    public let startDate: Date
    public let endDate: Date
    public let generatedBy: CKRecord.Reference
    public let generatedByName: String
    public let generatedAt: Date
    public let status: ReportStatus
    public let totalLeads: Int
    public let qualifiedLeads: Int
    public let convertedLeads: Int
    public let conversionRate: Double
    public let averageLeadValue: Double?
    public let totalRevenue: Double
    public let leadSources: [LeadSourceData]
    public let stageAnalysis: StageAnalysis
    public let teamPerformance: [TeamMemberPerformance]
    public let followUpMetrics: FollowUpMetrics
    public let qualityScores: QualityScores
    public let actionItems: [String]
    public let notes: String?
    public let isActive: Bool
    public let createdAt: Date
    public let updatedAt: Date
    
    public enum ReportPeriod: String, CaseIterable, Codable {
        case daily = "daily"
        case weekly = "weekly"
        case monthly = "monthly"
        case quarterly = "quarterly"
        
        public var displayName: String {
            switch self {
            case .daily: return "Daily"
            case .weekly: return "Weekly"
            case .monthly: return "Monthly"
            case .quarterly: return "Quarterly"
            }
        }
    }
    
    public enum ReportStatus: String, CaseIterable, Codable {
        case generating = "generating"
        case completed = "completed"
        case failed = "failed"
        
        public var displayName: String {
            switch self {
            case .generating: return "Generating"
            case .completed: return "Completed"
            case .failed: return "Failed"
            }
        }
    }
    
    public struct LeadSourceData: Codable, Identifiable {
        public let id: UUID
        public let sourceName: String
        public let totalLeads: Int
        public let qualifiedLeads: Int
        public let convertedLeads: Int
        public let conversionRate: Double
        public let averageValue: Double
        public let totalRevenue: Double
        public let costPerLead: Double?
        public let roi: Double?
        
        public init(
            id: UUID = UUID(),
            sourceName: String,
            totalLeads: Int,
            qualifiedLeads: Int,
            convertedLeads: Int,
            conversionRate: Double,
            averageValue: Double,
            totalRevenue: Double,
            costPerLead: Double? = nil,
            roi: Double? = nil
        ) {
            self.id = id
            self.sourceName = sourceName
            self.totalLeads = totalLeads
            self.qualifiedLeads = qualifiedLeads
            self.convertedLeads = convertedLeads
            self.conversionRate = conversionRate
            self.averageValue = averageValue
            self.totalRevenue = totalRevenue
            self.costPerLead = costPerLead
            self.roi = roi
        }
    }
    
    public struct StageAnalysis: Codable {
        public let newLeads: Int
        public let contacted: Int
        public let qualified: Int
        public let proposal: Int
        public let negotiation: Int
        public let closed: Int
        public let lost: Int
        public let averageTimeInStage: [String: TimeInterval] // stage name -> time
        public let conversionRates: [String: Double] // stage -> next stage conversion
        public let bottlenecks: [String] // stages with low conversion
        
        public var totalLeadsInPipeline: Int {
            return newLeads + contacted + qualified + proposal + negotiation
        }
        
        public var pipelineValue: Double? {
            // Would need additional data to calculate
            return nil
        }
    }
    
    public struct TeamMemberPerformance: Codable, Identifiable {
        public let id: UUID
        public let memberId: CKRecord.Reference
        public let memberName: String
        public let role: String
        public let totalLeads: Int
        public let qualifiedLeads: Int
        public let convertedLeads: Int
        public let conversionRate: Double
        public let totalRevenue: Double
        public let averageDealSize: Double
        public let followUpRate: Double
        public let responseTime: TimeInterval
        public let qualityScore: Double
        public let goalsAchieved: Bool
        
        public init(
            id: UUID = UUID(),
            memberId: CKRecord.Reference,
            memberName: String,
            role: String,
            totalLeads: Int,
            qualifiedLeads: Int,
            convertedLeads: Int,
            conversionRate: Double,
            totalRevenue: Double,
            averageDealSize: Double,
            followUpRate: Double,
            responseTime: TimeInterval,
            qualityScore: Double,
            goalsAchieved: Bool
        ) {
            self.id = id
            self.memberId = memberId
            self.memberName = memberName
            self.role = role
            self.totalLeads = totalLeads
            self.qualifiedLeads = qualifiedLeads
            self.convertedLeads = convertedLeads
            self.conversionRate = conversionRate
            self.totalRevenue = totalRevenue
            self.averageDealSize = averageDealSize
            self.followUpRate = followUpRate
            self.responseTime = responseTime
            self.qualityScore = qualityScore
            self.goalsAchieved = goalsAchieved
        }
    }
    
    public struct FollowUpMetrics: Codable {
        public let averageResponseTime: TimeInterval
        public let followUpRate: Double
        public let averageContactAttempts: Double
        public let bestContactTime: String
        public let preferredContactMethod: String
        public let followUpConversionRate: Double
        public let automatedFollowUps: Int
        public let manualFollowUps: Int
    }
    
    public struct QualityScores: Codable {
        public let overallScore: Double
        public let dataCompleteness: Double
        public let responseQuality: Double
        public let followUpConsistency: Double
        public let conversionEffectiveness: Double
        public let customerSatisfaction: Double
        public let processingAccuracy: Double
        
        public var averageScore: Double {
            return (dataCompleteness + responseQuality + followUpConsistency + 
                   conversionEffectiveness + customerSatisfaction + processingAccuracy) / 6.0
        }
    }
    
    // Computed properties
    public var qualificationRate: Double {
        guard totalLeads > 0 else { return 0 }
        return (Double(qualifiedLeads) / Double(totalLeads)) * 100
    }
    
    public var revenuePerLead: Double {
        guard totalLeads > 0 else { return 0 }
        return totalRevenue / Double(totalLeads)
    }
    
    public var topPerformer: TeamMemberPerformance? {
        return teamPerformance.max { $0.totalRevenue < $1.totalRevenue }
    }
    
    public var topLeadSource: LeadSourceData? {
        return leadSources.max { $0.totalRevenue < $1.totalRevenue }
    }
    
    public var needsAttention: [String] {
        var issues: [String] = []
        
        if conversionRate < 10 {
            issues.append("Low conversion rate (\(String(format: "%.1f", conversionRate))%)")
        }
        
        if followUpMetrics.followUpRate < 80 {
            issues.append("Poor follow-up rate (\(String(format: "%.1f", followUpMetrics.followUpRate))%)")
        }
        
        if qualityScores.overallScore < 70 {
            issues.append("Quality score below target (\(String(format: "%.1f", qualityScores.overallScore))%)")
        }
        
        return issues
    }
    
    // MARK: - CloudKit Integration
    
    public init?(record: CKRecord) {
        guard let storeCode = record["storeCode"] as? String,
              let reportPeriodRaw = record["reportPeriod"] as? String,
              let reportPeriod = ReportPeriod(rawValue: reportPeriodRaw),
              let startDate = record["startDate"] as? Date,
              let endDate = record["endDate"] as? Date,
              let generatedBy = record["generatedBy"] as? CKRecord.Reference,
              let generatedByName = record["generatedByName"] as? String,
              let generatedAt = record["generatedAt"] as? Date,
              let statusRaw = record["status"] as? String,
              let status = ReportStatus(rawValue: statusRaw),
              let totalLeads = record["totalLeads"] as? Int,
              let qualifiedLeads = record["qualifiedLeads"] as? Int,
              let convertedLeads = record["convertedLeads"] as? Int,
              let conversionRate = record["conversionRate"] as? Double,
              let totalRevenue = record["totalRevenue"] as? Double,
              let isActive = record["isActive"] as? Bool,
              let createdAt = record["createdAt"] as? Date,
              let updatedAt = record["updatedAt"] as? Date else {
            return nil
        }
        
        self.id = record.recordID
        self.storeCode = storeCode
        self.reportPeriod = reportPeriod
        self.startDate = startDate
        self.endDate = endDate
        self.generatedBy = generatedBy
        self.generatedByName = generatedByName
        self.generatedAt = generatedAt
        self.status = status
        self.totalLeads = totalLeads
        self.qualifiedLeads = qualifiedLeads
        self.convertedLeads = convertedLeads
        self.conversionRate = conversionRate
        self.averageLeadValue = record["averageLeadValue"] as? Double
        self.totalRevenue = totalRevenue
        self.notes = record["notes"] as? String
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        
        // Decode complex data from JSON
        if let leadSourcesData = record["leadSources"] as? Data,
           let decodedSources = try? JSONDecoder().decode([LeadSourceData].self, from: leadSourcesData) {
            self.leadSources = decodedSources
        } else {
            self.leadSources = []
        }
        
        if let stageData = record["stageAnalysis"] as? Data,
           let decodedStage = try? JSONDecoder().decode(StageAnalysis.self, from: stageData) {
            self.stageAnalysis = decodedStage
        } else {
            // Default empty stage analysis
            self.stageAnalysis = StageAnalysis(
                newLeads: 0, contacted: 0, qualified: 0, proposal: 0,
                negotiation: 0, closed: 0, lost: 0,
                averageTimeInStage: [:], conversionRates: [:], bottlenecks: []
            )
        }
        
        if let teamData = record["teamPerformance"] as? Data,
           let decodedTeam = try? JSONDecoder().decode([TeamMemberPerformance].self, from: teamData) {
            self.teamPerformance = decodedTeam
        } else {
            self.teamPerformance = []
        }
        
        if let followUpData = record["followUpMetrics"] as? Data,
           let decodedFollowUp = try? JSONDecoder().decode(FollowUpMetrics.self, from: followUpData) {
            self.followUpMetrics = decodedFollowUp
        } else {
            // Default empty follow-up metrics
            self.followUpMetrics = FollowUpMetrics(
                averageResponseTime: 0, followUpRate: 0, averageContactAttempts: 0,
                bestContactTime: "", preferredContactMethod: "", followUpConversionRate: 0,
                automatedFollowUps: 0, manualFollowUps: 0
            )
        }
        
        if let qualityData = record["qualityScores"] as? Data,
           let decodedQuality = try? JSONDecoder().decode(QualityScores.self, from: qualityData) {
            self.qualityScores = decodedQuality
        } else {
            // Default quality scores
            self.qualityScores = QualityScores(
                overallScore: 0, dataCompleteness: 0, responseQuality: 0,
                followUpConsistency: 0, conversionEffectiveness: 0,
                customerSatisfaction: 0, processingAccuracy: 0
            )
        }
        
        if let actionItemsData = record["actionItems"] as? Data,
           let decodedActions = try? JSONDecoder().decode([String].self, from: actionItemsData) {
            self.actionItems = decodedActions
        } else {
            self.actionItems = []
        }
    }
    
    public func toRecord() -> CKRecord {
        let record = CKRecord(recordType: "CRMIntakeReport", recordID: id)
        
        record["storeCode"] = storeCode
        record["reportPeriod"] = reportPeriod.rawValue
        record["startDate"] = startDate
        record["endDate"] = endDate
        record["generatedBy"] = generatedBy
        record["generatedByName"] = generatedByName
        record["generatedAt"] = generatedAt
        record["status"] = status.rawValue
        record["totalLeads"] = totalLeads
        record["qualifiedLeads"] = qualifiedLeads
        record["convertedLeads"] = convertedLeads
        record["conversionRate"] = conversionRate
        record["averageLeadValue"] = averageLeadValue
        record["totalRevenue"] = totalRevenue
        record["notes"] = notes
        record["isActive"] = isActive
        record["createdAt"] = createdAt
        record["updatedAt"] = updatedAt
        
        // Encode complex data as JSON
        if !leadSources.isEmpty,
           let leadSourcesData = try? JSONEncoder().encode(leadSources) {
            record["leadSources"] = leadSourcesData
        }
        
        if let stageData = try? JSONEncoder().encode(stageAnalysis) {
            record["stageAnalysis"] = stageData
        }
        
        if !teamPerformance.isEmpty,
           let teamData = try? JSONEncoder().encode(teamPerformance) {
            record["teamPerformance"] = teamData
        }
        
        if let followUpData = try? JSONEncoder().encode(followUpMetrics) {
            record["followUpMetrics"] = followUpData
        }
        
        if let qualityData = try? JSONEncoder().encode(qualityScores) {
            record["qualityScores"] = qualityData
        }
        
        if !actionItems.isEmpty,
           let actionItemsData = try? JSONEncoder().encode(actionItems) {
            record["actionItems"] = actionItemsData
        }
        
        return record
    }
    
    public static func from(record: CKRecord) -> CRMIntakeReport? {
        return CRMIntakeReport(record: record)
    }
    
    // MARK: - Factory Methods
    
    public static func create(
        storeCode: String,
        reportPeriod: ReportPeriod,
        startDate: Date,
        endDate: Date,
        generatedBy: CKRecord.Reference,
        generatedByName: String
    ) -> CRMIntakeReport {
        let now = Date()
        
        return CRMIntakeReport(
            id: CKRecord.ID(recordName: UUID().uuidString),
            storeCode: storeCode,
            reportPeriod: reportPeriod,
            startDate: startDate,
            endDate: endDate,
            generatedBy: generatedBy,
            generatedByName: generatedByName,
            generatedAt: now,
            status: .generating,
            totalLeads: 0,
            qualifiedLeads: 0,
            convertedLeads: 0,
            conversionRate: 0.0,
            averageLeadValue: nil,
            totalRevenue: 0.0,
            leadSources: [],
            stageAnalysis: StageAnalysis(
                newLeads: 0, contacted: 0, qualified: 0, proposal: 0,
                negotiation: 0, closed: 0, lost: 0,
                averageTimeInStage: [:], conversionRates: [:], bottlenecks: []
            ),
            teamPerformance: [],
            followUpMetrics: FollowUpMetrics(
                averageResponseTime: 0, followUpRate: 0, averageContactAttempts: 0,
                bestContactTime: "", preferredContactMethod: "", followUpConversionRate: 0,
                automatedFollowUps: 0, manualFollowUps: 0
            ),
            qualityScores: QualityScores(
                overallScore: 0, dataCompleteness: 0, responseQuality: 0,
                followUpConsistency: 0, conversionEffectiveness: 0,
                customerSatisfaction: 0, processingAccuracy: 0
            ),
            actionItems: [],
            notes: nil,
            isActive: true,
            createdAt: now,
            updatedAt: now
        )
    }
}
