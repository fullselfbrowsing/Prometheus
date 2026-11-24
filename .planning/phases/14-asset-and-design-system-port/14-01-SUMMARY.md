---
phase: 14
plan: 01
subsystem: chromium-asset-pipeline
tags: [tdd, wave-0, color-mixer, gtest, gate-scripts, RED]
dependency_graph:
  requires: [prometheus/phase-13-branding]
  provides: [prometheus/phase-14-assets, prometheus_unittests-target, verify-asset-pipeline, convert-fa-icons]
  affects: [chrome/browser/prometheus, chrome/browser/ui/color, BUILD.gn-gn_all]
tech_stack:
  added: [testing/test.gni, verify-asset-pipeline.sh, convert-fa-icons.sh]
  patterns: [chromium-gtest-test-target, gate-script-set-euo-pipefail, red-tdd-wave-scaffold]
key_files:
  created:
    - .context/chromium/src/chrome/browser/ui/color/prometheus_color_mixer.h
    - .context/chromium/src/chrome/browser/ui/color/prometheus_color_mixer.cc
    - .context/chromium/src/chrome/browser/prometheus/BUILD.gn
    - .context/chromium/src/chrome/browser/prometheus/prometheus_color_mixer_unittest.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_css_emission_unittest.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_asset_resource_unittest.cc
    - .planning/chromium/verify-asset-pipeline.sh
    - .planning/chromium/convert-fa-icons.sh
  modified:
    - .context/chromium/src/chrome/browser/ui/color/chrome_color_id.h
    - .context/chromium/src/BUILD.gn
decisions:
  - "Add kColorPrometheus* ids to chrome_color_id.h in Wave 0 (not Plan 14-02) so tests compile — prerequisite for RED test target to build"
  - "Include prometheus_color_mixer.cc directly in test sources (not via :mixers dep) so Wave 0 binary links before Plan 14-02 registers it"
  - "Use import(//testing/test.gni) in prometheus BUILD.gn and dep //testing/gtest for gtest infrastructure"
  - "Wire //chrome/browser/prometheus:prometheus_unittests into gn_all group in root BUILD.gn for GN discoverability"
  - "Use //skia not //third_party/skia dep — the latter causes duplicate skia_use_dawn arg error"
metrics:
  duration: 65min
  completed: 2026-06-24T16:52:53Z
  tasks: 3
  files: 8
---

# Phase 14 Plan 01: Wave 0 Test Scaffold and Gate Scripts Summary

Wave 0 TDD scaffold for Prometheus design system port. Creates the Phase 14 Chromium branch, RED unit test stubs that compile but fail until later plans fill values, and two gate scripts that exit non-zero on a fresh tree.

## Tasks Completed

| Task | Commit (Chromium repo) | Description |
|------|----------------------|-------------|
| Task 1: Mixer stubs + branch | 56e2ffd1ef | Branch prometheus/phase-14-assets; AddPrometheusColorMixer stub (Wave 0 no-op) |
| Task 2: RED tests + BUILD.gn | 3415ff1dbc, b2be1c4359 | Three *_unittest.cc + BUILD.gn; kColorPrometheus* ids in chrome_color_id.h; GN/dep fixes |
| Task 3: Gate scripts | 58043f90a (root repo) | verify-asset-pipeline.sh (6 D-12 assertions) + convert-fa-icons.sh |

## Chromium Branch

Branch: `prometheus/phase-14-assets`
Off tip: `prometheus/phase-13-branding @ 9de1d31be4`
Chromium repo commits:
- `56e2ffd1ef` — test(14-01): add prometheus color mixer stub (Wave 0 RED)
- `3415ff1dbc` — test(14-01): add RED prometheus unit test stubs and BUILD.gn target (Wave 0)
- `b2be1c4359` — fix(14-01): wire prometheus_unittests into GN graph and fix build deps

Root repo commits:
- `58043f90a` — chore(14-01): add verify-asset-pipeline.sh and convert-fa-icons.sh (Wave 0)

## Test Results (Wave 0 State)

```
[==========] 10 tests from 3 test suites ran.
[  PASSED  ] 3 tests.
  PrometheusColorMixerTest.ColorIdRangeInChromeBounds
  PrometheusColorCssEmissionTest.AccentIdHasCorrectCssName
  PrometheusColorCssEmissionTest.BgAppIdHasCorrectCssName
[  FAILED  ] 7 tests (RED — correct Wave 0 state):
  PrometheusAssetResourceTest.* (4 tests) — IDR not registered until Plans 14-04/05
  PrometheusColorMixerTest.DarkModeAccentResolvesToFsbOrange — mixer stub empty
  PrometheusColorMixerTest.LightModeBgAppToken — mixer stub empty
  PrometheusColorMixerTest.DarkModeBgAppToken — mixer stub empty
```

