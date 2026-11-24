---
phase: 01-baseline-and-legal-inventory
plan: 03
subsystem: legal-preservation
tags: [license, gpl, attribution, falkon]
provides:
  - Legal notice inventory
affects: [Phase 2, Phase 6]
tech-stack:
  added: []
  patterns: [markdown-inventory]
key-files:
  created:
    - falkon/tools/fsb-baseline/legal-notice-inventory.md
  modified: []
key-decisions:
  - "Rebrand work may move inherited notices but must not delete required notices."
duration: 10min
completed: 2026-06-16
---

# Phase 1: Legal Notice Inventory Summary

Mapped inherited legal and license surfaces that later rebrand and release work must preserve.

## Performance
- **Duration:** 10min
- **Tasks:** 1 completed
- **Files modified:** 1 created

## Accomplishments
- Identified source-level license files, in-app legal/about surfaces, packaging metadata, and theme license files.
- Added a preservation rule for later phases.
- Listed verification commands to run before and after rebrand work.

## Verification
- `rg -n "COPYING|GPL|licenseviewer|aboutdialog|Flatpak|theme|Required preservation rule" falkon/tools/fsb-baseline/legal-notice-inventory.md` passed.

## Files Created/Modified
- `falkon/tools/fsb-baseline/legal-notice-inventory.md` - Legal notice preservation inventory.

## Decisions & Deviations
None - followed plan as specified.

## Next Phase Readiness
Phase 2 and Phase 6 can use this inventory to preserve required notices while changing product identity and packaging.
