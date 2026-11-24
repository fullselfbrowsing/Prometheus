---
phase: 21-supervision-pairing-and-remote-control
plan: 19
subsystem: chromium-side-panel-supervision-strip
tags: [chromium, supervision, side-panel, webui, responsive, privacy, tdd]

requires:
  - phase: 21-18
    provides: Sanitized exact-tab supervision runtime and zero-authority native actions
  - phase: 21-17
    provides: Live browser-owned supervision projection and native tab badge
provides:
  - Persistent side-panel supervision strip below the four-mode navigation
  - Exact closed viewer, access, and activity copy from the sanitized Plan 18 snapshot
  - Immediate stop, safe end confirmation, and same-window management actions
  - Responsive 320px through 1024px and 200-percent zoom behavior with 48px controls
  - Keyboard, focus, live-region, hostile-data, and zero-argument action regressions
affects: [21-20, 21-21, 21-22, 21-25, phase-21-supervision]

tech-stack:
  added: []
  patterns:
    - Renderer presentation re-whitelists the closed native snapshot before touching the DOM
    - Supervision actions carry zero renderer arguments and preserve focus across native state changes
    - Focused browser verification rebuilds GRIT and replays Chromium's canonical full resource repack

key-files:
  created: []
  modified:
    - .context/chromium/src/chrome/browser/resources/prometheus/prometheus_side_panel.html
    - .context/chromium/src/chrome/browser/resources/prometheus/prometheus_webui.js
    - .context/chromium/src/chrome/browser/resources/prometheus/prometheus_webui.css
    - .context/chromium/src/chrome/browser/ui/webui/prometheus/prometheus_web_ui_browsertest.cc
    - .planning/chromium/verify-phase-21.sh

key-decisions:
  - "Keep the supervision strip outside the mode stack and directly between navigation and mode content so it persists across all four modes without becoming a fifth mode."
  - "Render only re-whitelisted Plan 18 display fields with textContent and fixed fallbacks; renderer-injected authority, URLs, paths, selectors, raw values, and secret-shaped labels remain absent."
  - "Send stop, end, and manage as zero-argument intent messages; End is emitted exactly once only after the safe browser-titled confirmation."
  - "Temporarily install a freshly repacked complete framework resource bundle for focused tests, then restore and hash-check the reviewed package."

patterns-established:
  - "Persistent closed-state surface: zero viewers removes the strip completely; any live viewer keeps one stable strip across all four side-panel modes."
  - "Safe destructive dialog: bounded browser-owned title copy, Keep access initial focus, no message on cancel/Escape/programmatic close, and one message on confirmation."
  - "Embedded-WebUI zoom testing: use HostZoomMap temporary zoom because top-chrome WebUI intentionally disables normal ZoomController mutation."

requirements-completed: []
requirements-progressed: [SUP-01, SUP-03, SUP-04]

duration: 1h37min
completed: 2026-07-24
---

# Phase 21 Plan 19: Persistent Responsive Supervision Strip Summary

**The side panel now keeps a sanitized supervision strip visible below its four-mode navigation, with exact state copy, zero-authority actions, safe confirmation, and responsive keyboard-accessible behavior.**

## Performance

- **Duration:** 1h37min
- **Started:** 2026-07-24T13:24:39Z
- **Completed:** 2026-07-24T15:01:21Z
- **Tasks:** 3
- **Files modified:** 5 source, test, and verifier files; 3 ordered patch exports

## Accomplishments

- Added one semantic strip directly after the four-mode navigation and before mode content; it persists across FSB Agent, Explorer, Tabs, and Tools and is structurally absent when no viewer exists.
- Rendered exact viewer count, view-only or controlled access, the closed activity vocabulary, and fixed remote-action categories from a second renderer-side whitelist of the Plan 18 snapshot.
- Rejected controls, bidi overrides, URLs, paths, query/fragment shapes, secret/authority terms, overlong labels, and every unrecognized snapshot field before presentation.
- Implemented immediate duplicate-safe Stop control, zero-argument Manage access, and a safe End supervision dialog whose cancel, Escape, and programmatic-close paths send nothing.
- Preserved keyboard focus when Stop removes its own control, when End is cancelled, and when successful ending removes the strip; exposed polite and assertive live regions for state and authority changes.
- Made the strip and all actions fit 320, 480, 720, and 1024 CSS-pixel widths and 200-percent zoom without page overflow, clipping, overlap, or sub-48px controls.
- Extended focused Chromium verification so current HTML, JavaScript, and CSS are built through GRIT, inserted into Chromium's exact full framework resource repack, tested, restored, and hash-audited.

