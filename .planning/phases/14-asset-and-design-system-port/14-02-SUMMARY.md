---
phase: 14
plan: 02
subsystem: chromium-color-pipeline
tags: [color-mixer, build-gn, dedup, registration, wave-1]
dependency_graph:
  requires: [14-01]
  provides: [prometheus/phase-14-assets@AddPrometheusColorMixer-registered, ui/color:mixers-with-prometheus]
  affects: [chrome/browser/ui/color, chrome/browser/prometheus, BUILD.gn-prometheus]
tech_stack:
  added: []
  patterns: [chromium-color-mixer-registration, gn-source-set-dedup]
key_files:
  created: []
  modified:
    - .context/chromium/src/chrome/browser/ui/color/chrome_color_mixers.cc
    - .context/chromium/src/chrome/browser/ui/color/BUILD.gn
    - .context/chromium/src/chrome/browser/prometheus/BUILD.gn
decisions:
  - "AddPrometheusColorMixer placed strictly last (after app_controller block) in AddChromeColorMixers, overriding GM3/Material and custom themes (D-04)"
  - "prometheus_color_mixer.{cc,h} added to ui/color/BUILD.gn :mixers source_set alphabetically between product_specifications and projects_panel mixers"
  - "Direct ../ui/color/prometheus_color_mixer.cc source removed from prometheus/BUILD.gn (Wave 0 stop-gap); :mixers dep already present from Wave 0 so no new dep needed"
  - "chrome_color_id.h left unchanged — all 20 kColorPrometheus* ids already existed from Wave 0 (deviation #1 of 14-01)"
metrics:
  duration: 15min
  completed: 2026-06-25T00:00:00Z
  tasks: 2
  files: 3
---

# Phase 14 Plan 02: Color Pipeline Reconciliation Summary

Idempotent reconciliation of the Wave 0 color pipeline stop-gaps. Verified the 20 kColorPrometheus* ids (no re-insertion), registered AddPrometheusColorMixer as the strictly last mixer in AddChromeColorMixers (after the app_controller block, overriding GM3/Material and any active custom theme per D-04), moved prometheus_color_mixer.{cc,h} into the ui/color :mixers source_set, and removed the Wave 0 direct test source to eliminate the duplicate-symbol link risk.

## Tasks Completed

| Task | Commit (Chromium repo) | Description |
|------|----------------------|-------------|
| Task 1: VERIFY 20 kColorPrometheus* ids | (no commit — verification only) | Count == 20; chrome_color_id.h unchanged |
| Task 2: Register mixer last; add to :mixers; remove duplicate source | 79ae3fa222 | chrome_color_mixers.cc + ui/color/BUILD.gn + prometheus/BUILD.gn |

## Chromium Branch

Branch: `prometheus/phase-14-assets`
Chromium repo commit: `79ae3fa222` — refactor(14-02): register AddPrometheusColorMixer last; move mixer into :mixers; drop duplicate test source (D-04)

## Deviations from Plan

### None — Plan Executed Exactly

Task 1 was the expected verification-only path (count == 20). No file edit was made, no commit was needed. Task 2 executed all three sub-steps atomically in a single commit. The :mixers dep was already present in prometheus/BUILD.gn from Wave 0 (b2be1c4359), so no new dep line was required — the plan correctly noted "Add //chrome/browser/ui/color:mixers if not already there".

## Must-Have Verification

| Truth | Status |
|-------|--------|
| 20 kColorPrometheus* ids in COMMON_CHROME_COLOR_IDS | VERIFIED (grep -c returns 20) |
| AddPrometheusColorMixer registered last (after app_controller block) | VERIFIED |
| prometheus_color_mixer.cc in :mixers sources | VERIFIED |
| Direct ../ui/color/prometheus_color_mixer.cc source REMOVED from prometheus/BUILD.gn | VERIFIED |
| //chrome/browser/ui/color:mixers dep present in prometheus/BUILD.gn | VERIFIED |
| CSS emission tests GREEN | VERIFIED (2 PASSED) |
| ColorIdRange test GREEN | VERIFIED (1 PASSED) |
| Token value tests remain RED | VERIFIED (3 FAILED — correct Wave 0 state, Plan 14-03 fills values) |
| No duplicate-symbol link error | VERIFIED (build succeeded cleanly) |

## Self-Check

Build command: `autoninja -C .context/chromium/src/out/Default prometheus_unittests`
Build result: SUCCESS — "The build has finished successfully."

Test command: `./out/Default/prometheus_unittests`

```
[==========] Running 10 tests from 3 test suites.
[  PASSED  ] 3 tests.
  PrometheusColorMixerTest.ColorIdRangeInChromeBounds
  PrometheusColorCssEmissionTest.AccentIdHasCorrectCssName
  PrometheusColorCssEmissionTest.BgAppIdHasCorrectCssName
[  FAILED  ] 7 tests (RED — correct post-14-02 state):
  PrometheusAssetResourceTest.FontResourcePoppinsThinResolves
  PrometheusAssetResourceTest.FontResourceSpaceMonoResolves
  PrometheusAssetResourceTest.IconResourceFaBoltResolves
  PrometheusAssetResourceTest.BrandAssetPmMarkDarkResolves
  PrometheusColorMixerTest.DarkModeAccentResolvesToFsbOrange
  PrometheusColorMixerTest.LightModeBgAppToken
  PrometheusColorMixerTest.DarkModeBgAppToken
```

RED/GREEN transitions this plan is responsible for: none (no tests transition in 14-02; this plan is a wiring/dedup reconciliation only; 3 GREEN tests were already GREEN from Wave 0 and remain GREEN; 7 RED tests remain RED as expected until Plans 14-03 through 14-05).

GPL guard: `bash .planning/chromium/check-falkon-gpl-guard.sh` exits 0 — clean.

## Self-Check: PASSED

Files modified:
- `.context/chromium/src/chrome/browser/ui/color/chrome_color_mixers.cc` — FOUND (AddPrometheusColorMixer call + include added)
- `.context/chromium/src/chrome/browser/ui/color/BUILD.gn` — FOUND (prometheus_color_mixer.{cc,h} in :mixers)
- `.context/chromium/src/chrome/browser/prometheus/BUILD.gn` — FOUND (direct source removed)

Chromium commit verified: `79ae3fa222` — FOUND
Build: EXIT_CODE 0 — PASSED
Tests run: 10 total, 7 FAILED (RED — correct), 3 PASSED (GREEN — unchanged) — PASSED
