---
phase: 20-fsb-runtime-providers-vault-memory-logs-and-control-panel
plan: 11
subsystem: ui
tags: [chromium, webui, side-panel, runtime, accessibility, privacy]

requires:
  - phase: 20-07
    provides: browser-local move-only runtime principals and exact-target authority
  - phase: 20-09
    provides: persisted sanitized runtime tasks, events, results, and usage
provides:
  - Exact-window SidePanelWebUIViewT/WebUIContentsWrapperT ownership
  - Live FSB composer, sanitized task snapshots, cancellation, provenance, results, and recovery
  - Automated 300/320 responsive, keyboard, lifecycle, malformed-message, restart, and privacy gates
affects: [20-12, 20-13, 20-14, fsb-side-panel, runtime-webui]

tech-stack:
  added: []
  patterns:
    - Exact Browser and stable-tab authority retained outside renderer values
    - Observer-driven sanitized native snapshots rendered only with textContent
    - Replacement WebUI controllers recover only the persisted embedding context

key-files:
  created:
    - .context/chromium/src/chrome/browser/ui/webui/prometheus/prometheus_side_panel_runtime.cc
    - .context/chromium/src/chrome/browser/ui/webui/prometheus/prometheus_side_panel_runtime.h
  modified:
    - .context/chromium/src/chrome/browser/ui/views/prometheus/prometheus_side_panel_helper.cc
    - .context/chromium/src/chrome/browser/ui/webui/prometheus/prometheus_web_ui.cc
    - .context/chromium/src/chrome/browser/resources/prometheus/prometheus_side_panel.html
    - .context/chromium/src/chrome/browser/resources/prometheus/prometheus_webui.js
    - .context/chromium/src/chrome/browser/resources/prometheus/prometheus_webui.css
    - .context/chromium/src/chrome/browser/ui/webui/prometheus/prometheus_web_ui_browsertest.cc

key-decisions:
  - "Keep one move-only local runtime principal in native side-panel controller state; never serialize caller, Agent session, owner, or principal identity."
  - "Break the WebUI/runtime dependency cycle with an opaque PrometheusSidePanelRuntime factory; keep the concrete service/principal bridge in browser main extra parts."
  - "Use RuntimeStore as the persisted task/result authority and merge only provider/route metadata from the in-memory service record."
  - "Rebind a controller created by renderer reload from WebUI embedding context, never from a global or last-active Browser lookup."

patterns-established:
  - "Exact-window WebUI: embedding context supplies the originating Browser while stable tab identity is revalidated for every native operation."
  - "Sanitized task UI: native safe_title/provenance/state/result values cross the WebUI boundary; raw prompts remain drafts only and clear after acceptance."
  - "Bounded automation: browser guards use native RunUntil waits, serial execution, and retries disabled for lifecycle-sensitive assertions."

requirements-completed: [FSB-01]
requirements-progressed: [FSB-02, FSB-05, FSB-08]

duration: 1h 58m commit window
completed: 2026-07-16
---

# Phase 20 Plan 11: Exact-window Live FSB Side Panel Summary

**An exact-window Chromium side panel now submits through one private native principal, renders sanitized live runtime state, and passes automated responsive, keyboard, lifecycle, and privacy gates.**

## Performance

- **Tracked commit window:** 2026-07-16T20:09:30-05:00 to 2026-07-16T22:07:05-05:00
- **Tasks:** 3
- **Nested Chromium files modified:** 18 distinct paths
- **Ordered exported patches:** 3 (`0026` through `0028`)

## Accomplishments

- Replaced raw side-panel hosting with `SidePanelWebUIViewT` and `WebUIContentsWrapperT`, permanently retaining the originating Browser/Profile/stable tab across focus changes.
- Acquired exactly one move-only browser-local principal per regular side panel, with observer teardown, task cancellation, session close, and ownership release kept native and exactly-once.
- Delivered the Auto/Provider/Local composer, Ask FSB draft seed, provider metadata, sanitized task timeline, truthful states, cancellation confirmation, bounded results, provenance, usage, and typed recovery.
- Proved persisted `safe_title` survives reload while raw URL/token/password text and caller/session/principal/owner identifiers remain absent from snapshots and DOM.
- Automated 300px and 320px layout, 48px targets, roving keyboard focus, Cmd+Enter submission, dialog focus return, malformed messages, duplicate mutations, reload, all runtime states, and no-engine/no-remote-resource gates.

## Task Commits

Each Chromium task was committed atomically and immediately exported:

1. **Task 1: Exact-window WebUI ownership** — `2a5b34a410` (`0026-feat-20-11-bind-side-panel-to-exact-window.patch`); root tracker `74371bfd2`
2. **Task 2: Live composer and sanitized runtime state** — `45d3d2bc1a` (`0027-feat-20-11-wire-live-side-panel-runtime.patch`); root tracker `92a93703b`
3. **Task 3: Responsive, keyboard, lifecycle, and privacy gates** — `33bae0de39` (`0028-test-20-11-automate-side-panel-runtime-gates.patch`); root tracker `e313ae61d`

