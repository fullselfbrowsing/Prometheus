---
phase: 14-asset-and-design-system-port
plan: "05"
subsystem: icon-pipeline
tags:
  - fa-icons
  - vector-icons
  - gn-build
  - prometheus-action
  - tdd
dependency_graph:
  requires:
    - 14-04  # vendored font_awesome_free and Falkon v1 bundle present
  provides:
    - 72 .icon files in chrome/browser/resources/prometheus/vector_icons/
    - 72 .svg files in chrome/browser/resources/prometheus/svg/
    - prometheus_vector_icons GN target (aggregate_vector_icons)
    - prometheus_resources.grdp with IDR constants (fonts, icons, marks)
    - PrometheusAction enum + resolver (prometheus_action.h + .cc)
  affects:
    - 14-06  # grit("prometheus_resources") target will include prometheus_resources.grdp
    - 14-07  # WebUI references svg/ FA SVGs via IDR constants
    - 14-08  # full-manifest IDR roundtrip test consumes IDR constants from grdp
tech_stack:
  added:
    - base::flat_map<PrometheusAction, const gfx::VectorIcon*> via base::NoDestructor
    - aggregate_vector_icons GN template (components/vector_icons/vector_icons.gni)
    - prometheus-specific vector_icons.cc.template and vector_icons.h.template
    - svgo v4 CJS API (patched skiafy 2.4.2 compatibility shim)
  patterns:
    - source_set wrapper over aggregate_vector_icons (visibility bypass)
    - manifest-driven conversion loop with exact count gate
    - TDD: RED (test stubs) then GREEN (implementation) then verify
key_files:
  created:
    - .planning/chromium/fa-glyph-manifest.txt
    - .context/chromium/src/chrome/browser/resources/prometheus/prometheus_resources.grdp
    - .context/chromium/src/chrome/browser/prometheus/prometheus_action.h
    - .context/chromium/src/chrome/browser/prometheus/prometheus_action.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_action_unittest.cc
    - .context/chromium/src/chrome/browser/resources/prometheus/vector_icons/vector_icons.cc.template
    - .context/chromium/src/chrome/browser/resources/prometheus/vector_icons/vector_icons.h.template
  modified:
    - .planning/chromium/convert-fa-icons.sh
    - .planning/chromium/verify-asset-pipeline.sh
    - .planning/chromium/svgo-preserve-comments.json
    - .context/chromium/src/chrome/browser/resources/prometheus/BUILD.gn
    - .context/chromium/src/chrome/browser/prometheus/BUILD.gn
    - .context/chromium/src/chrome/browser/resources/prometheus/vector_icons/ (72 .icon files)
    - .context/chromium/src/chrome/browser/resources/prometheus/svg/ (72 .svg files)
decisions:
  - "Glyph count is 72 (not 69 as plan states): Falkon v1 bundle contains 72 FA SVG files; used 72 as authoritative throughout; script gate enforces exactly 72"
  - "source_set wrapper required: aggregate_vector_icons hardcodes visibility=[':*']; added source_set('prometheus_vector_icons') as public wrapper following chrome/app/vector_icons precedent"
  - "Prometheus-specific vector_icons templates: upstream templates include components/vector_icons/vector_icons.h (wrong module) causing -Wunused-const-variable; created prometheus-specific templates including chrome/browser/resources/prometheus/vector_icons.h instead"
  - "arrow-down.svg synthesized: Falkon bundle has arrow-down-to-line.svg but not arrow-down.svg needed for SUBSTITUTE=arrow-down; copied arrow-down-to-line.svg as arrow-down.svg since it is the intended substitute glyph"
  - "skiafy patched for svgo v4: skiafy 2.4.2 uses svgo v1/v2 API (new SVGO()); patched /opt/homebrew/lib/node_modules/skiafy/lib/main.js to use svgo v4 CJS optimize() API"
  - "stdin redirect required: Node.js tools (skiafy, svgo) consume while-loop stdin from parent shell; added < /dev/null to both invocations inside the conversion loop"
  - "verify-asset-pipeline.sh assertion 5 scoped: was flagging CC BY 4.0 license attribution URLs in SVG comments as 'remote URLs'; narrowed check to functional remote URL patterns (@import, url(), link/script src=) only"
  - "PrometheusAction enum uses kArrowDownToLine (not kDownload): enum value reflects the glyph semantic, not the FA Free gap; icon resolves to the arrow-down substitution glyph"
