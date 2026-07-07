---
phase: 14-asset-and-design-system-port
plan: "07"
subsystem: chromium-dev-verification-surfaces
tags: [chromium, webui, views, browser_tests, color-provider, design-system]

dependency_graph:
  requires:
    - phase: 14-02
      provides: Prometheus color mixer registered after native and custom-theme mixers
    - phase: 14-05
      provides: Prometheus FA SVG resources, GRIT IDR constants, and vector icon pipeline
    - phase: 14-06
      provides: prometheus_resources.grd, prometheus_resources.pak, and chrome/grit include-path conventions
  provides:
    - "chrome://prometheus-theme-preview WebUIController, gated to DCHECK local UNKNOWN-channel builds"
    - "prometheus_theme_preview.html with token swatches, typography samples, icon gallery, and DESIGN-07 state matrix"
    - "PrometheusTokenGalleryView under chrome/browser/ui/views/prometheus with a Chrome-owned browsertest"
    - "Runtime proof that PrometheusTokenGalleryView rebuilds all 20 color rows across dark/light BrowserColorScheme changes"
  affects: [14-08, 16, DESIGN-07, D-13, D-14]

tech-stack:
  added: []
  patterns:
    - "Dev-only Chromium WebUI surfaces are guarded by both DCHECK_IS_ON() and chrome::GetChannel() == version_info::Channel::UNKNOWN, not DCHECK_IS_ON() alone"
    - "Chrome-owned Views verification surfaces live under chrome/browser/ui/views/<feature> with a sibling browser_tests source_set, not under //ui/views/examples"
    - "Views using GetColorProvider() must build color-dependent child content after widget attachment, e.g. AddedToWidget() or OnThemeChanged(), not in the constructor"

key-files:
  created:
    - .context/chromium/src/chrome/browser/resources/prometheus/prometheus_theme_preview.html
    - .context/chromium/src/chrome/browser/ui/webui/prometheus/BUILD.gn
    - .context/chromium/src/chrome/browser/ui/webui/prometheus/prometheus_theme_preview_ui.h
    - .context/chromium/src/chrome/browser/ui/webui/prometheus/prometheus_theme_preview_ui.cc
    - .context/chromium/src/chrome/browser/ui/views/prometheus/BUILD.gn
    - .context/chromium/src/chrome/browser/ui/views/prometheus/prometheus_token_gallery_view.h
    - .context/chromium/src/chrome/browser/ui/views/prometheus/prometheus_token_gallery_view.cc
    - .context/chromium/src/chrome/browser/ui/views/prometheus/prometheus_token_gallery_browsertest.cc
  modified:
    - .context/chromium/src/chrome/browser/resources/prometheus/prometheus_resources.grdp
    - .context/chromium/src/chrome/browser/ui/webui/BUILD.gn
    - .context/chromium/src/chrome/browser/ui/webui/chrome_web_ui_configs.cc
    - .context/chromium/src/chrome/test/BUILD.gn

key-decisions:
  - "Used a local UNKNOWN-channel guard in addition to DCHECK_IS_ON() so chrome://prometheus-theme-preview is not exposed on canary/dev channels"
  - "Kept the Views gallery in a Chrome-owned target and wired it to chrome/test via a :browser_tests dep, avoiding an upward dependency from //ui/views/examples"
  - "Moved the gallery's initial color-row creation from the constructor to AddedToWidget() after the browsertest exposed a null ColorProvider crash"

requirements-completed: [DESIGN-06, DESIGN-07]

duration: 43min resumed verification/fix
completed: 2026-07-07
---

# Phase 14 Plan 07: Dev Verification Surfaces Summary

**Dev-only Chromium WebUI and Views galleries for Prometheus design-token verification, with a runtime browsertest proving the native gallery rebuilds on dark/light theme changes**

## Performance

- **Duration:** 43 min resumed verification/fix (prior implementation was already paused mid-verification)
- **Started:** 2026-07-07T02:22:27Z
- **Completed:** 2026-07-07T03:05:00Z
- **Tasks:** 2
- **Files modified:** 12

## Accomplishments

