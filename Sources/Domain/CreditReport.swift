import Foundation
import CloudKit

/// Credit report for customer financial analysis and approval workflow
public struct CreditReport: Identifiable, Codable {
    public let id: CKRecord.ID
    public let customerId: CKRecord.Reference
    public let customerName: String
    public let customerEmail: String?
    public let customerPhone: String?
    public let storeCode: String
    public let requestedBy: CKRecord.Reference
    public let requestedByName: String
    public let requestedAt: Date
    public let reportType: CreditReportType
    public let status: ReportStatus
    public let creditScore: Int?
    public let creditRating: CreditRating?
    public let approvedCreditLimit: Double?
    public let recommendedLimit: Double?
    public let riskLevel: RiskLevel?
    public let reportData: CreditReportData?
    public let notes: String?
    public let reviewedBy: CKRecord.Reference?
    public let reviewedByName: String?
    public let reviewedAt: Date?
    public let expiresAt: Date?
    public let isActive: Bool
    public let createdAt: Date
    public let updatedAt: Date
    
    public enum CreditReportType: String, CaseIterable, Codable {
        case standard = "standard"
        case premium = "premium"
        case business = "business"
        case quickCheck = "quick_check"
        
        public var displayName: String {
            switch self {
            case .standard: return "Standard Report"
            case .premium: return "Premium Report"
            case .business: return "Business Report"
            case .quickCheck: return "Quick Check"
            }
        }
        
        public var cost: Double {
            switch self {
            case .quickCheck: return 5.00
            case .standard: return 15.00
            case .premium: return 35.00
            case .business: return 50.00
            }
        }
    }
    
    public enum ReportStatus: String, CaseIterable, Codable {
        case pending = "pending"
        case processing = "processing"
        case completed = "completed"
        case failed = "failed"
        case expired = "expired"
        
        public var displayName: String {
            switch self {
            case .pending: return "Pending"
            case .processing: return "Processing"
            case .completed: return "Completed"
            case .failed: return "Failed"
            case .expired: return "Expired"
            }
        }
    }
    
    public enum CreditRating: String, CaseIterable, Codable {
        case excellent = "excellent"
        case good = "good"
        case fair = "fair"
        case poor = "poor"
        case noCredit = "no_credit"
        
        public var displayName: String {
            switch self {
            case .excellent: return "Excellent"
            case .good: return "Good"
            case .fair: return "Fair"
            case .poor: return "Poor"
            case .noCredit: return "No Credit"
            }
        }
        
        public var scoreRange: ClosedRange<Int> {
            switch self {
            case .excellent: return 750...850
            case .good: return 670...749
            case .fair: return 580...669
            case .poor: return 300...579
            case .noCredit: return 0...0
            }
        }
    }
    
    public enum RiskLevel: String, CaseIterable, Codable {
        case low = "low"
        case medium = "medium"
        case high = "high"
        case extreme = "extreme"
        
        public var displayName: String {
            switch self {
            case .low: return "Low Risk"
            case .medium: return "Medium Risk"
            case .high: return "High Risk"
            case .extreme: return "Extreme Risk"
            }
        }
        
        public var color: String {
            switch self {
            case .low: return "green"
            case .medium: return "yellow"
            case .high: return "orange"
            case .extreme: return "red"
            }
        }
    }
    
    public struct CreditReportData: Codable {
        public let ssn: String? // Encrypted
        public let dateOfBirth: Date?
        public let address: Address?
        public let employmentInfo: EmploymentInfo?
        public let accounts: [CreditAccount]
        public let inquiries: [CreditInquiry]
        public let publicRecords: [PublicRecord]
        public let alerts: [CreditAlert]
        public let recommendations: [String]
        public let reportDate: Date
        public let bureauInfo: BureauInfo
        
        public struct Address: Codable {
            public let street: String
            public let city: String
            public let state: String
            public let zipCode: String
            public let isPrimary: Bool
        }
        
        public struct EmploymentInfo: Codable {
            public let employer: String?
            public let position: String?
            public let monthlyIncome: Double?
            public let startDate: Date?
            public let isVerified: Bool
        }
        
        public struct CreditAccount: Codable {
            public let accountNumber: String // Masked
            public let creditorName: String
            public let accountType: String
            public let balance: Double
            public let creditLimit: Double?
            public let paymentHistory: String
            public let openDate: Date?
            public let lastActivity: Date?
            public let status: String
        }
        
        public struct CreditInquiry: Codable {
            public let creditorName: String
            public let inquiryDate: Date
            public let inquiryType: String // soft/hard
        }
        