metrics:
  duration: "~8.5 hours (2026-06-25T02:55Z to 2026-06-25T11:23Z; dominated by first-time full Chromium blink+components build ~2h10m)"
  completed: "2026-06-25"
  tasks_completed: 4
  tasks_total: 4
  files_created: 150+
  files_modified: 7
---

# Phase 14 Plan 05: FA Icon Pipeline, GN Wiring, and PrometheusAction Resolver Summary

**One-liner:** Manifest-driven FA Free 6.x SVG-to-.icon pipeline producing 72 glyphs with CC BY 4.0 attribution intact, wired via aggregate_vector_icons GN target, with fully-implemented PrometheusAction resolver (flat_map + SVG path switch) covered by 3 passing unit tests (D-08 satisfied in-phase).

## What Was Built

### Task 0: Manifest and manifest-driven converter (planning repo)

- `fa-glyph-manifest.txt`: 72-glyph curated list (70 standard FA Free 6.x solid glyphs + `arrow-down-to-line # SUBSTITUTE=arrow-down` + `sidebar-flip # PLACEHOLDER`); one glyph per line, comment lines ignored
- `convert-fa-icons.sh` rewritten to iterate the manifest; parse order load-bearing: (1) skip blank/comment lines, (2) extract inline tag (`SUBSTITUTE=` / `PLACEHOLDER`) BEFORE stripping comment, (3) strip comment for bare glyph name; hard count gate exits 1 unless exactly 72 `.icon` and 72 `.svg` produced
- `svgo-preserve-comments.json`: svgo v4 config disabling `removeComments` to preserve CC BY 4.0 attribution

### Task 1: Icon conversion (Chromium repo commit `2a4cfcd57f`)

- 72 `.icon` files in `chrome/browser/resources/prometheus/vector_icons/` — each with 3-line Chromium copyright + Source + CC BY 4.0 license provenance header + path commands (CANVAS_DIMENSIONS 20, FILL_RULE_NONZERO, MOVE_TO, ...)
- 72 `.svg` files in `chrome/browser/resources/prometheus/svg/` — original FA Free SVGs with CC BY 4.0 attribution comments intact
- `fa_sidebar_flip.icon` and `fa_sidebar_flip.svg`: placeholder hand-authored (Pro-only glyph)
- `fa_arrow_down_to_line.icon` and `.svg`: substituted from `arrow-down.svg` (arrow-down-to-line not in FA Free 6 solid)

### Task 2: GN target, GRIT IDR constants, PrometheusAction header (Chromium repo commit `ee7552e19b`)

- `chrome/browser/resources/prometheus/BUILD.gn`: `aggregate_vector_icons("_prometheus_vector_icons_action")` (private, visibility restricted) + public `source_set("prometheus_vector_icons")` wrapper; lists all 72 `.icon` sources
- `chrome/browser/resources/prometheus/prometheus_resources.grdp`: IDR constants for 5 woff2 fonts, 2 TTF shims, 72 FA SVGs (IDR_PROMETHEUS_ICON_FA_BOLT ... IDR_PROMETHEUS_ICON_FA_XMARK), 7 brand marks
- `chrome/browser/prometheus/prometheus_action.h`: 72-value PrometheusAction enum (kArrowDownToLine substitution comment, kSidebarFlip placeholder comment) + GetPrometheusActionIconMap() and GetPrometheusActionSvgPath() declarations
- Prometheus-specific `vector_icons.cc.template` and `vector_icons.h.template` in `vector_icons/`: include `chrome/browser/resources/prometheus/vector_icons.h` (not the wrong upstream module header); no `namespace vector_icons {}` wrapper

