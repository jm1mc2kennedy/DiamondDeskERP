# Diamond Desk – iOS CloudKit Project Blueprint
**Version:** 1.0 (Clean CloudKit Rewrite)  
**Prepared For:** Hannoush Jewelers – Retail Operations Leadership  
**Primary Stakeholder:** Executive Director Retail Operations & Development  
**Platforms (Phase 1):** iOS & iPadOS (Universal SwiftUI app)  
**Deferred:** Web / Admin Portal (future phase), macOS Catalyst (evaluate later)

---
## 1. Executive Summary
Diamond Desk centralizes mission‑critical retail operations: communications, tasks, tickets, audits, training, CRM, performance analytics, KPIs, and visual merchandising. Phase 1 delivers a production‑viable internal beta **this week** using **CloudKit** for persistence, identity, sync, push change notifications, and media storage (CKAssets). No legacy references to Firebase / Firestore remain; all authorization and data modeling align with CloudKit constraints (record type limits, indexing rules, per‑record ACL semantics, subscription quotas).

---
## 2. Architectural Overview
| Layer | Technology | Purpose |
|-------|------------|---------|
| UI | SwiftUI + Combine | Declarative reactive interface, dynamic role gating |
| State / Domain | Observable view models + async/await | Consolidate business logic, isolate CloudKit calls |
| Persistence | CloudKit (Public + Private DB) + optional Core Data mirror | Durable storage, offline caching, delta sync |
| Media | CloudKit CKAssets in dedicated record types or fields | Photos (audits, visual merch, CRM), documents, training videos (small/medium) |
| Auth / Identity | iCloud account + Sign In with Apple (for internal identity mapping) | Secure, reduces password overhead |
| Notifications | CKSubscriptions (push) | Real‑time updates (tasks assigned, tickets updated, acknowledgments) |
| Analytics (Local) | Aggregation in app + periodic background refresh | KPI rollups for dashboard |

### 2.1 CloudKit Zones Strategy
| Zone | Contents | Scope |
|------|----------|-------|
| Public Default | Reference / shared operational data (Stores, Roles, TrainingCourse metadata, KPI Goals, AuditTemplates) | Company-wide |
| Custom Public Zones (e.g. `TicketsZone`, `TasksZone`) | High‑churn operational records enabling efficient CKFetchChanges | Company-wide filtered by role/store |
| User Private DB | UserSettings, NotificationPreferences, LayoutPreferences, ephemeral drafts | Per-user |
| Shared DB (Phase 2+) | Optional document collaboration (knowledge base inline editing) | Future |

---
## 3. Roles & Permission Model (Enforced Client + Data Design)
**Roles:** Admin, AreaDirector, StoreDirector, DepartmentHead, Agent, Associate.  
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
| Capability | Admin | AreaDir | StoreDir | DeptHead | Agent | Associate |
|------------|-------|---------|----------|----------|-------|-----------|
| Manage Users (role/store/department) | ✅ | ⬜ (down-chain only) | ❌ | ❌ | ❌ | ❌ |
| Assign Stores | ✅ | ✅ (within region) | ❌ | ❌ | ❌ | ❌ |
| Create Tasks (All Stores) | ✅ | ✅ | Own Store | Dept Scope | Dept Scope | Self Only |
| Close Ticket | ✅ | ✅ | Store-scope | Dept-scope | Dept-scope | ❌ |
| View Sales KPIs (All Company) | ✅ | ✅ | Store Only | Dept (filtered) | Dept (filtered) | ❌ |
| Upload Training | ✅ | ✅ | ❌ | Dept-scope | Dept-scope | ❌ |
| Approve Marketing Content | ✅ | ✅ | ✅ | Dept-scope | Dept-scope (if Marketing/Productivity) | ❌ |

(Full extended matrix kept in separate internal appendix; can be added if required.)

---
## 4. CloudKit Data Model
Below are **primary CKRecordTypes** (prefix omitted for clarity). All date fields ISO8601 strings (or Date) with server timestamp set client‑side; maintain `updatedAt` for conflict resolution auditing.

