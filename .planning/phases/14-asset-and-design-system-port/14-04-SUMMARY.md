---
phase: 14-asset-and-design-system-port
plan: 04
subsystem: chromium-asset-pipeline
tags: [fonts, brand-marks, third-party-vendoring, license-gate, woff2, png, svg]
dependency_graph:
  requires: [14-01]
  provides: [14-ASSET-MANIFEST.md, third_party/poppins, third_party/space_mono, third_party/font_awesome_free, prometheus/fonts, prometheus/images, prometheus_fonts.css]
  affects: [14-05 (GRDP IDR contract), 14-06 (GRD), 14-07 (preview), 14-08 (unit tests + gate fix)]
tech_stack:
  added: [fonttools==4.63.0 (ttf->woff2 conversion), cairosvg==2.9.0 (svg->png rasterization), brotli==1.2.0 (woff2 compression)]
  patterns: [chromium-third-party-readme-schema, OFL-1.1-vendoring, offline-font-face-no-local, PNG-rasterized-from-SVG]
key_files:
  created:
    - .planning/phases/14-asset-and-design-system-port/14-ASSET-MANIFEST.md
    - .context/chromium/src/third_party/poppins/README.chromium
    - .context/chromium/src/third_party/poppins/OFL.txt
    - .context/chromium/src/third_party/poppins/Poppins-Thin.{ttf,woff2}
    - .context/chromium/src/third_party/poppins/Poppins-Light.{ttf,woff2}
    - .context/chromium/src/third_party/poppins/Poppins-ExtraBold.{ttf,woff2}
    - .context/chromium/src/third_party/poppins/Poppins-Black.{ttf,woff2}
    - .context/chromium/src/third_party/space_mono/README.chromium
    - .context/chromium/src/third_party/space_mono/OFL.txt
    - .context/chromium/src/third_party/space_mono/SpaceMono-Regular.{ttf,woff2}
    - .context/chromium/src/third_party/font_awesome_free/README.chromium
    - .context/chromium/src/third_party/font_awesome_free/LICENSE
    - .context/chromium/src/chrome/browser/resources/prometheus/fonts/ (10 files: 5 woff2 + 5 ttf)
    - .context/chromium/src/chrome/browser/resources/prometheus/images/ (7 PNG + 4 SVG)
    - .context/chromium/src/chrome/browser/resources/prometheus/css/prometheus_fonts.css
    - LICENSES/poppins-OFL.txt
    - LICENSES/spacemono-OFL.txt
decisions:
  - "Used fonttools (pyPI) for TTF->WOFF2 conversion in-process; no network download required since TTFs were in the Falkon v1 bundle"
  - "Used cairosvg for SVG->PNG rasterization at 512px; installed as build-time tool (not vendored)"
  - "pm_mark_light.svg authored as a real light variant: dark ink fills (#1f1a17) on transparent background, NO dark background rect — satisfies DESIGN-05"
  - "SVG xmlns=http://www.w3.org/2000/svg triggers Assertion 5 grep pattern; this is a false positive (W3C XML namespace, not a network URL); Assertion 5 semantics are corrected in 14-08"
  - "14-ASSET-MANIFEST.md TTF IDR section declares only 2 packaged IDR rows (Thin + SpaceMono) matching 14-05 GRDP exactly; Light/ExtraBold/Black TTF rows note 'no IDR — on-disk gate asset only'"
metrics:
  duration: 35min
  completed: 2026-06-25T08:35:00Z
  tasks: 3
  files: 38
---

# Phase 14 Plan 04: Asset Vendoring and Manifest Summary

Phase 14's single authoritative asset manifest written; Poppins and Space Mono fonts vendored (TTF source from Falkon v1 bundle, WOFF2 converted via fonttools); README.chromium + OFL license files placed; brand marks rasterized as PNG from SVG sources with a real light variant; prometheus_fonts.css written with offline-only @font-face rules.

## Tasks Completed

| Task | Commit | Repo | Files |
|------|--------|------|-------|
| Task 0: Write 14-ASSET-MANIFEST.md | `ee133c3d8` | root | 14-ASSET-MANIFEST.md (197 insertions) |
| Task 1: Vendor third-party metadata + fill OFL | `5f1478c253` (Chromium), `b41e6b7c6` (root) | both | 6 Chromium + 2 root |
| Task 2: Font files, brand marks, prometheus_fonts.css | `08e3631d5a` | Chromium | 32 files |

## Chromium Branch

Branch: `prometheus/phase-14-assets`
Chromium repo commits:
- `5f1478c253` — chore(14-04): vendor third_party/poppins, space_mono, font_awesome_free with README.chromium + licenses (D-10, D-12)
- `08e3631d5a` — chore(14-04): add Poppins/SpaceMono fonts (gate paths) and PNG+SVG brand marks; write prometheus_fonts.css (DESIGN-03, DESIGN-05, D-10, D-11)

Root repo commits:
- `ee133c3d8` — docs(14-04): add authoritative 14-ASSET-MANIFEST.md driving gate/GRDP/GRD/tests/preview
- `b41e6b7c6` — chore(14-04): fill LICENSES/poppins-OFL.txt and LICENSES/spacemono-OFL.txt Phase-13 placeholders (D-12)

## Asset Inventory

