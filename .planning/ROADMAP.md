# Roadmap: Prometheus

## Overview

Prometheus starts by making the Falkon-derived browser buildable and legally understood, then replaces product-visible identity with Prometheus and the "Powered by FSB" affiliation, then builds the native agent control spine that makes this more than an extension port. Once the native spine exists, the roadmap restores FSB MCP compatibility, multi-agent execution, FSB runtime surfaces, PhantomStream supervision, and release packaging.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions

- [x] **Phase 1: Baseline and Legal Inventory** - Prove the fork builds and map inherited code, identity, and license obligations.
- [x] **Phase 2: Prometheus Product Identity Shell** - Rebrand primary product surfaces and establish the Prometheus visual shell, with "Powered by FSB" as the affiliation/tagline.
- [x] **Phase 3: Native Agent Control Spine** - Add the native command router, surface adapters, JS execution, page reads, and internal settings proof.
- [x] **Phase 4: MCP Compatibility and Multi-Agent Control** - Expose the FSB-compatible tool contract with ownership, action execution, visual sessions, and diagnostics.
- [x] **Phase 5: FSB Runtime Parity Surfaces** - Rebuild the user-facing FSB automation experience inside the browser.
- [x] **Phase 6: Supervision, Packaging, and Release Hardening** - Add PhantomStream-style supervision, safe pairing, release artifacts, and full validation.
- [x] **Phase 7: Compact Safari-style Browser Chrome and Advanced Tab Management** - Make Prometheus feel like a minimal native browser with compact toolbar/tab chrome, tab groups, overview, and agent-aware tab state.
- [x] **Phase 8: Native FSB-Plus Settings Side Panel and Feature Parity Matrix** - Build the four-mode side panel (FSB Agent, Explorer, Tabs, Tools) plus the FSB Control Panel operator page, settings, and parity matrix, skinned to the canonical Prometheus design. (completed 2026-06-17)
- [ ] **Phase 9: Offline Font Awesome Free Icon System and Minimal Themes** - Bundle Font Awesome icons and the Poppins/Space Mono brand fonts offline, complete the logo pass, and harden the warm minimal two-theme system.
- [ ] **Phase 10: New Tab Start Page** - Build the Prometheus start page: hero mark, omnibox with Ask FSB handoff, favorites grid, and FSB suggested automations.

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
- [x] 01-01: Build and smoke baseline for the local Falkon fork.
- [x] 01-02: Product identity and packaging inventory.
- [x] 01-03: License/legal notice inventory and preservation checks.

### Phase 2: Prometheus Product Identity Shell
**Goal**: Make the primary app experience look and feel like Prometheus, Powered by FSB, without breaking the native browser build.
**Depends on**: Phase 1
**Requirements**: BRAND-01, BRAND-02, BRAND-03, BRAND-04
**Success Criteria** (what must be TRUE):
  1. User sees Prometheus branding in app name, window title, icons, first-run/about surfaces, and main browser chrome, with "Powered by FSB" used as the affiliation/tagline where appropriate.
  2. User does not see Falkon/KDE product branding in primary browser UI, default bookmarks, desktop/bundle metadata, or product docs.
  3. Browser UI uses the FSB dark/orange operator visual language.
  4. The browser still builds and packages after each rebrand layer.
**Plans**: 4 plans

Plans:
- [x] 02-01: App metadata, bundle IDs, executable labels, and platform files.
- [x] 02-02: Icons, assets, default bookmarks, first-run/about surfaces.
- [x] 02-03: FSB dark/orange browser chrome and operator styling baseline.
- [x] 02-04: Product docs and rebrand verification pass.

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
- [x] 03-01: Native tool router, result envelope, and audit log foundation.
- [x] 03-02: Tab/window/navigation commands.
- [x] 03-03: Page text, DOM snapshot, and compact page snapshot adapters.
- [x] 03-04: Permissioned JavaScript execution with read-back verification.
- [x] 03-05: Internal settings/native surface command proof.

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
- [x] 04-01: MCP server/bridge and canonical FSB tool schema adapter.
- [x] 04-02: Manual action tools, waits, change reports, and stuck detection.
- [x] 04-03: Read tools and diagnostics parity.
- [x] 04-04: Multi-agent identity, ownership, cap, reconnect, and background-tab behavior.
- [x] 04-05: Visual session compatibility and overlay/action feedback.

### Phase 5: FSB Runtime Parity Surfaces
**Goal**: Rebuild the FSB automation product experience inside the browser.
**Depends on**: Phase 4
**Requirements**: FSB-01, FSB-02, FSB-03, FSB-04, FSB-05, FSB-06, SEC-01
**Success Criteria** (what must be TRUE):
  1. User can submit natural-language browser tasks from a Prometheus side panel or equivalent surface.
  2. User can configure supported hosted, routed, local, and custom AI providers.
  3. Browser can run autopilot tasks with progress, cancellation, final result, and failure reporting.
  4. Browser stores and displays logs, diagnostics, action history, costs, memory/site guides, and task outcomes.
  5. Vault and provider secrets use secure storage and do not cross MCP/remote transports.
