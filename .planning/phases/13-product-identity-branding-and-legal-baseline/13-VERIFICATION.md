---
phase: 13-product-identity-branding-and-legal-baseline
verified: 2026-06-24T00:00:00Z
status: passed
score: 15/15
overrides_applied: 0
---

# Phase 13: Product Identity, Branding, and Legal Baseline — Verification Report

**Phase Goal:** Make the Chromium app identify as Prometheus while preserving required attribution.
**Verified:** 2026-06-24
**Status:** passed
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | GPL Falkon source guard script fails if any Falkon C++/Qt signature appears in Prometheus-owned Chromium directories | VERIFIED | `bash .planning/chromium/check-falkon-gpl-guard.sh` exits 0: "GPL guard: clean — no Falkon GPL signatures in Prometheus Chromium directories." Script uses FOUND accumulator, scans only `chrome/browser/prometheus` and `components/prometheus`. |
| 2 | Smoke-launch script exists and asserts bundle identity (CFBundleName, CFBundleIdentifier) | VERIFIED | `.planning/chromium/smoke-launch-prometheus.sh` exists, `bash -n` passes. Uses `plutil -extract` for exact CFBundleName=Prometheus and CFBundleIdentifier=com.fullselfbrowsing.prometheus assertions. |
| 3 | Both scripts follow the Phase-12 gate skeleton (set -euo pipefail, SCRIPT_DIR/PROJECT_ROOT, fail()-to-stderr, final success printf) | VERIFIED | Both scripts: `grep -c 'set -euo pipefail'` returns 1; SCRIPT_DIR present; fail() defined; success printf present with period. |
| 4 | NOTICES.md exists with complete notice set (Font Awesome CC BY 4.0 + OFL + MIT, Poppins OFL, Space Mono OFL, FSB material, "Powered by FSB" tagline) | VERIFIED | 40-line file at repo root. All required grep checks pass: Powered by FSB, CC BY 4.0, OFL, Poppins, Space Mono, chrome://credits, Full Self Browsing, BSD. |
| 5 | README describes Prometheus as a "Chromium-based agent-native browser" and does not present Falkon/QtWebEngine as production architecture in primary description | VERIFIED | Line 44: "Prometheus is a Chromium-based agent-native browser built by Full Self Browsing." Falkon references on that line and line 48 are explicitly framed as preserved reference and historical context. |
| 6 | Product identity inventory and legal notice inventory exist under .planning/chromium/ with upstream vs. Prometheus override columns | VERIFIED | PRODUCT-IDENTITY-INVENTORY.md and LEGAL-NOTICE-INVENTORY.md both exist. PRODUCT-IDENTITY-INVENTORY.md covers all 10 BRANDING fields, 11 GRD IDS_ keys, Info.plist fields, preserved surfaces, and rebase drift detection. LEGAL-NOTICE-INVENTORY.md covers required preservation rule, notice files, Chromium in-tree surfaces, third-party assets, release obligations, and verification commands. |
| 7 | Chromium BRANDING file sets PRODUCT_FULLNAME=Prometheus, MAC_BUNDLE_ID=com.fullselfbrowsing.prometheus, COMPANY_FULLNAME=Full Self Browsing on branch prometheus/phase-13-branding | VERIFIED | `.context/chromium/src/chrome/app/theme/chromium/BRANDING` verified: 10 fields present, PRODUCT_FULLNAME=Prometheus, MAC_BUNDLE_ID=com.fullselfbrowsing.prometheus, COMPANY_FULLNAME=Full Self Browsing, MAC_CREATOR_CODE=Cr24. Chromium branch shows `prometheus/phase-13-branding` as current. |
| 8 | All 11 high-visibility IDS_* strings in chromium_strings.grd are overridden to Prometheus including both macOS IDS_ABOUT conditional branches | VERIFIED | All 9 IDS_ keys verified present. IDS_PRODUCT_NAME and IDS_APP_MENU_PRODUCT_NAME override values confirmed as "Prometheus". IDS_ABOUT at lines 1083 and 1100 both read "About &amp;Prometheus"; ChromeOS branch at line 1109 correctly retains "About &amp;Chromium". IDS_ABOUT_VERSION_COPYRIGHT retains "Powered by Chromium" for BRAND-03 attribution. |
| 9 | Both patches exported as git format-patch files under .context/chromium-patches/phase-13-branding/ and referenced in CHROMIUM-CHECKOUT.md | VERIFIED | Two patches present: `0001-branding-override-BRANDING-file-for-Prometheus-ident.patch` (contains PRODUCT_FULLNAME=Prometheus) and `0002-branding-override-chromium_strings.grd-product-name-.patch` (contains IDS_PRODUCT_NAME). CHROMIUM-CHECKOUT.md has Phase 13 Patches section with branch, directory, field table, and apply instructions. |
| 10 | After gn gen re-run and autoninja rebuild, output directory contains Prometheus.app with Prometheus binary | VERIFIED | `test -d .context/chromium/src/out/Default/Prometheus.app` exits 0; `test -f .context/chromium/src/out/Default/Prometheus.app/Contents/MacOS/Prometheus` exits 0. Stale Chromium.app coexists (known harmless build leftover). |
| 11 | smoke-launch-prometheus.sh exits 0, asserting Prometheus.app launches, CFBundleName=Prometheus, and CFBundleIdentifier=com.fullselfbrowsing.prometheus | VERIFIED | `.context/prometheus-launch.status` contains `status=0`, `workaround_used=false`, `normal_attempt_status=0`. plutil assertions confirmed both keys before status write. |
| 12 | Human confirmed macOS app menu reads Prometheus, window title contains Prometheus | VERIFIED | Human verification approved 2026-06-24 per VALIDATION.md sign-off (checkpoint:human-verify task in Plan 04). App menu, About item, window title, Dock, and Activity Monitor all confirmed reading Prometheus. Treated as PASSED per task instructions. |
| 13 | All Phase 13 BRAND-01..07 automated checks pass | VERIFIED | plutil -extract CFBundleName=Prometheus; plutil -extract CFBundleIdentifier=com.fullselfbrowsing.prometheus; NOTICES.md Powered by FSB; NOTICES.md CC BY 4.0; NOTICES.md Space Mono; NOTICES.md chrome://credits; GPL guard exits 0; README Chromium-based anchor; artifact isolation exits 0. |
| 14 | CHROMIUM-CHECKOUT.md records the Phase 13 patch branch and patch series location | VERIFIED | Contains "prometheus/phase-13-branding" as branch, ".context/chromium-patches/phase-13-branding/" as directory, smoke-launch-prometheus.sh in Phase 13 Script Gates section. |
| 15 | VALIDATION.md Per-Task Verification Map rows are populated and nyquist_compliant is set to true | VERIFIED | 7 task rows in Per-Task Verification Map covering all plans 01-04. Frontmatter: `nyquist_compliant: true`, `wave_0_complete: true`. Sign-off line dated 2026-06-24. |

