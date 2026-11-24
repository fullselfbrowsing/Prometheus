---
phase: 11-preservation-contract-and-falkon-freeze
plan: 03
subsystem: preservation
tags: [falkon, chromium, visual-ledger, freeze-checklist, stale-doc-gate]

requires:
  - phase: 11-02
    provides: Capability-first Falkon-to-Chromium migration map and verifier invariants
provides:
  - 26-row deferred v1 visual-check ledger with Chromium owners and future evidence
  - Source wipe and freeze checklist distinguishing already_removed, must_stay, reference_only, and future_chromium_owned items
  - Stale-doc verification gate for root docs, current state, and Chromium handoff status
affects: [phase-12-chromium-baseline, phase-16-webui-new-tab, phase-20-fsb-runtime, phase-23-parity-security, phase-24-packaging]

tech-stack:
  added: []
  patterns: [deferred visual-check ledger, stale-doc grep gate, source-freeze status table]

key-files:
  created:
    - .planning/phases/11-preservation-contract-and-falkon-freeze/11-03-SUMMARY.md
  modified:
    - .planning/preservation/FALKON-TO-CHROMIUM-PRESERVATION.md
    - .planning/preservation/verify-preservation.sh
    - README.md
    - .planning/STATE.md
    - .planning/chromium/CHROMIUM-CHECKOUT.md

key-decisions:
  - "Carry all 26 deferred Phase 08, 09, and 10 human visual checks forward as Chromium-owned checks instead of marking any complete or retiring them prematurely."
  - "Treat the first Chromium build as completed with exit status 0 while keeping unmodified launch verification in Phase 12 scope."
  - "Use the preservation verifier as the gate for visual-ledger count, freeze-status vocabulary, and stale active-Falkon/build wording."

patterns-established:
  - "Visual ledger rows use stable VIS-08/VIS-09/VIS-10 IDs with original phase, original check, Chromium owner, status, and future evidence."
  - "Freeze checklist rows separate removed source, must-keep preservation/planning artifacts, reference-only GPL material, and future Chromium-owned work."
  - "Stale-doc checks fail on active Falkon build commands or obsolete running-build handoff claims in README, STATE, and Chromium checkout docs."

requirements-completed: [PRES-02, PRES-05, PRES-06, PRES-07]

duration: 6min
completed: 2026-06-23
---

# Phase 11 Plan 03: Deferred Visual Ledger and Freeze Cleanup Summary

**Deferred visual checks and source-freeze rules are now preserved in the canonical dossier and enforced by the preservation verifier.**

## Performance

- **Duration:** 6min
- **Started:** 2026-06-23T18:30:44Z
- **Completed:** 2026-06-23T18:36:07Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Added `## Deferred Visual Check Ledger` with exactly 26 `VIS-08-*`, `VIS-09-*`, and `VIS-10-*` carry-forward rows, each with a Chromium owner and future evidence path.
- Added `## Source Wipe And Freeze Checklist` with the required `already_removed`, `must_stay`, `reference_only`, and `future_chromium_owned` statuses.
- Updated README, STATE, and Chromium handoff docs so Falkon is described as a preserved v1 reference and the first Chromium build is recorded as successfully completed, with launch verification left to Phase 12.
- Extended `verify-preservation.sh` with `check_visual_ledger`, `check_freeze_docs`, and `check_stale_docs`.

## Task Commits

1. **Task 1: Add the 26-row deferred visual-check ledger** - `e441348dd` (docs)
2. **Task 2: Add wipe/freeze checklist and reconcile stale docs** - `0cd1ba37f` (fix)

## Files Created/Modified

- `.planning/preservation/FALKON-TO-CHROMIUM-PRESERVATION.md` - Adds the visual-check ledger and source wipe/freeze checklist.
- `.planning/preservation/verify-preservation.sh` - Enforces visual-ledger, freeze-status, and stale-doc invariants.
- `README.md` - Replaces active Qt/Falkon build wording with Chromium migration and preserved-reference guidance.
- `.planning/STATE.md` - Records Phase 11 preservation execution and completed Chromium build evidence.
- `.planning/chromium/CHROMIUM-CHECKOUT.md` - Replaces first-build handoff wording with first-build result evidence.
- `.planning/phases/11-preservation-contract-and-falkon-freeze/11-03-SUMMARY.md` - Records execution, verification, and self-check evidence.

## Decisions Made

- Keep every deferred visual check as `carry_forward`; none were retired because each maps to a Chromium-equivalent product surface or release validation check.
- Keep the completed Chromium build evidence separate from Phase 12 launch validation, so later agents do not confuse a successful build with a verified launch.
- Gate stale docs with a small grep pattern set rather than relying on manual review.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None. A pre-existing local modification to `.planning/config.json` was present before this plan and was left unstaged.

## Known Stubs

| File | Line | Reason |
|------|------|--------|
| `.planning/preservation/FALKON-TO-CHROMIUM-PRESERVATION.md` | 217 | Existing dossier note says `sidebar-flip.svg` was a custom placeholder because the original glyph was Pro-only; it is an intentional v1 asset provenance note. |
| `.planning/STATE.md` | 132 | Existing decision note records the same intentional `sidebar-flip` placeholder provenance; it is not unfinished functionality. |

## Auth Gates

None.

## User Setup Required

None.

## Verification

- `git diff --check`
- `bash -n .planning/preservation/verify-preservation.sh`
- `bash .planning/preservation/verify-preservation.sh --dossier-only`
- `bash .planning/preservation/verify-preservation.sh`
- `test "$(rg -c '^\| VIS-(08|09|10)-' .planning/preservation/FALKON-TO-CHROMIUM-PRESERVATION.md)" = "26"`
- `! rg -n 'cmake -S falkon|falkon/tools|detached.*screen|prometheus-chromium-build.*running|built on Qt and QtWebEngine' README.md .planning/STATE.md .planning/chromium/CHROMIUM-CHECKOUT.md`

## Next Phase Readiness

Phase 12 can treat the Falkon source as preserved/frozen, consume the 26-row visual ledger for future Chromium-equivalent checks, and focus on unmodified Chromium launch verification before Prometheus patches begin.

## Self-Check: PASSED

- Found `.planning/preservation/FALKON-TO-CHROMIUM-PRESERVATION.md`
- Found `.planning/preservation/verify-preservation.sh`
- Found `README.md`
- Found `.planning/STATE.md`
- Found `.planning/chromium/CHROMIUM-CHECKOUT.md`
- Found `.planning/phases/11-preservation-contract-and-falkon-freeze/11-03-SUMMARY.md`
- Found task commits `e441348dd` and `0cd1ba37f`
- Full preservation verifier passed after summary creation

---
*Phase: 11-preservation-contract-and-falkon-freeze*
*Completed: 2026-06-23*
