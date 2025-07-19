# Diamond Desk iOS – AI Assistance README

**Version:** 2025-07-19
**Owner:** Executive Director, Retail Operations & Development
**Purpose:** This README is the *single source of truth* the in‑app AI assistant (and developers) will reference to (a) understand platform design direction (Apple 2025 cycle), (b) implement and debug Swift / SwiftUI features efficiently, and (c) enforce consistent architectural, UX, data, and performance standards across iOS, iPadOS, macOS companion, watchOS, and future visionOS adaptations.

---

## 1. How to Use This Document (For AI Prompting & Humans)

1. **Reference Sections Precisely:** When asking the AI for help, cite the section (e.g., “Data Management > Structured Models > Error Recovery”).
2. **State Intent:** *Example:* “Need code to implement deep link from Live Activity → specific scene (see Live Activities Deep Linking section).”
3. **Provide Current State:** Include relevant ViewModel names, GraphQL entities, or Metal pipeline objects.
4. \**Ask for: (a) Implementation, (b) Optimization, (c) Debug Support, (d) UX conformance.*
5. **Return Format Expectations:** Specify if you need code-only, checklist, or diagnostic decision tree.
6. **Never Request Deprecated API Patterns:** Always conform to latest core API semantics (e.g., Metal 4 MTL4\* types; SwiftData where appropriate).

### AI Prompt Template

```
Context: <module / file / crash log excerpt>
Goal: <what success looks like>
Constraints: <performance, privacy, UX, accessibility>
Relevant README Sections: <list>
Deliverable Format: <code / steps / diff>
```

---

## 2. Core Experience Pillars (Strategic Alignment)

**Information & Communication:** Deliver timely content (notifications, Siri exposure, shared activity interactions) to sustain engagement. fileciteturn1file11L11-L20 Promote collaboration pathways (shared activities FaceTime / Messages). fileciteturn1file11L21-L24
**Extensibility:** Extend reach via app extensions (widgets, background asset downloaders, notification services, filters) executed as separate processes with defined data sharing contracts. fileciteturn1file11L25-L33
**Data Foundation:** All functionality is grounded in robust primitive and structured data representation, secure persistence, and privacy‑respectful personal data access. fileciteturn1file11L38-L46

---

## 3. Data Management Strategy

### 3.1 Standard Data Types & Processes

Use Swift standard + Foundation types (numbers, strings, dates, URLs, collections) for portability and built‑in security features. fileciteturn1file3L4-L13 Design mutability intentionally; serialize to binary when persisting. fileciteturn1file3L14-L24 Localize formatting (numbers/dates), filter/sort/compare efficiently, encrypt sensitive data (consider Keychain). fileciteturn1file3L25-L31

### 3.2 Structured Data Models

Adopt SwiftData / Core Data where predicate-based targeted fetching, undo, iCloud sync, and persistence are needed; optionally integrate SQLite for performance-critical stores. fileciteturn1file3L32-L41 Implement: (a) entity definitions aligned to GraphQL schema, (b) lightweight migrations, (c) deterministic seeding for test environments.

### 3.3 Files & Directories

Understand file-system conventions (bundles, container paths) to minimize complexity and ensure correct placement. fileciteturn1file3L43-L50 Provide capabilities for create/read/move, background download, and encryption for at-rest protection. fileciteturn1file3L52-L56

### 3.4 Shared Data & Continuity

Use iCloud Drive / key‑value / CloudKit for continuity cross-device and between app + extensions. fileciteturn1file8L33-L41 Architect data structures with sharing in mind (namespace keys, conflict resolution).

### 3.5 Personal Data & Privacy

Access personal data (contacts, photos, locations, health, environmental Vision Pro sensors) transparently; disclose usage purpose and obtain permission. fileciteturn1file8L47-L54 Support on‑device identity verification in privacy‑friendly manner. fileciteturn1file8L55-L60

### 3.6 Security & Compliance Enhancements (Elaboration)

* **Encryption:** Prefer CryptoKit for structured payloads; Keychain for tokens.
* **Data Minimization:** Persist only analytics aggregates (avoid raw PII where feasible).
* **Observability:** Attach lightweight telemetry (latency, fetch counts) to repository methods; export anonymized metrics.

