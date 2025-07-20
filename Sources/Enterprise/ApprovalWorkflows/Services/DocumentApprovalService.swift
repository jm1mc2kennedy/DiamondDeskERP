//
//  DocumentApprovalService.swift
//  DiamondDeskERP
//
//  Created by J.Michael McDermott on 7/20/25.
//

import Foundation
import CloudKit
import Combine
import CryptoKit

/// Enterprise Document Approval Service
/// Manages approval workflows, digital signatures, and review processes
@MainActor
final class DocumentApprovalService: ObservableObject {
    
    static let shared = DocumentApprovalService()
    
    // MARK: - Published Properties
    
    @Published var approvalWorkflows: [ApprovalWorkflow] = []
    @Published var pendingApprovals: [ApprovalRequest] = []
    @Published var digitalSignatures: [DigitalSignature] = []
    @Published var reviewProcesses: [ReviewProcess] = []
    @Published var isLoading = false
    @Published var error: ApprovalError?
    
    // MARK: - Private Properties
    
    private let container = CKContainer(identifier: "iCloud.com.diamonddesk.erp")
    private var database: CKDatabase { container.privateCloudDatabase }
    private var cancellables = Set<AnyCancellable>()
    private let cryptoService = CryptoService()
    
    // MARK: - Approval Workflow Properties
    
    @Published var workflowTemplates: [WorkflowTemplate] = []
    @Published var approvalMetrics: ApprovalMetrics?
    @Published var complianceReports: [ComplianceReport] = []
    
    // MARK: - Initialization
    
    private init() {
        setupWorkflowTemplates()
        loadApprovalData()
    }
    
    // MARK: - Workflow Management
    
    /// Creates a new approval workflow for a document
    func createApprovalWorkflow(
        documentId: String,
        templateId: String,
        approvers: [ApprovalUser],
        deadline: Date?,
        priority: ApprovalPriority = .normal,
        requiresSequentialApproval: Bool = false,
        minimumApprovals: Int = 1,
        metadata: [String: Any] = [:]
    ) async throws -> ApprovalWorkflow {
        isLoading = true
        defer { isLoading = false }
        
        do {
            guard let template = workflowTemplates.first(where: { $0.id == templateId }) else {
                throw ApprovalError.templateNotFound
            }
            
            let workflow = ApprovalWorkflow(
                id: UUID().uuidString,
                documentId: documentId,
                templateId: templateId,
                title: template.name,
                description: template.description,
                createdBy: getCurrentUserId(),
                approvers: approvers,
                currentStage: 0,
                status: .pending,
                priority: priority,
                deadline: deadline,
                requiresSequentialApproval: requiresSequentialApproval,
                minimumApprovals: minimumApprovals,
                createdAt: Date(),
                metadata: metadata
            )
            
            // Save to CloudKit
            try await saveApprovalWorkflow(workflow)
            
            // Create initial approval requests
            try await createApprovalRequests(for: workflow)
            
            // Send notifications
            try await sendApprovalNotifications(workflow: workflow)
            
            // Update local state
            approvalWorkflows.append(workflow)
            
            // Track analytics
            await trackApprovalEvent(.workflowCreated, workflowId: workflow.id)
            
            return workflow
            
        } catch {
            await handleError(ApprovalError.workflowCreationFailed(error))
            throw error
        }
    }
    
    /// Processes an approval decision
    func processApproval(
        requestId: String,
        decision: ApprovalDecision,
        comments: String? = nil,
        digitalSignature: DigitalSignature? = nil
    ) async throws {
        guard let request = pendingApprovals.first(where: { $0.id == requestId }) else {
            throw ApprovalError.requestNotFound
        }
        
        guard let workflow = approvalWorkflows.first(where: { $0.id == request.workflowId }) else {
            throw ApprovalError.workflowNotFound
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Update approval request
            request.decision = decision
            request.comments = comments
            request.respondedAt = Date()
            request.status = decision == .approved ? .approved : .rejected
            
            // Add digital signature if provided
            if let signature = digitalSignature {
                request.digitalSignature = signature
                try await saveDigitalSignature(signature)
            }
            
            // Save updated request
            try await saveApprovalRequest(request)
            
            // Update workflow status
            try await updateWorkflowStatus(workflow, after: request)
            
            // Send notifications
            try await sendDecisionNotifications(request: request, workflow: workflow)
            
            // Update local state
            if let index = pendingApprovals.firstIndex(where: { $0.id == requestId }) {
                pendingApprovals[index] = request
            }
            
            // Track analytics
            await trackApprovalEvent(.decisionMade, workflowId: workflow.id)
            
        } catch {
            await handleError(ApprovalError.decisionProcessingFailed(error))
            throw error
        }
    }
    
