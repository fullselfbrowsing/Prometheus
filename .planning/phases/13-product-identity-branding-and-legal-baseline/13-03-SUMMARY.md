---
phase: "13-product-identity-branding-and-legal-baseline"
plan: "03"
subsystem: "chromium-branding"
tags: ["branding", "grd", "chromium-patch", "product-identity", "bundle-id"]
dependency_graph:
  requires: ["13-01", "13-02"]
  provides: ["prometheus-app-bundle", "phase-13-branding-patches"]
  affects: [".context/chromium/src/out/Default/Prometheus.app"]
tech_stack:
  added: []
  patterns: ["git-format-patch", "gn-gen", "autoninja-component-build", "grd-string-override"]
key_files:
  created:
    - ".context/chromium-patches/phase-13-branding/0001-branding-override-BRANDING-file-for-Prometheus-ident.patch"
    - ".context/chromium-patches/phase-13-branding/0002-branding-override-chromium_strings.grd-product-name-.patch"
  modified:
    - ".context/chromium/src/chrome/app/theme/chromium/BRANDING"
    - ".context/chromium/src/chrome/app/chromium_strings.grd"
    - ".planning/chromium/CHROMIUM-CHECKOUT.md"
decisions:
  - "git checkout -b used instead of git new-branch (depot_tools alias not available outside depot_tools shell context)"
  - "Both Chromium.app and Prometheus.app coexist in out/Default; Prometheus.app is the newly rebuilt Prometheus identity binary; Chromium.app is the prior unmodified baseline artifact from Phase 12"
  - "IDS_ABOUT_VERSION_COPYRIGHT uses HTML entity em-dash (&#8212;) for the Powered by Chromium attribution separator"
  - "Rebuild triggered via background autoninja which completed successfully; foreground re-run confirmed up-to-date status"
metrics:
  duration: "6min"
  completed: "2026-06-24"
  tasks: 2
  files: 3
---

# Phase 13 Plan 03: Apply Prometheus Branding Patches and Rebuild Summary

**One-liner:** BRANDING and chromium_strings.grd patched on branch prometheus/phase-13-branding, gn gen re-run, autoninja rebuilt Prometheus.app with CFBundleIdentifier=com.fullselfbrowsing.prometheus, and 2-patch series exported.

## What Was Built

Prometheus branding patches applied to the Chromium tree at `.context/chromium/src` on branch `prometheus/phase-13-branding` (off pinned baseline `0e8499df5172f55d0d29e2b92ef7e6a704529578`).

**Task 1: BRANDING file override + gn gen**

Replaced all 10 fields in `chrome/app/theme/chromium/BRANDING` with the Prometheus identity:
- `PRODUCT_FULLNAME=Prometheus`, `PRODUCT_SHORTNAME=Prometheus`
- `MAC_BUNDLE_ID=com.fullselfbrowsing.prometheus`
- `COMPANY_FULLNAME=Full Self Browsing`, `COMPANY_SHORTNAME=FSB`
- `COPYRIGHT=Copyright 2024-2026 Full Self Browsing. Powered by Chromium.`
- `MAC_CREATOR_CODE=Cr24` (unchanged), `MAC_TEAM_ID=` (unchanged)

gn gen re-run after BRANDING change (mandatory per Pitfall 1 from RESEARCH.md) baked `Prometheus.app` into the output tree.

GPL guard passed before commit. Patch 0001 exported.

CHROMIUM-CHECKOUT.md updated with Phase 13 Patches section documenting the branch, patch directory, field change table, and apply instructions.

**Task 2: chromium_strings.grd overrides + rebuild + verification**

All 11 high-visibility IDS_* string keys overridden:

| Key | Override |
|-----|----------|
| IDS_PRODUCT_NAME (else branch) | Prometheus |
| IDS_SHORT_PRODUCT_NAME (else branch) | Prometheus |
| IDS_FIRST_RUN_DIALOG_WINDOW_TITLE | Welcome to Prometheus |
| IDS_BROWSER_WINDOW_TITLE_FORMAT (not chromeos, else branch) | `$1 - Prometheus` |
| IDS_ABOUT_VERSION_COMPANY_NAME (else branch) | Full Self Browsing |
| IDS_ABOUT_VERSION_COPYRIGHT (else branch) | Copyright {YEAR} Full Self Browsing. Powered by Chromium -- see chrome://credits for attributions. |
| IDS_ABOUT (use_titlecase, not chromeos, else branch) | About &Prometheus |
| IDS_ABOUT (not use_titlecase, not chromeos, else branch) | About &Prometheus |
| IDS_APP_MENU_PRODUCT_NAME (macos) | Prometheus |
| IDS_HELPER_NAME (macos) | Prometheus Helper |
| IDS_SHORT_HELPER_NAME (macos) | Prometheus Helper |

ChromeOS branch of IDS_ABOUT left unchanged (correct per plan).

GPL guard passed before commit. autoninja rebuilt successfully. Prometheus.app verified with correct Info.plist identity. Full 2-patch series exported. Artifact isolation gate passed.

## Acceptance Criteria Results

