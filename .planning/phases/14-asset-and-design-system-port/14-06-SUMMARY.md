---
phase: 14-asset-and-design-system-port
plan: "06"
subsystem: chromium-resource-pipeline
tags: [grit, grd, pak, resource-bundle, gtest, tdd-fix, wave-3]

dependency_graph:
  requires:
    - phase: 14-03
      provides: prometheus_color_mixer.cc with all dark/light SkColor assignments and D-05 accent swatch constants
    - phase: 14-05
      provides: prometheus_resources.grdp (IDR declarations), prometheus_vector_icons GN target, PrometheusAction resolver
  provides:
    - "prometheus_resources.grd compiled by grit() to prometheus_resources.pak + grit/prometheus_resources.h"
    - "prometheus_resources.pak wired into the production browser resource bundle (chrome/BUILD.gn packed_resources)"
    - "prometheus_unittests loads the real .pak at runtime via AddDataPackFromPath and asserts HasDataResource + GetRawDataResource().size()>0 for all 5 font IDRs and all 7 brand-mark IDRs"
  affects: [14-07, 14-08]

tech-stack:
  added: []
  patterns:
    - "grit() GN target with output_dir=$root_gen_dir/chrome requires #include \"chrome/grit/<name>.h\" (chrome/ prefix), not bare \"grit/<name>.h\", because Chromium's include search root is $root_gen_dir"
    - "test() targets that construct ui::ResourceBundle must link //base/test:run_all_unittests (base::TestSuite-backed main), not bare //testing/gtest:gtest_main, or ResourceBundle's constructor DCHECK-crashes on an uninitialized base::CommandLine"
    - "resource_ids.spec entries for chrome/browser/resources/*.grd files belong in the chrome/browser section, not the components/ section, matching sibling entries (app_icon_resources.grd, component_extension_resources.grd)"

key-files:
  created:
    - .context/chromium/src/chrome/browser/resources/prometheus/prometheus_resources.grd
  modified:
    - .context/chromium/src/chrome/browser/resources/prometheus/BUILD.gn
    - .context/chromium/src/tools/gritsettings/resource_ids.spec
    - .context/chromium/src/chrome/BUILD.gn
    - .context/chromium/src/chrome/browser/BUILD.gn
    - .context/chromium/src/chrome/browser/prometheus/BUILD.gn
    - .context/chromium/src/chrome/browser/prometheus/prometheus_asset_resource_unittest.cc
    - .context/chromium/src/chrome/browser/resources/prometheus/prometheus_resources.grdp

key-decisions:
  - "Continued a previously interrupted execution attempt rather than redoing the work: found 8 uncommitted files in .context/chromium/src implementing both tasks' core logic (grd, GN wiring, real pak-load unittest), verified them against gate scripts and a fresh GN gen before trusting them, then fixed the two real defects a build+test run surfaced"
  - "Moved the resource_ids.spec entry for prometheus_resources.grd from the components/ section to the chrome/browser section (ID 2650, was misplaced at 7560) to match the section placement convention every other chrome/browser/resources/*.grd entry follows"
  - "Fixed the unittest's #include to chrome/grit/prometheus_resources.h (was grit/prometheus_resources.h) after confirming the physical header path and the gaia_auth_host_resources.h in-tree precedent that uses the same output_dir=$root_gen_dir/chrome + chrome/-prefixed include convention"
  - "Swapped prometheus_unittests' gtest_main dep for //base/test:run_all_unittests after a real test run DCHECK-crashed in ui::ResourceBundle's constructor (base::CommandLine::ForCurrentProcess() with no prior Init()); confirmed against 15 in-tree test() targets using the same swap for the same reason (ui/native_theme, crypto, gpu, dbus, among others)"
  - "Icon IDR test coverage intentionally NOT added in this plan — 14-ASSET-MANIFEST.md and the 14-06/14-08 plan boundary assign full-manifest IconResource coverage to Plan 14-08; this plan's must_haves only require font + brand-mark table-driven coverage, which is what shipped"

requirements-completed: [DESIGN-03, DESIGN-05, DESIGN-06]

duration: 55min
completed: 2026-07-01
---

# Phase 14 Plan 06: GRIT Resource Pipeline Wiring Summary

**Wired `prometheus_resources.grd` through `grit()` into the production browser resource bundle and turned the FontResource/BrandAsset unit tests into a real pak-load gate — `ResourceBundle::AddDataPackFromPath` + `HasDataResource`/`GetRawDataResource().size()>0`, table-driven over all 5 font IDRs and all 7 brand-mark IDRs — fixing two runtime-only GN/include defects (wrong grit include path, gtest_main missing `base::CommandLine::Init`) that a plain compile never surfaced.**

