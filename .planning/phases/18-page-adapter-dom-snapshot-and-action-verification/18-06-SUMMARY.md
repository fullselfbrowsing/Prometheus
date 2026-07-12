---
phase: 18-page-adapter-dom-snapshot-and-action-verification
plan: 06
subsystem: renderer-page-actions
tags: [chromium, cpp, mojo, blink-web-api, input-events, dom-refs]

# Dependency graph
requires:
  - phase: 18-page-adapter-dom-snapshot-and-action-verification
    plan: 04
    provides: PrometheusRenderFrame associated Mojo seam and per-frame observer
  - phase: 18-page-adapter-dom-snapshot-and-action-verification
    plan: 05
    provides: Document-token plus DOM-node-id snapshot refs and fresh APC re-resolution contract
provides:
  - Typed renderer PerformAction IPC for seven safe page actions
  - Connected exact-frame DOM ref resolution over public Blink Web APIs
  - Hidden, occluded, disabled, readonly, option, and named-key action gates
  - Reentrancy-safe mouse, keyboard, form, select, and scroll dispatch
affects: [18-07, 18-08, phase-19-mcp-bridge]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Renderer refs require valid token syntax but use connected exact-frame ownership as local authority; fresh browser APC remains the token authority.
    - Every event-producing Blink call is surrounded by weak-liveness checks and frame/widget re-acquisition.
    - Unknown Mojo action values map to a stable typed failure instead of disconnecting the associated interface.

key-files:
  created:
    - .context/chromium/src/chrome/renderer/prometheus_action_dispatcher.h
    - .context/chromium/src/chrome/renderer/prometheus_action_dispatcher.cc
    - .context/chromium/src/chrome/renderer/prometheus_action_dispatcher_unittest.cc
  modified:
    - .context/chromium/src/chrome/common/prometheus_render_frame.mojom
    - .context/chromium/src/chrome/renderer/prometheus_render_frame_observer.h
    - .context/chromium/src/chrome/renderer/prometheus_render_frame_observer.cc
    - .context/chromium/src/chrome/renderer/BUILD.gn

key-decisions:
  - "Require a non-empty document-token prefix, positive DOM node id, connected node, and exact WebLocalFrame match; the renderer cannot authenticate the token, so Plan 18-08 must fresh-resolve it through browser APC before IPC."
  - "Reject every hidden target with VisibleBoundsInWidget before action dispatch; scrolling received no exception because visible element scrolling works through the public API."
  - "Use an extensible Mojo action enum whose default kUnknown value returns a stable unsupported-action failure for untrusted or future values."
  - "Treat HandleInputEvent, Focus, SetValue, SetAutofillOption, and SetScrollOffset as reentrant destruction boundaries and never reuse renderer objects without a weak check and re-resolution."

patterns-established:
  - "Action target gate: parse ref -> FromDomNodeId -> connected -> exact frame -> DynamicTo element -> VisibleBoundsInWidget -> action-specific checks."
  - "Mouse targeting: intersect visible and client rects, use their center, and require hit-test containment before input dispatch."
  - "Mutation reporting: value_changed is derived only from actual before/after form, select, or scroll state."

requirements-completed: []
requirements-progressed: [PAGE-05]

# Metrics
duration: 18min
completed: 2026-07-12
---

# Phase 18 Plan 06: Safe Renderer Page Actions Summary

**Added seven ref-resolved renderer actions over public Blink Web APIs, with exact-frame authority, actionability rejection, and navigation-safe reentrancy handling.**

## Performance

- **Duration:** 18min
- **Started:** 2026-07-12T13:52:27Z
- **Completed:** 2026-07-12T14:10:38Z
- **Tasks:** 3 completed
- **Files created/modified:** 7

## Accomplishments

- Extended `PrometheusRenderFrame` with bounded `PerformAction` requests/results and lazy observer-owned dispatch.
- Implemented click, hover, type text, clear, select option, scroll, and named-key dispatch using only public Blink Web APIs.
- Rejected malformed, disconnected, foreign-frame, non-element, hidden, occluded, disabled, readonly, disabled-option, and unsupported-key targets with stable failures and no untrusted-input `CHECK`.
- Re-resolved targets and re-fetched widgets across synchronous page-script/navigation reentrancy so stale renderer objects are never dereferenced after dispatch.
- Added focused renderer tests for last-colon ref parsing and malformed/empty/non-numeric/nonpositive refs.

## Task Commits

Each task was committed atomically inside the nested `.context/chromium/src` checkout:

1. **Task 1: Extend the renderer IPC contract with PerformAction** - `d2c007a7bf` (feat)
2. **Task 2: Implement PrometheusActionDispatcher over public Blink Web APIs** - `af13d126e7` (feat)
3. **Task 3: Wire GN and add renderer-level ref coverage** - `6252dd01ae` (test)
4. **Scoped Chromium formatting** - `0cfa10f1dd` (style)

**Plan metadata:** this root planning commit

## Files Created/Modified

- `chrome/common/prometheus_render_frame.mojom` - Extensible typed action enum, bounded result, and associated `PerformAction` method.
- `chrome/renderer/prometheus_render_frame_observer.h/.cc` - Lazy dispatcher ownership and weak-safe Mojo delegation.
- `chrome/renderer/prometheus_action_dispatcher.h/.cc` - Ref resolution, visibility/actionability gates, public Blink dispatch, change detection, and liveness handling.
- `chrome/renderer/prometheus_action_dispatcher_unittest.cc` - Pure malformed-ref parsing coverage.
- `chrome/renderer/BUILD.gn` - Renderer source wiring, direct UI event/key/latency dependencies, and focused unit-test binary.

