import Foundation
import CloudKit
import Combine

/// Comprehensive Vendor Lifecycle Management Service
/// Implements PT3VS1 specifications for vendor relationship management (VRM)
@MainActor
class VendorLifecycleService: ObservableObject {
    
    @Published var vendors: [VendorModel] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Performance Analytics
    @Published var performanceMetrics: VendorPerformanceMetrics = VendorPerformanceMetrics()
    @Published var benchmarkData: [BenchmarkResult] = []
    
    // Lifecycle Management
    @Published var onboardingQueue: [VendorModel] = []
    @Published var renewalAlerts: [RenewalAlert] = []
    @Published var riskAlerts: [RiskAlert] = []
    
    private let container: CKContainer
    private let database: CKDatabase
    private let vendorCache: NSCache<NSString, VendorModel>
    private var cancellables = Set<AnyCancellable>()
    
    // Automation Rules Engine
    private let automationEngine: VendorAutomationEngine
    
    init(container: CKContainer = CKContainer.default()) {
        self.container = container
        self.database = container.privateCloudDatabase
        self.vendorCache = NSCache<NSString, VendorModel>()
        self.vendorCache.countLimit = 200
        self.automationEngine = VendorAutomationEngine()
        
        setupNotifications()
        setupAutomationTriggers()
    }
    
    // MARK: - Core CRUD Operations
    
    /// Create new vendor with lifecycle initialization
    func createVendor(_ vendor: VendorModel) async throws -> VendorModel {
        isLoading = true
        defer { isLoading = false }
        
        var newVendor = vendor
        newVendor.updatedAt = Date()
        
        // Initialize lifecycle stage and onboarding
        if newVendor.lifecycleStage == .prospect {
            newVendor.onboardingProgress = OnboardingProgress()
            newVendor.onboardingProgress.startDate = Date()
            newVendor.onboardingProgress.expectedCompletionDate = Calendar.current.date(
                byAdding: .day, 
                value: 30, 
                to: Date()
            )
            
            // Create initial onboarding tasks
            newVendor.onboardingProgress.onboardingTasks = createInitialOnboardingTasks()
        }
        
        // Validate vendor data
        try validateVendorData(newVendor)
        
        // Run automation rules
        newVendor = await automationEngine.processNewVendor(newVendor)
        
        let record = newVendor.toCKRecord()
        let savedRecord = try await database.save(record)
        
        guard let savedVendor = VendorModel.fromCKRecord(savedRecord) else {
            throw VendorLifecycleError.serializationFailed
        }
        
        // Update local cache and state
        vendors.append(savedVendor)
        vendorCache.setObject(savedVendor, forKey: savedVendor.id as NSString)
        
        // Trigger lifecycle events
        await triggerLifecycleEvent(.vendorCreated, for: savedVendor)
        
        return savedVendor
    }
    
    /// Update vendor with lifecycle validation
    func updateVendor(_ vendor: VendorModel) async throws -> VendorModel {
        isLoading = true
        defer { isLoading = false }
        
        guard let existingVendor = vendors.first(where: { $0.id == vendor.id }) else {
            throw VendorLifecycleError.vendorNotFound(id: vendor.id)
        }
        
        var updatedVendor = vendor
        updatedVendor.updatedAt = Date()
        
        // Check for lifecycle stage changes
        if existingVendor.lifecycleStage != updatedVendor.lifecycleStage {
            try await validateLifecycleTransition(
                from: existingVendor.lifecycleStage,
                to: updatedVendor.lifecycleStage,
                for: vendor.id
            )
            
            updatedVendor = await processLifecycleStageChange(
                vendor: updatedVendor,
                previousStage: existingVendor.lifecycleStage
            )
        }
        
        // Validate vendor data
        try validateVendorData(updatedVendor)
        
        // Run automation rules
        updatedVendor = await automationEngine.processVendorUpdate(updatedVendor, previousVendor: existingVendor)
        
        let record = updatedVendor.toCKRecord()
        let savedRecord = try await database.save(record)
        
        guard let savedVendor = VendorModel.fromCKRecord(savedRecord) else {
            throw VendorLifecycleError.serializationFailed
        }
        
        // Update local cache and state
        if let index = vendors.firstIndex(where: { $0.id == savedVendor.id }) {
            vendors[index] = savedVendor
        }
        vendorCache.setObject(savedVendor, forKey: savedVendor.id as NSString)
        
        // Trigger lifecycle events
        if existingVendor.lifecycleStage != savedVendor.lifecycleStage {
            await triggerLifecycleEvent(.stageChanged, for: savedVendor)
        }
        
        return savedVendor
    }
    
