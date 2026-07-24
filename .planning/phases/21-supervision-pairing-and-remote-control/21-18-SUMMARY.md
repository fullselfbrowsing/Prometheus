---
phase: 21-supervision-pairing-and-remote-control
plan: 18
subsystem: chromium-side-panel-supervision-runtime
tags: [chromium, supervision, side-panel, webui, exact-tab, privacy, tdd]

requires:
  - phase: 21-17
    provides: Live sanitized supervision state projected through browser-owned tab data
  - phase: 21-15
    provides: Authoritative controller/action lifecycle and exact native revalidation
provides:
  - Sanitized selected-tab supervision DTO and bounded browser-produced target label
  - Strict zero-authority stop, end, and same-window management WebUI messages
  - Fresh exact-browser selected-tab action routing with fail-closed lifecycle checks
  - Zero-argument bulk ending for every viewer and controller on one exact supervised tab
  - Browser regressions for privacy, target isolation, duplicate action, shutdown, and WebUI teardown
affects: [21-19, 21-20, 21-21, 21-22, 21-25, phase-21-supervision]

tech-stack:
  added: []
  patterns:
    - Persistent WebUI state is a closed sanitized browser snapshot, never renderer-supplied authority
    - Zero-identity UI intents re-resolve the exact browser-selected tab at mutation time
    - WebUI snapshot callbacks remain gated until the current document explicitly initializes

key-files:
  created: []
  modified:
    - .context/chromium/src/chrome/browser/ui/webui/prometheus/prometheus_side_panel_runtime.h
    - .context/chromium/src/chrome/browser/ui/webui/prometheus/prometheus_side_panel_runtime.cc
    - .context/chromium/src/chrome/browser/ui/webui/prometheus/prometheus_web_ui.h
    - .context/chromium/src/chrome/browser/ui/webui/prometheus/prometheus_web_ui.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_browser_main_extra_parts.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_supervision_profile_service.h
    - .context/chromium/src/chrome/browser/prometheus/prometheus_supervision_profile_service.cc
    - .context/chromium/src/chrome/browser/ui/webui/prometheus/prometheus_web_ui_browsertest.cc
    - .planning/chromium/verify-phase-21.sh

key-decisions:
  - "Keep the persistent supervision runtime available even when task-principal acquisition is unavailable; task actions remain disabled while selected-tab supervision stays independently observable."
  - "Expose exact selected-tab stop, manage, and bulk-end methods on the authoritative profile service so WebUI never retains or transmits dashboard sessions, controller leases, tab IDs, or other authority."
  - "Publish only a closed display DTO with bounded safe labels and activity categories; raw URLs, titles, identifiers, sequence/document state, action values, and page content remain structurally absent."
  - "Gate native-to-JavaScript snapshot delivery on the current WebUI document's explicit initialize message so reload/destruction cannot receive an early or late callback."

patterns-established:
  - "Zero-authority action perimeter: strict zero-argument messages carry intent only, then native code resolves the exact current browser, selected tab, profile service, and live owner."
  - "Two-phase bulk teardown: collect exact-tab viewers, revalidate every owner and exact binding before mutation, then terminalize the complete set."
  - "Browser-owned display labels: sanitize native tab titles to at most 80 UTF-16 characters and fall back to `this tab` for URL-, authority-, control-, bidi-, or secret-shaped input."

requirements-completed: []
requirements-progressed: [SUP-01, SUP-03, SUP-04]

duration: 1h49min
completed: 2026-07-24
---

# Phase 21 Plan 18: Exact-Tab Side-Panel Supervision Runtime Summary

**The side panel now receives one fresh, sanitized exact-tab supervision snapshot and can stop control, bulk-end supervision, or open management through zero-authority native intents.**

## Performance

- **Duration:** 1h49min
- **Started:** 2026-07-24T11:29:13Z
- **Completed:** 2026-07-24T13:18:41Z
- **Tasks:** 3
- **Files modified:** 9 source, test, and verifier files; 3 ordered patch exports

## Accomplishments

