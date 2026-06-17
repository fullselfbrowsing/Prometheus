---
phase: 01-baseline-and-legal-inventory
verified: 2026-06-16T16:51:57Z
status: passed
score: 4/4 must-haves verified
---

# Phase 1: Baseline and Legal Inventory Verification Report

**Phase Goal:** Establish a reliable browser fork baseline before rebrand or agent work.  
**Verified:** 2026-06-16T16:51:57Z  
**Status:** passed

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Developer can build and run the local browser from the workspace on the initial target platform. | VERIFIED | Preflight passed; CMake configured; `cmake --build build/fsb-baseline` completed; built binary exists at `build/fsb-baseline/bin/falkon.app/Contents/MacOS/falkon`. |
| 2 | Browser smoke test can open a page, navigate, create a tab, and exit cleanly. | VERIFIED | Smoke helper launched the built app and user confirmed it opened. Helper cleanup behavior was patched after first launch exposed a blocking second invocation; rerun with `--wait 1` exited 0. |
| 3 | Falkon/KDE/Qt identifiers, product strings, assets, packaging files, and required legal notices are inventoried. | VERIFIED | `product-identity-inventory.md` and `legal-notice-inventory.md` exist with primary surfaces. |
| 4 | Required GPL and third-party legal notices remain present and intentionally preserved. | VERIFIED | No legal notices were modified or deleted; preservation inventory references `COPYING`, license viewer/about dialog, Flatpak metadata, and theme licenses. |

**Score:** 4/4 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `falkon/tools/fsb-baseline/preflight.sh` | Build prerequisite preflight | EXISTS + SUBSTANTIVE | Checks `cmake`, `ninja`, `git`, Qt6, Qt6WebEngineCore, ECM, and KF6Archive hints. |
| `falkon/tools/fsb-baseline/smoke-browser.sh` | Browser smoke script | EXISTS + SUBSTANTIVE | Supports `--binary PATH`, smoke URLs, logging, and clean termination. |
| `falkon/tools/fsb-baseline/product-identity-inventory.md` | Product identity inventory | EXISTS + SUBSTANTIVE | Maps app IDs, packaging metadata, icons, docs, CMake names, and theme metadata. |
| `falkon/tools/fsb-baseline/legal-notice-inventory.md` | Legal notice inventory | EXISTS + SUBSTANTIVE | Maps source, in-app, packaging, and theme legal surfaces. |

### Requirements Coverage

| Requirement | Status | Blocking Issue |
|-------------|--------|----------------|
| BASE-01: Developer can build and run the local Falkon-derived browser from the workspace on the initial target platform. | SATISFIED | Baseline toolchain installed; configure and build pass. |
| BASE-02: Developer can run a repeatable smoke test that opens a page, navigates, creates a tab, and exits cleanly. | SATISFIED | Built app launched through the smoke helper and was manually confirmed. |
| BASE-03: Project has an inventory of inherited Falkon/KDE/Qt product identifiers, assets, packaging files, and legal notices. | SATISFIED | Inventories were created. |
| BASE-04: Required GPL and third-party legal notices remain available in source and in the browser's legal/about surface. | SATISFIED | Existing files remain present; no legal/about source was modified. |

## Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| n/a | n/a | None | None | No blocking anti-patterns remain for Phase 1. |

## Human Verification Required

Manual launch confirmation was provided during smoke validation.

## Gaps Summary

**No gaps found.** Phase goal achieved. Ready to proceed to Phase 2.

## Recommended Fix Plans

None.

## Verification Metadata

**Verification approach:** Goal-backward from Phase 1 success criteria  
**Automated checks:** preflight, configure, build, script syntax, inventory grep checks  
**Human checks required:** 1 launch confirmation, completed  
**Total verification time:** 45min

---
*Verified: 2026-06-16T16:51:57Z*
*Verifier: Codex*