    /// Transition vendor to new lifecycle stage
    func transitionVendorStage(vendorId: String, to newStage: VendorLifecycleStage, reason: String?) async throws {
        guard var vendor = vendors.first(where: { $0.id == vendorId }) else {
            throw VendorLifecycleError.vendorNotFound(id: vendorId)
        }
        
        let previousStage = vendor.lifecycleStage
        
        // Validate transition
        try await validateLifecycleTransition(from: previousStage, to: newStage, for: vendorId)
        
        // Update vendor
        vendor.lifecycleStage = newStage
        vendor = await processLifecycleStageChange(vendor: vendor, previousStage: previousStage)
        
        // Log transition
        let transitionRecord = VendorLifecycleTransition(
            vendorId: vendorId,
            fromStage: previousStage,
            toStage: newStage,
            reason: reason,
            timestamp: Date(),
            userId: getCurrentUserId()
        )
        
        await logLifecycleTransition(transitionRecord)
        
        // Save updated vendor
        _ = try await updateVendor(vendor)
    }
    
    // MARK: - Performance Management
    
    /// Record vendor performance evaluation
    func recordPerformanceEvaluation(
        vendorId: String,
        evaluation: VendorPerformanceRecord
    ) async throws {
        guard var vendor = vendors.first(where: { $0.id == vendorId }) else {
            throw VendorLifecycleError.vendorNotFound(id: vendorId)
        }
        
        // Add evaluation to history
        vendor.performanceHistory.append(evaluation)
        
        // Update overall performance rating
        vendor.performanceRating = calculateOverallPerformanceRating(from: vendor.performanceHistory)
        
        // Update scorecard
        vendor.scorecardData = updateVendorScorecard(vendor.scorecardData, with: evaluation)
        
        // Check for performance-based automation triggers
        await automationEngine.processPerformanceUpdate(vendor, evaluation: evaluation)
        
        // Save updated vendor
        _ = try await updateVendor(vendor)
        
        // Update analytics
        await updatePerformanceMetrics()
    }
    
    /// Calculate vendor scorecard metrics
    func calculateVendorScorecard(for vendorId: String) async -> VendorScorecard? {
        guard let vendor = vendors.first(where: { $0.id == vendorId }) else {
            return nil
        }
        
        var scorecard = VendorScorecard()
        
        // Calculate scores based on recent performance history
        let recentEvaluations = vendor.performanceHistory.suffix(5) // Last 5 evaluations
        
        if !recentEvaluations.isEmpty {
            scorecard.qualityScore = recentEvaluations
                .compactMap { $0.categoryScores[.quality] }
                .reduce(0, +) / Double(recentEvaluations.count)
            
            scorecard.deliveryScore = recentEvaluations
                .compactMap { $0.categoryScores[.delivery] }
                .reduce(0, +) / Double(recentEvaluations.count)
            
            scorecard.costScore = recentEvaluations
                .compactMap { $0.categoryScores[.cost] }
                .reduce(0, +) / Double(recentEvaluations.count)
            
            scorecard.serviceScore = recentEvaluations
                .compactMap { $0.categoryScores[.service] }
                .reduce(0, +) / Double(recentEvaluations.count)
            
            scorecard.complianceScore = recentEvaluations
                .compactMap { $0.categoryScores[.compliance] }
                .reduce(0, +) / Double(recentEvaluations.count)
            
            // Calculate weighted overall score
            let weights: [PerformanceCategory: Double] = [
                .quality: 0.25,
                .delivery: 0.20,
                .cost: 0.20,
                .service: 0.15,
                .compliance: 0.20
            ]
            
            var weightedSum: Double = 0
            var totalWeight: Double = 0
            
            for (category, weight) in weights {
                if let score = recentEvaluations.first?.categoryScores[category] {
                    weightedSum += score * weight
                    totalWeight += weight
                }
            }
            
            scorecard.overallScore = totalWeight > 0 ? weightedSum / totalWeight : 0
        }
        
        scorecard.lastCalculated = Date()
        return scorecard
    }
    
    // MARK: - Onboarding Management
    
    /// Process vendor onboarding workflow
    func processOnboardingStep(
        vendorId: String,
        taskId: String,
        isCompleted: Bool,
        notes: String? = nil
    ) async throws {
        guard var vendor = vendors.first(where: { $0.id == vendorId }) else {
            throw VendorLifecycleError.vendorNotFound(id: vendorId)
        }
        
        // Find and update the task
        if let taskIndex = vendor.onboardingProgress.onboardingTasks.firstIndex(where: { $0.id == taskId }) {
            vendor.onboardingProgress.onboardingTasks[taskIndex].isCompleted = isCompleted
            vendor.onboardingProgress.onboardingTasks[taskIndex].notes = notes
            
            if isCompleted {
                vendor.onboardingProgress.onboardingTasks[taskIndex].completedDate = Date()
            }
        }
        
        // Update onboarding progress
        vendor.onboardingProgress = calculateOnboardingProgress(vendor.onboardingProgress)
        
        // Check if onboarding is complete
        if vendor.onboardingProgress.isComplete && vendor.lifecycleStage == .onboarding {
            try await transitionVendorStage(vendorId: vendorId, to: .active, reason: "Onboarding completed")
        }
        
        // Save updated vendor
        _ = try await updateVendor(vendor)
    }
    