### 3.7 Failure Recovery Playbook (Elaboration)

| Layer         | Symptom                         | Triage Steps                                               | AI Debug Prompt Cue                                 |
| ------------- | ------------------------------- | ---------------------------------------------------------- | --------------------------------------------------- |
| Persistence   | Fetch returns empty             | Validate predicate; inspect migration; fallback to re-sync | “Check Core Data store version & migration logs”    |
| Sync          | Inconsistent multi-device state | Inspect CloudKit zone changes                              | “List last 10 CK operations & failures”             |
| Serialization | Crash on decode                 | Validate JSON schema vs model                              | “Generate diff between expected & actual JSON keys” |

---

## 4. Liquid Glass Design System Adoption

Liquid Glass is a dynamic material layer defining modern control/navigation visual affordances, adapting to content, overlap, and focus; standard components auto-adopt when built with latest SDKs. fileciteturn1file10L8-L15 Framework standard bars, sheets, popovers adjust autonomously; minimize custom work by leveraging SwiftUI/UIKit/AppKit defaults. fileciteturn1file10L17-L22 Remove custom backgrounds (split views, tab bars, toolbars) to avoid interference with system effects. fileciteturn1file10L23-L28 Respect accessibility settings reducing transparency/motion; provide fallbacks in custom elements. fileciteturn1file10L38-L44 Avoid overuse; restrict Liquid Glass effects to high-impact elements to maintain focus. fileciteturn1file10L45-L49 Design principles emphasize layout prioritization, bold layered icons, restrained control coloration, and cross-device hardware harmony. fileciteturn1file5L3-L11 App icon layers respond dynamically to lighting/visual system effects—ensure icon grid alignment. fileciteturn1file10L51-L55

### 4.1 Implementation Checklist (Elaboration)

* Audit all navigation containers (NavigationStack, NavigationSplitView) for removed custom backgrounds.
* Run UI tests with Reduce Transparency & Reduce Motion active.
* Provide fallback opaque materials when effects disabled.
* Centralize adaptive theming in a `DesignSystem` struct with environment-based modifiers.

---

## 5. Menu Bar (macOS & iPadOS Convergence)

Provide consistent top-level menu ordering to align user expectations. fileciteturn1file14L51-L59 Include Apple menu and system-defined ordering on macOS; support expected default menus & hierarchy. fileciteturn1file14L64-L69 Maintain parity for new iPad menu bar adoption (2025 guidance). fileciteturn1file14L24-L31 Keyboard shortcuts should track macOS patterns for cognitive transfer (see HIG). fileciteturn1file14L30-L31

### 5.1 Menu Governance (Elaboration)

| Menu   | Ownership          | Inclusion Rule                  |
| ------ | ------------------ | ------------------------------- |
| App    | Core Platform Team | About, Preferences, Quit        |
| File   | Document Lifecycle | New, Open, Close, Import/Export |
| Edit   | Shared             | Undo/Redo, Cut/Copy/Paste, Find |
| View   | Feature Teams      | Toggles, Layout Modes           |
| Window | OS Integration     | Minimize, Zoom, Arrange         |
| Help   | Documentation      | Search, Knowledge Base          |

---

## 6. Live Activities Deep Linking & Launch Flows

A Live Activity tap should open a scene aligned to current activity context (fallback: system passes an `NSUserActivity`). fileciteturn1file1L13-L21 Implement deep links via `widgetURL(_:)` for Lock Screen, compact leading/trailing, minimal presentations; ensure compact views link to same destination. fileciteturn1file1L36-L43 Extended presentation may use `widgetURL(_:)` or `Link`. fileciteturn1file4L18-L24 Provide callbacks to handle default launch & activity type validation. fileciteturn1file6L13-L20 On watchOS, system surfaces Live Activity alerts; optional opt‑in enables launching Watch app from Live Activity (configure Info.plist key). fileciteturn1file14L5-L13 CarPlay launches only if app supports CarPlay. fileciteturn1file6L33-L36

### 6.1 Implementation Steps (Elaboration)

1. Define a routing enum mapping Live Activity attributes → scene identifiers.
2. Provide a universal deep link scheme (`app://live/<activityType>/<id>`).
3. In `scenePhase` handler, resolve pending Live Activity intents → navigation path.
4. Implement graceful fallback if attributes missing (show overview dashboard).
5. Add unit tests for deep link parsing & scene selection logic.

