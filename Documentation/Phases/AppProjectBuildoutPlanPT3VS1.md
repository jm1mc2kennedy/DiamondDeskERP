# Diamond Desk – Load Testing, Localization Assets & Expanded Gherkin Scenarios

**Purpose:** Companion artifact providing (a) practical load / performance test harness samples tailored to a CloudKit‑only Phase 1 iOS deployment, (b) concrete localization key asset examples (.strings / .stringsdict / pseudo‑locale), and (c) an expanded library of formal Gherkin scenarios to broaden acceptance coverage.

---

## 1. Load / Performance Test Strategy

### 1.1 Objectives

| Goal                           | Description                                                                        | Success Criterion                                                |
| ------------------------------ | ---------------------------------------------------------------------------------- | ---------------------------------------------------------------- |
| Validate CRUD latency budgets  | Ensure core record create/query/update ops meet p50/p95 targets defined in Annex   | ≥90% sampled ops within budget; no sustained regressions >15%    |
| Establish scalability envelope | Understand safe concurrency levels before CloudKit rate limits / throttling appear | Identify plateau & error inflection; document backoff thresholds |
| Detect schema hotspots         | Find record types / predicates with disproportionate latency                       | Top 3 slow queries isolated w/ remediation plan                  |
| Measure offline queue drain    | Time to flush N pending mutations after reconnect                                  | Flush 100 queued ops < 10s (no user interaction)                 |
| Guard performance in CI        | Fail fast on regression introduced by code changes                                 | Baseline JSON diff < threshold (p95 delta ≤ +15%)                |

### 1.2 Workload Model (Phase 1 Internal Beta)

| Operation                             | Approx Rate / Active User / Hour | Mix % | Notes                                  |
| ------------------------------------- | -------------------------------- | ----- | -------------------------------------- |
| Task query (assigned list refresh)    | 12                               | 25%   | Pull‑to‑refresh & background intervals |
| Task update (completion / ack)        | 4                                | 8%    | Burst around shift changes             |
| Ticket list query                     | 6                                | 12%   | Filter changes included                |
| Ticket comment create                 | 3                                | 6%    | Short text bodies                      |
| Client follow‑up query                | 4                                | 8%    | Includes date window filter            |
| Audit item save (during active audit) | 30 (clustered)                   | 18%   | Short high‑churn window                |
| Visual merch upload (photo)           | 0.5                              | 3%    | Larger CKAsset ops                     |
| KPI dashboard refresh                 | 3                                | 7%    | After store meetings                   |
| Background delta sync cycles          | 6                                | 13%   | Silent pushes + periodic fetch         |

### 1.3 Constraints & Considerations (CloudKit)

- **Server‑side joins absent:** focus predicate simplicity (single field filters + containment).
- **Rate Limits:** Adaptive retry with exponential backoff (starting 0.5s → max 8s); load tests should intentionally escalate concurrency to observe CKError.limitExceeded occurrences.
- **Batch Size:** Modify operations batched ≤ 25 records; assets uploaded sequentially or small parallelism (2‑3) to avoid bandwidth saturation.
- **Idempotency:** Test harness uses deterministic seed data + recordName patterns to allow repeatable runs.

### 1.4 Metrics Collection Format

Sample JSON line (local log → aggregated):

```json
{"ts":"2025-07-19T14:05:12Z","op":"TaskQuery","count":42,"durationMs":382,"resultCount":37,"success":true,"retries":0,"net":"wifi"}
```

### 1.5 Baseline & Regression Detection

1. Capture 5 warm runs on reference device (e.g., iPhone 15) -> compute p50/p95 per op -> store baseline JSON.
2. CI job executes nightly synthetic run (mock or limited staging container) -> compares p95 deltas.
3. Fail build if any critical op (TaskQuery, TicketSave, AssetUpload) p95 > +15% vs baseline (moving window of last 3 baselines to smooth noise).

---

## 2. Sample Load Test Harnesses

### 2.1 Swift Concurrency Synthetic Load (XCTest)

```swift
import XCTest
import CloudKit

final class CloudKitLoadTests: XCTestCase {
    let db = CKContainer(identifier: "iCloud.com.company.DiamondDesk").publicCloudDatabase
    struct Metrics { var durations: [Double] = [] }
    var taskMetrics = Metrics()

    func testTaskQueryLoad() async throws {
        let iterations = 30
        for _ in 0..<iterations {
            let start = CFAbsoluteTimeGetCurrent()
            let predicate = NSPredicate(format: "assignedUserIds CONTAINS %@", TestConfig.userId)
            let q = CKQuery(recordType: "Task", predicate: predicate)
            let (records, _) = try await db.records(matching: q, desiredKeys: ["title","dueDate"])
            let dur = (CFAbsoluteTimeGetCurrent() - start) * 1000
            taskMetrics.durations.append(dur)
            XCTAssertLessThan(dur, 1200, "Single query too slow: \(dur)ms")
            XCTAssert(records.count <= 200)
        }
        let sorted = taskMetrics.durations.sorted()
        let p50 = sorted[sorted.count/2]
        let p95 = sorted[Int(Double(sorted.count) * 0.95) - 1]
        print("TaskQuery p50=\(Int(p50))ms p95=\(Int(p95))ms")
    }
}
```

> *Note:* `records(matching:)` convenience requires iOS 17+; otherwise assemble `CKQueryOperation` manually and measure in delegate callbacks.

### 2.2 Asset Upload Stress (Swift)

```swift
func uploadSyntheticPhotos(count: Int) async throws -> [CKRecord.ID] {
    let db = CKContainer.default().publicCloudDatabase
    return try await withThrowingTaskGroup(of: CKRecord.ID.self) { group in
        let semaphore = AsyncSemaphore(value: 2) // limit parallelism
        for i in 0..<count {
            group.addTask {
                try await semaphore.wait()
                defer { semaphore.signal() }
                let rec = CKRecord(recordType: "VisualMerchTemp")
                rec["storeCode"] = "010" as CKRecordValue
                rec["submittedBy"] = TestConfig.userId as CKRecordValue
                rec["submittedAt"] = Date() as CKRecordValue
                rec["photoAssets"] = [try TestData.smallJPEGAsset(name: "vm_\(i)")] as CKRecordValue
                try await db.save(rec)
                return rec.recordID
            }
        }
        return try await group.reduce(into: []) { $0.append($1) }
    }
}
```

### 2.3 k6 Script (CloudKit Web Services REST – *Illustrative*)

```javascript
// k6 run task_query.js
import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  vus: 20,
  duration: '2m',
  thresholds: {
    http_req_duration: ['p(95)<900'],
  },
};

const BASE = 'https://api.apple-cloudkit.com/database/1/<CONTAINER>/<ENV>/public/records/query';
const TOKEN = __ENV.CK_TOKEN; // server-to-server container token

export default function () {
  const payload = JSON.stringify({
    recordType: 'Task',
    filterBy: [{ fieldName: 'assignedUserIds', comparator: 'EQUALS', fieldValue: { value: '<USER_ID>' } }],
    desiredKeys: ['title','dueDate'],
    resultsLimit: 50
  });
  const res = http.post(`${BASE}?ckAPIToken=${TOKEN}`, payload, { headers: { 'Content-Type': 'application/json' }});
  check(res, { 'status 200': r => r.status === 200 });
  sleep(1 + Math.random()*2);
}
```