    /// Generate onboarding report
    func generateOnboardingReport(for vendorId: String) async -> OnboardingReport? {
        guard let vendor = vendors.first(where: { $0.id == vendorId }) else {
            return nil
        }
        
        let completedTasks = vendor.onboardingProgress.onboardingTasks.filter { $0.isCompleted }
        let overdueTasks = vendor.onboardingProgress.onboardingTasks.filter { $0.isOverdue }
        
        return OnboardingReport(
            vendorId: vendorId,
            vendorName: vendor.companyName,
            startDate: vendor.onboardingProgress.startDate ?? vendor.createdAt,
            expectedCompletionDate: vendor.onboardingProgress.expectedCompletionDate,
            actualCompletionDate: vendor.onboardingProgress.actualCompletionDate,
            totalTasks: vendor.onboardingProgress.onboardingTasks.count,
            completedTasks: completedTasks.count,
            overdueTasks: overdueTasks.count,
            progress: vendor.onboardingProgress.totalProgress,
            isComplete: vendor.onboardingProgress.isComplete,
            isOverdue: vendor.onboardingProgress.isOverdue,
            currentStage: vendor.onboardingProgress.currentStage,
            completedStages: vendor.onboardingProgress.completedStages
        )
    }
    
    // MARK: - Risk Management
    
    /// Assess vendor risk
    func assessVendorRisk(for vendorId: String) async -> VendorRiskAssessment? {
        guard let vendor = vendors.first(where: { $0.id == vendorId }) else {
            return nil
        }
        
        var riskScore: Double = 0.0
        var riskFactors: [String] = []
        
        // Financial health risk
        let financialRisk = calculateFinancialRisk(vendor.financialHealth)
        riskScore += financialRisk.score
        if financialRisk.score > 60 {
            riskFactors.append("Financial health concerns")
        }
        
        // Performance risk
        let performanceRisk = calculatePerformanceRisk(vendor.performanceHistory)
        riskScore += performanceRisk.score
        if performanceRisk.score > 60 {
            riskFactors.append("Performance concerns")
        }
        
        // Contract risk
        let contractRisk = calculateContractRisk(vendor)
        riskScore += contractRisk.score
        if contractRisk.score > 60 {
            riskFactors.append("Contract-related risks")
        }
        
        // Compliance risk
        let complianceRisk = calculateComplianceRisk(vendor.complianceStatus)
        riskScore += complianceRisk.score
        if complianceRisk.score > 60 {
            riskFactors.append("Compliance issues")
        }
        
        // Strategic dependency risk
        let dependencyRisk = calculateDependencyRisk(vendor)
        riskScore += dependencyRisk.score
        if dependencyRisk.score > 60 {
            riskFactors.append("High strategic dependency")
        }
        
        let averageRisk = riskScore / 5.0
        let riskLevel = getRiskLevel(from: averageRisk)
        
        return VendorRiskAssessment(
            vendorId: vendorId,
            overallRiskScore: averageRisk,
            riskLevel: riskLevel,
            riskFactors: riskFactors,
            financialRisk: financialRisk,
            performanceRisk: performanceRisk,
            contractRisk: contractRisk,
            complianceRisk: complianceRisk,
            dependencyRisk: dependencyRisk,
            assessmentDate: Date(),
            recommendedActions: generateRiskMitigationActions(riskLevel: riskLevel, factors: riskFactors)
        )
    }
    
    /// Generate renewal alerts
    func generateRenewalAlerts() async {
        let thirtyDaysFromNow = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
        let ninetyDaysFromNow = Calendar.current.date(byAdding: .day, value: 90, to: Date()) ?? Date()
        
        renewalAlerts = vendors.compactMap { vendor in
            guard vendor.contractEnd <= ninetyDaysFromNow && vendor.contractEnd > Date() else {
                return nil
            }
            
            let urgency: RenewalUrgency
            if vendor.contractEnd <= thirtyDaysFromNow {
                urgency = .critical
            } else if vendor.contractEnd <= Calendar.current.date(byAdding: .day, value: 60, to: Date()) ?? Date() {
                urgency = .high
            } else {
                urgency = .medium
            }
            
            return RenewalAlert(
                vendorId: vendor.id,
                vendorName: vendor.companyName,
                contractEndDate: vendor.contractEnd,
                daysUntilExpiry: Calendar.current.dateComponents([.day], from: Date(), to: vendor.contractEnd).day ?? 0,
                urgency: urgency,
                renewalOptions: vendor.renewalOptions,
                relationshipManager: vendor.relationshipManager
            )
        }
    }
    
