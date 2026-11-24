---
phase: 12
slug: chromium-checkout-build-and-patch-discipline
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-06-23
---

# Phase 12 - Validation Strategy

> Per-phase validation contract for the Chromium checkout, build, launch, and artifact-isolation baseline.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Bash script gates plus Chromium `gn` and `autoninja`; no root pytest/jest/vitest framework exists. |
| **Config file** | Chromium build config at `.context/chromium/src/out/Default/args.gn`; root planning scripts under `.planning/chromium/`. |
| **Quick run command** | `git diff --check && bash -n .planning/chromium/*.sh && bash .planning/chromium/check-chromium-env.sh && bash .planning/chromium/verify-artifact-isolation.sh` |
| **Full suite command** | `git diff --check && bash .planning/chromium/check-chromium-env.sh && bash .planning/chromium/build-chromium-baseline.sh --no-op-ok && bash .planning/chromium/smoke-launch-unmodified.sh && bash .planning/chromium/verify-artifact-isolation.sh` |
| **Estimated runtime** | ~60 seconds for quick checks after scripts exist; full suite may take longer if `autoninja` has real work. |

---

## Sampling Rate

- **After every task commit:** Run `git diff --check`, `bash -n .planning/chromium/*.sh`, and the focused script or `rg` check for the edited artifact.
- **After every plan wave:** Run `bash .planning/chromium/check-chromium-env.sh`, `bash .planning/chromium/verify-artifact-isolation.sh`, and any build/launch script introduced in that wave.
- **Before `$gsd-verify-work`:** Full suite must be green. If unmodified launch fails, Phase 12 records a blocker and Prometheus-specific Chromium patches remain blocked.
- **Max feedback latency:** 60 seconds for static/env/isolation checks; build and launch checks are required at phase gates even if slower.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 12-W0-01 | 01 | 1 | CHROM-01, CHROM-03, CHROM-05 | T-12-01, T-12-02 | Environment checks use explicit `.context` paths and fail before long Chromium commands. | env/static | `bash -n .planning/chromium/check-chromium-env.sh && bash .planning/chromium/check-chromium-env.sh` | no - Wave 0 creates script | pending |
| 12-W0-02 | 01 | 1 | CHROM-04, CHROM-08 | T-12-03, T-12-04 | Root git cannot accidentally track Chromium checkout, `.gclient`, `out/`, depot_tools, logs, caches, or generated artifacts. | git/static | `bash -n .planning/chromium/verify-artifact-isolation.sh && bash .planning/chromium/verify-artifact-isolation.sh` | no - Wave 0 creates script | pending |
| 12-02-01 | 02 | 2 | CHROM-02, CHROM-07 | T-12-05, T-12-06 | Build reproduction uses explicit depot_tools and Xcode paths and writes bounded status/log evidence under `.context/`. | build/smoke | `bash -n .planning/chromium/build-chromium-baseline.sh && bash .planning/chromium/build-chromium-baseline.sh --no-op-ok` | no - plan creates script | pending |
| 12-03-01 | 03 | 3 | CHROM-06, CHROM-07 | T-12-07, T-12-08 | Unmodified Chromium launches with isolated profile state, opens local or `data:` smoke content, exits cleanly, and writes launch evidence. | launch/smoke | `bash -n .planning/chromium/smoke-launch-unmodified.sh && bash .planning/chromium/smoke-launch-unmodified.sh` | no - plan creates script | pending |
| 12-04-01 | 04 | 4 | CHROM-03, CHROM-04, CHROM-05, CHROM-08 | T-12-09, T-12-10 | Handoff docs record current Chromium/depot_tools revisions, GN args, build/launch evidence, and future patch branch/export discipline. | docs/static | `rg '0e8499df5172f55d0d29e2b92ef7e6a704529578|ea253a3e3ae7653cafd343be001dc5cbe69b3ad0|is_debug=false|is_component_build=true|symbol_level=0|launch|git new-branch|format-patch' .planning/chromium/CHROMIUM-CHECKOUT.md` | yes - update required | pending |

*Status: pending / green / red / flaky*

---

## Wave 0 Requirements

- [ ] `.planning/chromium/check-chromium-env.sh` - fail-fast checks for depot_tools, Xcode, SDK, Metal, Chromium source path, build directory, GN args, and binary path before long commands run.
- [ ] `.planning/chromium/verify-artifact-isolation.sh` - root git ignore/tracking/dirty gate for `.context/`, `.gclient`, Chromium `out/`, depot_tools, logs, caches, and generated artifacts.
- [ ] A tracked ignore policy or explicit documented decision that root git isolation remains gitdir-exclude based; either path must be verified by `verify-artifact-isolation.sh`.
- [ ] `CHROMIUM-CHECKOUT.md` update plan that records current depot_tools revision and preserves the pinned Chromium baseline revision.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| macOS permission prompts during unmodified launch | CHROM-06 | Local network/keychain/default-browser prompts may require human observation on first launch. | Run `bash .planning/chromium/smoke-launch-unmodified.sh`; if it blocks on OS UI, record the prompt and rerun with the documented workaround only after the normal launch path is attempted. |
| Future patch branch/export discipline | CHROM-04, CHROM-05 | Phase 12 defines the policy; later Chromium source edits prove it in later phases. | Confirm `.planning/chromium/CHROMIUM-CHECKOUT.md` names the baseline revision, branch naming pattern, and patch export command before Phase 13 starts. |

---

## Validation Sign-Off

- [x] All phase requirements have automated static/build/smoke checks or manual validation entries.
- [x] Sampling continuity defined for task commits, plan waves, and phase gate.
- [x] Wave 0 covers all missing validation dependencies from research.
- [x] No watch-mode commands.
- [x] Feedback latency target documented.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** approved 2026-06-23 for planning; execution must update task statuses when checks pass.
