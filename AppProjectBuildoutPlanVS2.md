# Diamond Desk – iOS CloudKit Project Blueprint (Firebase References Removed)

**Version:** 1.0 (Clean CloudKit Rewrite)\
**Prepared For:** Hannoush Jewelers – Retail Operations Leadership\
**Primary Stakeholder:** Executive Director Retail Operations & Development\
**Platforms (Phase 1):** iOS & iPadOS (Universal SwiftUI app)\
**Deferred:** Web / Admin Portal (future phase), macOS Catalyst (evaluate later)

---

## Current Build Status (2025-07-19)

- Core navigation and all four major modules live: Tasks, Tickets, Clients, KPIs.
- User provisioning on launch; views filter to signed-in user ID and assigned store(s).
- Tasks and Tickets have robust CRUD (create/edit) support with validation, error handling, accessible UI, and Liquid Glass visual polish.
- Clients and KPIs currently support create operations, display errors gracefully, and feature accessible card/list designs; edit capability coming next.
- Basic test coverage now includes validation and error path checks for key flows in Task and Ticket creation.
- Next up: advanced filtering and search, batch operations, notification integration, onboarding UI, multi-store KPI support; enterprise modules backlog: Performance Targets, Project Management (Directory filter & creation UI implemented).

---

## 1. Executive Summary

Diamond Desk centralizes mission‑critical retail operations: communications, tasks, tickets, audits, training, CRM, performance analytics, KPIs, and visual merchandising. Phase 1 delivers a production‑viable internal beta **this week** using **CloudKit** for persistence, identity, sync, push change notifications, and media storage (CKAssets). No legacy references to Firebase / Firestore remain; all authorization and data modeling align with CloudKit constraints (record type limits, indexing rules, per‑record ACL semantics, subscription quotas).

---

## 2. Architectural Overview

| Layer             | Technology                                                          | Purpose                                                                       |
| ----------------- | ------------------------------------------------------------------- | ----------------------------------------------------------------------------- |
| UI                | SwiftUI + Combine                                                   | Declarative reactive interface, dynamic role gating                           |
| State / Domain    | Observable view models + async/await                                | Consolidate business logic, isolate CloudKit calls                            |
| Persistence       | CloudKit (Public + Private DB) + optional Core Data mirror          | Durable storage, offline caching, delta sync                                  |
| Media             | CloudKit CKAssets in dedicated record types or fields               | Photos (audits, visual merch, CRM), documents, training videos (small/medium) |
| Auth / Identity   | iCloud account + Sign In with Apple (for internal identity mapping) | Secure, reduces password overhead                                             |
| Notifications     | CKSubscriptions (push)                                              | Real‑time updates (tasks assigned, tickets updated, acknowledgments)          |
| Analytics (Local) | Aggregation in app + periodic background refresh                    | KPI rollups for dashboard                                                     |

### 2.1 CloudKit Zones Strategy

| Zone                                                  | Contents                                                                                                | Scope                               |
| ----------------------------------------------------- | ------------------------------------------------------------------------------------------------------- | ----------------------------------- |
| Public Default                                        | Reference / shared operational data (Stores, Roles, TrainingCourse metadata, KPI Goals, AuditTemplates) | Company-wide                        |
| Custom Public Zones (e.g. `TicketsZone`, `TasksZone`) | High‑churn operational records enabling efficient CKFetchChanges                                        | Company-wide filtered by role/store |
| User Private DB                                       | UserSettings, NotificationPreferences, LayoutPreferences, ephemeral drafts                              | Per-user                            |
| Shared DB (Phase 2+)                                  | Optional document collaboration (knowledge base inline editing)                                         | Future                              |

---

## 3. Roles & Permission Model (Enforced Client + Data Design)

**Roles:** Admin, AreaDirector, StoreDirector, DepartmentHead, Agent, Associate.\
**Scopes:** Store codes (e.g., "08", "10") and Department codes (HR, LP, Ops, Marketing, Inventory, QA, Finance, Facilities, LossPrevention, Productivity).

### 3.1 Record-Level Permission Fields

Each operational record includes fields enabling deterministic filtering:

- `roleVisibility: [String]` (e.g. ["Admin","AreaDirector"]) – broad gate.
- `storeCodes: [String]` – one or many store scope values.
- `departments: [String]` – department linkage.
- `createdByUserRef` (CKReference) – ownership for fallback access.
- `assignedUserRefs` (Tasks/Tickets) – explicit per-user access.
- `confidentialFlags` (Tickets: HR, LP) – hide from store directors if HR flagged.

**Enforcement:** CloudKit cannot express complex RBAC server rules beyond basic sharing; therefore **defense-in-depth**:

1. **Query Predicates:** Filter by store/department before fetch (minimizes over-fetch).
2. **Post-Fetch Validation:** Local pruning against current user’s role & lists.
3. **UI Gating:** Hide actions (edit/assign/close) if capability absent.

### 3.2 Capabilities Matrix (Excerpt)

| Capability                           | Admin | AreaDir             | StoreDir    | DeptHead        | Agent                                  | Associate |
| ------------------------------------ | ----- | ------------------- | ----------- | --------------- | -------------------------------------- | --------- |
| Manage Users (role/store/department) | ✅     | ⬜ (down-chain only) | ❌           | ❌               | ❌                                      | ❌         |
| Assign Stores                        | ✅     | ✅ (within region)   | ❌           | ❌               | ❌                                      | ❌         |
| Create Tasks (All Stores)            | ✅     | ✅                   | Own Store   | Dept Scope      | Dept Scope                             | Self Only |
| Close Ticket                         | ✅     | ✅                   | Store-scope | Dept-scope      | Dept-scope                             | ❌         |
| View Sales KPIs (All Company)        | ✅     | ✅                   | Store Only  | Dept (filtered) | Dept (filtered)                        | ❌         |
| Upload Training                      | ✅     | ✅                   | ❌           | Dept-scope      | Dept-scope                             | ❌         |
| Approve Marketing Content            | ✅     | ✅                   | ✅           | Dept-scope      | Dept-scope (if Marketing/Productivity) | ❌         |

(Full extended matrix kept in separate internal appendix; can be added if required.)

---

## 4. CloudKit Data Model

Below are **primary CKRecordTypes** (prefix omitted for clarity). All date fields ISO8601 strings (or Date) with server timestamp set client‑side; maintain `updatedAt` for conflict resolution auditing.