    // MARK: - Analytics and Reporting
    
    /// Generate comprehensive vendor analytics
    func generateVendorAnalytics() async -> VendorAnalytics {
        let totalVendors = vendors.count
        let activeVendors = vendors.filter { $0.isActive }.count
        let strategicPartners = vendors.filter { $0.isStrategicPartner }.count
        let preferredVendors = vendors.filter { $0.isPreferred }.count
        
        // Lifecycle distribution
        let lifecycleDistribution = Dictionary(grouping: vendors) { $0.lifecycleStage }
            .mapValues { $0.count }
        
        // Risk distribution
        let riskDistribution = Dictionary(grouping: vendors) { $0.riskLevel }
            .mapValues { $0.count }
        
        // Performance metrics
        let averagePerformance = vendors.map { $0.performanceRating }.reduce(0, +) / Double(vendors.count)
        let topPerformers = vendors.filter { $0.performanceRating >= 85.0 }.count
        let poorPerformers = vendors.filter { $0.performanceRating < 60.0 }.count
        
        // Financial metrics
        let totalContractValue = vendors.compactMap { $0.contractValue }.reduce(0, +)
        let averageContractValue = totalContractValue / Double(vendors.filter { $0.contractValue != nil }.count)
        
        return VendorAnalytics(
            totalVendors: totalVendors,
            activeVendors: activeVendors,
            strategicPartners: strategicPartners,
            preferredVendors: preferredVendors,
            lifecycleDistribution: lifecycleDistribution,
            riskDistribution: riskDistribution,
            averagePerformanceRating: averagePerformance,
            topPerformers: topPerformers,
            poorPerformers: poorPerformers,
            totalContractValue: totalContractValue,
            averageContractValue: averageContractValue,
            renewalsRequired: renewalAlerts.count,
            highRiskVendors: vendors.filter { $0.riskLevel == .high || $0.riskLevel == .critical }.count
        )
    }
    
    // MARK: - Fetch and Sync
    
    /// Fetch all vendors from CloudKit
    func fetchVendors() async throws {
        isLoading = true
        defer { isLoading = false }
        
        let query = CKQuery(recordType: "VendorModel", predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "companyName", ascending: true)]
        
        let results = try await database.records(matching: query)
        var fetchedVendors: [VendorModel] = []
        
        for (_, result) in results.matchResults {
            switch result {
            case .success(let record):
                if let vendor = VendorModel.fromCKRecord(record) {
                    fetchedVendors.append(vendor)
                    vendorCache.setObject(vendor, forKey: vendor.id as NSString)
                }
            case .failure(let error):
                print("Failed to fetch vendor record: \(error)")
            }
        }
        
        vendors = fetchedVendors
        
