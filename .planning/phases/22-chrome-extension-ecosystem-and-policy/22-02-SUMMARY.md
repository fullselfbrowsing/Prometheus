---
phase: 22-chrome-extension-ecosystem-and-policy
plan: 02
subsystem: browser-agent
tags: [chromium, extensions, agent, mcp, policy, audit]

requires:
  - phase: 22-01
    provides: Deny-by-default extension policy, effective regular/Private grants, generation fencing, and registry lifecycle authority
provides:
  - Closed popup/side-panel Agent selectors anchored to an exact stable tab across native and MCP transports
  - Browser-owned visible extension-surface resolution with exact profile, committed-frame, registry, visibility, and generation proof
  - Dedicated extension page adapter enforcing the Blocked, Read-only, and Interact action matrix at admission and dispatch
  - Typed recovery results and content-free extension audit metadata without widening ordinary HTTP(S) page routing
affects: [22-03-control-panel-policy, 22-04-extension-fixtures, 22-05-extension-smoke, 23-extension-runtime]

tech-stack:
  added: []
  patterns:
    - Caller input selects only a closed surface kind and stable tab anchor; browser-owned state reconstructs extension identity
    - Extension reads and actions revalidate surface generation and effective grant immediately before low-level dispatch
    - Extension audit projection is separate from transport route DTOs and excludes content and authority

key-files:
  created:
    - .context/chromium/src/chrome/browser/prometheus/prometheus_extension_surface_resolver.h
    - .context/chromium/src/chrome/browser/prometheus/prometheus_extension_surface_resolver.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_extension_surface_resolver_unittest.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_extension_surface_browsertest.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_extension_page_adapter.h
    - .context/chromium/src/chrome/browser/prometheus/prometheus_extension_page_adapter.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_extension_page_adapter_unittest.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_extension_agent_browsertest.cc
  modified:
    - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_route.h
    - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_transport_codec.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_service.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_audit.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_page_action_dispatcher.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_page_element_reader.cc
    - tools/prometheus-mcp/src/catalog.mjs
    - tools/prometheus-mcp/src/schema.mjs
    - tools/prometheus-mcp/src/tool-handler.mjs
    - .planning/chromium/verify-phase-22-extension-policy.sh

key-decisions:
  - "Accept only popup or side_panel plus a positive exact tab_id; reject every caller-supplied extension, URL, frame, renderer, ordinal, alias, or WebContents identity."
  - "Classify a selected committed chrome-extension:// primary frame after session and target ownership checks but before ordinary HTTP(S) page dispatch."
  - "Keep the extension adapter structurally separate from page JavaScript, raw DevTools, native messaging, gateway, vault, session, and policy-mutation authority."
  - "Carry bounded extension audit metadata through a dedicated completion path rather than widening AgentRouteResult and its transport ABI."

patterns-established:
  - "Positive visible-surface proof: exactly one current browser-owned popup or active side panel must match the stable tab anchor."
  - "Two-stage authorization: resolve and admit from fresh browser/policy state, then repeat validation immediately before the semantic read or mutation."
  - "Closed extension matrix: Blocked permits nothing; Read-only permits five semantic reads; Interact adds seven typed element actions; scripts and drag/drop remain denied."

requirements-completed: [EXT-03, EXT-04]

duration: 11h 34m
completed: 2026-07-29
---

# Phase 22 Plan 02: Extension Agent Surface Routing Summary

**Fail-closed Agent routing for visible extension tabs, options pages, popups, and side panels with browser-owned identity, fresh grant enforcement, and no script or reverse-authority widening**

## Performance

- **Duration:** 11h 34m
- **Started:** 2026-07-28T23:33:01Z
- **Completed:** 2026-07-29T11:07:11Z
- **Tasks:** 3
- **Files modified:** 44 root and nested repository paths

## Accomplishments

