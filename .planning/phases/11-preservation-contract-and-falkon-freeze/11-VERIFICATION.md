---
phase: 11-preservation-contract-and-falkon-freeze
verified: 2026-06-23T18:56:10Z
status: passed
score: "12/12 must-haves verified"
overrides_applied: 0
---

# Phase 11: Preservation Contract and Falkon Freeze Verification Report

**Phase Goal:** Make source removal recoverable and make the migration contract explicit.
**Verified:** 2026-06-23T18:56:10Z
**Status:** passed
**Re-verification:** No - initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Falkon v1 bundle restores the full preserved reference. | VERIFIED | Direct restore clone from `.context/falkon-preservation/falkon-prometheus-v1.bundle` produced HEAD `b0521c9d37e7545c680b78dfcc24f777a984091c`; `git bundle verify` passed. |
| 2 | Patch series is available under `.context/falkon-preservation/patches/`. | VERIFIED | Direct `find` count returned `81`; `verify-preservation.sh` enforces `expected_patch_count="81"`. |
| 3 | One preservation gate verifies bundle, expected refs, patch count, temporary restore, root `falkon/` absence, ignore coverage, and tracking state. | VERIFIED | `bash .planning/preservation/verify-preservation.sh` exited 0 and printed `Preservation verification passed.`; script lines 27-70 implement artifact checks. |
| 4 | No long-lived active `falkon/` checkout is recreated. | VERIFIED | `test -d falkon` failed as expected; direct check reported `root_falkon=absent`; restore-check temp directories remaining: `0`. |
| 5 | Canonical dossier records preservation evidence and GPL/license boundary. | VERIFIED | Dossier has `Preservation Evidence Gate` at line 54 and the default GPL boundary at line 74. |
| 6 | Dossier captures decisions, assets, design tokens, behavior contracts, source references, and license boundaries. | VERIFIED | Dossier sections cover Non-Negotiables, Source State, Licensing Boundary, Canonical Design Language, Asset Inventory, Behavior Inventory, Capability Migration Map, and Migration Rule. |
| 7 | Capability migration map assigns major v1 capabilities to Chromium owners, parity evidence, and license/attribution notes. | VERIFIED | `## Capability Migration Map` at line 320 with required six-column table and Phase 13-24 owners. |
| 8 | Migration rows distinguish behavior/design contracts from GPL Falkon implementation code. | VERIFIED | License/status labels `contract_only`, `product_owned`, `third_party_attribution_required`, `reference_only`, and `license_review_required` are present and enforced by `check_migration_map()`. |
| 9 | Verifier fails if dossier loses migration-map/license/visual-ledger/freeze/stale-doc invariants. | VERIFIED | `check_migration_map`, `check_visual_ledger`, `check_freeze_docs`, and `check_stale_docs` are wired in full mode and `--dossier-only`. |
| 10 | All 26 deferred v1 human-needed visual checks are represented as `VIS-08-*`, `VIS-09-*`, or `VIS-10-*` rows. | VERIFIED | Prompt ledger-count command passed; lines 349-374 contain exactly 26 rows. |
| 11 | Each deferred visual row has Chromium owner, `carry_forward`/`retired` status, and future evidence/rationale. | VERIFIED | All 26 rows use `carry_forward`, name later phase owners, and specify future Chromium evidence. |
| 12 | README, STATE, Chromium handoff docs, and dossier no longer claim root `falkon/` is active production source or the first Chromium build is running. | VERIFIED | Stale-doc pattern scan returned no matches; README lines 44/48 describe Falkon as preserved reference, not production base; Chromium handoff line 124 records build completed successfully. |