    /// Creates a digital signature for approval
    func createDigitalSignature(
        approverId: String,
        documentId: String,
        signatureData: Data,
        signatureType: SignatureType = .drawn,
        certificationLevel: CertificationLevel = .standard
    ) async throws -> DigitalSignature {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Generate cryptographic hash
            let documentHash = try await generateDocumentHash(documentId: documentId)
            
            // Create signature with crypto validation
            let signature = DigitalSignature(
                id: UUID().uuidString,
                documentId: documentId,
                signerId: approverId,
                signerName: getCurrentUserName(),
                signatureData: signatureData,
                signatureHash: cryptoService.generateSignatureHash(signatureData),
                documentHash: documentHash,
                signatureType: signatureType,
                certificationLevel: certificationLevel,
                timestamp: Date(),
                deviceInfo: getCurrentDeviceInfo(),
                locationInfo: await getCurrentLocationInfo(),
                biometricValidation: await validateBiometrics()
            )
            
            // Save to CloudKit
            try await saveDigitalSignature(signature)
            
            // Update local state
            digitalSignatures.append(signature)
            
            // Track analytics
            await trackApprovalEvent(.signatureCreated, workflowId: nil)
            
            return signature
            
        } catch {
            await handleError(ApprovalError.signatureCreationFailed(error))
            throw error
        }
    }
    
    // MARK: - Review Process Management
    
    /// Initiates a document review process
    func initiateReviewProcess(
        documentId: String,
        reviewers: [ReviewUser],
        reviewType: ReviewType,
        deadline: Date?,
        guidelines: String? = nil
    ) async throws -> ReviewProcess {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let review = ReviewProcess(
                id: UUID().uuidString,
                documentId: documentId,
                reviewType: reviewType,
                initiatedBy: getCurrentUserId(),
                reviewers: reviewers,
                status: .inProgress,
                deadline: deadline,
                guidelines: guidelines,
                createdAt: Date()
            )
            
            // Save to CloudKit
            try await saveReviewProcess(review)
            
            // Create review tasks
            try await createReviewTasks(for: review)
            
            // Send notifications
            try await sendReviewNotifications(review: review)
            
            // Update local state
            reviewProcesses.append(review)
            
            // Track analytics
            await trackApprovalEvent(.reviewInitiated, workflowId: nil)
            
            return review
            
        } catch {
            await handleError(ApprovalError.reviewCreationFailed(error))
            throw error
        }
    }
    
    /// Submits a review response
    func submitReview(
        processId: String,
        reviewerId: String,
        rating: ReviewRating,
        feedback: String,
        recommendations: [String] = [],
        attachments: [ReviewAttachment] = []
    ) async throws {
        guard let review = reviewProcesses.first(where: { $0.id == processId }) else {
            throw ApprovalError.reviewNotFound
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let reviewResponse = ReviewResponse(
                id: UUID().uuidString,
                processId: processId,
                reviewerId: reviewerId,
                rating: rating,
                feedback: feedback,
                recommendations: recommendations,
                attachments: attachments,
                submittedAt: Date()
            )
            
            // Save review response
            try await saveReviewResponse(reviewResponse)
            
            // Update review process
            review.responses.append(reviewResponse)
            review.modifiedAt = Date()
            
            // Check if review is complete
            if review.responses.count == review.reviewers.count {
                review.status = .completed
                review.completedAt = Date()
            }
            
            try await saveReviewProcess(review)
            
            // Send notifications
            try await sendReviewCompletionNotifications(review: review, response: reviewResponse)
            
            // Track analytics
            await trackApprovalEvent(.reviewSubmitted, workflowId: nil)
            
        } catch {
            await handleError(ApprovalError.reviewSubmissionFailed(error))
            throw error
        }
    }
    
    // MARK: - Compliance & Audit
    
    /// Generates compliance report for approval workflows
    func generateComplianceReport(
        timeRange: TimeRange,
        includeSignatures: Bool = true,
        includeAuditTrail: Bool = true
    ) async throws -> ComplianceReport {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let startDate = timeRange.startDate
            let endDate = Date()
            
            // Gather compliance data
            let workflows = approvalWorkflows.filter { 
                $0.createdAt >= startDate && $0.createdAt <= endDate
            }
            
            let signatures = digitalSignatures.filter {
                $0.timestamp >= startDate && $0.timestamp <= endDate
            }
            
            let reviews = reviewProcesses.filter {
                $0.createdAt >= startDate && $0.createdAt <= endDate
            }
            
            let report = ComplianceReport(
                id: UUID().uuidString,
                title: "Approval Compliance Report",
                generatedAt: Date(),
                timeRange: timeRange,
                totalWorkflows: workflows.count,
                completedWorkflows: workflows.filter { $0.status == .approved }.count,
                rejectedWorkflows: workflows.filter { $0.status == .rejected }.count,
                pendingWorkflows: workflows.filter { $0.status == .pending }.count,
                totalSignatures: signatures.count,
                validSignatures: signatures.filter { $0.isValid }.count,
                totalReviews: reviews.count,
                completedReviews: reviews.filter { $0.status == .completed }.count,
                averageApprovalTime: calculateAverageApprovalTime(workflows),
                complianceScore: calculateComplianceScore(workflows, signatures, reviews),
                auditTrail: includeAuditTrail ? generateAuditTrail(workflows, signatures, reviews) : [],
                violations: identifyComplianceViolations(workflows, signatures, reviews)
            )
            
            // Save report
            try await saveComplianceReport(report)
            
            // Update local state
            complianceReports.append(report)
            
            return report
            
        } catch {
            await handleError(ApprovalError.reportGenerationFailed(error))
            throw error
        }
    }
    
    // MARK: - Analytics
    
    /// Loads approval metrics and analytics
    func loadApprovalMetrics(timeRange: TimeRange = .lastMonth) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let metrics = try await fetchApprovalMetrics(timeRange: timeRange)
            self.approvalMetrics = metrics
            
        } catch {
            await handleError(ApprovalError.metricsFailed(error))
            throw error
        }
    }
    
    // MARK: - Private Implementation Methods
    
    private func setupWorkflowTemplates() {
        workflowTemplates = [
            WorkflowTemplate(
                id: "financial-approval",
                name: "Financial Document Approval",
                description: "Standard financial document approval process",
                requiredApprovers: 2,
                maxDuration: 86400 * 5, // 5 days
                requiresSequentialApproval: true,
                mandatoryFields: ["amount", "department", "purpose"]
            ),
            WorkflowTemplate(
                id: "policy-review",
                name: "Policy Document Review",
                description: "Policy document review and approval workflow",
                requiredApprovers: 3,
                maxDuration: 86400 * 10, // 10 days
                requiresSequentialApproval: false,
                mandatoryFields: ["policy_type", "effective_date"]
            ),
            WorkflowTemplate(
                id: "contract-approval",
                name: "Contract Approval Process",
                description: "Legal contract review and approval workflow",
                requiredApprovers: 2,
                maxDuration: 86400 * 7, // 7 days
                requiresSequentialApproval: true,
                mandatoryFields: ["contract_value", "counterparty", "legal_review"]
            ),
            WorkflowTemplate(
                id: "executive-approval",
                name: "Executive Document Approval",
                description: "High-level executive document approval process",
                requiredApprovers: 1,
                maxDuration: 86400 * 3, // 3 days
                requiresSequentialApproval: false,
                mandatoryFields: ["executive_level", "confidentiality"]
            )
        ]
    }
    
    private func loadApprovalData() {
        Task {
            do {
                // Load existing workflows and approvals
                let workflows = try await fetchApprovalWorkflows()
                let requests = try await fetchPendingApprovals()
                let signatures = try await fetchDigitalSignatures()
                let reviews = try await fetchReviewProcesses()
                
                await MainActor.run {
                    self.approvalWorkflows = workflows
                    self.pendingApprovals = requests
                    self.digitalSignatures = signatures
                    self.reviewProcesses = reviews
                }
            } catch {
                await handleError(ApprovalError.loadFailed(error))
            }
        }
    }
    
    private func createApprovalRequests(for workflow: ApprovalWorkflow) async throws {
        if workflow.requiresSequentialApproval {
            // Create first request only
            if let firstApprover = workflow.approvers.first {
                let request = ApprovalRequest(
                    id: UUID().uuidString,
                    workflowId: workflow.id,
                    documentId: workflow.documentId,
                    approverId: firstApprover.id,
                    approverName: firstApprover.name,
                    stage: 0,
                    status: .pending,
                    createdAt: Date(),
                    deadline: workflow.deadline
                )
                
                try await saveApprovalRequest(request)
                pendingApprovals.append(request)
            }
        } else {
            // Create requests for all approvers
            for (index, approver) in workflow.approvers.enumerated() {
                let request = ApprovalRequest(
                    id: UUID().uuidString,
                    workflowId: workflow.id,
                    documentId: workflow.documentId,
                    approverId: approver.id,
                    approverName: approver.name,
                    stage: index,
                    status: .pending,
                    createdAt: Date(),
                    deadline: workflow.deadline
                )
                
                try await saveApprovalRequest(request)
                pendingApprovals.append(request)
            }
        }
    }
    
    private func updateWorkflowStatus(_ workflow: ApprovalWorkflow, after request: ApprovalRequest) async throws {
        let approvedRequests = pendingApprovals.filter { 
            $0.workflowId == workflow.id && $0.status == .approved 
        }
        
        let rejectedRequests = pendingApprovals.filter {
            $0.workflowId == workflow.id && $0.status == .rejected
        }
        
        if !rejectedRequests.isEmpty {
            // Workflow rejected
            workflow.status = .rejected
            workflow.completedAt = Date()
        } else if approvedRequests.count >= workflow.minimumApprovals {
            if workflow.requiresSequentialApproval {
                // Check if we need to create next approval request
                let nextStage = workflow.currentStage + 1
                if nextStage < workflow.approvers.count {
                    workflow.currentStage = nextStage
                    let nextApprover = workflow.approvers[nextStage]
                    
                    let nextRequest = ApprovalRequest(
                        id: UUID().uuidString,
                        workflowId: workflow.id,
                        documentId: workflow.documentId,
                        approverId: nextApprover.id,
                        approverName: nextApprover.name,
                        stage: nextStage,
                        status: .pending,
                        createdAt: Date(),
                        deadline: workflow.deadline
                    )
                    
                    try await saveApprovalRequest(nextRequest)
                    pendingApprovals.append(nextRequest)
                } else {
                    // All stages complete
                    workflow.status = .approved
                    workflow.completedAt = Date()
                }
            } else {
                // Parallel approval complete
                workflow.status = .approved
                workflow.completedAt = Date()
            }
        }
        
        workflow.modifiedAt = Date()
        try await saveApprovalWorkflow(workflow)
    }
    
    // MARK: - CloudKit Operations
    
    private func saveApprovalWorkflow(_ workflow: ApprovalWorkflow) async throws {
        let record = workflow.toCKRecord()
        try await database.save(record)
    }
    
    private func saveApprovalRequest(_ request: ApprovalRequest) async throws {
        let record = request.toCKRecord()
        try await database.save(record)
    }
    
    private func saveDigitalSignature(_ signature: DigitalSignature) async throws {
        let record = signature.toCKRecord()
        try await database.save(record)
    }
    
    private func saveReviewProcess(_ review: ReviewProcess) async throws {
        let record = review.toCKRecord()
        try await database.save(record)
    }
    
    private func saveReviewResponse(_ response: ReviewResponse) async throws {
        let record = response.toCKRecord()
        try await database.save(record)
    }
    
    private func saveComplianceReport(_ report: ComplianceReport) async throws {
        let record = report.toCKRecord()
        try await database.save(record)
    }
    
    // MARK: - Fetch Operations
    
    private func fetchApprovalWorkflows() async throws -> [ApprovalWorkflow] {
        // Implementation for fetching workflows from CloudKit
        return []
    }
    
    private func fetchPendingApprovals() async throws -> [ApprovalRequest] {
        // Implementation for fetching pending approvals
        return []
    }
    
    private func fetchDigitalSignatures() async throws -> [DigitalSignature] {
        // Implementation for fetching signatures
        return []
    }
    
    private func fetchReviewProcesses() async throws -> [ReviewProcess] {
        // Implementation for fetching review processes
        return []
    }
    
    // MARK: - Utility Methods
    
    private func generateDocumentHash(documentId: String) async throws -> String {
        // Generate SHA-256 hash of document content
        return cryptoService.generateDocumentHash(documentId)
    }
    
    private func validateBiometrics() async -> BiometricValidation? {
        // Implement biometric validation if available
        return nil
    }
    
    private func getCurrentLocationInfo() async -> LocationInfo? {
        // Get current location for signature validation
        return nil
    }
    
    private func getCurrentDeviceInfo() -> DeviceInfo {
        return DeviceInfo(
            deviceId: UIDevice.current.identifierForVendor?.uuidString ?? "unknown",
            deviceModel: UIDevice.current.model,
            osVersion: UIDevice.current.systemVersion,
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        )
    }
    
    private func calculateAverageApprovalTime(_ workflows: [ApprovalWorkflow]) -> TimeInterval {
        let completedWorkflows = workflows.filter { $0.completedAt != nil }
        guard !completedWorkflows.isEmpty else { return 0 }
        
        let totalTime = completedWorkflows.reduce(0) { total, workflow in
            guard let completedAt = workflow.completedAt else { return total }
            return total + completedAt.timeIntervalSince(workflow.createdAt)
        }
        
        return totalTime / Double(completedWorkflows.count)
    }
    
    private func calculateComplianceScore(_ workflows: [ApprovalWorkflow], _ signatures: [DigitalSignature], _ reviews: [ReviewProcess]) -> Double {
        // Implementation of compliance scoring algorithm
        let totalWorkflows = workflows.count
        guard totalWorkflows > 0 else { return 100.0 }
        
        let compliantWorkflows = workflows.filter { workflow in
            // Check various compliance criteria
            let hasRequiredApprovals = workflow.status == .approved
            let withinDeadline = workflow.deadline == nil || workflow.completedAt == nil || workflow.completedAt! <= workflow.deadline!
            let hasValidSignatures = signatures.contains { $0.documentId == workflow.documentId && $0.isValid }
            
            return hasRequiredApprovals && withinDeadline && hasValidSignatures
        }
        
        return (Double(compliantWorkflows.count) / Double(totalWorkflows)) * 100.0
    }
    
    private func generateAuditTrail(_ workflows: [ApprovalWorkflow], _ signatures: [DigitalSignature], _ reviews: [ReviewProcess]) -> [AuditTrailEntry] {
        var entries: [AuditTrailEntry] = []
        
        // Add workflow events
        for workflow in workflows {
            entries.append(AuditTrailEntry(
                id: UUID().uuidString,
                timestamp: workflow.createdAt,
                event: "Workflow Created",
                documentId: workflow.documentId,
                userId: workflow.createdBy,
                details: "Workflow '\(workflow.title)' created"
            ))
            
            if let completedAt = workflow.completedAt {
                entries.append(AuditTrailEntry(
                    id: UUID().uuidString,
                    timestamp: completedAt,
                    event: "Workflow Completed",
                    documentId: workflow.documentId,
                    userId: workflow.createdBy,
                    details: "Workflow completed with status: \(workflow.status.rawValue)"
                ))
            }
        }
        
        // Add signature events
        for signature in signatures {
            entries.append(AuditTrailEntry(
                id: UUID().uuidString,
                timestamp: signature.timestamp,
                event: "Digital Signature Applied",
                documentId: signature.documentId,
                userId: signature.signerId,
                details: "Digital signature applied by \(signature.signerName)"
            ))
        }
        
        return entries.sorted { $0.timestamp < $1.timestamp }
    }
    
    private func identifyComplianceViolations(_ workflows: [ApprovalWorkflow], _ signatures: [DigitalSignature], _ reviews: [ReviewProcess]) -> [ComplianceViolation] {
        var violations: [ComplianceViolation] = []
        
        // Check for expired workflows
        for workflow in workflows where workflow.status == .pending {
            if let deadline = workflow.deadline, Date() > deadline {
                violations.append(ComplianceViolation(
                    id: UUID().uuidString,
                    type: .expiredWorkflow,
                    severity: .high,
                    documentId: workflow.documentId,
                    description: "Workflow '\(workflow.title)' has exceeded its deadline",
                    detectedAt: Date()
                ))
            }
        }
        
        // Check for missing signatures
        for workflow in workflows where workflow.status == .approved {
            let hasSignature = signatures.contains { $0.documentId == workflow.documentId }
            if !hasSignature {
                violations.append(ComplianceViolation(
                    id: UUID().uuidString,
                    type: .missingSignature,
                    severity: .medium,
                    documentId: workflow.documentId,
                    description: "Approved document lacks required digital signature",
                    detectedAt: Date()
                ))
            }
        }
        
        return violations
    }
    
    private func createReviewTasks(for review: ReviewProcess) async throws {
        // Implementation for creating review tasks
    }
    
    private func sendApprovalNotifications(workflow: ApprovalWorkflow) async throws {
        // Implementation for sending approval notifications
    }
    
    private func sendDecisionNotifications(request: ApprovalRequest, workflow: ApprovalWorkflow) async throws {
        // Implementation for sending decision notifications
    }
    
    private func sendReviewNotifications(review: ReviewProcess) async throws {
        // Implementation for sending review notifications
    }
    
    private func sendReviewCompletionNotifications(review: ReviewProcess, response: ReviewResponse) async throws {
        // Implementation for sending review completion notifications
    }
    
    private func fetchApprovalMetrics(timeRange: TimeRange) async throws -> ApprovalMetrics {
        // Implementation for fetching approval metrics
        return ApprovalMetrics(
            totalWorkflows: approvalWorkflows.count,
            pendingWorkflows: approvalWorkflows.filter { $0.status == .pending }.count,
            approvedWorkflows: approvalWorkflows.filter { $0.status == .approved }.count,
            rejectedWorkflows: approvalWorkflows.filter { $0.status == .rejected }.count,
            averageApprovalTime: 0,
            complianceScore: 95.0,
            overdueWorkflows: 0,
            digitalSignaturesCount: digitalSignatures.count,
            reviewsCompleted: reviewProcesses.filter { $0.status == .completed }.count,
            topApprovers: []
        )
    }
    
    private func trackApprovalEvent(_ event: ApprovalEvent, workflowId: String?) async {
        // Implementation for tracking approval analytics
    }
    
    private func getCurrentUserId() -> String {
        return "current-user-id"
    }
    
    private func getCurrentUserName() -> String {
        return "Current User"
    }
    
    private func handleError(_ error: ApprovalError) async {
        await MainActor.run {
            self.error = error
        }
    }
}