## Task Commits

Each TDD task was committed atomically in nested Chromium and exported into the root patch chain:

1. **Task 1 (RED): Specify persistent supervision strip behavior** — nested `6f57006736`, root `a835a8010`, patch `0048`
2. **Task 2 (GREEN): Render sanitized persistent state and zero-authority actions** — nested `49ae2e5dbc`, root `d934b892e`, patch `0049`
3. **Task 3 (HARDEN): Prove responsive layout, keyboard flow, and hostile-data privacy** — nested `344499e3f7`, root `fbe26be66`, patch `0050`

## Files Created/Modified

- `prometheus_side_panel.html` — Persistent semantic strip template, stable state/action order, live regions, and safe End supervision dialog.
- `prometheus_webui.js` — Closed snapshot normalizer, fixed copy mapping, text-only rendering, zero-argument messages, duplicate guards, dialog behavior, and focus restoration.
- `prometheus_webui.css` — Flat responsive strip layout, wrapping metadata, one-column full-width actions, 48px targets, and visible focus behavior.
- `prometheus_web_ui_browsertest.cc` — Full state vocabulary, all four modes, action/focus semantics, 320–1024 widths, 200-percent zoom, privacy sentinels, and dialog cancellation coverage.
- `.planning/chromium/verify-phase-21.sh` — Strip/static privacy guards plus fresh GRIT and exact framework resource repack for focused browser tests.
- `patches/0048` through `0050` — Stable ordered nested Chromium patch exports.

## Decisions Made

- The strip is persistent chrome for the side panel, not a fifth selectable mode. Its DOM position is always navigation, strip, then the current mode stack.
- Native Plan 18 remains the only state authority. JavaScript copies only its closed display fields into a new object and never retains sessions, leases, target IDs, tab authority, selectors, content, or raw action values.
- All dynamic copy uses `textContent`; no HTML sink or remote resource is permitted in the strip path.
- Stop is intentionally immediate, while End is the only destructive strip action requiring confirmation. The dialog uses only `safe_target_title`, focuses Keep access first, and emits one zero-argument message only from confirmation.
- At 320px, action buttons match the action grid's actual content edges rather than the strip border box; this proves full usable width without confusing padding and borders.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Loaded current resources into the focused browser binary**

- **Found during:** Task 2 GREEN verification
- **Issue:** The focused C++ relink still loaded the previously packaged framework `resources.pak`, so new side-panel HTML, JavaScript, and CSS were not under test.
- **Fix:** Added a direct GRIT build, checked generated resource IDs against the reviewed header, replayed Chromium's exact canonical full repack command with only the Prometheus component replaced, temporarily installed the result, and restored the original package in the exit trap.
- **Files modified:** `.planning/chromium/verify-phase-21.sh`
- **Verification:** Current strip resources were observed by the focused suite, and the framework package hash matched before and after every final run.
- **Committed in:** `d934b892e`

**2. [Rule 1 - Bug] Used the supported zoom path for embedded top-chrome WebUI**

- **Found during:** Task 3 full responsive verification
- **Issue:** Side-panel top-chrome WebUI deliberately disables normal `ZoomController::SetZoomLevel`, so the original 200-percent wait could never complete.
- **Fix:** Applied temporary frame zoom through `HostZoomMap`, retained the exact 200-percent assertion, and restored 100 percent afterward.
- **Files modified:** `prometheus_web_ui_browsertest.cc`
- **Verification:** The responsive test reached and passed the 200-percent geometry checks without timeout.
- **Committed in:** `344499e3f7`

**3. [Rule 1 - Bug] Compared full-width actions with their actual layout container**

- **Found during:** Task 3 full responsive verification
- **Issue:** The initial 320px assertion compared button content width to the strip border box with a one-pixel-wrong allowance for padding and borders, rejecting correctly full-width controls.
- **Fix:** Compared every button's left and right edges directly with the action grid and exposed named issue strings in failures.
- **Files modified:** `prometheus_web_ui_browsertest.cc`
- **Verification:** The final responsive test passed at 320, 480, 720, and 1024 CSS pixels and at 200-percent zoom.
- **Committed in:** `344499e3f7`

