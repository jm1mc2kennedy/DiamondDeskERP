import Foundation
import CloudKit

/// Outbound call report for sales and follow-up call tracking
public struct OutboundCallReport: Identifiable, Codable {
    public let id: CKRecord.ID
    public let storeCode: String
    public let reportPeriod: ReportPeriod
    public let startDate: Date
    public let endDate: Date
    public let generatedBy: CKRecord.Reference
    public let generatedByName: String
    public let generatedAt: Date
    public let status: ReportStatus
    public let totalCalls: Int
    public let successfulCalls: Int
    public let callsConnected: Int
    public let appointmentsSet: Int
    public let salesGenerated: Int
    public let totalRevenue: Double
    public let averageCallDuration: TimeInterval
    public let contactRate: Double
    public let conversionRate: Double
    public let callTypes: [CallTypeData]
    public let timeSlotAnalysis: TimeSlotAnalysis
    public let teamPerformance: [CallTeamPerformance]
    public let callOutcomes: CallOutcomes
    public let qualityMetrics: CallQualityMetrics
    public let followUpData: CallFollowUpData
    public let recommendations: [String]
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
    
    public struct CallTypeData: Codable, Identifiable {
        public let id: UUID
        public let callType: CallType
        public let totalCalls: Int
        public let connectedCalls: Int
        public let successfulCalls: Int
        public let averageDuration: TimeInterval
        public let conversionRate: Double
        public let revenueGenerated: Double
        public let averageRevenuePerCall: Double
        
        public enum CallType: String, CaseIterable, Codable {
            case coldCall = "cold_call"
            case followUp = "follow_up"
            case appointment = "appointment"
            case customerService = "customer_service"
            case upsell = "upsell"
            case winBack = "win_back"
            case survey = "survey"
            
            public var displayName: String {
                switch self {
                case .coldCall: return "Cold Call"
                case .followUp: return "Follow Up"
                case .appointment: return "Appointment"
                case .customerService: return "Customer Service"
                case .upsell: return "Upsell"
                case .winBack: return "Win Back"
                case .survey: return "Survey"
                }
            }
        }
        
        public init(
            id: UUID = UUID(),
            callType: CallType,
            totalCalls: Int,
            connectedCalls: Int,
            successfulCalls: Int,
            averageDuration: TimeInterval,
            conversionRate: Double,
            revenueGenerated: Double,
            averageRevenuePerCall: Double
        ) {
            self.id = id
            self.callType = callType
            self.totalCalls = totalCalls
            self.connectedCalls = connectedCalls
            self.successfulCalls = successfulCalls
            self.averageDuration = averageDuration
            self.conversionRate = conversionRate
            self.revenueGenerated = revenueGenerated
            self.averageRevenuePerCall = averageRevenuePerCall
        }
    }
    
    public struct TimeSlotAnalysis: Codable {
        public let morningCalls: TimeSlotData
        public let afternoonCalls: TimeSlotData
        public let eveningCalls: TimeSlotData
        public let bestTimeSlot: String
        public let worstTimeSlot: String
        public let hourlyBreakdown: [Int: TimeSlotData] // hour -> data
        
        public struct TimeSlotData: Codable {
            public let totalCalls: Int
            public let connectedCalls: Int
            public let successRate: Double
            public let averageDuration: TimeInterval
            public let conversionRate: Double
        }
    }
    
    public struct CallTeamPerformance: Codable, Identifiable {
        public let id: UUID
        public let memberId: CKRecord.Reference
        public let memberName: String
        public let role: String
        public let totalCalls: Int
        public let connectedCalls: Int
        public let successfulCalls: Int
        public let appointmentsSet: Int
        public let salesMade: Int
        public let revenueGenerated: Double
        public let averageCallDuration: TimeInterval
        public let contactRate: Double
        public let conversionRate: Double
        public let qualityScore: Double
        public let goalsAchieved: Bool
        public let ranking: Int
        
        public init(
            id: UUID = UUID(),
            memberId: CKRecord.Reference,
            memberName: String,
            role: String,
            totalCalls: Int,
            connectedCalls: Int,
            successfulCalls: Int,
            appointmentsSet: Int,
            salesMade: Int,
            revenueGenerated: Double,
            averageCallDuration: TimeInterval,
            contactRate: Double,
            conversionRate: Double,
            qualityScore: Double,
            goalsAchieved: Bool,
            ranking: Int
        ) {
            self.id = id
            self.memberId = memberId
            self.memberName = memberName
            self.role = role
            self.totalCalls = totalCalls
            self.connectedCalls = connectedCalls
            self.successfulCalls = successfulCalls
            self.appointmentsSet = appointmentsSet
            self.salesMade = salesMade
            self.revenueGenerated = revenueGenerated
            self.averageCallDuration = averageCallDuration
            self.contactRate = contactRate
            self.conversionRate = conversionRate
            self.qualityScore = qualityScore
            self.goalsAchieved = goalsAchieved
            self.ranking = ranking
        }
    }
    