> Adjust `vus` & ramp stages to explore limit thresholds; ensure usage complies with Apple guidelines.

### 2.4 Locust (Python) Example

```python
from locust import HttpUser, task, between
import json, random

class CloudKitUser(HttpUser):
    wait_time = between(1, 3)
    token = "<CK_TOKEN>"
    base = "https://api.apple-cloudkit.com/database/1/<CONTAINER>/<ENV>/public/records/query"

    @task(3)
    def task_query(self):
        payload = {
            "recordType": "Task",
            "filterBy": [{"fieldName": "assignedUserIds", "comparator": "EQUALS", "fieldValue": {"value": "<USER_ID>"}}],
            "resultsLimit": 50
        }
        self.client.post(f"{self.base}?ckAPIToken={self.token}", data=json.dumps(payload))

    @task(1)
    def ticket_query(self):
        payload = {"recordType": "Ticket", "resultsLimit": 30}
        self.client.post(f"{self.base}?ckAPIToken={self.token}", data=json.dumps(payload))
```

### 2.5 Result Aggregation Script (Swift CLI Snippet)

```swift
struct OpStat: Decodable { let op: String; let durationMs: Double }
let stats = try JSONDecoder().decode([OpStat].self, from: Data(contentsOf: URL(fileURLWithPath: "run.json")))
let grouped = Dictionary(grouping: stats, by: { $0.op })
for (op, arr) in grouped {
  let sorted = arr.map{ $0.durationMs }.sorted()
  let p95 = sorted[Int(Double(sorted.count)*0.95)-1]
  print("\(op) p95=\(Int(p95))ms count=\(arr.count)")
}
```

---

## 3. Concrete Localization Assets

### 3.1 Naming & Conventions

- **Format:** `Domain.View.Element.Action` (PascalCase segments).
- **Comments:** Provide translator context above each key.
- **Placeholders:** Always specify ordered `%@` / `%d` with comment clarifying variable.
- **No Embedded HTML:** Use separate attributed assembly if styling needed.

### 3.2 Base `Localizable.strings` (Excerpt)

```text
/* Dashboard Title */
"Dashboard.Title" = "Dashboard";
/* Task List Empty State */
"Task.List.Empty" = "No tasks yet";
/* Button: Mark Task Complete */
"Task.Detail.MarkComplete" = "Mark Complete";
/* Group task completion progress label (%d = completed, %d = total) */
"Task.Detail.ProgressFormat" = "%d of %d complete";
/* Acknowledgment required pill */
"Task.Detail.AckRequired" = "Acknowledgment Required";
/* Ticket confidential badge */
"Ticket.Badge.Confidential" = "Confidential";
/* CRM upcoming birthday label (%@ = name) */
"CRM.Client.BirthdaySoon" = "%@'s birthday soon";
/* Visual Merch awaiting approval */
"VisualMerch.Status.Pending" = "Pending Approval";
/* Generic error retry */
"Error.Generic.Retry" = "Something went wrong. Try again.";
/* Offline banner */
"Status.Offline" = "Offline Mode";
```

### 3.3 Spanish `es.lproj/Localizable.strings` (Sample)

```text
"Dashboard.Title" = "Panel";
"Task.List.Empty" = "No hay tareas";
"Task.Detail.MarkComplete" = "Marcar como completada";
"Task.Detail.ProgressFormat" = "%d de %d completadas";
"Task.Detail.AckRequired" = "Se requiere acuse";
"Ticket.Badge.Confidential" = "Confidencial";
"CRM.Client.BirthdaySoon" = "Pronto es el cumpleaños de %@";
"VisualMerch.Status.Pending" = "Pendiente de aprobación";
"Error.Generic.Retry" = "Ocurrió un error. Intenta de nuevo.";
"Status.Offline" = "Modo sin conexión";
```

### 3.4 French `fr.lproj/Localizable.strings`

```text
"Dashboard.Title" = "Tableau";
"Task.List.Empty" = "Aucune tâche";
"Task.Detail.MarkComplete" = "Marquer terminée";
"Task.Detail.ProgressFormat" = "%d sur %d terminées";
"Task.Detail.AckRequired" = "Accusé requis";
"Ticket.Badge.Confidential" = "Confidentiel";
"CRM.Client.BirthdaySoon" = "Anniversaire de %@ bientôt";
"VisualMerch.Status.Pending" = "En attente d'approbation";
"Error.Generic.Retry" = "Une erreur est survenue. Réessayez.";
"Status.Offline" = "Mode hors ligne";
```

### 3.5 Pseudo‑Locale (for Expansion / RTL Simulation)

```text
"Dashboard.Title" = "⟦Đàşħƀøářđ⟧";
"Task.List.Empty" = "⟦Ńø ţàşķş yēţ⟧";
"Task.Detail.MarkComplete" = "⟦Mářķ Ĉøṃƥŀēţē⟧";
```

> Launch with arguments: `-AppleLanguages (ps)` or custom scheme that swaps in pseudo bundle.

### 3.6 Plurals (`Localizable.stringsdict`)

```xml
<plist version="1.0"><dict>
  <key>Task.Count.Remaining</key>
  <dict>
    <key>NSStringLocalizedFormatKey</key><string>%#@tasks@</string>
    <key>tasks</key><dict>
      <key>NSStringFormatSpecTypeKey</key><string>NSStringPluralRuleType</string>
      <key>NSStringFormatValueTypeKey</key><string>d</string>
      <key>one</key><string>%d task remaining</string>
      <key>other</key><string>%d tasks remaining</string>
    </dict>
  </dict>
  <key>Ticket.Response.Minutes</key>
  <dict>
    <key>NSStringLocalizedFormatKey</key><string>%#@mins@</string>
    <key>mins</key><dict>
      <key>NSStringFormatSpecTypeKey</key><string>NSStringPluralRuleType</string>
      <key>NSStringFormatValueTypeKey</key><string>d</string>
      <key>one</key><string>%d minute since last response</string>
      <key>other</key><string>%d minutes since last response</string>
    </dict>
  </dict>
</dict></plist>
```

### 3.7 Translator Handoff (CSV Sample)

```csv
Key,Context,English,Spanish,French
Dashboard.Title,Screen title,Dashboard,Panel,Tableau
Task.List.Empty,Empty list label,No tasks yet,No hay tareas,Aucune tâche
Task.Detail.MarkComplete,Primary action,Mark Complete,Marcar como completada,Marquer terminée
```

### 3.8 Validation Script (Swift)

```swift
// Detect missing translations across supported locales
let locales = ["Base", "es", "fr"]
let base = loadKeys(locale: "Base")
for loc in locales where loc != "Base" {
  let diff = base.subtracting(loadKeys(locale: loc))
  if !diff.isEmpty { print("Missing in \(loc): \(diff)") }
}
```

---

## 4. Expanded Gherkin Scenario Library