### 6.2 Accessibility & Alerts (Elaboration)

Ensure accessible descriptions for Live Activity views to assist comprehension for assistive technologies (HIG alignment).

---

## 7. App Extensions Strategy

Identify required extension types (widgets, background download, notification service, Share extension) and define secure data sharing (app group container; minimal common model). fileciteturn1file11L25-L33 Maintain extension isolation for performance & security; only expose sanitized DTOs.

---

## 8. Metal 4 Core API Migration & Performance Doctrine

Metal 4 introduces independent MTL4-prefixed types paralleling legacy MTL types—adopt incrementally per subsystem. fileciteturn1file0L16-L23 Use new command queue protocol to reduce CPU overhead and permit multi-thread command buffer submission (group commit). fileciteturn1file0L41-L49 Synchronize across old/new queues with shared events for phased adoption. fileciteturn1file0L54-L58 Core feature set additions: command queues, buffers, encoders, allocators, argument tables, texture view pools, next-gen barriers (foundation for cross-platform adaptation e.g., DirectX/Vulkan parity). fileciteturn1file5L28-L35 Detect Metal 4 support at runtime to choose appropriate queue type. fileciteturn1file5L43-L49

**Command Encoders:** Metal 4 encoders shift from per-resource binding APIs to argument table configuration. fileciteturn1file12L21-L24 Render encoder evolves—removes legacy resource binding & tessellation setup, supports residency sets & mesh shader techniques. fileciteturn1file12L27-L35 Parallel render passes achieved by suspending/resuming across command buffers (replacing parallel encoder complexity). fileciteturn1file12L43-L50 Unified compute encoder consolidates prior blit, compute, acceleration structure encoders. fileciteturn1file12L51-L56 Argument tables store resource bindings efficiently to shrink memory footprint. fileciteturn1file12L57-L60

### 8.1 Migration Playbook (Elaboration)

| Phase         | Action                                 | Success Metric                       |
| ------------- | -------------------------------------- | ------------------------------------ |
| Assessment    | Inventory existing MTL\* usage         | Map 100% of render & compute paths   |
| Pilot         | Wrap MTL4CommandQueue in adapter       | Stability + no perf regressions      |
| Gradual Shift | Move high-CPU render passes            | ≥10% CPU frame time reduction        |
| Full Adoption | Replace legacy encoders                | Unified binding logic, fewer crashes |
| Optimization  | Apply argument tables & residency sets | Reduced memory & faster binding      |

### 8.2 Debug Checklist (Elaboration)

* Validate device Metal 4 support pre-initialization.
* Ensure allocator rotation logic resets per frame (see frame allocator reset pattern). fileciteturn1file12L5-L12
* Confirm argument table population completeness before encoder submit.
* Profile GPU timelines to ensure barrier placement minimal & effective.

---

## 9. Cross-Platform UX Consistency

Adopt standard bars, sheets, popovers so Liquid Glass & dynamic adaptations apply automatically. fileciteturn1file10L17-L22 Enforce removal of conflicting backgrounds in NavigationStack / SplitView / toolbars. fileciteturn1file13L23-L28

---

## 10. Accessibility & Inclusive Design

Honor user preferences that reduce transparency/motion—provide alternative opaque themes and simplified animations. fileciteturn1file13L38-L44 Limit Liquid Glass custom usage to essential controls to avoid distraction. fileciteturn1file13L45-L49 Provide meaningful accessible descriptions in Live Activities & widgets for clarity. fileciteturn1file14L15-L19

---

## 11. Performance & Observability (Elaboration)

| Dimension           | KPI                                                | Tooling                                |
| ------------------- | -------------------------------------------------- | -------------------------------------- |
| Launch Time         | < 2.0s cold start                                  | Instruments (App Launch), unified logs |
| Memory              | No sustained > 70% of budget per device class      | Xcode Memory Graph                     |
| GPU Frame Time      | <16ms (60fps) target, <8.3ms (120fps when enabled) | Metal System Trace                     |
| I/O Latency         | Data fetch <300ms P95                              | Signposts + MetricKit                  |
| Crash-Free Sessions | > 99.5%                                            | PLC Crash Reports                      |

