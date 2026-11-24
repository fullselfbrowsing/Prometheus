---
phase: 14
plan: 03
subsystem: chromium-color-pipeline
tags: [tdd, wave-2, color-mixer, green, palette, accent, d05-swatches]
dependency_graph:
  requires: [14-02]
  provides: [prometheus/phase-14-assets@warm-palette-green, prometheus_color_mixer-all-assignments]
  affects: [chrome/browser/ui/color/prometheus_color_mixer.cc, chrome/browser/ui/color/prometheus_color_mixer.h, chrome/browser/prometheus/prometheus_color_mixer_unittest.cc]
tech_stack:
  added: []
  patterns: [chromium-color-mixer-skcolor-assignment, dark-light-branch-guard, constexpr-swatch-constants]
key_files:
  created: []
  modified:
    - .context/chromium/src/chrome/browser/ui/color/prometheus_color_mixer.cc
    - .context/chromium/src/chrome/browser/ui/color/prometheus_color_mixer.h
    - .context/chromium/src/chrome/browser/prometheus/prometheus_color_mixer_unittest.cc
decisions:
  - "Expose four D-05 named swatch constants (kPrometheusAccentFsbOrange/Indigo/Teal/Rose) in .h header (not .cc anonymous namespace) so AccentSwatchConstantsDefined test can access them via the #include chain"
  - "Default accent wired via named constant kPrometheusAccentFsbOrange, not raw hex, per D-05; TODO(phase-16) comment names all four swatch constants for pref wiring"
  - "SkColorSetARGB alpha values use pre-computed 8-bit approximations from 14-RESEARCH.md Pitfall 1; each line carries alpha-rounding comment"
metrics:
  duration: 20min
  completed: 2026-06-25T00:00:00Z
  tasks: 1
  files: 3
---

# Phase 14 Plan 03: Warm Palette and Accent Derivations Summary

GREEN phase for Prometheus color pipeline. Filled all 15 dark + 15 light SkColor assignments in AddPrometheusColorMixer plus 5 accent derivations; locked the four D-05 named accent swatch constants (FSB Orange/Indigo/Teal/Rose) in the header; added AccentSwatchConstantsDefined test. Flipped 4 color mixer tests from RED to GREEN.

## Tasks Completed

| Task | Commit (Chromium repo) | Description |
|------|----------------------|-------------|
| Task 1: Fill all SkColor assignments | fa1230a874 | 15 dark + 15 light + 5 accent assignments; D-05 constants in .h; AccentSwatchConstantsDefined test |

## Chromium Branch

Branch: `prometheus/phase-14-assets`
Chromium repo commit: `fa1230a874` — feat(14-03): implement warm dark/light palette and accent derivations in prometheus_color_mixer.cc (DESIGN-01, D-02)

## Self-Check

### Before (Wave 0/14-02 state)

```
[==========] 10 tests from 3 test suites ran.
[  PASSED  ] 3 tests.
  PrometheusColorMixerTest.ColorIdRangeInChromeBounds
  PrometheusColorCssEmissionTest.AccentIdHasCorrectCssName
  PrometheusColorCssEmissionTest.BgAppIdHasCorrectCssName
[  FAILED  ] 7 tests (RED):
  PrometheusAssetResourceTest.* (4 tests)
  PrometheusColorMixerTest.DarkModeAccentResolvesToFsbOrange
  PrometheusColorMixerTest.LightModeBgAppToken
  PrometheusColorMixerTest.DarkModeBgAppToken
```

### After (Plan 14-03 state)

```
[==========] 11 tests from 3 test suites ran.
[  PASSED  ] 7 tests.
  PrometheusColorMixerTest.ColorIdRangeInChromeBounds
  PrometheusColorMixerTest.DarkModeAccentResolvesToFsbOrange  <-- RED→GREEN
  PrometheusColorMixerTest.LightModeBgAppToken                 <-- RED→GREEN
  PrometheusColorMixerTest.DarkModeBgAppToken                  <-- RED→GREEN
  PrometheusColorMixerTest.AccentSwatchConstantsDefined        <-- NEW GREEN
  PrometheusColorCssEmissionTest.AccentIdHasCorrectCssName
  PrometheusColorCssEmissionTest.BgAppIdHasCorrectCssName
[  FAILED  ] 4 tests (expected RED — IDR not registered until 14-04/14-05):
  PrometheusAssetResourceTest.FontResourcePoppinsThinResolves
  PrometheusAssetResourceTest.FontResourceSpaceMonoResolves
  PrometheusAssetResourceTest.IconResourceFaBoltResolves
  PrometheusAssetResourceTest.BrandAssetPmMarkDarkResolves
```

