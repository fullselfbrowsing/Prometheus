---
phase: 11-preservation-contract-and-falkon-freeze
plan: 02
subsystem: preservation
tags: [falkon, chromium, migration-map, license-boundary, verifier]

requires:
  - phase: 11-01
    provides: Recoverable Falkon v1 preservation gate and GPL-to-Chromium license boundary
provides:
  - Capability-first Falkon-to-Chromium migration map with Chromium phase owners
  - Scripted migration-map invariant checks in the preservation verifier
affects: [phase-13-brand-legal, phase-14-design-assets, phase-15-chrome-tabs, phase-16-webui, phase-17-agent-service, phase-18-page-adapter, phase-19-mcp, phase-20-fsb-runtime, phase-21-supervision, phase-22-extensions, phase-23-parity-security, phase-24-packaging]

tech-stack:
  added: []
  patterns: [capability-first migration contract, dossier invariant gate, license status labels]

key-files:
  created:
    - .planning/phases/11-preservation-contract-and-falkon-freeze/11-02-SUMMARY.md
  modified:
    - .planning/preservation/FALKON-TO-CHROMIUM-PRESERVATION.md
    - .planning/preservation/verify-preservation.sh

key-decisions:
  - "Use the canonical dossier's Capability Migration Map as the source-of-truth linking v1 behavior contracts to Chromium owner phases, parity evidence, and license status."
  - "Preservation verification now enforces required migration-map rows, columns, license labels, and Chromium owner phases before later Chromium work proceeds."

patterns-established:
  - "Migration row shape: Capability, v1 Behavior Contract, Falkon Reference, Chromium Owner, Parity Evidence, and License / Attribution Note."
  - "Verifier invariant pattern: use require_rg checks for required dossier sections, capability rows, license status labels, and future owner phases."

requirements-completed: [PRES-02, PRES-03, PRES-04]

duration: 4min
completed: 2026-06-23
---

# Phase 11 Plan 02: Capability Migration Contract Summary

**Capability-first migration map with scripted license-boundary and Chromium-owner invariants.**

## Performance

- **Duration:** 4min
- **Started:** 2026-06-23T18:23:16Z
- **Completed:** 2026-06-23T18:27:04Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Added `## Capability Migration Map` to the canonical dossier with 16 capability rows spanning product identity, legal, design/assets, compact chrome, WebUI, agent routing, page adapters, MCP, runtime, supervision, extensions, parity, security, and packaging.
- Mapped each row to Chromium owner phases 13-24 with future parity evidence and explicit license/attribution status labels.
- Extended `verify-preservation.sh` with `check_migration_map()` and wired it into `--dossier-only` and full verification modes.

## Task Commits

1. **Task 1: Add the capability-first migration map to the canonical dossier** - `e500ec205` (docs)
2. **Task 2: Enforce migration-map invariants in the preservation verifier** - `f6b98344b` (test)

## Files Created/Modified

- `.planning/preservation/FALKON-TO-CHROMIUM-PRESERVATION.md` - Adds the normalized capability migration map before Chromium architecture targets.
- `.planning/preservation/verify-preservation.sh` - Adds migration-map checks for required columns, rows, license labels, and owner phases.
- `.planning/phases/11-preservation-contract-and-falkon-freeze/11-02-SUMMARY.md` - Records execution, verification, deviations, and self-check evidence.

## Decisions Made

- The migration map is a behavior-contract document, not a Falkon implementation inventory.
- The verifier also checks owner phase labels because the threat register requires mitigation for lost Chromium ownership, not only lost rows or columns.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Added owner-phase invariant checks**
- **Found during:** Task 2 (Enforce migration-map invariants in the preservation verifier)
- **Issue:** The task's exact verifier pattern list covered columns, capability rows, and license labels, but threat T-11-06 also required the verifier to fail if Chromium owner phases disappear.
- **Fix:** Added `require_rg` checks for Phase 13 through Phase 24 owner labels inside `check_migration_map()`.
- **Files modified:** `.planning/preservation/verify-preservation.sh`
- **Verification:** `bash -n .planning/preservation/verify-preservation.sh`, `bash .planning/preservation/verify-preservation.sh --dossier-only`, and `bash .planning/preservation/verify-preservation.sh`
- **Committed in:** `f6b98344b`

---

**Total deviations:** 1 auto-fixed (Rule 2)
**Impact on plan:** Correctness strengthening only; it directly implements the plan threat mitigation.

## Issues Encountered

None.

## Known Stubs

| File | Line | Reason |
|------|------|--------|
| `.planning/preservation/FALKON-TO-CHROMIUM-PRESERVATION.md` | 217 | Existing dossier note says `sidebar-flip.svg` was a custom placeholder because the original glyph was Pro-only; it is an intentional v1 asset provenance note and does not block this migration contract. |

## Auth Gates

None.

## User Setup Required

None.

## Verification

- `git diff --check`
- `bash .planning/preservation/verify-preservation.sh --dossier-only`
- `bash .planning/preservation/verify-preservation.sh`
- `rg 'Capability Migration Map|Chromium Owner|Parity Evidence|License / Attribution Note' .planning/preservation/FALKON-TO-CHROMIUM-PRESERVATION.md`

## Next Phase Readiness

Plan 11-03 can now extend the same canonical dossier with the deferred visual-check ledger while relying on the preservation verifier to protect the migration-map and license-boundary contract.

## Self-Check: PASSED

- Found `.planning/preservation/FALKON-TO-CHROMIUM-PRESERVATION.md`
- Found `.planning/preservation/verify-preservation.sh`
- Found `.planning/phases/11-preservation-contract-and-falkon-freeze/11-02-SUMMARY.md`
- Found task commits `e500ec205` and `f6b98344b`
- Full preservation verifier passed after summary creation

---
*Phase: 11-preservation-contract-and-falkon-freeze*
*Completed: 2026-06-23*