Apply signposts around critical render passes and sync points; correlate with argument table binding steps.

---

## 12. Quality Gates (Elaboration)

| Gate          | Criteria                                                |
| ------------- | ------------------------------------------------------- |
| PR Review     | References associated README section(s)                 |
| UI Regression | Snapshot tests across Reduce Motion/Transparency        |
| Security      | Static scan: no plaintext secrets, encryption enforced  |
| Performance   | Baseline metrics unchanged or improved                  |
| Accessibility | VoiceOver traversal complete; contrast ratios validated |

---

## 13. Common AI Support Scenarios (Elaboration)

| Scenario           | Prompt Example                                                                     |
| ------------------ | ---------------------------------------------------------------------------------- |
| Deep Link Failure  | “Given Live Activity tap not navigating; analyze routing function; see Section 6.” |
| Menu Order Drift   | “Provide diff to realign menu order with Section 5 spec.”                          |
| Metal Migration    | “Refactor legacy encoder block to MTL4RenderCommandEncoder with argument table.”   |
| Data Sync Conflict | “Outline CloudKit merge resolution strategy using Section 3.4 principles.”         |
| Icon Redesign      | “Generate layered icon proposal consistent with Liquid Glass Section 4.”           |

---

## 14. Change Management Notes

Treat this README as a living artifact; version changes require (a) semantic version bump, (b) changelog entry, (c) broadcast via internal comms channel.

---

## 15. Changelog

* **2025-07-19:** Initial consolidation of Apple 2025 design & platform guidance (Liquid Glass, Metal 4, Live Activities) and internal architectural overlays.

---

**End of Document**

---

## 8. Advanced Graphics & Performance (Metal 4 Focus)

**Objective:** Provide forward‑looking guidance for any future high‑fidelity visualization (e.g., animated KPI graphs, 3D product renders) while staying performance budget‑aware on iPad retail devices.

### 8.1 Metal 4 Argument Tables & Resource Binding

| Concept                        | Explanation                                                                                                                 | Actionable Rule                                                                                           | Common Pitfall                                                                                                           | Diagnostic Tool                                                        |
| ------------------------------ | --------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------ | ---------------------------------------------------------------------- |
| Argument Buffers / Tables      | Pack multiple resources (textures, buffers, samplers) into a single encoded structure to reduce CPU → GPU binding overhead. | Pre‑declare stable resource sets (e.g., a KPI metrics buffer + color LUT textures) in one argument table. | Rebuilding argument buffer every frame due to minor scalar change (should use small constants buffer or push constants). | Xcode GPU Frame Capture – “Encoders” pane shows redundant set\* calls. |
| Function Constants             | Compile shader code variants cheaply.                                                                                       | Use for feature toggles (e.g., enableSmoothing) instead of branching at runtime.                          | Overusing constants causing shader explosion; keep variants < 8.                                                         | Pipeline State Statistics in capture.                                  |
| Heaps                          | Explicit memory residency control for transient vs. persistent assets.                                                      | Use a single heap for small transient dynamic KPI geometry buffers; recycle.                              | Allocating separate heap per frame → fragmentation.                                                                      | Memory report (Resident Size).                                         |
| Indirect Command Buffers (ICB) | Encode draw calls GPU‑side for dynamic dashboards.                                                                          | Batch similar bar/line chart segments into one ICB updated when dataset changes.                          | Updating ICB every frame when data static.                                                                               | GPU Counters – Draw Utilization.                                       |

#### 8.1.1 Argument Buffer Layout Example

**Metal Shading Language (MSL)**

```metal
struct KPIResources {
    device float *values;            // 0
    device float *targets;           // 1
    texture2d<float> gradientLUT;    // 2
    sampler gradientSampler;         // 3
};

fragment float4 kpiBarFrag(RasterizerData in [[stage_in]],
                           constant KPIResources &res [[buffer(0)]],
                           uint vid [[vertex_id]]) {
    float v = res.values[vid];
    float t = res.targets[vid];
    float ratio = clamp(v / max(t, 0.0001), 0.0, 1.0);
    float2 uv = float2(ratio, 0.5);
    float4 color = res.gradientLUT.sample(res.gradientSampler, uv);
    return color;
}
```

