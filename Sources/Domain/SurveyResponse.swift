import Foundation
import CloudKit

/// Survey response model for collecting feedback and data
struct SurveyResponse: Identifiable, Hashable, Codable {
    let id: CKRecord.ID
    let surveyRef: CKRecord.Reference
    let userRef: CKRecord.Reference? // Nullable for anonymous surveys
    var answers: [SurveyAnswer] // JSON schema for responses
    let submittedAt: Date
    var ipAddress: String? // For audit purposes
    var userAgent: String? // Device/browser information
    var location: ResponseLocation? // Optional location data
    var sessionId: String? // For tracking partial responses
    var isComplete: Bool
    var timeSpent: TimeInterval // Time spent completing survey
    var language: String // Survey language used
    var source: ResponseSource // How the response was submitted
    var metadata: ResponseMetadata?
    var validationErrors: [String]? // Any validation issues
    var createdAt: Date
    var updatedAt: Date
    
    struct SurveyAnswer: Codable, Hashable, Identifiable {
        let id: String // Question ID
        let questionText: String
        let questionType: Survey.SurveyQuestion.QuestionType
        var value: AnswerValue
        let answeredAt: Date
        var skipped: Bool
        var validationPassed: Bool
        
        enum AnswerValue: Codable, Hashable {
            case text(String)
            case singleChoice(String)
            case multipleChoice([String])
            case rating(Int)
            case yesNo(Bool)
            case date(Date)
            case number(Double)
            case scale(Double) // For 1-10 scales, etc.
            case email(String)
            case phone(String)
            case url(String)
            case none // For skipped questions
            
            var stringValue: String {
                switch self {
                case .text(let value): return value
                case .singleChoice(let value): return value
                case .multipleChoice(let values): return values.joined(separator: ", ")
                case .rating(let value): return "\(value)"
                case .yesNo(let value): return value ? "Yes" : "No"
                case .date(let value): return DateFormatter.surveyDate.string(from: value)
                case .number(let value): return "\(value)"
                case .scale(let value): return "\(value)"
                case .email(let value): return value
                case .phone(let value): return value
                case .url(let value): return value
                case .none: return "No Answer"
                }
            }
            
            var numericValue: Double? {
                switch self {
                case .rating(let value): return Double(value)
                case .number(let value): return value
                case .scale(let value): return value
                case .yesNo(let value): return value ? 1.0 : 0.0
                default: return nil
                }
            }
        }
    }
    
    struct ResponseLocation: Codable, Hashable {
        let latitude: Double
        let longitude: Double
        let accuracy: Double?
        let timestamp: Date
        let address: String?
        let storeCode: String? // If submitted from a specific store
    }
    
    enum ResponseSource: String, CaseIterable, Codable {
        case mobile = "mobile"
        case web = "web"
        case tablet = "tablet"
        case kiosk = "kiosk"
        case email = "email"
        case sms = "sms"
        case qrCode = "qr_code"
        case integration = "integration" // API/webhook
        
        var displayName: String {
            switch self {
            case .mobile: return "Mobile App"
            case .web: return "Web Browser"
            case .tablet: return "Tablet"
            case .kiosk: return "In-Store Kiosk"
            case .email: return "Email Link"
            case .sms: return "SMS Link"
            case .qrCode: return "QR Code"
            case .integration: return "API Integration"
            }
        }
    }
    
    struct ResponseMetadata: Codable, Hashable {
        let deviceModel: String?
        let osVersion: String?
        let appVersion: String?
        let screenSize: String?
        let connectionType: String? // wifi, cellular, etc.
        let referrer: String? // How they got to the survey
        let partialSaveCount: Int // Number of times partially saved
        let revisitCount: Int // Number of times returned to survey
        let abandonedAt: Date? // If they left without completing
        let completionSource: String? // What triggered completion
    }
    
    // MARK: - CloudKit Integration
    