> **Style:** Focus on clear Given/When/Then; include Scenario Outlines for combinatorial coverage. Not all will be automated immediately; prioritize High value.

### 4.1 Tasks & Acknowledgments

```gherkin
Feature: Task acknowledgment tracking
  Scenario: User acknowledges required task
    Given a task "Safety Brief" with acknowledgment required assigned to user U1
    And user U1 has not acknowledged the task
    When user U1 taps "Acknowledge"
    Then the task shows an acknowledgment badge cleared for user U1
    And an event "Task.Ack.Confirm" is logged
```

```gherkin
Feature: Individual completion does not complete group
  Scenario: Single assignee completes group task
    Given a group task assigned to users U1 and U2
    When U1 marks the task complete
    Then the overall task status remains "In Progress"
    And completion percent is 50%
```

### 4.2 Tickets – SLA & Confidentiality

```gherkin
Feature: Ticket SLA breach alert
  Scenario: SLA breach notification after inactivity
    Given a ticket "Printer Jam" with SLA limit 60 minutes
    And the last response was 61 minutes ago
    When the ticket list refreshes
    Then the ticket displays an SLA breach badge
```

```gherkin
Feature: Confidential ticket hidden
  Scenario: Store Director blocked from HR ticket
    Given a ticket marked with confidential flag "HR"
    And user SD1 has role StoreDirector and no HR department
    When SD1 attempts to open the ticket
    Then a "Restricted" message is shown
```

### 4.3 CRM – Follow-Ups & Reminders

```gherkin
Feature: Birthday reminder filter
  Scenario: Birthday within configured window
    Given client C has a birthday 25 days from today
    And birthday reminder window is 30 days
    When the user views Birthday reminders
    Then client C appears in the list
```

```gherkin
Feature: Follow-up due exclusion
  Scenario: Follow-up beyond window is not shown
    Given client D has followUpDate 21 days from now
    And follow-up window is 7 days
    When the user views Follow-Ups
    Then client D is not shown
```

### 4.4 Audits – Auto Ticket Draft

```gherkin
Feature: Fail item creates ticket draft
  Scenario: Auto-create ticket on failed audit item
    Given audit template T has autoCreateTicket enabled
    And an audit A of template T is in progress for store S
    When user marks item "Security Cameras" as Fail with note "Camera 3 offline"
    Then a ticket draft is created referencing audit A and item key
```

### 4.5 Training – Quiz Scoring

```gherkin
Feature: Training quiz completion
  Scenario Outline: Score recorded and pass flag set
    Given a published training course "Safety101" with pass threshold 80
    And user <user> has not started the course
    When user <user> completes the quiz with score <score>
    Then the training enrollment progress shows 100%
    And the quizScore is <score>
    And the completion status is <status>

    Examples:
      | user | score | status    |
      | U1   | 85    | Passed    |
      | U2   | 60    | Incomplete |
```

### 4.6 Visual Merch – Revision Cycle

```gherkin
Feature: Visual merch revision request
  Scenario: Approver requests revision
    Given a visual merch upload V in status "Pending"
    And user AD1 (AreaDirector) opens upload V
    When AD1 selects "Request Revision" with comment "Lighting glare"
    Then upload V status becomes "NeedsRevision"
    And the submitting user receives a notification
```

### 4.7 Performance Goals – Override

```gherkin
Feature: Store goal override
  Scenario: StoreGoal overrides global target
    Given a global performance goal for month M with salesTarget 10000
    And a store goal for store S for month M with salesTarget 12000
    When store S dashboard loads for month M
    Then the displayed target is 12000
```

### 4.8 Conflict Resolution – Role Precedence

```gherkin
Feature: Status conflict resolution
  Scenario: Lower role overridden by higher
    Given ticket T status is "Open"
    And user Associate A offline changes status to "Closed"
    And user AreaDirector D online changes status to "InProgress" at a later timestamp
    When A syncs
    Then ticket T status is "InProgress"
    And a conflict log entry records A's overridden change
```

### 4.9 Localization – Missing Key Fallback

```gherkin
Feature: Missing translation fallback
  Scenario: Spanish missing key uses base
    Given app locale is "es"
    And the key "Task.Detail.MarkComplete" is missing in Spanish bundle
    When Task Detail appears
    Then the English string "Mark Complete" is displayed
    And a missing translation event is logged
```

### 4.10 Accessibility – Dynamic Type Wrapping

```gherkin
Feature: Large text wraps KPI tiles
  Scenario: Accessibility XXL text size
    Given system text size is Accessibility XXL
    When the dashboard loads
    Then each KPI tile wraps text without truncation
    And horizontal scrolling is not required
```

### 4.11 Ingestion – Duplicate Deduplication

```gherkin
Feature: StoreReport duplicate prevention
  Scenario: Second import same store/date updates existing record
    Given a StoreReport exists for store S on date D with totalSales 1000
    When ingestion runs with a row for store S on date D with totalSales 1050
    Then the StoreReport totalSales becomes 1050
    And no duplicate record is created
```

### 4.12 Offline Sync – Queued Mutations

```gherkin
Feature: Offline task completion queued
  Scenario: Completion while offline
    Given device is offline
    And task X assigned to user U1 is incomplete
    When U1 marks task X complete
    Then task X shows status "Complete" locally with pending icon
    When connectivity restores
    Then the completion is uploaded
    And the pending icon disappears
```

### 4.13 Notifications – Task Assignment Push

```gherkin
Feature: New task push notification
  Scenario: Silent push triggers background fetch
    Given user U1 is assigned a new task T while app is backgrounded
    When a silent push with task recordID arrives
    Then the app fetches T in background
    And the badge count increases by 1
```

### 4.14 Reporting – KPI Calculation Integrity

```gherkin
Feature: Weighted gpPct calculation
  Scenario: Weighted formula applied
    Given two StoreReport records for store S:
      | totalSales | gpPct |
      | 1000       | 0.40  |
      | 2000       | 0.30  |
    When gpPct is computed for the period
    Then the result is (1000*0.40 + 2000*0.30)/3000 = 0.3333
```

### 4.15 Security – Confidential Field Redaction

```gherkin
Feature: HR ticket redaction in unauthorized list
  Scenario: Non-HR user sees limited fields
    Given ticket T is flagged "HR"
    And user U2 role Associate not in HR
    When ticket list loads
    Then ticket T is not included OR appears only with title "Restricted" and no description
```

---

## 5. Prioritization of Scenario Automation

| Priority | Feature Area | Scenario IDs                                                 |
| -------- | ------------ | ------------------------------------------------------------ |
| P0       | Core Ops     | Task acknowledgment; Conflict precedence; Offline completion |
| P0       | Security     | Confidential ticket hidden; HR redaction                     |
| P1       | Performance  | Weighted gpPct; StoreReport dedupe                           |
| P1       | UX Integrity | Dynamic Type wrapping; Missing translation fallback          |
| P2       | Workflow     | Visual merch revision; Auto ticket from audit                |
| P2       | Engagement   | Training quiz scoring                                        |

---

## 6. Next Steps