**Swift Encoding Snippet**

```swift
let argEncoder = barPSO.makeArgumentEncoder(bufferIndex: 0)
let length = argEncoder.encodedLength
let argBuffer = device.makeBuffer(length: length, options: .storageModeShared)!
argEncoder.setArgumentBuffer(argBuffer, offset: 0)
argEncoder.setBuffer(valuesBuffer, offset: 0, index: 0)
argEncoder.setBuffer(targetsBuffer, offset: 0, index: 1)
argEncoder.setTexture(gradientTexture, index: 2)
argEncoder.setSamplerState(linearSampler, index: 3)
renderEncoder.setFragmentBuffer(argBuffer, offset: 0, index: 0)
```

#### 8.1.2 Performance Rules (Adopt or Justify Deviation)

1. **< 2 ms GPU per dashboard frame** on target hardware (baseline iPad).
2. **No more than 1 pipeline switch** per small chart cluster; batch bars/lines.
3. **CPU frame encoding < 3 ms**; if exceeded, profile binding overhead; adopt argument buffers.
4. **Avoid dynamic allocation during frame** (pre‑allocate buffers to max expected data points).

### 8.2 Debugging & Profiling Checklist

| Scenario             | Tool                        | Steps                                                   | Success Criteria               |
| -------------------- | --------------------------- | ------------------------------------------------------- | ------------------------------ |
| Sudden FPS drop      | Xcode GPU Frame Capture     | Capture frame, sort encoders by time.                   | Top encoder < 40% frame time.  |
| High CPU encode      | Instruments – Time Profiler | Inspect Metal API calls; measure redundant set\* calls. | < 5% total app CPU.            |
| Memory spike         | Instruments – Allocations   | Filter for MTLBuffer / MTLTexture.                      | Stable, no continuous growth.  |
| Shader compile stall | Xcode Log + `MTLCompiler`   | Pre‑warm PSOs on startup.                               | Zero runtime compile warnings. |

### 8.3 When *Not* to Use Metal

If SwiftUI Charts achieve target performance (60fps for interactions) and memory is modest (< 150MB total), avoid early complexity. Introduce Metal only for:

* Real‑time animated large datasets (> 10k points).
* 3D product spin / lighting demos.
* Custom gradient, blur, or particle overlays not feasible in Core Animation.

---

## 9. Live Activities & Deep Linking (ActivityKit)

**Use Case in Diamond Desk:** Display real‑time KPI pulse (e.g., current hour sales vs. target) on Lock Screen / Dynamic Island during manager review days.

### 9.1 Architecture

| Layer                  | Responsibility                                                                  |
| ---------------------- | ------------------------------------------------------------------------------- |
| Activity Attributes    | Immutable identity (storeCode, metricType).                                     |
| Content State          | Mutable values (currentValue, targetValue, percent, trendArrow).                |
| Server Push (Optional) | Push token updates for near real‑time (APNs).                                   |
| App Intent / URL       | Deep link from Activity/Widget to in‑app StoreDashboardView filtered to metric. |

### 9.2 Data Model

```swift
struct KPIPulseAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var current: Double
        var target: Double
        var percent: Double
        var trend: Trend
    }
    enum Trend: String, Codable, CaseIterable { case up, flat, down }
    var storeCode: String
    var metric: String   // e.g. "salesMTD"
}
```

### 9.3 Starting an Activity

```swift
let attrs = KPIPulseAttributes(storeCode: "08", metric: "salesMTD")
let state = KPIPulseAttributes.ContentState(current: 12500, target: 40000, percent: 0.3125, trend: .up)
let activity = try? Activity<KPIPulseAttributes>.request(
    attributes: attrs,
    contentState: state,
    pushType: .token // enable if server push planned
)
```

Store `activity.id` for later updates. If push tokens needed:

```swift
for await data in Activity<KPIPulseAttributes>.pushTokenUpdates {
    let tokenString = data.map { String(format: "%02x", $0) }.joined()
    // Send tokenString to backend to authorize targeted push updates
}
```

### 9.4 Updating

```swift
Task { await activity?.update(ActivityContent(state: updatedState, staleDate: .now + 300)) }
```

**Rule:** Do not update more frequently than every 15 seconds locally to preserve battery.