    init?(record: CKRecord) {
        guard
            let surveyRef = record["surveyRef"] as? CKRecord.Reference,
            let submittedAt = record["submittedAt"] as? Date,
            let isComplete = record["isComplete"] as? Bool,
            let timeSpent = record["timeSpent"] as? Double,
            let language = record["language"] as? String,
            let sourceRaw = record["source"] as? String,
            let source = ResponseSource(rawValue: sourceRaw),
            let createdAt = record["createdAt"] as? Date,
            let updatedAt = record["updatedAt"] as? Date
        else {
            return nil
        }
        
        self.id = record.recordID
        self.surveyRef = surveyRef
        self.userRef = record["userRef"] as? CKRecord.Reference // Nullable for anonymous
        self.submittedAt = submittedAt
        self.ipAddress = record["ipAddress"] as? String
        self.userAgent = record["userAgent"] as? String
        self.sessionId = record["sessionId"] as? String
        self.isComplete = isComplete
        self.timeSpent = timeSpent
        self.language = language
        self.source = source
        self.validationErrors = record["validationErrors"] as? [String]
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        
        // Decode answers from JSON
        if let answersData = record["answers"] as? Data,
           let decodedAnswers = try? JSONDecoder().decode([SurveyAnswer].self, from: answersData) {
            self.answers = decodedAnswers
        } else {
            self.answers = []
        }
        
        // Decode location from JSON
        if let locationData = record["location"] as? Data,
           let decodedLocation = try? JSONDecoder().decode(ResponseLocation.self, from: locationData) {
            self.location = decodedLocation
        } else {
            self.location = nil
        }
        
        // Decode metadata from JSON
        if let metadataData = record["metadata"] as? Data,
           let decodedMetadata = try? JSONDecoder().decode(ResponseMetadata.self, from: metadataData) {
            self.metadata = decodedMetadata
        } else {
            self.metadata = nil
        }
    }
    
    func toRecord() throws -> CKRecord {
        let record = CKRecord(recordType: "SurveyResponse", recordID: id)
        
        record["surveyRef"] = surveyRef
        record["userRef"] = userRef // Nullable for anonymous surveys
        record["submittedAt"] = submittedAt
        record["ipAddress"] = ipAddress
        record["userAgent"] = userAgent
        record["sessionId"] = sessionId
        record["isComplete"] = isComplete
        record["timeSpent"] = timeSpent
        record["language"] = language
        record["source"] = source.rawValue
        record["validationErrors"] = validationErrors
        record["createdAt"] = createdAt
        record["updatedAt"] = updatedAt
        
        // Encode answers as JSON
        let answersData = try JSONEncoder().encode(answers)
        record["answers"] = answersData
        
        // Encode location as JSON
        if let location = location {
            let locationData = try JSONEncoder().encode(location)
            record["location"] = locationData
        }
        
        // Encode metadata as JSON
        if let metadata = metadata {
            let metadataData = try JSONEncoder().encode(metadata)
            record["metadata"] = metadataData
        }
        
        return record
    }
    
    static func from(record: CKRecord) -> SurveyResponse? {
        return SurveyResponse(record: record)
    }
    
    // MARK: - Factory Methods
    
    static func create(
        surveyRef: CKRecord.Reference,
        userRef: CKRecord.Reference? = nil, // nil for anonymous
        source: ResponseSource = .mobile,
        language: String = "en",
        sessionId: String? = nil
    ) -> SurveyResponse {
        let now = Date()
        return SurveyResponse(
            id: CKRecord.ID(recordName: UUID().uuidString),
            surveyRef: surveyRef,
            userRef: userRef,
            answers: [],
            submittedAt: now,
            ipAddress: nil,
            userAgent: nil,
            location: nil,
            sessionId: sessionId ?? UUID().uuidString,
            isComplete: false,
            timeSpent: 0,
            language: language,
            source: source,
            metadata: nil,
            validationErrors: nil,
            createdAt: now,
            updatedAt: now
        )
    }
    
    // MARK: - Helper Methods
    
    func withAnswer(
        questionId: String,
        questionText: String,
        questionType: Survey.SurveyQuestion.QuestionType,
        value: SurveyAnswer.AnswerValue,
        validationPassed: Bool = true
    ) -> SurveyResponse {
        var updated = self
        
        // Remove existing answer for same question
        updated.answers.removeAll { $0.id == questionId }
        
        // Add new answer
        let answer = SurveyAnswer(
            id: questionId,
            questionText: questionText,
            questionType: questionType,
            value: value,
            answeredAt: Date(),
            skipped: false,
            validationPassed: validationPassed
        )
        updated.answers.append(answer)
        updated.updatedAt = Date()
        
        return updated
    }
    
    func withSkippedQuestion(
        questionId: String,
        questionText: String,
        questionType: Survey.SurveyQuestion.QuestionType
    ) -> SurveyResponse {
        var updated = self
        
        // Remove existing answer for same question
        updated.answers.removeAll { $0.id == questionId }
        
        // Add skipped answer
        let answer = SurveyAnswer(
            id: questionId,
            questionText: questionText,
            questionType: questionType,
            value: .none,
            answeredAt: Date(),
            skipped: true,
            validationPassed: true
        )
        updated.answers.append(answer)
        updated.updatedAt = Date()
        
        return updated
    }
    
    func withCompletion(timeSpent: TimeInterval) -> SurveyResponse {
        var updated = self
        updated.isComplete = true
        updated.submittedAt = Date()
        updated.timeSpent = timeSpent
        updated.updatedAt = Date()
        
        return updated
    }
    