        // Generate alerts and analytics
        await generateRenewalAlerts()
        await updatePerformanceMetrics()
    }
    
    // MARK: - Private Helper Methods
    
    private func validateVendorData(_ vendor: VendorModel) throws {
        if vendor.companyName.isEmpty {
            throw VendorLifecycleError.invalidData("Company name is required")
        }
        
        if vendor.email.isEmpty || !isValidEmail(vendor.email) {
            throw VendorLifecycleError.invalidData("Valid email is required")
        }
        
        if vendor.contractEnd <= vendor.contractStart {
            throw VendorLifecycleError.invalidData("Contract end date must be after start date")
        }
    }
    
    private func validateLifecycleTransition(
        from: VendorLifecycleStage,
        to: VendorLifecycleStage,
        for vendorId: String
    ) async throws {
        guard from.allowedNextStages.contains(to) else {
            throw VendorLifecycleError.invalidTransition(from: from, to: to)
        }
        
        // Additional business rule validations
        switch to {
        case .active:
            // Ensure onboarding is complete
            if let vendor = vendors.first(where: { $0.id == vendorId }),
               !vendor.onboardingProgress.isComplete {
                throw VendorLifecycleError.preconditionNotMet("Onboarding must be complete before activating vendor")
            }
        case .strategic:
            // Ensure vendor meets strategic criteria
            if let vendor = vendors.first(where: { $0.id == vendorId }),
               vendor.performanceRating < 80.0 {
                throw VendorLifecycleError.preconditionNotMet("Vendor must have performance rating ≥ 80% for strategic status")
            }
        case .terminated:
            // Check for outstanding obligations
            // This would typically check for open contracts, pending payments, etc.
            break
        default:
            break
        }
    }
    
    private func processLifecycleStageChange(
        vendor: VendorModel,
        previousStage: VendorLifecycleStage
    ) async -> VendorModel {
        var updatedVendor = vendor
        
        switch vendor.lifecycleStage {
        case .onboarding:
            if previousStage == .evaluation {
                // Initialize onboarding process
                updatedVendor.onboardingProgress.startDate = Date()
                updatedVendor.onboardingProgress.expectedCompletionDate = Calendar.current.date(
                    byAdding: .day,
                    value: 30,
                    to: Date()
                )
                updatedVendor.onboardingProgress.onboardingTasks = createInitialOnboardingTasks()
            }
        case .active:
            if previousStage == .onboarding {
                updatedVendor.onboardingProgress.actualCompletionDate = Date()
            }
            updatedVendor.nextReviewDate = Calendar.current.date(byAdding: .month, value: 6, to: Date())
        case .strategic:
            updatedVendor.isStrategicPartner = true
            updatedVendor.strategicImportance = .strategic
        case .terminated:
            updatedVendor.isActive = false
            updatedVendor.isStrategicPartner = false
            updatedVendor.isPreferred = false
        default:
            break
        }
        
        return updatedVendor
    }
    
    private func createInitialOnboardingTasks() -> [OnboardingTask] {
        return [
            OnboardingTask(
                id: UUID().uuidString,
                title: "Document Review",
                description: "Review and collect all required documentation",
                stage: .documentation,
                dueDate: Calendar.current.date(byAdding: .day, value: 5, to: Date()),
                priority: .high,
                dependencies: [],
                isCompleted: false
            ),
            OnboardingTask(
                id: UUID().uuidString,
                title: "Compliance Verification",
                description: "Verify compliance certifications and requirements",
                stage: .compliance,
                dueDate: Calendar.current.date(byAdding: .day, value: 10, to: Date()),
                priority: .high,
                dependencies: [],
                isCompleted: false
            ),
            OnboardingTask(
                id: UUID().uuidString,
                title: "System Setup",
                description: "Configure system access and integrations",
                stage: .systemSetup,
                dueDate: Calendar.current.date(byAdding: .day, value: 15, to: Date()),
                priority: .medium,
                dependencies: [],
                isCompleted: false
            ),
            OnboardingTask(
                id: UUID().uuidString,
                title: "Training Session",
                description: "Complete vendor orientation and training",
                stage: .training,
                dueDate: Calendar.current.date(byAdding: .day, value: 20, to: Date()),
                priority: .medium,
                dependencies: [],
                isCompleted: false
            ),
            OnboardingTask(
                id: UUID().uuidString,
                title: "Go Live",
                description: "Activate vendor for production use",
                stage: .goLive,
                dueDate: Calendar.current.date(byAdding: .day, value: 25, to: Date()),
                priority: .critical,
                dependencies: [],
                isCompleted: false
            )
        ]
    }
    
    private func calculateOnboardingProgress(_ progress: OnboardingProgress) -> OnboardingProgress {
        var updatedProgress = progress
        
        let totalTasks = progress.onboardingTasks.count
        let completedTasks = progress.onboardingTasks.filter { $0.isCompleted }.count
        
        updatedProgress.totalProgress = totalTasks > 0 ? (Double(completedTasks) / Double(totalTasks)) * 100 : 0
        
        // Update completed stages
        let stageProgress = Dictionary(grouping: progress.onboardingTasks) { $0.stage }
        
        for (stage, tasks) in stageProgress {
            let stageCompletedTasks = tasks.filter { $0.isCompleted }.count
            let stageProgress = Double(stageCompletedTasks) / Double(tasks.count) * 100
            updatedProgress.stageProgress[stage] = stageProgress
            
            if stageProgress >= 100 && !updatedProgress.completedStages.contains(stage) {
                updatedProgress.completedStages.append(stage)
            }
        }
        
        return updatedProgress
    }
    
    private func calculateOverallPerformanceRating(from history: [VendorPerformanceRecord]) -> Double {
        guard !history.isEmpty else { return 0.0 }
        
        // Weight recent evaluations more heavily
        let weightedScores = history.enumerated().map { index, record in
            let weight = Double(index + 1) / Double(history.count)
            return record.overallScore * weight
        }
        
        return weightedScores.reduce(0, +) / Double(history.count)
    }
    
    private func updateVendorScorecard(_ scorecard: VendorScorecard, with evaluation: VendorPerformanceRecord) -> VendorScorecard {
        var updated = scorecard
        
        // Update individual scores from evaluation
        for (category, score) in evaluation.categoryScores {
            switch category {
            case .quality:
                updated.qualityScore = (updated.qualityScore + score) / 2
            case .delivery:
                updated.deliveryScore = (updated.deliveryScore + score) / 2
            case .cost:
                updated.costScore = (updated.costScore + score) / 2
            case .service:
                updated.serviceScore = (updated.serviceScore + score) / 2
            case .compliance:
                updated.complianceScore = (updated.complianceScore + score) / 2
            default:
                break
            }
        }
        
        // Recalculate overall score
        let scores = [updated.qualityScore, updated.deliveryScore, updated.costScore, updated.serviceScore, updated.complianceScore]
        updated.overallScore = scores.reduce(0, +) / Double(scores.count)
        updated.lastCalculated = Date()
        
        return updated
    }
    
    private func calculateFinancialRisk(_ financial: FinancialHealthMetrics) -> (score: Double, factors: [String]) {
        var score: Double = 0
        var factors: [String] = []
        
        // Credit rating risk
        if let rating = financial.creditRating {
            if rating.lowercased().contains("d") || rating.lowercased().contains("c") {
                score += 40
                factors.append("Poor credit rating")
            }
        }
        
        // Financial stability risk
        switch financial.financialStability {
        case .critical:
            score += 50
            factors.append("Critical financial stability")
        case .unstable:
            score += 35
            factors.append("Unstable financial condition")
        case .concerning:
            score += 20
            factors.append("Financial concerns")
        default:
            break
        }
        
        // Days payable outstanding
        if financial.daysPayableOutstanding > 60 {
            score += 15
            factors.append("High days payable outstanding")
        }
        
        return (score, factors)
    }
    
    private func calculatePerformanceRisk(_ history: [VendorPerformanceRecord]) -> (score: Double, factors: [String]) {
        var score: Double = 0
        var factors: [String] = []
        
        guard !history.isEmpty else {
            return (25, ["No performance history"])
        }
        
        let recentEvaluations = Array(history.suffix(3))
        let averageScore = recentEvaluations.map { $0.overallScore }.reduce(0, +) / Double(recentEvaluations.count)
        
        if averageScore < 60 {
            score += 40
            factors.append("Poor performance ratings")
        } else if averageScore < 75 {
            score += 20
            factors.append("Below average performance")
        }
        
        // Check for declining trend
        if recentEvaluations.count >= 2 {
            let isDeclimaing = recentEvaluations.last!.overallScore < recentEvaluations.first!.overallScore
            if isDeclimaing {
                score += 15
                factors.append("Declining performance trend")
            }
        }
        
        return (score, factors)
    }
    
    private func calculateContractRisk(_ vendor: VendorModel) -> (score: Double, factors: [String]) {
        var score: Double = 0
        var factors: [String] = []
        
        // Contract expiry risk
        let daysToExpiry = Calendar.current.dateComponents([.day], from: Date(), to: vendor.contractEnd).day ?? 0
        
        if daysToExpiry < 30 {
            score += 30
            factors.append("Contract expiring soon")
        } else if daysToExpiry < 90 {
            score += 15
            factors.append("Contract renewal needed")
        }
        
        // Single source risk
        if vendor.alternativeVendors.isEmpty {
            score += 25
            factors.append("No alternative vendors identified")
        }
        
        return (score, factors)
    }
    
    private func calculateComplianceRisk(_ compliance: VendorComplianceStatus) -> (score: Double, factors: [String]) {
        // This would be implemented based on the actual compliance status structure
        return (0, [])
    }
    
    private func calculateDependencyRisk(_ vendor: VendorModel) -> (score: Double, factors: [String]) {
        var score: Double = 0
        var factors: [String] = []
        
        if vendor.strategicImportance == .critical {
            score += 30
            factors.append("Critical strategic dependency")
        }
        
        if vendor.contractValue ?? 0 > 1000000 { // > $1M
            score += 20
            factors.append("High financial exposure")
        }
        
        return (score, factors)
    }
    
    private func getRiskLevel(from score: Double) -> RiskLevel {
        switch score {
        case 0..<25: return .low
        case 25..<50: return .medium
        case 50..<75: return .high
        default: return .critical
        }
    }
    
    private func generateRiskMitigationActions(riskLevel: RiskLevel, factors: [String]) -> [String] {
        var actions: [String] = []
        
        switch riskLevel {
        case .critical:
            actions.append("Immediate escalation to senior management required")
            actions.append("Develop immediate contingency plan")
            actions.append("Consider contract termination")
        case .high:
            actions.append("Enhanced monitoring and frequent reviews")
            actions.append("Identify alternative vendors")
            actions.append("Renegotiate contract terms")
        case .medium:
            actions.append("Regular monitoring and quarterly reviews")
            actions.append("Performance improvement plan")
        case .low:
            actions.append("Standard monitoring procedures")
        }
        
        // Factor-specific actions
        for factor in factors {
            if factor.contains("credit") {
                actions.append("Request financial guarantees or insurance")
            } else if factor.contains("performance") {
                actions.append("Implement performance improvement plan")
            } else if factor.contains("expiring") {
                actions.append("Initiate renewal discussions immediately")
            }
        }
        
        return actions
    }
    
    private func updatePerformanceMetrics() async {
        // Update aggregate performance metrics
        performanceMetrics = VendorPerformanceMetrics(
            totalVendors: vendors.count,
            averagePerformanceRating: vendors.map { $0.performanceRating }.reduce(0, +) / Double(vendors.count),
            topPerformers: vendors.filter { $0.performanceRating >= 85 }.count,
            underPerformers: vendors.filter { $0.performanceRating < 60 }.count,
            onTimeDeliveryRate: calculateAverageOnTimeDelivery(),
            costEffectivenessScore: calculateAverageCostEffectiveness(),
            lastUpdated: Date()
        )
    }
    
    private func calculateAverageOnTimeDelivery() -> Double {
        // This would calculate based on actual delivery data
        return 85.0 // Placeholder
    }
    
    private func calculateAverageCostEffectiveness() -> Double {
        // This would calculate based on actual cost data
        return 78.0 // Placeholder
    }
    
    private func triggerLifecycleEvent(_ event: VendorLifecycleEvent, for vendor: VendorModel) async {
        // Trigger notifications, workflows, etc.
        print("Lifecycle event triggered: \(event) for vendor \(vendor.companyName)")
    }
    
    private func logLifecycleTransition(_ transition: VendorLifecycleTransition) async {
        // Log the transition for audit purposes
        print("Lifecycle transition logged: \(transition)")
    }
    
    private func getCurrentUserId() -> String {
        // Get current user ID from authentication system
        return "current-user-id"
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func setupNotifications() {
        // Setup CloudKit subscription for vendor changes
        NotificationCenter.default.publisher(for: .CKAccountChanged)
            .sink { [weak self] _ in
                Task {
                    try? await self?.fetchVendors()
                }
            }
            .store(in: &cancellables)
    }
    
    private func setupAutomationTriggers() {
        // Setup periodic automation checks
        Timer.publish(every: 3600, on: .main, in: .common) // Every hour
            .autoconnect()
            .sink { [weak self] _ in
                Task {
                    await self?.runAutomationChecks()
                }
            }
            .store(in: &cancellables)
    }
    
    private func runAutomationChecks() async {
        await generateRenewalAlerts()
        
        // Run risk assessments for critical vendors
        for vendor in vendors.filter({ $0.strategicImportance == .critical }) {
            _ = await assessVendorRisk(for: vendor.id)
        }
    }
}