### 9.5 Deep Linking

Provide a `widgetURL` or `Link` with structured URL:

```
myapp://dashboard/store/08?metric=salesMTD
```

Route inside `onOpenURL` and pre‑select store & metric in `DashboardViewModel`.

### 9.6 End / Error Handling

```swift
await activity?.end(.init(state: finalState, staleDate: nil), dismissalPolicy: .immediate)
```

**Common Failure Modes & Fixes**

| Symptom              | Root Cause                                          | Resolution                                                       |
| -------------------- | --------------------------------------------------- | ---------------------------------------------------------------- |
| Activity not showing | Missing `NSActivityTypes` entitlement.              | Verify capability & target > iOS 16.1.                           |
| No updates           | Activity ended implicitly due to staleDate expired. | Extend staleDate with each update.                               |
| Deep link ignored    | URL not declared.                                   | Add custom URL scheme & handle in `SceneDelegate` / `@main` app. |

---

## 10. Liquid / Glass Effects & Accessibility Fallbacks

**Objective:** Provide modern translucent UI while respecting accessibility & performance.

### 10.1 Implementation Tiers

1. **Tier A (Full Transparency):** Use `.background(.ultraThinMaterial)` on KPI cards.
2. **Tier B (Reduced Transparency Enabled):** Replace with solid adaptive surface color + subtle border.
3. **Tier C (High Contrast):** Elevate contrast ratio minimum 4.5:1; replace gradients with flat colors.

### 10.2 Environment Detection

```swift
@Environment(\.accessibilityReduceTransparency) private var reduceTransparency
@Environment(\.accessibilityContrast) private var contrast

var cardBackground: some View {
    Group {
        if reduceTransparency { Color(uiColor: .systemBackground) }
        else { Color.clear.background(.ultraThinMaterial) }
    }
}
```

**Rule:** Never rely solely on blur for separation; always include shape, spacing, or border.

### 10.3 Performance

| Guideline                                                  | Metric                                 |
| ---------------------------------------------------------- | -------------------------------------- |
| Max simultaneous materials on iPad list view               | ≤ 12                                   |
| Offscreen render passes triggered by overlapping materials | 0 (use `compositingGroup()` sparingly) |
| GPU frame time overhead added by materials                 | < 1.5 ms                               |

### 10.4 Testing Script

* Toggle *Reduce Transparency*.\*
* Toggle *Increase Contrast*.
* Run *Color Filters* (Deuteranopia, etc.) ensuring semantic color usage (not numeric thresholds).
* Profile with *Instruments → Core Animation* (look for high “Renders with Blur”).

### 10.5 Fallback Content Strategy

If gradient conveys metric status (e.g., green → on target), also show icon + text label (▲ 92% to Target). Avoid color-only semantics.

---

## 11. Code Template Library (Swift / SwiftUI)

### 11.1 ViewModel Base (Combine + Dependency Injection)

```swift
protocol ServiceProvider { var kpiService: KPIService { get } }

class BaseViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var error: IdentifiableError?
    var cancellables = Set<AnyCancellable>()
    func runAsync(_ op: @escaping () async throws -> Void) {
        Task { @MainActor in
            isLoading = true
            do { try await op() } catch { self.error = IdentifiableError(error) }
            isLoading = false
        }
    }
}

struct IdentifiableError: Identifiable, Error { let id = UUID(); let underlying: Error }
```

### 11.2 KPI Service (GraphQL via Apollo)

```swift
protocol KPIService {
    func fetchStoreReports(storeCodes: [String], range: DateRange) async throws -> [StoreReport]
}

final class ApolloKPIService: KPIService {
    private let client: ApolloClient
    init(client: ApolloClient) { self.client = client }
    func fetchStoreReports(storeCodes: [String], range: DateRange) async throws -> [StoreReport] {
        let query = GetStoreReportsQuery(storeCodes: storeCodes, start: range.startISO, end: range.endISO)
        let result = try await client.fetchAsync(query: query, cachePolicy: .fetchIgnoringCacheData)
        return result.data?.storeReports.compactMap { $0.fragments.storeReportFragment.model } ?? []
    }
}
```

### 11.3 Reusable KPI Card