| Record Type                | Key Fields                                                                                                                                                                                                                                                                                                     | Notes                                                                                                                            |                                                     |
| -------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------- |
| User                       | userId (UUID), email, displayName, role, storeCodes[], departments[], isActive, createdAt, lastLoginAt                                                                                                                                                                                                         | Created at first launch after Sign In with Apple identity resolution                                                             |                                                     |
| UserSettings               | userRef, notificationPrefs(json), crmLayout ("tabbed"                                                                                                                                                                                                                                                          | "scroll"), darkMode, smartRemindersEnabled                                                                                       | Private DB                                          |
| Store                      | code, name, address\*, status, region, createdAt                                                                                                                                                                                                                                                               | Seeded initial list; modifiable by Admin                                                                                         |                                                     |
| Department                 | code, name                                                                                                                                                                                                                                                                                                     | Normalized list                                                                                                                  |                                                     |
| Task                       | title, description, status, dueDate, isGroupTask (Bool), completionMode ("group"                                                                                                                                                                                                                               | "individual"), assignedUserRefs[], completedUserRefs[], storeCodes[], departments[], createdByRef, createdAt, requiresAck (Bool) | Completion logic differentiates group vs individual |
| TaskComment                | taskRef, authorRef, body, createdAt                                                                                                                                                                                                                                                                            | Lightweight; optional first release (could inline)                                                                               |                                                     |
| Ticket                     | title, description, category, status, priority, department, storeCodes[], createdByRef, assignedUserRef, watchers[], confidentialFlags[], slaOpenedAt, lastResponseAt, responseDeltas[], attachments[] (AssetRefs)                                                                                             | SLA analytics derived locally                                                                                                    |                                                     |
| TicketComment              | ticketRef, authorRef, body, createdAt, attachments[]                                                                                                                                                                                                                                                           | Chronological display                                                                                                            |                                                     |
| Client                     | guestAcctNumber, guestName, partnerName, dob(s), address\*, contactPreference[], accountType[], ringSizes, importantDates[], jewelryPreferences, wishList(json), purchaseHistory(json lightweight), contactHistory(json), notes, assignedUserRef, preferredStoreCode, createdByRef, createdAt, lastInteraction | Larger media (drawings) in separate `ClientMedia`                                                                                |                                                     |
| ClientMedia                | clientRef, type (photo/drawing/doc), asset (CKAsset), uploadedByRef, createdAt                                                                                                                                                                                                                                 | Avoids large record payloads                                                                                                     |                                                     |
| TrainingCourse             | title, description, assetRefs[], scormManifests[], createdByRef, createdAt                                                                                                                                                                                                                                     | Large videos may need external CDN in future                                                                                     |                                                     |
| TrainingProgress           | courseRef, userRef, status, score, completedAt, lastAccessedAt                                                                                                                                                                                                                                                 | Dashboard KPIs                                                                                                                   |                                                     |
| Document                   | title, category, version, asset (CKAsset), uploadedByRef, updatedAt, versionHistory[] (json meta only)                                                                                                                                                                                                         | Store diff meta only, not all binary versions                                                                                    |                                                     |
| KnowledgeArticle           | title, body(markdown), tags[], version, authorRef, updatedAt, visibilityRoles[]                                                                                                                                                                                                                                | Future shared editing zone                                                                                                       |                                                     |
| Survey                     | title, questions(json schema), isAnonymous, createdByRef, targetStoreCodes[], targetRoles[]                                                                                                                                                                                                                    | Distribution filters                                                                                                             |                                                     |
| SurveyResponse             | surveyRef, userRef (nullable if anonymous), answers(json), submittedAt                                                                                                                                                                                                                                         | Analytics aggregated locally                                                                                                     |                                                     |
| AuditTemplate              | name, sections(json), weighting(json), createdByRef, createdAt                                                                                                                                                                                                                                                 | Template authoring gated                                                                                                         |                                                     |
| Audit                      | templateRef, storeCode, startedByRef, startedOn, finishedOn, status, scoreSummary(json), responses(json), photoAssets[]                                                                                                                                                                                        | Failed items may spawn Tickets                                                                                                   |                                                     |
| VisualMerchTask            | taskRef (optional), storeCode, title, instructions, createdAt                                                                                                                                                                                                                                                  | Paired with uploads for approval                                                                                                 |                                                     |
| VisualMerchUpload          | merchTaskRef, storeCode, submittedByRef, photoAssets[], submittedAt, approvedByRef, approvedAt, status                                                                                                                                                                                                         | Approval workflow                                                                                                                |                                                     |
| PerformanceGoal            | period (YYYY-MM), scope ("global"                                                                                                                                                                                                                                                                              | storeCode), targets(json partial KpiGoals), createdAt, createdByRef                                                              | Merges at runtime                                   |
| StoreReport                | storeCode, date, totalSales, totalTransactions, totalItems, upt, ads, ccpPct, gpPct                                                                                                                                                                                                                            | Derived from Sales Audit ingestion                                                                                               |                                                     |
| CreditReport               | storeCode, date, totalApplications                                                                                                                                                                                                                                                                             | Derived from file ingestion                                                                                                      |                                                     |
| BirdeyeReport              | storeCode, weekStart (ISO), reviewCount                                                                                                                                                                                                                                                                        | Weekly aggregate                                                                                                                 |                                                     |
| CrmIntakeReport            | storeCode, date, totalIntakes                                                                                                                                                                                                                                                                                  | Daily client intakes                                                                                                             |                                                     |
| OutboundCallReport         | storeCode, weekStart, totalCalls, dailyCounts(json)                                                                                                                                                                                                                                                            | Weekly activity                                                                                                                  |                                                     |
| VendorPerformance          | vendorId, vendorName, periodRange, totalSales, totalItems                                                                                                                                                                                                                                                      | Aggregated query results persisted (cache)                                                                                       |                                                     |
| CategoryPerformance        | category, periodRange, totalSales, totalItems                                                                                                                                                                                                                                                                  | As above                                                                                                                         |                                                     |
| KPIRecord (Optional cache) | date, storeCode, metrics(json)                                                                                                                                                                                                                                                                                 | Speeds dashboard load                                                                                                            |                                                     |
| SalesTarget                | storeCode, month, monthlyTarget, dailyTargets(json), createdByRef, updatedAt                                                                                                                                                                                                                                   | For dashboard target comparisons                                                                                                 |                                                     |

---

## 5. Data Access Patterns & Predicates (Illustrative)

**Fetch Tasks for Current User (Active or Assigned):**\
`(assignedUserRefs CONTAINS %@) OR (storeCodes CONTAINS %@ AND %@ IN roleVisibility)`\
**Tickets Visible (Non‑Confidential):**\
`(storeCodes CONTAINS %@ AND NOT (confidentialFlags CONTAINS "HR")) OR (createdByRef == %@) OR (assignedUserRef == %@)`\
**HR Ticket (Restricted):**\
`confidentialFlags CONTAINS "HR" AND (role == "Admin" OR role == "AreaDirector" OR department CONTAINS "HR")`

Post-fetch, further prune by department list union for multi‑dept Agents.

---

## 6. Sync, Offline, Conflict Strategy

| Concern                   | Strategy                                                                                                 |
| ------------------------- | -------------------------------------------------------------------------------------------------------- |
| Offline Read              | Core Data mirror (lightweight) keyed by recordName; last sync timestamps per type                        |
| Write Conflicts           | Attempt modify; on CKError.serverRecordChanged merge field-by-field (prefer newest `updatedAt`), re-save |
| High-Churn Collections    | Use separate zones + CKQuerySubscriptions for push deltas                                                |
| Batch Ingestion (Reports) | Parse file locally → create/upsert records in background queue → throttle to CK rate limits              |