---

**Total deviations:** 3 auto-fixed (1 missing-critical resource verification path, 2 test bugs).
**Impact on plan:** The fixes made the planned browser/layout evidence real and deterministic without expanding product behavior or renderer authority.

## Issues Encountered

- The first RED browser fixture attempted to inspect missing nodes as if the strip already existed. It was tightened to report ordinary expectation failures for the intended missing behavior, with no crash or infrastructure failure.
- Two Task 3 verification iterations exposed the disabled top-chrome zoom path and the border-box/content-box mismatch above. Both failures occurred in test infrastructure; protected artifacts were restored after each run.

## Test Evidence

- Task 1 RED selected exactly 3 `SidePanelSupervisionStrip*` browser tests and failed only their intended unimplemented assertions.
- Task 2 GREEN selected the 2 state/action tests; both passed with exact copy, persistent mode behavior, immediate Stop, safe End confirmation, Manage access, duplicate suppression, and focus restoration.
- Final verification selected all 3 `PrometheusWebUIBrowserTest.SidePanelSupervisionStrip*` tests; all passed, followed by clean root and nested `git diff --check`.
- Responsive coverage passed at 320, 480, 720, and 1024 CSS pixels and at 200-percent zoom with no page overflow, strip/content overlap, clipped controls, unreachable actions, or targets below 48px.
- Hostile renderer fields, URLs, secrets, selectors, sessions, leases, and raw values were absent from the normalized snapshot, strip DOM, accessibility attributes, and End dialog.
- End cancel, Escape, and programmatic close produced zero authority messages; confirmation produced exactly one `prometheusEndSelectedTabSupervision` message with zero arguments.
- Final reviewed hashes remained byte-identical: `.ninja_log` `eccf79f3dfdc6c8d51af20f56bf1973eb35ff486b1dab9b2b0653cc37b586dce`, `.ninja_deps` `ab1a6ad4639e8db53459384f8636dc53f396397363f3c2751bcdadc0349947c0`, Blink dylib `663af12ba1a986db789c4c05967dda8b3b3615030e6cecb569de0f74ba01ff8e`, Blink TOC `bdc164a10b8616fa099b089a1f4542c789a584c84212b0f4d92b616701a3ce9b`, and framework `resources.pak` `c9c541d780ad9c0054eaec0abd8453703972ebcc3ce3607d06e3c80e5a8f79ff`.
- Patches `0048`, `0049`, and `0050` have stable patch IDs `3024e7bb96eb82ecc5a46205b85ef61e0f6165e7`, `965891cd558ae8a7ddde87b039cc3295063deff8`, and `0f25139055595ca9b9d2a84e6c676d0a2a5e5065`; each matches its nested commit.
- Applying `0048–0050` in order to nested base `c8cc042cc2` produced tree `c49f758742b25fb571aa659b24b2bf2e4f779549`, exactly matching nested commit `344499e3f7`.

Human desktop visual review remains deferred to the consolidated Phase 24 release review; automated real-browser geometry and accessibility evidence is complete for this plan.

## User Setup Required

None. No credentials, packages, listeners, external services, assets, or configuration are required.

## Next Phase Readiness

Plan 21-20 can build strict Control Panel supervision snapshots and one-shot pairing creation on the now-visible side-panel lifecycle without changing the strip's zero-authority boundary.

SUP-01, SUP-03, and SUP-04 remain phase-level in progress until Control Panel lifecycle/UI, built-app smoke, and Phase 21 closeout are complete. No blockers remain.

## Self-Check: PASSED

- FOUND: nested commits `6f57006736`, `49ae2e5dbc`, and `344499e3f7`
- FOUND: root task commits `a835a8010`, `d934b892e`, and `fbe26be66`
- FOUND: ordered patches `0048`, `0049`, and `0050`
- VERIFIED: 3-test RED, 2-test Task 2 GREEN, and final 3-test full strip suite
- VERIFIED: responsive layout, keyboard/focus behavior, hostile-data privacy, zero-argument actions, resource freshness, patch identity/replay, and unchanged reviewed build metadata

---
*Phase: 21-supervision-pairing-and-remote-control*
*Completed: 2026-07-24*