Transitions: 3 GREEN → 7 GREEN (+4). AccentSwatchConstantsDefined is a new test added in this plan.
PrometheusAssetResourceTest (4 tests): remain RED — expected, depend on Plans 14-04/14-05.

### Gate Scripts

```
bash .planning/chromium/check-falkon-gpl-guard.sh → PASSED (clean)
bash .planning/chromium/verify-artifact-isolation.sh → PASSED
kPrometheusAccentIndigo in prometheus_color_mixer.h → FOUND
kPrometheusAccentTeal in prometheus_color_mixer.h → FOUND
kPrometheusAccentRose in prometheus_color_mixer.h → FOUND
```

## Must-Have Verification

| Truth | Status |
|-------|--------|
| All 20 dark-mode kColorPrometheus* ids assigned | VERIFIED |
| All 20 light-mode kColorPrometheus* ids assigned | VERIFIED |
| kColorPrometheusAccent = FSB Orange #ff6b35 both themes | VERIFIED (test GREEN) |
| Four D-05 named swatch constants defined (header) | VERIFIED (grep FOUND) |
| kPrometheusAccentSoft/Soft2/Glow = 12/18/24% alpha derivations | VERIFIED |
| rgba tokens use SkColorSetARGB with 8-bit alpha rounding comments | VERIFIED |
| DarkModeAccentResolvesToFsbOrange GREEN | VERIFIED |
| AccentSwatchConstantsDefined GREEN | VERIFIED |
| LightModeBgAppToken GREEN | VERIFIED |
| DarkModeBgAppToken GREEN | VERIFIED |
| prometheus_color_mixer.cc contains SkColorSetRGB(0x0d,0x0a,0x09) | VERIFIED (dark BgApp) |
| TODO(phase-16) comment names all four swatch constants | VERIFIED |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing functionality] Moved swatch constants from .cc anonymous namespace to .h header**

- **Found during:** Task 1 — AccentSwatchConstantsDefined test needs to access kPrometheusAccentIndigo/Teal/Rose constants; anonymous namespace in .cc is not accessible to test code
- **Issue:** Plan said "Define at file scope (anonymous namespace above AddPrometheusColorMixer)" but that makes constants inaccessible to unittest.cc
- **Fix:** Declared all four D-05 constants as `constexpr SkColor` at file scope in prometheus_color_mixer.h (before the function declaration); removed anonymous namespace from .cc; .cc now includes the header to use kPrometheusAccentFsbOrange in the mixer body
- **Files modified:** prometheus_color_mixer.h (constants added), prometheus_color_mixer.cc (anonymous namespace removed, uses header constants)
- **Rationale:** The plan explicitly requires AccentSwatchConstantsDefined test to assert the constants; that test includes the .h header; therefore the constants must live in .h. This is the correct Chromium pattern for shared constants (analogous to how color IDs in chrome_color_id.h are accessible everywhere).

## Threat Surface Scan

No new network endpoints or auth paths introduced. T-14-08 (hex transcription tampering) is mitigated by the token-value GTests that all pass GREEN. T-14-09 (accent pref bypass) is mitigated by the TODO(phase-16) comment marking the exact wiring point and the direct mixer assignment at leaf.

## Self-Check: PASSED

Files modified:
- `.context/chromium/src/chrome/browser/ui/color/prometheus_color_mixer.cc` — FOUND
- `.context/chromium/src/chrome/browser/ui/color/prometheus_color_mixer.h` — FOUND
- `.context/chromium/src/chrome/browser/prometheus/prometheus_color_mixer_unittest.cc` — FOUND

Chromium commit verified: fa1230a874 — FOUND
Build: EXIT_CODE 0 — PASSED
Tests: 11 total, 7 PASSED (GREEN), 4 FAILED (expected RED) — PASSED
GPL guard: clean — PASSED
Artifact isolation: PASSED
