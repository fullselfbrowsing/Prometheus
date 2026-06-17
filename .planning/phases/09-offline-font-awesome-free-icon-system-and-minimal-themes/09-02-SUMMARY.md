---
phase: 09-offline-font-awesome-free-icon-system-and-minimal-themes
plan: "02"
subsystem: ui
tags: [font-loader, poppins, space-mono, qfontdatabase, startup, qt-resources]

requires:
  - phase: 09-offline-font-awesome-free-icon-system-and-minimal-themes
    plan: "01"
    provides: 5 brand TTFs at :/fonts/poppins/ and :/fonts/spacemono/ in fonts.qrc

provides:
  - PromethusFontLoader class (agent/promethusfontloader.h + .cpp) with static registerAll()
  - All 5 brand font TTFs registered via QFontDatabase::addApplicationFont at startup
  - qWarning on failure matching 09-UI-SPEC.md Copywriting Contract exactly (with em-dash and weight int)
  - FalkonPrivate builds cleanly with new files in CMakeLists.txt SRCS + HDRS

affects:
  - 09-03 and later (PrometheusMarkWidget, theme QSS font-family selectors rely on font registration)

tech-stack:
  added: []
  patterns:
    - Pure-static utility class pattern (no Q_OBJECT, no singleton) for startup registration
    - qWarning with UTF-8 em-dash literal (\xe2\x80\x94) for 09-UI-SPEC compliance
    - Sentinel-terminated struct array for iterating font entries without heap allocation

key-files:
  created:
    - falkon/src/lib/agent/promethusfontloader.h
    - falkon/src/lib/agent/promethusfontloader.cpp
  modified:
    - falkon/src/lib/app/mainapplication.cpp (include + unconditional registerAll() call after QIcon::setThemeName block)
    - falkon/src/lib/CMakeLists.txt (agent/promethusfontloader.cpp in SRCS; agent/promethusfontloader.h in HDRS)

key-decisions:
  - "PromethusFontLoader is a pure-static utility class: no instances, no Q_OBJECT, no singleton; simplest correct form for a one-shot startup registration"
  - "Include via qzcommon.h not falkon_defs.h: agentcommandrouter.h and other agent headers use qzcommon.h which already defines FALKON_EXPORT"
  - "registerAll() called after QIcon::setThemeName block (line 141) per plan insertion-point spec, before QSQLITE driver check"

requirements-completed: [FONT-01]

duration: 2min
completed: 2026-06-17
---

# Phase 9 Plan 02: PromethusFontLoader Startup Registration Summary

**PromethusFontLoader static class created registering all 5 brand TTFs (Poppins 100/300/800/900 + Space Mono 400) via QFontDatabase at MainApplication startup before any UI is rendered**

## Performance

- **Duration:** 2 min
- **Started:** 2026-06-17T07:32:37Z
- **Completed:** 2026-06-17T07:34:18Z
- **Tasks:** 1
- **Files modified:** 4

## Accomplishments

- `promethusfontloader.h` and `promethusfontloader.cpp` created in `falkon/src/lib/agent/` as a pure-static utility class using `FALKON_EXPORT` via `qzcommon.h`
- `registerAll()` iterates exactly 5 font entries from a sentinel-terminated struct array; calls `QFontDatabase::addApplicationFont` for each and emits `qWarning` on `id == -1` with the exact message from 09-UI-SPEC.md Copywriting Contract (including UTF-8 em-dash `\xe2\x80\x94` and weight integer)
- `mainapplication.cpp` updated: `#include "agent/promethusfontloader.h"` added after other agent includes; `PromethusFontLoader::registerAll()` called unconditionally after `QIcon::setThemeName` block (line 141) and before QSQLITE driver check
- `CMakeLists.txt` updated: `agent/promethusfontloader.cpp` added to SRCS block after `agent/fsbcontrolpanel.cpp`; `agent/promethusfontloader.h` added to HDRS block after `agent/fsbcontrolpanel.h`
- FalkonPrivate builds cleanly with exit 0 and no new errors (one pre-existing Q_OS_OSX deprecation warning in preferences.cpp is unchanged)

## Task Commits

1. **Task 1: Create PromethusFontLoader class and wire into MainApplication** - `9951c273c` (feat)

## Files Created/Modified

- `falkon/src/lib/agent/promethusfontloader.h` — pure-static class declaration with `static void registerAll()`; `FALKON_EXPORT` applied via `qzcommon.h`
- `falkon/src/lib/agent/promethusfontloader.cpp` — implementation: sentinel-terminated FontEntry struct array, `QFontDatabase::addApplicationFont` per entry, `qWarning` on failure with exact 09-UI-SPEC.md message format
- `falkon/src/lib/app/mainapplication.cpp` — include and unconditional `PromethusFontLoader::registerAll()` call inserted after `QIcon::setThemeName` block
- `falkon/src/lib/CMakeLists.txt` — `agent/promethusfontloader.cpp` and `agent/promethusfontloader.h` added to SRCS and HDRS lists

## Decisions Made

- **Pure-static class, not singleton or Q_OBJECT:** registerAll() is a one-shot startup function with no signals, no state after return, and no need for instance lifetime management. Pure-static is the simplest correct form and matches the plan's explicit instruction.
- **qzcommon.h for FALKON_EXPORT:** Checked agentcommandrouter.h (the adjacent agent header); it uses `#include "qzcommon.h"` for `FALKON_EXPORT`. Used the same pattern for consistency instead of `falkon_defs.h` which does not exist in the tree.
- **UTF-8 em-dash literal:** Used `\xe2\x80\x94` in the `qWarning` format string (C string literal) rather than a Unicode escape to guarantee byte-level match with the em-dash character in 09-UI-SPEC.md §Copywriting Contract.

## Deviations from Plan

None. Plan executed exactly as written.

## Stub Scan

No stubs. `registerAll()` loads real font files from real Qt resource paths vendored in Plan 09-01. No placeholder or hardcoded empty values.

## Threat Surface Scan

No new network endpoints, auth paths, or trust-boundary changes introduced. All font paths are compile-time Qt resource constants (`:/fonts/...`). qWarning output is developer-facing only (no user-visible disclosure). Threat mitigations T-09-02-B and T-09-02-D are satisfied: `registerAll()` is called after `QApplication` base initialization, and no CSS `@import` or network font URL is used.

## Self-Check

### File existence

- falkon/src/lib/agent/promethusfontloader.h: FOUND
- falkon/src/lib/agent/promethusfontloader.cpp: FOUND
- falkon/src/lib/app/mainapplication.cpp (modified): FOUND
- falkon/src/lib/CMakeLists.txt (modified): FOUND

### Commit existence

- 9951c273c: FOUND (falkon git log)

### Build

- `cmake --build build/fsb-baseline --target FalkonPrivate -j4`: EXIT 0, ninja: no work to do (all compiled in prior build run)

## Self-Check: PASSED