**Plans**: 5 plans

Plans:
- [x] 05-01: Agent side panel and task submission UI.
- [x] 05-02: Provider configuration, model discovery, and secure key storage.
- [x] 05-03: Autopilot loop, progress, cancellation, and final results.
- [x] 05-04: Logs, diagnostics, analytics, costs, memory, and site guides.
- [x] 05-05: Vault flows and sensitive autofill boundaries.

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
- [x] 06-01: PhantomStream-style DOM mirror and supervised viewer.
- [x] 06-02: Safe dashboard/sync pairing and remote-control session identity.
- [x] 06-03: Initial platform packaging and legal bundle.
- [x] 06-04: Release validation suite and final hardening.

### Phase 7: Compact Safari-style Browser Chrome and Advanced Tab Management
**Goal**: Make Prometheus use a minimal compact browser chrome inspired by Safari's compact layout while preserving agent visibility and power-user tab workflows.
**Depends on**: Phase 6
**Requirements**: UX-01, UX-02, UX-03, UX-04, UX-05, UX-06
**Success Criteria** (what must be TRUE):
  1. Compact mode moves tabs into the toolbar, with the active tab acting as the unified address/search field.
  2. Users can switch compact/separate layouts and keep titles or favicon-only tab display without layout instability.
  3. Tab groups, tab overview/search, reorder, close/restore, unload, duplicate, detach, and quick-switch flows work from native UI.
  4. Agent ownership, active automation, supervision, and tab health remain visible in compact chrome without visual clutter.
  5. Keyboard shortcuts and mouse/trackpad interactions remain Mac-native and compatible with existing Falkon tab behavior.
  6. Visual verification confirms compact chrome is minimal, readable, non-overlapping, and stable across narrow and wide windows.
**Plans**: 10 plans

Plans:
- [x] 07-01-PLAN.md — Persist compact/separate layout and title/favicon tab display settings.
- [x] 07-02-PLAN.md — Expose agent-aware tab state through native reads and TabModel roles.
- [x] 07-03-PLAN.md — Build the compact tab strip, filter model, and delegate primitives.
- [x] 07-04-PLAN.md — Integrate compact chrome into NavigationBar and preserve separate layout.
- [x] 07-05-PLAN.md — Build the tab overview, search, and quick-switch popup foundation.
- [x] 07-06-PLAN.md — Wire tab overview/search/quick-switch into chrome and menus.
- [x] 07-07-PLAN.md — Add persistent native tab group metadata and model roles.
- [x] 07-08-PLAN.md — Complete group actions, advanced tab operations, and MCP/native tab reads.
- [x] 07-09-PLAN.md — Wire native tab group roles into compact chrome and grouped overview/search.
- [x] 07-10-PLAN.md — Add compact-tab smoke validation and visual verification checkpoint.

### Phase 8: Native FSB-Plus Settings Side Panel and Feature Parity Matrix
**Goal**: Build the four-mode Prometheus side panel (FSB Agent, Explorer, Tabs, Tools) as the fast everyday surface and the dense FSB Control Panel page as the operator center, both skinned to the canonical Prometheus design, with settings and a verified parity matrix against FSB.
**Depends on**: Phase 7
**Requirements**: FSBP-01, FSBP-02, FSBP-03, FSBP-04, FSBP-05, FSBP-06
**Design reference**: `.planning/design/DESIGN-REFERENCE.md` (side panel four modes, control panel split, warm tokens)
**Success Criteria** (what must be TRUE):
  1. The native side panel provides the four modes (FSB Agent, Explorer, Tabs, Tools) per the canonical design, while the dense operator control center (tasks, providers, model discovery/fallbacks, MCP, permissions, vault, memory, site guides, logs, diagnostics, supervision, pairing) lives on the FSB Control Panel page.
  2. The FSB Agent mode and control panel can run real provider-backed tasks when configured, while preserving local/offline and MCP-driven workflows.
  3. Every FSB feature category is represented in a maintained parity matrix with native status, improvement target, and validation command.
  4. Settings for internal-surface permissions, agent caps, tab ownership, visual feedback, telemetry, and vault boundaries are visible and auditable on the control panel.
  5. Prometheus improves on FSB where native browser ownership helps: settings/internal page control, lower-latency tool routing, safer secrets, and richer tab/session state.
  6. The side panel, control panel, and settings adopt the canonical Prometheus design system (warm dark and light tokens, Poppins plus Space Mono, FSB orange accent) per the design reference.
  7. Verification exercises the four-mode side panel, the control panel sections, MCP bridge, browser-owned settings, provider config, memory/site guides, vault, diagnostics, and release validation.
**Plans**: 0 plans

Plans:
- [ ] TBD (run /gsd-plan-phase 8 to break down)