1. Integrate Swift load harness into dedicated `PerformanceTests` target; gate in CI nightly lane.
2. Add localization validation script pre‑build phase to catch missing keys.
3. Tag Gherkin scenarios with `@p0`, `@security`, etc. for selective automation.
4. Implement minimal event logger for translation misses & conflict merges.
5. Baseline first full performance run and persist JSON artifact.

---

**End of Document**

### Data Models (addendum)

#### Phase 4 Enterprise Models

```swift
// Document Management System Models
struct DocumentModel: Identifiable, Codable {
    let id: String
    var title: String
    var fileType: String
    var fileSize: Int64
    var version: String
    var createdBy: String
    var createdAt: Date
    var modifiedBy: String
    var modifiedAt: Date
    var accessLevel: DocumentAccessLevel
    var departmentRestrictions: [String]
    var tags: [String]
    var documentPath: String
    var thumbnailPath: String?
    var checkoutBy: String?
    var checkoutAt: Date?
    var approvalStatus: DocumentApprovalStatus
    var retentionPolicy: RetentionPolicy
    var auditTrail: [DocumentAuditEntry]
}

enum DocumentAccessLevel: String, CaseIterable {
    case public = "PUBLIC"
    case internal = "INTERNAL" 
    case confidential = "CONFIDENTIAL"
    case restricted = "RESTRICTED"
}

enum DocumentApprovalStatus: String, CaseIterable {
    case draft = "DRAFT"
    case pendingReview = "PENDING_REVIEW"
    case approved = "APPROVED"
    case rejected = "REJECTED"
    case archived = "ARCHIVED"
}

struct DocumentAuditEntry: Codable {
    let action: String
    let performedBy: String
    let timestamp: Date
    let details: String
    let ipAddress: String?
}

// Unified Permissions Framework Models
struct RoleDefinitionModel: Identifiable, Codable {
    let id: String
    var name: String
    var description: String
    var inheritFrom: String?
    var permissions: [PermissionEntry]
    var contextualRules: [ContextualRule]
    var isSystemRole: Bool
    var departmentScope: [String]
    var locationScope: [String]
    var createdAt: Date
    var modifiedAt: Date
}

struct PermissionEntry: Codable {
    let resource: String
    let actions: [String]
    let conditions: [String]?
    let inherited: Bool
}

struct ContextualRule: Codable {
    let condition: String
    let timeRestrictions: TimeRestriction?
    let locationRestrictions: [String]?
    let additionalPermissions: [PermissionEntry]
    let deniedPermissions: [PermissionEntry]
}

// Employee & Vendor Directory Models  
struct EmployeeModel: Identifiable, Codable {
    let id: String
    var employeeNumber: String
    var firstName: String
    var lastName: String
    var email: String
    var phone: String?
    var department: String
    var title: String
    var manager: String?
    var directReports: [String]
    var hireDate: Date
    var birthDate: Date?
    var address: Address
    var emergencyContact: EmergencyContact
    var skills: [String]
    var certifications: [Certification]
    var performanceHistory: [PerformanceReview]
    var isActive: Bool
    var profilePhoto: String?
}

struct VendorModel: Identifiable, Codable {
    let id: String
    var companyName: String
    var contactPerson: String
    var email: String
    var phone: String
    var address: Address
    var vendorType: VendorType
    var contractStart: Date
    var contractEnd: Date
    var paymentTerms: String
    var performanceRating: Double
    var certifications: [String]
    var serviceCategories: [String]
    var isPreferred: Bool
    var riskLevel: RiskLevel
    var auditHistory: [VendorAudit]
}

// Enhanced Audit Models
struct AuditTemplateModel: Identifiable, Codable {
    let id: String
    var name: String
    var description: String
    var category: String
    var sections: [AuditSection]
    var scoringMethod: ScoringMethod
    var passingScore: Double
    var estimatedDuration: Int
    var requiredRole: String
    var autoCreateTickets: Bool
    var complianceFramework: String?
    var version: String
    var isActive: Bool
    var createdBy: String
    var createdAt: Date
}

struct AuditSection: Codable, Identifiable {
    let id: String
    var title: String
    var weight: Double
    var items: [AuditItem]
    var conditionalLogic: ConditionalLogic?
}

struct AuditItem: Codable, Identifiable {
    let id: String
    var question: String
    var itemType: AuditItemType
    var required: Bool
    var weight: Double
    var acceptableValues: [String]?
    var photoRequired: Bool
    var aiAnalysisEnabled: Bool
    var helpText: String?
}

// Performance Target Management Models
struct PerformanceGoalModel: Identifiable, Codable {
    let id: String
    var title: String
    var description: String
    var goalType: GoalType
    var targetValue: Double
    var currentValue: Double
    var unit: String
    var period: GoalPeriod
    var assignedTo: String
    var assignedBy: String
    var parentGoal: String?
    var childGoals: [String]
    var startDate: Date
    var endDate: Date
    var status: GoalStatus
    var progress: Double
    var milestones: [Milestone]
    var kpiMetrics: [KPIMetric]
}

enum GoalType: String, CaseIterable {
    case individual = "INDIVIDUAL"
    case team = "TEAM"
    case department = "DEPARTMENT"
    case company = "COMPANY"
}

enum GoalPeriod: String, CaseIterable {
    case daily = "DAILY"
    case weekly = "WEEKLY"
    case monthly = "MONTHLY"
    case quarterly = "QUARTERLY"
    case annual = "ANNUAL"
}

// Enterprise Project Management Models
struct ProjectModel: Identifiable, Codable {
    let id: String
    var name: String
    var description: String
    var projectManager: String
    var sponsor: String
    var startDate: Date
    var endDate: Date
    var status: ProjectStatus
    var priority: ProjectPriority
    var budget: Double
    var actualCost: Double
    var progress: Double
    var phases: [ProjectPhase]
    var dependencies: [ProjectDependency]
    var resources: [ResourceAllocation]
    var risks: [ProjectRisk]
    var stakeholders: [String]
    var deliverables: [Deliverable]
}

struct ProjectPhase: Codable, Identifiable {
    let id: String
    var name: String
    var startDate: Date
    var endDate: Date
    var status: PhaseStatus
    var progress: Double
    var tasks: [String]
    var milestones: [Milestone]
    var budget: Double
    var actualCost: Double
}

struct ResourceAllocation: Codable {
    let resourceId: String
    let resourceType: ResourceType
    let allocation: Double // percentage
    let startDate: Date
    let endDate: Date
    let cost: Double
}

enum ResourceType: String, CaseIterable {
    case human = "HUMAN"
    case equipment = "EQUIPMENT"
    case facility = "FACILITY"
    case software = "SOFTWARE"
    case budget = "BUDGET"
}

#### Calendar Module
```graphql
type CalendarEvent {
  id: ID!
  title: String!
  startTime: DateTime!
  endTime: DateTime!
  location: String
  ownerId: ID!
  attendees: [EventAttendee!]!
  calendarGroupId: ID
  isSyncedWithOutlook: Boolean!
}

type EventAttendee {
  id: ID!
  eventId: ID!
  userId: ID!
  status: String! # e.g. accepted, declined
}

