---
phase: 20-fsb-runtime-providers-vault-memory-logs-and-control-panel
plan: 12
subsystem: ui
tags: [chromium, webui, control-panel, providers, diagnostics, accessibility, privacy]

requires:
  - phase: 20-07
    provides: regular-profile runtime, provider execution, and browser-local task authority
  - phase: 20-09
    provides: sanitized runtime/provider/log DTOs and external MCP mutation denial
  - phase: 20-11
    provides: exact-window WebUI runtime bridge and live sanitized task patterns
provides:
  - Exact regular-profile control-panel handler, observer, and validated native mutations
  - Live Tasks, Providers & Models, MCP, Permissions, Logs & Diagnostics operator workflows
  - Automated 320/480/720/1024 responsive, keyboard, state, malformed-input, and disclosure gates
affects: [20-13, 20-14, fsb-control-panel, provider-configuration, runtime-observability]

tech-stack:
  added: []
  patterns:
    - Bind local control authority to one exact regular Profile and WebContents
    - Reconcile renderer workflows from fresh sanitized native snapshots after every mutation
    - Gate unavailable profiles with module-backed load-time data before any chrome.send call
    - Search and render only persisted safe titles and closed metadata fields

key-files:
  created: []
  modified:
    - .context/chromium/src/chrome/browser/prometheus/prometheus_runtime_profile_service.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_provider_registry.cc
    - .context/chromium/src/chrome/browser/ui/webui/prometheus/prometheus_side_panel_runtime.h
    - .context/chromium/src/chrome/browser/ui/webui/prometheus/prometheus_web_ui.cc
    - .context/chromium/src/chrome/browser/ui/webui/prometheus/prometheus_web_ui.h
    - .context/chromium/src/chrome/browser/resources/prometheus/prometheus_control_panel.html
    - .context/chromium/src/chrome/browser/resources/prometheus/prometheus_webui.js
    - .context/chromium/src/chrome/browser/resources/prometheus/prometheus_webui.css
    - .context/chromium/src/chrome/browser/ui/webui/prometheus/prometheus_web_ui_browsertest.cc

key-decisions:
  - "Keep OTR and non-exact control pages handler-free; native load-time availability suppresses renderer initialization and renders a typed unavailable state."
  - "Permit provider mutations only through RuntimeCallerOrigin::kLocalControlUi after exact Profile/WebContents validation; MCP receives LOCAL_UI_REQUIRED without state change."
  - "Treat the native aggregate snapshot as authoritative and refresh it after cancel, provider, discovery, reorder, and log-clear operations."
  - "Keep prompt, page, secret, authorization, endpoint-query, and authority data structurally absent rather than hiding renderer fields."

patterns-established:
  - "Exact control binding: one regular-profile controller owns one opaque native runtime observer and invalidates callbacks at teardown."
  - "Closed operator rendering: tasks, providers, logs, diagnostics, usage, and recovery use bounded textContent-only DTOs."
  - "Responsive control contract: navigation and list/detail forms adapt at exact contract widths while preserving labels, focus, and 48px actions."

requirements-completed: [FSB-05]
requirements-progressed: [FSB-02, FSB-03, FSB-08]

duration: 2h 4m
completed: 2026-07-17
---

# Phase 20 Plan 12: Live Native Control Panel Summary

**The FSB control panel now manages exact-profile native tasks and safe provider metadata, renders content-free logs and diagnostics, and passes serial responsive, keyboard, malformed-input, and privacy gates.**

## Performance

- **Duration:** 2h 4m
- **Started:** 2026-07-17T03:22:39Z
- **Completed:** 2026-07-17T05:27:22Z
- **Tasks:** 3
- **Nested Chromium files modified:** 20 distinct paths
- **Ordered exported patches:** 3 (`0029` through `0031`)

## Accomplishments

- Added one exact regular-profile control runtime and observer with typed cancel, provider save/delete/enable/reorder/discovery, and log-clear operations; OTR receives no native handler.
- Extended provider metadata with validated model, route, fallback, integer rate, trust, health, and discovery state while preserving native-only secrets and stable external MCP denial.
- Replaced shell-ready Tasks, Providers & Models, MCP, Permissions, and Logs & Diagnostics panels with live loading/empty/ready/degraded/error views backed by fresh native snapshots.
- Kept task search limited to persisted `safe_title`, task ID, provider, and model; raw prompts, sensitive URLs, tokens, passwords, page content, endpoint queries, and authority identifiers never enter the snapshot or search index.
- Automated exact 320/480/720/1024 layouts, rail/select adaptation, keyboard navigation, focus return and preservation, reduced motion, confirmations, live announcements, malformed messages, and packaged-resource/content-free boundaries.

## Task Commits

Each Chromium task was committed atomically and immediately exported:

1. **Task 1: Regular-profile control handler and sanitized observer** — `94a6f20b16` (`0029-feat-20-12-bind-local-control-runtime.patch`); root tracker `1bb62b9dd`
2. **Task 2: Live task, provider/model, and log workflows** — `26c97bd4b4` (`0030-feat-20-12-render-live-control-workflows.patch`); root tracker `a0175a351`
3. **Task 3: Responsive, keyboard, state, and content-free gates** — `0f3a2b5511` (`0031-test-20-12-prove-control-panel-boundaries.patch`); root tracker `4bcd70b3e`

## Automated Verification

