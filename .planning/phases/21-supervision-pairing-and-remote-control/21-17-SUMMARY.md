---
phase: 21-supervision-pairing-and-remote-control
plan: 17
subsystem: chromium-native-tab-supervision
tags: [chromium, supervision, tabs, views, accessibility, compact-chrome, tdd]

requires:
  - phase: 21-16
    provides: Fresh authority-free supervision state through the exact browser-owned tab-data lease
  - phase: 15
    provides: Existing compact native tab chrome and noninteractive three-slot status cluster
provides:
  - Live noninteractive supervision badges on every real native Tab
  - Exact action/controller/viewer icon priority with complete sanitized accessibility text
  - Width-aware visual compression that preserves supervision before active Agent, health, and idle ownership
  - Browser regressions for lifecycle, isolation, compressed geometry, close reachability, and active-address stability
affects: [21-18, 21-19, 21-20, 21-22, 21-25, phase-21-supervision]

tech-stack:
  added: []
  patterns:
    - Native tab chrome observes only the existing sanitized tab-state lease and never resolves supervision authority
    - Visual slots compress independently from the complete accessible name and tooltip
    - Tab layout offers only the width between title start and existing alert or close controls

key-files:
  created:
    - .context/chromium/src/chrome/browser/ui/views/prometheus/prometheus_tab_supervision_badge_browsertest.cc
  modified:
    - .context/chromium/src/chrome/browser/ui/views/tabs/prometheus_tab_status_badge.h
    - .context/chromium/src/chrome/browser/ui/views/tabs/prometheus_tab_status_badge.cc
    - .context/chromium/src/chrome/browser/ui/views/tabs/tab.h
    - .context/chromium/src/chrome/browser/ui/views/tabs/tab.cc
    - .context/chromium/src/chrome/browser/ui/views/prometheus/prometheus_compact_chrome_browsertest.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_tab_state.h
    - .context/chromium/src/chrome/browser/prometheus/prometheus_tab_state.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_tab_data.cc
    - .context/chromium/src/chrome/browser/ui/views/prometheus/BUILD.gn
    - .planning/chromium/verify-phase-21.sh

key-decisions:
  - "Compress visual slots in supervision, active-Agent, health, then idle-owner priority while preserving the complete sanitized accessible name."
  - "Derive badge width only from the real Tab title-to-alert/close interval so status changes cannot move or cover native close controls."
  - "Keep active remote action indication steady and noninteractive; no animation, authority action, menu, or event target belongs in the tab badge."

patterns-established:
  - "Display-only compression: hidden visual clauses remain present in the accessible name and tooltip."
  - "Geometry isolation: the badge consumes only spare title width and never changes tab height, close-button bounds, or active-address geometry."

requirements-completed: []
requirements-progressed: [SUP-01, SUP-04]

duration: 1h45min active
completed: 2026-07-24
---

# Phase 21 Plan 17: Native Tab Supervision Badge Summary

**Every real Chromium tab now renders fresh, sanitized supervision state through a noninteractive three-slot badge that remains accessible and geometry-safe under severe compression.**

## Performance

- **Duration:** 1h45min active across interrupted and resumed execution
- **Started:** 2026-07-22T18:05:50Z
- **Completed:** 2026-07-24T11:21:58Z
- **Tasks:** 3
- **Files modified:** 11 source, test, build, and verifier files; 3 ordered patch exports

## Accomplishments

- Locked exact owner/Agent, viewer, controller, remote-action, and health icon/name behavior with content-free recursive privacy and event-transparency checks.
- Connected one persistent badge to every real `Tab` through the exact browser-owned `PrometheusTabStateObservation`, including live transitions, terminal clear, replacement, and exact-tab isolation.
- Added width-aware slot compression that preserves supervision first, active Agent second, health third, and idle ownership last while retaining the complete accessible name.
- Preserved tab height, close-button bounds/reachability, title separation, and active-address bounds at normal and severe tab compression.
- Kept active-action presentation steady and reduced-motion-safe, with no badge event handler, menu, authority action, or new asset.

## Task Commits

Each task was committed atomically in nested Chromium and exported into the root patch chain:

1. **Task 1 (RED): Lock icon priority and complete accessible-name semantics** — nested `c6c9e3913e`, root `4bfc1728d`, patch `0042`
2. **Task 2 (GREEN): Render Phase 21 states and wire the badge into real Tab instances** — nested `622937c71e`, root `5ab090ff5`, patch `0043`
3. **Task 3 (GREEN): Preserve compression, tab geometry, and accessibility** — nested `14586df967`, root `c64a7f8f7`, patch `0044`

## Files Created/Modified

