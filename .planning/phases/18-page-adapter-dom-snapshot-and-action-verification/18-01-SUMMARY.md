---
phase: 18-page-adapter-dom-snapshot-and-action-verification
plan: 01
subsystem: browser-agent-routing
tags: [chromium, cpp, gtest, route-contracts, audit-metadata, dom-adapter]

# Dependency graph
requires:
  - phase: 17-native-agent-command-service-and-tab-ownership
    provides: Typed AgentRouteName/AgentRouteRequest/AgentRouteResult/AgentErrorCode spine, PrometheusAgentService route validation, data-minimal audit model
provides:
  - AgentRouteName entries for read_page, get_dom_snapshot, get_page_snapshot, execute_js, click, type_text, press_key, scroll, hover, select_option, clear, drag, and drop_file
  - AgentErrorCode entries kInvalidPageInput, kFrameRestricted, kVerificationFailed, kRepeatedAction
  - AgentFrameTarget, AgentElementTarget, AgentPageActionRequest, AgentPageReadOptions, AgentPageRequest, and AgentPageResult plain-data structs
  - Optional page_request/page_result wiring on AgentRouteRequest/AgentRouteResult
  - Extended kDisallowedAuditMetadataTerms covering DOM/script/selector/typed-text/file-path/secret-bearing terms
affects: [18-02, 18-03, 18-04, 18-05, 18-06, 18-07, 18-08, phase-19-mcp-bridge]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Page payload structs are plain-data-only (no content/browser includes) in the route header, keeping the contract layer buildable without pulling in renderer dependencies.
    - Optional<T> wrapping on AgentRouteRequest::page_request / AgentRouteResult::page_result keeps page content physically separate from route metadata fields.
    - Route/error string vocabulary changes are TDD-covered by extending the existing PrometheusAgentRouteTest and PrometheusAgentAuditTest suites rather than new test binaries.

key-files:
  created: []
  modified:
    - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_route.h
    - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_route.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_route_unittest.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_audit.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_audit_unittest.cc

key-decisions:
  - "Used exact D-03 string names (read_page, get_dom_snapshot, get_page_snapshot, execute_js, click, type_text, press_key, scroll, hover, select_option, clear, drag, drop_file) so Phase 19's MCP bridge can map tool names directly without a translation table."
  - "Page payload structs carry only optional/bounded fields (no raw WebContents/RenderFrameHost pointers), preserving D-07's no-durable-ref guarantee at the contract level — implementation plans must re-resolve frames/elements at action time."
  - "BUILD.gn required no edit: prometheus_agent_route_unittest.cc and prometheus_agent_audit_unittest.cc were already registered in the prometheus_unittests test() target from Phase 17 scaffolding, and no browser_test_utils.h dependency was introduced."
  - "Changed 'RejectsUnknownRouteStrings' test's example from click to click_element, since click is now a valid Phase 18 route name."

patterns-established:
  - "Frame/element identity contracts (AgentFrameTarget, AgentElementTarget) are labeled in comments as untrusted, per-snapshot, per-frame data requiring re-resolution at use time — future plans reading this header get the security boundary inline."
  - "Audit denylist extension for new content categories is verified with both direct IsAgentRouteAuditMetadataSafe() term checks and full AgentRouteAuditLog::Append() rejection tests, covering the two call sites content could otherwise leak through."

requirements-completed: [PAGE-01, PAGE-02, PAGE-03, PAGE-04, PAGE-05, PAGE-06, PAGE-07, PAGE-08]

# Metrics
duration: 4min
completed: 2026-07-07
---

# Phase 18 Plan 01: Page Route Contracts and Content-Safe Audit Denylist Summary

**Extended the Phase 17 typed route spine with 13 D-03-compatible page route names, 4 page-specific error codes, and 6 bounded page payload structs, then hardened the audit denylist against DOM/script/selector/typed-text/file-path content leakage.**

## Performance

- **Duration:** 4min
- **Started:** 2026-07-07T15:48:45Z
- **Completed:** 2026-07-07T15:52:38Z
- **Tasks:** 3 completed (2 code tasks + 1 verification-only wiring task)
- **Files modified:** 5

## Accomplishments
- All Phase 18 route names (`read_page`, `get_dom_snapshot`, `get_page_snapshot`, `execute_js`, `click`, `type_text`, `press_key`, `scroll`, `hover`, `select_option`, `clear`, `drag`, `drop_file`) parse and serialize through the existing Phase 17 route spine, verified by 19 focused unit tests.
- Defined a complete set of bounded, copyable page payload structs (`AgentFrameTarget`, `AgentElementTarget`, `AgentPageActionRequest`, `AgentPageReadOptions`, `AgentPageRequest`, `AgentPageResult`) wired onto `AgentRouteRequest`/`AgentRouteResult` via `std::optional`, keeping page content physically separate from route metadata.
- Extended the audit metadata denylist with 13 new content-bearing terms (`dom_snapshot`, `page_snapshot`, `script`, `javascript`, `js_snippet`, `selector`, `element_ref`, `typed_text`, `file_path`, `drop_path`, `page_html`, `page_content`, `local_path`) and verified they are rejected while the plan's required stable changed-state constants remain accepted.