type CalendarGroup {
  id: ID!
  name: String!
  ownerId: ID!
  members: [ID!]!
  isPublic: Boolean!
}
```

#### Asset Management Module
```graphql
type Asset {
  id: ID!
  name: String!
  type: String!
  category: String
  tags: [String!]!
  uploadedBy: ID!
  uploadDate: Date!
  storagePath: String!
  accessRoles: [String!]!
  fileSize: Int!
  mimeType: String!
  usageCount: Int!
}

type AssetCategory {
  id: ID!
  name: String!
  parentId: ID
  description: String
}

type AssetTag {
  id: ID!
  name: String!
  color: String
}

type AssetUsageLog {
  id: ID!
  assetId: ID!
  userId: ID!
  action: String!
  timestamp: DateTime!
  context: String
}
```

#### Workflow & Automation Builder
```graphql
type Workflow {
  id: ID!
  name: String!
  description: String
  triggerType: String!
  isActive: Boolean!
  createdBy: ID!
  createdAt: DateTime!
  lastExecuted: DateTime
  executionCount: Int!
}

type TriggerCondition {
  id: ID!
  workflowId: ID!
  field: String!
  operator: String!
  value: String!
  logicalOperator: String # AND, OR
}

type ActionStep {
  id: ID!
  workflowId: ID!
  stepOrder: Int!
  actionType: String!
  params: JSON!
  isEnabled: Boolean!
}

type WorkflowExecution {
  id: ID!
  workflowId: ID!
  status: String!
  startedAt: DateTime!
  completedAt: DateTime
  errorMessage: String
  executedBy: ID
}
```

#### Office 365 Integration
```graphql
type Office365Token {
  id: ID!
  userId: ID!
  accessToken: String!
  refreshToken: String!
  expiry: DateTime!
  scope: [String!]!
  tenantId: String!
}

type SharePointResource {
  id: ID!
  userId: ID!
  path: String!
  resourceType: String!
  lastIndexed: DateTime
  isAccessible: Boolean!
  metadata: JSON
}

type OutlookIntegration {
  id: ID!
  userId: ID!
  isCalendarSyncEnabled: Boolean!
  isEmailSyncEnabled: Boolean!
  lastSyncAt: DateTime
  syncErrors: [String!]!
}

type MicrosoftGraphSync {
  id: ID!
  userId: ID!
  resourceType: String!
  lastSyncToken: String
  syncStatus: String!
  errorCount: Int!
}
```

#### Custom Reports Module
```graphql
type CustomReport {
  id: ID!
  name: String!
  ownerId: ID!
  parserTemplateId: ID!
  createdAt: Date!
  lastRun: Date
  outputPath: String
  description: String
  isPublic: Boolean!
  tags: [String!]!
}

type ParserTemplate {
  id: ID!
  name: String!
  pythonCode: String!
  version: Int!
  createdBy: ID!
  isActive: Boolean!
  parameters: JSON
  outputSchema: JSON
}

type UploadRecord {
  id: ID!
  reportId: ID!
  filename: String!
  version: Int!
  uploadDate: Date!
  fileSize: Int!
  processedRows: Int
  errorCount: Int
}

type ReportLog {
  id: ID!
  reportId: ID!
  entryDate: Date!
  summary: String!
  executionTime: Float
  status: String!
  errorDetails: String
}
```

#### Customizable Dashboards & Widgets
```graphql
type UserDashboard {
  id: ID!
  userId: ID!
  name: String!
  layout: JSON!
  isDefault: Boolean!
  isPublic: Boolean!
  createdAt: Date!
  lastModified: Date!
}

type DashboardWidget {
  id: ID!
  dashboardId: ID!
  module: String!
  widgetType: String!
  config: JSON!
  position: JSON!
  size: JSON!
  isEnabled: Boolean!
}

type WidgetConfig {
  id: ID!
  widgetType: String!
  name: String!
  description: String
  defaultConfig: JSON!
  requiredPermissions: [String!]!
  availableModules: [String!]!
}
```

#### User Interface Customization
```graphql
type UserPreferences {
  id: ID!
  userId: ID!
  preferredTheme: String!
  iconChoice: String!
  navOrder: [String!]!
  colorScheme: String!
  sidebarCollapsed: Boolean!
  defaultView: String
  notificationSettings: JSON
  lastUpdated: Date!
}

type ThemeOption {
  id: ID!
  name: String!
  colorScheme: JSON!
  previewImage: String
  isActive: Boolean!
  category: String!
}

type AppIconOption {
  id: ID!
  name: String!
  iconPath: String!
  category: String!
  isDefault: Boolean!
}
```

#### Cross-Module Record Linking
```graphql
type RecordLink {
  id: ID!
  sourceModule: String!
  sourceId: ID!
  targetModule: String!
  targetId: ID!
  linkType: String!
  label: String
  context: String
  createdBy: ID!
  createdAt: Date!
  isActive: Boolean!
}

type LinkableRecord {
  id: ID!
  module: String!
  recordId: ID!
  title: String!
  description: String
  recordType: String!
  metadata: JSON
}

type RecordLinkRule {
  id: ID!
  sourceModule: String!
  targetModule: String!
  isEnabled: Boolean!
  autoLinkConditions: JSON
  requiredPermissions: [String!]!
}
```
```

//
```

#### Phase 4.11-4.15 Enterprise Data Models (Custom Reports, Dashboards, Office365 Deep Integration, UI Customization, Cross-Module Linking)

```swift
// Custom Reports Module Models
struct CustomReportModel: Identifiable, Codable {
    let id: String
    var name: String
    var description: String
    var ownerId: String
    var parserTemplateId: String
    var reportType: ReportType
    var dataSourceConnections: [DataSourceConnection]
    var scheduleConfig: ReportScheduleConfig?
    var outputFormat: ReportOutputFormat
    var accessLevel: ReportAccessLevel
    var tags: [String]
    var createdAt: Date
    var lastExecuted: Date?
    var executionCount: Int
    var averageExecutionTime: TimeInterval
    var isActive: Bool
    var retentionPolicy: RetentionPolicy
}

struct ParserTemplateModel: Identifiable, Codable {
    let id: String
    var name: String
    var description: String
    var version: String
    var pythonCode: String
    var inputSchema: ReportSchema
    var outputSchema: ReportSchema
    var validationRules: [ValidationRule]
    var testDataSets: [TestDataSet]
    var createdBy: String
    var createdAt: Date
    var lastModified: Date
    var isPublic: Bool
    var downloadCount: Int
    var rating: Double
    var tags: [String]
}

struct ReportExecutionLogModel: Identifiable, Codable {
    let id: String
    var reportId: String
    var executionStartTime: Date
    var executionEndTime: Date?
    var status: ExecutionStatus
    var inputFileMetadata: FileMetadata
    var outputFileMetadata: FileMetadata?
    var recordsProcessed: Int
    var recordsValid: Int
    var recordsRejected: Int
    var errorMessages: [ExecutionError]
    var performanceMetrics: ExecutionMetrics
    var triggeredBy: String
    var triggeredMethod: TriggerMethod
}