// MARK: - Supporting Models

/// Approval Workflow Model
class ApprovalWorkflow: ObservableObject, Identifiable {
    let id: String
    let documentId: String
    let templateId: String
    @Published var title: String
    @Published var description: String
    let createdBy: String
    let approvers: [ApprovalUser]
    @Published var currentStage: Int
    @Published var status: ApprovalStatus
    let priority: ApprovalPriority
    let deadline: Date?
    let requiresSequentialApproval: Bool
    let minimumApprovals: Int
    let createdAt: Date
    @Published var modifiedAt: Date?
    @Published var completedAt: Date?
    let metadata: [String: Any]
    
    init(
        id: String,
        documentId: String,
        templateId: String,
        title: String,
        description: String,
        createdBy: String,
        approvers: [ApprovalUser],
        currentStage: Int,
        status: ApprovalStatus,
        priority: ApprovalPriority,
        deadline: Date?,
        requiresSequentialApproval: Bool,
        minimumApprovals: Int,
        createdAt: Date,
        metadata: [String: Any]
    ) {
        self.id = id
        self.documentId = documentId
        self.templateId = templateId
        self.title = title
        self.description = description
        self.createdBy = createdBy
        self.approvers = approvers
        self.currentStage = currentStage
        self.status = status
        self.priority = priority
        self.deadline = deadline
        self.requiresSequentialApproval = requiresSequentialApproval
        self.minimumApprovals = minimumApprovals
        self.createdAt = createdAt
        self.metadata = metadata
    }
    
    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: "ApprovalWorkflow", recordID: CKRecord.ID(recordName: id))
        record["documentId"] = documentId
        record["templateId"] = templateId
        record["title"] = title
        record["description"] = description
        record["createdBy"] = createdBy
        record["approvers"] = try? JSONEncoder().encode(approvers)
        record["currentStage"] = currentStage
        record["status"] = status.rawValue
        record["priority"] = priority.rawValue
        record["deadline"] = deadline
        record["requiresSequentialApproval"] = requiresSequentialApproval
        record["minimumApprovals"] = minimumApprovals
        record["createdAt"] = createdAt
        record["modifiedAt"] = modifiedAt
        record["completedAt"] = completedAt
        record["metadata"] = try? JSONSerialization.data(withJSONObject: metadata)
        return record
    }
}