## Performance

- **Duration:** 55 min (includes diagnosing and fixing two runtime failures a clean compile did not catch)
- **Started:** 2026-07-01T15:20:00Z (approx, first Read of plan files)
- **Completed:** 2026-07-01T21:42:10Z
- **Tasks:** 2 (as planned)
- **Files modified:** 8 (1 created, 7 modified)

## Accomplishments

- `prometheus_resources.grd` (new top-level GRIT file) compiles the Plan 14-05 `prometheus_resources.grdp` into `prometheus_resources.pak` + `grit/prometheus_resources.h` via a `grit("prometheus_resources")` GN target, plus a `copy("prometheus_resources_pak")` target that stages the compiled `.pak` at `$root_out_dir`.
- `prometheus_resources.pak` is wired into the production browser resource bundle: `chrome/BUILD.gn`'s `packed_resources` target depends on it and merges it into `additional_extra_paks`; `chrome/browser/BUILD.gn`'s `browser_resources` grit target depends on it so the generated header is reachable tree-wide.
- `prometheus_asset_resource_unittest.cc` is a real pak-load test fixture, not RED stubs: `SetUp()` resolves the `.pak` path via `base::PathService::Get(base::DIR_ASSETS)` and loads it with `ui::ResourceBundle::AddDataPackFromPath`. Each test asserts BOTH `HasDataResource()` and `GetRawDataResource().size() > 0`, table-driven over all 5 font IDRs (`kFontResources`) and all 7 brand-mark IDRs (`kBrandAssetResources`) from `14-ASSET-MANIFEST.md` — no `static_assert`, no uninitialized-bundle check. This is the exact HIGH review finding the plan exists to close.
- All 15 tests in `prometheus_unittests` pass GREEN (5 asset-resource + 3 action + 4 color mixer + 2 CSS emission + 1 range check); `check-falkon-gpl-guard.sh`, `verify-artifact-isolation.sh`, and `verify-asset-pipeline.sh` all pass.

## Task Commits

Each task was committed atomically on branch `prometheus/phase-14-assets` in `.context/chromium/src`:

1. **Task 1: Write prometheus_resources.grd and compile via grit** - `32f46c1a5b` (feat)
2. **Task 2: Wire pak into browser resource bundle and turn IDR tests GREEN** - `2e71710165` (feat)

_No separate plan-metadata commit in the Chromium sub-repo — GSD plan metadata (SUMMARY.md, STATE.md, ROADMAP.md) lives in the main repo per project convention (`sub_repos: ["falkon"]`... Chromium tracked similarly as an out-of-band checkout under `.context/`)._

## Files Created/Modified

- `.context/chromium/src/chrome/browser/resources/prometheus/prometheus_resources.grd` - New top-level GRIT file: `data_package` output → `prometheus_resources.pak`, `rc_header` output → `grit/prometheus_resources.h`, includes `prometheus_resources.grdp` via `<part file="...">`.
- `.context/chromium/src/chrome/browser/resources/prometheus/BUILD.gn` - Adds `grit("prometheus_resources")` and `copy("prometheus_resources_pak")` targets alongside the existing `prometheus_vector_icons` target from Plan 14-05.
- `.context/chromium/src/tools/gritsettings/resource_ids.spec` - Registers `chrome/browser/resources/prometheus/prometheus_resources.grd` for global grit ID allocation (required for any new top-level `.grd`); placed in the `chrome/browser` section (ID 2650) to match sibling `chrome/browser/resources/*.grd` entries, not the `components/` section where it was initially misplaced.
- `.context/chromium/src/chrome/BUILD.gn` - `packed_resources` (`chrome_paks` target) depends on `//chrome/browser/resources/prometheus:prometheus_resources` and merges its `.pak` into `additional_extra_paks`.
- `.context/chromium/src/chrome/browser/BUILD.gn` - `browser_resources` grit target's `deps` includes `//chrome/browser/resources/prometheus:prometheus_resources`.
- `.context/chromium/src/chrome/browser/prometheus/BUILD.gn` - `prometheus_unittests` gains `data`/`data_deps` on the compiled `.pak`, `deps` on `prometheus_resources` and `//ui/base`, and swaps `//testing/gtest:gtest_main` for `//base/test:run_all_unittests` (see Deviations).
- `.context/chromium/src/chrome/browser/prometheus/prometheus_asset_resource_unittest.cc` - Rewritten from 4 `EXPECT_TRUE(false)` RED stubs to a real `PrometheusAssetResourceTest` fixture with `SetUp()`/`TearDown()` around a loaded `ui::ResourceBundle`, plus 5 table-driven test cases. Include fixed to `chrome/grit/prometheus_resources.h` (see Deviations).
- `.context/chromium/src/chrome/browser/resources/prometheus/prometheus_resources.grdp` - `IDR_PROMETHEUS_ASSET_WORDMARK_DARK`/`LIGHT` renamed to `IDR_PROMETHEUS_ASSET_PM_WORDMARK_DARK`/`LIGHT` to match `14-ASSET-MANIFEST.md` (the authoritative IDR-naming source) and the names the new unittest table references.