// MARK: - Supporting Types and Enums

enum VendorLifecycleEvent {
    case vendorCreated
    case stageChanged
    case performanceUpdated
    case riskAssessed
    case contractRenewed
    case vendorTerminated
}

struct VendorLifecycleTransition {
    let vendorId: String
    let fromStage: VendorLifecycleStage
    let toStage: VendorLifecycleStage
    let reason: String?
    let timestamp: Date
    let userId: String
}

struct OnboardingReport {
    let vendorId: String
    let vendorName: String
    let startDate: Date
    let expectedCompletionDate: Date?
    let actualCompletionDate: Date?
    let totalTasks: Int
    let completedTasks: Int
    let overdueTasks: Int
    let progress: Double
    let isComplete: Bool
    let isOverdue: Bool
    let currentStage: OnboardingStage
    let completedStages: [OnboardingStage]
}

struct VendorRiskAssessment {
    let vendorId: String
    let overallRiskScore: Double
    let riskLevel: RiskLevel
    let riskFactors: [String]
    let financialRisk: (score: Double, factors: [String])
    let performanceRisk: (score: Double, factors: [String])
    let contractRisk: (score: Double, factors: [String])
    let complianceRisk: (score: Double, factors: [String])
    let dependencyRisk: (score: Double, factors: [String])
    let assessmentDate: Date
    let recommendedActions: [String]
}

