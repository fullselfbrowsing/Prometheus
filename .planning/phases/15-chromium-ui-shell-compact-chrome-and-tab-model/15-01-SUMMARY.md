---
phase: 15-chromium-ui-shell-compact-chrome-and-tab-model
plan: 01
subsystem: ui
tags: [chromium, views, prefs, compact-chrome, prometheus]
requires:
  - phase: 14-asset-and-design-system-port
    provides: Prometheus Chromium source targets and design-system assets
provides:
  - Prometheus compact/separate chrome mode enum and PrefService helpers
  - Registered profile pref for `prometheus.chrome.mode`
  - Unit coverage for parsing, serialization, fallback, and pref round-trip behavior
affects: [phase-15, phase-16, phase-17, chromium-ui]
tech-stack:
  added: []
  patterns:
    - Chromium PrefService string pref wrapped by typed Prometheus helper
key-files:
  created:
    - .context/chromium/src/chrome/browser/prometheus/prometheus_chrome_mode.h
    - .context/chromium/src/chrome/browser/prometheus/prometheus_chrome_mode.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_chrome_mode_unittest.cc
  modified:
    - .context/chromium/src/chrome/browser/prometheus/BUILD.gn
    - .context/chromium/src/chrome/common/pref_names.h
    - .context/chromium/src/chrome/browser/prefs/browser_prefs.cc
key-decisions:
  - "Separate remains the safe default for `prometheus.chrome.mode`."
  - "Unknown persisted mode strings resolve to separate instead of enabling compact chrome."
patterns-established:
  - "Prometheus UI mode prefs should expose a typed helper and keep raw string parsing centralized."
requirements-completed: [UX-01, UX-02, UX-07]
duration: 11min
completed: 2026-07-07
---

# Phase 15 Plan 01: Chrome Mode Pref Foundation Summary

**Typed Chromium pref foundation for Prometheus compact/separate chrome mode with safe fallback behavior**

## Performance

- **Duration:** 11 min
- **Started:** 2026-07-07T05:20:12Z
- **Completed:** 2026-07-07T05:31:00Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Added `prefs::kPrometheusChromeMode` as the profile pref backing compact vs separate chrome.
- Added `PrometheusChromeMode` helpers for parsing, serialization, and `PrefService` read/write.
- Added unit tests proving known values, malformed fallback, default separate mode, and compact round-trip behavior.

## Task Commits

Each task was committed atomically in the Chromium checkout:

1. **Task 1: Add Prometheus chrome mode pref helper** - `75f734bc50`
2. **Task 2: Add chrome mode unit tests** - `11ff9ec73d`

## Files Created/Modified

- `.context/chromium/src/chrome/browser/prometheus/prometheus_chrome_mode.h` - Defines the chrome mode enum and helper API.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_chrome_mode.cc` - Implements compact/separate parsing, serialization, and pref access.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_chrome_mode_unittest.cc` - Covers parser, serializer, fallback, and pref round-trip behavior.
- `.context/chromium/src/chrome/browser/prometheus/BUILD.gn` - Adds the helper source set and test wiring.
- `.context/chromium/src/chrome/common/pref_names.h` - Declares `prefs::kPrometheusChromeMode`.
- `.context/chromium/src/chrome/browser/prefs/browser_prefs.cc` - Registers the profile pref with `"separate"` as the default.

## Decisions Made

- Kept `separate` as the default mode so compact layout remains opt-in until later layout/browser tests pass.
- Centralized malformed string handling in `PrometheusChromeModeFromString()` so all later layout callers inherit the same safe fallback.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The first compile attempt exposed a missing `pref_registry_simple.h` include in the new unit test. Added the include before the Task 2 commit and reran the target successfully.

## Verification

- `PATH=".context/depot_tools:$PATH" DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer autoninja -C out/Default prometheus_unittests` - passed.
- `./out/Default/prometheus_unittests --gtest_filter='*PrometheusChromeMode*'` - passed, 4/4 tests.
- `git -C .context/chromium/src diff --check` - passed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 15-02 can consume `GetPrometheusChromeMode()` to branch BrowserView layout behavior while preserving the conventional separate layout fallback.

---
*Phase: 15-chromium-ui-shell-compact-chrome-and-tab-model*
*Completed: 2026-07-07*
