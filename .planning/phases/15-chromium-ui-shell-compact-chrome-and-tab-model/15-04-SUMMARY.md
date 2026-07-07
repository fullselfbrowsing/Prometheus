---
phase: 15-chromium-ui-shell-compact-chrome-and-tab-model
plan: 04
subsystem: ui
tags: [chromium, tabs, tab-state, badges, prometheus]
requires:
  - phase: 15
    plan: 02
    provides: Compact chrome layout allocation helper
  - phase: 15
    plan: 03
    provides: Native side-panel and Ask FSB toolbar entry points
provides:
  - Safe Prometheus tab state stub
  - Compact tab status badge view
  - Unit coverage proving WebContents user data is not trusted in Phase 15
affects: [phase-15, chromium-ui, tabs, agent-status]
tech-stack:
  added: []
  patterns:
    - Safe default state helpers before Phase 17 agent runtime integration
    - Standalone Views badge controls that can be integrated into tab layout later
key-files:
  created:
    - .context/chromium/src/chrome/browser/prometheus/prometheus_tab_state.h
    - .context/chromium/src/chrome/browser/prometheus/prometheus_tab_state.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_tab_state_unittest.cc
    - .context/chromium/src/chrome/browser/ui/views/tabs/prometheus_tab_status_badge.h
    - .context/chromium/src/chrome/browser/ui/views/tabs/prometheus_tab_status_badge.cc
  modified:
    - .context/chromium/src/chrome/browser/prometheus/BUILD.gn
    - .context/chromium/src/chrome/browser/ui/BUILD.gn
key-decisions:
  - "Phase 15 tab state always returns `PrometheusTabState::SafeDefault()` and ignores `WebContents` user data until Phase 17 owns authenticated agent/session state."
  - "The badge view is integration-ready but not wired into live tab layout in this plan, preserving tab layout behavior while exposing a compiled Views primitive."
  - "`prometheus_unittests` now uses `//content/test:run_all_unittests` because the tab-state trust test constructs real `WebContents` test infrastructure."
patterns-established:
  - "Prometheus status affordances should expose exact UI-SPEC accessibility phrases even when the visual glyph set is compact."
requirements-completed: [UX-04, UX-06]
duration: 8min
completed: 2026-07-07
---

# Phase 15 Plan 04: Tab State and Status Badge Summary

**Safe tab/session state defaults plus compact status badge primitives**

## Performance

- **Duration:** 8 min
- **Started:** 2026-07-07T06:05:00Z
- **Completed:** 2026-07-07T06:12:54Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments

- Added `PrometheusTabState` with safe default owner, automation, supervision, and health fields.
- Added `GetPrometheusTabStateForWebContents(content::WebContents*)`, returning safe defaults in Phase 15.
- Added unit tests for safe defaults and a real `WebContents` user-data trust boundary.
- Added `PrometheusTabStatusBadge`, a compact Views control that can render owner/automation, supervision, and health warning glyphs.
- Added exact accessibility strings for `No agent owns this tab`, `Owned by %1`, `Agent is working in this tab`, `Supervision active`, `Tab health OK`, and `Tab needs attention`.
- Wired the badge view into the active Chromium UI GN target.

## Task Commits

Each task was committed atomically in the Chromium checkout:

1. **Task 1: Add safe tab state model** - `46e2f05ccc`
2. **Task 2: Add compact tab status badge view** - `3d6d00b3b6`

## Files Created/Modified

- `.context/chromium/src/chrome/browser/prometheus/prometheus_tab_state.h` - Declares the safe tab state model and lookup API.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_tab_state.cc` - Returns safe defaults for all Phase 15 lookups.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_tab_state_unittest.cc` - Covers safe defaults and ignores arbitrary `WebContents` user data.
- `.context/chromium/src/chrome/browser/prometheus/BUILD.gn` - Adds the tab-state source set, unit test, and content unit-test runner support.
- `.context/chromium/src/chrome/browser/ui/views/tabs/prometheus_tab_status_badge.h` - Declares the compact badge view.
- `.context/chromium/src/chrome/browser/ui/views/tabs/prometheus_tab_status_badge.cc` - Implements glyph visibility and accessibility phrase composition.
- `.context/chromium/src/chrome/browser/ui/BUILD.gn` - Adds the badge view sources and Prometheus dependencies to the active UI target.

## Decisions Made

- Kept Phase 15 tab ownership intentionally empty and non-authoritative until Phase 17 introduces authenticated native agent state.
- Used existing Prometheus action icons: `kBolt` for owner/automation, `kShield` for supervision, and `kTriangleExclamation` for health attention.
- Used `kColorPrometheusAccent` for compact status glyph foregrounds so the badge consumes Phase 14 tokens.

## Deviations from Plan

- The plan referenced `chrome/browser/ui/views/tabs/BUILD.gn`, which does not exist in this checkout. The active GN owner for tab view sources is `chrome/browser/ui/BUILD.gn`.
- `prometheus_unittests` changed from `//base/test:run_all_unittests` to `//content/test:run_all_unittests` so the `WebContents` user-data test initializes content/Mojo correctly.

## Issues Encountered

- The first `WebContents` unit test crashed under the base test runner because Mojo was not initialized. Switching the test binary to the content unit-test runner fixed the harness without weakening the trust-boundary test.

## Verification

- `PATH=".context/depot_tools:$PATH" DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer autoninja -C out/Default prometheus_unittests` - passed.
- `./out/Default/prometheus_unittests --gtest_filter='*PrometheusTabState*'` - passed, 2/2 tests.
- `PATH=".context/depot_tools:$PATH" DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer autoninja -C out/Default chrome` - passed.
- `PATH=".context/depot_tools:$PATH" DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer autoninja -C out/Default prometheus_unittests chrome` - passed, no work remaining.
- `git -C .context/chromium/src diff --check` - passed.
- Acceptance marker scan confirmed `struct PrometheusTabState`, `SafeDefault`, `SafeDefaultHasNoOwner`, `DoesNotTrustCallerProvidedLabel`, `class PrometheusTabStatusBadge`, `No agent owns this tab`, `Supervision active`, and `kColorPrometheusAccent`.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 15-05 can add tab search/overview wiring while relying on safe Prometheus tab status defaults and the compiled badge primitive.

---
*Phase: 15-chromium-ui-shell-compact-chrome-and-tab-model*
*Completed: 2026-07-07*