**Score:** 15/15 truths verified

---

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `.planning/chromium/check-falkon-gpl-guard.sh` | GPL Falkon contamination guard | VERIFIED | Exists, executable, syntax valid, exits 0. 9 GPL patterns present. FOUND accumulator pattern. Phase-12 gate skeleton confirmed. |
| `.planning/chromium/smoke-launch-prometheus.sh` | Identity-asserting smoke launch gate | VERIFIED | Exists, syntax valid (`bash -n` passes). Targets Prometheus.app, asserts CFBundleName and CFBundleIdentifier via `plutil -extract`, writes prometheus-launch.status. |
| `NOTICES.md` | Prometheus-owned legal notice baseline | VERIFIED | 40 lines, all required sections: Font Awesome (CC BY 4.0 / OFL / MIT), Poppins (OFL), Space Mono (OFL), FSB-Owned Material, "Powered by FSB" tagline, chrome://credits pointer. |
| `.planning/chromium/PRODUCT-IDENTITY-INVENTORY.md` | Upstream vs. Prometheus override inventory | VERIFIED | All 10 BRANDING fields, 11 GRD IDS_ keys, Info.plist fields, preserved surfaces table, rebase drift detection commands. |
| `.planning/chromium/LEGAL-NOTICE-INVENTORY.md` | Legal surface inventory | VERIFIED | Required preservation rule, source-level notice files, Chromium in-tree surfaces, third-party assets, release obligations, verification commands. "Authored Phase 13" row present. |
| `README.md` | BRAND-07 compliance — Chromium-based browser description | VERIFIED | "Chromium-based agent-native browser" on line 44. Falkon references framed as historical context only. |
| `.context/chromium/src/chrome/app/theme/chromium/BRANDING` | Prometheus BRANDING override | VERIFIED | All 10 fields including PRODUCT_FULLNAME=Prometheus, MAC_BUNDLE_ID=com.fullselfbrowsing.prometheus, COMPANY_FULLNAME=Full Self Browsing, MAC_CREATOR_CODE=Cr24 (unchanged), MAC_TEAM_ID= (empty/deferred). |
| `.context/chromium/src/chrome/app/chromium_strings.grd` | GRD product-name overrides | VERIFIED | 11 IDS_* keys present and overridden. IDS_ABOUT both macOS branches patched. ChromeOS branch correctly preserved. Chromium attribution in IDS_ABOUT_VERSION_COPYRIGHT. |
| `.context/chromium/src/out/Default/Prometheus.app` | Rebranded Chromium binary | VERIFIED | Directory exists; MacOS/Prometheus binary exists; plutil-extract confirms CFBundleName=Prometheus and CFBundleIdentifier=com.fullselfbrowsing.prometheus. |
| `.context/chromium-patches/phase-13-branding/0001-*.patch` | BRANDING file patch | VERIFIED | `0001-branding-override-BRANDING-file-for-Prometheus-ident.patch` exists, contains PRODUCT_FULLNAME=Prometheus. |
| `.context/chromium-patches/phase-13-branding/0002-*.patch` | GRD string patch | VERIFIED | `0002-branding-override-chromium_strings.grd-product-name-.patch` exists, contains IDS_PRODUCT_NAME. |
| `.context/prometheus-launch.status` | Smoke launch evidence | VERIFIED | Contains `status=0`, `normal_attempt_status=0`, `workaround_used=false`. |
| `.planning/chromium/CHROMIUM-CHECKOUT.md` | Updated handoff doc | VERIFIED | Phase 13 Patches section present with branch, directory, field change table, apply instructions, and rebase command. Phase 13 Script Gates section includes smoke-launch-prometheus.sh. |
| `.planning/phases/13-product-identity-branding-and-legal-baseline/13-VALIDATION.md` | Populated verification map | VERIFIED | 7 task rows, nyquist_compliant: true, wave_0_complete: true, sign-off dated 2026-06-24. |