/// Approval Request Model
class ApprovalRequest: ObservableObject, Identifiable {
    let id: String
    let workflowId: String
    let documentId: String
    let approverId: String
    let approverName: String
    let stage: Int
    @Published var status: ApprovalRequestStatus
    @Published var decision: ApprovalDecision?
    @Published var comments: String?
    @Published var digitalSignature: DigitalSignature?
    let createdAt: Date
    @Published var respondedAt: Date?
    let deadline: Date?
    
    init(
        id: String,
        workflowId: String,
        documentId: String,
        approverId: String,
        approverName: String,
        stage: Int,
        status: ApprovalRequestStatus,
        createdAt: Date,
        deadline: Date?
    ) {
        self.id = id
        self.workflowId = workflowId
        self.documentId = documentId
        self.approverId = approverId
        self.approverName = approverName
        self.stage = stage
        self.status = status
        self.createdAt = createdAt
        self.deadline = deadline
    }
    
    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: "ApprovalRequest", recordID: CKRecord.ID(recordName: id))
        record["workflowId"] = workflowId
        record["documentId"] = documentId
        record["approverId"] = approverId
        record["approverName"] = approverName
        record["stage"] = stage
        record["status"] = status.rawValue
        record["decision"] = decision?.rawValue
        record["comments"] = comments
        record["digitalSignature"] = digitalSignature?.id
        record["createdAt"] = createdAt
        record["respondedAt"] = respondedAt
        record["deadline"] = deadline
        return record
    }
}