---

## 7. File / Media Handling

| Use Case                   | Record Type / Field                 | Notes                                                    |
| -------------------------- | ----------------------------------- | -------------------------------------------------------- |
| Audit Photos               | Audit.photoAssets[] (Array CKAsset) | Limit size; compress JPEG before upload                  |
| Visual Merch Photos        | VisualMerchUpload.photoAssets[]     | Approval status drives retention                         |
| CRM Drawings / Style Cards | ClientMedia.asset                   | Tag type for filtering                                   |
| Training Videos            | TrainingCourse.assetRefs[]          | If > 50MB repeatedly, plan Phase 2 CDN (S3 + signed URL) |

Retention policy defined later (Phase 2) for archiving large assets.

---

## 8. Notifications & Subscriptions

| Event                    | Subscription Type                                                               | Payload Fields          |
| ------------------------ | ------------------------------------------------------------------------------- | ----------------------- |
| Task Assigned / Updated  | CKQuerySubscription on Task (predicate includes userRef)                        | taskId, status, dueDate |
| Ticket Status Change     | CKQuerySubscription on Ticket (assignedUserRef or storeCodes contains)          | ticketId, status        |
| Required Acknowledgment  | CKQuerySubscription (Task.requiresAck == TRUE & assignedUserRefs CONTAINS user) | acknowledgment flag     |
| Training Course Assigned | QuerySubscription on TrainingProgress (userRef)                                 | courseId, status        |
| Follow-up Reminder (CRM) | Local scheduled notification based on nextInteractionDate                       | clientId                |

UserSettings controls whether push converts to in-app banner or silent update.

---

## 9. Module Specifications

### 9.1 Messages (Phase 1 Scope)

- **Features:** 1:1, group threads, categories (labels) without visibility restriction, read receipts (per user ID set).
- **Data:** `MessageThread` (participants[], title?, category, lastMessageAt), `Message` (threadRef, authorRef, body, sentAt, readBy[])
- **View:** Conversation list (sorted by lastMessageAt) → Thread view (lazy loading).
- **Later:** Search index (local) by participant, body tokens.

### 9.2 Tasks

- Group vs individual completion.
- Per-user progress % on dashboard: `completedUserRefs.count / assignedUserRefs.count` (group) OR aggregated individuals.
- Acknowledgment receipts: boolean flag stored separately to isolate from completion semantics when needed.

### 9.3 Ticketing

- SLA metrics: store open time vs lastResponseAt deltas appended to `responseDeltas[]`.
- Confidential HR / LP segregation via `confidentialFlags` array.
- Auto-late indicator if no update > SLA threshold (config constant) – surfaces in dashboard.

### 9.4 Calendar / Events (Basic Internal)

- Local Event model (no external integration yet).
- Fields: title, startDate, endDate, isAllDay, storeCodes[], participants[].
- Future: Office 365 integration; keep abstraction layer `CalendarService` to swap provider.

  
### 9.5 Directory (Enterprise)
  
- Features: Employee directory list with search, filters, and multiple view modes (list, grid, org chart, map); employee detail display; add/edit employee profiles; org chart navigation; bulk import and LDAP integration (future).
  
- Data: `Employee` record type with personalInfo, contactInfo, organizationalInfo, professionalInfo, permissions, preferences, analytics.
  
- Views: `DirectoryListView`, `EmployeeDetailView`, `EmployeeCreationView`, `DirectoryFilterView`, `OrganizationalChartView`, `DirectoryMapView`.
  
- Later: Bulk import/export CSV, Active Directory sync, advanced org chart editing, profile photo upload and cropping.

  
### 9.6 Performance Targets (Enterprise)
  
- Features: Define and track performance targets for KPIs and custom metrics; list, detail, create/edit targets; assign to employees, departments, and projects; recurring targets and scheduling; deletion and notifications for target breaches.
  
- Data: `PerformanceTarget` record type with name, description, metricType, targetValue, unit, period, recurrence, assignedTo, departmentId, projectId.
  
- Views: `PerformanceTargetsListView`, `PerformanceTargetDetailView`, `PerformanceTargetCreationView`.
  
- Later: Progress tracking dashboard, target alerts, threshold notifications, goal alignment charts.

  
### 9.7 Project Management (Enterprise)
  
- Features: Project list view; project detail and timeline; create/edit projects; task and milestone association; stakeholder assignment; status updates (planning, active, on hold, completed); deletion.
  
- Data: `Project` record type with name, description, startDate, endDate, status, managerId, stakeholderIds, tasks, milestoneIds.
  
- Views: `ProjectListView`, `ProjectDetailView`, `ProjectCreationView`, `ProjectMilestonesView`, `ProjectTasksView`.
  
- Later: Gantt chart visualization, resource allocation, dependency management, export to CSV/PDF, project templating.

  
### 9.8 Documents & Knowledge Base

- Version history: append metadata entry to `versionHistory[]` (author, timestamp, changeSummary).
- Non‑privileged roles see only `updatedAt` & current asset.

### 9.9 Training Modules

- Support video (CKAsset) + quiz (questions JSON).
- Progress records create KPI signals.
- SCORM (Phase 2+): placeholder field `scormManifests[]` for import mapping.

### 9.10 Surveys

- Schema question types: single choice, multiple choice, text, number, acknowledgment (boolean).
- Anonymous: omit userRef and store hashed surrogate key for aggregate counts.

### 9.11 Audits

- Template-driven hierarchical sections, weighted scoring.
- On audit completion: if `responses[].answer == Fail` and `autoCreateTicket` setting enabled → stage ticket draft for approving role (AreaDirector or template owner) with prefilled context.

### 9.12 CRM

- Comprehensive fields per prior spec.
- Follow-up scheduling: nextInteractionDate derived from purchase anniversaries + custom reminders.
- Smart Alerts: Anniversary in 14 days, Inactivity > 180 days, Birthday in 30 days; user can disable individually.
- Tagging: free‑form plus controlled list (designers, style tags).
- Filters: store, assigned user, follow-up due window, birthday month, anniversary month, interest tags, account type, contact permission.
- Access: Associates see own + store peers (configurable), Agents limited to assigned departments (Marketing, Productivity).

### 9.13 Visual Merch

- Tasks reference; each submission requires approval by creator or designated approver (store director / area director).
- Revision cycle: resubmit until approved.

### 9.14 Performance Dashboard

- Aggregates WTD/MTD/YTD metrics from StoreReport + other ingestion record sets.
- Target merge: global PerformanceGoal + optional store override.
- Percent to target = (actual / target) - 1 displayed with color semantics (>=0 green, <0 red).
- Quarterly Review generator consolidates 3 months + quarter totals for export (PDF Phase 2).

### 9.15 Settings Module

- Notification preferences per module (Push / In-App / Email placeholder).
- Layout toggle for CRM detail (tab vs scroll).
- Dark Mode toggle (leverages system but user override stored).
- Smart reminders enable/disable.
- Localization scaffold (English base; key-based strings file).

---

## 10. KPI & Analytics Computation

