---
gsd_state_version: 1.0
milestone: v2.0
milestone_name: - Linux and Windows Chromium-based builds after macOS-first validation.
status: executing
stopped_at: Phase 17 Plan 17-05 completed
last_updated: "2026-07-07T09:22:47Z"
last_activity: 2026-07-07 -- Completed Phase 17 Plan 17-05
progress:
  total_phases: 15
  completed_phases: 6
  total_plans: 37
  completed_plans: 36
  percent: 97
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-06-23)

**Core value:** Agents get fast, precise, auditable control of the whole browser through DOM/native structure, not screenshots, brittle extension injection, or human-only UI.
**Current focus:** Phase 17 — native-agent-command-service-and-tab-ownership

## Current Position

Phase: 17 (native-agent-command-service-and-tab-ownership) — EXECUTING
Plan: 6 of 6
Status: Executing Phase 17
Last activity: 2026-07-07 -- Completed Phase 17 Plan 17-05

## Performance Metrics

**Velocity:**

- Total plans completed: 70
- Average duration: 7min
- Total execution time: 0.3 hours

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 07 | 10 | 87min | 9min |
| 08 | 5 | - | - |
| 09 | 6 | - | - |
| 10 | 4 | - | - |
| 11 | 3 | - | - |
| 12 | 4 | - | - |
| 13 | 4 | - | - |
| 14 | 8 | - | - |

**Recent Trend:**

- Last 5 plans: 07-06 through 07-10 completed, including review fixes and visual approval
- Trend: Phase 07 completed after verification, code review, and UI audit gates

*Updated after each plan completion*

**Recent Plan Metrics:**

