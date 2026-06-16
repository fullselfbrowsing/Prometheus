# Roadmap: FSB Browser

## Overview

FSB Browser starts by making the Falkon-derived browser buildable and legally understood, then replaces product-visible identity with FSB Browser, then builds the native agent control spine that makes this more than an extension port. Once the native spine exists, the roadmap restores FSB MCP compatibility, multi-agent execution, FSB runtime surfaces, PhantomStream supervision, and release packaging.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions

- [ ] **Phase 1: Baseline and Legal Inventory** - Prove the fork builds and map inherited code, identity, and license obligations.
- [ ] **Phase 2: FSB Product Identity Shell** - Rebrand primary product surfaces and establish the FSB Browser visual shell.
- [ ] **Phase 3: Native Agent Control Spine** - Add the native command router, surface adapters, JS execution, page reads, and internal settings proof.
- [ ] **Phase 4: MCP Compatibility and Multi-Agent Control** - Expose the FSB-compatible tool contract with ownership, action execution, visual sessions, and diagnostics.
- [ ] **Phase 5: FSB Runtime Parity Surfaces** - Rebuild the user-facing FSB automation experience inside the browser.
- [ ] **Phase 6: Supervision, Packaging, and Release Hardening** - Add PhantomStream-style supervision, safe pairing, release artifacts, and full validation.

## Phase Details

### Phase 1: Baseline and Legal Inventory
**Goal**: Establish a reliable browser fork baseline before rebrand or agent work.
**Depends on**: Nothing (first phase)
**Requirements**: BASE-01, BASE-02, BASE-03, BASE-04
**Success Criteria** (what must be TRUE):
  1. Developer can build and run the local browser from the workspace on the initial target platform.
  2. Browser smoke test can open a page, navigate, create a tab, and exit cleanly.
  3. Falkon/KDE/Qt identifiers, product strings, assets, packaging files, and required legal notices are inventoried.
  4. Required GPL and third-party legal notices remain present and intentionally preserved.
**Plans**: 3 plans

Plans:
- [ ] 01-01: Build and smoke baseline for the local Falkon fork.
- [ ] 01-02: Product identity and packaging inventory.
- [ ] 01-03: License/legal notice inventory and preservation checks.

### Phase 2: FSB Product Identity Shell
**Goal**: Make the primary app experience look and feel like FSB Browser without breaking the native browser build.
**Depends on**: Phase 1
**Requirements**: BRAND-01, BRAND-02, BRAND-03, BRAND-04
**Success Criteria** (what must be TRUE):
  1. User sees FSB Browser branding in app name, window title, icons, first-run/about surfaces, and main browser chrome.
  2. User does not see Falkon/KDE product branding in primary browser UI, default bookmarks, desktop/bundle metadata, or product docs.
  3. Browser UI uses the FSB dark/orange operator visual language.
  4. The browser still builds and packages after each rebrand layer.
**Plans**: 4 plans

Plans:
- [ ] 02-01: App metadata, bundle IDs, executable labels, and platform files.
- [ ] 02-02: Icons, assets, default bookmarks, first-run/about surfaces.
- [ ] 02-03: FSB dark/orange browser chrome and operator styling baseline.
- [ ] 02-04: Product docs and rebrand verification pass.

### Phase 3: Native Agent Control Spine
**Goal**: Create the browser-native control layer that can target web pages and browser-owned surfaces safely.
**Depends on**: Phase 2
**Requirements**: AGENT-01, AGENT-02, AGENT-03, AGENT-04, AGENT-05, AGENT-06, PAGE-01, PAGE-02, PAGE-03, SEC-02, SEC-03
**Success Criteria** (what must be TRUE):
  1. Agent commands route through one validated native tool router with logs and structured results.
  2. Agent can control tabs/navigation and read page text, DOM snapshots, and compact page snapshots.
  3. Agent can execute audited JavaScript on normal web pages and receive normalized results.
  4. Agent can control at least one browser-owned settings/internal surface through structured native commands.
  5. Unsafe or unsupported actions return typed errors and audit entries.
**Plans**: 5 plans

Plans:
- [ ] 03-01: Native tool router, result envelope, and audit log foundation.
- [ ] 03-02: Tab/window/navigation commands.
- [ ] 03-03: Page text, DOM snapshot, and compact page snapshot adapters.
- [ ] 03-04: Permissioned JavaScript execution with read-back verification.
- [ ] 03-05: Internal settings/native surface command proof.

