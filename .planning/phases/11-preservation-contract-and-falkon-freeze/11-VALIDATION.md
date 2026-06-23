---
phase: 11
slug: preservation-contract-and-falkon-freeze
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-23
---

# Phase 11 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Shell-based preservation gate plus docs-lint commands |
| **Config file** | none - Wave 0 creates `.planning/preservation/verify-preservation.sh` |
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
| 11-01-01 | 01 | 1 | PRES-01, PRES-05 | T-11-01 | Bundle recovery proves expected HEAD without recreating active `falkon/` | smoke | `bash .planning/preservation/verify-preservation.sh` | missing W0 | pending |
| 11-01-02 | 01 | 1 | PRES-02, PRES-03 | T-11-02 | Dossier contains capability map with Chromium owner, parity evidence, and license note columns | docs-lint | `rg 'Chromium Owner|Parity Evidence|License Note' .planning/preservation/FALKON-TO-CHROMIUM-PRESERVATION.md` | partial | pending |
| 11-01-03 | 01 | 1 | PRES-04 | T-11-03 | License boundary says GPL Falkon implementation is reference-only unless license review permits copy | docs-lint | `rg 'GPL|license review|reference-only|Do not copy' .planning/preservation/FALKON-TO-CHROMIUM-PRESERVATION.md` | partial | pending |
| 11-02-01 | 02 | 1 | PRES-07 | T-11-04 | All 26 deferred visual checks are marked `carry_forward` or `retired` with Chromium owner/rationale | docs-lint | `rg 'VIS-08|VIS-09|VIS-10|carry_forward|retired' .planning/preservation/FALKON-TO-CHROMIUM-PRESERVATION.md` | missing W0 | pending |
| 11-02-02 | 02 | 1 | PRES-06 | T-11-05 | Stale current-state docs no longer claim an active `falkon/` source tree or running Chromium build | docs-lint | `! rg -n 'cmake -S falkon|falkon/tools|detached.*screen|prometheus-chromium-build.*running' README.md .planning/STATE.md .planning/chromium/CHROMIUM-CHECKOUT.md` | missing W0 | pending |

*Status: pending / green / red / flaky*

---

## Wave 0 Requirements

- [ ] `.planning/preservation/verify-preservation.sh` - verifies bundle integrity, expected HEAD, patch count 81, temporary restore clone, active `falkon/` absence, and `.context/falkon-preservation/` ignore status.
- [ ] `.planning/preservation/FALKON-TO-CHROMIUM-PRESERVATION.md` - add normalized migration map table with `Chromium Owner`, `Parity Evidence`, and `License Note` columns.
- [ ] `.planning/preservation/FALKON-TO-CHROMIUM-PRESERVATION.md` - add 26-row deferred visual-check ledger using `VIS-08-*`, `VIS-09-*`, and `VIS-10-*` IDs.
- [ ] README/STATE/Chromium handoff docs - reconcile false current-state claims about active Falkon source and running Chromium build.

---

## Manual-Only Verifications

All Phase 11 behaviors have automated or docs-lint verification. Live Chromium launch remains Phase 12 scope.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies.
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify.
- [ ] Wave 0 covers all MISSING references.
- [ ] No watch-mode flags.
- [ ] Feedback latency < 60s.
- [ ] `nyquist_compliant: true` set in frontmatter after Wave 0 checks exist and pass.

**Approval:** pending
