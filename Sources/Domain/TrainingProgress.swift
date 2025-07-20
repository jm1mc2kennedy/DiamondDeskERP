import Foundation
import CloudKit

/// Training progress tracking model for course completion and scoring
struct TrainingProgress: Identifiable, Hashable, Codable {
    let id: CKRecord.ID
    let courseRef: CKRecord.Reference
    let userRef: CKRecord.Reference
    var status: TrainingProgressStatus
    var score: Double?
    var completedAt: Date?
    var lastAccessedAt: Date
    var startedAt: Date
    var timeSpent: TimeInterval // Total time spent in seconds
    var progressPercentage: Double // 0.0 to 100.0
    var currentModule: String? // Current module/section being studied
    var completedModules: [String] // List of completed module IDs
    var quizScores: [QuizScore] // Individual quiz/assessment scores
    var certificateIssued: Bool
    var certificateNumber: String?
    var expirationDate: Date? // For certifications that expire
    var notes: String?
    var createdAt: Date
    var updatedAt: Date
    
    enum TrainingProgressStatus: String, CaseIterable, Codable {
        case notStarted = "not_started"
        case inProgress = "in_progress"
        case completed = "completed"
        case failed = "failed"
        case expired = "expired"
        case certified = "certified"
        
        var displayName: String {
            switch self {
            case .notStarted: return "Not Started"
            case .inProgress: return "In Progress"
            case .completed: return "Completed"
            case .failed: return "Failed"
            case .expired: return "Expired"
            case .certified: return "Certified"
            }
        }
        
        var isActive: Bool {
            return self == .inProgress || self == .notStarted
        }
        
        var isCompleted: Bool {
            return self == .completed || self == .certified
        }
    }
    
    struct QuizScore: Codable, Hashable, Identifiable {
        let id: String
        let moduleId: String
        let moduleName: String
        let score: Double
        let maxScore: Double
        let passed: Bool
        let completedAt: Date
        let timeSpent: TimeInterval
        let attempts: Int
        
        var percentage: Double {
            guard maxScore > 0 else { return 0 }
            return (score / maxScore) * 100
        }
    }
    
    // MARK: - CloudKit Integration
    
    init?(record: CKRecord) {
        guard
            let courseRef = record["courseRef"] as? CKRecord.Reference,
            let userRef = record["userRef"] as? CKRecord.Reference,
            let statusRaw = record["status"] as? String,
            let status = TrainingProgressStatus(rawValue: statusRaw),
            let lastAccessedAt = record["lastAccessedAt"] as? Date,
            let startedAt = record["startedAt"] as? Date,
            let timeSpent = record["timeSpent"] as? Double,
            let progressPercentage = record["progressPercentage"] as? Double,
            let completedModules = record["completedModules"] as? [String],
            let certificateIssued = record["certificateIssued"] as? Bool,
            let createdAt = record["createdAt"] as? Date,
            let updatedAt = record["updatedAt"] as? Date
        else {
            return nil
        }
        
        self.id = record.recordID
        self.courseRef = courseRef
        self.userRef = userRef
        self.status = status
        self.score = record["score"] as? Double
        self.completedAt = record["completedAt"] as? Date
        self.lastAccessedAt = lastAccessedAt
        self.startedAt = startedAt
        self.timeSpent = timeSpent
        self.progressPercentage = progressPercentage
        self.currentModule = record["currentModule"] as? String
        self.completedModules = completedModules
        self.certificateIssued = certificateIssued
        self.certificateNumber = record["certificateNumber"] as? String
        self.expirationDate = record["expirationDate"] as? Date
        self.notes = record["notes"] as? String
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        
        // Decode quiz scores from JSON
        if let quizScoresData = record["quizScores"] as? Data,
           let decodedScores = try? JSONDecoder().decode([QuizScore].self, from: quizScoresData) {
            self.quizScores = decodedScores
        } else {
            self.quizScores = []
        }
    }
    
    func toRecord() throws -> CKRecord {
        let record = CKRecord(recordType: "TrainingProgress", recordID: id)
        
        record["courseRef"] = courseRef
        record["userRef"] = userRef
        record["status"] = status.rawValue
        record["score"] = score
        record["completedAt"] = completedAt
        record["lastAccessedAt"] = lastAccessedAt
        record["startedAt"] = startedAt
        record["timeSpent"] = timeSpent
        record["progressPercentage"] = progressPercentage
        record["currentModule"] = currentModule
        record["completedModules"] = completedModules
        record["certificateIssued"] = certificateIssued
        record["certificateNumber"] = certificateNumber
        record["expirationDate"] = expirationDate
        record["notes"] = notes
        record["createdAt"] = createdAt
        record["updatedAt"] = updatedAt
        
        // Encode quiz scores as JSON
        if !quizScores.isEmpty {
            let quizScoresData = try JSONEncoder().encode(quizScores)
            record["quizScores"] = quizScoresData
        }
        
        return record
    }
    