    func withMetadata(_ metadata: ResponseMetadata) -> SurveyResponse {
        var updated = self
        updated.metadata = metadata
        updated.updatedAt = Date()
        
        return updated
    }
    
    func withLocation(_ location: ResponseLocation) -> SurveyResponse {
        var updated = self
        updated.location = location
        updated.updatedAt = Date()
        
        return updated
    }
    
    func withValidationErrors(_ errors: [String]) -> SurveyResponse {
        var updated = self
        updated.validationErrors = errors.isEmpty ? nil : errors
        updated.updatedAt = Date()
        
        return updated
    }
    
    // MARK: - Computed Properties
    
    var isAnonymous: Bool {
        return userRef == nil
    }
    
    var completionPercentage: Double {
        guard !answers.isEmpty else { return 0 }
        let answeredCount = answers.filter { !$0.skipped }.count
        return (Double(answeredCount) / Double(answers.count)) * 100
    }
    
    var answeredQuestionCount: Int {
        return answers.filter { !$0.skipped }.count
    }
    
    var skippedQuestionCount: Int {
        return answers.filter { $0.skipped }.count
    }
    
    var hasValidationErrors: Bool {
        return validationErrors?.isEmpty == false
    }
    
    var averageTimePerQuestion: TimeInterval {
        guard answeredQuestionCount > 0 else { return 0 }
        return timeSpent / Double(answeredQuestionCount)
    }
    
    /// Get answer for specific question
    func answer(for questionId: String) -> SurveyAnswer? {
        return answers.first { $0.id == questionId }
    }
    
    /// Get all answers of a specific type
    func answers(ofType type: Survey.SurveyQuestion.QuestionType) -> [SurveyAnswer] {
        return answers.filter { $0.questionType == type }
    }
    
    /// Calculate sentiment score for text responses (simplified)
    var sentimentScore: Double? {
        let textAnswers = answers.compactMap { answer in
            if case .text(let text) = answer.value {
                return text
            }
            return nil
        }
        
        guard !textAnswers.isEmpty else { return nil }
        
        // Simple sentiment analysis based on word counting
        let positiveWords = ["good", "great", "excellent", "love", "amazing", "perfect", "wonderful", "satisfied", "happy", "pleased"]
        let negativeWords = ["bad", "terrible", "awful", "hate", "horrible", "poor", "disappointed", "unsatisfied", "unhappy", "frustrated"]
        
        var positiveCount = 0
        var negativeCount = 0
        
        for text in textAnswers {
            let words = text.lowercased().components(separatedBy: .whitespacesAndNewlines)
            positiveCount += words.filter { positiveWords.contains($0) }.count
            negativeCount += words.filter { negativeWords.contains($0) }.count
        }
        
        let totalWords = positiveCount + negativeCount
        guard totalWords > 0 else { return 0.5 } // Neutral
        
        return Double(positiveCount) / Double(totalWords)
    }
}

// MARK: - Extensions

extension DateFormatter {
    static let surveyDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
}

extension SurveyResponse {
    
    /// Export response data as CSV row
    func csvRow(includeHeaders: Bool = false) -> String {
        if includeHeaders {
            let headers = ["Response ID", "Survey ID", "User ID", "Submitted At", "Is Complete", "Time Spent", "Source", "Answers"]
            return headers.joined(separator: ",")
        }
        
        let responseId = id.recordName
        let surveyId = surveyRef.recordID.recordName
        let userId = userRef?.recordID.recordName ?? "Anonymous"
        let submittedAtString = DateFormatter.surveyDate.string(from: submittedAt)
        let timeSpentString = String(format: "%.2f", timeSpent / 60) // Convert to minutes
        let answersString = answers.map { "\($0.questionText): \($0.value.stringValue)" }.joined(separator: "; ")
        
        let fields = [responseId, surveyId, userId, submittedAtString, "\(isComplete)", timeSpentString, source.displayName, answersString]
        return fields.map { "\"\($0)\"" }.joined(separator: ",")
    }
    
    /// Generate summary statistics for numeric answers
    var numericSummary: [String: Double] {
        let numericAnswers = answers.compactMap { $0.value.numericValue }
        guard !numericAnswers.isEmpty else { return [:] }
        
        let sum = numericAnswers.reduce(0, +)
        let count = Double(numericAnswers.count)
        let average = sum / count
        let min = numericAnswers.min() ?? 0
        let max = numericAnswers.max() ?? 0
        
        return [
            "average": average,
            "min": min,
            "max": max,
            "sum": sum,
            "count": count
        ]
    }
}
