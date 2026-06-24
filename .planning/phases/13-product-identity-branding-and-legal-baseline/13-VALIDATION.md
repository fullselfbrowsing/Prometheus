---
phase: 13
slug: product-identity-branding-and-legal-baseline
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-23
completed: 2026-06-24
---

# Phase 13 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Populated by the planner as plans are created; rows map each task to a verifiable identity/legal check.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Bash gate scripts + grep/plutil assertions (no app unit-test harness; identity surfaces verified via built `.app` introspection) |
| **Config file** | none — gates live under `.planning/chromium/` |
| **Quick run command** | `bash .planning/chromium/verify-artifact-isolation.sh` |
| **Full suite command** | `bash .planning/chromium/check-falkon-gpl-guard.sh && bash .planning/chromium/smoke-launch-prometheus.sh` |
| **Estimated runtime** | ~seconds (verification); rebuild after BRANDING/.grd change ~5–20 min (is_component_build) |

---

## Sampling Rate

- **After every task commit:** Run the relevant gate (`verify-artifact-isolation.sh`, or `bash -n` on authored scripts)
- **After every plan wave:** Re-run the branding verify gate + isolation gate
- **Before `/gsd-verify-work`:** Branding gate green; built `Prometheus.app` shows Prometheus identity
- **Max feedback latency:** seconds (excluding the one branding rebuild)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 13-01-T1 | 01 | 0 | BRAND-05 | T-13-05 | GPL Falkon source guard — fails if any Falkon C++/Qt GPL signatures found in prometheus Chromium dirs | automated | `bash .planning/chromium/check-falkon-gpl-guard.sh` | `.planning/chromium/check-falkon-gpl-guard.sh` | ✅ green |
| 13-01-T2 | 01 | 0 | BRAND-01 | T-13-15 | Prometheus smoke-launch script exists and syntax-validates before Wave 2 build | automated | `bash -n .planning/chromium/smoke-launch-prometheus.sh` | `.planning/chromium/smoke-launch-prometheus.sh` | ✅ green |
| 13-02-T1 | 02 | 1 | BRAND-02, BRAND-04 | — | NOTICES.md at repo root contains "Powered by FSB", Font Awesome CC BY 4.0 triple-license, Poppins OFL 1.1, Space Mono OFL 1.1, chrome://credits pointer | automated | `grep -q "Powered by FSB" NOTICES.md && grep -q "CC BY 4.0" NOTICES.md && grep -q "Space Mono" NOTICES.md && grep -q "chrome://credits" NOTICES.md` | `NOTICES.md` | ✅ green |
| 13-02-T2 | 02 | 1 | BRAND-03, BRAND-07 | — | PRODUCT-IDENTITY-INVENTORY.md records all upstream/override pairs; README contains present-tense Chromium-based description | automated | `grep -q "com.fullselfbrowsing.prometheus" .planning/chromium/PRODUCT-IDENTITY-INVENTORY.md && grep -q "Chromium-based agent-native browser" README.md` | `.planning/chromium/PRODUCT-IDENTITY-INVENTORY.md`, `.planning/chromium/LEGAL-NOTICE-INVENTORY.md`, `README.md` | ✅ green |
| 13-03-T1 | 03 | 2 | BRAND-01, BRAND-06 | T-13-15 | BRANDING file patched (PRODUCT_FULLNAME=Prometheus, MAC_BUNDLE_ID=com.fullselfbrowsing.prometheus); gn gen re-run; Prometheus.app exists in out/Default | automated | `grep -q "PRODUCT_FULLNAME=Prometheus" .context/chromium/src/chrome/app/theme/chromium/BRANDING && test -d .context/chromium/src/out/Default/Prometheus.app` | `.context/chromium/src/chrome/app/theme/chromium/BRANDING` | ✅ green |
| 13-03-T2 | 03 | 2 | BRAND-01, BRAND-03 | T-13-15 | 11 IDS_* product-name overrides in chromium_strings.grd; Prometheus.app rebuilt with correct Info.plist; CFBundleIdentifier=com.fullselfbrowsing.prometheus | automated | `plutil -p .context/chromium/src/out/Default/Prometheus.app/Contents/Info.plist \| grep -q "Prometheus" && plutil -p .context/chromium/src/out/Default/Prometheus.app/Contents/Info.plist \| grep -q "com.fullselfbrowsing.prometheus"` | `.context/chromium/src/chrome/app/chromium_strings.grd`, `.context/chromium/src/out/Default/Prometheus.app/Contents/Info.plist` | ✅ green |
| 13-04-T1 | 04 | 3 | BRAND-01..07 | T-13-15, T-13-16 | Full automated gate: smoke-launch exits 0 with status=0 in prometheus-launch.status; all BRAND checks pass; CHROMIUM-CHECKOUT.md records branch; VALIDATION.md nyquist_compliant: true | automated | `bash .planning/chromium/smoke-launch-prometheus.sh && grep -q "status=0" .context/prometheus-launch.status && grep -q "prometheus/phase-13-branding" .planning/chromium/CHROMIUM-CHECKOUT.md && grep -q "nyquist_compliant: true" .planning/phases/13-product-identity-branding-and-legal-baseline/13-VALIDATION.md` | `.context/prometheus-launch.status`, `.planning/chromium/CHROMIUM-CHECKOUT.md`, `13-VALIDATION.md` | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] Branding verify gate script — `bash .planning/chromium/smoke-launch-prometheus.sh` (asserts `Prometheus.app`, `CFBundleIdentifier=com.fullselfbrowsing.prometheus`, launches and verifies identity via plutil)
- [x] Falkon-source guard script — `bash .planning/chromium/check-falkon-gpl-guard.sh` (fails on GPL Falkon C++/Qt signatures in `.context/chromium/src` Prometheus dirs)

*Existing Phase 12 gates (env/build/isolation) cover build + isolation requirements.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| App menu / window title visibly read "Prometheus" | BRAND-01 | GUI-only string at runtime | Launch built app; confirm macOS app menu + window title say Prometheus, not Chromium |
| "Powered by FSB" visible on about/legal surface | BRAND-02 | rendered surface | Open the about/legal surface; confirm verbatim "Powered by FSB" |

*Remaining behaviors (bundle id, notices in source, inventory, README) have automated verification.*

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency acceptable (branding rebuild is the one slow step)
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** Phase 13 automated gate passed. Human visual verification pending (Task 2 checkpoint).