| Metric         | Source                                                                      | Calculation                 |
| -------------- | --------------------------------------------------------------------------- | --------------------------- |
| totalSales     | Sum(StoreReport.totalSales)                                                 | Period filter (date range)  |
| avgAds         | totalSales / Sum(StoreReport.totalTransactions)                             | Guard zero transactions     |
| ccpPct         | Weighted avg of (StoreReport.ccpPct \* StoreReport.totalItems) / totalItems | Accuracy via item weighting |
| upt            | Sum(totalItems) / Sum(totalTransactions)                                    | —                           |
| gpPct          | Sum(StoreReport.gpPct \* totalSales) / totalSales                           | Weighted by sales           |
| creditApps     | Sum(CreditReport.totalApplications)                                         | —                           |
| birdeyeReviews | Sum(BirdeyeReport.reviewCount)                                              | Weekly aggregated roll-up   |
| guestCapture   | Sum(CrmIntakeReport.totalIntakes)                                           | —                           |
| outboundCalls  | Sum(OutboundCallReport.totalCalls)                                          | Weekly aggregated           |

Optional caching via KPIRecord to reduce recomputation overhead.

---

## 11. Ingestion Pipelines (Local Parsing → CloudKit Upsert)

| Feed                           | Input | Parser Notes                                 | Dedup Key           |
| ------------------------------ | ----- | -------------------------------------------- | ------------------- |
| Sales Audit                    | XLSX  | Extract daily store rows; map to StoreReport | storeCode+date      |
| Credit Apps                    | XLSX  | Normalize date + store code; bucket counts   | storeCode+date      |
| Birdeye Reviews                | XLSX  | Week start detection; map store code         | storeCode+weekStart |
| CRM Intakes                    | XLSX  | Company column → store code + date parse     | storeCode+date      |
| Outbound Calls                 | XLSX  | Weekly log → dailyCounts aggregate           | storeCode+weekStart |
| Employee Performance (Phase 2) | CSV   | Salesperson metrics; project projections     | employeeId+period   |

Upsert Algorithm: fetch existing record by predicate; if exists update fields; else create new.

---

## 12. Security & Privacy Considerations

| Aspect               | Control                                                                                                                                                                                           |
| -------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| PII (Client records) | Stored in Public DB (company internal) but access constrained by app logic; consider encryption at rest (Apple handled) + optional field-level client-side encryption for sensitive notes Phase 2 |
| HR / LP Tickets      | `confidentialFlags` gating + UI redaction for unauthorized roles                                                                                                                                  |
| Least Privilege      | Hide creation actions for roles lacking manage rights                                                                                                                                             |
| Audit Trail          | Maintain arrays of (timestamp, userRef, action, diff summary) in high-value records (Tickets, Documents)                                                                                          |
| Data Export          | Future: Signed CSV export restricted to Admin; not in Phase 1                                                                                                                                     |

---

## 13. Performance & Scaling Guardrails

| Concern                  | Mitigation                                                                     |
| ------------------------ | ------------------------------------------------------------------------------ |
| Large Queries (KPI view) | Date-bounded predicates + local cache (KPIRecord)                              |
| High-Frequency Polling   | Push subscriptions + background app refresh minimal fetch intervals            |
| Asset Bloat              | Enforce image compression (target < 500KB), limit photo count per Audit/Upload |
| Cold Start Latency       | Parallel initial fetch (User, Stores, Goals) + skeleton UI placeholders        |

---

## 14. Error Handling & Resilience

- **Categorization:** User (validation), Connectivity (no network), Server (CKError.\*), Conflict (serverRecordChanged).
- **Standard Retry Policy:** Exponential backoff for transient; immediate surfacing for user input errors.
- **Offline Queue:** Persist unsent mutations (JSON file or Core Data) with ordered replay when network returns.

---

## 15. Logging & Diagnostics

- Local structured log wrapper (os\_log) with categories: `sync`, `ingestion`, `ui`, `auth`.
- Redact PII in logs.
- Optional remote log shipping (Phase 2) via background CK record appends or third-party if approved.

---

## 16. Internationalization & Localization (Future-Proofing)

- Base English string keys.
- Use `LocalizationService` wrapper to centralize.
- Numeric / currency formatting via `NumberFormatter` respecting locale (USD enforced Phase 1, parameterized).

---

## 17. Extensibility for Future Web Portal

- Design record schemas agnostic of client UI; avoid iOS-specific naming.
- Keep a version field in complex JSON blobs (wishList v1, auditTemplate v1).
- Web portal can adopt same CloudKit containers; if multi-platform scaling becomes a constraint, plan migration path to hybrid (e.g., server layer + alternative DB) with export script.

---

## 18. Sprint 0 → Beta Execution Plan (Condensed)

| Sprint        | Duration | Primary Deliverables                                                                                                   |
| ------------- | -------- | ---------------------------------------------------------------------------------------------------------------------- |
| 0 (Today + 1) | 1–2 days | Core CK schema init scripts, User bootstrap, Store seeding, Role gating scaffolds                                      |
| 1             | 3–4 days | Tasks (CRUD, assign, completion logic, subscriptions), Messages MVP                                                    |
| 2             | 3–4 days | Tickets (CRUD, comments, SLA timers), Basic Dashboard (WTD/MTD Sales from seeded sample)                               |
| 3             | 3–4 days | CRM (create, assign, filters, follow-ups), Notifications preferences                                                   |
| 4             | 3–4 days | Audits + Visual Merch Uploads + Training (upload + progress)                                                           |
| 5 (Hardening) | 2–3 days | Ingestion pipelines (Sales Audit, Credit, CRM Intakes, Reviews, Outbound Calls), KPI aggregation, polish, QA, Beta cut |

Parallel small task: Documents/Knowledge Base (read + version metadata) integrated during idle developer capacity.

---

## 19. Open Items / Assumptions

| Item                            | Status   | Action                                           |
| ------------------------------- | -------- | ------------------------------------------------ |
| SCORM support                   | Deferred | Design manifest parser Phase 2                   |
| External Office 365 integration | Deferred | Abstract CalendarService now                     |
| HR ticket encryption            | Deferred | Evaluate per-field client encryption feasibility |
| Export / Reporting PDFs         | Deferred | Introduce in Performance Review Phase 2          |
| Advanced search (full-text)     | Deferred | Local index; consider Core Spotlight integration |

---

## 20. Next Steps Required from Stakeholder

1. Confirm KPI target calculation acceptance (weighted metrics) – **Pending**.
2. Provide any store region groupings (if AreaDirector scoping uses region) – **Needed**.
3. Approve Sprint Plan or request adjustments – **Pending**.
4. Supply initial set of training media filenames / sizes for capacity planning – **Optional**.
5. Clarify maximum expected weekly volume for Tickets & Tasks to validate subscription quota – **Optional**.

---

**End of CloudKit-Only Blueprint**\
No Firebase / Firestore references remain. Ready for confirmation or targeted deep dives (e.g., code templates, schema init).

---

## Appendix A – CKRecordType Schema (Initial)