struct RenewalAlert {
    let vendorId: String
    let vendorName: String
    let contractEndDate: Date
    let daysUntilExpiry: Int
    let urgency: RenewalUrgency
    let renewalOptions: [RenewalOption]
    let relationshipManager: String?
}

enum RenewalUrgency {
    case critical // < 30 days
    case high     // < 60 days
    case medium   // < 90 days
    case low      // > 90 days
}

struct RiskAlert {
    let vendorId: String
    let vendorName: String
    let riskLevel: RiskLevel
    let riskFactors: [String]
    let recommendedActions: [String]
    let alertDate: Date
}

struct VendorPerformanceMetrics {
    let totalVendors: Int
    let averagePerformanceRating: Double
    let topPerformers: Int
    let underPerformers: Int
    let onTimeDeliveryRate: Double
    let costEffectivenessScore: Double
    let lastUpdated: Date
    
    init() {
        self.totalVendors = 0
        self.averagePerformanceRating = 0.0
        self.topPerformers = 0
        self.underPerformers = 0
        self.onTimeDeliveryRate = 0.0
        self.costEffectivenessScore = 0.0
        self.lastUpdated = Date()
    }
    
    init(totalVendors: Int, averagePerformanceRating: Double, topPerformers: Int, underPerformers: Int, onTimeDeliveryRate: Double, costEffectivenessScore: Double, lastUpdated: Date) {
        self.totalVendors = totalVendors
        self.averagePerformanceRating = averagePerformanceRating
        self.topPerformers = topPerformers
        self.underPerformers = underPerformers
        self.onTimeDeliveryRate = onTimeDeliveryRate
        self.costEffectivenessScore = costEffectivenessScore
        self.lastUpdated = lastUpdated
    }
}

