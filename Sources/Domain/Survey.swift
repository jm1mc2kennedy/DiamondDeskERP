import Foundation
import CloudKit

/// Represents a survey for collecting feedback and data
struct Survey: Identifiable, Hashable {
    let id: CKRecord.ID
    var title: String
    var questions: [SurveyQuestion] // JSON schema
    var isAnonymous: Bool
    var createdByRef: CKRecord.Reference
    var targetStoreCodes: [String]
    var targetRoles: [String]
    var publishedAt: Date?
    var expiresAt: Date?
    var isActive: Bool
    var responseCount: Int
    var createdAt: Date
    var updatedAt: Date
    
    struct SurveyQuestion: Codable, Hashable {
        let id: String
        let text: String
        let type: QuestionType
        let isRequired: Bool
        let options: [String]? // For multiple choice
        let validation: QuestionValidation?
        
        enum QuestionType: String, Codable, CaseIterable {
            case text = "text"
            case multipleChoice = "multiple_choice"
            case singleChoice = "single_choice"
            case rating = "rating"
            case yesNo = "yes_no"
            case date = "date"
            case number = "number"
        }
        
        struct QuestionValidation: Codable, Hashable {
            let minLength: Int?
            let maxLength: Int?
            let minValue: Double?
            let maxValue: Double?
            let pattern: String? // Regex pattern
        }
    }
    
    init?(record: CKRecord) {
        guard
            let title = record["title"] as? String,
            let questionsData = record["questions"] as? Data,
            let questions = try? JSONDecoder().decode([SurveyQuestion].self, from: questionsData),
            let isAnonymous = record["isAnonymous"] as? Bool,
            let createdByRef = record["createdByRef"] as? CKRecord.Reference,
            let targetStoreCodes = record["targetStoreCodes"] as? [String],
            let targetRoles = record["targetRoles"] as? [String],
            let isActive = record["isActive"] as? Bool,
            let responseCount = record["responseCount"] as? Int,
            let createdAt = record["createdAt"] as? Date,
            let updatedAt = record["updatedAt"] as? Date
        else {
            return nil
        }
        
        self.id = record.recordID
        self.title = title
        self.questions = questions
        self.isAnonymous = isAnonymous
        self.createdByRef = createdByRef
        self.targetStoreCodes = targetStoreCodes
        self.targetRoles = targetRoles
        self.isActive = isActive
        self.responseCount = responseCount
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        
        // Optional fields
        self.publishedAt = record["publishedAt"] as? Date
        self.expiresAt = record["expiresAt"] as? Date
    }
    
    func toRecord() -> CKRecord {
        let record = CKRecord(recordType: "Survey", recordID: id)
        record["title"] = title as CKRecordValue
        record["isAnonymous"] = isAnonymous as CKRecordValue
        record["createdByRef"] = createdByRef as CKRecordValue
        record["targetStoreCodes"] = targetStoreCodes as CKRecordValue
        record["targetRoles"] = targetRoles as CKRecordValue
        record["isActive"] = isActive as CKRecordValue
        record["responseCount"] = responseCount as CKRecordValue
        record["createdAt"] = createdAt as CKRecordValue
        record["updatedAt"] = updatedAt as CKRecordValue
        
        // Encode questions as JSON
        if let questionsData = try? JSONEncoder().encode(questions) {
            record["questions"] = questionsData as CKRecordValue
        }
        
        if let publishedAt = publishedAt {
            record["publishedAt"] = publishedAt as CKRecordValue
        }
        if let expiresAt = expiresAt {
            record["expiresAt"] = expiresAt as CKRecordValue
        }
        
        return record
    }
    
    static func from(record: CKRecord) -> Survey? {
        return Survey(record: record)
    }
    
    // MARK: - Helper Methods
    
    mutating func publish() {
        isActive = true
        publishedAt = Date()
        updatedAt = Date()
    }
    
    mutating func deactivate() {
        isActive = false
        updatedAt = Date()
    }
    
    mutating func incrementResponseCount() {
        responseCount += 1
        updatedAt = Date()
    }
    
    var isExpired: Bool {
        guard let expiresAt = expiresAt else { return false }
        return Date() > expiresAt
    }
    
    var isPublished: Bool {
        return publishedAt != nil
    }
    
    var requiredQuestionCount: Int {
        return questions.filter { $0.isRequired }.count
    }
}

/// Represents a response to a survey
struct SurveyResponse: Identifiable, Hashable {
    let id: CKRecord.ID
    var surveyRef: CKRecord.Reference
    var userRef: CKRecord.Reference? // Null if anonymous
    var answers: [String: SurveyAnswer] // Question ID -> Answer
    var submittedAt: Date
    var completionTimeSeconds: Int
    var isComplete: Bool
    var deviceInfo: String?
    
    struct SurveyAnswer: Codable, Hashable {
        let questionId: String
        let value: String // JSON-encoded answer value
        let answeredAt: Date
    }
    
    init?(record: CKRecord) {
        guard
            let surveyRef = record["surveyRef"] as? CKRecord.Reference,
            let answersData = record["answers"] as? Data,
            let answers = try? JSONDecoder().decode([String: SurveyAnswer].self, from: answersData),
            let submittedAt = record["submittedAt"] as? Date,
            let completionTimeSeconds = record["completionTimeSeconds"] as? Int,
            let isComplete = record["isComplete"] as? Bool
        else {
            return nil
        }
        
        self.id = record.recordID
        self.surveyRef = surveyRef
        self.answers = answers
        self.submittedAt = submittedAt
        self.completionTimeSeconds = completionTimeSeconds
        self.isComplete = isComplete
        
        // Optional fields
        self.userRef = record["userRef"] as? CKRecord.Reference
        self.deviceInfo = record["deviceInfo"] as? String
    }
    
    func toRecord() -> CKRecord {
        let record = CKRecord(recordType: "SurveyResponse", recordID: id)
        record["surveyRef"] = surveyRef as CKRecordValue
        record["submittedAt"] = submittedAt as CKRecordValue
        record["completionTimeSeconds"] = completionTimeSeconds as CKRecordValue
        record["isComplete"] = isComplete as CKRecordValue
        
        // Encode answers as JSON
        if let answersData = try? JSONEncoder().encode(answers) {
            record["answers"] = answersData as CKRecordValue
        }
        
        if let userRef = userRef {
            record["userRef"] = userRef as CKRecordValue
        }
        if let deviceInfo = deviceInfo {
            record["deviceInfo"] = deviceInfo as CKRecordValue
        }
        
        return record
    }
    
    static func from(record: CKRecord) -> SurveyResponse? {
        return SurveyResponse(record: record)
    }
    
    // MARK: - Helper Methods
    
    mutating func addAnswer(questionId: String, value: String) {
        answers[questionId] = SurveyAnswer(
            questionId: questionId,
            value: value,
            answeredAt: Date()
        )
    }
    
    var isAnonymous: Bool {
        return userRef == nil
    }
    
    var answeredQuestionCount: Int {
        return answers.count
    }
}