Wave 0 acceptance: 7 RED + 3 GREEN is correct. The 3 passing tests prove `kColorPrometheus*` ids are correctly declared in `COMMON_CHROME_COLOR_IDS` and CSS emission works. The 7 failing tests will turn GREEN as Plans 14-03 through 14-05 execute.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] kColorPrometheus* ids added in Wave 0 (not Plan 14-02)**
- **Found during:** Task 2 — test files reference `kColorPrometheus*` which didn't exist
- **Issue:** Tests could not compile without the color ID declarations
- **Fix:** Added all 20 `kColorPrometheus*` ids to `chrome_color_id.h` COMMON_CHROME_COLOR_IDS macro in Wave 0
- **Files modified:** `chrome/browser/ui/color/chrome_color_id.h`
- **Commit:** 3415ff1dbc

**2. [Rule 3 - Blocking] prometheus_color_mixer.cc included directly in test sources**
- **Found during:** Task 2 — link error: `AddPrometheusColorMixer` undefined symbol
- **Issue:** The mixer .cc is not yet in `:mixers` source set (that's Plan 14-02); test binary couldn't link
- **Fix:** Added `../ui/color/prometheus_color_mixer.cc` directly to `test("prometheus_unittests")` sources
- **Files modified:** `chrome/browser/prometheus/BUILD.gn`
- **Commit:** b2be1c4359

**3. [Rule 3 - Blocking] GN build infrastructure fixes**
- **Found during:** Task 2 — three issues: `test()` function unknown, `//third_party/skia` dep causes duplicate arg, target not in GN graph
- **Issue:** `test()` requires `import("//testing/test.gni")`; skia dep must be `//skia`; target must be referenced from `gn_all`
- **Fix:** Added import, fixed dep, wired target into root BUILD.gn gn_all group
- **Files modified:** `chrome/browser/prometheus/BUILD.gn`, `BUILD.gn`
- **Commit:** b2be1c4359

## Gate Script Verification

```
$ bash .planning/chromium/verify-asset-pipeline.sh
verify-asset-pipeline check failed: Poppins-Thin.woff2 missing or empty in third_party/poppins
EXIT_CODE: 1  (correct RED state — assets land in Plans 14-04/05)

$ bash .planning/chromium/check-falkon-gpl-guard.sh
GPL guard: clean — no Falkon GPL signatures in Prometheus Chromium directories.

$ bash .planning/chromium/verify-artifact-isolation.sh
Chromium artifact isolation passed.
```

## Known Stubs

The following are intentional Wave 0 stubs that will be replaced by later plans:

| Stub | File | Resolved By |
|------|------|-------------|
| `AddPrometheusColorMixer` is a no-op | `prometheus_color_mixer.cc` | Plan 14-03 |
| `EXPECT_TRUE(false)` for all IDR constants | `prometheus_asset_resource_unittest.cc` | Plans 14-04, 14-05 |
| `// TODO(phase-14-03): mixer[kColor...] = {...}` | `prometheus_color_mixer.cc` | Plan 14-03 |

## Threat Surface Scan

No new network endpoints or auth paths introduced. `verify-asset-pipeline.sh` implements T-14-01 (remote URL assertion) and T-14-02 (CC BY 4.0 assertion) from the threat register.

## Self-Check: PASSED

Files created/exist:
- `.context/chromium/src/chrome/browser/ui/color/prometheus_color_mixer.h` — FOUND
- `.context/chromium/src/chrome/browser/ui/color/prometheus_color_mixer.cc` — FOUND
- `.context/chromium/src/chrome/browser/prometheus/BUILD.gn` — FOUND
- `.context/chromium/src/chrome/browser/prometheus/prometheus_color_mixer_unittest.cc` — FOUND
- `.context/chromium/src/chrome/browser/prometheus/prometheus_css_emission_unittest.cc` — FOUND
- `.context/chromium/src/chrome/browser/prometheus/prometheus_asset_resource_unittest.cc` — FOUND
- `.planning/chromium/verify-asset-pipeline.sh` — FOUND
- `.planning/chromium/convert-fa-icons.sh` — FOUND

Chromium commits verified: 56e2ffd1ef, 3415ff1dbc, b2be1c4359 — FOUND
Root repo commit verified: 58043f90a — FOUND
Branch verified: prometheus/phase-14-assets — FOUND
Build: EXIT_CODE 0 — PASSED
Tests run: 10 total, 7 FAILED (RED), 3 PASSED — correct Wave 0 state