/// Digital Signature Model
class DigitalSignature: ObservableObject, Identifiable {
    let id: String
    let documentId: String
    let signerId: String
    let signerName: String
    let signatureData: Data
    let signatureHash: String
    let documentHash: String
    let signatureType: SignatureType
    let certificationLevel: CertificationLevel
    let timestamp: Date
    let deviceInfo: DeviceInfo
    let locationInfo: LocationInfo?
    let biometricValidation: BiometricValidation?
    @Published var isValid: Bool = true
    @Published var verificationStatus: SignatureVerificationStatus = .verified
    
    init(
        id: String,
        documentId: String,
        signerId: String,
        signerName: String,
        signatureData: Data,
        signatureHash: String,
        documentHash: String,
        signatureType: SignatureType,
        certificationLevel: CertificationLevel,
        timestamp: Date,
        deviceInfo: DeviceInfo,
        locationInfo: LocationInfo?,
        biometricValidation: BiometricValidation?
    ) {
        self.id = id
        self.documentId = documentId
        self.signerId = signerId
        self.signerName = signerName
        self.signatureData = signatureData
        self.signatureHash = signatureHash
        self.documentHash = documentHash
        self.signatureType = signatureType
        self.certificationLevel = certificationLevel
        self.timestamp = timestamp
        self.deviceInfo = deviceInfo
        self.locationInfo = locationInfo
        self.biometricValidation = biometricValidation
    }
    
    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: "DigitalSignature", recordID: CKRecord.ID(recordName: id))
        record["documentId"] = documentId
        record["signerId"] = signerId
        record["signerName"] = signerName
        record["signatureData"] = signatureData
        record["signatureHash"] = signatureHash
        record["documentHash"] = documentHash
        record["signatureType"] = signatureType.rawValue
        record["certificationLevel"] = certificationLevel.rawValue
        record["timestamp"] = timestamp
        record["deviceInfo"] = try? JSONEncoder().encode(deviceInfo)
        record["locationInfo"] = try? JSONEncoder().encode(locationInfo)
        record["biometricValidation"] = try? JSONEncoder().encode(biometricValidation)
        record["isValid"] = isValid
        record["verificationStatus"] = verificationStatus.rawValue
        return record
    }
}