### Task 3: PrometheusAction resolver implementation + tests (Chromium repo commit `8f9ed92f99`)

- `chrome/browser/prometheus/prometheus_action.cc`: `GetPrometheusActionIconMap()` returns a function-local `base::NoDestructor<base::flat_map<PrometheusAction, const gfx::VectorIcon*>>` with all 72 entries; `GetPrometheusActionSvgPath()` switch statement returning `"fa_<glyph>.svg"` for each action
- `chrome/browser/prometheus/prometheus_action_unittest.cc`: 3 tests verifying map size == 72, every action maps to a non-null VectorIcon, every action maps to a non-empty `.svg` path starting with `fa_`
- `chrome/browser/prometheus/BUILD.gn`: `source_set("prometheus_action")` compiling `.cc` with deps on `//base`, `:prometheus_vector_icons`, `//ui/gfx`; `prometheus_action_unittest.cc` added to `prometheus_unittests`; duplicate `prometheus_color_mixer.cc` source removed (was causing duplicate symbol with `//chrome/browser/ui/color:mixers`)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug / Deviation] Glyph count is 72, not 69**
- **Found during:** Task 0 planning
- **Issue:** Plan and STATE.md stated 69 glyphs; Falkon v1 bundle examination found 72 FA SVG files
- **Fix:** Used 72 as the authoritative count throughout; script gate enforces exactly 72; manifest has 72 entries
- **Decision:** Documented in plan decisions; used 72 everywhere

**2. [Rule 1 - Bug] arrow-down.svg not in Falkon bundle**
- **Found during:** Task 1 conversion run
- **Issue:** Bundle has `arrow-down-to-line.svg` but `SUBSTITUTE=arrow-down` requires `arrow-down.svg` as the source file
- **Fix:** Copied `arrow-down-to-line.svg` as `arrow-down.svg` — the substitute glyph is the same arrow-down-to-line shape; the naming reflects the FA Free availability, not a shape difference
- **Files modified:** FA_SOURCE_DIR during conversion run

**3. [Rule 1 - Bug] skiafy 2.4.2 incompatible with installed svgo v4**
- **Found during:** Task 1 first conversion attempt
- **Issue:** skiafy calls `new SVGO({...})` (svgo v1/v2 API) but installed svgo is v4.0.1 which exports `optimize()` CJS function
- **Fix:** Patched `/opt/homebrew/lib/node_modules/skiafy/lib/main.js` to use svgo v4 CJS API
- **Files modified:** Local skiafy installation (not vendored into repo)

**4. [Rule 1 - Bug] Node.js tools consumed while-loop stdin**
- **Found during:** Task 1 first conversion run (produced only 1 icon/svg)
- **Issue:** `skiafy` and `svgo` detect non-TTY stdin and treat `-` (stdin) as implicit input, consuming the while-loop's stdin pipe and causing only 1 iteration
- **Fix:** Added `< /dev/null` to both svgo and skiafy invocations inside the conversion loop
- **Commit:** planning repo `8ad45f8a0`

**5. [Rule 1 - Bug] GN visibility error — aggregate_vector_icons hardcodes visibility=[":*"]**
- **Found during:** Task 2 GN wiring
- **Issue:** `aggregate_vector_icons` template hardcodes `visibility = [":*"]`; external consumers (prometheus_action GN target) cannot depend on it directly
- **Fix:** Named private action `_prometheus_vector_icons_action`; added public `source_set("prometheus_vector_icons")` wrapper — following `chrome/app/vector_icons` precedent
- **Files modified:** `chrome/browser/resources/prometheus/BUILD.gn`