| Record Type | Key Fields | Notes |
|-------------|-----------|-------|
| User | userId (UUID), email, displayName, role, storeCodes[], departments[], isActive, createdAt, lastLoginAt | Created at first launch after Sign In with Apple identity resolution |
| UserSettings | userRef, notificationPrefs(json), crmLayout ("tabbed"|"scroll"), darkMode, smartRemindersEnabled | Private DB |
| Store | code, name, address*, status, region, createdAt | Seeded initial list; modifiable by Admin |
| Department | code, name | Normalized list |
| Task | title, description, status, dueDate, isGroupTask (Bool), completionMode ("group"|"individual"), assignedUserRefs[], completedUserRefs[], storeCodes[], departments[], createdByRef, createdAt, requiresAck (Bool) | Completion logic differentiates group vs individual |
| TaskComment | taskRef, authorRef, body, createdAt | Lightweight; optional first release (could inline) |
| Ticket | title, description, category, status, priority, department, storeCodes[], createdByRef, assignedUserRef, watchers[], confidentialFlags[], slaOpenedAt, lastResponseAt, responseDeltas[], attachments[] (AssetRefs) | SLA analytics derived locally |
| TicketComment | ticketRef, authorRef, body, createdAt, attachments[] | Chronological display |
| Client | guestAcctNumber, guestName, partnerName, dob(s), address*, contactPreference[], accountType[], ringSizes, importantDates[], jewelryPreferences, wishList(json), purchaseHistory(json lightweight), contactHistory(json), notes, assignedUserRef, preferredStoreCode, createdByRef, createdAt, lastInteraction | Larger media (drawings) in separate `ClientMedia` |
| ClientMedia | clientRef, type (photo/drawing/doc), asset (CKAsset), uploadedByRef, createdAt | Avoids large record payloads |
| TrainingCourse | title, description, assetRefs[], scormManifests[], createdByRef, createdAt | Large videos may need external CDN in future |
| TrainingProgress | courseRef, userRef, status, score, completedAt, lastAccessedAt | Dashboard KPIs |
| Document | title, category, version, asset (CKAsset), uploadedByRef, updatedAt, versionHistory[] (json meta only) | Store diff meta only, not all binary versions |
| KnowledgeArticle | title, body(markdown), tags[], version, authorRef, updatedAt, visibilityRoles[] | Future shared editing zone |
| Survey | title, questions(json schema), isAnonymous, createdByRef, targetStoreCodes[], targetRoles[] | Distribution filters |
| SurveyResponse | surveyRef, userRef (nullable if anonymous), answers(json), submittedAt | Analytics aggregated locally |
| AuditTemplate | name, sections(json), weighting(json), createdByRef, createdAt | Template authoring gated |
| Audit | templateRef, storeCode, startedByRef, startedOn, finishedOn, status, scoreSummary(json), responses(json), photoAssets[] | Failed items may spawn Tickets |
| VisualMerchTask | taskRef (optional), storeCode, title, instructions, createdAt | Paired with uploads for approval |
| VisualMerchUpload | merchTaskRef, storeCode, submittedByRef, photoAssets[], submittedAt, approvedByRef, approvedAt, status | Approval workflow |
| PerformanceGoal | period (YYYY-MM), scope ("global"|storeCode), targets(json partial KpiGoals), createdAt, createdByRef | Merges at runtime |
| StoreReport | storeCode, date, totalSales, totalTransactions, totalItems, upt, ads, ccpPct, gpPct | Derived from Sales Audit ingestion |
| CreditReport | storeCode, date, totalApplications | Derived from file ingestion |
| BirdeyeReport | storeCode, weekStart (ISO), reviewCount | Weekly aggregate |
| CrmIntakeReport | storeCode, date, totalIntakes | Daily client intakes |
| OutboundCallReport | storeCode, weekStart, totalCalls, dailyCounts(json) | Weekly activity |
| VendorPerformance | vendorId, vendorName, periodRange, totalSales, totalItems | Aggregated query results persisted (cache) |
| CategoryPerformance | category, periodRange, totalSales, totalItems | As above |
| KPIRecord (Optional cache) | date, storeCode, metrics(json) | Speeds dashboard load |
| SalesTarget | storeCode, month, monthlyTarget, dailyTargets(json), createdByRef, updatedAt | For dashboard target comparisons |

---
## 5. Data Access Patterns & Predicates (Illustrative)
**Fetch Tasks for Current User (Active or Assigned):**  
`(assignedUserRefs CONTAINS %@) OR (storeCodes CONTAINS %@ AND %@ IN roleVisibility)`  
**Tickets Visible (Non‑Confidential):**  
`(storeCodes CONTAINS %@ AND NOT (confidentialFlags CONTAINS "HR")) OR (createdByRef == %@) OR (assignedUserRef == %@)`  
**HR Ticket (Restricted):**  
`confidentialFlags CONTAINS "HR" AND (role == "Admin" OR role == "AreaDirector" OR department CONTAINS "HR")`

Post-fetch, further prune by department list union for multi‑dept Agents.

---
## 6. Sync, Offline, Conflict Strategy
| Concern | Strategy |
|---------|----------|
| Offline Read | Core Data mirror (lightweight) keyed by recordName; last sync timestamps per type |
| Write Conflicts | Attempt modify; on CKError.serverRecordChanged merge field-by-field (prefer newest `updatedAt`), re-save |
| High-Churn Collections | Use separate zones + CKQuerySubscriptions for push deltas |
| Batch Ingestion (Reports) | Parse file locally → create/upsert records in background queue → throttle to CK rate limits |