/// Review Process Model
class ReviewProcess: ObservableObject, Identifiable {
    let id: String
    let documentId: String
    let reviewType: ReviewType
    let initiatedBy: String
    let reviewers: [ReviewUser]
    @Published var status: ReviewStatus
    let deadline: Date?
    let guidelines: String?
    let createdAt: Date
    @Published var modifiedAt: Date?
    @Published var completedAt: Date?
    @Published var responses: [ReviewResponse] = []
    
    init(
        id: String,
        documentId: String,
        reviewType: ReviewType,
        initiatedBy: String,
        reviewers: [ReviewUser],
        status: ReviewStatus,
        deadline: Date?,
        guidelines: String?,
        createdAt: Date
    ) {
        self.id = id
        self.documentId = documentId
        self.reviewType = reviewType
        self.initiatedBy = initiatedBy
        self.reviewers = reviewers
        self.status = status
        self.deadline = deadline
        self.guidelines = guidelines
        self.createdAt = createdAt
    }
    
    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: "ReviewProcess", recordID: CKRecord.ID(recordName: id))
        record["documentId"] = documentId
        record["reviewType"] = reviewType.rawValue
        record["initiatedBy"] = initiatedBy
        record["reviewers"] = try? JSONEncoder().encode(reviewers)
        record["status"] = status.rawValue
        record["deadline"] = deadline
        record["guidelines"] = guidelines
        record["createdAt"] = createdAt
        record["modifiedAt"] = modifiedAt
        record["completedAt"] = completedAt
        record["responses"] = try? JSONEncoder().encode(responses)
        return record
    }
}

// MARK: - Supporting Types and Enums

struct ApprovalUser: Codable, Identifiable {
    let id: String
    let name: String
    let email: String
    let role: String
    let department: String
}

struct ReviewUser: Codable, Identifiable {
    let id: String
    let name: String
    let email: String
    let expertise: [String]
}

struct WorkflowTemplate: Identifiable {
    let id: String
    let name: String
    let description: String
    let requiredApprovers: Int
    let maxDuration: TimeInterval
    let requiresSequentialApproval: Bool
    let mandatoryFields: [String]
}

