---
phase: 09-offline-font-awesome-free-icon-system-and-minimal-themes
plan: "03"
subsystem: ui
tags: [icon-resolver, font-awesome, qt-resources, qobject, singleton, fallback-chain]

requires:
  - phase: 09-01
    provides: 69 FA Free SVGs at :/icons/fa/ (including arrow-down-to-line substitution and sidebar-flip placeholder)

provides:
  - PrometheusIconResolver singleton (FALKON_EXPORT) at falkon/src/lib/agent/
  - static icon(actionId) with 3-step fallback: bundled SVG -> QIcon::fromTheme -> 1x1 transparent + qWarning
  - 88-entry action map covering all 09-UI-SPEC.md tables (nav/agent/MCP/provider/vault/diag/supervision/tab/tools/settings/utility/mode)

affects:
  - 09-04 and later (QSS theme, PrometheusMarkWidget, StartPage — all can call PrometheusIconResolver::icon() for deterministic icons)
  - Phase 10 (StartPage icon callsites)

tech-stack:
  added: []
  patterns:
    - Q_GLOBAL_STATIC singleton with public constructor (required by macro; instance() is the canonical access path)
    - QHash<QString, QPair<QString,QString>> for compile-time-constant action map (no runtime path interpolation)
    - 3-step icon fallback: QIcon(resourcePath) -> QIcon::fromTheme(fallback) -> 1x1 transparent + qWarning

key-files:
  created:
    - falkon/src/lib/agent/prometheusiconresolver.h
    - falkon/src/lib/agent/prometheusiconresolver.cpp
  modified:
    - falkon/src/lib/CMakeLists.txt

key-decisions:
  - "Public constructor on PrometheusIconResolver required by Q_GLOBAL_STATIC: Q_GLOBAL_STATIC instantiates the class internally and cannot access a private constructor; constructor made public while instance() remains the canonical singleton access path"
  - "88 action map entries (plan specified 70+): all tables from 09-UI-SPEC.md enumerated completely; several spec categories have more entries than the round-number floor"
  - "QSL() used for all string literals per codebase convention"
  - "Empty string for themeFallback when no QIcon::fromTheme fallback is defined (e.g. agent-fsb must always resolve from bundled SVG)"

metrics:
  duration: 8min
  completed: 2026-06-17
  tasks: 1
  files: 3
---

# Phase 9 Plan 03: PrometheusIconResolver Summary

**PrometheusIconResolver singleton with 88-entry compile-time action map and a 3-step fallback (bundled SVG resource -> QIcon::fromTheme -> 1x1 transparent + qWarning) wired into FalkonPrivate**

## Performance

- **Duration:** 8 min
- **Started:** 2026-06-17
- **Completed:** 2026-06-17
- **Tasks:** 1
- **Files modified:** 3

## Accomplishments

- Created `prometheusiconresolver.h` declaring a `FALKON_EXPORT` QObject singleton with `static QIcon icon(const QString &actionId)` and `static PrometheusIconResolver* instance()`
- Created `prometheusiconresolver.cpp` with a Q_GLOBAL_STATIC singleton, `initActionMap()` populating 88 entries (all 09-UI-SPEC.md tables: nav 15, agent 10, MCP 6, provider 5, vault 5, diag/supervision 7, tab 7, page tools 8, settings 7, utility 13, mode-switcher 4), and the complete 3-step fallback chain
- Both files registered in `falkon/src/lib/CMakeLists.txt` SRCS and HDRS sections after existing `promethusfontloader` entries
- FalkonPrivate builds cleanly with no errors

## Task Commits

1. **Task 1: Create PrometheusIconResolver with full action map and 3-step fallback** - `b85054c76` (feat)

## Files Created/Modified

- `falkon/src/lib/agent/prometheusiconresolver.h` — FALKON_EXPORT class declaration, static icon() and instance(), QHash action map storage (new)
- `falkon/src/lib/agent/prometheusiconresolver.cpp` — 88-entry action map init, 3-step fallback chain, Q_GLOBAL_STATIC singleton (new)
- `falkon/src/lib/CMakeLists.txt` — SRCS and HDRS entries added

## Decisions Made

- **Public constructor for Q_GLOBAL_STATIC compatibility:** The plan's interface stub shows a private constructor, but `Q_GLOBAL_STATIC` calls the constructor internally and cannot reach private members. Constructor made public while `instance()` remains the canonical access path. This is the same pattern used by `IconProvider` (the structural analog), where the constructor is also public. No behavioral difference; callers still use `instance()`.
- **88 action map entries vs 70+ minimum:** Every row in every 09-UI-SPEC.md table was included. The count is higher than the plan floor because the spec has more entries when fully enumerated.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Q_GLOBAL_STATIC cannot call private constructor**
- **Found during:** Task 1 (first build attempt)
- **Issue:** The plan interface spec declares the constructor private. `Q_GLOBAL_STATIC(PrometheusIconResolver, s_instance)` generates code that calls `new PrometheusIconResolver()` at the call site, which fails with "calling a private constructor" if the constructor is private.
- **Fix:** Moved the constructor to the public section with a comment explaining that `instance()` is the canonical access path. The `IconProvider` analog (the pattern reference cited in the plan) also has a public constructor for the same reason.
- **Files modified:** `falkon/src/lib/agent/prometheusiconresolver.h`
- **Committed in:** `b85054c76` (Task 1 commit)

## Stub Scan

No stubs. The action map is fully populated with real resource paths and fallback names per the spec. No hardcoded placeholder strings or empty-returning logic beyond the intentional unknown-actionId guard (which returns `QIcon()` as documented).

## Threat Surface Scan

No new network endpoints, auth paths, or file access patterns beyond those specified in the plan's threat model:

- `T-09-03-A` mitigated: all resource paths are compile-time constants; no user-controlled string interpolation into paths
- `T-09-03-C` mitigated: Q_GLOBAL_STATIC init is thread-safe; icon() is read-only post-init

## Self-Check

Files exist:
- `falkon/src/lib/agent/prometheusiconresolver.h` — FOUND
- `falkon/src/lib/agent/prometheusiconresolver.cpp` — FOUND

Commit exists: b85054c76 — FOUND

Action map count: 88 entries (>= 70 minimum) — PASS

CMakeLists entries: both .cpp and .h — FOUND

Warning strings: "unknown actionId" and "missing icon for action...release gate will fail" — FOUND

Build: FalkonPrivate exits 0 — PASS

## Self-Check: PASSED