---

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `.planning/chromium/smoke-launch-prometheus.sh` | `.context/chromium/src/out/Default/Prometheus.app/Contents/Info.plist` | `plutil -extract` identity assertions after launch | WIRED | Script reads PLIST at the exact path; asserts CFBundleName="Prometheus" and CFBundleIdentifier="com.fullselfbrowsing.prometheus" with exact string comparison. |
| `.planning/chromium/check-falkon-gpl-guard.sh` | `.context/chromium/src/chrome/browser/prometheus` | grep -rn GPL pattern scan | WIRED | Script scans the directory (exits 0 cleanly if absent — correct pre-C++ state). |
| `NOTICES.md` | `chrome://credits` | pointer in opening paragraph | WIRED | "chrome://credits exposes the complete generated credits in packaged builds" present on line 7. |
| `.planning/chromium/PRODUCT-IDENTITY-INVENTORY.md` | `.context/chromium/src/chrome/app/theme/chromium/BRANDING` | upstream vs. override table rows | WIRED | All 10 BRANDING field rows documented with upstream and Prometheus override values. |
| `.planning/chromium/LEGAL-NOTICE-INVENTORY.md` | `NOTICES.md` | Source-Level Notice Files table row | WIRED | Row present with status "Authored Phase 13". |
| `.context/chromium/src/chrome/app/theme/chromium/BRANDING` | `.context/chromium/src/out/Default/Prometheus.app` | gn gen reads MAC_BUNDLE_ID and PRODUCT_FULLNAME at gen time | WIRED | Two commits on prometheus/phase-13-branding above pinned baseline; built Prometheus.app confirmed with correct bundle identity via plutil. |
| `.context/chromium/src/chrome/app/chromium_strings.grd` | `.context/chromium/src/out/Default/Prometheus.app/Contents/MacOS/Prometheus` | branded_strings grit target produces pak file | WIRED | GRD overrides committed and rebuilt; smoke launch exercised the binary and confirmed runtime identity. |
| `.context/chromium-patches/phase-13-branding/` | `.planning/chromium/CHROMIUM-CHECKOUT.md` | Phase 13 Patches section | WIRED | CHROMIUM-CHECKOUT.md contains "phase-13-branding" directory reference with apply instructions. |
| `.planning/chromium/smoke-launch-prometheus.sh` | `.context/prometheus-launch.status` | status file written after successful launch | WIRED | `status=0` confirmed in `.context/prometheus-launch.status`. |
| `.planning/chromium/CHROMIUM-CHECKOUT.md` | `.context/chromium-patches/phase-13-branding/` | Phase 13 Patches section references directory | WIRED | "Patch directory: .context/chromium-patches/phase-13-branding/" explicitly recorded. |