    static func from(record: CKRecord) -> TrainingProgress? {
        return TrainingProgress(record: record)
    }
    
    // MARK: - Factory Methods
    
    static func create(
        courseRef: CKRecord.Reference,
        userRef: CKRecord.Reference
    ) -> TrainingProgress {
        let now = Date()
        return TrainingProgress(
            id: CKRecord.ID(recordName: UUID().uuidString),
            courseRef: courseRef,
            userRef: userRef,
            status: .notStarted,
            score: nil,
            completedAt: nil,
            lastAccessedAt: now,
            startedAt: now,
            timeSpent: 0,
            progressPercentage: 0,
            currentModule: nil,
            completedModules: [],
            quizScores: [],
            certificateIssued: false,
            certificateNumber: nil,
            expirationDate: nil,
            notes: nil,
            createdAt: now,
            updatedAt: now
        )
    }
    
    // MARK: - Helper Methods
    
    func withProgress(
        currentModule: String?,
        progressPercentage: Double,
        timeSpent: TimeInterval
    ) -> TrainingProgress {
        var updated = self
        updated.currentModule = currentModule
        updated.progressPercentage = min(100, max(0, progressPercentage))
        updated.timeSpent = timeSpent
        updated.lastAccessedAt = Date()
        updated.updatedAt = Date()
        
        // Auto-update status based on progress
        if updated.progressPercentage >= 100 && updated.status == .inProgress {
            updated.status = .completed
            updated.completedAt = Date()
        } else if updated.progressPercentage > 0 && updated.status == .notStarted {
            updated.status = .inProgress
        }
        
        return updated
    }
    
    func withQuizScore(_ quizScore: QuizScore) -> TrainingProgress {
        var updated = self
        
        // Remove existing score for same module if it exists
        updated.quizScores.removeAll { $0.moduleId == quizScore.moduleId }
        updated.quizScores.append(quizScore)
        
        // Add to completed modules if passed
        if quizScore.passed && !updated.completedModules.contains(quizScore.moduleId) {
            updated.completedModules.append(quizScore.moduleId)
        }
        
        // Calculate overall score as average of quiz scores
        if !updated.quizScores.isEmpty {
            let totalPercentage = updated.quizScores.reduce(0) { $0 + $1.percentage }
            updated.score = totalPercentage / Double(updated.quizScores.count)
        }
        
        updated.lastAccessedAt = Date()
        updated.updatedAt = Date()
        
        return updated
    }
    
    func withCompletion(
        finalScore: Double?,
        certificateNumber: String? = nil,
        expirationDate: Date? = nil
    ) -> TrainingProgress {
        var updated = self
        updated.status = .completed
        updated.completedAt = Date()
        updated.progressPercentage = 100
        updated.score = finalScore ?? updated.score
        updated.lastAccessedAt = Date()
        updated.updatedAt = Date()
        
        if let certNumber = certificateNumber {
            updated.certificateIssued = true
            updated.certificateNumber = certNumber
            updated.expirationDate = expirationDate
            updated.status = .certified
        }
        
        return updated
    }
    
    func withFailure(notes: String? = nil) -> TrainingProgress {
        var updated = self
        updated.status = .failed
        updated.notes = notes
        updated.lastAccessedAt = Date()
        updated.updatedAt = Date()
        
        return updated
    }
    
    // MARK: - Computed Properties
    
    var averageQuizScore: Double? {
        guard !quizScores.isEmpty else { return nil }
        let total = quizScores.reduce(0) { $0 + $1.percentage }
        return total / Double(quizScores.count)
    }
    
    var passingQuizCount: Int {
        return quizScores.filter { $0.passed }.count
    }
    
    var totalQuizAttempts: Int {
        return quizScores.reduce(0) { $0 + $1.attempts }
    }
    
    var isExpired: Bool {
        guard let expirationDate = expirationDate else { return false }
        return Date() > expirationDate
    }
    
    var daysUntilExpiration: Int? {
        guard let expirationDate = expirationDate else { return nil }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: expirationDate)
        return components.day
    }
}

// MARK: - Extensions

extension TrainingProgress {
    
    /// Generate a completion certificate number
    static func generateCertificateNumber(courseId: String, userId: String) -> String {
        let timestamp = Int(Date().timeIntervalSince1970)
        let coursePrefix = String(courseId.prefix(4)).uppercased()
        let userPrefix = String(userId.prefix(4)).uppercased()
        return "CERT-\(coursePrefix)-\(userPrefix)-\(timestamp)"
    }
    
    /// Check if user can retake the course
    var canRetake: Bool {
        return status == .failed || status == .expired
    }
    
    /// Check if progress is stale (no activity in 30 days)
    var isStale: Bool {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        return lastAccessedAt < thirtyDaysAgo && status == .inProgress
    }
}