- Added a native and MCP `extension_surface` selector that accepts exactly `popup|side_panel`, requires a positive stable `tab_id`, round-trips the exact selector, and rejects aliases, ambiguity, unknown values, and caller identity.
- Reconstructed extension identity from the selected committed primary frame, enabled registry membership, exact BrowserContext, and current browser-owned visibility instead of trusting renderer or request metadata.
- Added a dedicated extension adapter with exactly five bounded semantic reads and seven typed interactions, plus fresh surface-generation and effective-grant checks immediately before dispatch.
- Kept ordinary page handling HTTP(S)-only and made JavaScript, drag/drop, raw protocol, background/offscreen contexts, native messaging, vault, gateway, and grant mutation unreachable from extension routing.
- Added bounded, content-free extension audit projection and stable recovery copy for unavailable, blocked, read-denied, interaction-denied, unsupported, script-denied, stale-policy, and Private-denied outcomes.

## Task Commits

Each task was committed atomically in both the root coordination repository and nested Chromium repository:

1. **Task 1: Retain exhaustive surface-resolution and transport RED fixtures**
   - Root: `f1e3a4c4f`
   - Chromium: `edc9f83118`
2. **Task 2: Implement browser-owned identity and visible-surface resolution**
   - Root: `90b84de81`
   - Chromium: `d7b3b47b25`
3. **Task 3: Enforce the closed extension read/interact matrix**
   - RED root: `20010238b`
   - RED Chromium: `889fdfd778`
   - GREEN root: `0b1bf8078`
   - GREEN Chromium: `071759e504`

## Files Created/Modified

- `.context/chromium/src/chrome/browser/prometheus/prometheus_agent_route.{h,cc}` and `prometheus_agent_transport_codec.cc` - Closed selector type, exact stable-tab validation, and result round-trip.
- `tools/prometheus-mcp/src/{catalog,schema,tool-handler}.mjs` - Matching closed MCP schema, normalization, and native envelope projection.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_extension_surface_resolver.{h,cc}` - Browser-owned frame, registry, profile, visible-UI, and generation resolution.
- `.context/chromium/src/chrome/browser/ui/views/extensions/extension_popup.{h,cc}` and side-panel coordinator/manager files - Read-only observation seams for the currently shown browser-owned surfaces.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_extension_page_adapter.{h,cc}` - Dedicated grant-aware semantic read and typed interaction adapter.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_agent_service.{h,cc}` - Extension classification and distinct completion/audit path after exact ownership validation.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_agent_audit.{h,cc}` - Closed suffix/surface/grant/result metadata validation without route authority.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_page_action_dispatcher.{h,cc}` and `prometheus_page_element_reader.{h,cc}` - Optional immediate dispatch validators used by extension routing while preserving ordinary HTTP(S) behavior.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_agent_profile_service.{h,cc}` - Out-of-line weak-pointer accessor preserving composition ABI and owning-sequence teardown.
- Resolver, adapter, service, audit, route, codec, browser, and Node test files - Exhaustive positive, denial, lifecycle, provenance, reverse-authority, and bounds evidence.
- `.planning/chromium/verify-phase-22-extension-policy.sh` - Metadata-preserving focused rebuild, combined test, and static contract gate.
- `.planning/phases/22-chrome-extension-ecosystem-and-policy/patches/0005-*.patch` through `0008-*.patch` - Ordered stable source-only Chromium exports.

## Decisions Made

- Treat `extension_surface` as a routing hint only. The request cannot name an extension; Chromium derives the ID from the current committed origin and re-queries browser-owned state.
- Require exactly one current visible UI match. Missing, duplicated, hidden, wrong-profile, stale, disabled, terminated, or unsupported candidates fail typed without active-tab or first-host fallback.
- Reuse bounded semantic primitives through optional pre-dispatch validation callbacks, leaving their ordinary callers and HTTP(S)-only URL boundary unchanged.
- Keep extension audit metadata out of `AgentRouteResult`; a separate service completion path prevents transport ABI growth and records only a six-character ID suffix plus closed enums.

## Deviations from Plan

### Auto-fixed Issues

**1. Added minimal popup and side-panel observation seams**

- **Found during:** Task 2
- **Issue:** Chromium did not expose the exact shown popup or active extension side-panel `WebContents` needed for positive browser-owned resolution.
- **Fix:** Added read-only popup/coordinator/manager observation methods and no mutation authority.
- **Files:** `extension_popup.{h,cc}`, `extension_side_panel_coordinator.{h,cc}`, `extension_side_panel_manager.{h,cc}`
- **Verification:** The complete surface cohort passed 32/32 with exact missing, ambiguous, wrong-profile, hidden, and lifecycle denials.