**Score:** 12/12 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `.planning/preservation/verify-preservation.sh` | Executable preservation/dossier/stale-doc gate | VERIFIED | Exists, substantive, executable, and passed full run. Artifact helper passed in all three plans. |
| `.planning/preservation/FALKON-TO-CHROMIUM-PRESERVATION.md` | Canonical preservation dossier | VERIFIED | Contains evidence gate, license boundary, design/assets/behavior inventory, migration map, visual ledger, and freeze checklist. |
| `.context/falkon-preservation/falkon-prometheus-v1.bundle` | Recoverable local Falkon v1 Git bundle | VERIFIED | Exists, non-empty, `git bundle verify` passed, HEAD/master/restored HEAD all equal expected SHA. |
| `.context/falkon-preservation/patches/` | 81-patch preserved series | VERIFIED | Directory exists with exactly 81 `.patch` files. |
| `README.md` | Root docs reconciled to Chromium migration status | VERIFIED | Manual check confirms equivalent wording: Falkon is now a preserved reference, not production base. The helper missed only the exact phrase `Falkon is a preserved v1 reference`. |
| `.planning/STATE.md` | Current state reconciled with finished Chromium build evidence | VERIFIED | Records first Chromium build status `0`, no active screen during Phase 11 research, and Phase 12 launch verification as next scope. |
| `.planning/chromium/CHROMIUM-CHECKOUT.md` | Chromium handoff no longer describes a running detached build | VERIFIED | `## First Build Result` records successful build and launch verification deferred to Phase 12. |
| `.planning/phases/11-preservation-contract-and-falkon-freeze/11-REVIEW.md` | Clean code review report | VERIFIED | Frontmatter has `status: clean`, critical/warning/info totals all zero. |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `verify-preservation.sh` | Falkon bundle | `git bundle verify` and temporary clone | VERIFIED | `gsd-tools verify key-links 11-01` passed; direct restore also passed. |
| `verify-preservation.sh` | Patch directory | Patch count equals 81 | VERIFIED | `gsd-tools verify key-links 11-01` passed; direct count returned 81. |
| Dossier | Future Chromium implementation phases | Reference-only GPL boundary | VERIFIED | `gsd-tools verify key-links 11-01` passed. |
| Dossier | Roadmap phases 13-24 | `Chromium Owner` column | VERIFIED | `gsd-tools verify key-links 11-02` passed. |
| Dossier | License boundary | `License / Attribution Note` column | VERIFIED | `gsd-tools verify key-links 11-02` passed. |
| Phase 08 verification | Dossier | `VIS-08-01` through `VIS-08-10` rows | VERIFIED | `gsd-tools verify key-links 11-03` passed. |
| Phase 09 verification | Dossier | `VIS-09-01` through `VIS-09-08` rows | VERIFIED | `gsd-tools verify key-links 11-03` passed. |
| Phase 10 verification | Dossier | `VIS-10-01` through `VIS-10-08` rows | VERIFIED | `gsd-tools verify key-links 11-03` passed. |
| `verify-preservation.sh` | README/STATE/Chromium docs | Stale active-source/build grep checks | VERIFIED | `check_stale_docs()` wired and full preservation gate passed. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| `.planning/preservation/verify-preservation.sh` | Bundle HEAD/master/restored HEAD, patch count, ignore/tracked state | Git bundle, temp clone, filesystem, root git | Yes - live local commands read actual artifacts | FLOWING |
| `.planning/preservation/FALKON-TO-CHROMIUM-PRESERVATION.md` | N/A | Static canonical dossier | N/A - documentation contract | NOT_APPLICABLE |
| README/STATE/Chromium docs | N/A | Static project documentation | N/A - documentation contract | NOT_APPLICABLE |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Whitespace sanity | `git diff --check` | exit 0 | PASS |
| Full preservation gate | `bash .planning/preservation/verify-preservation.sh` | `Preservation verification passed.` | PASS |
| Schema drift | `node /Users/lakshman/.codex/get-shit-done/bin/gsd-tools.cjs verify schema-drift 11` | `drift_detected: false`, `blocking: false` | PASS |
| Visual ledger count | Prompt command: count `VIS-08`, `VIS-09`, and `VIS-10` table rows and require `26` | exit 0 | PASS |
| Direct bundle restore | temporary `git clone` from bundle and `rev-parse HEAD` | restored expected HEAD `b0521c9d37e7545c680b78dfcc24f777a984091c` | PASS |
| Preservation artifacts ignored/untracked | `git check-ignore -v ...` and `git ls-files -- ...` | `.context/` ignore rule matched; no tracked files | PASS |
| Stale docs absent | Prompt stale-doc pattern scan over README, STATE, and Chromium handoff docs | no matches | PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| PRES-01 | 11-01 | Recover full Falkon-based Prometheus v1 source reference from local bundle after active `falkon/` removal. | SATISFIED | Bundle verified and restored to `b0521c9d37e7545c680b78dfcc24f777a984091c`; root `falkon/` absent. |
| PRES-02 | 11-02, 11-03 | Written inventory of decisions, tokens, UI surfaces, assets, tool contracts, tests, validation scripts, and deferred verification items. | SATISFIED | Dossier contains non-negotiables, design language, asset inventory, behavior inventory, migration map, and 26-row deferred visual ledger. |
| PRES-03 | 11-02 | Explicit migration map from v1 Falkon/Qt surfaces to Chromium-native owners or future/deferred owners. | SATISFIED | Capability Migration Map rows assign owners across Phases 13-24 with parity evidence. |
| PRES-04 | 11-01, 11-02 | Distinguish behavior/design contracts from GPL-derived Falkon implementation code. | SATISFIED | Default GPL boundary and per-row license/attribution statuses are present and verifier-enforced. |
| PRES-05 | 11-01, 11-03 | Remove active `falkon/` checkout without losing source history, patches, assets, or planning context. | SATISFIED | Root `falkon/` absent; bundle and 81 patches preserved under ignored `.context/`; freeze checklist marks must-stay items. |
| PRES-06 | 11-03 | Root docs no longer present Falkon/QtWebEngine as production architecture after Chromium baseline. | SATISFIED | README/STATE/Chromium docs describe Falkon as preserved/reference-only and build as completed, not running. |
| PRES-07 | 11-03 | Deferred v1 human visual checks accounted for against Chromium equivalents or retirement rationale. | SATISFIED | All 26 checks are carried forward as Chromium-equivalent rows with later phase owners and future evidence; none retired prematurely. |

No orphaned Phase 11 requirements found: the phase plans collectively declare PRES-01 through PRES-07, matching `.planning/REQUIREMENTS.md` and `.planning/ROADMAP.md`.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `.planning/STATE.md` | 133 | `sidebar-flip placeholder SVG` | INFO | Intentional v1 asset provenance note; not a Phase 11 implementation stub. |
| `.planning/preservation/FALKON-TO-CHROMIUM-PRESERVATION.md` | 220 | `sidebar-flip.svg` custom placeholder | INFO | Intentional Font Awesome Free/provenance note, already documented. |
| `.planning/preservation/verify-preservation.sh` | 47 | `restore-check-XXXXXX` | INFO | Valid `mktemp` template, not a placeholder implementation. |

### Human Verification Required

None for Phase 11. The phase goal is preservation and migration-contract evidence. The 26 visual checks remain future Chromium-owned UAT obligations and are explicitly carried forward in the dossier.

### Gaps Summary

No blocking gaps found. The only helper mismatch was a literal README pattern from Plan 11-03; manual verification confirmed equivalent wording that satisfies the intended artifact contract.

---

_Verified: 2026-06-23T18:56:10Z_
_Verifier: Claude (gsd-verifier)_