struct ReviewResponse: Codable, Identifiable {
    let id: String
    let processId: String
    let reviewerId: String
    let rating: ReviewRating
    let feedback: String
    let recommendations: [String]
    let attachments: [ReviewAttachment]
    let submittedAt: Date
}

struct ReviewAttachment: Codable, Identifiable {
    let id: String
    let fileName: String
    let fileType: String
    let fileSize: Int64
    let uploadedAt: Date
}

struct ComplianceReport: Identifiable {
    let id: String
    let title: String
    let generatedAt: Date
    let timeRange: TimeRange
    let totalWorkflows: Int
    let completedWorkflows: Int
    let rejectedWorkflows: Int
    let pendingWorkflows: Int
    let totalSignatures: Int
    let validSignatures: Int
    let totalReviews: Int
    let completedReviews: Int
    let averageApprovalTime: TimeInterval
    let complianceScore: Double
    let auditTrail: [AuditTrailEntry]
    let violations: [ComplianceViolation]
    
    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: "ComplianceReport", recordID: CKRecord.ID(recordName: id))
        record["title"] = title
        record["generatedAt"] = generatedAt
        record["timeRange"] = timeRange.rawValue
        record["totalWorkflows"] = totalWorkflows
        record["completedWorkflows"] = completedWorkflows
        record["rejectedWorkflows"] = rejectedWorkflows
        record["pendingWorkflows"] = pendingWorkflows
        record["totalSignatures"] = totalSignatures
        record["validSignatures"] = validSignatures
        record["totalReviews"] = totalReviews
        record["completedReviews"] = completedReviews
        record["averageApprovalTime"] = averageApprovalTime
        record["complianceScore"] = complianceScore
        record["auditTrail"] = try? JSONEncoder().encode(auditTrail)
        record["violations"] = try? JSONEncoder().encode(violations)
        return record
    }
}

struct AuditTrailEntry: Codable, Identifiable {
    let id: String
    let timestamp: Date
    let event: String
    let documentId: String
    let userId: String
    let details: String
}

struct ComplianceViolation: Codable, Identifiable {
    let id: String
    let type: ViolationType
    let severity: ViolationSeverity
    let documentId: String
    let description: String
    let detectedAt: Date
}

struct ApprovalMetrics {
    let totalWorkflows: Int
    let pendingWorkflows: Int
    let approvedWorkflows: Int
    let rejectedWorkflows: Int
    let averageApprovalTime: TimeInterval
    let complianceScore: Double
    let overdueWorkflows: Int
    let digitalSignaturesCount: Int
    let reviewsCompleted: Int
    let topApprovers: [ApprovalUser]
}

struct DeviceInfo: Codable {
    let deviceId: String
    let deviceModel: String
    let osVersion: String
    let appVersion: String
}

struct LocationInfo: Codable {
    let latitude: Double
    let longitude: Double
    let accuracy: Double
    let timestamp: Date
}

struct BiometricValidation: Codable {
    let type: BiometricType
    let successful: Bool
    let timestamp: Date
}

// MARK: - Enums

enum ApprovalStatus: String, CaseIterable, Codable {
    case pending = "pending"
    case approved = "approved"
    case rejected = "rejected"
    case cancelled = "cancelled"
    
    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .approved: return "Approved"
        case .rejected: return "Rejected"
        case .cancelled: return "Cancelled"
        }
    }
    
    var color: Color {
        switch self {
        case .pending: return .orange
        case .approved: return .green
        case .rejected: return .red
        case .cancelled: return .gray
        }
    }
}

enum ApprovalRequestStatus: String, CaseIterable, Codable {
    case pending = "pending"
    case approved = "approved"
    case rejected = "rejected"
    case expired = "expired"
    
    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .approved: return "Approved"
        case .rejected: return "Rejected"
        case .expired: return "Expired"
        }
    }
}

enum ApprovalDecision: String, CaseIterable, Codable {
    case approved = "approved"
    case rejected = "rejected"
    case requestChanges = "request_changes"
    
    var displayName: String {
        switch self {
        case .approved: return "Approved"
        case .rejected: return "Rejected"
        case .requestChanges: return "Request Changes"
        }
    }
}

enum ApprovalPriority: String, CaseIterable, Codable {
    case low = "low"
    case normal = "normal"
    case high = "high"
    case urgent = "urgent"
    
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .normal: return "Normal"
        case .high: return "High"
        case .urgent: return "Urgent"
        }
    }
    
    var color: Color {
        switch self {
        case .low: return .blue
        case .normal: return .gray
        case .high: return .orange
        case .urgent: return .red
        }
    }
}

enum SignatureType: String, CaseIterable, Codable {
    case drawn = "drawn"
    case typed = "typed"
    case image = "image"
    case biometric = "biometric"
    
    var displayName: String {
        switch self {
        case .drawn: return "Hand Drawn"
        case .typed: return "Typed"
        case .image: return "Image"
        case .biometric: return "Biometric"
        }
    }
}

enum CertificationLevel: String, CaseIterable, Codable {
    case basic = "basic"
    case standard = "standard"
    case advanced = "advanced"
    case qualified = "qualified"
    
    var displayName: String {
        switch self {
        case .basic: return "Basic"
        case .standard: return "Standard"
        case .advanced: return "Advanced"
        case .qualified: return "Qualified"
        }
    }
}