```swift
struct KPICard: View {
    let title: String; let value: String; let delta: String?; let trend: Trend
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.caption).opacity(0.7)
            Text(value).font(.title2).fontWeight(.semibold)
            if let delta { Label(delta, systemImage: trend.systemImage).font(.caption).foregroundStyle(trend.color) }
        }
        .padding()
        .background(cardBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(.white.opacity(0.08)))
    }
}
```

Helper:

```swift
enum Trend { case up, flat, down
    var systemImage: String { switch self { case .up: "arrow.up"; case .flat: "arrow.right"; case .down: "arrow.down" } }
    var color: Color { switch self { case .up: .green; case .flat: .secondary; case .down: .red } }
}
```

### 11.4 Error Boundary View

```swift
struct ErrorBoundary<Content: View>: View {
    @Binding var error: IdentifiableError?
    let retry: () -> Void
    let content: Content
    init(error: Binding<IdentifiableError?>, retry: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        _error = error; self.retry = retry; self.content = content()
    }
    var body: some View {
        ZStack {
            content
            if let err = error { VStack(spacing: 12) {
                Text("Something went wrong").font(.headline)
                Text(String(describing: err.underlying)).font(.caption).multilineTextAlignment(.center)
                Button("Retry", action: retry)
            }.padding().background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20)) }
        }
    }
}
```

### 11.5 Dependency Container

```swift
final class AppContainer: ServiceProvider {
    static let shared = AppContainer()
    let kpiService: KPIService
    private init() {
        let apollo = ApolloClient(url: URL(string: "https://api.diamonddesk.example/graphql")!)
        kpiService = ApolloKPIService(client: apollo)
    }
}
```

### 11.6 Feature Flag Wrapper

```swift
enum FeatureFlag: String { case liveActivities, metalDashboards }
struct FeatureFlags {
    static func isEnabled(_ flag: FeatureFlag) -> Bool {
        UserDefaults.standard.bool(forKey: flag.rawValue)
    }
}
```

### 11.7 Live Activity Manager

```swift
final class KPIPulseActivityManager {
    static let shared = KPIPulseActivityManager()
    private var activity: Activity<KPIPulseAttributes>? = nil
    func start(store: String, metric: String, current: Double, target: Double) {
        let attrs = KPIPulseAttributes(storeCode: store, metric: metric)
        let percent = current / max(target, 0.0001)
        let state = KPIPulseAttributes.ContentState(current: current, target: target, percent: percent, trend: .up)
        activity = try? Activity.request(attributes: attrs, contentState: state, pushType: .token)
    }
    func update(current: Double, target: Double) async {
        guard let activity else { return }
        let percent = current / max(target, 0.0001)
        let trend: KPIPulseAttributes.Trend = .up // TODO: compute delta logic
        let state = KPIPulseAttributes.ContentState(current: current, target: target, percent: percent, trend: trend)
        await activity.update(ActivityContent(state: state, staleDate: .now + 300))
    }
    func end() async { await activity?.end(nil, dismissalPolicy: .immediate); activity = nil }
}
```

---

## 12. Troubleshooting Playbooks

**Format:** *Symptom → Probable Causes → Stepwise Diagnostic → Remediation → Preventive Control.*

### 12.1 Launch / Login Loop

* **Causes:** UserDefaults flag not set; auth token expired; race between auth state listener & role fetch.
* **Diagnostics:** 1) Set breakpoint in `App.start` 2) Log `hasCompletedLogin` 3) Confirm Firebase `Auth.auth().currentUser` non‑nil 4) Trace role fetch completion.
* **Remediation:** Gate role resolution behind awaited async chain; reset flag on signOut.
* **Prevention:** Add integration test for cold launch after valid login.

### 12.2 GraphQL Fetch Failure (Network 200, Logical Error)

* **Causes:** Schema drift; enum value mismatch; auth header missing.
* **Diagnostics:** Inspect `result.errors`; enable `ApolloInterceptor` logging; compare generated fragments vs schema.
* **Remediation:** Regenerate code (`apollo codegen`), bump client cache key, validate headers.
* **Prevention:** CI job verifying schema diff before deploy.

### 12.3 Stale Data After Update