> *Purpose:* Formalize the CloudKit data contract for Phase 1 iOS delivery. All numeric counts are `Int` unless suffixed; monetary values `Double` (USD). Timestamps ISO8601 strings where not using system `Date` directly.

| Record Type               | Key Fields (Name: Type)                                                                                                                                                                                                    | Required?                                                                   | Index / Query Notes                                                                                                                                        | Security / Access Logic (Client Enforced + Server Constraints)                                                                             |                                                                                                       |
| ------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------ | ----------------------------------------------------------------------------------------------------- |
| User                      | `role:String` `stores:[String]` `departments:[String]` `displayName:String` `isActive:Bool`                                                                                                                                | Yes                                                                         | Query by `role`, `stores CONTAINS`, `departments CONTAINS`                                                                                                 | Only self editable except Admin/AreaDirector for subordinates. Store/Dept arrays drive scope filters.                                      |                                                                                                       |
| Store                     | `storeCode:String` `name:String` `status:String`                                                                                                                                                                           | Yes                                                                         | Indexed by `storeCode`                                                                                                                                     | Read all; create/update Admin only.                                                                                                        |                                                                                                       |
| Task                      | `title:String` `detail:String` `dueDate:Date` `scopeStoreCodes:[String]?` `assignedUserIds:[String]` `isGroupCompletion:Bool` `completedUserIds:[String]` `createdBy:String` `ackRequired:Bool` `ackUserIds:[String]`      | Yes                                                                         | Predicates on `assignedUserIds CONTAINS` OR `scopeStoreCodes CONTAINS`                                                                                     | Write if creator or elevated role; completion updates allowed for assignees.                                                               |                                                                                                       |
| Ticket                    | `title:String` `description:String` `status:String` `storeCode:String` `department:String` `createdBy:String` `assignedTo:String?` `visibility:[String]` `responseSLASeconds:Int?` `lastResponseAt:Date?` `createdAt:Date` | Yes                                                                         | Filter by `storeCode`, `department`, `assignedTo`, `status`                                                                                                | If HR dept: restrict to HR roles + creator. Others: store + department scoping.                                                            |                                                                                                       |
| TicketComment             | `ticketRef:CKReference(Ticket)` `authorId:String` `body:String` `createdAt:Date` `attachments:[CKAsset]?`                                                                                                                  | Yes                                                                         | Query by `ticketRef`                                                                                                                                       | Only visible if parent Ticket visible.                                                                                                     |                                                                                                       |
| Client                    | (Full CRM spec fields) `assignedUserId:String?` `storeCode:String` `tags:[String]` `followUpDate:Date?` `nextReminderAt:Date?` `privacyOptOut:Bool`                                                                        | Yes                                                                         | Search facets: `storeCode`, `assignedUserId`, `followUpDate BETWEEN`, `birthdayMonth`, `anniversaryMonth`, `tags CONTAINS`, text search on composite field | Associates limited to own + store; marketing & selling agents get broader per department; sensitive PII redacted in lightweight list view. |                                                                                                       |
| ClientNote                | `clientRef:CKReference(Client)` `authorId:String` `body:String` `createdAt:Date`                                                                                                                                           | Yes                                                                         | By `clientRef`                                                                                                                                             | Inherits Client visibility.                                                                                                                |                                                                                                       |
| Appointment               | `clientRef?` `title:String` `storeCode:String` `start:Date` `end:Date` `createdBy:String` `attendeeUserIds:[String]`                                                                                                       | Yes                                                                         | Range queries by `start`                                                                                                                                   | Visible to participants + hierarchical roles.                                                                                              |                                                                                                       |
| Document                  | `title:String` `category:String` `version:Int` `storeScope:[String]?` `departmentScope:[String]?` `fileAsset:CKAsset` `updatedBy:String` `updatedAt:Date` `changeLog:String?`                                              | Yes                                                                         | Filter on `category`, `updatedAt >`                                                                                                                        | Version increments; only permitted roles upload (Admin, AreaDirector, DeptHead for own dept).                                              |                                                                                                       |
| KnowledgeArticle          | `title:String` `slug:String` \`bodyMarkdown\:CKAsset                                                                                                                                                                       | Text` `tags:[String]` `createdBy\:String` `updatedAt\:Date` `version\:Int\` | Yes                                                                                                                                                        | Indexed on `slug`, tag filters                                                                                                             | Edit roles: Admin, Agents (Marketing/Selling/Operations), AreaDirector, StoreDirector (if permitted). |
| Survey                    | `title:String` `questions:[JSON]` `isAnonymous:Bool` `targetStoreCodes:[String]?` `targetRoles:[String]?` `createdBy:String` `publishedAt:Date?`                                                                           | Yes                                                                         | Filter `publishedAt != NULL`                                                                                                                               | Submission allowed if user matches target filters.                                                                                         |                                                                                                       |
| SurveyResponse            | `surveyRef:CKReference(Survey)` `userId:String?` `submittedAt:Date` `answers:JSON`                                                                                                                                         | Yes                                                                         | Query by `surveyRef`                                                                                                                                       | If anonymous, omit `userId`. Restricted read (aggregate for non-admin).                                                                    |                                                                                                       |
| AuditTemplate             | `title:String` `sections:[JSON]` `department:String?` `createdBy:String` `version:Int`                                                                                                                                     | Yes                                                                         | Filter by `department`                                                                                                                                     | Create/edit privileged roles only.                                                                                                         |                                                                                                       |
| Audit                     | `templateRef:CKReference(AuditTemplate)` `storeCode:String` `status:String` `startedBy:String` `startedAt:Date` `finishedAt:Date?` `score:Double?` `failCount:Int` `passCount:Int` `naCount:Int`                           | Yes                                                                         | Filter by `storeCode`, date ranges                                                                                                                         | Creation allowed to roles with store access; visibility hierarchical.                                                                      |                                                                                                       |
| AuditItemResult           | `auditRef:CKReference(Audit)` `itemKey:String` `answer:String` `notes:String?` `photoAssets:[CKAsset]?`                                                                                                                    | Yes                                                                         | By `auditRef`                                                                                                                                              | As per parent.                                                                                                                             |                                                                                                       |
| TrainingCourse            | `title:String` `description:String` `mediaAssets:[CKAsset]` `scormZip:CKAsset?` `createdBy:String` `publishedAt:Date?`                                                                                                     | Yes                                                                         | Filter `publishedAt != NULL`                                                                                                                               | Edit Admin + Department Heads (Training), Agents (Training).                                                                               |                                                                                                       |
| TrainingEnrollment        | `courseRef:CKReference(TrainingCourse)` `userId:String` `progressPct:Double` `lastAccessed:Date` `completedAt:Date?` `quizScore:Double?`                                                                                   | Yes                                                                         | By `userId` or `courseRef`                                                                                                                                 | User can read own; managers aggregate by store.                                                                                            |                                                                                                       |
| VisualMerch               | `taskRef:CKReference(Task)?` `storeCode:String` `submittedBy:String` `submittedAt:Date` `photoAssets:[CKAsset]` `status:String`                                                                                            | Yes                                                                         | Filter by `storeCode`, `status`                                                                                                                            | Approvers: creator of originating task, AreaDirector, StoreDirector for own store.                                                         |                                                                                                       |
| PerformanceGoal           | `month:String(yyyy-MM)` `scope:String ('global' or storeCode)` `targets:JSON` `createdBy:String` `updatedAt:Date`                                                                                                          | Yes                                                                         | Filter by `month` and `scope`                                                                                                                              | Admin/AreaDirector set global; store overrides by AreaDirector/StoreDirector.                                                              |                                                                                                       |
| StoreReport (Daily Sales) | `storeCode:String` `date:String(yyyy-MM-dd)` `totalSales:Double` `totalTransactions:Int` `totalItems:Int` `upt:Double` `ads:Double` `ccpPct:Double` `gpPct:Double`                                                         | Yes                                                                         | Date & store range queries                                                                                                                                 | Read hierarchical; write only ingestion utility.                                                                                           |                                                                                                       |
| CreditReport              | `storeCode:String` `date:String` `totalApplications:Int`                                                                                                                                                                   | Yes                                                                         | As above                                                                                                                                                   | Same visibility as StoreReport.                                                                                                            |                                                                                                       |
| BirdeyeReport             | `storeCode:String` `weekStart:String` `reviewCount:Int`                                                                                                                                                                    | Yes                                                                         | Weekly filter                                                                                                                                              | Same visibility.                                                                                                                           |                                                                                                       |
| CrmIntakeReport           | `storeCode:String` `date:String` `totalIntakes:Int`                                                                                                                                                                        | Yes                                                                         | Date filter                                                                                                                                                | Same visibility.                                                                                                                           |                                                                                                       |
| OutboundCallReport        | `storeCode:String` `weekStart:String` `totalCalls:Int`                                                                                                                                                                     | Yes                                                                         | Weekly filter                                                                                                                                              | Same visibility.                                                                                                                           |                                                                                                       |
| VendorPerformance         | `storeCode:String?` `from:Date` `to:Date` `vendorId:String` `vendorName:String` `totalSales:Double` `totalItems:Int`                                                                                                       | Yes                                                                         | Reporting range queries                                                                                                                                    | Generated only; read-only.                                                                                                                 |                                                                                                       |
| CategoryPerformance       | `storeCode:String?` `from:Date` `to:Date` `category:String` `totalSales:Double` `totalItems:Int`                                                                                                                           | Yes                                                                         | Range queries                                                                                                                                              | Generated only.                                                                                                                            |                                                                                                       |

> *Index Guidance:* CloudKit automatically indexes most simple fields. For heavy filters (e.g., `storeCode`, `date`, `month`, `role`) ensure fields are primitive (avoid nested JSON). For tag-based search, maintain a lowercase canonical array field (`searchTerms:[String]`).

---

## Appendix B – Swift Model Layer & Mapping

**Goals:** Type safety, minimal boilerplate, diff-friendly updates, testability.

### 1. Domain Struct Pattern

```swift
struct TaskModel: Identifiable, Hashable {
    let id: CKRecord.ID
    var title: String
    var detail: String
    var dueDate: Date
    var assignedUserIds: [String]
    var isGroupCompletion: Bool
    var completedUserIds: [String]
    var createdBy: String
    var ackRequired: Bool
    var ackUserIds: [String]
}