### Phase 4: MCP Compatibility and Multi-Agent Control
**Goal**: Let existing FSB-style MCP clients drive the native browser with safe action execution and multi-agent isolation.
**Depends on**: Phase 3
**Requirements**: PAGE-04, PAGE-05, PAGE-06, PAGE-07, MCP-01, MCP-02, MCP-03, MCP-04, MCP-05, MCP-06, MULTI-01, MULTI-02, MULTI-03, MULTI-04, MULTI-05, SUP-01, SUP-02
**Success Criteria** (what must be TRUE):
  1. Existing MCP clients can connect and use compatible FSB manual/read tools.
  2. Agent can click, type, press keys, scroll, hover, select, clear, drag/drop, and verify changes on normal pages.
  3. Browser enforces agent identity, tab ownership, concurrency caps, reconnect recovery, and safe background-tab execution.
  4. Action tools support visual-session fields and show visible trusted-client/action state.
  5. Diagnostics identify browser, MCP, tab, page adapter, and internal adapter health.
**Plans**: 5 plans

Plans:
- [ ] 04-01: MCP server/bridge and canonical FSB tool schema adapter.
- [ ] 04-02: Manual action tools, waits, change reports, and stuck detection.
- [ ] 04-03: Read tools and diagnostics parity.
- [ ] 04-04: Multi-agent identity, ownership, cap, reconnect, and background-tab behavior.
- [ ] 04-05: Visual session compatibility and overlay/action feedback.

### Phase 5: FSB Runtime Parity Surfaces
**Goal**: Rebuild the FSB automation product experience inside the browser.
**Depends on**: Phase 4
**Requirements**: FSB-01, FSB-02, FSB-03, FSB-04, FSB-05, FSB-06, SEC-01
**Success Criteria** (what must be TRUE):
  1. User can submit natural-language browser tasks from an FSB Browser side panel or equivalent surface.
  2. User can configure supported hosted, routed, local, and custom AI providers.
  3. Browser can run autopilot tasks with progress, cancellation, final result, and failure reporting.
  4. Browser stores and displays logs, diagnostics, action history, costs, memory/site guides, and task outcomes.
  5. Vault and provider secrets use secure storage and do not cross MCP/remote transports.
**Plans**: 5 plans

Plans:
- [ ] 05-01: Agent side panel and task submission UI.
- [ ] 05-02: Provider configuration, model discovery, and secure key storage.
- [ ] 05-03: Autopilot loop, progress, cancellation, and final results.
- [ ] 05-04: Logs, diagnostics, analytics, costs, memory, and site guides.
- [ ] 05-05: Vault flows and sensitive autofill boundaries.

### Phase 6: Supervision, Packaging, and Release Hardening
**Goal**: Make the browser supervised, installable, and release-ready.
**Depends on**: Phase 5
**Requirements**: SUP-03, SUP-04, SUP-05, REL-01, REL-02, REL-03
**Success Criteria** (what must be TRUE):
  1. Browser can stream a live supervised web-page view using DOM-native snapshot/diff mirroring or equivalent PhantomStream-derived behavior.
  2. Dashboard/sync pairing is session-stamped and rejects stale snapshots, diffs, and remote-control actions.
  3. Browser produces a repeatable package/build artifact for the initial target platform.
  4. Release artifact includes required legal notices and source/license guidance.
  5. Release validation covers build, smoke, MCP compatibility, automation, internal surfaces, security, branding, and supervision.
**Plans**: 4 plans

Plans:
- [ ] 06-01: PhantomStream-style DOM mirror and supervised viewer.
- [ ] 06-02: Safe dashboard/sync pairing and remote-control session identity.
- [ ] 06-03: Initial platform packaging and legal bundle.
- [ ] 06-04: Release validation suite and final hardening.

## Progress

**Execution Order:**
Phases execute in numeric order: 1 -> 2 -> 3 -> 4 -> 5 -> 6

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Baseline and Legal Inventory | 0/3 | Not started | - |
| 2. FSB Product Identity Shell | 0/4 | Not started | - |
| 3. Native Agent Control Spine | 0/5 | Not started | - |
| 4. MCP Compatibility and Multi-Agent Control | 0/5 | Not started | - |
| 5. FSB Runtime Parity Surfaces | 0/5 | Not started | - |
| 6. Supervision, Packaging, and Release Hardening | 0/4 | Not started | - |