        public struct PublicRecord: Codable {
            public let recordType: String
            public let court: String?
            public let amount: Double?
            public let filedDate: Date?
            public let status: String
        }
        
        public struct CreditAlert: Codable {
            public let alertType: String
            public let message: String
            public let severity: String
            public let date: Date
        }
        
        public struct BureauInfo: Codable {
            public let bureau: String // Experian, Equifax, TransUnion
            public let reportId: String
            public let generatedAt: Date
        }
    }
    
    // Computed properties
    public var isExpired: Bool {
        guard let expiresAt = expiresAt else { return false }
        return Date() > expiresAt
    }
    
    public var isCompleted: Bool {
        return status == .completed
    }
    
    public var daysUntilExpiration: Int? {
        guard let expiresAt = expiresAt else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: expiresAt).day
    }
    
    public var formattedCreditLimit: String? {
        guard let limit = approvedCreditLimit else { return nil }
        return String(format: "$%.2f", limit)
    }
    
    public var totalDebt: Double? {
        return reportData?.accounts.reduce(0) { $0 + $1.balance }
    }
    
    public var totalCreditLimit: Double? {
        return reportData?.accounts.compactMap { $0.creditLimit }.reduce(0, +)
    }
    
    public var utilizationRate: Double? {
        guard let debt = totalDebt, let limit = totalCreditLimit, limit > 0 else { return nil }
        return (debt / limit) * 100
    }
    
    // MARK: - CloudKit Integration
    
    public init?(record: CKRecord) {
        guard let customerId = record["customerId"] as? CKRecord.Reference,
              let customerName = record["customerName"] as? String,
              let storeCode = record["storeCode"] as? String,
              let requestedBy = record["requestedBy"] as? CKRecord.Reference,
              let requestedByName = record["requestedByName"] as? String,
              let requestedAt = record["requestedAt"] as? Date,
              let reportTypeRaw = record["reportType"] as? String,
              let reportType = CreditReportType(rawValue: reportTypeRaw),
              let statusRaw = record["status"] as? String,
              let status = ReportStatus(rawValue: statusRaw),
              let isActive = record["isActive"] as? Bool,
              let createdAt = record["createdAt"] as? Date,
              let updatedAt = record["updatedAt"] as? Date else {
            return nil
        }
        
        self.id = record.recordID
        self.customerId = customerId
        self.customerName = customerName
        self.customerEmail = record["customerEmail"] as? String
        self.customerPhone = record["customerPhone"] as? String
        self.storeCode = storeCode
        self.requestedBy = requestedBy
        self.requestedByName = requestedByName
        self.requestedAt = requestedAt
        self.reportType = reportType
        self.status = status
        self.creditScore = record["creditScore"] as? Int
        self.approvedCreditLimit = record["approvedCreditLimit"] as? Double
        self.recommendedLimit = record["recommendedLimit"] as? Double
        self.notes = record["notes"] as? String
        self.reviewedBy = record["reviewedBy"] as? CKRecord.Reference
        self.reviewedByName = record["reviewedByName"] as? String
        self.reviewedAt = record["reviewedAt"] as? Date
        self.expiresAt = record["expiresAt"] as? Date
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        
        // Decode enums
        if let creditRatingRaw = record["creditRating"] as? String {
            self.creditRating = CreditRating(rawValue: creditRatingRaw)
        } else {
            self.creditRating = nil
        }
        
        if let riskLevelRaw = record["riskLevel"] as? String {
            self.riskLevel = RiskLevel(rawValue: riskLevelRaw)
        } else {
            self.riskLevel = nil
        }
        
        // Decode report data from JSON
        if let reportDataBytes = record["reportData"] as? Data,
           let decodedData = try? JSONDecoder().decode(CreditReportData.self, from: reportDataBytes) {
            self.reportData = decodedData
        } else {
            self.reportData = nil
        }
    }
    
    public func toRecord() -> CKRecord {
        let record = CKRecord(recordType: "CreditReport", recordID: id)
        
        record["customerId"] = customerId
        record["customerName"] = customerName
        record["customerEmail"] = customerEmail
        record["customerPhone"] = customerPhone
        record["storeCode"] = storeCode
        record["requestedBy"] = requestedBy
        record["requestedByName"] = requestedByName
        record["requestedAt"] = requestedAt
        record["reportType"] = reportType.rawValue
        record["status"] = status.rawValue
        record["creditScore"] = creditScore
        record["creditRating"] = creditRating?.rawValue
        record["approvedCreditLimit"] = approvedCreditLimit
        record["recommendedLimit"] = recommendedLimit
        record["riskLevel"] = riskLevel?.rawValue
        record["notes"] = notes
        record["reviewedBy"] = reviewedBy
        record["reviewedByName"] = reviewedByName
        record["reviewedAt"] = reviewedAt
        record["expiresAt"] = expiresAt
        record["isActive"] = isActive
        record["createdAt"] = createdAt
        record["updatedAt"] = updatedAt
        
        // Encode report data as JSON
        if let reportData = reportData,
           let reportDataBytes = try? JSONEncoder().encode(reportData) {
            record["reportData"] = reportDataBytes
        }
        
        return record
    }
    
    public static func from(record: CKRecord) -> CreditReport? {
        return CreditReport(record: record)
    }
    
    // MARK: - Factory Methods
    
    public static func create(
        customerId: CKRecord.Reference,
        customerName: String,
        customerEmail: String? = nil,
        customerPhone: String? = nil,
        storeCode: String,
        requestedBy: CKRecord.Reference,
        requestedByName: String,
        reportType: CreditReportType = .standard
    ) -> CreditReport {
        let now = Date()
        let expirationDate = Calendar.current.date(byAdding: .day, value: 30, to: now)
        
        return CreditReport(
            id: CKRecord.ID(recordName: UUID().uuidString),
            customerId: customerId,
            customerName: customerName,
            customerEmail: customerEmail,
            customerPhone: customerPhone,
            storeCode: storeCode,
            requestedBy: requestedBy,
            requestedByName: requestedByName,
            requestedAt: now,
            reportType: reportType,
            status: .pending,
            creditScore: nil,
            creditRating: nil,
            approvedCreditLimit: nil,
            recommendedLimit: nil,
            riskLevel: nil,
            reportData: nil,
            notes: nil,
            reviewedBy: nil,
            reviewedByName: nil,
            reviewedAt: nil,
            expiresAt: expirationDate,
            isActive: true,
            createdAt: now,
            updatedAt: now
        )
    }
    
    // MARK: - Helper Methods
    
    public func withStatus(_ newStatus: ReportStatus) -> CreditReport {
        return CreditReport(
            id: id,
            customerId: customerId,
            customerName: customerName,
            customerEmail: customerEmail,
            customerPhone: customerPhone,
            storeCode: storeCode,
            requestedBy: requestedBy,
            requestedByName: requestedByName,
            requestedAt: requestedAt,
            reportType: reportType,
            status: newStatus,
            creditScore: creditScore,
            creditRating: creditRating,
            approvedCreditLimit: approvedCreditLimit,
            recommendedLimit: recommendedLimit,
            riskLevel: riskLevel,
            reportData: reportData,
            notes: notes,
            reviewedBy: reviewedBy,
            reviewedByName: reviewedByName,
            reviewedAt: reviewedAt,
            expiresAt: expiresAt,
            isActive: isActive,
            createdAt: createdAt,
            updatedAt: Date()
        )
    }
    
    public func withReportData(_ data: CreditReportData) -> CreditReport {
        // Determine credit rating and risk level from score
        let rating: CreditRating? = {
            guard let score = data.accounts.isEmpty ? nil : creditScore else { return nil }
            switch score {
            case 750...850: return .excellent
            case 670...749: return .good
            case 580...669: return .fair
            case 300...579: return .poor
            default: return .noCredit
            }
        }()
        
        let risk: RiskLevel? = {
            guard let rating = rating else { return nil }
            switch rating {
            case .excellent: return .low
            case .good: return .low
            case .fair: return .medium
            case .poor: return .high
            case .noCredit: return .extreme
            }
        }()
        
        return CreditReport(
            id: id,
            customerId: customerId,
            customerName: customerName,
            customerEmail: customerEmail,
            customerPhone: customerPhone,
            storeCode: storeCode,
            requestedBy: requestedBy,
            requestedByName: requestedByName,
            requestedAt: requestedAt,
            reportType: reportType,
            status: .completed,
            creditScore: creditScore,
            creditRating: rating,
            approvedCreditLimit: approvedCreditLimit,
            recommendedLimit: recommendedLimit,
            riskLevel: risk,
            reportData: data,
            notes: notes,
            reviewedBy: reviewedBy,
            reviewedByName: reviewedByName,
            reviewedAt: reviewedAt,
            expiresAt: expiresAt,
            isActive: isActive,
            createdAt: createdAt,
            updatedAt: Date()
        )
    }
}