## Decisions Made

- The document-token prefix is required and non-empty but is not treated as renderer-authenticated identity. Exact current-frame ownership closes sibling-frame confusion locally; fresh APC lookup in Plan 18-08 remains authoritative for the browser-issued token.
- Hidden targets are denied for all seven actions, including scroll. No scroll exception was necessary because visible scroll containers use `GetScrollOffset`/`SetScrollOffset` directly.
- Click/hover points must be both visibly bounded and hit-test-contained by the target's flat tree, avoiding blind center clicks through an overlay.
- Type/clear reject readonly controls, selection rejects disabled options, and key dispatch focuses then verifies the re-resolved target before sending its allowlisted down/up pair.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Added the dispatcher boundary during the IPC task**
- **Found during:** Task 1 compile RED
- **Issue:** Observer delegation could not satisfy Task 1's required `chrome` build before the Task 2 dispatcher type existed.
- **Fix:** Captured the expected missing-header compile failure, then added a minimal stable-failure dispatcher boundary and GN source wiring before the full Task 2 GREEN implementation.
- **Files modified:** `prometheus_action_dispatcher.h/.cc`, `chrome/renderer/BUILD.gn`
- **Verification:** RED failed on the missing dispatcher header; the boundary build and every later full build passed.
- **Committed in:** `d2c007a7bf`

**2. [Rule 2 - Security] Made unknown Mojo values fail stably**
- **Found during:** Untrusted-input review
- **Issue:** A non-extensible Mojo enum rejects an unknown value during message validation, preventing the promised stable action failure.
- **Fix:** Added `[Extensible]` with `[Default] kUnknown`; dispatcher handling returns `ok=false` with `Unsupported action kind`.
- **Files modified:** `prometheus_render_frame.mojom`, `prometheus_action_dispatcher.cc`
- **Verification:** `chrome` regenerated Mojo bindings and built successfully; no `CHECK` handles action kinds.
- **Committed in:** `af13d126e7`

**3. [Rule 2 - Security/Correctness] Strengthened target and reentrancy validation**
- **Found during:** Blink API and navigation-race review
- **Issue:** Local-root-only checks admit sibling frames, hidden targets were not uniformly covered by the action sketch, and page handlers can synchronously destroy the observer during input/value/focus APIs.
- **Fix:** Required connected exact-frame nodes, uniform visible bounds, hit-test containment, readonly/disabled-option checks, and weak/liveness guards with fresh frame/widget/node lookup after every reentrant call.
- **Files modified:** `prometheus_action_dispatcher.h/.cc`, `prometheus_render_frame_observer.cc`
- **Verification:** Final build, focused unit tests, public-API/security scans, and 2/2 key links passed.
- **Committed in:** `af13d126e7`

---

**Total deviations:** 3 auto-fixed (1 blocking, 2 security/correctness).
**Impact on plan:** All fixes are necessary to satisfy the plan's stated safety contract. No browser-route authority, MCP bridge, third-party CLI/runtime, terminal, alternate engine, or engine-toggle scope was added.

## Issues Encountered

- A broad formatter briefly touched unrelated pre-existing Chromium files. Every unrelated formatting edit was restored exactly to `HEAD` with scoped `apply_patch`; only the two dispatcher files were then formatted explicitly and committed.
- No established per-frame Prometheus renderer test target existed, so Task 3 added a small dedicated binary instead of deferring malformed-ref coverage to Plan 18-08.

## Verification

- **Compile RED:** `autoninja -C out/Default chrome` failed as expected on missing `prometheus_action_dispatcher.h` after the IPC seam was first wired.
- `../../depot_tools/autoninja -C out/Default chrome prometheus_action_dispatcher_unittests` - passed, 20 final incremental steps.
- `./out/Default/prometheus_action_dispatcher_unittests --gtest_filter='PrometheusActionDispatcherTest.*'` - passed, 2/2.
- Post-implementation key links - passed, 2/2 (observer delegation and `FromDomNodeId`).
- Actor dependency/include, internal Blink/test API, unsafe cast/`CHECK`, and forbidden bundled CLI/runtime/terminal/engine scans - no matches.
- Nested committed-range and root diff checks - passed.
- Chromium environment, Falkon GPL guard, artifact isolation, and preservation verification - passed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 18-07 can add page-settle waiting and repeated-action detection. Plan 18-08 must fresh-resolve document tokens through APC before invoking this renderer seam and will supply full route/browser action coverage. `PAGE-05` remains open until those route, verification, drag, and file-drop outcomes are complete.

## Self-Check: PASSED

- FOUND: all three created renderer files and four modified IPC/observer/GN files.
- FOUND: four nested Chromium commits from `d2c007a7bf` through `0cfa10f1dd`.
- PASSED: final `chrome` and focused unit builds, 2/2 unit tests, 2/2 key links, security/runtime scans, diff checks, and four root gates.
- CLEAN: nested Chromium and root working trees before metadata creation.

---
*Phase: 18-page-adapter-dom-snapshot-and-action-verification*
*Completed: 2026-07-12*