- Added a closed supervision DTO with availability, bounded viewer/controller display state, closed activity/action categories, resync/stopping/ending flags, and a browser-produced `safe_target_title`.
- Sanitized hostile titles by rejecting controls, bidi overrides, URLs, paths, queries, fragments, authority/secret-shaped text, and overlong labels, with a fixed `this tab` fallback and 80-character bound.
- Registered strict zero-argument stop, end, and manage messages whose operation results expose only accepted/status/recovery and cannot echo renderer-supplied identifiers, results, or titles.
- Bound the persistent runtime to one exact regular-profile Browser, observed selected-tab and supervision changes, and kept supervision independently available when task-principal acquisition is unavailable.
- Implemented exact selected-tab stop and same-window management actions with fresh target/owner checks, duplicate-safe typed failures, and no active-profile or cross-window fallback.
- Implemented all-viewer bulk end with preflight owner and exact-binding revalidation before any requested end mutation, coherent controller removal, transient ending state, and harmless repeat submission.
- Added WebUI initialization gating so construction, reload, destruction, and later service notifications cannot deliver JavaScript callbacks to the wrong document lifetime.

## Task Commits

Each TDD task was committed atomically in nested Chromium and exported into the root patch chain:

1. **Task 1 (RED): Freeze sanitized selected-tab state and zero-authority messages** — nested `1c641d971b`, root `aa1d6f2cc`, patch `0045`
2. **Task 2 (GREEN): Bind exact-window snapshot, stop, and manage actions** — nested `391e4e0516`, root `0e8d554c8`, patch `0046`
3. **Task 3 (GREEN): Execute zero-argument bulk end with fresh native revalidation** — nested `c8cc042cc2`, root `89a6285fb`, patch `0047`

## Files Created/Modified

- `prometheus_side_panel_runtime.h/.cc` — Closed supervision DTO, activity/action enums, hostile-title sanitizer, operation defaults, and safe snapshot serialization.
- `prometheus_web_ui.h/.cc` — Strict zero-argument message handlers, native action dispatch, snapshot/operation delivery, and per-document initialization gate.
- `prometheus_browser_main_extra_parts.cc` — Exact-browser native runtime, selected-tab/service observation, sanitized snapshot mapping, stop/manage/end routing, and lifecycle invalidation.
- `prometheus_supervision_profile_service.h/.cc` — Authority-owning exact-selected-tab stop, same-window management, and preflighted bulk-end APIs.
- `prometheus_web_ui_browsertest.cc` — State/privacy, zero-argument rejection, stop/manage isolation, OTR/window/tab/shutdown failure, bulk end, duplicate, transient-state, and reload teardown coverage.
- `.planning/chromium/verify-phase-21.sh` — Static side-panel runtime contract checks plus focused production and browser-test object compilation.
- `patches/0045` through `0047` — Stable ordered nested Chromium patch exports.

## Decisions Made

- The WebUI owns presentation intent only. It cannot provide a profile, browser, tab, owner, session, controller, document, sequence, result, or title to native supervision actions.
- The authoritative profile service owns exact-target lookup and mutation. Runtime snapshots intentionally contain no dashboard token that could be reused as action authority.
- The selected-tab supervision strip remains alive after the original task principal or task target is lost; task observation retires independently while the browser/window supervision observer remains exact and fresh.
- Bulk end validates the complete current viewer set before requested termination so a stale exact target cannot produce a partial requested end.
- Renderer readiness is explicit: snapshot callbacks are dropped until the current document sends runtime initialization, after which a fresh full snapshot converges state.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Added zero-identity service APIs outside the listed Task 2/3 files**

- **Found during:** Task 2 exact-action implementation
- **Issue:** The sanitized runtime correctly retained no dashboard session or controller token, so existing token-based service methods could not implement zero-authority stop/end without introducing forbidden WebUI authority.
- **Fix:** Added exact-browser/selected-tab stop, same-window management, and bulk-end entry points to the authoritative supervision profile service; each performs its own regular-profile, active-tab, owner, and exact-binding checks before mutation.
- **Files modified:** `prometheus_supervision_profile_service.h`, `prometheus_supervision_profile_service.cc`
- **Verification:** Exact stop/manage isolation tests and the all-viewer end regression passed; the exported patches reproduce the final nested tree.
- **Committed in:** `391e4e0516`, `c8cc042cc2`