---

## Phase 4 – New Enterprise Modules

### Document Management System (DMS)
**Timeline:** 2025-Q4 to 2026-Q1  
**Scope:** Full document lifecycle management with CloudKit private database integration

#### Core Components
- **DocumentModel.swift** - Document metadata, versioning, and access control
- **DocumentRepository.swift** - CloudKit operations for document records and CKAsset handling
- **DocumentListView.swift** - Document browser with search, filtering, and bulk operations
- **DocumentDetailView.swift** - Document viewer with annotation, sharing, and version history
- **DocumentUploadService.swift** - Multi-format upload with progress tracking and validation
- **DocumentVersioningService.swift** - Version control with diff tracking and rollback capabilities

#### Enterprise Features
- **Access Control:** Role-based permissions with department-level restrictions
- **Workflow Integration:** Document approval workflows with digital signatures
- **Compliance:** Retention policies, audit trails, and regulatory compliance reporting
- **Storage Management:** Intelligent tiering with automatic archival and compression

### Unified Permissions Framework
**Timeline:** 2025-Q4 (Foundation) 
**Scope:** Centralized authorization system replacing distributed role checks

#### Architecture
- **PermissionService.swift** - Central authorization engine with caching
- **RoleDefinitionModel.swift** - Dynamic role definitions with inheritance
- **PermissionMatrix.swift** - Action-resource mapping with context awareness
- **AdminPermissionView.swift** - Visual permission editor with inheritance visualization

#### Advanced Capabilities
- **Contextual Permissions:** Location, time, and condition-based access
- **Permission Inheritance:** Role hierarchy with override capabilities
- **Audit Integration:** Complete permission usage logging and reporting
- **Dynamic Updates:** Real-time permission changes without app restart

### Vendor & Employee Directory
**Timeline:** 2026-Q1  
**Scope:** Comprehensive personnel and vendor management system

#### Core Models
- **EmployeeModel.swift** - Extended employee profiles with organizational hierarchy
- **VendorModel.swift** - Vendor information with contract and performance tracking
- **ContactModel.swift** - Unified contact management with communication history
- **OrganizationChartModel.swift** - Dynamic organizational structure representation

#### Directory Features
- **Advanced Search:** Full-text search with faceted filtering and sorting
- **Integration Points:** Calendar, communication, and task assignment integration
- **Reporting:** Personnel analytics, vendor performance metrics, and org chart visualization
- **Compliance:** GDPR-compliant data handling with consent management

### Audits Module (Expanded)
**Timeline:** 2026-Q1  
**Scope:** Enterprise-grade audit management with advanced workflow

#### Enhanced Capabilities
- **Custom Audit Templates:** Visual template builder with conditional logic
- **Advanced Scoring:** Weighted scoring, benchmarking, and trend analysis
- **Remediation Tracking:** Action item management with escalation workflows
- **Compliance Reporting:** Automated compliance reports with regulatory templates

#### Integration Enhancements
- **Photo AI Analysis:** Automated compliance checking using CoreML
- **IoT Integration:** Sensor data integration for environmental audits
- **Third-party Connectors:** Integration with external audit platforms
- **Predictive Analytics:** ML-powered audit scheduling and risk assessment

### Performance Target Management
**Timeline:** 2026-Q1  
**Scope:** Advanced performance management with goal cascading

#### Core Features
- **Goal Cascading:** Top-down goal alignment with automatic target distribution
- **Performance Analytics:** Advanced KPI calculations with predictive modeling
- **Coaching Integration:** Performance coaching workflows with feedback loops
- **Incentive Management:** Bonus calculation and performance reward tracking