struct VendorAnalytics {
    let totalVendors: Int
    let activeVendors: Int
    let strategicPartners: Int
    let preferredVendors: Int
    let lifecycleDistribution: [VendorLifecycleStage: Int]
    let riskDistribution: [RiskLevel: Int]
    let averagePerformanceRating: Double
    let topPerformers: Int
    let poorPerformers: Int
    let totalContractValue: Double
    let averageContractValue: Double
    let renewalsRequired: Int
    let highRiskVendors: Int
}

// Placeholder for automation engine
class VendorAutomationEngine {
    func processNewVendor(_ vendor: VendorModel) async -> VendorModel {
        // Implement automation rules for new vendors
        return vendor
    }
    
    func processVendorUpdate(_ vendor: VendorModel, previousVendor: VendorModel) async -> VendorModel {
        // Implement automation rules for vendor updates
        return vendor
    }
    
    func processPerformanceUpdate(_ vendor: VendorModel, evaluation: VendorPerformanceRecord) async {
        // Implement automation rules for performance updates
    }
}

// Error types
enum VendorLifecycleError: Error, LocalizedError {
    case vendorNotFound(id: String)
    case invalidData(String)
    case invalidTransition(from: VendorLifecycleStage, to: VendorLifecycleStage)
    case preconditionNotMet(String)
    case serializationFailed
    
    var errorDescription: String? {
        switch self {
        case .vendorNotFound(let id):
            return "Vendor with ID '\(id)' not found"
        case .invalidData(let message):
            return "Invalid vendor data: \(message)"
        case .invalidTransition(let from, let to):
            return "Invalid lifecycle transition from \(from.displayName) to \(to.displayName)"
        case .preconditionNotMet(let message):
            return "Precondition not met: \(message)"
        case .serializationFailed:
            return "Failed to serialize/deserialize vendor data"
        }
    }
}

// Placeholder types that would need to be defined elsewhere
struct VendorComplianceStatus: Codable {
    // Implementation would go here
}

struct InsuranceInformation: Codable {
    // Implementation would go here
}

enum BackgroundCheckStatus: String, Codable {
    case pending = "pending"
    case approved = "approved"
    case rejected = "rejected"
    case expired = "expired"
}

struct BudgetAllocation: Codable {
    // Implementation would go here
}

struct CostCategory: Codable {
    // Implementation would go here
}

struct ExclusivityAgreement: Codable {
    // Implementation would go here
}

struct VendorBenefit: Codable {
    // Implementation would go here
}

struct VendorAutomationRule: Codable {
    // Implementation would go here
}

struct WorkflowStage: Codable {
    // Implementation would go here
}

struct ApprovalWorkflow: Codable {
    // Implementation would go here
}

struct IntegrationEndpoint: Codable {
    // Implementation would go here
}

struct DataFormat: Codable {
    // Implementation would go here
}

struct APICredentials: Codable {
    // Implementation would go here
}

struct EDIConfiguration: Codable {
    // Implementation would go here
}

struct AttachmentReference: Codable {
    // Implementation would go here
}

struct BusinessContinuityPlan: Codable {
    // Implementation would go here
}

struct BenchmarkResult: Codable {
    // Implementation would go here
}

struct ActionItem: Codable {
    // Implementation would go here
}

struct InvoiceProcessingRules: Codable {
    // Implementation would go here
}

struct Address: Codable {
    let street: String
    let city: String
    let state: String
    let zipCode: String
    let country: String
}