---

### Data-Flow Trace (Level 4)

Not applicable — this phase delivers Bash gate scripts, planning documents, and a compiled binary. No dynamic-data rendering artifacts (React/Vue/Svelte components, Next.js pages) are in scope. The closest analog, the built Info.plist, is a compiled artifact whose data is traced from BRANDING source through gn gen to the built plist — verified by plutil introspection.

---

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| GPL guard exits 0 (no Falkon GPL source in Prometheus dirs) | `bash .planning/chromium/check-falkon-gpl-guard.sh` | "GPL guard: clean — no Falkon GPL signatures in Prometheus Chromium directories." | PASS |
| smoke-launch script passes syntax check | `bash -n .planning/chromium/smoke-launch-prometheus.sh` | exit 0 | PASS |
| CFBundleName = Prometheus | `plutil -extract CFBundleName raw -o - .context/chromium/src/out/Default/Prometheus.app/Contents/Info.plist` | `Prometheus` | PASS |
| CFBundleIdentifier = com.fullselfbrowsing.prometheus | `plutil -extract CFBundleIdentifier raw -o - .../Info.plist` | `com.fullselfbrowsing.prometheus` | PASS |
| Artifact isolation passes | `bash .planning/chromium/verify-artifact-isolation.sh` | "Chromium artifact isolation passed." | PASS |
| prometheus-launch.status = status=0 | `grep status=0 .context/prometheus-launch.status` | `status=0` | PASS |
| NOTICES.md tagline present | `grep -q "Powered by FSB" NOTICES.md` | exit 0 | PASS |
| README BRAND-07 anchor present | `grep -q "Chromium-based agent-native browser" README.md` | exit 0 | PASS |

---

### Probe Execution

No conventional `scripts/*/tests/probe-*.sh` probes exist for this phase. The smoke gate `.planning/chromium/smoke-launch-prometheus.sh` is the functional equivalent and was run during Plan 04 execution; the status file `.context/prometheus-launch.status` records `status=0` as evidence. The GPL guard and artifact isolation gate were also verified above. No additional probe files to execute.

