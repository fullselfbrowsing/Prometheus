---
phase: 09-offline-font-awesome-free-icon-system-and-minimal-themes
plan: "05"
subsystem: ui
tags: [logo, widget, icon-resolver, qt-painter, poppins, space-mono]

requires:
  - phase: 09-02
    provides: Poppins and Space Mono fonts registered via PromethusFontLoader
  - phase: 09-03
    provides: PrometheusIconResolver singleton with 88-entry action map

provides:
  - PrometheusMarkWidget QWidget with Size enum (Compact/Medium/Large)
  - PM monogram: P in Poppins Thin 100, M in Poppins Black 900 via QPainter text draws
  - Version tag U+25BD 0.1 in Space Mono when lockup >= 28px
  - PrometheusMarkWidget(Compact) wired into sidebar header replacing placeholder
  - 14 primary QIcon::fromTheme call sites migrated to PrometheusIconResolver::icon

affects:
  - Phase 09-06 visual gate (PrometheusMarkWidget renders in sidebar; icons deterministic)

tech-stack:
  added: []
  patterns:
    - QPainter two-weight text draws (QFontDatabase::font with style string "Thin"/"Black")
    - U+25BD (QChar(0x25BD)) for version tag triangle — not letter v
    - QFont::setPixelSize with letterPx() switch table (12/26/52 for Compact/Medium/Large)
    - Resolver include path: "agent/prometheusiconresolver.h" from navigation/webengine callers
    - QFontDatabase::font(family, style, 0) then setPixelSize() — avoids point/pixel confusion

key-files:
  created:
    - falkon/src/lib/agent/prometheusmarkwidget.h
    - falkon/src/lib/agent/prometheusmarkwidget.cpp
  modified:
    - falkon/src/lib/CMakeLists.txt
    - falkon/src/lib/agent/agentruntimesidebar.cpp
    - falkon/src/lib/navigation/navigationbar.cpp
    - falkon/src/lib/navigation/locationbar.cpp
    - falkon/src/lib/webengine/webview.cpp

key-decisions:
  - "Use qzcommon.h not falkon_defs.h for FALKON_EXPORT — falkon_defs.h does not exist in build paths; qzcommon.h is the codebase standard (Rule 3 auto-fix on first build)"
  - "QFontDatabase::font(family, style, 0) then fontP.setPixelSize(px) — zero point size avoids platform DPI confusion; pixel size is set explicitly afterward"
  - "agentruntimesidebar.cpp requires #include <QFontDatabase> added explicitly — not pulled in transitively via other agent headers"
  - "locationbar.cpp security-medium/low pattern: resolver replaces the fallback icon only, leaving the icon = QIcon::fromTheme(..., icon) assignment-chain pattern unchanged structurally"

metrics:
  duration: 4min
  completed: 2026-06-17
  tasks: 2
  files: 7
---

# Phase 9 Plan 05: PrometheusMarkWidget and Icon Resolver Migration Summary

**PrometheusMarkWidget native QPainter PM monogram (P Poppins Thin 100 + M Poppins Black 900, U+25BD version tag) replaces sidebar placeholder; 14 primary QIcon::fromTheme call sites in navigationbar/locationbar/webview migrated to PrometheusIconResolver**

## Performance

- **Duration:** 4 min
- **Started:** 2026-06-17T07:53:26Z
- **Completed:** 2026-06-17
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments

- Created `prometheusmarkwidget.h`: FALKON_EXPORT QWidget with Size enum (Compact=26, Medium=64, Large=128), sizeHint/minimumSizeHint, and paintEvent; letterPx() and showVersionTag() private helpers
- Created `prometheusmarkwidget.cpp`: QPainter draws "P" in Poppins Thin 100 and "M" in Poppins Black 900 at pixel sizes 12/26/52; version tag QString(QChar(0x25BD)) + "0.1" drawn below in Space Mono when size >= 28 px; color --text-3 `#a99283`
- `CMakeLists.txt`: added `agent/prometheusmarkwidget.cpp` and `agent/prometheusmarkwidget.h` to SRCS and HDRS after prometheusiconresolver
- `agentruntimesidebar.cpp`: replaced QLabel "Prometheus" + QLabel "Powered by FSB" placeholder with PrometheusMarkWidget(Compact, 26x26) + wordmark QHBoxLayout (wPro "Pro" + wMetheus "metheus") in a headerRow inside a headerWidget; added #include "prometheusmarkwidget.h" and #include <QFontDatabase>
- `navigationbar.cpp`: 2 QIcon::fromTheme calls replaced (view-list-icons -> tab-all, edit-find -> nav-search)
- `locationbar.cpp`: 4 QIcon::fromTheme calls replaced (edit-find x2 -> nav-search, security-medium -> nav-lock-secure, security-low -> nav-lock-insecure)
- `webview.cpp`: 8 QIcon::fromTheme calls replaced (edit-undo/redo/cut/copy/paste/select-all -> utility-*, view-refresh -> nav-reload, process-stop -> nav-stop)
- FalkonPrivate builds cleanly with no errors after all changes

