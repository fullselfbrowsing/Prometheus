---
phase: 01-baseline-and-legal-inventory
plan: 01
subsystem: baseline-validation
tags: [falkon, cmake, qt, smoke]
provides:
  - Baseline preflight script
  - Browser smoke launch script
  - Baseline README with configure/build/smoke commands
affects: [Phase 1, Phase 2, Phase 6]
tech-stack:
  added: [cmake, ninja, qt, qtwebengine, extra-cmake-modules, karchive, ki18n]
  patterns: [bash-preflight, smoke-script]
key-files:
  created:
    - falkon/tools/fsb-baseline/README.md
    - falkon/tools/fsb-baseline/preflight.sh
    - falkon/tools/fsb-baseline/smoke-browser.sh
  modified:
    - src/lib/tools/mactoolbutton.h
    - src/lib/app/mainmenu.cpp
key-decisions:
  - "Do not auto-install build dependencies during baseline validation."
  - "Report missing CMake/Ninja/Qt/KF tooling as a blocker with exact command output."
duration: 45min
completed: 2026-06-16
---

# Phase 1: Baseline Validation Summary

Added repeatable build preflight and smoke-launch tooling for the local Falkon fork, installed the baseline toolchain, fixed two macOS/Qt 6.11 build compatibility issues, and built the app.

## Performance
- **Duration:** 45min
- **Tasks:** 3 completed
- **Files modified:** 3 created, 2 modified

## Accomplishments
- Created `preflight.sh` to check mandatory local build tools and Qt/KF CMake package metadata.
- Created `smoke-browser.sh` to launch a built browser binary, open smoke URLs, and terminate cleanly.
- Documented the baseline build and smoke workflow in `README.md`.
- Installed the required Homebrew build dependencies: `cmake`, `ninja`, `qt`, `qtwebengine`, `extra-cmake-modules`, `karchive`, and `ki18n`.
- Fixed `MacToolButton` macOS declarations so they match the existing implementation.
- Removed an obsolete `qt_mac_set_dock_menu` Qt-private call that no longer links with Qt 6.11.
- Built `build/fsb-baseline/bin/falkon.app/Contents/MacOS/falkon`.

## Verification
- `./tools/fsb-baseline/preflight.sh` passed after dependency installation.
- `cmake -S . -B build/fsb-baseline -G Ninja -DCMAKE_BUILD_TYPE=RelWithDebInfo` passed.
- `cmake --build build/fsb-baseline` passed.
- `bash falkon/tools/fsb-baseline/smoke-browser.sh --help` passed.
- `./tools/fsb-baseline/smoke-browser.sh --binary build/fsb-baseline/bin/falkon.app/Contents/MacOS/falkon --wait 5` launched the browser; user confirmed the app opened.
- After patching cleanup behavior, `./tools/fsb-baseline/smoke-browser.sh --binary build/fsb-baseline/bin/falkon.app/Contents/MacOS/falkon --wait 1` exited 0.
- `rg -n "cmake -S . -B build/fsb-baseline|smoke-browser|preflight" falkon/tools/fsb-baseline/README.md` passed.

## Files Created/Modified
- `falkon/tools/fsb-baseline/README.md` - Baseline build/smoke instructions.
- `falkon/tools/fsb-baseline/preflight.sh` - Build dependency preflight.
- `falkon/tools/fsb-baseline/smoke-browser.sh` - Browser smoke launch helper.
- `src/lib/tools/mactoolbutton.h` - macOS declaration compatibility fix.
- `src/lib/app/mainmenu.cpp` - removed obsolete Qt-private dock menu hook.

## Decisions & Deviations
- Build dependency installation was performed after the initial preflight blocker.
- `MacToolButton::resetIconColor()` and `iconColor() const` were already implemented but not declared consistently for macOS; the header was updated.
- `qt_mac_set_dock_menu()` is not available in the current Qt 6.11 Homebrew build; the nonessential Dock menu hook was removed to restore baseline buildability.
- The first smoke run launched successfully but exposed a script hang on the second URL invocation; `smoke-browser.sh` now backgrounds both launches and terminates helper-launched PIDs.

## Next Phase Readiness
Phase 2 can start from a buildable macOS baseline. Product naming is Prometheus, with "Powered by FSB" as the affiliation/tagline.