- Added `chrome://prometheus-theme-preview`, compiled by a dedicated Chrome WebUI target and registered only for local developer builds (`DCHECK_IS_ON()` plus `version_info::Channel::UNKNOWN`).
- Added `prometheus_theme_preview.html` with the Phase 14 DESIGN-07 evidence surface: token swatches, Poppins/Space Mono samples, brand samples, FA icon gallery, and visual state matrix.
- Added `PrometheusTokenGalleryView` under `chrome/browser/ui/views/prometheus` with all 20 `kColorPrometheus*` color IDs and `OnThemeChanged()` rebuild behavior.
- Added a Chrome-owned `browser_tests` source_set and filtered browsertest proving the gallery row count remains 20 and the resolved Prometheus background color changes across `ThemeService::SetBrowserColorScheme(kDark -> kLight)`.
- Verified the full `chrome browser_tests` build, then the filtered gallery browsertest, catching and fixing a real runtime crash that a successful build did not reveal.

## Task Commits

Each task was committed atomically on branch `prometheus/phase-14-assets` in `.context/chromium/src`:

1. **Task 1: Build PrometheusThemePreviewUI WebUI controller and preview HTML** - `7671820a2b` (feat)
2. **Task 2: Build PrometheusTokenGalleryView in a Chrome-owned target + browsertest** - `91c6a19c60` (feat)

## Files Created/Modified

- `.context/chromium/src/chrome/browser/ui/webui/prometheus/prometheus_theme_preview_ui.{h,cc}` - Dev-only WebUIController and `PrometheusThemePreviewUIConfig`.
- `.context/chromium/src/chrome/browser/ui/webui/prometheus/BUILD.gn` - Chrome WebUI source_set for the Prometheus preview controller.
- `.context/chromium/src/chrome/browser/ui/webui/chrome_web_ui_configs.cc` - Registers `PrometheusThemePreviewUIConfig` behind the DCHECK + UNKNOWN-channel guard.
- `.context/chromium/src/chrome/browser/ui/webui/BUILD.gn` - Wires the Prometheus WebUI source_set into Chrome WebUI configs.
- `.context/chromium/src/chrome/browser/resources/prometheus/prometheus_theme_preview.html` - Dev preview page for tokens, typography, icon gallery, and state matrix.
- `.context/chromium/src/chrome/browser/resources/prometheus/prometheus_resources.grdp` - Adds IDRs for `prometheus_fonts.css` and the preview HTML.
- `.context/chromium/src/chrome/browser/ui/views/prometheus/prometheus_token_gallery_view.{h,cc}` - Native Views gallery for all 20 Prometheus color IDs.
- `.context/chromium/src/chrome/browser/ui/views/prometheus/prometheus_token_gallery_browsertest.cc` - Runtime proof for row creation and dark/light rebuild.
- `.context/chromium/src/chrome/browser/ui/views/prometheus/BUILD.gn` - Chrome-owned gallery and browser_tests targets.
- `.context/chromium/src/chrome/test/BUILD.gn` - Wires the Prometheus gallery browsertest into `browser_tests`.

## Decisions Made

- The WebUI preview is gated on `chrome::GetChannel() == version_info::Channel::UNKNOWN` in addition to `DCHECK_IS_ON()`. This closes the review concern that canary/dev channels may also be DCHECK-enabled.
- The native gallery uses a Chrome-owned `chrome/browser/ui/views/prometheus:browser_tests` target. `chrome/test/BUILD.gn` depends on that target instead of listing the source directly, matching existing Chromium per-feature test target style while avoiding `//ui/views/examples` layering problems.
- The gallery creates color-dependent rows in `AddedToWidget()` and rebuilds in `OnThemeChanged()`. `GetColorProvider()` is not safe in the constructor because the view is not yet attached to a widget.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Missing WebUI URL constants include**

- **Found during:** Pre-pause build verification inherited from the interrupted attempt
- **Issue:** `PrometheusThemePreviewUIConfig` used `content::kChromeUIScheme` without the required `content/public/common/url_constants.h` include. The first verification build failed on this real compile error.
- **Fix:** Added the explicit include in `prometheus_theme_preview_ui.cc`.
- **Files modified:** `.context/chromium/src/chrome/browser/ui/webui/prometheus/prometheus_theme_preview_ui.cc`
- **Verification:** Full `autoninja -C out/Default chrome browser_tests` passed: `out/Default/phase14-07-rebuild-20260707T022305Z.log`, `EXIT_CODE=0`.
- **Committed in:** `7671820a2b`

