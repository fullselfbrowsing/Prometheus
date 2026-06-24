---
phase: 14
slug: asset-and-design-system-port
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-24
---

# Phase 14 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Derived from `14-RESEARCH.md` § Validation Architecture. The Per-Task Verification
> Map is seeded by requirement; task IDs are bound when plans are finalized.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | GTest (Chromium's standard C++ test harness) + static gate scripts (`bash`) |
| **Config file** | `chrome/browser/prometheus/BUILD.gn` (new — Wave 0 creates the test target) |
| **Quick run command** | `autoninja -C out/Default prometheus_unittests && ./out/Default/prometheus_unittests` |
| **Full suite command** | `autoninja -C out/Default prometheus_unittests && ./out/Default/prometheus_unittests --gtest_filter=* && bash .planning/chromium/verify-asset-pipeline.sh` |
| **Estimated runtime** | unit ~10–30s after incremental build; full gate run dominated by `autoninja` link time |

> Note: Chromium edits and the GTest targets live in `.context/chromium/src` on the
> `prometheus/phase-14-*` branch (off the `prometheus/phase-13-branding` tip, per research).
> Gate scripts (`verify-asset-pipeline.sh`, `check-falkon-gpl-guard.sh`,
> `verify-artifact-isolation.sh`) run from the repo root.

---

## Sampling Rate

- **After every task commit:** Run the quick unit target (`prometheus_unittests`).
- **After every plan wave:** Full unit suite + `verify-asset-pipeline.sh` + `check-falkon-gpl-guard.sh` + `verify-artifact-isolation.sh`.
- **Before `/gsd-verify-work`:** Full suite green + dev-surface screenshot evidence captured + VIS subset marked `satisfied-by-Ph14-harness`.
- **Max feedback latency:** < 60 seconds (incremental unit run); full link-inclusive run is wave-boundary only.

---

## Per-Task Verification Map

> Seeded per requirement from `14-RESEARCH.md`. `Task ID` / `Plan` / `Wave` / `Threat Ref`
> columns are bound to concrete plan tasks once PLAN.md files exist; the executor updates
> Status as tests go green.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| TBD | — | — | DESIGN-01 | — | Each `kColorPrometheus*` id resolves to correct SkColor (dark) | unit | `prometheus_unittests --gtest_filter=*DarkMode*` | ❌ W0 | ⬜ pending |
| TBD | — | — | DESIGN-01 | — | Each `kColorPrometheus*` id resolves to correct SkColor (light) | unit | `prometheus_unittests --gtest_filter=*LightMode*` | ❌ W0 | ⬜ pending |
| TBD | — | — | DESIGN-01+06 | — | `--color-prometheus-*` CSS custom properties emit in `colors.css` (`sets=chrome`) | unit | `prometheus_unittests --gtest_filter=*CssEmission*` | ❌ W0 | ⬜ pending |
| TBD | — | — | DESIGN-02 | — | `kColorPrometheusAccent` resolves to `#ff6b35` (default swatch) | unit | `prometheus_unittests --gtest_filter=*AccentDefault*` | ❌ W0 | ⬜ pending |
| TBD | — | — | DESIGN-03 | T-offline | No `https://` / `fonts.googleapis.com` in bundled CSS/SVG/HTML | static grep | `bash .planning/chromium/verify-asset-pipeline.sh` | ❌ W0 | ⬜ pending |
| TBD | — | — | DESIGN-03 | — | IDR constants for Poppins (4 weights) + Space Mono woff2 resolve (non-null) | unit | `prometheus_unittests --gtest_filter=*FontResource*` | ❌ W0 | ⬜ pending |
| TBD | — | — | DESIGN-04 | T-license | CC BY 4.0 attribution comment present in each bundled FA SVG | static grep | `bash .planning/chromium/verify-asset-pipeline.sh` | ❌ W0 | ⬜ pending |
| TBD | — | — | DESIGN-04 | — | IDR constants for FA glyph SVGs resolve (non-null) | unit | `prometheus_unittests --gtest_filter=*IconResource*` | ❌ W0 | ⬜ pending |
| TBD | — | — | DESIGN-05 | — | IDR constants for PM mark, wordmark, FSB logos (dark+light) resolve | unit | `prometheus_unittests --gtest_filter=*BrandAsset*` | ❌ W0 | ⬜ pending |
| TBD | — | — | DESIGN-06 | — | `kColorPrometheus*` ids fall within `kChromeColorsStart..kChromeColorsEnd` | unit | `prometheus_unittests --gtest_filter=*ColorIdRange*` | ❌ W0 | ⬜ pending |
| 14-07 T2 | 14-07 | 4 | DESIGN-07 | — | Views token gallery rebuilds on `OnThemeChanged()`; PrometheusTokenGalleryView registered in `views_examples` target alongside colors_example.cc (D-13 live-rebuild proof) | unit/visual | `autoninja -C out/Default views_examples && out/Default/views_examples` — Prometheus token gallery tab present | ❌ later wave | ⬜ pending |
| TBD | — | — | DESIGN-07 | T-dev-surface | Visual token gallery renders; dev-surface evidence captured | manual/screenshot | open `chrome://prometheus-theme-preview`, toggle dark/light | ❌ later wave | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `chrome/browser/prometheus/prometheus_color_mixer_unittest.cc` — DESIGN-01, DESIGN-02, DESIGN-06 dark/light id resolution + range
- [ ] `chrome/browser/prometheus/prometheus_css_emission_unittest.cc` — DESIGN-01+06 CSS custom-property emission
- [ ] `chrome/browser/prometheus/prometheus_asset_resource_unittest.cc` — DESIGN-03, DESIGN-04, DESIGN-05 IDR resolution
- [ ] `chrome/browser/prometheus/BUILD.gn` — `prometheus_unittests` test target declaration
- [ ] `.planning/chromium/verify-asset-pipeline.sh` — DESIGN-03 (offline) + DESIGN-04 (CC-BY) static grep gate
- [ ] `chrome/browser/ui/color/prometheus_color_mixer.{cc,h}` — Wave 0 stubs with placeholder values so tests compile RED-first

*Note: tests are authored against `.context/chromium/src`; the GTest target builds via `autoninja`.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Dark↔light token swap renders without restart on the dev preview | DESIGN-07 | Visual perception of resolved hex on real surfaces; project auto-approves visual checkpoints with captured evidence | Open `chrome://prometheus-theme-preview`, toggle BrowserColorScheme kLight/kDark, capture screenshot |
| Poppins weight-split PM monogram + wordmark render correctly on dark/light | DESIGN-05 | Glyph rendering / weight fidelity is visual | Render PM mark + wordmark on both surfaces in the preview, capture screenshot |
| Every bundled FA glyph renders as the real FA vector (not a Material substitute) | DESIGN-04, DESIGN-07 | Visual confirmation that `.icon` parity matches FA source | Inspect the icon gallery section of the preview surface, capture screenshot |

*Automated commands above are the real gate; manual screenshots are the auto-approved evidence artifact (per D-14).*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