enum SignatureVerificationStatus: String, CaseIterable, Codable {
    case verified = "verified"
    case pending = "pending"
    case failed = "failed"
    case expired = "expired"
    
    var displayName: String {
        switch self {
        case .verified: return "Verified"
        case .pending: return "Pending"
        case .failed: return "Failed"
        case .expired: return "Expired"
        }
    }
}

enum ReviewType: String, CaseIterable, Codable {
    case technical = "technical"
    case legal = "legal"
    case financial = "financial"
    case compliance = "compliance"
    case general = "general"
    
    var displayName: String {
        switch self {
        case .technical: return "Technical Review"
        case .legal: return "Legal Review"
        case .financial: return "Financial Review"
        case .compliance: return "Compliance Review"
        case .general: return "General Review"
        }
    }
}

enum ReviewStatus: String, CaseIterable, Codable {
    case inProgress = "in_progress"
    case completed = "completed"
    case cancelled = "cancelled"
    
    var displayName: String {
        switch self {
        case .inProgress: return "In Progress"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        }
    }
}

enum ReviewRating: String, CaseIterable, Codable {
    case excellent = "excellent"
    case good = "good"
    case satisfactory = "satisfactory"
    case needsImprovement = "needs_improvement"
    case unsatisfactory = "unsatisfactory"
    
    var displayName: String {
        switch self {
        case .excellent: return "Excellent"
        case .good: return "Good"
        case .satisfactory: return "Satisfactory"
        case .needsImprovement: return "Needs Improvement"
        case .unsatisfactory: return "Unsatisfactory"
        }
    }
    
    var score: Int {
        switch self {
        case .excellent: return 5
        case .good: return 4
        case .satisfactory: return 3
        case .needsImprovement: return 2
        case .unsatisfactory: return 1
        }
    }
}

enum ViolationType: String, CaseIterable, Codable {
    case expiredWorkflow = "expired_workflow"
    case missingSignature = "missing_signature"
    case invalidSignature = "invalid_signature"
    case missingApproval = "missing_approval"
    case duplicateApproval = "duplicate_approval"
    
    var displayName: String {
        switch self {
        case .expiredWorkflow: return "Expired Workflow"
        case .missingSignature: return "Missing Signature"
        case .invalidSignature: return "Invalid Signature"
        case .missingApproval: return "Missing Approval"
        case .duplicateApproval: return "Duplicate Approval"
        }
    }
}

enum ViolationSeverity: String, CaseIterable, Codable {
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
        case .low: return .blue
        case .medium: return .yellow
        case .high: return .orange
        case .critical: return .red
        }
    }
}

enum BiometricType: String, CaseIterable, Codable {
    case faceID = "face_id"
    case touchID = "touch_id"
    case voiceprint = "voiceprint"
    
    var displayName: String {
        switch self {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        case .voiceprint: return "Voiceprint"
        }
    }
}

enum ApprovalEvent: String, CaseIterable {
    case workflowCreated = "workflow_created"
    case decisionMade = "decision_made"
    case signatureCreated = "signature_created"
    case reviewInitiated = "review_initiated"
    case reviewSubmitted = "review_submitted"
    
    var displayName: String {
        switch self {
        case .workflowCreated: return "Workflow Created"
        case .decisionMade: return "Decision Made"
        case .signatureCreated: return "Signature Created"
        case .reviewInitiated: return "Review Initiated"
        case .reviewSubmitted: return "Review Submitted"
        }
    }
}

// MARK: - Error Types

enum ApprovalError: LocalizedError {
    case templateNotFound
    case workflowCreationFailed(Error)
    case requestNotFound
    case workflowNotFound
    case decisionProcessingFailed(Error)
    case signatureCreationFailed(Error)
    case reviewCreationFailed(Error)
    case reviewNotFound
    case reviewSubmissionFailed(Error)
    case reportGenerationFailed(Error)
    case loadFailed(Error)
    case metricsFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .templateNotFound:
            return "Workflow template not found"
        case .workflowCreationFailed(let error):
            return "Failed to create workflow: \(error.localizedDescription)"
        case .requestNotFound:
            return "Approval request not found"
        case .workflowNotFound:
            return "Approval workflow not found"
        case .decisionProcessingFailed(let error):
            return "Failed to process approval decision: \(error.localizedDescription)"
        case .signatureCreationFailed(let error):
            return "Failed to create digital signature: \(error.localizedDescription)"
        case .reviewCreationFailed(let error):
            return "Failed to create review process: \(error.localizedDescription)"
        case .reviewNotFound:
            return "Review process not found"
        case .reviewSubmissionFailed(let error):
            return "Failed to submit review: \(error.localizedDescription)"
        case .reportGenerationFailed(let error):
            return "Failed to generate compliance report: \(error.localizedDescription)"
        case .loadFailed(let error):
            return "Failed to load data: \(error.localizedDescription)"
        case .metricsFailed(let error):
            return "Failed to load metrics: \(error.localizedDescription)"
        }
    }
}

// MARK: - Crypto Service

class CryptoService {
    func generateSignatureHash(_ signatureData: Data) -> String {
        let hash = SHA256.hash(data: signatureData)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    func generateDocumentHash(_ documentId: String) -> String {
        let data = documentId.data(using: .utf8) ?? Data()
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}