#### Advanced Analytics
- **Predictive Performance:** ML models for performance forecasting
- **Peer Benchmarking:** Comparative performance analysis across similar roles/stores
- **Performance Correlation:** Multi-variable analysis of performance drivers
- **Real-time Dashboards:** Executive dashboards with drill-down capabilities

### Project & Task Management (Enterprise)
**Timeline:** 2026-Q1  
**Scope:** Enterprise project management with resource allocation

#### Project Management
- **ProjectModel.swift** - Complex project structures with dependencies
- **ResourceAllocationService.swift** - Intelligent resource scheduling and optimization
- **ProjectDashboardView.swift** - Executive project portfolio view
- **GanttChartView.swift** - Interactive project timeline with critical path analysis

#### Advanced Task Features
- **Task Dependencies:** Complex dependency chains with automatic scheduling
- **Resource Optimization:** AI-powered resource allocation and load balancing
- **Portfolio Management:** Multi-project view with resource conflict resolution
- **Integration APIs:** External project management tool integration

#### Collaboration Enhancement
- **Real-time Collaboration:** Live document editing and comment threading
- **Video Integration:** Embedded video conferencing for project meetings
- **Workflow Automation:** Custom workflow builders with approval chains
- **External Integrations:** Slack, Teams, and external calendar synchronization

### 4.7 Calendar Module
| Purpose | In-app calendar that supports event creation, visibility, team scheduling, and integration with Office 365. |
| Entities | CalendarEvent, CalendarGroup, EventAttendee |
| Views | CalendarGridView, DayDetailView, EventModal, SharedGroupCalendar |
| Features | Create/edit/delete events, assign guests, location/time zone support, Office 365 sync. |
| Permissions | View/Manage by role and store. |
| Milestones | Schema (M4.7-a), Basic UI (M4.7-b), Office 365 Integration (M4.7-c), Alerts + Reminders (M4.7-d) |

### 4.8 Asset Management Module
| Purpose | Central inventory of digital assets (photos, PDFs, training materials, product videos). |
| Entities | Asset, AssetCategory, AssetTag, AssetUsageLog |
| Features | Upload, categorize, tag, restrict by role/store/department, track usage. |
| Views | AssetLibraryView, AssetDetailView, UploadFlow, UsageAnalyticsView |
| Integrations | CRM (for media submitted by associates or guests), DMS (for versioned documents) |

### 4.9 Workflow & Automation Builder
| Purpose | Self-service tool to define custom rules, alerts, and automated sequences across modules. |
| Example Use Cases | Auto-notify Area Director when sales fall below threshold; auto-assign follow-up task if care plan is missing; auto-export guest records weekly. |
| Core Concepts | Trigger (event), Condition (optional filter), Action (executed rule) |
| Entities | Workflow, TriggerCondition, ActionStep |
| Views | WorkflowDashboard, WorkflowBuilderCanvas, ActionLibraryModal |
| Execution Engine | On-device for UI triggers, Cloud Function backend for DB events |
| Security | Admin-only creation, role-scoped activation |

### 4.10 Office 365 Integration
| Purpose | Authenticate & sync with Microsoft accounts to pull Outlook email, Outlook calendar, and SharePoint file references. |
| Features | 
- Sign in with Microsoft (OAuth2)
- Import Outlook calendar to Diamond Desk Calendar
- Sync tasks and events to Outlook
- Index SharePoint folders for asset/document access
- Send email to Outlook from Tickets/CRM |
| Architecture | Use Microsoft Graph API; sync via background job or real-time WebHooks |
| Requirements | Per-user consent; tenant-based restrictions; fallback logic for failed connections |
| UI Elements | Office365ConnectButton, SharePointFilePicker, EmailSendDialog |
| Milestones | Auth & Token Mgmt (M4.10-a), Calendar sync (M4.10-b), SharePoint indexer (M4.10-c), Outlook outbound (M4.10-d) |

### 4.11 Custom Reports Module
**Timeline:** 2026-Q1  
**Scope:** Self-service report generation with dynamic parsing and analytics

#### Core Features
- **File Upload Engine:** Support CSV, XLSX, JSON, and custom delimited formats
- **Parser Template Library:** Python-based parsing with configurable schemas  
- **Report Builder:** Visual query builder with filters, aggregations, and joins
- **Template Management:** Save, version, and share parsing templates across teams
- **Automated Processing:** Schedule reports with email delivery and export options
- **Data Validation:** Schema validation with error reporting and data cleansing suggestions

#### Views & Components
| View | Purpose | Features |
|------|---------|----------|
| ReportUploaderView | File upload interface | Drag-drop, preview, validation, progress tracking |
| ReportBuilderView | Visual query builder | Schema mapping, filter builder, aggregation controls |
| SavedReportsDashboard | Report library | Search, categories, access control, sharing options |
| LogDetailModal | Execution history | Runtime logs, error details, performance metrics |
| ParserTemplateManager | Template authoring | Python editor, testing sandbox, version control |

#### Data Models
- **CustomReport:** Report metadata, ownership, template references, execution history
- **UploadRecord:** File processing details, version tracking, data lineage  
- **ParserTemplate:** Python logic, input/output schemas, validation rules
- **ReportLog:** Execution details, performance metrics, error tracking
- **ReportSchedule:** Automated execution configuration with delivery preferences

#### Technical Implementation
- **On-Device Python Runtime:** Pyodide or custom Swift-Python bridge for parsing
- **Cloud Function Fallback:** Complex operations offloaded to server infrastructure
- **Version Control:** Git-like versioning for templates and data transformations
- **Caching Layer:** Intelligent result caching with invalidation strategies

### 4.12 Customizable Dashboards
**Timeline:** 2026-Q1  
**Scope:** Drag-and-drop dashboard builder with multi-module data integration

#### Core Features
- **Widget Library:** 20+ pre-built widgets covering all modules (KPIs, charts, lists, calendars)
- **Drag-Drop Builder:** Intuitive interface with grid snapping and responsive layouts
- **Data Connections:** Real-time data binding with automatic refresh intervals
- **Custom Visualizations:** Chart.js integration with custom styling options
- **Role-Based Templates:** Default dashboard configurations per role and department
- **Export & Sharing:** PDF export, dashboard sharing, and presentation mode

#### Dashboard Widgets
| Widget Type | Data Source | Customization Options |
|-------------|-------------|----------------------|
| KPI Summary Cards | StoreReport, Custom Reports | Timeframe, comparison periods, target overlays |
| Sales Performance Chart | Multiple KPI sources | Chart type, date range, store filtering |
| Task Progress Tracker | Task Module | Assignment filters, completion status, due dates |
| Ticket Backlog Monitor | Ticket Module | Priority filtering, SLA tracking, assignment view |
| Training Compliance Grid | Training Module | Department filter, certification status, progress |
| Calendar Event Feed | Calendar Module | Date range, event types, attendee filtering |
| CRM Activity Stream | CRM Module | Follow-up alerts, birthday reminders, interaction log |

#### Views & Components
- **DashboardEditorView:** Main editor with widget palette and canvas
- **WidgetSelectorModal:** Categorized widget library with search and preview
- **WidgetConfigurationDialog:** Per-widget settings with live preview
- **DashboardLibraryView:** Saved dashboards with templates and sharing
- **PresentationModeView:** Full-screen dashboard display for meetings