    public struct CallOutcomes: Codable {
        public let answered: Int
        public let voicemail: Int
        public let busy: Int
        public let noAnswer: Int
        public let disconnected: Int
        public let interested: Int
        public let notInterested: Int
        public let callback: Int
        public let appointment: Int
        public let sale: Int
        public let doNotCall: Int
        
        public var totalAttempts: Int {
            return answered + voicemail + busy + noAnswer + disconnected
        }
        
        public var positiveOutcomes: Int {
            return interested + callback + appointment + sale
        }
        
        public var successRate: Double {
            guard totalAttempts > 0 else { return 0 }
            return (Double(positiveOutcomes) / Double(totalAttempts)) * 100
        }
    }
    
    public struct CallQualityMetrics: Codable {
        public let overallQualityScore: Double
        public let scriptAdherence: Double
        public let customerEngagement: Double
        public let objectionHandling: Double
        public let closingEffectiveness: Double
        public let professionalismScore: Double
        public let listenedCallsCount: Int
        public let averageMonitoringScore: Double
        public let coachingOpportunities: [String]
        
        public var averageScore: Double {
            return (scriptAdherence + customerEngagement + objectionHandling + 
                   closingEffectiveness + professionalismScore) / 5.0
        }
    }
    
    public struct CallFollowUpData: Codable {
        public let followUpCallsScheduled: Int
        public let followUpCallsCompleted: Int
        public let followUpConversionRate: Double
        public let averageTimeBetweenCalls: TimeInterval
        public let emailFollowUpsSent: Int
        public let textFollowUpsSent: Int
        public let noFollowUpNeeded: Int
        public let missedFollowUps: Int
        
        public var followUpCompletionRate: Double {
            guard followUpCallsScheduled > 0 else { return 0 }
            return (Double(followUpCallsCompleted) / Double(followUpCallsScheduled)) * 100
        }
    }
    
    // Computed properties
    public var appointmentRate: Double {
        guard totalCalls > 0 else { return 0 }
        return (Double(appointmentsSet) / Double(totalCalls)) * 100
    }
    
    public var salesRate: Double {
        guard totalCalls > 0 else { return 0 }
        return (Double(salesGenerated) / Double(totalCalls)) * 100
    }
    
    public var averageRevenuePerCall: Double {
        guard totalCalls > 0 else { return 0 }
        return totalRevenue / Double(totalCalls)
    }
    
    public var averageRevenuePerSale: Double {
        guard salesGenerated > 0 else { return 0 }
        return totalRevenue / Double(salesGenerated)
    }
    
