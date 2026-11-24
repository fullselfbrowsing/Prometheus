---
phase: 15-chromium-ui-shell-compact-chrome-and-tab-model
plan: 06
subsystem: ui
tags: [chromium, verification, patches, validation, prometheus]
requires:
  - phase: 15
    plan: 01
  - phase: 15
    plan: 02
  - phase: 15
    plan: 03
  - phase: 15
    plan: 04
  - phase: 15
    plan: 05
provides:
  - Phase 15 automated gate evidence
  - Phase 15 Chromium patch series
  - Preservation ledger update for compact chrome carry-forward
affects: [phase-15, chromium-ui, validation, preservation]
tech-stack:
  added: []
  patterns:
    - Phase-prefixed ignored logs under Chromium out/Default for local gate evidence
    - Root-tracked patch series exported from explicit Chromium base commits
key-files:
  created:
    - .planning/phases/15-chromium-ui-shell-compact-chrome-and-tab-model/patches/
  modified:
    - .planning/phases/15-chromium-ui-shell-compact-chrome-and-tab-model/15-VALIDATION.md
    - .planning/preservation/FALKON-TO-CHROMIUM-PRESERVATION.md
key-decisions:
  - "Do not preserve screenshot PNGs that do not show the Prometheus window; document the capture blocker instead."
  - "Treat Phase 15 automated compact chrome evidence as complete while leaving desktop visual UAT open for a human-run session."
  - "Export Phase 15 Chromium patches from explicit Phase 14 tip `19d1f8e0de..HEAD`."
patterns-established:
  - "When native screenshot capture is blocked, validation docs must distinguish automated geometry evidence from human visual approval."
requirements-completed: [UX-01, UX-02, UX-03, UX-04, UX-05, UX-06, UX-07]
duration: 12min
completed: 2026-07-07
---

# Phase 15 Plan 06: Validation and Patch Export Summary

**Full Phase 15 gate run, preservation update, and Chromium patch export**

## Performance

- **Duration:** 12 min
- **Started:** 2026-07-07T06:24:00Z
- **Completed:** 2026-07-07T06:36:16Z
- **Tasks:** 2
- **Files modified:** 14 tracked planning artifacts: validation doc, preservation ledger, summary, and 11 exported patches.

## Accomplishments

- Ran the Phase 15 build gate for `chrome browser_tests prometheus_unittests`.
- Ran full `prometheus_unittests`.
- Ran targeted Phase 15 browser tests for compact chrome, chrome mode, tab search, and tab commands.
- Ran the toolbar-entrypoint browser test separately because the plan's broad browser-test filter did not include `Toolbar`.
- Ran root Chromium environment, GPL guard, and artifact isolation gates.
- Exported 11 Phase 15 Chromium patches from `19d1f8e0de..HEAD`.
- Updated `15-VALIDATION.md` with passed task rows, log references, patch evidence, and the visual capture blocker.
- Updated the preservation ledger with Phase 15 compact chrome and advanced tab-management evidence while keeping later Phase 16/20/21 checks as `carry_forward`.

## Gate Logs

Ignored local logs under `.context/chromium/src/out/Default/`:

- `phase15-06-build.log` - `EXIT_CODE=0`.
- `phase15-06-prometheus-unittests.log` - `EXIT_CODE=0`.
- `phase15-06-browser-tests.log` - 7/7 tests passed, `EXIT_CODE=0`.
- `phase15-06-toolbar-browser-test.log` - 1/1 test passed, `EXIT_CODE=0`.
- `phase15-06-root-gates.log` - Chromium environment, GPL guard, and artifact isolation passed, `EXIT_CODE=0`.
- `phase15-06-visual-capture-blocker.log` - documents why screenshot PNGs were not preserved.

## Patch Series

Exported to `.planning/phases/15-chromium-ui-shell-compact-chrome-and-tab-model/patches/`:

- 11 non-empty `.patch` files.
- Range: `19d1f8e0de..HEAD`.
- Covers Plans 15-01 through 15-05 Chromium commits.

## Deviations from Plan

- Native screenshots at 800px, 1280px, and 1728px+ could not be captured reliably in this Conductor session. `screencapture -R` failed, Apple Events window targeting was unauthorized, and full-screen captures showed desktop/wallpaper rather than the Prometheus window.
- Misleading screenshot PNGs were removed instead of committed. The validation doc records the blocker and keeps desktop visual UAT open.

## Verification

- `../../depot_tools/autoninja -C out/Default chrome browser_tests prometheus_unittests` - passed.
- `./out/Default/prometheus_unittests` - passed.
- `./out/Default/browser_tests --gtest_filter='*Prometheus*Compact*:*Prometheus*Chrome*:*Prometheus*Tab*'` - passed, 7/7 tests.
- `./out/Default/browser_tests --gtest_filter='*PrometheusToolbarEntryPoint*'` - passed, 1/1 test.
- `bash .planning/chromium/check-chromium-env.sh && bash .planning/chromium/check-falkon-gpl-guard.sh && bash .planning/chromium/verify-artifact-isolation.sh` - passed.
- `find .planning/phases/15-chromium-ui-shell-compact-chrome-and-tab-model/patches -name '*.patch' -size +0` - returned 11 patches.
- `git -C .context/chromium/src diff --check` - passed.
- `git diff --check` - passed.

## User Setup Required

- Human desktop visual UAT remains open for native screenshot/window behavior: compact chrome at 800px, 1280px, and 1728px+, macOS traffic lights, drag regions, and standard shortcuts.

## Next Phase Readiness

Phase 16 can begin with Phase 15 compact chrome, toolbar entry points, tab state defaults, tab command adapter, automated tests, and exported patch series in place.

---
*Phase: 15-chromium-ui-shell-compact-chrome-and-tab-model*
*Completed: 2026-07-07*