enum ReportType: String, CaseIterable {
    case salesAnalysis = "SALES_ANALYSIS"
    case performanceMetrics = "PERFORMANCE_METRICS"
    case complianceReport = "COMPLIANCE_REPORT"
    case customDataProcessing = "CUSTOM_DATA_PROCESSING"
    case crossModuleAnalysis = "CROSS_MODULE_ANALYSIS"
}

enum ExecutionStatus: String, CaseIterable {
    case queued = "QUEUED"
    case running = "RUNNING"
    case completed = "COMPLETED"
    case failed = "FAILED"
    case cancelled = "CANCELLED"
    case partialSuccess = "PARTIAL_SUCCESS"
}

// Customizable Dashboards Models
struct DashboardModel: Identifiable, Codable {
    let id: String
    var name: String
    var description: String
    var ownerId: String
    var layoutConfiguration: DashboardLayout
    var widgets: [DashboardWidgetInstance]
    var refreshInterval: TimeInterval
    var isPublic: Bool
    var sharedWith: [String]
    var roleRestrictions: [String]
    var isTemplate: Bool
    var templateCategory: String?
    var viewCount: Int
    var lastAccessed: Date
    var createdAt: Date
    var modifiedAt: Date
}

struct DashboardWidgetInstance: Identifiable, Codable {
    let id: String
    var widgetTypeId: String
    var position: WidgetPosition
    var size: WidgetSize
    var configuration: WidgetConfiguration
    var dataConnections: [DataConnection]
    var refreshSettings: RefreshSettings
    var conditionalDisplay: ConditionalDisplayRule?
    var accessPermissions: [String]
    var isEnabled: Bool
    var customStyling: WidgetStyling?
}

struct WidgetTypeDefinition: Identifiable, Codable {
    let id: String
    var name: String
    var description: String
    var category: WidgetCategory
    var supportedDataSources: [String]
    var configurationSchema: WidgetConfigSchema
    var defaultConfiguration: WidgetConfiguration
    var minimumSize: WidgetSize
    var maximumSize: WidgetSize
    var requiredPermissions: [String]
    var previewImage: String
    var documentation: String
    var version: String
    var isActive: Bool
}

struct DashboardLayout: Codable {
    var gridColumns: Int
    var gridRows: Int
    var responsiveBreakpoints: [ResponsiveBreakpoint]
    var backgroundColor: String
    var headerConfiguration: HeaderConfiguration
    var sidebarConfiguration: SidebarConfiguration?
    var footerConfiguration: FooterConfiguration?
}

enum WidgetCategory: String, CaseIterable {
    case kpiMetrics = "KPI_METRICS"
    case chartVisualization = "CHART_VISUALIZATION"
    case dataTable = "DATA_TABLE"
    case activityFeed = "ACTIVITY_FEED"
    case statusIndicator = "STATUS_INDICATOR"
    case controlPanel = "CONTROL_PANEL"
    case textDisplay = "TEXT_DISPLAY"
    case mediaViewer = "MEDIA_VIEWER"
}

// Office365 Deep Integration Models
struct Office365IntegrationModel: Identifiable, Codable {
    let id: String
    var userId: String
    var tenantId: String
    var applicationId: String
    var authenticationTokens: Office365TokenSet
    var enabledServices: [Office365Service]
    var syncConfiguration: SyncConfiguration
    var lastSyncStatus: SyncStatus
    var errorHistory: [IntegrationError]
    var usageStatistics: UsageStatistics
    var permissionGrants: [PermissionGrant]
    var isActive: Bool
    var createdAt: Date
    var lastSyncAt: Date?
}

struct Office365TokenSet: Codable {
    var accessToken: String
    var refreshToken: String
    var idToken: String?
    var tokenType: String
    var expiresAt: Date
    var scope: [String]
    var lastRefreshed: Date
}

struct SharePointResourceModel: Identifiable, Codable {
    let id: String
    var userId: String
    var siteId: String
    var driveId: String
    var itemId: String
    var itemPath: String
    var itemName: String
    var itemType: SharePointItemType
    var mimeType: String
    var fileSize: Int64?
    var lastModifiedBy: String
    var lastModifiedAt: Date
    var accessLevel: SharePointAccessLevel
    var syncStatus: SyncStatus
    var localCachePath: String?
    var versionInfo: SharePointVersionInfo
    var isShared: Bool
    var sharePermissions: [SharePermission]
}

struct OutlookIntegrationModel: Identifiable, Codable {
    let id: String
    var userId: String
    var mailboxId: String
    var calendarSyncEnabled: Bool
    var emailSyncEnabled: Bool
    var contactSyncEnabled: Bool
    var taskSyncEnabled: Bool
    var syncFilters: OutlookSyncFilters
    var lastCalendarSync: Date?
    var lastEmailSync: Date?
    var lastContactSync: Date?
    var syncErrors: [OutlookSyncError]
    var performanceMetrics: OutlookMetrics
}

enum Office365Service: String, CaseIterable {
    case outlook = "OUTLOOK"
    case sharePoint = "SHAREPOINT"
    case teams = "TEAMS"
    case powerBI = "POWER_BI"
    case oneDrive = "ONEDRIVE"
    case planner = "PLANNER"
    case dynamics365 = "DYNAMICS_365"
}

enum SharePointItemType: String, CaseIterable {
    case folder = "FOLDER"
    case file = "FILE"
    case list = "LIST"
    case listItem = "LIST_ITEM"
    case site = "SITE"
    case drive = "DRIVE"
}

// User Interface Customization Models
struct UserInterfacePreferencesModel: Identifiable, Codable {
    let id: String
    var userId: String
    var themeConfiguration: ThemeConfiguration
    var navigationConfiguration: NavigationConfiguration
    var layoutPreferences: LayoutPreferences
    var accessibilitySettings: AccessibilitySettings
    var moduleVisibility: ModuleVisibilitySettings
    var personalizations: [PersonalizationSetting]
    var isSystemDefault: Bool
    var lastModified: Date
    var syncAcrossDevices: Bool
}

struct ThemeConfiguration: Codable {
    var themeId: String
    var colorScheme: ColorScheme
    var darkModePreference: DarkModePreference
    var accentColor: String
    var backgroundStyle: BackgroundStyle
    var iconStyle: IconStyle
    var fontConfiguration: FontConfiguration
    var customColorOverrides: [String: String]
}

struct NavigationConfiguration: Codable {
    var sidebarStyle: SidebarStyle
    var menuItems: [NavigationMenuItem]
    var collapsedByDefault: Bool
    var showModuleIcons: Bool
    var groupingPreference: NavigationGrouping
    var customShortcuts: [CustomShortcut]
    var breadcrumbsEnabled: Bool
    var searchInNavigation: Bool
}

struct LayoutPreferences: Codable {
    var informationDensity: InformationDensity
    var cardSizing: CardSizing
    var listViewStyle: ListViewStyle
    var defaultViewModes: [String: ViewMode]
    var gridColumnPreferences: [String: Int]
    var pageSizePreferences: [String: Int]
    var sortingPreferences: [String: SortConfiguration]
}

struct AppIconConfiguration: Identifiable, Codable {
    let id: String
    var name: String
    var description: String
    var iconSetPath: String
    var category: IconCategory
    var isDefault: Bool
    var isSeasonalVariant: Bool
    var availabilityPeriod: DateInterval?
    var requiredRole: String?
    var previewImage: String
    var approvalStatus: ApprovalStatus
    var downloadCount: Int
}