### Phase 9: Offline Font Awesome Free Icon System and Minimal Themes
**Goal**: Bundle a free offline Font Awesome icon system and the Poppins and Space Mono brand fonts, complete the logo pass to the real Prometheus mark and wordmark, and reduce Prometheus themes to the canonical warm minimal aesthetic (dark and light token sets).
**Depends on**: Phase 8
**Requirements**: ICON-01, ICON-02, ICON-03, ICON-04, THEME-01, THEME-02, THEME-03, FONT-01, LOGO-01
**Design reference**: `.planning/design/DESIGN-REFERENCE.md` (typography, logo and brand mark, palette, theme tokens)
**Success Criteria** (what must be TRUE):
  1. A curated Font Awesome Free icon subset is bundled in Qt resources with license/attribution preserved and no network dependency.
  2. Prometheus has a central native icon resolver that maps browser, agent, MCP, provider, vault, diagnostics, and tab-management actions to bundled SVG icons.
  3. Existing `QIcon::fromTheme` call sites used by primary UI have deterministic Prometheus fallbacks.
  4. The Poppins (display) and Space Mono (mono) brand fonts are bundled offline as Qt resources with license/attribution and no network font loading.
  5. The logo pass wires the real Prometheus PM mark and the "Prometheus" / "Powered by FSB" wordmark per the brand sheet across app icon, side panel header, start page, and about/first-run surfaces, retiring placeholder marks with correct clear-space and minimum-size behavior.
  6. Minimal themes implement the canonical warm dark and warm light token sets (and the accent recolor option) as pure token swaps, removing heavy inherited chrome while preserving focus, hover, active, disabled, warning, and supervised-action states.
  7. Release packaging includes icon/font/theme assets and Font Awesome plus brand font license metadata.
  8. Visual/resource validation fails if required icons or fonts are missing, remote-loaded, illegible, or inconsistent across light/dark/minimal modes.
**Plans**: 6 plans

Plans:
- [x] 09-01-PLAN.md — FA SVG resource subset (70 glyphs) + fonts.qrc + font TTF asset layout.
- [x] 09-02-PLAN.md — PromethusFontLoader C++ class and MainApplication startup hook.
- [x] 09-03-PLAN.md — PrometheusIconResolver service with 70+ action map and 3-step fallback.
- [ ] 09-04-PLAN.md — Prometheus warm dark + light + common QSS theme files and runtime switch.
- [ ] 09-05-PLAN.md — PrometheusMarkWidget (two-weight PM mark) and primary call site migration.
- [ ] 09-06-PLAN.md — FSB asset bundle, about/first-run logo wiring, ICON-04 gate, and visual approval.

### Phase 10: New Tab Start Page
**Goal**: Build the Prometheus New Tab start page — hero PM mark, omnibox with an Ask FSB handoff, favorites grid, and FSB suggested automations — skinned to the canonical Prometheus design.
**Depends on**: Phase 8, Phase 9
**Requirements**: START-01, START-02, START-03, START-04, START-05
**Design reference**: `.planning/design/DESIGN-REFERENCE.md` (start page) and `.planning/design/prometheus-browser/prometheus/StartPage.jsx`
**Success Criteria** (what must be TRUE):
  1. Opening a New Tab shows the Prometheus start page with the hero PM mark, the Prometheus wordmark, and an omnibox.
  2. The omnibox accepts a search or address, and an Ask FSB action hands a natural-language prompt to the FSB Agent side panel.
  3. The start page shows a favorites grid that navigates to the chosen entry on click.
  4. The start page shows FSB suggested automations that seed the agent panel when chosen.
  5. The start page uses the canonical Prometheus design system (warm tokens, Poppins, Space Mono, Font Awesome) and renders correctly in both themes.
**Plans**: 0 plans

Plans:
- [ ] TBD (run /gsd-plan-phase 10 to break down)

## Progress

**Execution Order:**
Phases execute in numeric order: 1 -> 2 -> 3 -> 4 -> 5 -> 6 -> 7 -> 8 -> 9 -> 10

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Baseline and Legal Inventory | 3/3 | Complete | 2026-06-16 |
| 2. Prometheus Product Identity Shell | 4/4 | Complete | 2026-06-16 |
| 3. Native Agent Control Spine | 5/5 | Complete | 2026-06-16 |
| 4. MCP Compatibility and Multi-Agent Control | 5/5 | Complete | 2026-06-16 |
| 5. FSB Runtime Parity Surfaces | 5/5 | Complete | 2026-06-16 |
| 6. Supervision, Packaging, and Release Hardening | 4/4 | Complete | 2026-06-16 |
| 7. Compact Safari-style Browser Chrome and Advanced Tab Management | 10/10 | Complete | 2026-06-16 |
| 8. Native FSB-Plus Settings Side Panel and Feature Parity Matrix | 5/5 | Complete   | 2026-06-17 |
| 9. Offline Font Awesome Free Icon System and Minimal Themes | 0/6 | In progress | - |
| 10. New Tab Start Page | 0/0 | Not planned | - |