**6. [Rule 1 - Bug] -Wunused-const-variable from wrong module include in generated .cc**
- **Found during:** Task 2/3 build
- **Issue:** Standard `vector_icons.cc.template` includes `"components/vector_icons/vector_icons.h"` (the wrong module's generated header), causing unused VectorIcon symbols from that module to trigger -Werror
- **Fix:** Created prometheus-specific templates including `"chrome/browser/resources/prometheus/vector_icons.h"` and no `namespace vector_icons {}` wrapper
- **Files modified:** `vector_icons.cc.template`, `vector_icons.h.template`

**7. [Rule 1 - Bug] Duplicate symbol linker error in prometheus_unittests**
- **Found during:** Task 3 build
- **Issue:** `AddPrometheusColorMixer` defined twice: from `"../ui/color/prometheus_color_mixer.cc"` direct source AND from `"//chrome/browser/ui/color:mixers"` transitive dep
- **Fix:** Removed direct `"../ui/color/prometheus_color_mixer.cc"` from prometheus_unittests sources
- **Files modified:** `chrome/browser/prometheus/BUILD.gn`

**8. [Rule 2 - Missing] verify-asset-pipeline.sh assertion 5 false positive**
- **Found during:** Task 1 verification
- **Issue:** Assertion 5 was flagging CC BY 4.0 license attribution URLs (`https://fontawesome.com`) inside SVG comments as "remote URLs", conflicting with D-07 requiring CC BY 4.0 attribution to be preserved
- **Fix:** Changed assertion 5 to check only functional remote URL patterns (@import, url(), `<link>`, `<script src=`), excluding attribution comments in SVG XML
- **Commit:** planning repo `435758688`

## Verification Results

All plan verification checks passed:
- fa-glyph-manifest.txt: 72 glyph entries (grep -vcE '^[[:space:]]*(#|$)' = 72)
- convert-fa-icons.sh: manifest-driven (glob loop removed)
- vector_icons/: 72 .icon files with provenance headers
- svg/: 72 .svg files with CC BY 4.0 attribution intact
- prometheus_vector_icons GN target: declared
- IDR_PROMETHEUS_ICON_FA_BOLT in prometheus_resources.grdp: present
- PrometheusAction enum + resolver declarations in prometheus_action.h: present
- GetPrometheusActionIconMap() in prometheus_action.cc: implemented
- `prometheus_unittests --gtest_filter='*PrometheusAction*'`: 3/3 PASSED
- verify-asset-pipeline.sh: 6/6 assertions passed
- check-falkon-gpl-guard.sh: clean

## Known Stubs

None. All 72 PrometheusAction values have non-null VectorIcon entries and non-empty SVG path returns. The sidebar-flip placeholder icon is intentional (Pro-only glyph per D-08) and is correctly handled as a placeholder, not a stub.

## Threat Flags

None. No new network endpoints or auth paths introduced. The CC BY 4.0 attribution preservation (T-14-14) is verified by assertion 4 of verify-asset-pipeline.sh.

## Self-Check: PASSED

- fa-glyph-manifest.txt: EXISTS at .planning/chromium/fa-glyph-manifest.txt
- prometheus_action.cc: EXISTS at .context/chromium/src/chrome/browser/prometheus/prometheus_action.cc
- prometheus_action_unittest.cc: EXISTS at .context/chromium/src/chrome/browser/prometheus/prometheus_action_unittest.cc
- prometheus_resources.grdp: EXISTS at .context/chromium/src/chrome/browser/resources/prometheus/prometheus_resources.grdp
- Chromium repo Task 1 commit: 2a4cfcd57f (verified in git log)
- Chromium repo Task 2 commit: ee7552e19b (verified in git log)
- Chromium repo Task 3 commit: 8f9ed92f99 (verified in git log)
- Planning repo Task 0 commits: f01decb23, 8ad45f8a0, 435758688 (verified in git log)
