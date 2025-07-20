import XCTest
@testable import DiamondDeskERP

class VendorLifecycleTests: XCTestCase {
    
    var vendorService: VendorLifecycleService!
    var testVendors: [VendorModel]!
    
    override func setUp() {
        super.setUp()
        vendorService = VendorLifecycleService()
        setupTestVendors()
    }
    
    override func tearDown() {
        vendorService = nil
        testVendors = nil
        super.tearDown()
    }
    
    // MARK: - Setup Helpers
    
    func setupTestVendors() {
        let address = Address(
            street: "123 Business St",
            city: "Business City",
            state: "BC",
            zipCode: "12345",
            country: "USA"
        )
        
        testVendors = [
            // New vendor in prospect stage
            VendorModel(
                id: "vendor-1",
                vendorNumber: "V001",
                companyName: "Tech Solutions Inc",
                contactPerson: "John Smith",
                email: "john@techsolutions.com",
                phone: "555-0001",
                website: "https://techsolutions.com",
                address: address,
                vendorType: .serviceProvider,
                serviceCategories: ["IT Services", "Consulting"],
                businessSegment: .technology,
                industryVertical: "Technology",
                contractStart: Date(),
                contractEnd: Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date(),
                paymentTerms: "Net 30",
                contractValue: 100000,
                currency: "USD"
            ),
            
            // Active vendor with good performance
            VendorModel(
                id: "vendor-2", 
                vendorNumber: "V002",
                companyName: "Reliable Manufacturing",
                contactPerson: "Jane Doe",
                email: "jane@reliable.com",
                phone: "555-0002",
                address: address,
                vendorType: .supplier,
                serviceCategories: ["Manufacturing", "Supply Chain"],
                businessSegment: .manufacturing,
                industryVertical: "Manufacturing",
                contractStart: Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date(),
                contractEnd: Calendar.current.date(byAdding: .month, value: 6, to: Date()) ?? Date(),
                paymentTerms: "Net 15",
                contractValue: 500000,
                currency: "USD"
            ),
            
            // Strategic partner with excellent performance
            VendorModel(
                id: "vendor-3",
                vendorNumber: "V003", 
                companyName: "Strategic Consulting Group",
                contactPerson: "Bob Johnson",
                email: "bob@strategic.com",
                phone: "555-0003",
                address: address,
                vendorType: .consultant,
                serviceCategories: ["Strategy", "Management"],
                businessSegment: .consulting,
                industryVertical: "Consulting",
                contractStart: Calendar.current.date(byAdding: .year, value: -2, to: Date()) ?? Date(),
                contractEnd: Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date(),
                paymentTerms: "Net 10",
                contractValue: 750000,
                currency: "USD"
            )
        ]
        
        // Setup lifecycle stages and performance data
        testVendors[0].lifecycleStage = .prospect
        
        testVendors[1].lifecycleStage = .active
        testVendors[1].performanceRating = 85.0
        testVendors[1].isPreferred = true
        
        testVendors[2].lifecycleStage = .strategic
        testVendors[2].performanceRating = 95.0
        testVendors[2].isStrategicPartner = true
        testVendors[2].strategicImportance = .strategic
        
        // Add performance history to active vendor
        testVendors[1].performanceHistory = [
            VendorPerformanceRecord(
                evaluator: "Test Evaluator",
                period: .quarterly,
                overallScore: 85.0,
                categoryScores: [
                    .quality: 85.0,
                    .delivery: 90.0,
                    .cost: 80.0,
                    .service: 85.0,
                    .compliance: 90.0
                ]
            )
        ]
    }
    
    // MARK: - Vendor Creation Tests
    
    func testCreateVendor() async {
        let newVendor = testVendors[0]
        
        do {
            let createdVendor = try await vendorService.createVendor(newVendor)
            
            XCTAssertEqual(createdVendor.companyName, "Tech Solutions Inc")
            XCTAssertEqual(createdVendor.lifecycleStage, .prospect)
            XCTAssertNotNil(createdVendor.onboardingProgress.startDate)
            XCTAssertFalse(createdVendor.onboardingProgress.onboardingTasks.isEmpty)
            
        } catch {
            XCTFail("Should be able to create vendor: \(error)")
        }
    }
    