    public var formattedCallDuration: String {
        let minutes = Int(averageCallDuration) / 60
        let seconds = Int(averageCallDuration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    public var topPerformer: CallTeamPerformance? {
        return teamPerformance.min { $0.ranking < $1.ranking }
    }
    
    public var mostProductiveCallType: CallTypeData? {
        return callTypes.max { $0.revenueGenerated < $1.revenueGenerated }
    }
    
    public var needsImprovement: [String] {
        var issues: [String] = []
        
        if contactRate < 30 {
            issues.append("Low contact rate (\(String(format: "%.1f", contactRate))%)")
        }
        
        if conversionRate < 5 {
            issues.append("Low conversion rate (\(String(format: "%.1f", conversionRate))%)")
        }
        
        if qualityMetrics.overallQualityScore < 70 {
            issues.append("Quality score below target (\(String(format: "%.1f", qualityMetrics.overallQualityScore))%)")
        }
        
        if followUpData.followUpCompletionRate < 80 {
            issues.append("Poor follow-up completion (\(String(format: "%.1f", followUpData.followUpCompletionRate))%)")
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
              let totalCalls = record["totalCalls"] as? Int,
              let successfulCalls = record["successfulCalls"] as? Int,
              let callsConnected = record["callsConnected"] as? Int,
              let appointmentsSet = record["appointmentsSet"] as? Int,
              let salesGenerated = record["salesGenerated"] as? Int,
              let totalRevenue = record["totalRevenue"] as? Double,
              let averageCallDuration = record["averageCallDuration"] as? TimeInterval,
              let contactRate = record["contactRate"] as? Double,
              let conversionRate = record["conversionRate"] as? Double,
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
        self.totalCalls = totalCalls
        self.successfulCalls = successfulCalls
        self.callsConnected = callsConnected
        self.appointmentsSet = appointmentsSet
        self.salesGenerated = salesGenerated
        self.totalRevenue = totalRevenue
        self.averageCallDuration = averageCallDuration
        self.contactRate = contactRate
        self.conversionRate = conversionRate
        self.notes = record["notes"] as? String
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        
        // Decode complex data from JSON
        if let callTypesData = record["callTypes"] as? Data,
           let decodedTypes = try? JSONDecoder().decode([CallTypeData].self, from: callTypesData) {
            self.callTypes = decodedTypes
        } else {
            self.callTypes = []
        }
        
        if let timeSlotData = record["timeSlotAnalysis"] as? Data,
           let decodedTimeSlot = try? JSONDecoder().decode(TimeSlotAnalysis.self, from: timeSlotData) {
            self.timeSlotAnalysis = decodedTimeSlot
        } else {
            // Default empty time slot analysis
            let emptySlotData = TimeSlotAnalysis.TimeSlotData(totalCalls: 0, connectedCalls: 0, successRate: 0, averageDuration: 0, conversionRate: 0)
            self.timeSlotAnalysis = TimeSlotAnalysis(
                morningCalls: emptySlotData, afternoonCalls: emptySlotData, eveningCalls: emptySlotData,
                bestTimeSlot: "", worstTimeSlot: "", hourlyBreakdown: [:]
            )
        }
        
        if let teamData = record["teamPerformance"] as? Data,
           let decodedTeam = try? JSONDecoder().decode([CallTeamPerformance].self, from: teamData) {
            self.teamPerformance = decodedTeam
        } else {
            self.teamPerformance = []
        }
        
        if let outcomesData = record["callOutcomes"] as? Data,
           let decodedOutcomes = try? JSONDecoder().decode(CallOutcomes.self, from: outcomesData) {
            self.callOutcomes = decodedOutcomes
        } else {
            self.callOutcomes = CallOutcomes(
                answered: 0, voicemail: 0, busy: 0, noAnswer: 0, disconnected: 0,
                interested: 0, notInterested: 0, callback: 0, appointment: 0,
                sale: 0, doNotCall: 0
            )
        }
        
        if let qualityData = record["qualityMetrics"] as? Data,
           let decodedQuality = try? JSONDecoder().decode(CallQualityMetrics.self, from: qualityData) {
            self.qualityMetrics = decodedQuality
        } else {
            self.qualityMetrics = CallQualityMetrics(
                overallQualityScore: 0, scriptAdherence: 0, customerEngagement: 0,
                objectionHandling: 0, closingEffectiveness: 0, professionalismScore: 0,
                listenedCallsCount: 0, averageMonitoringScore: 0, coachingOpportunities: []
            )
        }
        
        if let followUpData = record["followUpData"] as? Data,
           let decodedFollowUp = try? JSONDecoder().decode(CallFollowUpData.self, from: followUpData) {
            self.followUpData = decodedFollowUp
        } else {
            self.followUpData = CallFollowUpData(
                followUpCallsScheduled: 0, followUpCallsCompleted: 0, followUpConversionRate: 0,
                averageTimeBetweenCalls: 0, emailFollowUpsSent: 0, textFollowUpsSent: 0,
                noFollowUpNeeded: 0, missedFollowUps: 0
            )
        }
        
        if let recommendationsData = record["recommendations"] as? Data,
           let decodedRecommendations = try? JSONDecoder().decode([String].self, from: recommendationsData) {
            self.recommendations = decodedRecommendations
        } else {
            self.recommendations = []
        }
    }
    
    public func toRecord() -> CKRecord {
        let record = CKRecord(recordType: "OutboundCallReport", recordID: id)
        
        record["storeCode"] = storeCode
        record["reportPeriod"] = reportPeriod.rawValue
        record["startDate"] = startDate
        record["endDate"] = endDate
        record["generatedBy"] = generatedBy
        record["generatedByName"] = generatedByName
        record["generatedAt"] = generatedAt
        record["status"] = status.rawValue
        record["totalCalls"] = totalCalls
        record["successfulCalls"] = successfulCalls
        record["callsConnected"] = callsConnected
        record["appointmentsSet"] = appointmentsSet
        record["salesGenerated"] = salesGenerated
        record["totalRevenue"] = totalRevenue
        record["averageCallDuration"] = averageCallDuration
        record["contactRate"] = contactRate
        record["conversionRate"] = conversionRate
        record["notes"] = notes
        record["isActive"] = isActive
        record["createdAt"] = createdAt
        record["updatedAt"] = updatedAt
        
        // Encode complex data as JSON
        if !callTypes.isEmpty,
           let callTypesData = try? JSONEncoder().encode(callTypes) {
            record["callTypes"] = callTypesData
        }
        
        if let timeSlotData = try? JSONEncoder().encode(timeSlotAnalysis) {
            record["timeSlotAnalysis"] = timeSlotData
        }
        
        if !teamPerformance.isEmpty,
           let teamData = try? JSONEncoder().encode(teamPerformance) {
            record["teamPerformance"] = teamData
        }
        
        if let outcomesData = try? JSONEncoder().encode(callOutcomes) {
            record["callOutcomes"] = outcomesData
        }
        
        if let qualityData = try? JSONEncoder().encode(qualityMetrics) {
            record["qualityMetrics"] = qualityData
        }
        
        if let followUpData = try? JSONEncoder().encode(followUpData) {
            record["followUpData"] = followUpData
        }
        
        if !recommendations.isEmpty,
           let recommendationsData = try? JSONEncoder().encode(recommendations) {
            record["recommendations"] = recommendationsData
        }
        
        return record
    }
    
    public static func from(record: CKRecord) -> OutboundCallReport? {
        return OutboundCallReport(record: record)
    }
    
    // MARK: - Factory Methods
    
    public static func create(
        storeCode: String,
        reportPeriod: ReportPeriod,
        startDate: Date,
        endDate: Date,
        generatedBy: CKRecord.Reference,
        generatedByName: String
    ) -> OutboundCallReport {
        let now = Date()
        
        return OutboundCallReport(
            id: CKRecord.ID(recordName: UUID().uuidString),
            storeCode: storeCode,
            reportPeriod: reportPeriod,
            startDate: startDate,
            endDate: endDate,
            generatedBy: generatedBy,
            generatedByName: generatedByName,
            generatedAt: now,
            status: .generating,
            totalCalls: 0,
            successfulCalls: 0,
            callsConnected: 0,
            appointmentsSet: 0,
            salesGenerated: 0,
            totalRevenue: 0.0,
            averageCallDuration: 0,
            contactRate: 0.0,
            conversionRate: 0.0,
            callTypes: [],
            timeSlotAnalysis: TimeSlotAnalysis(
                morningCalls: TimeSlotAnalysis.TimeSlotData(totalCalls: 0, connectedCalls: 0, successRate: 0, averageDuration: 0, conversionRate: 0),
                afternoonCalls: TimeSlotAnalysis.TimeSlotData(totalCalls: 0, connectedCalls: 0, successRate: 0, averageDuration: 0, conversionRate: 0),
                eveningCalls: TimeSlotAnalysis.TimeSlotData(totalCalls: 0, connectedCalls: 0, successRate: 0, averageDuration: 0, conversionRate: 0),
                bestTimeSlot: "", worstTimeSlot: "", hourlyBreakdown: [:]
            ),
            teamPerformance: [],
            callOutcomes: CallOutcomes(
                answered: 0, voicemail: 0, busy: 0, noAnswer: 0, disconnected: 0,
                interested: 0, notInterested: 0, callback: 0, appointment: 0,
                sale: 0, doNotCall: 0
            ),
            qualityMetrics: CallQualityMetrics(
                overallQualityScore: 0, scriptAdherence: 0, customerEngagement: 0,
                objectionHandling: 0, closingEffectiveness: 0, professionalismScore: 0,
                listenedCallsCount: 0, averageMonitoringScore: 0, coachingOpportunities: []
            ),
            followUpData: CallFollowUpData(
                followUpCallsScheduled: 0, followUpCallsCompleted: 0, followUpConversionRate: 0,
                averageTimeBetweenCalls: 0, emailFollowUpsSent: 0, textFollowUpsSent: 0,
                noFollowUpNeeded: 0, missedFollowUps: 0
            ),
            recommendations: [],
            notes: nil,
            isActive: true,
            createdAt: now,
            updatedAt: now
        )
    }
}