## Decisions Made

- **Continued interrupted prior work instead of redoing it.** On starting this plan, `.context/chromium/src` (a separate git checkout, not covered by the "clean git log/working tree" verification the task description ran against the main repo) had 8 uncommitted files that already implemented the substance of both tasks — evidently left by a previously killed execution attempt. Rather than discard and re-implement, verified the work: ran `gn gen` (clean), ran all three project gate scripts (all pass), then built and ran the actual test binary before trusting or committing anything. This surfaced two real runtime defects the prior attempt's compile-only state had not caught (see below) — validating the "verify, don't just inherit" approach.
- **Relocated the `resource_ids.spec` entry.** Found `prometheus_resources.grd`'s ID-allocation entry sitting inside the `# START components/ section.` / `# END components/ section.` block by grep-proximity accident, even though the file is `chrome/browser/resources/prometheus/prometheus_resources.grd`. Every sibling `chrome/browser/resources/*.grd` entry (`app_icon_resources.grd`, `component_extension_resources.grd`, `preinstalled_web_apps/resources.grd`) lives in the `chrome/browser` section. Moved it there with a fresh non-colliding ID (2650, confirmed unused in that range) for correctness/maintainability, even though grit's ID allocator does not hard-enforce section-matches-path (the sections are organizational).
- **Renamed grdp IDR constants to match the manifest.** `IDR_PROMETHEUS_ASSET_WORDMARK_DARK`/`LIGHT` in the grdp did not match `IDR_PROMETHEUS_ASSET_PM_WORDMARK_DARK`/`LIGHT` in `14-ASSET-MANIFEST.md` (the plan's designated single source of truth for IDR names) or in the already-written unittest table. Renamed the grdp entries to the manifest's names — the manifest wins per its own stated authority, and this is what makes the test compile.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Continuing prior interrupted work required verification, not blind trust**

- **Found during:** Task 1 read_first / pre-execution state check
- **Issue:** The task description's "no orphaned work" claim was verified only against the main repo (`.planning/`); it did not check `.context/chromium/src`, a separate git checkout, which had 8 uncommitted files from a killed prior attempt covering both this plan's tasks.
- **Fix:** Treated the uncommitted state as unverified input, not ground truth. Ran `gn gen` and all three gate scripts before proceeding, then built the actual test target and ran the binary rather than accepting "it compiles" as sufficient — which is exactly what caught the two defects below.
- **Files modified:** None directly (verification step); enabled discovery of Deviations 2 and 3.
- **Verification:** `gn gen out/Default` clean; `check-falkon-gpl-guard.sh`, `verify-artifact-isolation.sh`, `verify-asset-pipeline.sh` all pass on the inherited state before any further edits.
- **Committed in:** N/A (pre-commit diagnostic step)

**2. [Rule 1 - Bug] Wrong grit include path — `grit/prometheus_resources.h` instead of `chrome/grit/prometheus_resources.h`**

- **Found during:** Task 2 first build attempt (`autoninja -C out/Default prometheus_unittests`)
- **Issue:** `prometheus_asset_resource_unittest.cc` included `"grit/prometheus_resources.h"`. The `.grd`'s `grit()` target sets `output_dir = "$root_gen_dir/chrome"`, so the generated header physically lands at `out/Default/gen/chrome/grit/prometheus_resources.h`. Chromium's include search root is `$root_gen_dir` (not `$root_gen_dir/chrome`), so the correct include string needs the `chrome/` prefix. Compile failed with `fatal error: 'grit/prometheus_resources.h' file not found` even though the file existed on disk at the (different) resolvable path.
- **Fix:** Changed the include to `#include "chrome/grit/prometheus_resources.h"`. Confirmed correct against the in-tree `chrome/browser/resources/gaia_auth_host/BUILD.gn` precedent, which uses the identical `output_dir = "$root_gen_dir/chrome"` pattern and whose generated header is included elsewhere (`chrome/browser/ui/webui/signin/inline_login_ui.cc`) as `"chrome/grit/gaia_auth_host_resources.h"`.
- **Files modified:** `chrome/browser/prometheus/prometheus_asset_resource_unittest.cc`
- **Verification:** `autoninja -C out/Default prometheus_unittests` succeeded with 0 failed steps (previously 1/60783 failed on this exact file).
- **Committed in:** `2e71710165` (Task 2 commit)

**3. [Rule 1 - Bug] `prometheus_unittests` DCHECK-crashed at runtime — missing `base::CommandLine::Init`**

- **Found during:** Task 2, after the compile fix, actually running the test binary (not stopping at "build succeeded")
- **Issue:** `prometheus_unittests` linked `//testing/gtest:gtest_main`. That target's bare `main()` never calls `base::CommandLine::Init(argc, argv)`. `PrometheusAssetResourceTest::SetUp()` is the first place this test suite constructs a `ui::ResourceBundle`; its constructor calls `base::CommandLine::ForCurrentProcess()`, which `DCHECK`-fails immediately (`DCHECK failed: current_process_commandline_.`) because `CommandLine::Init` was never called — a hard crash at test-run time despite a completely clean compile and link. None of the three pre-existing unittest files (`prometheus_color_mixer_unittest.cc`, `prometheus_css_emission_unittest.cc`, `prometheus_action_unittest.cc`) ever construct a `ResourceBundle`, so this DCHECK was invisible until this plan's new fixture ran for the first time.
- **Fix:** Swapped the `prometheus_unittests` `deps` entry from `//testing/gtest:gtest_main` to `//base/test:run_all_unittests`, a `base::TestSuite`-backed `main()` that performs `CommandLine`/`AtExitManager` initialization before running tests. Confirmed as the correct, precedented fix against 15 in-tree `test()` targets doing the identical swap for the identical reason: `ui/native_theme`, `crypto`, `gpu`, `dbus`, `ui/touch_selection`, `ui/accelerated_widget_mac`, and others. `//base/test:run_all_unittests` transitively pulls in `//testing/gtest` via `base/test:test_support`, so the explicit `//testing/gtest` dep (needed for the direct `#include "testing/gtest/include/gtest/gtest.h"` in the test files) was kept, only the `_main` variant was replaced.
- **Files modified:** `chrome/browser/prometheus/BUILD.gn`
- **Verification:** `gn gen` clean after the dep swap; `autoninja -C out/Default prometheus_unittests` succeeded with 0 failed steps; `./out/Default/prometheus_unittests --gtest_filter='*FontResource*:*BrandAsset*'` → `[  PASSED  ] 5 tests.`, exit code 0; full suite `./out/Default/prometheus_unittests` → `[==========] 15 tests ... SUCCESS: all tests passed.`, exit code 0.
- **Committed in:** `2e71710165` (Task 2 commit)

---

**Total deviations:** 3 auto-fixed (1 process/verification discipline, 2 genuine build/runtime bugs)
**Impact on plan:** Both code-level fixes (Deviations 2 and 3) were necessary for the plan's actual goal — tests that GREEN prove the asset is packaged, not tests that merely compile. Neither was scope creep: both are minimal, surgical corrections to GN wiring inherited from the interrupted prior attempt, confirmed against multiple in-tree Chromium precedents before applying. No functional/design changes beyond what the plan specified.

## Issues Encountered

The task description's pre-execution note ("previous execution attempt was killed/interrupted before it made any commits or wrote a SUMMARY.md — verified: git log and working tree are clean, no orphaned work") was accurate for the main repo but did not extend to `.context/chromium/src`, a separate git checkout where the interrupted attempt had in fact left substantial uncommitted work. This was discovered by routine `git status` inspection before editing and handled per Deviation 1 above — verified rather than either blindly trusted or blindly discarded. No repeat of this class of gap is anticipated for 14-07/14-08 since this SUMMARY now documents the actual committed state.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- `prometheus_resources.pak` is compiled, wired into the production browser bundle, and verified loadable at runtime by an actual `ResourceBundle` instance — the foundation Plan 14-07 needs for `chrome://prometheus-theme-preview` to serve fonts/marks/icons as WebUI resources, and Plan 14-08 needs to extend table-driven coverage to the 72 icon IDRs.
- The `//base/test:run_all_unittests` + `chrome/grit/` include-path patterns established here apply to any future `.cc` file that both constructs a `ui::ResourceBundle` and lives in `prometheus_unittests`, or includes a grit header generated with `output_dir = "$root_gen_dir/chrome"` — Plan 14-07's browsertest and Plan 14-08's full-manifest icon test should follow the same conventions.
- No blockers. All gate scripts (`check-falkon-gpl-guard.sh`, `verify-artifact-isolation.sh`, `verify-asset-pipeline.sh`) and the full `prometheus_unittests` suite (15/15) are GREEN on the committed `prometheus/phase-14-assets` branch tip.

---
*Phase: 14-asset-and-design-system-port*
*Completed: 2026-07-01*
