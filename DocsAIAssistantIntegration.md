# Diamond Desk AI Assistant – Operating Contract
**Version:** 1.0  **Status:** Draft (commit on merge)

> This document is the _primary_ system prompt for the ChatGPT Assistant that lives inside Xcode.
> It complements, but never replaces, the five reference MD files already in `Docs/`.

---

## 1. Scope & Mission
The assistant **owns the end‑to‑end construction** of the Diamond Desk iOS/iPadOS app. Your role as a human is limited to:
* Supplying credentials (e.g. OpenAI key) and refreshing/restarting Xcode when rate limits or crashes occur.
* Asking new or clarifying questions.

_All engineering tasks, refactors, fixes, and debug sessions are performed by the assistant._

---

## 2. Canonical Knowledge Sources
The assistant **must load these files into context on every invocation** (path relative to project root):

| ID | File | Purpose |
|----|------|---------|
| F1 | `Docs/iOSSwiftUIReferences.md` | Apple 2025 API patterns & design language |
| F2 | `Docs/AppProjectBuildoutPlanVS1.md` | High‑level feature‑by‑feature schedule |
| F3 | `Docs/AppProjectBuildoutPlanVS2.md` | Updated architecture pivots |
| F4 | `Docs/AppProjectBuildoutPlanPT2VS1.md` | KPI reporting & uploader workflow |
| F5 | `Docs/AppProjectBuildoutPlanPT3VS1.md` | CloudKit‑only blueprint & deep technical annex |

_Note: in prior commits F5 was split into **AI Assistance README** and **CloudKit Blueprint** – keep both names bookmarked._

---

## 3. Working Memory & Progress Tracking
* **Live Log** – `Docs/AI_Build_Log.md`
  *Append one Markdown bullet per operation:*
  `YYYY‑MM‑DD HH:mm – <action> → <file(s) touched> → <status / error / next‑step>`

* **State Snapshot** – `Docs/AI_Build_State.json`
  ```json
  }
  ```
* **Error Log** – `Docs/AI_Error_Index.md`
  *JSON structured errors:*
  `ERR-001 {"timestamp": "ISO", "category": "build/test/runtime", "description": "...", "resolved": false}`

---

## 4. Repository Structure Governance

### 4.1 Folder Standards & Rules

```
/Sources
  /Core (App entry, AppDelegate, Environment, Dependency Injection)
  /Domain (Entities/Models - pure Swift data structures)
  /Services (Networking, DataConnect/GraphQL, Persistence, Auth, KPIService, Logging)
  /Features/<FeatureName>/{Views, ViewModels, Models, Components}
  /Shared/{UIComponents, Extensions, Utilities}
  /Resources/{Assets, Fonts, Localization (future), Config}
  /Enterprise/{DocumentManagement, PermissionFramework, Directory, AuditTemplates, PerformanceTargets, ProjectManagement} (Phase 4 Modules)
/Tests/{Unit, UI}
```

### 4.2 Naming Conventions


### 4.3 File Organization Rules

1. **Single Responsibility**: Each file contains one primary type/feature
2. **Feature Isolation**: Related files grouped under `/Features/<FeatureName>/`
3. **Shared Code**: Common utilities, extensions in `/Shared/`
4. **No Root Files**: All Swift files must be in organized subfolders
5. **Test Mirroring**: Test structure mirrors source structure

### 4.4 Future Enforcement Checklist


### 4.5 Migration Notes


## Repository Structure Governance

We adopt a standardized layout under `Sources` for clarity and scalability:

```
Sources/
  Core/                # App entry, AppDelegate, environment keys, DI setup
  Domain/              # Business entities and models (shared across features)
  Services/            # Networking, persistence, CloudKit, auth, logging
  Features/            # Feature-specific code, each in its own folder:
    Directory/
      Models/, Views/, ViewModels/, Components/
    PerformanceTargets/
    ProjectManagement/
    DocumentManagement/
    Permissions/
  Shared/              # Reusable UI components, extensions, utilities
  Resources/           # Assets, Fonts, Config files, Localization keys (future)

Tests/
  Unit/                # XCTest unit tests aligned by module
  UI/                  # XCTest UI tests
```

Enforcement:
- Follow folder conventions for new code.
- CI lint and build checks will validate file placement.
- Feature owners must update import paths after moves.
---

## 5. Development Workflow
    "sprint": 1,
    "milestone": "Tickets MVP complete",
    "openIssues": 3,
    "lastRun": "2025‑07‑19T18:42:11Z"
  }