**2. Added immediate validation seams to bounded semantic primitives**

- **Found during:** Task 3
- **Issue:** Admission-time policy checks alone could not close the lifecycle window immediately before a Mojo read or element mutation.
- **Fix:** Added optional dispatch-validation callbacks to the action dispatcher and element reader; only the extension adapter supplies them, and ordinary callers retain existing HTTP(S)-only checks.
- **Files:** `prometheus_page_action_dispatcher.{h,cc}`, `prometheus_page_element_reader.{h,cc}`
- **Verification:** The 14/14 extension Agent cohort and static call-graph gate passed.

**3. Rebuilt dependent composition objects and stabilized the weak-pointer ABI**

- **Found during:** Task 3 focused verification
- **Issue:** The metadata-preserving focused linker reused stale objects compiled against the prior embedded Agent-service layout, causing owning-sequence teardown failures.
- **Fix:** Moved `AgentProfileService::GetWeakPtr()` out of line and taught the focused harness to rebuild Agent session/profile/factory, supervision factory, audit, adapter, dispatcher, and reader dependencies coherently.
- **Files:** `prometheus_agent_profile_service.{h,cc}`, `.planning/chromium/verify-phase-22-extension-policy.sh`
- **Verification:** The exact 14/14 browser/profile lifecycle cohort, 54/54 native regression, and 67/67 combined focused gate passed.

## Issues Encountered

- Widening `AgentTarget` changed the native route layout, so the focused binary also needed an exact `PrometheusAgentSession` rebuild. The harness now compiles that dependency and all related composition objects from one source state.
- An early audit projection through the general route result would have widened a broadly shared transport DTO. The final implementation instead uses a dedicated content-free extension completion record.

## User Setup Required

None - no external service configuration required.

## Verification

- `bash .planning/chromium/verify-phase-22-extension-policy.sh --focus 'PrometheusExtensionSurface*'` passed the complete 32/32 surface cohort.
- `bash .planning/chromium/verify-phase-22-extension-policy.sh --focus 'PrometheusExtensionAgent*'` passed 14/14 adapter, service, and browser/profile lifecycle cases.
- `bash .planning/chromium/verify-phase-22-extension-policy.sh --focused` passed the combined 67/67 policy, surface, Agent, and browser cohort plus the static dispatch contract.
- `.context/chromium/src/out/Default/prometheus_unittests --gtest_filter='PrometheusAgentRouteTest.*:PrometheusAgentTransportCodecTest.*:PrometheusAgentAuditTest.*:PrometheusAgentServiceTest.*:PrometheusAgentServiceObservationTest.*' --gtest_brief=1` passed 54/54.
- `node --test test/catalog.test.mjs test/tools.test.mjs test/transport.test.mjs` passed 44/44.
- `.ninja_log` remained `eccf79f3dfdc6c8d51af20f56bf1973eb35ff486b1dab9b2b0653cc37b586dce`; `.ninja_deps` remained `ab1a6ad4639e8db53459384f8636dc53f396397363f3c2751bcdadc0349947c0`.
- Root and nested Chromium `git diff --check` passed, patch `0008` reverse-applied cleanly, and both worktrees were clean before summary creation.

## Next Phase Readiness

- Plan 22-03 can project the bounded extension inventory and regular/Private grant controls into the local control panel without changing the Agent route contract.
- Plans 22-04 and 22-05 can build deterministic extension fixtures and end-to-end smoke evidence on top of the exact visible-surface resolver.
- Parallel-worktree `STATE.md` and `ROADMAP.md` advancement remains with the root GSD orchestrator.
- No implementation or verification blockers remain.

## Self-Check: PASSED

- Resolver, adapter, service integration, audit projection, focused verifier, MCP selector, and all four Plan 22-02 patch files exist.
- All eight root/nested RED and GREEN task commits resolve.
- Focused, native transport/service, Node transport, static boundary, metadata-preservation, and diff gates pass.
- Root and nested Chromium worktrees were clean at closeout.

---
*Phase: 22-chrome-extension-ecosystem-and-policy*
*Completed: 2026-07-29*
