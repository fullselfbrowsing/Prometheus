---
phase: "13-product-identity-branding-and-legal-baseline"
plan: "02"
subsystem: "legal-baseline"
tags: [legal, notices, branding, identity, documentation]
dependency_graph:
  requires: ["13-01"]
  provides: ["NOTICES.md", "PRODUCT-IDENTITY-INVENTORY.md", "LEGAL-NOTICE-INVENTORY.md", "README-BRAND-07"]
  affects: ["13-03", "13-04", "Phase 24 release packaging"]
tech_stack:
  added: []
  patterns: ["planning-doc-header-convention", "CHROMIUM-CHECKOUT.md header style", "upstream-vs-override-inventory-table"]
key_files:
  created:
    - "NOTICES.md"
    - ".planning/chromium/PRODUCT-IDENTITY-INVENTORY.md"
    - ".planning/chromium/LEGAL-NOTICE-INVENTORY.md"
  modified:
    - "README.md"
decisions:
  - "[Phase 13-02] NOTICES.md is the authoritative Prometheus-owned legal notice source; chrome://credits integration deferred to Phase 24 (Option A confirmed)"
  - "[Phase 13-02] PRODUCT-IDENTITY-INVENTORY.md records upstream Chromium value and Prometheus override per surface for rebase drift detection"
  - "[Phase 13-02] IDS_ABOUT_VERSION_COPYRIGHT uses dual attribution: Full Self Browsing as producer, Chromium as engine (BRAND-03 + BRAND-04)"
  - "[Phase 13-02] README updated to present-tense Chromium-based browser description; Falkon historical attribution preserved as context"
metrics:
  duration: "2min"
  completed_date: "2026-06-24"
  tasks_completed: 2
  files_created: 3
  files_modified: 1
requirements:
  - BRAND-02
  - BRAND-04
  - BRAND-07
---

# Phase 13 Plan 02: Product Identity Baseline and Legal Notices Summary

**One-liner:** Complete Prometheus legal notice baseline (Font Awesome CC BY 4.0 + OFL 1.1 + MIT, Poppins OFL 1.1, Space Mono OFL 1.1, FSB-owned, Chromium pointer) with BRAND-07 README update and upstream-vs-override identity inventory for rebase drift detection.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Author NOTICES.md at repo root | a70d191f1 | `NOTICES.md` |
| 2 | Author identity and legal inventories; update README | 45362593d | `.planning/chromium/PRODUCT-IDENTITY-INVENTORY.md`, `.planning/chromium/LEGAL-NOTICE-INVENTORY.md`, `README.md` |

## What Was Built

**NOTICES.md** (repo root): Prometheus-owned legal notice baseline with five sections: Font Awesome Free 6.x (triple license: CC BY 4.0 icons, OFL 1.1 fonts, MIT code), Poppins (OFL 1.1), Space Mono (OFL 1.1), FSB-Owned Material (Full Self Browsing, all rights reserved), and the verbatim tagline "Powered by FSB". Includes a Chromium attribution pointer to `chrome://credits`.

**PRODUCT-IDENTITY-INVENTORY.md** (.planning/chromium/): Records all BRANDING file fields with upstream Chromium values and Prometheus overrides, all 11 GRD IDS\_ string overrides with conditional guards noted, Info.plist identity fields post-build, surfaces intentionally preserved as "Chromium" (about:version, chrome://credits), and rebase drift detection bash commands.

**LEGAL-NOTICE-INVENTORY.md** (.planning/chromium/): Records the Required Preservation Rule (Chromium BSD-3-Clause + third-party must remain reachable; GPL Falkon guard enforced), source-level notice files with status, Chromium in-tree legal surfaces with Phase 13 actions, third-party asset notices, release obligations, and verification commands.

**README.md** (updated): Line 44 updated to present-tense "Prometheus is a Chromium-based agent-native browser" (BRAND-07 compliance anchor). Status block updated to reflect Phase 12 Chromium baseline is established and v2.0 migration is active. Falkon historical attribution and all milestone history preserved unchanged.

## Verification Results

All plan-level verification commands exit 0:

```
grep -q "Powered by FSB" NOTICES.md                                          PASS
grep -q "CC BY 4.0" NOTICES.md                                               PASS
grep -q "Space Mono" NOTICES.md                                              PASS
grep -q "chrome://credits" NOTICES.md                                        PASS
grep -q "com.fullselfbrowsing.prometheus" .planning/chromium/PRODUCT-IDENTITY-INVENTORY.md   PASS
grep -q "Chromium-based agent-native browser" README.md                      PASS
```

All acceptance criteria for both tasks exit 0 (9 criteria for Task 1, 9 criteria for Task 2).

## Deviations from Plan

None. Plan executed exactly as written.

- NOTICES.md authored with all required sections and correct license identifiers.
- README update is minimal and targeted: only lines 44 and 48 changed; all Falkon historical attribution and milestone history preserved.
- No architectural changes, no package installs, no Chromium tree edits in this plan.

## Known Stubs

- `LICENSES/poppins-OFL.txt` and `LICENSES/spacemono-OFL.txt` referenced in NOTICES.md and LEGAL-NOTICE-INVENTORY.md but not yet created. Phase 14 drops the font files and license texts together. These are documented as placeholders in the legal inventory.
- `chrome://credits` shows the Chromium sample page (not real credits) until `generate_about_credits=true` is wired in Phase 24. NOTICES.md is the Phase 13 authoritative source per the CONTEXT.md Area 3 decision (Option A confirmed).
- Info.plist identity fields in PRODUCT-IDENTITY-INVENTORY.md are marked "pending verification" until the Prometheus branding rebuild is complete in a subsequent task.

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes were introduced. All deliverables are documentation-only files. No threat flags.

## Self-Check: PASSED

- `NOTICES.md` exists at repo root: confirmed.
- `.planning/chromium/PRODUCT-IDENTITY-INVENTORY.md` exists: confirmed.
- `.planning/chromium/LEGAL-NOTICE-INVENTORY.md` exists: confirmed.
- `README.md` modified: confirmed via `git diff --name-only README.md`.
- Commit `a70d191f1` exists: confirmed via `git log`.
- Commit `45362593d` exists: confirmed via `git log`.
