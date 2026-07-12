---
phase: 18-page-adapter-dom-snapshot-and-action-verification
plan: 05
subsystem: browser-page-snapshot
tags: [chromium, cpp, annotated-page-content, json, dom-refs, audit]

# Dependency graph
requires:
  - phase: 18-page-adapter-dom-snapshot-and-action-verification
    plan: 03
    provides: Callback-based page adapter/service routing, frame policy, TestFuture browser harness, and bounded read_page
provides:
  - Bounded full and compact APC-backed page snapshot routes
  - Document-token plus DOM-node-id refs with functional FindNodeWithID re-resolution
  - Redacted-frame markers, form/actionability state, and content-free snapshot audit records
  - Valid JSON under node and serialized-byte bounds
affects: [18-04, 18-06, 18-07, 18-08, phase-19-mcp-bridge]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Snapshot refs are document-scoped ephemeral data and must be re-resolved against fresh APC before action.
    - Serialized snapshot bounds remove tail entries and reserialize; JSON is never cut as an arbitrary byte string.
    - Closed route enums are safe audit vocabulary, while free-form changed_state remains denylisted for page content.

key-files:
  created:
    - .context/chromium/src/chrome/browser/prometheus/prometheus_page_snapshot.h
    - .context/chromium/src/chrome/browser/prometheus/prometheus_page_snapshot.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_page_snapshot_unittest.cc
  modified:
    - .context/chromium/src/chrome/browser/prometheus/prometheus_page_adapter.h
    - .context/chromium/src/chrome/browser/prometheus/prometheus_page_adapter.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_page_adapter_browsertest.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_audit.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_audit_unittest.cc
    - .context/chromium/src/chrome/browser/prometheus/BUILD.gn
    - .context/chromium/src/chrome/test/data/prometheus/page_adapter/forms.html
    - .context/chromium/src/chrome/test/data/prometheus/page_adapter/dynamic_dom.html

key-decisions:
  - "Reused the callback-based Execute/ExecuteRoute signatures already committed by Plan 18-03; no synchronous production path was added."
  - "Used AnnotatedPageContent.main_frame_data().document_identifier().serialized_token() as the primary document identity and child FrameData tokens for nested refs."
  - "Kept max_chars output valid JSON by removing tail nodes and reserializing, with [] as the minimum two-byte envelope."
  - "Requested same-site-only APC so cross-site frames become restricted markers rather than serialized content."

patterns-established:
  - "Ref contract: <document-token>:<dom-node-id>, parsed and re-resolved by ResolveSnapshotNodeRef -> optimization_guide::FindNodeWithID."
  - "Compact snapshot: focusable, clickable, form, anchor, heading, landmark, and restricted-frame nodes only; filtered nodes increment omitted_count."
  - "Snapshot audit: changed_state is exactly snapshot_returned or compact_snapshot_returned and never contains refs, selectors, or node text."

requirements-completed: []
requirements-progressed: [PAGE-02, PAGE-03]

# Metrics
duration: 19min
completed: 2026-07-12
---

# Phase 18 Plan 05: APC DOM and Compact Snapshot Summary

**Added bounded, frame-aware full and compact page snapshots over Chromium APC, with re-resolvable document-scoped refs, valid JSON truncation, and content-free audit metadata.**

## Performance

- **Duration:** 19min
- **Started:** 2026-07-12T12:39:03Z
- **Completed:** 2026-07-12T12:57:56Z
- **Tasks:** 3 completed
- **Files created/modified:** 11

## Accomplishments

- Transformed APC trees into full or compact JSON nodes carrying refs, frame tokens, tag/role/name/text hints, form state, and actionability signals.
- Added a functional `ResolveSnapshotNodeRef` contract that parses document-scoped refs and calls Chromium's `FindNodeWithID`; child-frame refs use each `FrameData.document_identifier.serialized_token`.
- Enforced node and byte bounds without ever returning syntactically truncated JSON, and stopped traversal beneath Chromium-redacted iframe markers.
- Wired `get_dom_snapshot` and `get_page_snapshot` into the existing callback route chain with direct APC main-document identity and same-site-only extraction.
- Added route-level forms, compaction, mutation/ref-lifetime, audit-safety, and read-page regression coverage.