| Plan | Duration | Tasks | Files |
|------|----------|-------|-------|
| Phase 07 P02 | 9min | 2 tasks | 10 files |
| Phase 07 P03 | 8min | 2 tasks | 7 files |
| Phase 07 P04 | 5 min | 2 tasks | 5 files |
| Phase 07 P05 | 8min | 2 tasks | 8 files |
| Phase 07 P06 | 7min | 2 tasks | 7 files |
| Phase 07 P07 | 14min | 2 tasks | 10 files |
| Phase 07 P08 | 12min | 2 tasks | 10 files |
| Phase 07 P09 | 9min | 2 tasks | 10 files |
| Phase 07 P10 | 6min | 3 tasks | 4 files |
| Phase 08 P02 | 5min | 2 tasks | 6 files |
| Phase 08 P03 | 3min | 2 tasks | 2 files |
| Phase 08 P04 | 8min | 2 tasks | 2 files |
| Phase 08 P05 | 12min | 1 tasks | 4 files |
| Phase 09 P01 | 3 | 2 tasks | 78 files |
| Phase 09 P02 | 2min | 1 tasks | 4 files |
| Phase 09 P03 | 8min | 1 tasks | 3 files |
| Phase 09 P04 | 5min | 2 tasks | 10 files |
| Phase 09 P05 | 4min | 2 tasks | 7 files |
| Phase 09 P06 | 5min | 3 tasks | 6 files |
| Phase 10 P01 | 3min | 2 tasks | 5 files |
| Phase 10 P03 | 15min | 2 tasks | 6 files |
| Phase 10 P04 | 3min | 2 tasks | 0 files |
| Phase 11-preservation-contract-and-falkon-freeze P01 | 3min | 2 tasks | 2 files |
| Phase 11-preservation-contract-and-falkon-freeze P02 | 4min | 2 tasks | 2 files |
| Phase 11-preservation-contract-and-falkon-freeze P03 | 6min | 2 tasks | 6 files |
| Phase 12 P12-02 | 1min | 1 tasks | 1 files |
| Phase 12-chromium-checkout-build-and-patch-discipline P12-03 | 7min | 1 tasks | 1 files |
| Phase 12-chromium-checkout-build-and-patch-discipline P12-04 | 10min | 2 tasks | 2 files |
| Phase 13 P01 | 3min | 2 tasks | 2 files |
| Phase 13-product-identity-branding-and-legal-baseline P13-02 | 2min | 2 tasks | 4 files |
| Phase 13 P03 | 6min | 2 tasks | 3 files |
| Phase 14 P02 | 15min | 2 tasks | 3 files |
| Phase 14 P14-04 | 35 | 3 tasks | 38 files |
| Phase 14 P14-03 | 20min | 1 tasks | 3 files |
| Phase 14 P14-05 | 510min | 4 tasks | 150 files |
| Phase 14 P14-06 | 55min | 2 tasks | 8 files |
| Phase 14 P07 | 43min | 2 tasks | 12 files |
| Phase 14 P08 | 79min | 2 tasks | 21 files |
| Phase 15 P01 | 11min | 2 tasks | 6 files |
| Phase 15 P02 | 16min | 2 tasks | 6 files |
| Phase 15 P03 | 17min | 2 tasks | 8 files |
| Phase 15 P04 | 8min | 2 tasks | 7 files |
| Phase 15 P05 | 10min | 2 tasks | 5 files |
| Phase 15 P06 | 12min | 2 tasks | 14 files |
| Phase 16 P01 | 18min | 2 tasks | 14 files |
| Phase 16 P02 | 22min | 2 tasks | 15 files |
| Phase 16 P03 | 15min | 2 tasks | 7 files |
| Phase 16 P04 | 6min | 2 tasks | 4 files |
| Phase 16 P05 | 13min | 2 tasks | 7 files |
| Phase 16 P06 | 6min | 2 tasks | 15 files |

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- User steer: Product name is Prometheus; affiliation/tagline is "Powered by FSB".
- Initialization: Start from local Falkon/QtWebEngine fork.
- Initialization: Rebrand product-visible identity while preserving required legal notices.
- Initialization: Prioritize native agent control and MCP compatibility before full FSB runtime parity.
- Phase 5: Use a native Prometheus sidebar and `AgentRuntime` for task, provider, log, memory/site-guide, and vault surfaces.
- Phase 6: Use session-stamped DOM-native supervision tools and a local macOS validation package with legal/source bundle.
- Milestone extension: Use Safari compact mode as a reference for space-saving chrome, not as a visual clone.
- Milestone extension: Require an explicit FSB feature parity matrix before claiming "FSB but better".
- Milestone extension: Use a curated offline Font Awesome Free icon subset with attribution preserved and no network dependency.
- [Phase 07]: Use enum-backed QzSettings helpers as the canonical mapping between stored strings and runtime tab chrome settings.
- [Phase 07]: Keep Separate and TitleAndIcon as compatible defaults while presenting native Preferences labels exactly as specified.
- [Phase 07]: Expose tab chrome state as a router-owned whitelist instead of exposing request params or router internals.
- [Phase 07]: Use MainApplication::agentCommandRouter() as the native UI access path so TabModel does not own agent state.
- [Phase 07]: Return safe model defaults when the router is unavailable: empty owner, false automation/supervision, and health ok.
- [Phase 07]: Use a proxy/delegate/list-view primitive instead of moving the existing ComboTabBar into the navigation row.
- [Phase 07]: Route compact tab switching, close requests, context menus, and drag/drop through existing WebTab, TabWidget, TabContextMenu, and TabModel behavior.
- [Phase 07]: Partially stage CMake registration hunks for the Task 2 commit so unrelated pre-existing CMake changes remain uncommitted.
- [Phase 07]: Use a fixed compact NavigationBar row from qzSettings->tabLayout while preserving saved NavigationBar/Layout and ShowSearchBar behavior for Separate.
- [Phase 07]: Hide the conventional tab row with TabBar::setForceHidden() instead of moving tab ownership or LocationBar synchronization out of TabWidget.
- [Phase 07]: Use a QSortFilterProxyModel over either BrowserWindow::tabModel() or BrowserWindow::tabMruModel() so overview/search and quick switch share rendering without changing source order.
- [Phase 07]: Render only existing title, favicon, URL/domain, and sanitized TabModel state roles in the privileged popup.
- [Phase 07]: Keep the group filter as a hidden populated control slot until Plan 07-07 adds real group roles.
- [Phase 07]: Use BrowserWindow-owned one-shot TabSearchPopup instances with delete-on-close instead of long-lived shared popup state.
- [Phase 07]: Expose quick switch through a native File menu action with unused Ctrl+Shift+A metadata while preserving existing tab and location shortcuts.
- [Phase 07]: Place Tab Overview and Search Tabs after the active address/search field so compact tab overflow cannot hide Search Tabs.
- [Phase 07]: Expose group state through TabModel roles backed by TabGroupModel instead of extension pseudo-tabs.
- [Phase 07]: Store group membership on each WebTab through prometheusTabGroupId sessionData and keep group labels/colors/collapsed state in BrowserWindow TabGroups UI state.
- [Phase 07]: Normalize restored group IDs, labels, and colors before applying persisted session data.
- [Phase 07]: Keep group mutation MCP/native tool names as typed compatibility errors while exposing group state through list_tabs.
- [Phase 07]: Use disabled state rows and confirmation-body summaries to show owner/supervision state before destructive or group-moving UI actions.
- [Phase 07]: Leave group registry metadata intact when closing a group so Recently Closed Tabs can restore group membership.
- [Phase 07]: Use active tab, then TabMruModel, then source order as the representative precedence for collapsed groups.
- [Phase 07]: Use an internal ungrouped filter sentinel while keeping user-facing copy as Ungrouped.
- [Phase 07]: Group only Tab Overview into section order; Search Tabs and quick switch preserve source/MRU ordering semantics.
- [Phase 07]: Require health-issued bearer authorization for native agent commands and bind tab ownership to authenticated sessions, not caller-controlled client labels.
- [Phase 07]: Key agent tab ownership, supervision, and chrome state by stable tab IDs instead of mutable tab indices.
- [Phase ?]: FsbControlPanelPage uses QWidget with floating Window flags; routeForSession(request, control_panel) is the internal surface session key for native policy calls
- [Phase ?]: [09-01] arrow-down-to-line substituted with arrow-down: FA Free 6.x solid missing this glyph
- [Phase ?]: [09-01] sidebar-flip placeholder SVG created: Pro-only icon not in FA Free 6.x; minimal valid SVG with two-panel geometry and CC BY 4.0 attribution
- [Phase ?]: [09-01] 69 glyphs vendored offline (plan prose said 70 but enumerated list has 69 unique names)
- [Phase ?]: PrometheusMarkWidget: use qzcommon.h not falkon_defs.h for FALKON_EXPORT
- [Phase ?]: New FA SVGs appended after sidebar-flip.svg inside existing CC BY 4.0 block — no per-entry attribution comment needed
- [Phase ?]: TabWidget new-tab default uses settings.value() fallback only; explicit user newTabUrl settings are untouched
- [Phase ?]: SideBarManager is in sidebar.h; BrowserWindow obtained from WebPage via TabbedWebView cast
- [Phase ?]: Human-verify checkpoint auto-approved under auto-mode; 26 visual checks deferred to final binary run
- [Milestone v2.0]: Falkon/QtWebEngine is no longer the production base. Preserve it as a recoverable reference, then migrate to Chromium.
- [Milestone v2.0]: The active Falkon checkout is nested, clean, and preserved at `b0521c9d37e7545c680b78dfcc24f777a984091c`; bundle path `.context/falkon-preservation/falkon-prometheus-v1.bundle`; patch series `.context/falkon-preservation/patches/`.
- [Milestone v2.0]: Preserve product/design/behavior contracts, not GPL Falkon implementation code, unless license review explicitly permits copying.
- [Milestone v2.0]: Chromium implementation should use browser-process services, WebContents/RenderFrameHost/page adapters, WebUI, Views, resource packs, and extension-system policy rather than Qt/QWebChannel/QSS/Falkon plugin APIs.
- [Milestone v2.0]: Active `falkon/` checkout was removed after bundle restore verification. Root git status is clean after removal.
- [Milestone v2.0]: depot_tools installed at `.context/depot_tools` (revision at build time `ea253a3e3ae7653cafd343be001dc5cbe69b3ad0`); Chromium fetched at `.context/chromium/src` (revision `0e8499df5172f55d0d29e2b92ef7e6a704529578`).
- [Milestone v2.0]: The local Xcode blocker is resolved. Active developer directory is `/Applications/Xcode.app/Contents/Developer`; `xcodebuild -version` reports Xcode 26.5 build 17F42.
- [Milestone v2.0]: The Metal Toolchain blocker is resolved with `xcodebuild -runFirstLaunch` and `xcodebuild -downloadComponent MetalToolchain`; `xcrun metal -v` now succeeds.
- [Milestone v2.0]: GN generation for `.context/chromium/src/out/Default` succeeds with `is_debug=false is_component_build=true symbol_level=0`.
- [Milestone v2.0]: First Chromium `chrome` build finished successfully with status file `.context/chromium-build-screen.status` reporting `0`; GN args locked as `is_debug=false is_component_build=true symbol_level=0`.
- [Phase 12]: Unmodified Chromium launch verification passed before Prometheus patches begin. Normal launch attempted first. Evidence: `.context/chromium-launch.status` records `status=0`, `workaround_used=false`, `patches_blocked=false`, Chromium revision `0e8499df5172f55d0d29e2b92ef7e6a704529578`, depot_tools revision at build time `ea253a3e3ae7653cafd343be001dc5cbe69b3ad0`, GN args `is_debug=false is_component_build=true symbol_level=0`. Full launch log at `.context/chromium-launch.log`.
- [Phase 12]: Artifact isolation verified: `.planning/chromium/verify-artifact-isolation.sh` exits 0; tracked `.gitignore` policy covers all Chromium checkout, build, and launch artifacts.
- [Phase 12]: Patch discipline documented in `.planning/chromium/CHROMIUM-CHECKOUT.md`: future Chromium source edits happen inside `.context/chromium/src` on named branches (`git new-branch prometheus/phase-13-branding`); patches exported with `git format-patch` from pinned baseline; root repo stores docs, scripts, evidence, and patch guidance only.
- [Phase 11]: Preservation verification must prove bundle integrity, expected refs, patch count 81, temporary restore, and root git ignore coverage.
- [Phase 11]: Falkon GPL implementation, Qt/QSS/package metadata, and copied GPL text remain reference-only or license-review-required for Chromium migration.
- [Phase 11-preservation-contract-and-falkon-freeze]: Use the canonical dossier's Capability Migration Map as the source-of-truth linking v1 behavior contracts to Chromium owner phases, parity evidence, and license status.
- [Phase 11-preservation-contract-and-falkon-freeze]: Preservation verification now enforces required migration-map rows, columns, license labels, and Chromium owner phases before later Chromium work proceeds.
- [Phase 11-preservation-contract-and-falkon-freeze]: Phase 11 completed the deferred visual ledger, source-freeze checklist, and stale-doc verification gate before Phase 12 launch validation.
- [Phase 11-preservation-contract-and-falkon-freeze]: No active screen session was present during Phase 11 research; .context/chromium-build-screen.status was 0; .context/chromium-build-screen.log ended with a successful Chromium build message.
- [Phase 11-preservation-contract-and-falkon-freeze]: Carry all 26 deferred Phase 08, 09, and 10 human visual checks forward as Chromium-owned checks instead of marking any complete or retiring them prematurely.
- [Phase 11-preservation-contract-and-falkon-freeze]: Treat the first Chromium build as completed with exit status 0 while keeping unmodified launch verification in Phase 12 scope.
- [Phase 11-preservation-contract-and-falkon-freeze]: Use the preservation verifier as the gate for visual-ledger count, freeze-status vocabulary, and stale active-Falkon/build wording.
- [Phase ?]: build-chromium-baseline.sh: --no-op-ok runs same GN+autoninja as no-arg; status file written before fail-on-nonzero
- [Phase ?]: [Phase 13-01]: GPL guard scans only chrome/browser/prometheus and components/prometheus to avoid false positives from unrelated Chromium third-party code
- [Phase ?]: [Phase 13-01]: smoke-launch-prometheus.sh is a new sibling; smoke-launch-unmodified.sh preserved unchanged as immutable baseline reference
- [Phase ?]: Moved swatch constants from .cc anonymous namespace to .h header for test accessibility
- [Phase 14-05]: Actual FA glyph count is 72 (not 69 as plan stated); Falkon v1 bundle has 72 SVG files; used 72 as authoritative count throughout
- [Phase 14-05]: source_set wrapper required over aggregate_vector_icons due to hardcoded visibility=[":*"] in GN template
- [Phase 14-05]: Prometheus-specific vector_icons.cc/h.template needed to avoid -Wunused-const-variable from wrong-module header include
- [Phase 14-05]: PrometheusAction enum uses kArrowDownToLine (not kDownload); resolves to arrow-down substitution glyph per D-08
- [Phase 14-06]: grit() targets with output_dir=$root_gen_dir/chrome need #include "chrome/grit/<name>.h" (chrome/ prefix), not bare "grit/<name>.h" — Chromium's include search root is $root_gen_dir
- [Phase 14-06]: test() targets constructing ui::ResourceBundle must link //base/test:run_all_unittests, not bare //testing/gtest:gtest_main, or ResourceBundle's ctor DCHECK-crashes on uninitialized base::CommandLine
- [Phase 14-06]: resource_ids.spec entries for chrome/browser/resources/*.grd files belong in the chrome/browser section, not components/
- [Phase 14-06]: IDR_PROMETHEUS_ASSET_PM_WORDMARK_DARK/LIGHT is the manifest-authoritative name (grdp had WORDMARK_DARK/LIGHT without the PM_ prefix, fixed to match 14-ASSET-MANIFEST.md)
- [Phase 15-05]: Prometheus advanced tab commands delegate to Chromium browser commands and TabStripModel context-menu commands; unsupported unload/discard returns false without mutation until a native discard path is chosen.
- [Phase 15-06]: Phase 15 automated gates passed and 11 Chromium patches were exported from `19d1f8e0de..HEAD`; desktop visual screenshot UAT remains open because Conductor could not foreground/window-target the native app.
- [Phase 16-01]: Production Prometheus WebUI hosts are `chrome://prometheus-newtab/`, `chrome://prometheus-side-panel/`, and `chrome://prometheus-control-panel/`; only the older theme preview remains DCHECK/UNKNOWN-channel gated.
- [Phase 16-02]: Ask FSB prompts are trimmed, bounded, and stored in browser-owned Profile user data; prompts are not placed in URLs/history and only seed side-panel WebUI state until a real task runtime exists.
- [Phase 16-02]: Prometheus side-panel entry registration is shared through a BrowserWindowInterface helper and loads `chrome://prometheus-side-panel/`; Plan 16-03 should extend this helper instead of restoring the old placeholder.
- [Phase 16-03]: The Prometheus side-panel shell uses icon-only mode buttons with title/aria labels and local packaged Font Awesome SVG masks; inactive mode labels remain in DOM text while content visibility is mode-gated.
- [Phase 16-03]: Toolbar side-panel regression validates the live side-panel WebView from BrowserView's side-panel content parent after opening the existing Assistant side-panel entry.
- [Phase 16-04]: FSB Control Panel uses a rail/select synchronized section model over nine UI-SPEC operator sections; hidden panels keep required copy in DOM while one section is visible.
- [Phase 16-04]: Required provider/vault secret-blocked strings are UI security copy only; no raw key or vault fixture values are rendered.
- [Phase 16-05]: Pending Ask FSB prompt reads consume browser-owned state; browser tests inspect the live handoff-opened side-panel WebView instead of navigating a second side-panel page.
- [Phase 16-05]: Prometheus WebUI iteration remains package-backed by default and is gated by `verify-prometheus-webui-resources.sh`; disk-loaded WebUI is deferred until it can satisfy the same gates.
- [Phase 16-06]: Phase 16 WebUI automated gates passed: build, full `prometheus_unittests`, full Phase 16 `browser_tests` filter, WebUI resource scanner, Chromium env/GPL/isolation gates, and 9-patch export from `a4423116ff..HEAD`.
- [Phase 16-06]: Preservation evidence now covers Phase 16 WebUI shells while desktop visual UAT and Phase 20 runtime/provider/vault data checks remain carry-forward.

### Roadmap Evolution

- Phase 7 added: Compact Safari-style browser chrome and advanced tab management.
- Phase 8 added: Native FSB-plus settings side panel and feature parity matrix.
- Phase 9 added: Offline Font Awesome Free icon system and minimal themes.
- Phase 8 edited: revised to side-panel four modes + FSB Control Panel page split per canonical design
- Phase 9 edited: added Poppins/Space Mono fonts, logo pass, warm two-theme tokens
- Phase 10 added: New Tab Start Page (design-driven new scope)
- Milestone v2.0 started: Chromium Engine Migration.
- Phases 11-24 added: preservation, Chromium checkout/build, branding/legal, design-system port, compact chrome, WebUI, native agent service, page adapters, MCP, FSB runtime, supervision, extensions, parity/security, packaging.
- Phase 20.1 inserted after Phase 20: Embedded xterm.js terminal with bundled/pinned Claude Code CLI runtime, CLAUDE.md provisioning, and auto-installed MCP bridge; toggleable in Settings as an alternate side-panel engine alongside FSB's own provider engine. User-requested scope extension (2026-07-01) -- NOT jumping the execution queue; the autonomous run continues Phase 14 -> 15 -> ... -> 20 -> 20.1 -> 21 in numeric sequence.

### Pending Todos

Unmodified Chromium launch verification passed before Prometheus patches begin. `.context/chromium-launch.status` records `status=0`, `workaround_used=false`, `patches_blocked=false`. Prometheus-specific Chromium patches may now proceed from Phase 13.

### Blockers/Concerns

Open items carried into v2.0 (formal list in Deferred Items below):

- 26 human-visual UAT checks across phases 08/09/10 were never run on a live Falkon binary; Phase 11 mapped all of them into the canonical Chromium carry-forward ledger for later Chromium-equivalent UAT.
- Internal Falkon → Prometheus namespace/class/library rename is obsolete as a direct task because the implementation is being replaced; de-Falkon validation moves to Phase 23.
- The release artifact is a local macOS validation package, not a notarized public release.
- Provider-backed hosted model execution remains partially deferred.
- Chromium checkout, build, unmodified launch, and artifact isolation are all complete (Phase 12). Phase 13 Prometheus Chromium patches may begin.
- License boundary is high-risk: do not copy Falkon GPL implementation into Chromium without review.

## Deferred Items

Acknowledged at v1.0 milestone close (2026-06-17) and carried into v2.0. Phase 11 mapped every item into `.planning/preservation/FALKON-TO-CHROMIUM-PRESERVATION.md` as Chromium-owned `carry_forward` evidence; later owner phases must run the Chromium-equivalent visual checks or retire a check with rationale if the surface no longer exists.

| Category | Item | Status | Deferred At |
|----------|------|--------|-------------|
| verification | 08-VERIFICATION.md — 10 control-panel/side-panel visual checks | carried_forward_phase_11 | v1.0 close 2026-06-17 |
| verification | 09-VERIFICATION.md — 8 icon/font/theme rendering checks | carried_forward_phase_11 | v1.0 close 2026-06-17 |
| verification | 10-VERIFICATION.md — 8 start-page visual checks | carried_forward_phase_11 | v1.0 close 2026-06-17 |
| migration | Internal Falkon → Prometheus namespace/class/library rename replaced by Chromium migration and de-Falkon gate | active_v2_replacement | v2.0 start 2026-06-17 |
| release | Notarized, distributable macOS release (current is local validation package) | deferred | v1.0 close 2026-06-17 |
| preservation | Falkon v1 source bundle and 81-patch series | saved | v2.0 start 2026-06-17 |
| local_build | Chromium GN generation required accepted Xcode license | fixed | v2.0 Phase 12 2026-06-17 |
| local_build | Chromium Metal Toolchain asset required for ANGLE Metal shader compilation | fixed | v2.0 Phase 12 2026-06-17 |
| local_build | First Chromium `chrome` build finished; unmodified launch verification remains Phase 12 scope | complete | v2.0 Phase 12 2026-06-17 |
| local_launch | Unmodified Chromium launch verified (status=0, workaround_used=false, patches_blocked=false); evidence at .context/chromium-launch.status and normal launch attempted first | complete | v2.0 Phase 12 2026-06-24 |

## Session Continuity

Last session: 2026-07-07T09:22:47Z
Stopped at: Phase 17 Plan 17-05 completed
Resume file: .planning/phases/17-native-agent-command-service-and-tab-ownership/17-05-SUMMARY.md

## Operator Next Steps

- Phase 12 is complete. The unmodified Chromium baseline is verified (checkout, build, launch, artifact isolation).
- Begin Phase 13: Prometheus branding and Chromium source patches. Create a named branch in `.context/chromium/src` (e.g. `git new-branch prometheus/phase-13-branding`) before making source edits.
- Use `.planning/chromium/CHROMIUM-CHECKOUT.md` as the canonical handoff for revision, GN args, gate scripts, and patch discipline.
- If a future rebuild fails, inspect `.context/chromium/src/out/Default/siso_output` and rerun `bash .planning/chromium/build-chromium-baseline.sh --no-op-ok`.