enum DarkModePreference: String, CaseIterable {
    case system = "SYSTEM"
    case light = "LIGHT"
    case dark = "DARK"
    case auto = "AUTO"
}

enum InformationDensity: String, CaseIterable {
    case compact = "COMPACT"
    case standard = "STANDARD"
    case comfortable = "COMFORTABLE"
    case spacious = "SPACIOUS"
}

enum IconCategory: String, CaseIterable {
    case seasonal = "SEASONAL"
    case corporate = "CORPORATE"
    case minimal = "MINIMAL"
    case colorful = "COLORFUL"
    case themed = "THEMED"
    case branded = "BRANDED"
}

// Cross-Module Record Linking Models
struct RecordLinkModel: Identifiable, Codable {
    let id: String
    var sourceModule: String
    var sourceRecordId: String
    var targetModule: String
    var targetRecordId: String
    var linkType: LinkType
    var relationshipCategory: RelationshipCategory
    var linkStrength: LinkStrength
    var bidirectional: Bool
    var contextMetadata: LinkContext
    var createdBy: String
    var createdAt: Date
    var lastValidated: Date
    var validationStatus: ValidationStatus
    var automaticallyCreated: Bool
    var confidenceScore: Double?
    var isActive: Bool
}

struct LinkableRecordModel: Identifiable, Codable {
    let id: String
    var recordId: String
    var module: String
    var recordType: String
    var title: String
    var description: String?
    var metadata: RecordMetadata
    var linkingRules: [LinkingRule]
    var searchableFields: [String]
    var lastIndexed: Date
    var indexVersion: String
    var accessRestrictions: [String]
}

struct RecordLinkRuleModel: Identifiable, Codable {
    let id: String
    var name: String
    var description: String
    var sourceModule: String
    var targetModule: String
    var autoLinkConditions: [AutoLinkCondition]
    var linkingAlgorithm: LinkingAlgorithm
    var confidenceThreshold: Double
    var maxSuggestions: Int
    var isEnabled: Bool
    var requiredPermissions: [String]
    var createdBy: String
    var createdAt: Date
    var lastModified: Date
    var usageStatistics: RuleUsageStatistics
}

struct LinkSuggestionModel: Identifiable, Codable {
    let id: String
    var sourceRecordId: String
    var targetRecordId: String
    var suggestionReason: SuggestionReason
    var confidenceScore: Double
    var suggestedLinkType: LinkType
    var supportingEvidence: [EvidenceItem]
    var generatedAt: Date
    var status: SuggestionStatus
    var reviewedBy: String?
    var reviewedAt: Date?
    var feedback: SuggestionFeedback?
}

enum LinkType: String, CaseIterable {
    case relatedTo = "RELATED_TO"
    case dependsOn = "DEPENDS_ON"
    case affects = "AFFECTS"
    case contains = "CONTAINS"
    case partOf = "PART_OF"
    case assignedTo = "ASSIGNED_TO"
    case causedBy = "CAUSED_BY"
    case resolvedBy = "RESOLVED_BY"
    case references = "REFERENCES"
    case duplicateOf = "DUPLICATE_OF"
}

enum RelationshipCategory: String, CaseIterable {
    case hierarchical = "HIERARCHICAL"
    case peer = "PEER"
    case dependency = "DEPENDENCY"
    case causal = "CAUSAL"
    case temporal = "TEMPORAL"
    case spatial = "SPATIAL"
    case contextual = "CONTEXTUAL"
}

enum LinkStrength: String, CaseIterable {
    case weak = "WEAK"
    case moderate = "MODERATE"
    case strong = "STRONG"
    case critical = "CRITICAL"
}

enum SuggestionStatus: String, CaseIterable {
    case pending = "PENDING"
    case accepted = "ACCEPTED"
    case rejected = "REJECTED"
    case expired = "EXPIRED"
    case superseded = "SUPERSEDED"
}

// Supporting GraphQL Schemas for Phase 4.11-4.15

#### Custom Reports Module (GraphQL)
```graphql
type CustomReport {
  id: ID!
  name: String!
  description: String
  ownerId: ID!
  parserTemplateId: ID!
  reportType: ReportType!
  dataSourceConnections: [DataSourceConnection!]!
  scheduleConfig: ReportScheduleConfig
  outputFormat: ReportOutputFormat!
  accessLevel: ReportAccessLevel!
  tags: [String!]!
  createdAt: DateTime!
  lastExecuted: DateTime
  executionCount: Int!
  averageExecutionTime: Float!
  isActive: Boolean!
  retentionPolicy: RetentionPolicy!
}

type ParserTemplate {
  id: ID!
  name: String!
  description: String
  version: String!
  pythonCode: String!
  inputSchema: ReportSchema!
  outputSchema: ReportSchema!
  validationRules: [ValidationRule!]!
  testDataSets: [TestDataSet!]!
  createdBy: ID!
  createdAt: DateTime!
  lastModified: DateTime!
  isPublic: Boolean!
  downloadCount: Int!
  rating: Float!
  tags: [String!]!
}

type ReportExecutionLog {
  id: ID!
  reportId: ID!
  executionStartTime: DateTime!
  executionEndTime: DateTime
  status: ExecutionStatus!
  inputFileMetadata: FileMetadata!
  outputFileMetadata: FileMetadata
  recordsProcessed: Int!
  recordsValid: Int!
  recordsRejected: Int!
  errorMessages: [ExecutionError!]!
  performanceMetrics: ExecutionMetrics!
  triggeredBy: ID!
  triggeredMethod: TriggerMethod!
}

enum ReportType {
  SALES_ANALYSIS
  PERFORMANCE_METRICS
  COMPLIANCE_REPORT
  CUSTOM_DATA_PROCESSING
  CROSS_MODULE_ANALYSIS
}

enum ExecutionStatus {
  QUEUED
  RUNNING
  COMPLETED
  FAILED
  CANCELLED
  PARTIAL_SUCCESS
}
```

#### Customizable Dashboards (GraphQL)
```graphql
type Dashboard {
  id: ID!
  name: String!
  description: String
  ownerId: ID!
  layoutConfiguration: DashboardLayout!
  widgets: [DashboardWidgetInstance!]!
  refreshInterval: Float!
  isPublic: Boolean!
  sharedWith: [ID!]!
  roleRestrictions: [String!]!
  isTemplate: Boolean!
  templateCategory: String
  viewCount: Int!
  lastAccessed: DateTime!
  createdAt: DateTime!
  modifiedAt: DateTime!
}

type DashboardWidgetInstance {
  id: ID!
  widgetTypeId: ID!
  position: WidgetPosition!
  size: WidgetSize!
  configuration: WidgetConfiguration!
  dataConnections: [DataConnection!]!
  refreshSettings: RefreshSettings!
  conditionalDisplay: ConditionalDisplayRule
  accessPermissions: [String!]!
  isEnabled: Boolean!
  customStyling: WidgetStyling
}

type WidgetTypeDefinition {
  id: ID!
  name: String!
  description: String
  category: WidgetCategory!
  supportedDataSources: [String!]!
  configurationSchema: WidgetConfigSchema!
  defaultConfiguration: WidgetConfiguration!
  minimumSize: WidgetSize!
  maximumSize: WidgetSize!
  requiredPermissions: [String!]!
  previewImage: String!
  documentation: String!
  version: String!
  isActive: Boolean!
}

enum WidgetCategory {
  KPI_METRICS
  CHART_VISUALIZATION
  DATA_TABLE
  ACTIVITY_FEED
  STATUS_INDICATOR
  CONTROL_PANEL
  TEXT_DISPLAY
  MEDIA_VIEWER
}
```