## Task Commits

Each task was committed atomically inside the nested `.context/chromium/src` Chromium checkout (root repo does not track Chromium source):

1. **Task 1: Add Phase 18 page route contracts** - `c381ba1be5` (feat)
2. **Task 2: Keep page content out of audit metadata** - `bddc1618aa` (feat)
3. **Task 3: Wire contract tests into the unit target** - no commit (verification-only; `BUILD.gn` already registered both unittest files from Phase 17, no source changes required)

**Plan metadata:** (this commit, docs: complete plan)

## Files Created/Modified
- `.context/chromium/src/chrome/browser/prometheus/prometheus_agent_route.h` - Added `kReadPage` through `kDropFile` route enum entries, `kInvalidPageInput`/`kFrameRestricted`/`kVerificationFailed`/`kRepeatedAction` error codes, and the six new page payload structs plus optional wiring on `AgentRouteRequest`/`AgentRouteResult`.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_agent_route.cc` - Added `kRouteNameEntries` mappings for all 13 new D-03 route strings, error-code string serialization for the 4 new codes, and default-constructor/copy boilerplate for the new structs.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_agent_route_unittest.cc` - Added `ParsesPageReadRouteStrings`, `ParsesPageActionRouteStrings`, extended `SerializesErrorCodes`, and added `PageRequestIsCopyableAndCarriesActionFields`, `PageResultIsCopyableAndCarriesBoundedOutput`, and `RouteRequestAndResultCarryOptionalPagePayloads` tests. Changed `RejectsUnknownRouteStrings` to use `click_element` instead of `click` since `click` is now valid.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_agent_audit.cc` - Extended `kDisallowedAuditMetadataTerms` with 13 page-content-bearing terms.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_agent_audit_unittest.cc` - Added `RejectsPageContentBearingMetadataTerms`, `AcceptsStablePage18ChangedStateConstants`, `RejectsPageContentBearingChangedState`, and `AcceptsPage18StableChangedStateRecord` tests.

## Decisions Made
- Used exact D-03 string names for all 13 route entries so the Phase 19 MCP bridge can map tool names directly.
- Verified no collision between the 13 newly disallowed audit terms and the 7 required-accepted stable constants (`visible_text_returned`, `snapshot_returned`, `js_executed`, `element_clicked`, `verification_timeout`, `file_drop_denied`, `stuck_action_detected`) before writing tests — none found, matching the fix already applied upstream in the phase-planning commit (`7caa330c1`).
- Left `chrome/browser/prometheus/BUILD.gn` unmodified: both extended unittest files were already registered in the `prometheus_unittests` `test()` target from Phase 17 scaffolding, and this plan introduced no new test source files.

## Deviations from Plan

None - plan executed exactly as written. All three tasks' acceptance criteria were met without requiring architectural changes, blocking-issue fixes, or scope additions beyond what the plan specified.

## Issues Encountered

None. The Chromium checkout at `.context/chromium/src` was already on the `prometheus/phase-14-assets` branch with a clean working tree at commit `ad736125ee`; the prior `prometheus_unittests` binary built successfully on the first `autoninja` invocation for both tasks.

## User Setup Required

None - no external service configuration required. All work is local C++ contract/test code inside the existing Chromium checkout.

## Next Phase Readiness

Plans 18-02 through 18-08 (frame resolution, page reads/snapshots, JS execution, safe actions, waits/change reports, stuck-action detection, and gate/export work) can now build directly on the typed `AgentPageRequest`/`AgentPageResult` contracts and the extended route/error vocabulary defined here. No blockers. The route/audit unit target (`prometheus_unittests`) builds cleanly and the focused `*PrometheusAgentRoute*:*PrometheusAgentAudit*` filter passes all 19 tests, giving downstream plans a stable, tested contract surface to implement against.

## Self-Check: PASSED

- FOUND: `.context/chromium/src/chrome/browser/prometheus/prometheus_agent_route.h`
- FOUND: `.context/chromium/src/chrome/browser/prometheus/prometheus_agent_route.cc`
- FOUND: `.context/chromium/src/chrome/browser/prometheus/prometheus_agent_route_unittest.cc`
- FOUND: `.context/chromium/src/chrome/browser/prometheus/prometheus_agent_audit.cc`
- FOUND: `.context/chromium/src/chrome/browser/prometheus/prometheus_agent_audit_unittest.cc`
- FOUND: commit `c381ba1be5` (Chromium checkout, `prometheus/phase-14-assets` branch)
- FOUND: commit `bddc1618aa` (Chromium checkout, `prometheus/phase-14-assets` branch)

---
*Phase: 18-page-adapter-dom-snapshot-and-action-verification*
*Completed: 2026-07-07*