---
## 7. File / Media Handling
| Use Case | Record Type / Field | Notes |
|----------|--------------------|-------|
| Audit Photos | Audit.photoAssets[] (Array CKAsset) | Limit size; compress JPEG before upload |
| Visual Merch Photos | VisualMerchUpload.photoAssets[] | Approval status drives retention |
| CRM Drawings / Style Cards | ClientMedia.asset | Tag type for filtering |
| Training Videos | TrainingCourse.assetRefs[] | If > 50MB repeatedly, plan Phase 2 CDN (S3 + signed URL) |

Retention policy defined later (Phase 2) for archiving large assets.

---
## 8. Notifications & Subscriptions
| Event | Subscription Type | Payload Fields |
|-------|-------------------|---------------|
| Task Assigned / Updated | CKQuerySubscription on Task (predicate includes userRef) | taskId, status, dueDate |
| Ticket Status Change | CKQuerySubscription on Ticket (assignedUserRef or storeCodes contains) | ticketId, status |
| Required Acknowledgment | CKQuerySubscription (Task.requiresAck == TRUE & assignedUserRefs CONTAINS user) | acknowledgment flag |
| Training Course Assigned | QuerySubscription on TrainingProgress (userRef) | courseId, status |
| Follow-up Reminder (CRM) | Local scheduled notification based on nextInteractionDate | clientId |

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

### 9.5 Documents & Knowledge Base
- Version history: append metadata entry to `versionHistory[]` (author, timestamp, changeSummary).  
- Non‑privileged roles see only `updatedAt` & current asset.

### 9.6 Training Modules
- Support video (CKAsset) + quiz (questions JSON).  
- Progress records create KPI signals.  
- SCORM (Phase 2+): placeholder field `scormManifests[]` for import mapping.

### 9.7 Surveys
- Schema question types: single choice, multiple choice, text, number, acknowledgment (boolean).  
- Anonymous: omit userRef and store hashed surrogate key for aggregate counts.

### 9.8 Audits
- Template-driven hierarchical sections, weighted scoring.  
- On audit completion: if `responses[].answer == Fail` and `autoCreateTicket` setting enabled → stage ticket draft for approving role (AreaDirector or template owner) with prefilled context.

### 9.9 CRM
- Comprehensive fields per prior spec.  
- Follow-up scheduling: nextInteractionDate derived from purchase anniversaries + custom reminders.  
- Smart Alerts: Anniversary in 14 days, Inactivity > 180 days, Birthday in 30 days; user can disable individually.  
- Tagging: free‑form plus controlled list (designers, style tags).  
- Filters: store, assigned user, follow-up due window, birthday month, anniversary month, interest tags, account type, contact permission.  
- Access: Associates see own + store peers (configurable), Agents limited to assigned departments (Marketing, Productivity).  

### 9.10 Visual Merch
- Tasks reference; each submission requires approval by creator or designated approver (store director / area director).  
- Revision cycle: resubmit until approved.

### 9.11 Performance Dashboard
- Aggregates WTD/MTD/YTD metrics from StoreReport + other ingestion record sets.  
- Target merge: global PerformanceGoal + optional store override.  
- Percent to target = (actual / target) - 1 displayed with color semantics (>=0 green, <0 red).  
- Quarterly Review generator consolidates 3 months + quarter totals for export (PDF Phase 2).

### 9.12 Settings Module
- Notification preferences per module (Push / In-App / Email placeholder).  
- Layout toggle for CRM detail (tab vs scroll).  
- Dark Mode toggle (leverages system but user override stored).  
- Smart reminders enable/disable.  
- Localization scaffold (English base; key-based strings file).

---
## 10. KPI & Analytics Computation
| Metric | Source | Calculation |
|--------|--------|-------------|
| totalSales | Sum(StoreReport.totalSales) | Period filter (date range) |
| avgAds | totalSales / Sum(StoreReport.totalTransactions) | Guard zero transactions |
| ccpPct | Weighted avg of (StoreReport.ccpPct * StoreReport.totalItems) / totalItems | Accuracy via item weighting |
| upt | Sum(totalItems) / Sum(totalTransactions) | — |
| gpPct | Sum(StoreReport.gpPct * totalSales) / totalSales | Weighted by sales |
| creditApps | Sum(CreditReport.totalApplications) | — |
| birdeyeReviews | Sum(BirdeyeReport.reviewCount) | Weekly aggregated roll-up |
| guestCapture | Sum(CrmIntakeReport.totalIntakes) | — |
| outboundCalls | Sum(OutboundCallReport.totalCalls) | Weekly aggregated |