**2. [Rule 1 - Bug] Gallery crashed before theme verification because it queried ColorProvider before widget attachment**

- **Found during:** Task 2 filtered browsertest run after the full build passed
- **Issue:** `PrometheusTokenGalleryView` called `CreateGallery()` in its constructor. `InsertColorRow()` then called `color_view->GetColorProvider()->GetColor(...)` before the view hierarchy had a widget, causing a segmentation fault in `PrometheusTokenGalleryBrowserTest.OnThemeChangedRebuildsAllRows`.
- **Fix:** Removed constructor-time `CreateGallery()` and added `AddedToWidget()` to build rows only after `GetWidget()` starts returning a widget-backed color provider. `OnThemeChanged()` continues to rebuild the gallery for live theme changes.
- **Files modified:** `.context/chromium/src/chrome/browser/ui/views/prometheus/prometheus_token_gallery_view.{h,cc}`
- **Verification:** Initial failed log: `out/Default/phase14-07-gallery-browsertest-20260707T025744Z.log`, `EXIT_CODE=1`. Rebuild passed: `out/Default/phase14-07-gallery-fix-build-20260707T025903Z.log`, `EXIT_CODE=0`. Rerun passed: `out/Default/phase14-07-gallery-browsertest-rerun-20260707T025931Z.log`, `[  PASSED  ] 1 test`, `EXIT_CODE=0`.
- **Committed in:** `91c6a19c60`

---

**Total deviations:** 2 auto-fixed runtime/build correctness issues.
**Impact on plan:** Both fixes were required to make the dev surfaces actually compile and execute. No scope expansion beyond Plan 14-07.

## Verification

- `autoninja -C out/Default chrome browser_tests` - passed, `out/Default/phase14-07-rebuild-20260707T022305Z.log`, `Build Succeeded`, `EXIT_CODE=0`.
- Static WebUI check - passed: `PrometheusThemePreviewUIConfig`, `GetChannel`, `DCHECK_IS_ON`, `AddResourcePath`, WebUI `BUILD.gn`, and `prometheus_theme_preview_ui` wiring present.
- Static gallery check - passed: gallery `.h/.cc`, `OnThemeChanged`, Chrome-owned `BUILD.gn`, browsertest source, no `ui/views/examples` registration, and `chrome/test/BUILD.gn` wiring present.
- `autoninja -C out/Default browser_tests` after the gallery fix - passed, `out/Default/phase14-07-gallery-fix-build-20260707T025903Z.log`, `EXIT_CODE=0`.
- `./out/Default/browser_tests --gtest_filter="PrometheusTokenGalleryBrowserTest.*"` - passed, `out/Default/phase14-07-gallery-browsertest-rerun-20260707T025931Z.log`, `SUCCESS: all tests passed`, `EXIT_CODE=0`.
- Final no-op `autoninja -C out/Default browser_tests` after the GN comment clarification - passed, `out/Default/phase14-07-final-browser-tests-build-20260707T030105Z.log`, `EXIT_CODE=0`.

## Issues Encountered

- A headless `--dump-dom chrome://prometheus-theme-preview` smoke was attempted with an isolated user-data-dir, but Prometheus did not produce a useful DOM result and was terminated after the timeout wrapper (`out/Default/phase14-07-webui-headless-20260707T030200Z.log`, `EXIT_CODE=143`). Treat this as inconclusive, not a failed WebUI proof. The reliable automated evidence for the WebUI surface is compile/link plus static resource/config wiring; visual screenshot evidence remains part of the broader DESIGN-07 validation path.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 14-08 can extend asset/resource tests to the full manifest and run the full Phase 14 gate suite with the gallery browsertest now available.
- Carry forward the `AddedToWidget()` lesson: any future Views dev surface that resolves colors through `GetColorProvider()` must wait for widget attachment.
- The `chrome://prometheus-theme-preview` surface exists for DESIGN-07 visual evidence, but non-interactive screenshot capture was not completed in this plan.

## Self-Check: PASSED

- All Plan 14-07 tasks are implemented and committed.
- Full build and targeted runtime browsertest pass.
- SUMMARY.md documents deviations, verification logs, commits, and residual visual-evidence limitation.

---
*Phase: 14-asset-and-design-system-port*
*Completed: 2026-07-07*
