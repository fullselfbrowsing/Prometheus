---
phase: 01-baseline-and-legal-inventory
plan: 02
subsystem: product-identity
tags: [falkon, rebrand, metadata, packaging]
provides:
  - Product identity inventory
affects: [Phase 2]
tech-stack:
  added: []
  patterns: [markdown-inventory]
key-files:
  created:
    - falkon/tools/fsb-baseline/product-identity-inventory.md
  modified: []
key-decisions:
  - "Inventory product identity before making any rebrand edits."
  - "Separate rebrand targets from legal-attribution-sensitive surfaces."
duration: 10min
completed: 2026-06-16
---

# Phase 1: Product Identity Inventory Summary

Mapped the inherited Falkon/KDE/Qt product identity surfaces that Phase 2 must review.

## Performance
- **Duration:** 10min
- **Tasks:** 1 completed
- **Files modified:** 1 created

## Accomplishments
- Identified primary macOS, Windows, Linux, CMake, icon, theme, notification, and documentation identity surfaces.
- Flagged legal-attribution-sensitive files that should not be blindly rebranded or deleted.

## Verification
- `rg -n "org.kde.falkon|Info.plist|version.rc|desktop|appdata|icons|falkon/linux/hicolor" falkon/tools/fsb-baseline/product-identity-inventory.md` passed.

## Files Created/Modified
- `falkon/tools/fsb-baseline/product-identity-inventory.md` - Rebrand surface inventory.

## Decisions & Deviations
None - followed plan as specified.

## Next Phase Readiness
Phase 2 can use this file as the first-pass rebrand checklist once baseline build validation is unblocked.