#### Office365 Deep Integration (GraphQL)
```graphql
type Office365Integration {
  id: ID!
  userId: ID!
  tenantId: String!
  applicationId: String!
  authenticationTokens: Office365TokenSet!
  enabledServices: [Office365Service!]!
  syncConfiguration: SyncConfiguration!
  lastSyncStatus: SyncStatus!
  errorHistory: [IntegrationError!]!
  usageStatistics: UsageStatistics!
  permissionGrants: [PermissionGrant!]!
  isActive: Boolean!
  createdAt: DateTime!
  lastSyncAt: DateTime
}

type SharePointResource {
  id: ID!
  userId: ID!
  siteId: String!
  driveId: String!
  itemId: String!
  itemPath: String!
  itemName: String!
  itemType: SharePointItemType!
  mimeType: String!
  fileSize: Int
  lastModifiedBy: String!
  lastModifiedAt: DateTime!
  accessLevel: SharePointAccessLevel!
  syncStatus: SyncStatus!
  localCachePath: String
  versionInfo: SharePointVersionInfo!
  isShared: Boolean!
  sharePermissions: [SharePermission!]!
}

type OutlookIntegration {
  id: ID!
  userId: ID!
  mailboxId: String!
  calendarSyncEnabled: Boolean!
  emailSyncEnabled: Boolean!
  contactSyncEnabled: Boolean!
  taskSyncEnabled: Boolean!
  syncFilters: OutlookSyncFilters!
  lastCalendarSync: DateTime
  lastEmailSync: DateTime
  lastContactSync: DateTime
  syncErrors: [OutlookSyncError!]!
  performanceMetrics: OutlookMetrics!
}

enum Office365Service {
  OUTLOOK
  SHAREPOINT
  TEAMS
  POWER_BI
  ONEDRIVE
  PLANNER
  DYNAMICS_365
}

enum SharePointItemType {
  FOLDER
  FILE
  LIST
  LIST_ITEM
  SITE
  DRIVE
}
```

#### User Interface Customization (GraphQL)
```graphql
type UserInterfacePreferences {
  id: ID!
  userId: ID!
  themeConfiguration: ThemeConfiguration!
  navigationConfiguration: NavigationConfiguration!
  layoutPreferences: LayoutPreferences!
  accessibilitySettings: AccessibilitySettings!
  moduleVisibility: ModuleVisibilitySettings!
  personalizations: [PersonalizationSetting!]!
  isSystemDefault: Boolean!
  lastModified: DateTime!
  syncAcrossDevices: Boolean!
}

type ThemeConfiguration {
  themeId: String!
  colorScheme: ColorScheme!
  darkModePreference: DarkModePreference!
  accentColor: String!
  backgroundStyle: BackgroundStyle!
  iconStyle: IconStyle!
  fontConfiguration: FontConfiguration!
  customColorOverrides: [ColorOverride!]!
}

type NavigationConfiguration {
  sidebarStyle: SidebarStyle!
  menuItems: [NavigationMenuItem!]!
  collapsedByDefault: Boolean!
  showModuleIcons: Boolean!
  groupingPreference: NavigationGrouping!
  customShortcuts: [CustomShortcut!]!
  breadcrumbsEnabled: Boolean!
  searchInNavigation: Boolean!
}

type AppIconConfiguration {
  id: ID!
  name: String!
  description: String
  iconSetPath: String!
  category: IconCategory!
  isDefault: Boolean!
  isSeasonalVariant: Boolean!
  availabilityPeriod: DateRange
  requiredRole: String
  previewImage: String!
  approvalStatus: ApprovalStatus!
  downloadCount: Int!
}

enum DarkModePreference {
  SYSTEM
  LIGHT
  DARK
  AUTO
}

enum IconCategory {
  SEASONAL
  CORPORATE
  MINIMAL
  COLORFUL
  THEMED
  BRANDED
}
```

#### Cross-Module Record Linking (GraphQL)
```graphql
type RecordLink {
  id: ID!
  sourceModule: String!
  sourceRecordId: ID!
  targetModule: String!
  targetRecordId: ID!
  linkType: LinkType!
  relationshipCategory: RelationshipCategory!
  linkStrength: LinkStrength!
  bidirectional: Boolean!
  contextMetadata: LinkContext!
  createdBy: ID!
  createdAt: DateTime!
  lastValidated: DateTime!
  validationStatus: ValidationStatus!
  automaticallyCreated: Boolean!
  confidenceScore: Float
  isActive: Boolean!
}

type LinkableRecord {
  id: ID!
  recordId: ID!
  module: String!
  recordType: String!
  title: String!
  description: String
  metadata: RecordMetadata!
  linkingRules: [LinkingRule!]!
  searchableFields: [String!]!
  lastIndexed: DateTime!
  indexVersion: String!
  accessRestrictions: [String!]!
}

type RecordLinkRule {
  id: ID!
  name: String!
  description: String
  sourceModule: String!
  targetModule: String!
  autoLinkConditions: [AutoLinkCondition!]!
  linkingAlgorithm: LinkingAlgorithm!
  confidenceThreshold: Float!
  maxSuggestions: Int!
  isEnabled: Boolean!
  requiredPermissions: [String!]!
  createdBy: ID!
  createdAt: DateTime!
  lastModified: DateTime!
  usageStatistics: RuleUsageStatistics!
}

type LinkSuggestion {
  id: ID!
  sourceRecordId: ID!
  targetRecordId: ID!
  suggestionReason: SuggestionReason!
  confidenceScore: Float!
  suggestedLinkType: LinkType!
  supportingEvidence: [EvidenceItem!]!
  generatedAt: DateTime!
  status: SuggestionStatus!
  reviewedBy: ID
  reviewedAt: DateTime
  feedback: SuggestionFeedback
}

enum LinkType {
  RELATED_TO
  DEPENDS_ON
  AFFECTS
  CONTAINS
  PART_OF
  ASSIGNED_TO
  CAUSED_BY
  RESOLVED_BY
  REFERENCES
  DUPLICATE_OF
}

enum RelationshipCategory {
  HIERARCHICAL
  PEER
  DEPENDENCY
  CAUSAL
  TEMPORAL
  SPATIAL
  CONTEXTUAL
}

enum LinkStrength {
  WEAK
  MODERATE
  STRONG
  CRITICAL
}

enum SuggestionStatus {
  PENDING
  ACCEPTED
  REJECTED
  EXPIRED
  SUPERSEDED
}
````