    func testCreateVendorWithInvalidData() async {
        var invalidVendor = testVendors[0]
        invalidVendor.companyName = "" // Invalid empty name
        
        do {
            _ = try await vendorService.createVendor(invalidVendor)
            XCTFail("Should not be able to create vendor with invalid data")
        } catch VendorLifecycleError.invalidData {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - Lifecycle Transition Tests
    
    func testValidLifecycleTransition() async {
        vendorService.vendors = testVendors
        
        do {
            try await vendorService.transitionVendorStage(
                vendorId: "vendor-1",
                to: .evaluation,
                reason: "Initial evaluation started"
            )
            
            let updatedVendor = vendorService.vendors.first { $0.id == "vendor-1" }
            XCTAssertEqual(updatedVendor?.lifecycleStage, .evaluation)
            
        } catch {
            XCTFail("Should be able to transition from prospect to evaluation: \(error)")
        }
    }
    
    func testInvalidLifecycleTransition() async {
        vendorService.vendors = testVendors
        
        do {
            try await vendorService.transitionVendorStage(
                vendorId: "vendor-1", 
                to: .terminated,
                reason: "Direct termination"
            )
            XCTFail("Should not be able to transition directly from prospect to terminated")
        } catch VendorLifecycleError.invalidTransition {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testOnboardingToActiveTransition() async {
        var onboardingVendor = testVendors[0]
        onboardingVendor.lifecycleStage = .onboarding
        onboardingVendor.onboardingProgress.totalProgress = 100.0
        
        // Mark all tasks as completed
        for i in 0..<onboardingVendor.onboardingProgress.onboardingTasks.count {
            onboardingVendor.onboardingProgress.onboardingTasks[i].isCompleted = true
        }
        
        vendorService.vendors = [onboardingVendor]
        
        do {
            try await vendorService.transitionVendorStage(
                vendorId: onboardingVendor.id,
                to: .active,
                reason: "Onboarding completed"
            )
            
            let updatedVendor = vendorService.vendors.first { $0.id == onboardingVendor.id }
            XCTAssertEqual(updatedVendor?.lifecycleStage, .active)
            XCTAssertNotNil(updatedVendor?.onboardingProgress.actualCompletionDate)
            
        } catch {
            XCTFail("Should be able to transition to active after onboarding: \(error)")
        }
    }
    
    func testStrategicTransitionRequiresHighPerformance() async {
        var lowPerformanceVendor = testVendors[1]
        lowPerformanceVendor.performanceRating = 70.0 // Below 80% threshold
        
        vendorService.vendors = [lowPerformanceVendor]
        
        do {
            try await vendorService.transitionVendorStage(
                vendorId: lowPerformanceVendor.id,
                to: .strategic,
                reason: "Attempt strategic promotion"
            )
            XCTFail("Should not be able to transition to strategic with low performance")
        } catch VendorLifecycleError.preconditionNotMet {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - Performance Management Tests
    
    func testRecordPerformanceEvaluation() async {
        vendorService.vendors = testVendors
        
        let evaluation = VendorPerformanceRecord(
            evaluator: "Test Manager",
            period: .quarterly,
            overallScore: 90.0,
            categoryScores: [
                .quality: 92.0,
                .delivery: 88.0,
                .cost: 85.0,
                .service: 93.0,
                .compliance: 87.0
            ],
            improvementAreas: ["Cost optimization"],
            strengths: ["Excellent service quality", "Reliable delivery"]
        )
        
        do {
            try await vendorService.recordPerformanceEvaluation(
                vendorId: "vendor-2",
                evaluation: evaluation
            )
            
            let updatedVendor = vendorService.vendors.first { $0.id == "vendor-2" }
            XCTAssertEqual(updatedVendor?.performanceHistory.count, 2) // Original + new
            XCTAssertTrue(updatedVendor?.performanceRating ?? 0 > 85.0) // Should be updated
            
        } catch {
            XCTFail("Should be able to record performance evaluation: \(error)")
        }
    }
    
    func testCalculateVendorScorecard() async {
        vendorService.vendors = testVendors
        
        let scorecard = await vendorService.calculateVendorScorecard(for: "vendor-2")
        
        XCTAssertNotNil(scorecard)
        XCTAssertTrue(scorecard!.overallScore > 0)
        XCTAssertTrue(scorecard!.qualityScore > 0)
        XCTAssertEqual(scorecard!.rating, .good) // Should be good rating
    }
    
    // MARK: - Onboarding Management Tests
    
    func testProcessOnboardingStep() async {
        var onboardingVendor = testVendors[0]
        onboardingVendor.lifecycleStage = .onboarding
        vendorService.vendors = [onboardingVendor]
        
        let taskId = onboardingVendor.onboardingProgress.onboardingTasks.first?.id ?? ""
        
        do {
            try await vendorService.processOnboardingStep(
                vendorId: onboardingVendor.id,
                taskId: taskId,
                isCompleted: true,
                notes: "Documentation received and reviewed"
            )
            
            let updatedVendor = vendorService.vendors.first { $0.id == onboardingVendor.id }
            let completedTask = updatedVendor?.onboardingProgress.onboardingTasks.first { $0.id == taskId }
            
            XCTAssertTrue(completedTask?.isCompleted ?? false)
            XCTAssertNotNil(completedTask?.completedDate)
            XCTAssertEqual(completedTask?.notes, "Documentation received and reviewed")
            
        } catch {
            XCTFail("Should be able to complete onboarding step: \(error)")
        }
    }
    
    func testOnboardingProgressCalculation() async {
        var onboardingVendor = testVendors[0]
        onboardingVendor.lifecycleStage = .onboarding
        
        // Complete 2 out of 5 tasks
        onboardingVendor.onboardingProgress.onboardingTasks[0].isCompleted = true
        onboardingVendor.onboardingProgress.onboardingTasks[1].isCompleted = true
        
        vendorService.vendors = [onboardingVendor]
        
        // Process a task completion to trigger progress calculation
        let taskId = onboardingVendor.onboardingProgress.onboardingTasks[2].id
        
        do {
            try await vendorService.processOnboardingStep(
                vendorId: onboardingVendor.id,
                taskId: taskId,
                isCompleted: true
            )
            
            let updatedVendor = vendorService.vendors.first { $0.id == onboardingVendor.id }
            let progress = updatedVendor?.onboardingProgress.totalProgress ?? 0
            
            XCTAssertEqual(progress, 60.0) // 3 out of 5 tasks = 60%
            
        } catch {
            XCTFail("Should be able to calculate onboarding progress: \(error)")
        }
    }
    
    func testGenerateOnboardingReport() async {
        var onboardingVendor = testVendors[0]
        onboardingVendor.lifecycleStage = .onboarding
        onboardingVendor.onboardingProgress.onboardingTasks[0].isCompleted = true
        onboardingVendor.onboardingProgress.totalProgress = 20.0
        
        vendorService.vendors = [onboardingVendor]
        
        let report = await vendorService.generateOnboardingReport(for: onboardingVendor.id)
        
        XCTAssertNotNil(report)
        XCTAssertEqual(report?.vendorName, "Tech Solutions Inc")
        XCTAssertEqual(report?.totalTasks, 5)
        XCTAssertEqual(report?.completedTasks, 1)
        XCTAssertEqual(report?.progress, 20.0)
        XCTAssertFalse(report?.isComplete ?? true)
    }
    
    // MARK: - Risk Management Tests
    
    func testAssessVendorRisk() async {
        var riskVendor = testVendors[1]
        riskVendor.performanceRating = 50.0 // Poor performance
        riskVendor.contractEnd = Calendar.current.date(byAdding: .day, value: 15, to: Date()) ?? Date() // Expiring soon
        riskVendor.strategicImportance = .critical
        riskVendor.contractValue = 2000000 // High value
        
        vendorService.vendors = [riskVendor]
        
        let riskAssessment = await vendorService.assessVendorRisk(for: riskVendor.id)
        
        XCTAssertNotNil(riskAssessment)
        XCTAssertTrue(riskAssessment!.overallRiskScore > 50) // Should be high risk
        XCTAssertEqual(riskAssessment!.riskLevel, .high)
        XCTAssertFalse(riskAssessment!.riskFactors.isEmpty)
        XCTAssertFalse(riskAssessment!.recommendedActions.isEmpty)
    }
    
    func testLowRiskVendorAssessment() async {
        var lowRiskVendor = testVendors[2] // Strategic partner with excellent performance
        lowRiskVendor.contractEnd = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
        lowRiskVendor.contractValue = 100000 // Moderate value
        
        vendorService.vendors = [lowRiskVendor]
        
        let riskAssessment = await vendorService.assessVendorRisk(for: lowRiskVendor.id)
        
        XCTAssertNotNil(riskAssessment)
        XCTAssertTrue(riskAssessment!.overallRiskScore < 50) // Should be low-medium risk
        XCTAssertTrue([.low, .medium].contains(riskAssessment!.riskLevel))
    }
    
    // MARK: - Renewal Management Tests
    
    func testGenerateRenewalAlerts() async {
        var expiringVendor = testVendors[1]
        expiringVendor.contractEnd = Calendar.current.date(byAdding: .day, value: 20, to: Date()) ?? Date()
        
        vendorService.vendors = [expiringVendor]
        
        await vendorService.generateRenewalAlerts()
        
        XCTAssertEqual(vendorService.renewalAlerts.count, 1)
        
        let alert = vendorService.renewalAlerts.first
        XCTAssertEqual(alert?.vendorId, expiringVendor.id)
        XCTAssertEqual(alert?.urgency, .critical) // < 30 days
        XCTAssertTrue(alert?.daysUntilExpiry ?? 0 < 30)
    }
    
    func testRenewalAlertUrgencyLevels() async {
        let criticalVendor = testVendors[0]
        var mediumVendor = testVendors[1]
        var highVendor = testVendors[2]
        
        // Set different expiry dates
        criticalVendor.contractEnd = Calendar.current.date(byAdding: .day, value: 15, to: Date()) ?? Date() // Critical
        mediumVendor.contractEnd = Calendar.current.date(byAdding: .day, value: 75, to: Date()) ?? Date() // Medium
        highVendor.contractEnd = Calendar.current.date(byAdding: .day, value: 45, to: Date()) ?? Date() // High
        
        vendorService.vendors = [criticalVendor, mediumVendor, highVendor]
        
        await vendorService.generateRenewalAlerts()
        
        XCTAssertEqual(vendorService.renewalAlerts.count, 3)
        
        let criticalAlert = vendorService.renewalAlerts.first { $0.vendorId == criticalVendor.id }
        let mediumAlert = vendorService.renewalAlerts.first { $0.vendorId == mediumVendor.id }
        let highAlert = vendorService.renewalAlerts.first { $0.vendorId == highVendor.id }
        
        XCTAssertEqual(criticalAlert?.urgency, .critical)
        XCTAssertEqual(mediumAlert?.urgency, .medium)
        XCTAssertEqual(highAlert?.urgency, .high)
    }
    
    // MARK: - Analytics Tests
    
    func testGenerateVendorAnalytics() async {
        vendorService.vendors = testVendors
        
        let analytics = await vendorService.generateVendorAnalytics()
        
        XCTAssertEqual(analytics.totalVendors, 3)
        XCTAssertEqual(analytics.activeVendors, 3) // All test vendors are active
        XCTAssertEqual(analytics.strategicPartners, 1) // Only vendor-3
        XCTAssertEqual(analytics.preferredVendors, 1) // Only vendor-2
        
        // Check lifecycle distribution
        XCTAssertEqual(analytics.lifecycleDistribution[.prospect], 1)
        XCTAssertEqual(analytics.lifecycleDistribution[.active], 1)
        XCTAssertEqual(analytics.lifecycleDistribution[.strategic], 1)
        
        // Performance metrics
        XCTAssertTrue(analytics.averagePerformanceRating > 0)
        XCTAssertEqual(analytics.topPerformers, 2) // vendor-2 and vendor-3
        XCTAssertEqual(analytics.poorPerformers, 0)
        
        // Financial metrics
        XCTAssertEqual(analytics.totalContractValue, 1350000) // Sum of all contract values
        XCTAssertTrue(analytics.averageContractValue > 0)
    }
    
    // MARK: - Data Validation Tests
    
    func testVendorDataValidation() async {
        var invalidVendor = testVendors[0]
        
        // Test empty company name
        invalidVendor.companyName = ""
        do {
            _ = try await vendorService.createVendor(invalidVendor)
            XCTFail("Should reject empty company name")
        } catch VendorLifecycleError.invalidData {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        
        // Test invalid email
        invalidVendor.companyName = "Valid Company"
        invalidVendor.email = "invalid-email"
        do {
            _ = try await vendorService.createVendor(invalidVendor)
            XCTFail("Should reject invalid email")
        } catch VendorLifecycleError.invalidData {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        
        // Test invalid contract dates
        invalidVendor.email = "valid@email.com"
        invalidVendor.contractEnd = Calendar.current.date(byAdding: .day, value: -1, to: invalidVendor.contractStart) ?? Date()
        do {
            _ = try await vendorService.createVendor(invalidVendor)
            XCTFail("Should reject end date before start date")
        } catch VendorLifecycleError.invalidData {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - CloudKit Serialization Tests
    
    func testVendorCloudKitSerialization() {
        let vendor = testVendors[0]
        
        // Test serialization to CKRecord
        let record = vendor.toCKRecord()
        XCTAssertEqual(record.recordType, "VendorModel")
        XCTAssertEqual(record["companyName"] as? String, vendor.companyName)
        XCTAssertEqual(record["email"] as? String, vendor.email)
        XCTAssertEqual(record["vendorType"] as? String, vendor.vendorType.rawValue)
        
        // Test deserialization from CKRecord
        let deserializedVendor = VendorModel.fromCKRecord(record)
        XCTAssertNotNil(deserializedVendor)
        XCTAssertEqual(deserializedVendor?.companyName, vendor.companyName)
        XCTAssertEqual(deserializedVendor?.email, vendor.email)
        XCTAssertEqual(deserializedVendor?.vendorType, vendor.vendorType)
    }
    
    // MARK: - Performance Tests
    
    func testLargeVendorSetPerformance() {
        measure {
            // Create a large set of vendors for performance testing
            var largeVendorSet: [VendorModel] = []
            
            for i in 0..<1000 {
                let address = Address(
                    street: "Street \(i)",
                    city: "City \(i)",
                    state: "State",
                    zipCode: "12345",
                    country: "USA"
                )
                
                let vendor = VendorModel(
                    id: "vendor-\(i)",
                    vendorNumber: "V\(String(format: "%03d", i))",
                    companyName: "Company \(i)",
                    contactPerson: "Contact \(i)",
                    email: "contact\(i)@company\(i).com",
                    phone: "555-\(String(format: "%04d", i))",
                    address: address,
                    vendorType: .supplier,
                    contractStart: Date(),
                    contractEnd: Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date(),
                    paymentTerms: "Net 30"
                )
                
                largeVendorSet.append(vendor)
            }
            
            vendorService.vendors = largeVendorSet
            
            // Test analytics generation performance
            Task {
                let analytics = await vendorService.generateVendorAnalytics()
                XCTAssertEqual(analytics.totalVendors, 1000)
            }
        }
    }
    
    // MARK: - Edge Cases Tests
    
    func testVendorWithNoPerformanceHistory() async {
        let newVendor = testVendors[0]
        newVendor.performanceHistory = []
        
        vendorService.vendors = [newVendor]
        
        let scorecard = await vendorService.calculateVendorScorecard(for: newVendor.id)
        XCTAssertNotNil(scorecard)
        XCTAssertEqual(scorecard?.overallScore, 0.0)
    }
    
    func testVendorNotFound() async {
        vendorService.vendors = []
        
        do {
            try await vendorService.transitionVendorStage(
                vendorId: "non-existent",
                to: .active,
                reason: "Test"
            )
            XCTFail("Should throw vendor not found error")
        } catch VendorLifecycleError.vendorNotFound {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testRiskAssessmentForVendorWithMinimalData() async {
        var minimalVendor = testVendors[0]
        minimalVendor.performanceHistory = []
        minimalVendor.financialHealth = FinancialHealthMetrics()
        
        vendorService.vendors = [minimalVendor]
        
        let riskAssessment = await vendorService.assessVendorRisk(for: minimalVendor.id)
        XCTAssertNotNil(riskAssessment)
        // Should handle minimal data gracefully
    }
}

// MARK: - Mock Extensions for Testing

extension VendorLifecycleService {
    func setTestVendors(_ vendors: [VendorModel]) {
        self.vendors = vendors
    }
}
