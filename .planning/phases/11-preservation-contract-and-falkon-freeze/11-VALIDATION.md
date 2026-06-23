---
phase: 11
slug: preservation-contract-and-falkon-freeze
status: ready
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-23
---

# Phase 11 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Shell-based preservation gate plus docs-lint commands |
| **Config file** | `.planning/preservation/verify-preservation.sh` planned in `11-01-PLAN.md` |
| **Quick run command** | `git diff --check && bash .planning/preservation/verify-preservation.sh` |
| **Full suite command** | `git diff --check && bash .planning/preservation/verify-preservation.sh && rg 'Chromium Owner|Parity Evidence|License Note|VIS-08|VIS-09|VIS-10|carry_forward|retired' .planning/preservation/FALKON-TO-CHROMIUM-PRESERVATION.md` |
| **Estimated runtime** | ~60 seconds |

---

## Sampling Rate

- **After every task commit:** Run `git diff --check` plus the focused `rg`/shell check for the edited section.
- **After every plan wave:** Run `git diff --check && bash .planning/preservation/verify-preservation.sh`.
- **Before `$gsd-verify-work`:** Full suite must be green.
- **Max feedback latency:** 60 seconds.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 11-01-01 | 01 | 1 | PRES-01, PRES-05 | T-11-01, T-11-02 | Bundle recovery proves expected HEAD and 81 patches without recreating active `falkon/` | smoke | `bash -n .planning/preservation/verify-preservation.sh && test -x .planning/preservation/verify-preservation.sh && bash .planning/preservation/verify-preservation.sh --artifacts-only` | planned in 11-01 | pending |
| 11-01-02 | 01 | 1 | PRES-01, PRES-04, PRES-05 | T-11-03, T-11-04, T-11-05 | Dossier records preservation evidence, active checkout status, and strict no-copy GPL boundary | docs-lint | `git diff --check && bash .planning/preservation/verify-preservation.sh` | planned in 11-01 | pending |
| 11-02-01 | 02 | 2 | PRES-02, PRES-03, PRES-04 | T-11-06, T-11-07, T-11-08, T-11-09, T-11-10 | Capability map preserves contracts with Chromium owner, parity evidence, and license/attribution note | docs-lint | `rg 'Capability Migration Map|Chromium Owner|Parity Evidence|License / Attribution Note' .planning/preservation/FALKON-TO-CHROMIUM-PRESERVATION.md` | planned in 11-02 | pending |
| 11-02-02 | 02 | 2 | PRES-02, PRES-03, PRES-04 | T-11-06, T-11-09, T-11-10 | Verifier fails if migration-map columns, owner phases, required capability rows, or license labels disappear | docs-lint | `bash .planning/preservation/verify-preservation.sh --dossier-only && bash .planning/preservation/verify-preservation.sh` | planned in 11-02 | pending |
| 11-03-01 | 03 | 3 | PRES-07 | T-11-11, T-11-12 | All 26 deferred visual checks are marked `carry_forward` or `retired` with Chromium owner and rationale/future evidence | docs-lint | `test "$(rg -c '^\| VIS-(08|09|10)-' .planning/preservation/FALKON-TO-CHROMIUM-PRESERVATION.md)" = "26"` | planned in 11-03 | pending |
| 11-03-02 | 03 | 3 | PRES-02, PRES-05, PRES-06, PRES-07 | T-11-13, T-11-14, T-11-15 | Freeze checklist and stale-doc verifier prevent active-Falkon or running-build false claims | docs-lint | `git diff --check && bash .planning/preservation/verify-preservation.sh && ! rg -n 'cmake -S falkon|falkon/tools|detached.*screen|prometheus-chromium-build.*running|built on Qt and QtWebEngine' README.md .planning/STATE.md .planning/chromium/CHROMIUM-CHECKOUT.md` | planned in 11-03 | pending |

*Status: pending / green / red / flaky*

---

## Wave 0 Requirements

- [x] `11-01-PLAN.md` Task 1 creates `.planning/preservation/verify-preservation.sh` to verify bundle integrity, expected HEAD, patch count 81, temporary restore clone, active `falkon/` absence, and `.context/falkon-preservation/` ignore status.
- [x] `11-02-PLAN.md` Task 1 adds the normalized migration map table with `Chromium Owner`, `Parity Evidence`, and `License / Attribution Note` columns.
- [x] `11-03-PLAN.md` Task 1 adds the 26-row deferred visual-check ledger using `VIS-08-*`, `VIS-09-*`, and `VIS-10-*` IDs.
- [x] `11-03-PLAN.md` Task 2 reconciles false current-state claims about active Falkon source and running Chromium build in README/STATE/Chromium handoff docs.

---

## Manual-Only Verifications

All Phase 11 behaviors have automated or docs-lint verification. Live Chromium launch remains Phase 12 scope.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies.
- [x] Sampling continuity: no 3 consecutive tasks without automated verify.
- [x] Wave 0 covers all MISSING references through planned tasks.
- [x] No watch-mode flags.
- [x] Feedback latency < 60s.
- [x] `nyquist_compliant: true` set in frontmatter after all validation gaps were assigned to concrete plan tasks.

**Approval:** approved 2026-06-23 for planning; execution must update task statuses when checks pass.