- Focused production and browser-test C++ translation units compiled successfully using their persisted Ninja commands.
- The exact Prometheus GRIT action and full resource repack succeeded; generated and branded Framework `resources.pak` files matched SHA-256 `a1d576baf8e612d8e32c6783e9d4259ac973207f75c8d30233274b8a4e93be47`.
- The exact complete `browser_tests` link succeeded, the 311,300,752-byte executable was ad-hoc signed, and `codesign --verify` passed.
- The two focused OTR/privacy regressions passed `2/2` serially in 28 seconds with retries disabled.
- Task 2 regressions plus the three Task 3 guards passed `6/6` serially in 69 seconds with retries disabled.
- The complete control-panel list guard selected exactly 11 cases; `PrometheusControlPanelBrowserTest.*` passed `11/11` serially in 140 seconds with retries disabled.
- Exact test-name counts, `node --check`, nested `git diff --check`, no-data-bearing-HTML scans, packaged-resource checks, and recursive prompt/page/secret/ciphertext/auth/session/profile-path assertions passed.
- No human UAT was run; visual review remains intentionally deferred to the non-blocking Phase 24 release review.

## Decisions Made

- The control WebUI uses the same opaque browser-process runtime bridge pattern as the side panel, so renderer code never owns Profile, WebContents, caller, principal, session, or secret authority.
- Native provider validation remains the second boundary after bounded WebUI message validation; hidden controls and crafted messages cannot add secret or authority fields.
- Provider configuration can expose canonical origin and safe endpoint metadata, but query parameters, authorization, ciphertext, and native secret values are omitted from all DTOs.
- Loading and failure states preserve dimensions and announcements; live refresh restores focus by stable safe keys rather than retaining stale renderer objects.
- FSB-05 is complete. FSB-02 remains open for external MCP promotion and final integration, FSB-03 remains open for exact-window native key entry, and FSB-08 remains open for enforced Settings in Plan 20-13.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] OTR renderer initialized an intentionally absent handler**
- **Found during:** Task 3 full 11-case serial gate
- **Issue:** Shared control JavaScript automatically sent `prometheusControlInitialize` in OTR while the native security contract correctly registered zero handlers, causing an unhandled-message crash.
- **Fix:** Published exact runtime availability through `WebUIDataSource`, enabled shared module-safe `strings.m.js`, and rendered a sanitized `TARGET_LOST` error without sending when no exact regular-profile runtime exists.
- **Files modified:** `prometheus_web_ui.cc`, `prometheus_webui.js`, `prometheus_web_ui_browsertest.cc`
- **Verification:** The regular page auto-received `OK`; OTR rendered `error`/`TARGET_LOST`, retained zero handlers, and the focused plus full serial gates passed.
- **Committed in:** `0f3a2b5511`

**2. [Rule 1 - Test bug] Generic security copy caused a false-positive leak assertion**
- **Found during:** Task 3 full 11-case serial gate
- **Issue:** A combined DOM/snapshot scan rejected the generic word `authorization` in truthful security guidance even though no authorization field or value crossed the native boundary.
- **Fix:** Kept exact sensitive-value scanning across snapshot and DOM, while checking forbidden field names as quoted keys only in serialized native snapshot JSON.
- **Files modified:** `prometheus_web_ui_browsertest.cc`
- **Verification:** Exact prompt, URL, token, password, authorization, ciphertext, caller, session, owner, and profile-path sentinels remained absent and both privacy tests passed.
- **Committed in:** `0f3a2b5511`

**Total deviations:** 2 auto-fixed Rule 1 bugs. Both fixes strengthen the intended OTR and structural privacy contracts without scope expansion.

## Issues Encountered

- The mixed Ninja/Siso graph was not cleaned, regenerated, or broadly rebuilt. Validation used focused persisted-source compiles, the exact GRIT/repack commands, the branded Framework resource copy/hash, the exact full browser-test link, and serial filters.
- Early browser assertions were corrected to respect roving-tab `tabindex=-1`, typed model-discovery failure outcomes, Chromium's unsupported renderer fetch of local source files, and the actual `prometheus-control-panel` asset host.
- Browser tests initially exercised stale packed resources and object code; exact repacking, Framework copy, relinking, and ad-hoc signing made every final run consume the current sources.

## User Setup Required

None. Provider secrets remain native-only work for Plan 20-13, and Local continues to require an already-running configured loopback server rather than downloading or launching an engine.

## Next Phase Readiness

- Plan 20-13 can extend the same exact-profile handler and fresh aggregate snapshot with Memory, Site Guides, Vault metadata, enforced Settings, and exact-window native provider/vault dialogs.
- Dependency order remains Plan 20-13, deferred Wave 13 Plan 20-10, then Plan 20-14 final integration and mandatory gates.
- No known blocker remains.

## Self-Check: PASSED

- All three nested task commits have ordered non-empty patches with exact `From` identities, and all three root patch-tracker commits exist.
- The final list guard selected 11 tests, the complete serial run passed 11/11, and the three Task 3 guard names appear exactly once.
- Nested Chromium was clean after `0f3a2b5511`; the root patch ledger was clean after `4bcd70b3e` before this summary.
- Completion tracking advances to dependency-ordered Plan 20-13 at 63/66 plans (95%).

---
*Phase: 20-fsb-runtime-providers-vault-memory-logs-and-control-panel*
*Completed: 2026-07-17*