**2. [Rule 1 - Bug] Prevented pre-initialize WebUI callback delivery during reload**

- **Found during:** Task 3 teardown regression
- **Issue:** Reconstructing the side-panel WebUI could publish a native snapshot before the new JavaScript document initialized, tripping Chromium's WebUI weak-lifetime guard.
- **Fix:** Added a per-controller initialization gate, emitted the first full snapshot from the initialize handler, preserved late browser binding, and dropped observer deliveries before readiness.
- **Files modified:** `prometheus_web_ui.h`, `prometheus_web_ui.cc`
- **Verification:** The isolated bulk-end/teardown regression and final five-test runtime suite both passed through reload and a later service notification.
- **Committed in:** `c8cc042cc2`

---

**Total deviations:** 2 auto-fixed (1 missing-critical authority seam, 1 lifecycle bug).
**Impact on plan:** Both fixes were necessary to preserve the planned zero-authority and teardown-safe contracts; no new product surface or authority path was added.

## Issues Encountered

- The initial Task 1 RED fixture inherited a typed-test base and retained an observer across an intentional assertion failure. Correcting the fixture boundary produced the required assertion-only RED result with no crash or infrastructure failure.
- The first Task 3 teardown run exposed the pre-initialize WebUI callback bug above. The focused production compile succeeded, the isolated regression passed after the fix, and the complete runtime suite then passed.

## Test Evidence

- Task 1 RED selected 2 named `SidePanelSupervisionRuntime*` browser tests and failed only their intended unimplemented assertions.
- Task 2 GREEN selected 4 state/action browser tests; all passed for sanitized state, strict messages, exact stop, same-window management, tab/window/OTR isolation, and shutdown behavior.
- Task 3 isolated regression passed for two simultaneous viewers, active control, forged-argument rejection without mutation, transient ending state, exact bulk end, harmless repeat, tab-switch isolation, reload, and post-reload notification.
- Final verification selected all 5 `PrometheusWebUIBrowserTest.SidePanelSupervisionRuntime*` tests; all passed, followed by clean root and nested `git diff --check`.
- Focused verification freshly compiled the browser composition, side-panel runtime, WebUI, and browser-test objects and linked the supervision Blink endpoint.
- Reviewed `.ninja_log`, `.ninja_deps`, Blink dylib, and Blink TOC SHA-256 values remained byte-identical during the final run.
- Patches `0045`, `0046`, and `0047` have stable patch IDs `fec5d133e8b71848001a7319d1a6b714e2783333`, `cd12eab7acb9c559122b03b6be6b3c8a29d0a1b7`, and `ec20be57af7c05b2107513352b805678ed4bce8c`; each matches its nested commit.
- Applying 0045–0047 in order to nested base `14586df967` produced tree `72bb51de5b40c10bfdd4abec366950cfd0a2db68`, exactly matching nested commit `c8cc042cc2`.

Human desktop visual review was not run and remains deferred to the rendered side-panel work in Plan 21-19 and consolidated Phase 24 release review.

## User Setup Required

None. No credentials, packages, listeners, external services, assets, or configuration are required.

## Next Phase Readiness

Plan 21-19 can render the persistent responsive strip directly from the closed `supervision` snapshot and send only the three strict zero-argument intents. It does not need to resolve or retain any native authority.

SUP-01, SUP-03, and SUP-04 remain phase-level in progress until the visible strip, Control Panel lifecycle, built-app smoke, and Phase 21 closeout are complete. No blockers remain.

## Self-Check: PASSED

- FOUND: nested commits `1c641d971b`, `391e4e0516`, and `c8cc042cc2`
- FOUND: root task commits `aa1d6f2cc`, `0e8d554c8`, and `89a6285fb`
- FOUND: ordered patches `0045`, `0046`, and `0047`
- VERIFIED: 2-test RED, 4-test Task 2 GREEN, isolated Task 3 regression, and final 5-test runtime suite
- VERIFIED: exact-tab isolation, zero-authority messages, hostile-title privacy, all-viewer end, teardown safety, patch identity/applicability, and unchanged reviewed build metadata

---
*Phase: 21-supervision-pairing-and-remote-control*
*Completed: 2026-07-24*