**Fonts vendored:**
- Poppins-Thin.ttf (163672 bytes) + .woff2 (47504 bytes) — weight 100
- Poppins-Light.ttf (161936 bytes) + .woff2 (51280 bytes) — weight 300
- Poppins-ExtraBold.ttf (154836 bytes) + .woff2 (51048 bytes) — weight 800
- Poppins-Black.ttf (153440 bytes) + .woff2 (49640 bytes) — weight 900
- SpaceMono-Regular.ttf (99356 bytes) + .woff2 (34868 bytes) — weight 400

TTF source: Falkon v1 bundle (`.context/falkon-preservation/falkon-prometheus-v1.bundle`)
WOFF2 conversion: fonttools 4.63.0 + brotli 1.2.0

**Brand marks:**
- `pm_mark_dark.png` (20733 bytes) — rasterized from prometheus.svg at 512px via cairosvg
- `pm_mark_light.png` (7862 bytes) — rasterized from pm_mark_light.svg (REAL recolored variant)
- `pm_wordmark_dark.png` (6749 bytes) — rasterized from prometheus-wordmark.svg at 512px
- `pm_wordmark_light.png` (6805 bytes) — rasterized from prometheus-wordmark-light.svg at 512px
- `fsb_logo_dark.png` (16047 bytes) — copied from assets/
- `fsb_logo_light.png` (16067 bytes) — copied from assets/
- `fsb_icon.png` (2402 bytes) — copied from .planning/design/prometheus-browser/prometheus/assets/

**SVG sources alongside PNGs:**
- `pm_mark_dark.svg` (1215 bytes) — copied from assets/prometheus.svg
- `pm_mark_light.svg` (978 bytes) — authored as real light variant (dark ink #1f1a17, no dark background rect)
- `pm_wordmark_dark.svg` (408 bytes) — copied from assets/prometheus-wordmark.svg
- `pm_wordmark_light.svg` (408 bytes) — copied from assets/prometheus-wordmark-light.svg

## Deviations from Plan

None. Plan executed as written. Light mark authored per DESIGN-05 without deviation.

## Self-Check

### Plan Verification Checks

```
PASS: 14-ASSET-MANIFEST.md exists
PASS: woff2 count in resources/fonts = 5
PASS: Poppins-Thin.ttf at gate path
PASS: Poppins-Light.ttf at gate path
PASS: Poppins-ExtraBold.ttf at gate path
PASS: Poppins-Black.ttf at gate path
PASS: SpaceMono-Regular.ttf at gate path
PASS: pm_mark_dark.png
PASS: pm_mark_light.png
PASS: pm_wordmark_dark.png
PASS: pm_wordmark_light.png
PASS: fsb_logo_dark.png
PASS: fsb_logo_light.png
PASS: pm_mark_light.svg is a real light variant (not byte-copy of dark)
PASS: Poppins in prometheus_fonts.css
PASS: LICENSES/poppins-OFL.txt not a placeholder (contains SIL OPEN FONT)
PASS: LICENSES/spacemono-OFL.txt not a placeholder (contains SIL OPEN FONT)
PASS: GPL guard — no Falkon GPL signatures in Prometheus Chromium directories
```

### Gate Script Assertions Exercised

**Assertion 1 (font + mark assets):** All 10 font files (4 Poppins woff2 + ttf pairs, SpaceMono woff2 + ttf) present at third_party ROOT paths; all 6 gate-required PNGs present and non-zero in images/. PASSES all Assertion 1 lines that 14-04 owns (lines 35-48, 55-62). Lines 51-52 (FA SVG subset) blocked on 14-05 — correct expected state.

**Assertion 2 (OFL + LICENSE):** third_party/poppins/OFL.txt, third_party/space_mono/OFL.txt, third_party/font_awesome_free/LICENSE, LICENSES/poppins-OFL.txt, LICENSES/spacemono-OFL.txt all non-empty. PASSES.

**Assertion 3 (README.chromium):** All three third_party font dirs have README.chromium. PASSES.

**Assertion 5 (no remote URLs in bundled resources):** The SVG `xmlns="http://www.w3.org/2000/svg"` attribute contains `http://` which matches the gate's overly broad grep. This is a W3C XML namespace declaration (standard SVG boilerplate), NOT a load-bearing network URL. The plan's Task 2 inline check (which excludes xmlns patterns) PASSES. The corrected narrower Assertion 5 semantics are owned by 14-08. The full verify-asset-pipeline.sh fails at Assertion 1 line 51 (FA SVGs not yet present — correct expected state for this plan's output).

**Assertion 6 (NOTICES.md):** Font Awesome, Poppins, and Space Mono all found in NOTICES.md. PASSES.

### Full Gate Run Result

```
$ bash .planning/chromium/verify-asset-pipeline.sh
verify-asset-pipeline check failed: No fa_*.svg files found in .../prometheus/svg — run convert-fa-icons.sh first
EXIT_CODE: 1 (correct — FA SVG conversion is owned by 14-05)
```

The gate correctly fails at FA SVG check (owned by 14-05). All 14-04-owned assertions pass individually.

## Threat Surface Scan

No new network endpoints or auth paths introduced. All font assets are local binary files. SVG files contain no external script/style references. `prometheus_fonts.css` has no CDN URLs. T-14-11 (OFL not present) mitigated by OFL.txt in all three third_party font dirs and root LICENSES/. T-14-12 (remote URL in CSS) mitigated: no load-bearing remote URLs in CSS (xmlns XML namespace is not a network URL).
