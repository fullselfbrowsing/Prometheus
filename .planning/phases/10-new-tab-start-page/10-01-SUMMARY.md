---
phase: 10
plan: 01
subsystem: assets
tags: [svg, icons, qt-resources, new-tab]
dependency_graph:
  requires: []
  provides:
    - qrc:icons/fa/inbox.svg
    - qrc:icons/fa/cart-shopping.svg
    - qrc:icons/fa/calendar-check.svg
    - falkon:start as new-tab default
  affects:
    - falkon/src/lib/data/icons.qrc
    - falkon/src/lib/tabwidget/tabwidget.cpp
tech_stack:
  added:
    - Font Awesome Free 6.x (CC BY 4.0) — inbox, cart-shopping, calendar-check solids
  patterns:
    - Qt resource bundle (qrc) with FA solid SVG subset
    - settings.value() default-only override (preserves explicit user settings)
key_files:
  created:
    - falkon/src/lib/data/icons/fa/inbox.svg
    - falkon/src/lib/data/icons/fa/cart-shopping.svg
    - falkon/src/lib/data/icons/fa/calendar-check.svg
  modified:
    - falkon/src/lib/data/icons.qrc
    - falkon/src/lib/tabwidget/tabwidget.cpp
decisions:
  - "New FA SVGs appended after sidebar-flip.svg inside the existing CC BY 4.0 block — no new attribution comment needed per entry"
  - "TabWidget default uses settings.value() fallback only; explicit user newTabUrl settings are untouched"
metrics:
  duration: 3min
  completed_date: "2026-06-17T08:59:33Z"
---

# Phase 10 Plan 01: FA SVG Asset Bundle and New-Tab Default Summary

**One-liner:** Three FA Free 6.x solid SVGs (inbox, cart-shopping, calendar-check) bundled as Qt resources and new-tab URL default repointed from falkon:speeddial to falkon:start.

## What Was Built

**Task 1 — Download and register FA SVG glyphs**

Downloaded three Font Awesome Free 6.x solid-style SVGs from the canonical GitHub CDN:

- `falkon/src/lib/data/icons/fa/inbox.svg` (667 bytes, valid `<svg>`)
- `falkon/src/lib/data/icons/fa/cart-shopping.svg` (687 bytes, valid `<svg>`)
- `falkon/src/lib/data/icons/fa/calendar-check.svg` (687 bytes, valid `<svg>`)

All three are registered in `falkon/src/lib/data/icons.qrc` inside the existing `<!-- Font Awesome Free 6.x subset — CC BY 4.0 — offline only -->` block, appended immediately after `icons/fa/sidebar-flip.svg`. They are accessible at runtime via `qrc:icons/fa/inbox.svg`, `qrc:icons/fa/cart-shopping.svg`, and `qrc:icons/fa/calendar-check.svg`.

**Task 2 — Repoint new-tab default URL**

Changed the `settings.value()` fallback default in `TabWidget::loadSettings()` (line 176) from `QSL("falkon:speeddial")` to `QSL("falkon:start")`. Users who explicitly saved a custom `newTabUrl` retain their setting unchanged; only fresh profiles and profiles where the key was never explicitly written get the new default.

## Verification Results

All automated checks passed:

- `test -s` confirmed all three SVGs are non-empty
- `grep -c` confirmed exactly one entry per SVG in `icons.qrc`
- SVG content starts with `<svg xmlns=...` in each file
- `grep "newTabUrl"` shows `QSL("falkon:start")` as the sole default value in `tabwidget.cpp`

## Commits

| Task | Commit | Description |
|------|--------|-------------|
| Task 1 | `05757cfd9` (falkon) | chore(10-01): bundle FA SVG glyphs inbox, cart-shopping, calendar-check |
| Task 2 | `d4df16fa0` (falkon) | feat(10-01): repoint new-tab default URL to falkon:start |

## Deviations from Plan

None — plan executed exactly as written.

The `commit-to-subrepo` SDK command returned `no sub_repos configured` (SDK config lookup issue), so commits were made directly into the falkon sub-repo git repository via `git add` + `git commit`, which is the correct physical target. No behavioral difference from the plan's intent.

## Known Stubs

None. This plan delivers concrete asset files and a one-line code change. No placeholder data flows to any UI rendering in this plan.

## Threat Surface Scan

T-10-SC (Tampering — curl download from GitHub CDN) mitigated: all three SVGs are non-empty and confirmed to begin with `<svg` before commit. Source is the canonical Font Awesome Free 6.x GitHub tree (CC BY 4.0).

No new network endpoints, auth paths, or schema changes introduced.

## Self-Check: PASSED

- falkon/src/lib/data/icons/fa/inbox.svg: FOUND (667 bytes)
- falkon/src/lib/data/icons/fa/cart-shopping.svg: FOUND (687 bytes)
- falkon/src/lib/data/icons/fa/calendar-check.svg: FOUND (687 bytes)
- icons.qrc entries (3 of 3): FOUND
- tabwidget.cpp default `falkon:start`: FOUND
- falkon commit 05757cfd9: FOUND
- falkon commit d4df16fa0: FOUND