## Automated Verification

- Focused modified C++ translation units compiled successfully using their existing Ninja commands.
- Prometheus grit resources were regenerated, aggregate resources were repacked, and the branded framework copy matched the generated pack hash.
- Task 2 Runtime and AskFsb guards passed `2/2` serially with retries disabled.
- The complete `PrometheusWebUIFoundationBrowserTest.*` list guard selected exactly 10 cases and passed `10/10` serially in 140 seconds with retries disabled.
- The responsive guard exercised real 300px and 320px WebContents sizes with no horizontal overflow and all tested interactive targets at least 48px high.
- `node --check`, `git diff --check`, and static no-remote/no-engine/no-secret/no-native-identity resource scans passed.
- No human UAT was run.

## Decisions Made

- Plan 11 completes FSB-01. FSB-02 remains open until external MCP promotion and final integration, FSB-05 remains open until full logs/diagnostics UI, and FSB-08 remains open until settings surfaces are live.
- Runtime observer callbacks originate from persisted store changes, so WebUI state is reconciled from native truth instead of optimistic renderer state.
- Cancellation follows the store's legal `queued/running/waiting -> cancelling -> cancelled` transition and still records one native finish.
- Provider labels, kinds, route classes, health, and model IDs are renderer-safe metadata; credentials, raw authorization failures, and endpoints remain excluded.
- Renderer reload creates a fresh controller/principal but binds it through the same WebUI embedding context; it cannot acquire against another active window.

## Deviations from Plan

### Auto-fixed Issues

**1. Legal persisted cancellation transition**
- **Found during:** Task 2 cancellation browser guard
- **Issue:** The service attempted `queued -> cancelled` directly, which the persisted runtime store correctly rejected.
- **Fix:** Transitioned through `cancelling` and passed the returned generation into the exactly-once terminal finish.
- **Verification:** Cancellation accepted, rendered `Cancelled`, survived refresh, and `finish_count_for_testing` remained one.
- **Committed in:** `45d3d2bc1a`

**2. Replacement WebUI controller exact-window binding**
- **Found during:** Task 3 sanitized restart guard
- **Issue:** Renderer reload replaced the WebUI controller, while the initial helper-only Browser injection did not run again.
- **Fix:** A replacement controller reads the already-persisted exact Browser from WebUI embedding context; no global or last-active lookup was added.
- **Verification:** The reload guard passed with one new principal and the persisted sanitized title.
- **Committed in:** `33bae0de39`

**3. [Rule 3 - Blocking] Split the native runtime target to avoid a dependency cycle**
- **Found during:** Task 1 exact-window host integration
- **Issue:** Directly coupling `prometheus_web_ui.cc` to `PrometheusRuntimeProfileService` would create a Chromium target cycle and expose native authority concerns to the WebUI target.
- **Fix:** Added an opaque `PrometheusSidePanelRuntime` interface/factory in the WebUI layer and registered its concrete service/principal bridge from `prometheus_browser_main_extra_parts.cc`.
- **Verification:** The historical plan key link now follows the concrete bridge, `gsd-tools verify key-links` passes all links, and no principal/session/owner identity crosses the opaque interface.
- **Committed in:** `2a5b34a410` and `45d3d2bc1a`

**Total deviations:** 3 auto-fixed issues (two correctness fixes and one blocking target-graph split). All preserve the plan's authority and privacy boundaries without scope expansion.

## Issues Encountered

- Browser tests initially loaded an older branded framework resource pack. The focused grit output was repacked and copied to the exact framework resource path used by the test process.
- A cancellation fix initially appeared stale because the temporary browser-test executable predated the directly linked service object. Relinking that focused executable exposed the corrected code and the guard passed.
- The mixed Ninja/Siso graph was not cleaned or regenerated. Validation used focused direct translation-unit compiles, the single grit action, exact resource repacking, focused full links, and serial filtered browser tests.

## User Setup Required

None. Local mode continues to use an already-running configured loopback provider and does not download or launch a model server.

## Next Phase Readiness

- Dependency order is Plan 20-12, Plan 20-13, deferred Wave 13 Plan 20-10, then Plan 20-14; all can consume the exact-window side-panel runtime and its sanitized observer contract.
- No known blocker remains; both the nested Chromium repository and root patch ledger are expected to be clean after this summary commit.

## Self-Check: PASSED

- Requirement metadata records FSB-01 complete and FSB-02, FSB-05, and FSB-08 progressed but still open.
- Plan artifacts and key links follow the opaque WebUI runtime/concrete browser-main bridge split.
- Completion tracking advances to dependency-ordered Plan 20-12 at 62/66 plans (94%).

---
*Phase: 20-fsb-runtime-providers-vault-memory-logs-and-control-panel*
*Completed: 2026-07-16*