- `prometheus_tab_supervision_badge_browsertest.cc` — Exact icon/name, privacy, event-transparency, live-tab lifecycle, isolation, compression, and native geometry coverage.
- `prometheus_tab_status_badge.h/.cc` — Live tab-state observation, closed icon/name rendering, visual compression priority, minimum/preferred sizing, and steady action tile.
- `tab.h/.cc` — One real badge child per tab plus width allocation that respects title, alert, and close-button geometry.
- `prometheus_tab_state.h/.cc` and `prometheus_agent_tab_data.cc` — Observation availability and the authority-free display projection consumed by the badge.
- `prometheus_compact_chrome_browsertest.cc` — Deterministic compact-chrome fixture setup for the focused geometry regression.
- `chrome/browser/ui/views/prometheus/BUILD.gn` — Browser-test source registration.
- `.planning/chromium/verify-phase-21.sh` — Exact badge/compression/motion guards and fresh compact/badge test-object compilation.
- Patches `0042` through `0044` — Stable ordered nested Chromium exports.

## Decisions Made

- Slot visibility is a visual-only concern. Compression never rewrites or removes true accessibility clauses.
- Supervision wins the final visual slot; active Agent wins the second; health wins the third; idle owner is the first state elided.
- Real tab layout computes available badge width before title sizing and never borrows space from alert or close controls.
- `kCircleNodes` on the existing accent-soft tile is a steady state, not an animation.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Ran the actual compact-chrome fixture omitted by the planned filter**

- **Found during:** Task 3 final plan verification
- **Issue:** The plan filter names `PrometheusCompactChromeBrowserTest.*`, but the registered fixture is `PrometheusCompactChromeLayoutBrowserTest.*`; the literal plan command therefore selected only the badge suite.
- **Fix:** Retained the exact planned run, then separately ran the real compact-layout fixture and required a nonempty two-test selection.
- **Files modified:** None; verification correction only.
- **Verification:** All 8 badge tests and both compact-layout tests passed.
- **Committed in:** N/A

---

**Total deviations:** 1 auto-fixed missing-critical verification gap.
**Impact on plan:** Verification was strengthened without changing production scope or authority boundaries.

## Issues Encountered

- Execution was interrupted after Tasks 1 and 2. Safe-resume recovery preserved both nested/root commit pairs, audited the partial Task 3 diff, and completed only the remaining compression, geometry, verification, and export work.
- The generic `git cl format --diff` path was unavailable outside the configured depot-tools environment; a whole-file formatter attempt was compared against the saved task diff and fully restored before commit. Final nested and root diffs passed their applicable whitespace checks.

## Test Evidence

- Retained Task 1 RED coverage selected the new badge contract and failed only on unimplemented behavior before the GREEN commit.
- The final planned filter selected 8 runnable `PrometheusTabSupervisionBadgeBrowserTest` cases; all passed.
- The corrected `PrometheusCompactChromeLayoutBrowserTest.*` filter selected 2 runnable compact-chrome cases; both passed.
- Browser tests cover exact 12px slots/4px gaps, action/controller/viewer priority, singular/plural phrasing, ordered accessible names, recursive sentinel rejection, event transparency, live replacement/terminal clear, exact-tab isolation, width-by-width compression, and real close/title/address geometry.
- Static guards reject service/factory/lease/code/session/document/target/content access and any `gfx::Animation`, throb, or pulse path in the badge.
- Root and nested source diffs passed `git diff --check`; the exported patch is intentionally validated as a patch artifact rather than as newly added source text.
- Patches `0042`, `0043`, and `0044` have stable patch IDs `d56651c8e67cd8bfe86c00e586b2f4b7fd5f06a2`, `2a380540d39aab5792509ecc45c6eafe19f357d6`, and `39a88e59a7ad2e6ddc01306816b39868792d1030`; each matches its nested commit.
- Patch `0044` is nonempty, source-only, reverse-applies to the current nested tree, and applies cleanly to nested commit `14586df967^`.
- Reviewed `.ninja_log`, `.ninja_deps`, Blink dylib, and Blink TOC hashes remained byte-identical in both final browser-verification runs.

Human desktop visual review was not run and remains deferred to the consolidated Phase 24 release review.

## User Setup Required

None. No credentials, listeners, external services, assets, or configuration are required.

## Next Phase Readiness

Plan 21-18 can consume the same fresh browser-owned supervision state for the native/WebUI control surface without resolving tab, session, controller, or document authority inside the UI.

SUP-01 and SUP-04 remain phase-level in progress until the side-panel/Control Panel consumers, built-app smoke, and Phase 21 closeout are complete. No blockers remain.

## Self-Check: PASSED

- FOUND: nested commits `c6c9e3913e`, `622937c71e`, and `14586df967`
- FOUND: root task commits `4bfc1728d`, `5ab090ff5`, and `c64a7f8f7`
- FOUND: ordered patches `0042`, `0043`, and `0044`
- VERIFIED: 8-test complete badge suite and 2-test actual compact-layout suite
- VERIFIED: compression priority, complete accessibility, exact-tab lifecycle, native geometry, privacy, no-motion contract, patch identity/applicability, and unchanged reviewed build metadata

---
*Phase: 21-supervision-pairing-and-remote-control*
*Completed: 2026-07-24*