## Task Commits

Each TDD step was committed atomically inside the nested `.context/chromium/src` checkout:

1. **Task 1 RED: Specify APC snapshot transform behavior** - `df4d6f2077` (test)
2. **Task 1 GREEN: Build bounded APC snapshots and ref resolver** - `d6b1cf3888` (feat)
3. **Tasks 2/3 RED: Specify route and fixture behavior** - `e6fe20f150` (test)
4. **Tasks 2/3 GREEN: Route APC-backed snapshots and repair typed audit storage** - `8d8fa36b2f` (feat)
5. **REFACTOR: Test the committed snapshot header directly** - `2c3d8107d4` (refactor)
6. **Security fix: Redact cross-site snapshot frames** - `d150209d0d` (fix)

**Plan metadata:** this root planning commit

## Files Created/Modified

- `.context/chromium/src/chrome/browser/prometheus/prometheus_page_snapshot.h/.cc` - Snapshot schema, APC walker, valid JSON bounds, compact filter, redacted-frame handling, and live ref re-resolution contract.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_page_snapshot_unittest.cc` - Five pure-proto tests for full/compact bounds, frame refs, `FindNodeWithID`, redaction, and valid JSON.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_page_adapter.h/.cc` - Asynchronous APC route dispatch and full/compact result mapping on the existing callback signature.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_page_adapter_browsertest.cc` - Three snapshot browser tests plus unchanged `TestFuture` synchronization for existing read routes.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_agent_audit.cc` and `_unittest.cc` - Closed route-enum handling with free-form changed-state content checks retained.
- `.context/chromium/src/chrome/browser/prometheus/BUILD.gn` - Snapshot sources, proto/content dependencies, and unit-test wiring.
- `.context/chromium/src/chrome/test/data/prometheus/page_adapter/forms.html` - APC-supported ARIA markers for deterministic form-control assertions.
- `.context/chromium/src/chrome/test/data/prometheus/page_adapter/dynamic_dom.html` - Deterministic element replacement proving snapshot refs are not durable handles.

## Decisions Made

- The committed production signatures remain:
  - `void PrometheusPageAdapter::Execute(const AgentRouteRequest&, BrowserWindowInterface*, tabs::TabInterface*, const AgentSession&, CompletionCallback)`
  - `void PrometheusAgentService::ExecuteRoute(BrowserWindowInterface*, const AgentRouteRequest&, RouteCallback)`
- Browser tests retain the test-only `base::test::TestFuture<AgentRouteResult>` helper; no production `base::RunLoop`, blocking wrapper, or synchronous page-route path exists.
- APC does not expose raw DOM IDs in `ContentAttributes`/`FormControlData`; browser fixtures therefore expose deterministic ID-equivalent names through supported `aria-label` fields.
- A requested JSON bound smaller than two bytes returns the minimum valid JSON array `[]`, marked truncated with omitted nodes, because no valid JSON array can satisfy a one-byte limit.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Pre-satisfied dependency] Did not repeat the async conversion**
- **Found during:** Task 2 source preflight
- **Issue:** The plan described converting synchronous signatures, but Plan 18-03 had already safely committed callback-based adapter/service signatures and test-only `TestFuture` synchronization.
- **Fix:** Reused those exact signatures and extended only the snapshot route arms/callback.
- **Files modified:** `prometheus_page_adapter.h/.cc`; no service signature changes
- **Verification:** Combined build and all six snapshot/read browser tests passed; production RunLoop scan found no matches.
- **Committed in:** `8d8fa36b2f`

**2. [Rule 1 - Correctness] Preserved valid JSON under max_chars**
- **Found during:** Task 1 design and parent source override
- **Issue:** Applying `BoundString` directly to serialized JSON could return invalid syntax.
- **Fix:** Removed tail nodes and reserialized until within the bound, with `[]` as the irreducible valid envelope.
- **Files modified:** `prometheus_page_snapshot.h/.cc`, `prometheus_page_snapshot_unittest.cc`
- **Verification:** `CharacterBoundKeepsJsonSyntacticallyValid` passed for normal and one-byte requests.
- **Committed in:** `d6b1cf3888`