#### Data Models
- **UserDashboard:** Layout configuration, widget instances, sharing settings
- **DashboardWidget:** Widget type, position, data configuration, styling
- **WidgetConfig:** Available widgets, default settings, permission requirements
- **DashboardTemplate:** Pre-configured dashboards per role with customization options

### 4.13 Office365 Deep Integration Enhancements
**Timeline:** 2026-Q1  
**Scope:** Comprehensive Microsoft ecosystem integration across all modules

#### Enhanced Integration Points
| Module | Office 365 Feature | Integration Details |
|--------|-------------------|-------------------|
| Calendar | Outlook Calendar Sync | Bi-directional sync, meeting integration, availability status |
| Messaging | Exchange Integration | Unified inbox, email templates, contact synchronization |
| Documents | SharePoint Integration | File browser, version control, collaborative editing |
| Tasks | Planner Integration | Task synchronization, project alignment, status updates |
| CRM | Dynamics 365 Sync | Contact integration, sales pipeline, activity tracking |
| Reports | Power BI Integration | Embedded reports, data refresh, interactive dashboards |

#### Core Features
- **Single Sign-On (SSO):** Microsoft Graph authentication with token management
- **Unified Search:** Cross-platform search across Diamond Desk and Office 365 content
- **Offline Synchronization:** Intelligent sync with conflict resolution and merge strategies
- **Permission Inheritance:** Respect Office 365 permissions within Diamond Desk interface
- **Audit Trail Integration:** Combined audit logs across both platforms

#### Views & Components
- **Office365ConnectorView:** Setup wizard with permission configuration
- **UnifiedInboxView:** Combined email and Diamond Desk messages
- **SharePointBrowserView:** Native file browser with Diamond Desk integration
- **Office365SettingsView:** Per-module integration controls and sync preferences
- **ConflictResolutionView:** Manual resolution interface for sync conflicts

#### Data Models
- **Office365Token:** Authentication tokens with automatic refresh
- **SharePointResource:** File metadata with access controls and sync status
- **OutlookIntegration:** Calendar and email sync configuration
- **MicrosoftGraphSync:** Synchronization status and error tracking
- **Office365AuditLog:** Combined audit trail for compliance reporting

### 4.14 User Interface Customization
**Timeline:** 2026-Q1  
**Scope:** Comprehensive UI personalization system with theme management

#### Core Features
- **Theme Engine:** 10 curated color schemes with light/dark mode variants
- **Icon Customization:** 15 app icon options with seasonal and branded variants
- **Navigation Builder:** Drag-drop sidebar organization with custom menu items
- **Layout Preferences:** Grid/list toggles, card sizing, information density controls
- **Typography Options:** Font size scaling, weight preferences, accessibility enhancements
- **Module Visibility:** Show/hide modules based on role and personal preferences

#### Customization Options
| Category | Options | User Control Level |
|----------|---------|-------------------|
| Color Themes | Sapphire, Emerald, Ruby, Gold, Platinum, Corporate, Minimal | Full selection |
| App Icons | Seasonal, Corporate, Minimal, Colored, Monochrome | User choice with admin approval |
| Navigation | Module order, grouping, custom shortcuts | Full customization |
| Information Density | Compact, Standard, Comfortable | Per-view preference |
| Accessibility | High contrast, reduced motion, large text | System integration |

#### Views & Components
- **ThemeCustomizerView:** Live preview with real-time application
- **AppIconSelectorView:** Icon gallery with preview and seasonal collections
- **NavigationCustomizerView:** Drag-drop interface for menu organization
- **LayoutPreferencesView:** Density controls with preview samples
- **AccessibilityOptionsView:** Enhanced accessibility controls beyond system settings

#### Data Models
- **UserPreferences:** Theme, icon, navigation, and layout preferences
- **ThemeOption:** Available themes with color definitions and assets
- **AppIconOption:** Icon variants with metadata and approval status
- **NavigationConfiguration:** Custom menu structure and visibility settings
- **LayoutPreferences:** Per-view density and display preferences

### 4.15 Cross-Module Record Linking
**Timeline:** 2026-Q1  
**Scope:** Universal record relationships with intelligent suggestions

#### Core Features
- **Universal Linking:** Connect any record type across all modules
- **Smart Suggestions:** AI-powered link recommendations based on context and history
- **Relationship Types:** Configurable relationship categories (related, dependent, conflicting)
- **Cascade Navigation:** Seamless navigation between linked records with breadcrumb trails
- **Link Analytics:** Track relationship patterns and suggest optimizations
- **Bulk Linking:** Batch operations for creating multiple relationships

#### Link Types & Use Cases
| Source Module | Target Module | Relationship Examples |
|---------------|---------------|----------------------|
| Tickets | Store Reports | Service issues affecting sales performance |
| CRM Clients | Training Records | Customer interaction training requirements |
| Audit Results | Tasks | Remediation tasks from failed audit items |
| Performance Goals | Projects | Strategic initiatives supporting goal achievement |
| Assets | Vendors | Equipment and supplier relationship tracking |
| Training | Compliance | Certification requirements and audit evidence |

#### Views & Components
- **RecordLinkModal:** Universal linking interface with search and filters
- **LinkedRecordViewer:** Related records display with relationship context
- **LinkSuggestionPanel:** AI-powered recommendations with acceptance controls
- **RelationshipMapView:** Visual representation of record connections
- **BulkLinkingView:** Batch operations interface with validation and preview

#### Data Models
- **RecordLink:** Source/target references with relationship type and metadata
- **LinkableRecord:** Universal record interface with module and type identification
- **RecordLinkRule:** Automatic linking rules based on conditions and patterns
- **LinkSuggestion:** AI-generated relationship recommendations with confidence scores
- **RelationshipType:** Configurable relationship categories with display properties

### Implementation Strategy

#### Phase 4A: Foundation (2025-Q4)
1. **Unified Permissions Framework** - Core authorization system
2. **Document Management** - Basic document storage and retrieval
3. **Enhanced Audit Templates** - Visual template builder

#### Phase 4B: Integration (2026-Q1)
1. **Vendor & Employee Directory** - Complete personnel management
2. **Performance Target Management** - Advanced performance analytics
3. **Enterprise Project Management** - Full project lifecycle management

#### Technical Requirements
- **CloudKit Private Database** - Enhanced security for enterprise data
- **CoreML Integration** - AI-powered analytics and automation
- **Advanced Caching** - Enterprise-scale performance optimization
- **Real-time Sync** - Enhanced CloudKit subscriptions for live collaboration
- **Security Hardening** - Advanced encryption and access control

#### Success Metrics
- **User Adoption:** 90% enterprise user engagement within 6 months
- **Performance:** Sub-200ms response times for all enterprise operations
- **Compliance:** 100% audit trail coverage for enterprise actions
- **Integration:** Seamless workflow between all enterprise modules

---

**End of Document**
  