## Task Commits

1. **Task 1: Create PrometheusMarkWidget with two-weight PM rendering** — `589da65f6` (feat) — falkon sub-repo
2. **Task 2: Wire PrometheusMarkWidget into sidebar header and resolver into primary nav call sites** — `0ae45a061` (feat) — falkon sub-repo

## Files Created/Modified

- `falkon/src/lib/agent/prometheusmarkwidget.h` — FALKON_EXPORT class with Size enum and paintEvent (new)
- `falkon/src/lib/agent/prometheusmarkwidget.cpp` — Two-weight QPainter rendering; U+25BD version tag (new)
- `falkon/src/lib/CMakeLists.txt` — SRCS + HDRS registration
- `falkon/src/lib/agent/agentruntimesidebar.cpp` — Sidebar header replaced; includes added
- `falkon/src/lib/navigation/navigationbar.cpp` — 2 fromTheme -> resolver migrations
- `falkon/src/lib/navigation/locationbar.cpp` — 4 fromTheme -> resolver migrations
- `falkon/src/lib/webengine/webview.cpp` — 8 fromTheme -> resolver migrations

## Decisions Made

- **qzcommon.h not falkon_defs.h:** The plan interface stub listed `#include "falkon_defs.h"`. That file does not exist in this codebase — `FALKON_EXPORT` is defined via `qzcommon.h` (confirmed by checking all other agent headers). First build caught the error immediately; fix applied under Rule 3.
- **QFontDatabase::font(family, style, 0) then setPixelSize:** Using zero as the point size argument avoids macOS DPI scaling artifacts; pixel size is set explicitly afterward via fontP.setPixelSize(px). This matches how the codebase handles pixel-exact font sizing in custom widgets.
- **QFontDatabase include in agentruntimesidebar.cpp:** The wormark labels in the header row call QFontDatabase::font() directly. This header is not transitively available in agentruntimesidebar.cpp, so #include <QFontDatabase> was added explicitly.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] `falkon_defs.h` not found**
- **Found during:** Task 1 (first build)
- **Issue:** The plan's header stub used `#include "falkon_defs.h"`. This file does not exist in the Falkon build tree. All other agent headers use `#include "qzcommon.h"` which provides `FALKON_EXPORT`.
- **Fix:** Changed include to `#include "qzcommon.h"` in prometheusmarkwidget.h.
- **Files modified:** `falkon/src/lib/agent/prometheusmarkwidget.h`
- **Committed in:** `589da65f6` (Task 1 commit)

## Stub Scan

No stubs. All call sites wire to real resolver action IDs. PrometheusMarkWidget draws real Poppins Thin/Black text and real U+25BD — no placeholders. The wordmark labels use real QFontDatabase lookups with named Poppins styles.

## Threat Surface Scan

No new network endpoints or auth paths. All threat model mitigations confirmed:
- T-09-05-A mitigated: QChar(0x25BD) is the triangle; grep confirmed; no letter v used
- T-09-05-B mitigated: QFontDatabase::font falls back gracefully when family not registered; setPixelSize used for fallback path
- T-09-05-C mitigated: grep confirms 14 call sites migrated; prometheus icon at line 63 of agentruntimesidebar.cpp kept as-is per plan

## Self-Check

Files exist:
- `falkon/src/lib/agent/prometheusmarkwidget.h` — FOUND
- `falkon/src/lib/agent/prometheusmarkwidget.cpp` — FOUND

Commits exist:
- `589da65f6` — FOUND
- `0ae45a061` — FOUND

Resolver migration counts:
- navigationbar.cpp: 2 — PASS
- locationbar.cpp: 4 — PASS
- webview.cpp: 8 — PASS

Build: FalkonPrivate exits 0 — PASS

U+25BD grep: QChar(0x25BD) in prometheusmarkwidget.cpp — PASS

## Self-Check: PASSED