- [x] `PRODUCT_FULLNAME=Prometheus` in BRANDING
- [x] `MAC_BUNDLE_ID=com.fullselfbrowsing.prometheus` in BRANDING
- [x] `COMPANY_FULLNAME=Full Self Browsing` in BRANDING
- [x] `MAC_CREATOR_CODE=Cr24` in BRANDING (unchanged)
- [x] 10 fields in BRANDING (all present including MAC_TEAM_ID=)
- [x] Branch `prometheus/phase-13-branding` in Chromium checkout
- [x] Last commit message contains "BRANDING"
- [x] GPL guard exits 0 (both before BRANDING commit and before GRD commit)
- [x] 1 patch exported after Task 1, 2 patches after Task 2
- [x] `IDS_APP_MENU_PRODUCT_NAME` present and overridden to Prometheus
- [x] `IDS_PRODUCT_NAME` overridden to Prometheus
- [x] `Prometheus.app` exists at `out/Default/Prometheus.app`
- [x] `Prometheus` binary at `Contents/MacOS/Prometheus`
- [x] `plutil` shows CFBundleName=Prometheus and CFBundleIdentifier=com.fullselfbrowsing.prometheus
- [x] 2 commits on branch (git log count = 2)
- [x] 2 .patch files in `.context/chromium-patches/phase-13-branding/`
- [x] Patch 0001 contains PRODUCT_FULLNAME=Prometheus
- [x] Patch 0002 contains IDS_PRODUCT_NAME
- [x] Artifact isolation gate passes
- [x] Nothing written outside puebla

## Deviations from Plan

**1. [Rule 3 - Blocking] git new-branch not available**
- **Found during:** Task 1 Step 1
- **Issue:** `git new-branch` is a depot_tools alias available inside depot_tools-configured shell; it was not available in the execution environment's PATH
- **Fix:** Used `git checkout -b prometheus/phase-13-branding` which creates the same branch from current HEAD (the pinned baseline)
- **Files modified:** None (git operation only)
- **Impact:** None -- same result, branch created at correct baseline

**2. [Note] Chromium.app coexists with Prometheus.app**
- Both `Chromium.app` and `Prometheus.app` exist in `out/Default`. `Chromium.app` is the pre-existing Phase 12 baseline artifact (built before BRANDING patch). `Prometheus.app` is the newly rebuilt binary with correct Prometheus identity (built after gn gen re-run with patched BRANDING). The plan notes "If BOTH exist, that's fine as long as Prometheus.app is the real one." Prometheus.app was confirmed correct via plutil assertions.

**3. [Note] Patch filename differs from plan's must_have artifact path**
- Plan's `must_haves.artifacts` references `0001-branding-BRANDING-file-override.patch` and `0002-branding-chromium-strings-grd-product-name.patch`
- Actual filenames generated by `git format-patch` (based on commit messages): `0001-branding-override-BRANDING-file-for-Prometheus-ident.patch` and `0002-branding-override-chromium_strings.grd-product-name-.patch`
- This is expected -- `git format-patch` generates filenames from commit subjects. Both patches contain the required content (verified by grep).

## Chromium Checkout Commits

Commits on `prometheus/phase-13-branding` in `.context/chromium/src`:

| Commit | Message |
|--------|---------|
| b759608330 | branding: override BRANDING file for Prometheus identity |
| 9de1d31be4 | branding: override chromium_strings.grd product-name strings for Prometheus |

## Evidence

```
out/Default/Prometheus.app/Contents/Info.plist:
  CFBundleDisplayName = "Prometheus"
  CFBundleName        = "Prometheus"
  CFBundleIdentifier  = "com.fullselfbrowsing.prometheus"

.context/chromium-patches/phase-13-branding/:
  0001-branding-override-BRANDING-file-for-Prometheus-ident.patch  (1.3 KB)
  0002-branding-override-chromium_strings.grd-product-name-.patch   (4.4 KB)

bash .planning/chromium/check-falkon-gpl-guard.sh:
  GPL guard: clean -- no Falkon GPL signatures in Prometheus Chromium directories.

bash .planning/chromium/verify-artifact-isolation.sh:
  Chromium artifact isolation passed.
```

## Requirements Satisfied

- BRAND-01: App bundle named Prometheus, CFBundleName=Prometheus, macOS app menu/window title driven by IDS_PRODUCT_NAME=Prometheus and IDS_APP_MENU_PRODUCT_NAME=Prometheus
- BRAND-03: No unwanted Chromium branding in primary product surfaces; IDS_ABOUT_VERSION_COPYRIGHT retains Chromium attribution per legal requirements
- BRAND-06: CFBundleIdentifier=com.fullselfbrowsing.prometheus; does not conflict with org.chromium.Chromium (installed Chromium) or com.google.Chrome

## Self-Check

All artifacts are present and verifiable:

- `.context/chromium/src/chrome/app/theme/chromium/BRANDING` — PRODUCT_FULLNAME=Prometheus verified
- `.context/chromium/src/chrome/app/chromium_strings.grd` — 11 IDS_* overrides verified
- `.context/chromium/src/out/Default/Prometheus.app` — exists, correct Info.plist
- `.context/chromium-patches/phase-13-branding/0001-*.patch` — exists, contains PRODUCT_FULLNAME=Prometheus
- `.context/chromium-patches/phase-13-branding/0002-*.patch` — exists, contains IDS_PRODUCT_NAME
- `.planning/chromium/CHROMIUM-CHECKOUT.md` — Phase 13 Patches section added
- Both gate scripts exit 0: check-falkon-gpl-guard.sh, verify-artifact-isolation.sh

## Self-Check: PASSED