**3. [Rule 3 - Fixture mismatch] Used APC-supported accessible names and deterministic replacement**
- **Found during:** Task 3 read-first review
- **Issue:** `forms.html` IDs differed from its `name` values, APC exposes `field_name` but not raw DOM ID, and the dynamic fixture did not deterministically replace the target element.
- **Fix:** Added ID-matching `aria-label` markers and made the mutation replace the labeled node while preserving its selector-facing HTML ID.
- **Files modified:** `forms.html`, `dynamic_dom.html`
- **Verification:** All three route browser tests passed and the mutated region's ref changed.
- **Committed in:** `e6fe20f150`

**4. [Rule 1 - Latent audit regression] Allowed closed snapshot route enums in audit records**
- **Found during:** Tasks 2/3 GREEN browser tests
- **Issue:** The content denylist rejected the fixed route name `get_dom_snapshot`, so otherwise-safe snapshot audit records were silently dropped.
- **Fix:** Applied the content denylist to free-form `changed_state`, not the closed browser-owned route enum; all content-bearing values remain rejected.
- **Files modified:** `prometheus_agent_audit.cc`, `prometheus_agent_audit_unittest.cc`
- **Verification:** 8/8 audit tests and 3/3 snapshot audit assertions passed.
- **Committed in:** `8d8fa36b2f`

**5. [Rule 2 - Security] Requested cross-site APC redaction**
- **Found during:** Final threat-model review
- **Issue:** The actionable APC helper defaults `include_same_site_only` to false, which would not generate the planned cross-site restriction marker.
- **Fix:** Set `include_same_site_only = true` before extraction.
- **Files modified:** `prometheus_page_adapter.cc`
- **Verification:** Combined build and all 19 focused audit/snapshot/read checks remained green.
- **Committed in:** `d150209d0d`

---

**Total deviations:** 5 auto-fixed (1 pre-satisfied dependency, 2 correctness/blocking, 1 latent regression, 1 security).
**Impact on plan:** All changes preserve the intended snapshot contract and security boundaries; no MCP, runtime, bundled CLI, terminal, alternate engine, or engine-toggle scope was added.

## Issues Encountered

- The APC options Mojo smart pointer requires the full generated `ai_page_content.mojom.h` at its destruction site; adding the same include used by established Chromium APC callers resolved the compile error.
- Focused browser tests emitted Chromium's known non-fatal `waitpid(...): No child processes` teardown log; all selected tests exited successfully.

## Verification

- `../../depot_tools/autoninja -C out/Default browser_tests prometheus_unittests` - passed.
- `./out/Default/prometheus_unittests --gtest_filter='*PrometheusPageSnapshot*:*PrometheusAgentAudit*'` - passed, 13/13.
- `./out/Default/browser_tests --gtest_filter='*Prometheus*Snapshot*:*Prometheus*ReadPage*'` - passed, 6/6.
- Post-implementation key links - passed, 2/2 (`BuildSnapshotJson`, functional `FindNodeWithID`).
- Audit-content, production test-API/RunLoop, and embedded/bundled CLI/runtime/engine scans - no forbidden matches.
- Chromium environment, GPL guard, artifact isolation, and preservation checks - passed.
- Nested Chromium and plan-scoped diff checks - passed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 18-04 can add the permissioned renderer/Mojo JavaScript seam on the unchanged callback route signatures. Plan 18-06 can call `ResolveSnapshotNodeRef` as the concrete document-scoped re-resolution contract before actions. PAGE-02 and PAGE-03 remain open until full Phase 18 verification; this plan records progress only.

## Self-Check: PASSED

- FOUND: all three created snapshot files and eight modified integration/fixture files.
- FOUND: six nested Chromium commits from `df4d6f2077` through `d150209d0d`.
- PASSED: combined build, 13 unit/audit tests, 6 browser tests, four root gates, security/audit scans, diff checks, and 2/2 key links.
- CLEAN: nested Chromium working tree after all task commits.

---
*Phase: 18-page-adapter-dom-snapshot-and-action-verification*
*Completed: 2026-07-12*