Optional caching via KPIRecord to reduce recomputation overhead.

---
## 11. Ingestion Pipelines (Local Parsing → CloudKit Upsert)
| Feed | Input | Parser Notes | Dedup Key |
|------|-------|-------------|-----------|
| Sales Audit | XLSX | Extract daily store rows; map to StoreReport | storeCode+date |
| Credit Apps | XLSX | Normalize date + store code; bucket counts | storeCode+date |
| Birdeye Reviews | XLSX | Week start detection; map store code | storeCode+weekStart |
| CRM Intakes | XLSX | Company column → store code + date parse | storeCode+date |
| Outbound Calls | XLSX | Weekly log → dailyCounts aggregate | storeCode+weekStart |
| Employee Performance (Phase 2) | CSV | Salesperson metrics; project projections | employeeId+period |

Upsert Algorithm: fetch existing record by predicate; if exists update fields; else create new.

---
## 12. Security & Privacy Considerations
| Aspect | Control |
|--------|---------|
| PII (Client records) | Stored in Public DB (company internal) but access constrained by app logic; consider encryption at rest (Apple handled) + optional field-level client-side encryption for sensitive notes Phase 2 |
| HR / LP Tickets | `confidentialFlags` gating + UI redaction for unauthorized roles |
| Least Privilege | Hide creation actions for roles lacking manage rights |
| Audit Trail | Maintain arrays of (timestamp, userRef, action, diff summary) in high-value records (Tickets, Documents) |
| Data Export | Future: Signed CSV export restricted to Admin; not in Phase 1 |

---
## 13. Performance & Scaling Guardrails
| Concern | Mitigation |
|---------|-----------|
| Large Queries (KPI view) | Date-bounded predicates + local cache (KPIRecord) |
| High-Frequency Polling | Push subscriptions + background app refresh minimal fetch intervals |
| Asset Bloat | Enforce image compression (target < 500KB), limit photo count per Audit/Upload |
| Cold Start Latency | Parallel initial fetch (User, Stores, Goals) + skeleton UI placeholders |

---
## 14. Error Handling & Resilience
- **Categorization:** User (validation), Connectivity (no network), Server (CKError.*), Conflict (serverRecordChanged).  
- **Standard Retry Policy:** Exponential backoff for transient; immediate surfacing for user input errors.  
- **Offline Queue:** Persist unsent mutations (JSON file or Core Data) with ordered replay when network returns.

---
## 15. Logging & Diagnostics
- Local structured log wrapper (os_log) with categories: `sync`, `ingestion`, `ui`, `auth`.  
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
| Sprint | Duration | Primary Deliverables |
|--------|----------|----------------------|
| 0 (Today + 1) | 1–2 days | Core CK schema init scripts, User bootstrap, Store seeding, Role gating scaffolds |
| 1 | 3–4 days | Tasks (CRUD, assign, completion logic, subscriptions), Messages MVP |
| 2 | 3–4 days | Tickets (CRUD, comments, SLA timers), Basic Dashboard (WTD/MTD Sales from seeded sample) |
| 3 | 3–4 days | CRM (create, assign, filters, follow-ups), Notifications preferences |
| 4 | 3–4 days | Audits + Visual Merch Uploads + Training (upload + progress) |
| 5 (Hardening) | 2–3 days | Ingestion pipelines (Sales Audit, Credit, CRM Intakes, Reviews, Outbound Calls), KPI aggregation, polish, QA, Beta cut |

Parallel small task: Documents/Knowledge Base (read + version metadata) integrated during idle developer capacity.

---
## 19. Open Items / Assumptions
| Item | Status | Action |
|------|--------|--------|
| SCORM support | Deferred | Design manifest parser Phase 2 |
| External Office 365 integration | Deferred | Abstract CalendarService now |
| HR ticket encryption | Deferred | Evaluate per-field client encryption feasibility |
| Export / Reporting PDFs | Deferred | Introduce in Performance Review Phase 2 |
| Advanced search (full-text) | Deferred | Local index; consider Core Spotlight integration |

---
## 20. Next Steps Required from Stakeholder
1. Confirm KPI target calculation acceptance (weighted metrics) – **Pending**.  
2. Provide any store region groupings (if AreaDirector scoping uses region) – **Needed**.  
3. Approve Sprint Plan or request adjustments – **Pending**.  
4. Supply initial set of training media filenames / sizes for capacity planning – **Optional**.  
5. Clarify maximum expected weekly volume for Tickets & Tasks to validate subscription quota – **Optional**.

---
**End of CloudKit-Only Blueprint**  
No Firebase / Firestore references remain. Ready for confirmation or targeted deep dives (e.g., code templates, schema init).