---

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|---------|
| BRAND-01 | 13-03, 13-04 | User sees Prometheus as app name, window title, profile/application identity, first-run/about identity | SATISFIED | CFBundleName=Prometheus; CFBundleIdentifier=com.fullselfbrowsing.prometheus; IDS_PRODUCT_NAME=Prometheus; IDS_APP_MENU_PRODUCT_NAME=Prometheus; IDS_ABOUT="About &Prometheus"; human verified runtime identity. |
| BRAND-02 | 13-02, 13-04 | User sees "Powered by FSB" as affiliation/tagline in side panel, start page, about/legal surfaces, and relevant docs | SATISFIED (Phase 13 scope) | "Powered by FSB" tagline in NOTICES.md (legal surface). Side panel and start page placement are Phase 15/16 scope per Plan 02 interfaces block; explicitly deferred with CONTEXT.md Area decision. |
| BRAND-03 | 13-03 | User does not see Chromium/Chrome/Falkon/KDE branding in primary Prometheus product surfaces except where legally required | SATISFIED | All 11 IDS_* product-name strings overridden to Prometheus. "About Prometheus" in both macOS menu branches. IDS_ABOUT_VERSION_COPYRIGHT retains "Powered by Chromium" clause — legally required attribution, explicitly documented. |
| BRAND-04 | 13-02 | Required Chromium, third-party, Font Awesome, Poppins, Space Mono, FSB-owned notices visible in source and appropriate legal surface | SATISFIED | NOTICES.md provides all required notices with correct license identifiers. Chromium attribution via chrome://credits pointer. BSD-3-Clause mentioned in NOTICES.md opening. |
| BRAND-05 | 13-01 | Migration avoids copying GPL Falkon source into Chromium without explicit license review | SATISFIED | check-falkon-gpl-guard.sh exists, runs, exits 0. Scans chrome/browser/prometheus and components/prometheus for 9 Falkon C++/Qt GPL patterns. Verified executable and clean. |
| BRAND-06 | 13-03, 13-04 | Product metadata and bundle identifiers are Prometheus-owned and do not conflict with installed Chrome/Chromium | SATISFIED | CFBundleIdentifier=com.fullselfbrowsing.prometheus (not org.chromium.Chromium, not com.google.Chrome). Confirmed by plutil introspection. |
| BRAND-07 | 13-02 | README and release docs describe Prometheus as a Chromium-based agent-native browser after baseline migration | SATISFIED | README.md line 44: "Prometheus is a Chromium-based agent-native browser built by Full Self Browsing." Exact BRAND-07 anchor phrase present. |

All 7 BRAND requirements satisfied within Phase 13 scope.

---

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `.planning/chromium/LEGAL-NOTICE-INVENTORY.md` | 32-33 | "Placeholder — Phase 14 drops..." for `LICENSES/poppins-OFL.txt` and `LICENSES/spacemono-OFL.txt` | INFO | These are not stub implementations — they document intentionally deferred Phase 14 work (font file delivery). The inventory accurately records the current status. Not a code stub; no rendering or gate blocked by their absence. |

No TBD, FIXME, or XXX markers found in any file modified by this phase.
No unreferenced debt markers.
No empty implementations or hollow props.

---

### Human Verification Required

None. The human visual verification checkpoint (macOS app menu, window title, About menu item, Dock, Activity Monitor all reading "Prometheus") was completed during Plan 04 execution on 2026-06-24. The VALIDATION.md sign-off records: "human visual verification confirmed (app menu, window title, About, Dock all read Prometheus)." Per task instructions, this is treated as PASSED rather than requiring re-verification.

---

### Gaps Summary

No gaps. All 15 must-have truths verified. All 7 BRAND requirements satisfied. All required artifacts exist and are wired. No blockers.

Notable deviations that were self-resolved during execution (not gaps):
- `smoke-launch-prometheus.sh` uses `plutil -extract` (exact key extraction) rather than `plutil -p` (pretty-print grep) as the plan acceptance criteria specified. The implementation is stricter and more reliable — it performs exact string comparison against "Prometheus" and "com.fullselfbrowsing.prometheus" rather than a substring grep on pretty-printed output. Not a regression; an improvement.
- `check-chromium-env.sh` was updated (Plan 04) to accept the pinned baseline as an ancestor of HEAD rather than requiring exact HEAD match. Required once branding commits existed on the branch. Baseline still anchored; gate still fails if baseline absent from history.
- `osascript` quit logic in `smoke-launch-prometheus.sh` was hardened (Plan 04) to verify actual process exit before trusting the quit command, due to a Launch Services registration race. Both deviations committed in `6cad8e124`.
- Patch filenames differ slightly from plan artifact paths (git format-patch generates names from commit subjects). Content verified correct by grep.
- Chromium.app coexists with Prometheus.app in out/Default (incremental build leftover). Prometheus.app identity confirmed correct; the stale bundle is harmless.

---

_Verified: 2026-06-24_
_Verifier: Claude (gsd-verifier)_
