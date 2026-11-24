---
phase: 11-preservation-contract-and-falkon-freeze
plan: 01
subsystem: preservation
tags: [falkon, chromium, git-bundle, license-boundary, gpl]

requires:
  - phase: v2.0-start
    provides: Falkon v1 bundle and 81-patch preservation archive under .context/falkon-preservation/
provides:
  - Executable preservation verification gate for the archived Falkon v1 bundle
  - Canonical dossier evidence targets and GPL-to-Chromium license boundary
affects: [phase-12-chromium-baseline, phase-13-brand-legal, phase-23-de-falkon-gate]

tech-stack:
  added: [bash, git-bundle, ripgrep]
  patterns: [evidence-first preservation gate, reference-only GPL boundary]

key-files:
  created:
    - .planning/preservation/verify-preservation.sh
  modified:
    - .planning/preservation/FALKON-TO-CHROMIUM-PRESERVATION.md

key-decisions:
  - "Preservation verification must prove bundle integrity, expected refs, patch count 81, temporary restore, and root git ignore coverage."
  - "Falkon GPL implementation, Qt/QSS/package metadata, and copied GPL text remain reference-only or license-review-required for Chromium migration."

patterns-established:
  - "Preservation gate: use git bundle verify, literal ref checks, temporary restore-check clone, and dossier invariant checks."
  - "Carry-forward classification: separate contract_only, product_owned, third_party_attribution_required, reference_only, and license_review_required materials."

requirements-completed: [PRES-01, PRES-04, PRES-05]

duration: 3min
completed: 2026-06-23
---

# Phase 11 Plan 01: Preservation Evidence Gate Summary

**Recoverable Falkon v1 preservation gate with canonical evidence targets and a strict GPL-to-Chromium reference boundary.**

## Performance

- **Duration:** 3min
- **Started:** 2026-06-23T18:16:38Z
- **Completed:** 2026-06-23T18:19:58Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Added `.planning/preservation/verify-preservation.sh`, an executable gate that verifies the local Falkon bundle, expected HEAD/master refs, 81 patches, temporary restore recovery, absent root `falkon/`, and `.context/` ignore coverage.
- Updated the canonical preservation dossier with the expected HEAD, patch count, bundle and patch paths, restore-check path pattern, active checkout status `already_removed`, and the downstream verification command.
- Added a visible default license rule and carry-forward classification table separating behavior contracts, product assets, third-party-attributed assets, reference-only Falkon material, and license-review-required GPL text.

## Task Commits

1. **Task 1: Create the preservation evidence gate script** - `9d2fb121a` (feat)
2. **Task 2: Add preservation evidence and GPL boundary to the canonical dossier** - `3e84c5332` (docs)

## Files Created/Modified

- `.planning/preservation/verify-preservation.sh` - Executable preservation gate for bundle, refs, patch count, restore clone, active checkout absence, ignore coverage, and dossier invariants.
- `.planning/preservation/FALKON-TO-CHROMIUM-PRESERVATION.md` - Canonical evidence block and GPL-to-Chromium license boundary classifications.

## Decisions Made

- Use literal `HEAD` and `refs/heads/master` rows from `git ls-remote` so bundle verification is not confused by `refs/remotes/origin/HEAD`.
- Keep the dossier as the only canonical preservation document and make future Chromium phases run `bash .planning/preservation/verify-preservation.sh`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed bundle ref parsing in the preservation script**
- **Found during:** Task 1 (Create the preservation evidence gate script)
- **Issue:** `git ls-remote "$bundle" HEAD` also returned `refs/remotes/origin/HEAD`, causing the HEAD comparison to include two SHAs and fail.
- **Fix:** Selected only the literal `HEAD` row and only the literal `refs/heads/master` row; also silenced successful `git bundle verify` output so success prints exactly `Preservation verification passed.`.
- **Files modified:** `.planning/preservation/verify-preservation.sh`
- **Verification:** `bash -n .planning/preservation/verify-preservation.sh && test -x .planning/preservation/verify-preservation.sh && bash .planning/preservation/verify-preservation.sh --artifacts-only`
- **Committed in:** `9d2fb121a`

---

**Total deviations:** 1 auto-fixed (Rule 1)
**Impact on plan:** Correctness fix only; no scope expansion.

## Issues Encountered

None remaining. A parallel cleanup scan briefly observed a `restore-check-*` directory while the verification clone was still running; a sequential follow-up confirmed no restore-check directory remained.

## Known Stubs

| File | Line | Reason |
|------|------|--------|
| `.planning/preservation/FALKON-TO-CHROMIUM-PRESERVATION.md` | 217 | Existing dossier note says `sidebar-flip.svg` was a custom placeholder because the original glyph was Pro-only; it is an intentional v1 asset provenance note and does not block this preservation gate. |

## Auth Gates

None.

## User Setup Required

None.

## Verification

- `bash -n .planning/preservation/verify-preservation.sh`
- `test -x .planning/preservation/verify-preservation.sh`
- `git diff --check`
- `bash .planning/preservation/verify-preservation.sh`

## Next Phase Readiness

Plans 11-02 and 11-03 can consume the gate and dossier boundary as the canonical preservation contract before expanding the migration map, deferred visual-check ledger, and stale-doc cleanup gates.

## Self-Check: PASSED

- Found `.planning/preservation/verify-preservation.sh`
- Found `.planning/preservation/FALKON-TO-CHROMIUM-PRESERVATION.md`
- Found `.planning/phases/11-preservation-contract-and-falkon-freeze/11-01-SUMMARY.md`
- Found task commits `9d2fb121a` and `3e84c5332`
- Full preservation gate passed after summary creation

---
*Phase: 11-preservation-contract-and-falkon-freeze*
*Completed: 2026-06-23*
