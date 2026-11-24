---
phase: 20-fsb-runtime-providers-vault-memory-logs-and-control-panel
fixed_at: 2026-07-20T11:53:58-05:00
review_path: .planning/phases/20-fsb-runtime-providers-vault-memory-logs-and-control-panel/20-REVIEW.md
iteration: 2
findings_in_scope: 2
fixed: 2
skipped: 0
status: all_fixed
---

# Phase 20: Code Review Fix Report

**Fixed at:** 2026-07-20T11:53:58-05:00
**Source review:** `.planning/phases/20-fsb-runtime-providers-vault-memory-logs-and-control-panel/20-REVIEW.md`
**Iteration:** 2

**Summary:**

- Findings in scope: 2
- Fixed: 2
- Skipped: 0

## Fixed Issues

### WR-08: Released Agent-session tombstones grow for the profile lifetime

**Status:** fixed: requires human verification
**Files modified:** `prometheus_runtime_profile_service.cc`, `prometheus_runtime_profile_service.h`, `prometheus_runtime_profile_service_unittest.cc`
**Commits:** Chromium `c5453efdc54ea313cb5bc08c84ed09a78a83f8fd`; root patch export `9cdf860b7ec7fc7778bd24faa51fdb60dc30d928`
**Patch:** `0052-fix-20-wr-08-retire-released-session-tombstones.patch`; SHA-256 `e9b8285847f4c74bf9ea85f61083de7955774f1f184ffdb9dc267b05194be7eb`
**Applied fix:** Replaced the profile-lifetime released-session tombstone set with live ownership tracking. Principal creation and accepted task admission register the session while the service owns close/release responsibility; release erases that live entry before invoking either boundary, so duplicate principal, session-loss, and shutdown paths remain exactly-once without retaining dead identifiers.
**Verification:** The fake boundary now emits production-shaped unique session IDs and tracks per-ID close/release counts. A stress regression creates and releases more than the retained task bound, observes a maximum bookkeeping size of one and a final size of zero, then exercises duplicate loss and shutdown. Exact direct compiles passed; the focused lifecycle filter passed `4/4`; the full runtime-profile suite passed `46/46`; and the complete Phase 20 native gate passed `203/203`.

### WR-09: The patch gate does not verify patch-content identity

**Status:** fixed: requires human verification
**Files modified:** `.planning/chromium/verify-phase-20.sh`, `20-VALIDATION.md`, `20-VERIFICATION.md`, `FALKON-TO-CHROMIUM-PRESERVATION.md`
**Commit:** root `e8e7f7824a9c702f0d1ad842739a56f6631199dd`
**Applied fix:** The authoritative verifier now derives exactly one well-formed `git patch-id --stable` for every ordered mail patch and the corresponding `git show --pretty=format: --binary` commit diff, and fails closed on command errors, malformed or multiple identities, or unequal bodies. Existing From-line, order, source-only artifact, and parse checks remain. A deterministic self-test changes a non-whitespace added line in patch 0052, proves the changed patch still applies to the claimed commit parent through an isolated index, and requires the identity comparison to reject it.
**Verification:** Focused `--patches-only` runs passed all `52/52` real patch/commit pairs and rejected the valid mutation (`2493697af1acade54eff3a76c98ed2f6eb8d79d4` versus `f362127ed08dd35eecf37666c6450f9647c2e714`). The final no-argument verifier repeated the real-pair and mutation gates successfully. Current validation, verification, and preservation evidence now agree on 52 patches, 203 Phase 20 native tests, 24 content/renderer tests, 84 native regressions, 36 Phase 20 browser tests, 83 browser regressions, and 75 Node tests.

## Verification and Closeout

- Exact command `bash .planning/chromium/verify-phase-20.sh` exited 0 from the actual root workspace.
- Fresh results: Phase 20 native `203/203`; content/renderer `24/24`; Phase 17-19 native regressions `84/84`; Phase 20 browser `36/36`; Phase 17-19 browser regressions `83/83`; Node `75/75` with fail/cancelled/skipped/TODO all zero; built-app external MCP smoke passed.
- All 52 ordered Chromium patches have exact stable body identity with the 52-commit nested baseline range; the deterministic valid-mutation self-test fails closed.
- Reviewed build metadata remained byte-identical: `.ninja_log` SHA-256 `eccf79f3dfdc6c8d51af20f56bf1973eb35ff486b1dab9b2b0653cc37b586dce`; `.ninja_deps` SHA-256 `ab1a6ad4639e8db53459384f8636dc53f396397363f3c2751bcdadc0349947c0`.
- Live branches remain `chromium` at `e8e7f7824a9c702f0d1ad842739a56f6631199dd` and `prometheus/phase-14-assets` at `c5453efdc54ea313cb5bc08c84ed09a78a83f8fd`.

## Skipped Issues

None.

---

_Fixed: 2026-07-20T11:53:58-05:00_
_Fixer: the agent (gsd-code-fixer)_
_Iteration: 2_