* **Causes:** Apollo normalized cache not invalidated; reused query with `.returnCacheDataDontFetch`.
* **Diagnostics:** Switch to `.fetchIgnoringCacheData`; check cache key path.
* **Remediation:** Manually `client.store.clearCache()` on major data mutation.
* **Prevention:** Define cache invalidation policy doc (append to Section 5).

### 12.4 UI Jank Scrolling Dashboard

* **Causes:** Heavy layout invalidations; synchronous decoding of large images; unnecessary `onChange` triggers.
* **Diagnostics:** Instruments → Time Profiler (look at SwiftUI Diffing & Layout); Profile with `Debug View Hierarchy` for view count.
* **Remediation:** Memoize expensive subviews; move decoding off main; limit materials.
* **Prevention:** Performance budget review for new PRs.

### 12.5 Memory Leak / Growth Over Time

* **Causes:** Retain cycles in closures; never‑ending Task; cached images not purged.
* **Diagnostics:** Instruments → Leaks; check Tasks with `Task.isCancelled` guards.
* **Remediation:** Use `[weak self]`; cancel tasks `onDisappear`; implement LRU cache.
* **Prevention:** Add static analysis rule for strong self in async closures.

### 12.6 Concurrency Race Condition

* **Symptom:** Random crash or inconsistent KPI values.
* **Causes:** Updating shared mutable arrays from multiple Tasks.
* **Diagnostics:** Enable Thread Sanitizer; add `@MainActor` to ViewModels.
* **Remediation:** Wrap shared state in an `actor`.
* **Prevention:** Concurrency checklist in PR template.

### 12.7 Live Activity Not Appearing

* **Causes:** Missing entitlement; started before user granted notification permission; unsupported OS.
* **Diagnostics:** Check `ActivityAuthorizationInfo().areActivitiesEnabled`; log errors in request.
* **Remediation:** Request permission, retry after grant.
* **Prevention:** Guard feature flag behind capability check.

### 12.8 Widget Timeline Not Refreshing

* **Causes:** `reloadTimelines` not called; outdated `Date` in `TimelineEntry`; background refresh disabled.
* **Diagnostics:** Add debug entry with `Date()` stamp; review Console for WidgetKit errors.
* **Remediation:** Schedule `Timeline` with realistic `policy: .after(nextUpdate)`.
* **Prevention:** Document max refresh frequency constraints.

### 12.9 Metal Shader Compilation Error

* **Symptom:** Red runtime error: `Function kpiBarFrag not found`.
* **Causes:** Pipeline not rebuilt after file rename; argument buffer index mismatch.
* **Diagnostics:** Log compiled function names; compare indices; run shader validation.
* **Remediation:** Recreate PSO after source change; ensure argument indices align with MSL struct.
* **Prevention:** Centralize shader index constants.

### 12.10 Excessive Battery Drain During Activity

* **Causes:** Over‑frequent Live Activity updates; continuous GPU animation.
* **Diagnostics:** Energy Log Instrument; count updates/hour.
* **Remediation:** Coalesce updates to 1 / 5 minutes for slow metrics.
* **Prevention:** Add rate limiter wrapper around update calls.

---

## 13. Expansion Backlog (For Future Iteration)

| Item                                         | Rationale                                          | Priority |
| -------------------------------------------- | -------------------------------------------------- | -------- |
| Add Apollo Cache Invalidation Policy Section | Reduce stale data incidents.                       | High     |
| Introduce Actor‑based Data Aggregator        | Eliminate race conditions.                         | Medium   |
| Metal Prototype Branch                       | Validate performance claims before broad adoption. | Medium   |
| Accessibility Audit Script                   | Automate screenshots in all modes.                 | Low      |
| Unit Test Templates Section                  | Improve coverage velocity.                         | Medium   |

---

## 14. Usage Guidance for AI Assistant

When AI is asked implementation questions related to Sections 8–13, it should:

1. Identify relevant section quickly (by numeric heading) and cite rule numbers explicitly in response.
2. If missing detail, propose addition to *Expansion Backlog* with draft spec.
3. Provide code aligned with templates (Section 11) and performance rules (8.1.2).
4. Default to **not** escalating to Metal unless Section 8.3 criteria met.
5. Enforce accessibility fallbacks (10.1 / 10.2) whenever materials used.

---

**End of Extended Sections (v1.1)**

