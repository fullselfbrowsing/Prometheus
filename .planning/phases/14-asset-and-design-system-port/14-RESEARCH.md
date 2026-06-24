# Phase 14: Asset and Design System Port — Research

**Researched:** 2026-06-24
**Domain:** Chromium color pipeline, vector icons, font/asset resources, theme switching, WebUI registration, license validation
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Area 1 — Token pipeline (Views + WebUI)**
- D-01: Single Chromium-idiomatic color mixer. `kColorPrometheus*` ids in `kChromeColorsStart` block of `chrome/browser/ui/color/chrome_color_id.h`; dark/light values in new `prometheus_color_mixer.cc` registered via `AddChromeColorMixers`. Native Views uses `ColorProvider->GetColor(kColorPrometheus*)`; WebUI consumes auto-emitted `--color-prometheus-*` from `chrome://theme/colors.css`. (satisfies DESIGN-06)
- D-02: Token family mirrors canonical `styles.css`: bg-app, chrome, chrome-2, surface, surface-2, surface-3, tab-active, tab-idle, tab-hover, text, text-2, text-3, border, border-2, hairline, accent, accent-2, accent-soft, accent-soft-2, accent-glow.
- D-03: Theme switching reuses `BrowserColorScheme {kSystem, kLight, kDark}` pref (`prefs::kBrowserColorScheme`). Default = follow system.
- D-04: Prometheus mixer runs LAST (after Material/GM3) to force warm palette wholesale at leaf.
- D-05: Accent as overridable token now, picker deferred. `kColorPrometheusAccent`/`Accent2` resolved from Prometheus-owned pref (NOT `ColorProviderKey::user_color`). Four swatches locked: FSB Orange `#ff6b35`, Indigo `#6366f1`, Teal `#14b8a6`, Rose `#f43f5e`. No swatch-picker UI in Phase 14.

**Area 2 — Icon port (FULL PARITY)**
- D-06: Full parity — entire curated FA Free subset (~69 glyphs) as `gfx::VectorIcon` `.icon` files, shipped via `aggregate_vector_icons("prometheus_vector_icons")` GN target.
- D-07: Conversion scripted and repeatable. No in-tree SVG→.icon converter. Wrap skiafy + SVGO in `.planning/chromium/` helper with provenance header (source FA glyph name + CC BY 4.0) injected into each `.icon` file. Gate-fail-on-missing-provenance NOT required (Claude's Discretion).
- D-08: One semantic-action header: `PrometheusAction` enum → Views: `base::flat_map<PrometheusAction, const gfx::VectorIcon*>` via `ui::ImageModel::FromVectorIcon(kPrometheus…Icon, kColorPrometheusAccent, size)`; WebUI: same enum to iconset symbol id. Substitutions: `arrow-down-to-line`→`arrow-down`; `sidebar-flip` bundled placeholder.
- D-09: WebUI keeps raw FA SVG subset (CC BY 4.0 comment survives inside XML). Both formats per glyph: `.icon` (Views) + `.svg` (WebUI).

**Area 3 — Font + asset resource and license pipeline**
- D-10: Prometheus-owned GRIT/.pak resource pipeline. Vendored under `third_party/{poppins,space_mono,font_awesome_free}/` each with `README.chromium` + verbatim OFL/CC-BY/MIT LICENSE. Product marks under `chrome/browser/resources/prometheus/`. One Prometheus GRD/grdp compiled to `.pak`.
- D-11: WebUI ships Poppins (Thin 100, Light 300, ExtraBold 800, Black 900) + Space Mono as woff2, via `prometheus_fonts.css` @font-face at `url(//resources/prometheus/fonts/…woff2)`. Native Views: do NOT add OS-level CTFontManager registration. As-needed shim uses `ResourceBundle::GetRawDataResource(IDR_…)` + `PlatformFontMac(sk_sp<SkTypeface>, …)` from SkTypeface built from TTF bytes. Ship TTF for Views shim path, woff2 for WebUI.
- D-12: Asset/license validation gate script `.planning/chromium/verify-asset-pipeline.sh` asserting 6 properties (all assets present/non-zero; OFL/LICENSE files present; README.chromium per third_party dir; CC BY 4.0 in every FA SVG; no remote URLs in bundled CSS/HTML/SVG; NOTICES.md sections present).

**Area 4 — Phase-14 verification harness**
- D-13: Dev-only `chrome://prometheus-theme-preview` WebUI page (~65-line WebUIController + WebUIConfig registration in `chrome_web_ui_configs.cc` + GRIT resource). Plus native Views token gallery mirroring `colors_example.cc`. Both throwaway; Phase 16 deletes/folds.
- D-14: Automated tests: unit tests asserting each `kColorPrometheus*` id resolves to correct SkColor in dark/light; `--color-prometheus-*` CSS properties emit; fonts load with sane metrics; every declared asset IDR resolves. Build on `ui/color/color_provider_unittest.cc` / `color_mixer_unittest.cc` patterns.
- D-15: Phase 14 satisfies-now (does NOT retire) the asset/token/font/icon subset of 26 carried-forward v1 checks. Mark `satisfied-by-Ph14-harness`. Do NOT retire product-layout/packaging checks.

**Cross-cutting (locked)**
- Patch discipline: edits in `.context/chromium/src` on `prometheus/phase-14-*` branch, exported via `git format-patch` from pinned baseline `0e8499df5172f55d0d29e2b92ef7e6a704529578`.
- License boundary: NO GPL Falkon C++/Qt/QSS into Chromium. v1 QSS themes are design-token reference only.
- Display family: Poppins (NOT Space Grotesk).
- Phase-12 gates still apply: `check-chromium-env.sh`, `build-chromium-baseline.sh`, `verify-artifact-isolation.sh`.

### Claude's Discretion
- Exact `kColorPrometheus*` id names, mixer recipe/derivations for accent-soft/glow, GRD/grdp organization and IDR naming, `prometheus_vector_icons` GN target name, dev-preview host name, conversion-helper script structure/filenames, validation-script filename.
- Whether asset/license gate additionally fails on missing `.icon` provenance header (not required, may add as hardening).
- Planner must confirm exact carried-forward VIS check ids against preservation dossier ledger before marking `satisfied-by-Ph14-harness`.

### Deferred Ideas (OUT OF SCOPE)
- Accent swatch-picker UI / tweaks surface → Phase 16/20.
- Themed Prometheus "About" WebUI page with full brand treatment → Phase 16.
- Compact chrome / tab-strip Views and WebUI pages consuming these tokens/icons → Phase 15/16.
- Packaged-notice validation, app-icon-in-package, OFL-in-about checks → Phase 24.
- Product-layout / responsive / handoff carried-forward visual checks → later owner phases.
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DESIGN-01 | Implements canonical warm dark and warm light token sets: `#0d0a09`, `#141110`, `#1d1816`, `#f6efe9`, `#d2c1b4`, `#a99283`, `#fffdfb`, `#f3ede6`, `#e9e2da`, `#ff6b35`, `#ff8c42` | Mixer injects these values verbatim; full token table in §Standard Stack |
| DESIGN-02 | FSB orange used sparingly for primary action, active agent/supervision, selected/focus, logo treatment | accent token model with `kColorPrometheusAccent` id controlled at mixer leaf |
| DESIGN-03 | Bundles Poppins and Space Mono offline with OFL notices, no network font dependency | GRIT/.pak pipeline, woff2+ttf, no `//fonts.googleapis.com` URLs, grep gate |
| DESIGN-04 | Bundles curated FA Free subset with CC BY 4.0 attribution preserved, no network dependency | FA SVGs bundled with comments intact; `.icon` files for Views; grep gate on remote URLs |
| DESIGN-05 | Prometheus ships PM monogram, Prometheus wordmark, FSB logo assets in dark/light with clear-space, min-size, fallback | Product marks under `chrome/browser/resources/prometheus/`, IDR constants, asset validation gate |
| DESIGN-06 | WebUI and native Views surfaces use same token vocabulary and state colors | Single mixer → `kColorPrometheus*` → Views; auto-emitted `--color-prometheus-*` → WebUI; one source of truth |
| DESIGN-07 | Visual verification covers dark/light, accent states, text fit, icon rendering, font loading, focus rings, disabled, warning, private/supervised states | `chrome://prometheus-theme-preview` + Views token gallery + automated color resolver tests |
</phase_requirements>

---

## Summary

Phase 14 ports the entire warm design system into Chromium as a single-source-of-truth set of typed resources that both native Views and WebUI consume without divergence. The architecture is straightforward because Chromium already provides all the necessary machinery — the research task was to locate, verify, and understand each primitive exactly.

The six work areas (color pipeline, icon conversion, font/asset GRIT packaging, theme switching, verification harness, license gate) map to discrete, independent deliverables that can be planned in separate waves. No area requires inventing new infrastructure: all required Chromium primitives are confirmed present at the pinned baseline `0e8499df5172f55d0d29e2b92ef7e6a704529578`.

The most operationally challenging area is the icon port. There is confirmed to be no in-tree SVG-to-.icon converter; the `aggregate_vector_icons.py` script only composes existing `.icon` files. This means the conversion helper script is a genuine prerequisite: it must produce path-command `.icon` syntax from FA Free SVGs before any other icon work can proceed. Every other area has a direct in-tree precedent to copy from.

**Primary recommendation:** Plan in five waves — Wave 0 (test infrastructure + branch setup), Wave 1 (color mixer + CSS emission), Wave 2 (font/asset packaging + GRIT/.pak), Wave 3 (icon conversion + vector-icon target), Wave 4 (verification surfaces + license gate). Waves 1 and 2 can run in parallel after Wave 0.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Token definitions (dark/light hex values) | C++ mixer (`chrome/browser/ui/color/`) | — | Single source generates both Views and WebUI values |
| Native Views token consumption | Views call sites (`GetColor(kColorPrometheus*)`) | — | Standard Views ColorProvider API |
| WebUI token consumption | Generated CSS (`chrome://theme/colors.css?sets=chrome`) | ColorChangeHandler (Mojo) | Auto-emitted from C++ values; no hand-written WebUI token file needed |
| Theme switching (dark/light/system) | `ThemeService` + `prefs::kBrowserColorScheme` | `NativeTheme::ShouldUseDarkColors()` | Reuse existing browser pref wiring |
| Accent preference storage | New Prometheus-owned pref | `kColorPrometheusAccent` id in mixer | Per D-05: separate from `ColorProviderKey::user_color` |
| Font delivery (WebUI) | GRIT `.pak` resource | `prometheus_fonts.css` @font-face | Mirrors Roboto precedent; no CDN |
| Font delivery (Views shim, as-needed) | `ResourceBundle::GetRawDataResource` + `PlatformFontMac(SkTypeface)` | TTF bundled alongside woff2 | D-11: only when a native Views label genuinely needs it |
| Vector icons (Views) | `prometheus_vector_icons` GN target | `aggregate_vector_icons` template | `.icon` path-command files, `gfx::VectorIcon&` constants |
| Vector icons (WebUI) | Raw FA SVG subset in GRIT resource | `cr-iconset` or image resource | D-09: CC BY 4.0 comment survives in XML |
| Brand marks | `chrome/browser/resources/prometheus/` GRIT resource | IDR constants | Product-owned assets, not third-party |
| License validation | `.planning/chromium/verify-asset-pipeline.sh` | `tools/licenses` README.chromium | Gate script per Phase-12/13 convention |
| Dev verification (WebUI) | `chrome://prometheus-theme-preview` WebUIController | `chrome_web_ui_configs.cc` | Throwaway; Phase 16 deletes |
| Dev verification (Views) | Views token gallery (colors_example pattern) | `OnThemeChanged()` rebuild | Live dark/light toggle proof |
| Automated tests | `chrome/browser/prometheus/prometheus_color_mixer_unittest.cc` | `ui/color/color_provider_unittest.cc` patterns | Per D-14 |

---

## Standard Stack

### Core (all verified present at pinned Chromium baseline)

| Component | File | Purpose |
|-----------|------|---------|
| Color ID block | `chrome/browser/ui/color/chrome_color_id.h` | Declare `kColorPrometheus*` ids using `E_CPONLY` macro in `COMMON_CHROME_COLOR_IDS` before `kChromeColorsEnd` |
| Color mixer | New `chrome/browser/ui/color/prometheus_color_mixer.{cc,h}` | Assign dark/light `SkColor` values per id; added to `chrome_color_mixers.cc::AddChromeColorMixers` LAST |
| Mixer registration | `chrome/browser/ui/color/chrome_color_mixers.cc` (`AddChromeColorMixers`) | Hook point; Prometheus mixer added after `AddNativeChromeColorMixer` |
| CSS emission | `chrome/browser/ui/webui/theme_source.cc` (`GenerateColorsCss`) | Emits `kChromeColorsStart`..`kChromeColorsEnd` range as `--color-*` CSS properties when `sets=chrome` is requested |
| CSS naming | `ui/color/color_provider_utils.cc` (`ConvertColorProviderColorIdToCSSColorId`) | Converts `kColorPrometheusAccent` → `--color-prometheus-accent` automatically |
| ColorChangeHandler | `ui/webui/color_change_listener/color_change_handler.{cc,h}` | Mojo bridge that pushes `OnColorProviderChanged()` events to WebUI renderer so it re-fetches colors.css on theme change |
| Vector icon format | `components/vector_icons/*.icon` (path-command text files) | `.icon` file format (CANVAS_DIMENSIONS, MOVE_TO, ARC_TO, etc.) |
| Aggregate GN template | `components/vector_icons/vector_icons.gni` (`aggregate_vector_icons` template) | Generates `vector_icons.cc` + `vector_icons.h` from a list of `.icon` sources |
| Aggregate py script | `components/vector_icons/aggregate_vector_icons.py` | Invoked by the GN template; reads `.icon` files, writes C++ output |
| VectorIcon types | `ui/gfx/vector_icon_types.h` | `gfx::VectorIcon`, `gfx::VectorIconRep` type definitions |
| ImageModel API | `ui/base/models/image_model.h` (`ImageModel::FromVectorIcon`) | Views call site for rendering a `gfx::VectorIcon` with a `ui::ColorVariant` color id |
| Font precedent | `ui/webui/resources/roboto/` (3 woff2 files) | Direct copy pattern for Poppins/Space Mono woff2 bundle |
| Font CSS precedent | `ui/webui/resources/css/roboto.css` | @font-face pattern; replicate as `prometheus_fonts.css` |
| PlatformFontMac shim | `ui/gfx/platform_font_mac.mm`, `ui/gfx/platform_font_mac.h` | `PlatformFontMac(sk_sp<SkTypeface> typeface, std::optional<SystemFontType>)` ctor at line 298 |
| Theme switching | `chrome/browser/themes/theme_service.{h,cc}` | `BrowserColorScheme { kSystem=0, kLight=1, kDark=2 }`, `SetBrowserColorScheme()`, `GetBrowserColorScheme()` |
| Color scheme pref | `chrome/common/pref_names.h` line 694 | `inline constexpr char kBrowserColorScheme[] = "browser.theme.color_scheme2"` |
| WebUIController template | `chrome/browser/ui/webui/internals/internals_ui.cc` | Pattern: `DefaultWebUIConfig(content::kChromeUIScheme, host)`, `WebUIDataSource::CreateAndAdd`, `WEB_UI_CONTROLLER_TYPE_IMPL` |
| WebUI registration | `chrome/browser/ui/webui/chrome_web_ui_configs.cc` (`RegisterChromeWebUIConfigs`) | `content::WebUIConfigMap::GetInstance().AddWebUIConfig(std::make_unique<PrometheusThemePreviewUIConfig>())` |
| Views gallery template | `ui/views/examples/colors_example.cc` | `InsertColorRow(container, label, color_id)` + `GetColorProvider()->GetColor(color_id)` + `OnThemeChanged()` pattern |
| License tooling | `tools/licenses/licenses.py` | Reads `README.chromium` per `third_party/` subdirectory; generates `chrome://credits` |
| README.chromium schema | `third_party/test_fonts/README.chromium` | Canonical fields: Name, URL, Version, Revision, Update Mechanism, License, License File, Security Critical, Shipped, Description |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Single C++ mixer for both surfaces | Separate WebUI token file | CSS file would drift from C++; the C++→CSS auto-emission eliminates drift entirely |
| `aggregate_vector_icons` GN template | Inline `.icon` constants in `.cc` files | Template generates consistent header with `extern const gfx::VectorIcon&` constants; inline would duplicate boilerplate |
| Poppins woff2 bundled in GRIT | System font or CDN | System font not guaranteed; CDN breaks offline requirement (DESIGN-03) |

---

## Package Legitimacy Audit

This phase installs no npm/pip/cargo packages in the repository. The external tools cited (skiafy, SVGO) are invoked only inside the conversion helper script as build-time tools for generating `.icon` files; they are not vendored into the repo. The conversion script should document the version of each tool it requires, but these are not project dependencies.

No slopcheck run required — no packages are added to the project's dependency manifest.

---

## Architecture Patterns

### System Architecture Diagram

```
Canonical styles.css (hex values, token names)
    |
    v
[Wave 1: C++ Color Mixer]
prometheus_color_mixer.cc
    |
    +--[dark_mode=false]---> warm-light SkColor values
    +--[dark_mode=true] ---> warm-dark SkColor values
    |
    v
ColorProvider (per-profile, rebuilt on theme change)
    |
    +----> Native Views call sites
    |      ColorProvider->GetColor(kColorPrometheusAccent)
    |      ImageModel::FromVectorIcon(..., kColorPrometheusAccent, ...)
    |
    +----> ThemeSource::GenerateColorsCss()
           |  chrome://theme/colors.css?sets=chrome
           |  ConvertColorProviderColorIdToCSSColorId()
           |  kColorPrometheusAccent -> "--color-prometheus-accent"
           v
           CSS: html:not(#z){ --color-prometheus-accent: #ff6b35ff; }
                |
                ColorChangeHandler (Mojo) -> OnColorProviderChanged()
                -> WebUI re-fetches colors.css on theme toggle
                |
                v
                WebUI CSS: color: var(--color-prometheus-accent)

[Wave 2: Font + Asset GRIT pipeline]
third_party/poppins/     -> Poppins-[100,300,800,900].woff2 + OFL.txt + README.chromium
third_party/space_mono/  -> SpaceMono-Regular.woff2 + OFL.txt + README.chromium
                           + SpaceMono-Regular.ttf (Views shim path)
third_party/font_awesome_free/ -> fa-*.svg + LICENSE + README.chromium
chrome/browser/resources/prometheus/ -> pm-mark-dark.svg, pm-mark-light.svg,
                                        wordmark-dark.svg, wordmark-light.svg,
                                        fsb-logo-dark.png, fsb-logo-light.png
    |
    v
prometheus.grd/grdp -> grit compile -> prometheus_resources.pak

[Wave 3: Vector Icon Target]
convert-fa-icons.sh
    SVGO (optimize FA SVG) -> skiafy -> .icon path-command files
    + provenance header injected per glyph
    |
    v
chrome/browser/resources/prometheus/vector_icons/
    fa_bolt.icon, fa_compass.icon, ... (69 glyphs)
    |
aggregate_vector_icons("prometheus_vector_icons") [GN]
    -> gen/prometheus_vector_icons.cc + vector_icons.h
    -> extern const gfx::VectorIcon& kFaBoltIcon; etc.

PrometheusAction enum (semantic resolver)
    -> Views: base::flat_map<PrometheusAction, const gfx::VectorIcon*>
    -> WebUI: PrometheusAction -> fa-*.svg resource path
```

### Recommended Project Structure

```
.context/chromium/src/
├── chrome/browser/ui/color/
│   ├── chrome_color_id.h          [MODIFIED: add kColorPrometheus* block]
│   ├── chrome_color_mixers.cc     [MODIFIED: add AddPrometheusColorMixer call last]
│   ├── prometheus_color_mixer.cc  [NEW]
│   └── prometheus_color_mixer.h   [NEW]
├── chrome/browser/resources/prometheus/
│   ├── BUILD.gn                   [NEW]
│   ├── fonts/
│   │   ├── Poppins-Thin.woff2     (100)
│   │   ├── Poppins-Light.woff2    (300)
│   │   ├── Poppins-ExtraBold.woff2 (800)
│   │   ├── Poppins-Black.woff2    (900)
│   │   └── SpaceMono-Regular.woff2
│   ├── images/
│   │   ├── pm_mark_dark.svg / pm_mark_light.svg
│   │   ├── prometheus_wordmark_dark.svg / _light.svg
│   │   ├── fsb_logo_dark.png / fsb_logo_light.png
│   │   └── fsb_icon.png
│   ├── css/
│   │   └── prometheus_fonts.css   [NEW: @font-face for woff2]
│   ├── vector_icons/
│   │   ├── fa_bolt.icon
│   │   ├── fa_compass.icon
│   │   ├── ... (69 .icon files)
│   │   ├── vector_icons.cc.template
│   │   └── vector_icons.h.template
│   ├── svg/
│   │   ├── fa_bolt.svg            (raw FA SVGs with CC BY 4.0 comments)
│   │   └── ... (69 .svg files)
│   └── prometheus_resources.grd   [NEW: or .grdp included from parent .grd]
├── chrome/browser/ui/webui/prometheus/
│   ├── prometheus_theme_preview_ui.cc [NEW]
│   └── prometheus_theme_preview_ui.h  [NEW]
├── chrome/browser/ui/webui/chrome_web_ui_configs.cc [MODIFIED: add config]
├── chrome/browser/prometheus/
│   ├── prometheus_action.h        [NEW: PrometheusAction enum + resolver maps]
│   └── prometheus_color_mixer_unittest.cc [NEW: per D-14]
└── third_party/
    ├── poppins/
    │   ├── README.chromium
    │   └── OFL.txt
    ├── space_mono/
    │   ├── README.chromium
    │   └── OFL.txt
    └── font_awesome_free/
        ├── README.chromium
        └── LICENSE              (CC BY 4.0 for icons, OFL for fonts, MIT for code)
```

### Pattern 1: Adding Color Ids to COMMON_CHROME_COLOR_IDS

**What:** Insert a named block of `E_CPONLY()` entries into the `COMMON_CHROME_COLOR_IDS` macro in `chrome_color_id.h`, before `kChromeColorsEnd`. The macro generates both the enum values and the string name map used for CSS emission.

**Example:**
```cpp
// Source: chrome/browser/ui/color/chrome_color_id.h (verified at baseline)
// Pattern matches existing kColorActorUi* cluster at lines 30-36.
// Add at end of COMMON_CHROME_COLOR_IDS, before kChromeColorsEnd:

/* Prometheus design system token colors. */  \
E_CPONLY(kColorPrometheusBgApp)              \
E_CPONLY(kColorPrometheusChrome)             \
E_CPONLY(kColorPrometheusChrome2)            \
E_CPONLY(kColorPrometheusSurface)            \
E_CPONLY(kColorPrometheusSurface2)           \
E_CPONLY(kColorPrometheusSurface3)           \
E_CPONLY(kColorPrometheusTabActive)          \
E_CPONLY(kColorPrometheusTabIdle)            \
E_CPONLY(kColorPrometheusTabHover)           \
E_CPONLY(kColorPrometheusText)               \
E_CPONLY(kColorPrometheusText2)              \
E_CPONLY(kColorPrometheusText3)              \
E_CPONLY(kColorPrometheusBorder)             \
E_CPONLY(kColorPrometheusBorder2)            \
E_CPONLY(kColorPrometheusHairline)           \
E_CPONLY(kColorPrometheusAccent)             \
E_CPONLY(kColorPrometheusAccent2)            \
E_CPONLY(kColorPrometheusAccentSoft)         \
E_CPONLY(kColorPrometheusAccentSoft2)        \
E_CPONLY(kColorPrometheusAccentGlow)
```

**CSS output (auto-emitted):** `kColorPrometheusBgApp` → `--color-prometheus-bg-app`, `kColorPrometheusAccent` → `--color-prometheus-accent`. The conversion function strips the leading `k`, then converts CamelCase to kebab-case with double-dash prefix: `k`→`-`, `C`→`-c` combined = `--color-...`.

### Pattern 2: Prometheus Color Mixer Implementation

**What:** A new `prometheus_color_mixer.cc` that assigns per-id SkColor values using `ColorProvider::AddMixer()`. The `dark_mode` flag from `key.color_mode` selects which hex table to apply. Function signature mirrors existing mixers exactly.

**Example:**
```cpp
// Source: chrome/browser/ui/color/chrome_color_mixers.cc (verified at baseline)
// Pattern: AddTabStripColorMixer, AddMaterialChromeColorMixer
void AddPrometheusColorMixer(ui::ColorProvider* provider,
                              const ui::ColorProviderKey& key) {
  const bool dark_mode =
      key.color_mode == ui::ColorProviderKey::ColorMode::kDark;

  ui::ColorMixer& mixer = provider->AddMixer();

  // Dark warm palette (canonical hex from styles.css / DESIGN-REFERENCE.md)
  if (dark_mode) {
    mixer[kColorPrometheusBgApp]    = {SkColorSetRGB(0x0d, 0x0a, 0x09)};
    mixer[kColorPrometheusChrome]   = {SkColorSetRGB(0x1d, 0x18, 0x16)};
    mixer[kColorPrometheusChrome2]  = {SkColorSetRGB(0x18, 0x13, 0x11)};
    mixer[kColorPrometheusSurface]  = {SkColorSetRGB(0x14, 0x11, 0x10)};
    mixer[kColorPrometheusSurface2] = {SkColorSetRGB(0x1d, 0x18, 0x16)};
    mixer[kColorPrometheusSurface3] = {SkColorSetRGB(0x26, 0x20, 0x1d)};
    mixer[kColorPrometheusTabActive]= {SkColorSetRGB(0x2a, 0x22, 0x1e)};
    mixer[kColorPrometheusText]     = {SkColorSetRGB(0xf6, 0xef, 0xe9)};
    mixer[kColorPrometheusText2]    = {SkColorSetRGB(0xd2, 0xc1, 0xb4)};
    mixer[kColorPrometheusText3]    = {SkColorSetRGB(0xa9, 0x92, 0x83)};
    // tab-idle and hairline are rgba — use SkColorSetARGB
    mixer[kColorPrometheusTabIdle]  = {SK_ColorTRANSPARENT};
    // border/hairline as closest opaque approximation (rgba not supported in SkColor alpha)
  } else {
    // Light warm palette
    mixer[kColorPrometheusBgApp]    = {SkColorSetRGB(0xe9, 0xe2, 0xda)};
    mixer[kColorPrometheusChrome]   = {SkColorSetRGB(0xf3, 0xed, 0xe6)};
    // ...
  }

  // Accent resolved from Prometheus-owned pref (default FSB Orange)
  mixer[kColorPrometheusAccent]   = {SkColorSetRGB(0xff, 0x6b, 0x35)};
  mixer[kColorPrometheusAccent2]  = {SkColorSetRGB(0xff, 0x8c, 0x42)};
  // accent-soft/soft-2/glow: derive from accent with alpha blending
  // styles.css: color-mix(in srgb, var(--accent) 12%, transparent)
  // Chromium equivalent: ui::AlphaBlend(accent, SK_ColorTRANSPARENT, 0.12 * 0xff)
}
```

### Pattern 3: Registering Prometheus Mixer Last in AddChromeColorMixers

**What:** Add `AddPrometheusColorMixer(provider, key)` at the end of `AddChromeColorMixers()` in `chrome_color_mixers.cc`, after `AddNativeChromeColorMixer` but before the `key.custom_theme` and `key.app_controller` blocks. This ensures the Prometheus warm palette overrides all GM3/Material defaults.

**Example:**
```cpp
// Source: chrome/browser/ui/color/chrome_color_mixers.cc (verified at baseline)
// Current last-mixer call before custom theme:
AddNativeChromeColorMixer(provider, key);  // must remain before Prometheus

// ADD HERE (after AddNativeChromeColorMixer, before custom_theme block):
AddPrometheusColorMixer(provider, key);    // NEW

if (key.custom_theme) { ... }
```

### Pattern 4: WebUIController Registration

**What:** A minimal `PrometheusThemePreviewUI` WebUIController with `PrometheusThemePreviewUIConfig` registered in `RegisterChromeWebUIConfigs()`. Pattern from `InternalsUI` (~65 lines total).

**Example:**
```cpp
// Source: chrome/browser/ui/webui/internals/internals_ui.cc (verified at baseline)
// PrometheusThemePreviewUIConfig:
class PrometheusThemePreviewUIConfig
    : public DefaultWebUIConfig<PrometheusThemePreviewUI> {
 public:
  PrometheusThemePreviewUIConfig()
      : DefaultWebUIConfig(content::kChromeUIScheme,
                           "prometheus-theme-preview") {}
};

// Registration in chrome_web_ui_configs.cc RegisterChromeWebUIConfigs():
map.AddWebUIConfig(std::make_unique<PrometheusThemePreviewUIConfig>());
```

### Pattern 5: aggregate_vector_icons GN Target

**What:** The `aggregate_vector_icons` template from `components/vector_icons/vector_icons.gni` takes a list of `.icon` source files and generates `vector_icons.cc` + `vector_icons.h` with typed `extern const gfx::VectorIcon&` constants. The template requires local `.cc.template` and `.h.template` files in the `icon_directory`.

**Example:**
```gn
# Source: components/vector_icons/BUILD.gn (verified at baseline)
import("//components/vector_icons/vector_icons.gni")

aggregate_vector_icons("prometheus_vector_icons") {
  icon_directory = "vector_icons"  # relative to chrome/browser/resources/prometheus/

  sources = [
    "fa_bolt.icon",
    "fa_compass.icon",
    "fa_layer_group.icon",
    # ... all 69 glyphs
  ]
}
```

Note: The templates (`vector_icons.cc.template`, `vector_icons.h.template`) must be copied from `components/vector_icons/` into the icon directory, or the path adjusted via `rebase_path`. The `.icon` format is path-command text: `CANVAS_DIMENSIONS, 16, FILL_RULE_NONZERO, MOVE_TO, ...`.

### Pattern 6: Font @font-face (WebUI)

**What:** `prometheus_fonts.css` with `@font-face` rules using `url(//resources/prometheus/fonts/…woff2)` format, mirroring `ui/webui/resources/css/roboto.css` exactly.

**Example:**
```css
/* Source: ui/webui/resources/css/roboto.css (verified at baseline) */
/* Replicate for Poppins/Space Mono: */
@font-face {
  font-family: 'Poppins';
  font-style: normal;
  font-weight: 100;
  src: url(//resources/prometheus/fonts/Poppins-Thin.woff2) format('woff2');
}
@font-face {
  font-family: 'Poppins';
  font-style: normal;
  font-weight: 300;
  src: url(//resources/prometheus/fonts/Poppins-Light.woff2) format('woff2');
}
/* weights 800, 900; then Space Mono regular */
```

### Pattern 7: PlatformFontMac SkTypeface Shim (as-needed Views path)

**What:** Load font bytes from ResourceBundle and construct `PlatformFontMac` with `SkTypeface`, for native Views labels that need Poppins/Space Mono before Phase 15/16. Constructor signature verified at `ui/gfx/platform_font_mac.h` line 48.

**Example:**
```cpp
// Source: ui/gfx/platform_font_mac.h:48 (verified at baseline)
// PlatformFontMac(sk_sp<SkTypeface> typeface, std::optional<SystemFontType>)
auto bytes = ui::ResourceBundle::GetSharedInstance()
    .GetRawDataResource(IDR_PROMETHEUS_FONT_SPACE_MONO_TTF);
auto stream = SkMemoryStream::MakeDirect(bytes.data(), bytes.size());
sk_sp<SkTypeface> tf = SkTypeface::MakeFromStream(std::move(stream));
auto* font = new gfx::PlatformFontMac(tf, std::nullopt);
```

### Anti-Patterns to Avoid

- **Putting Prometheus ids BEFORE kChromeColorsStart:** The `kChromeColorsStart` anchor is defined at `color::kComponentsColorsEnd`. Prometheus ids must be in the `COMMON_CHROME_COLOR_IDS` macro block which feeds the `ChromeColorIds` enum between `kChromeColorsStart` and `kChromeColorsEnd`. This is what makes them discoverable by `theme_source.cc::GenerateColorsCss`.
- **Requesting `sets=prometheus` in colors.css URL:** There is no separate "prometheus" set. Prometheus ids live in the "chrome" set (`kChromeColorsStart`..`kChromeColorsEnd`). WebUI must request `chrome://theme/colors.css?sets=chrome`.
- **Using `user_color` / `UserColorSource::kAccent` for the warm palette:** D-04 is explicit — this regenerates a neutral GM3 tonal ramp that fights the warm palette. The Prometheus mixer owns its own ids and assigns them directly at the leaf.
- **Registering CTFontManager globally for WebUI fonts:** D-11 is explicit — no OS-level font registration. Use the GRIT/pak + @font-face WebUI path for WebUI; use the SkTypeface shim only for as-needed native Views labels.
- **Using `color-mix()` for accent-soft derivations in CSS only:** The C++ mixer must also produce `kColorPrometheusAccentSoft` etc. as computed SkColor values because Views reads them directly. The CSS `color-mix()` in `styles.css` is a reference; in C++ use `ui::AlphaBlend` or `SkColorSetA` to replicate the 12%/18%/24% alpha mixing.
- **Running `aggregate_vector_icons.py` directly:** It is invoked by the GN action template; do not call it from the conversion helper script. The conversion helper only produces `.icon` files from FA SVGs; the GN target composes them.
- **Stripping HTML comments from FA SVGs during bundling:** The CC BY 4.0 attribution comment is inside the SVG XML. Any minification step that strips comments violates the license requirement (D-12 check 4). The asset gate must grep for the attribution comment.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| C++→CSS token emission | Custom template/codegen | `theme_source.cc` + `ConvertColorProviderColorIdToCSSColorId` | Auto-emits all `kChromeColorsStart..kChromeColorsEnd` ids; zero maintenance cost |
| Dark/light switching | New pref + native theme observer | `prefs::kBrowserColorScheme` + `ThemeService::BrowserColorScheme` | Already wired to `NativeTheme::ShouldUseDarkColors()`; browser handles all the observer chains |
| SVG→C++ icon conversion in GN | Custom Python GN action | `aggregate_vector_icons.py` (via GN template) | Standard machinery; generates correctly structured `vector_icons.h` with typed constants |
| WebUI font delivery CDN fallback | Runtime CDN check + fallback | Bundled woff2 in GRIT with no `src: local()` or network URL | Offline requirement is absolute (DESIGN-03); no network fallback permitted |
| License metadata discovery | Custom registry | `tools/licenses/licenses.py` + `README.chromium` schema | Chromium credits tooling reads README.chromium; non-standard metadata is invisible to `chrome://credits` |
| Color id string names for debugging | Custom enum-to-string map | `CHROME_COLOR_IDS` macro + `color_id_map_macros.inc` | The E_CPONLY macro auto-generates the id-name pairs used by `ChromeColorIdName()` |

---

## Runtime State Inventory

This is a greenfield asset port (no rename/refactor of existing state). The only runtime state relevant to Phase 14 is:

| Category | Items Found | Action Required |
|----------|-------------|-----------------|
| Stored data | None — no Prometheus color data yet stored in any database or profile | None |
| Live service config | None | None |
| OS-registered state | None — no CTFontManager registration is being added (D-11 explicit) | None |
| Secrets/env vars | None | None |
| Build artifacts | `.context/chromium/src/out/Default/` — existing build from Phase 13 branch | Wave 0: create new `prometheus/phase-14-assets` branch from Phase 13 tip; rebuild after GN changes |

**Phase 13 branch state:** The Chromium checkout is currently on branch `prometheus/phase-13-branding` with 2 commits ahead of the pinned baseline. Phase 14 must branch from this tip (not from the raw pinned baseline) to inherit the branding patches.

---

## Common Pitfalls

### Pitfall 1: rgba Tokens Lose Precision as SkColor

**What goes wrong:** The canonical `styles.css` uses `rgba(41,29,20,0.10)` for `--border` (light theme). `SkColor` is 8-bit per channel, so the alpha `0.10 * 255 = 25.5` rounds to 25, giving `rgba(41,29,20,0.098)` — a perceptible but small drift.
**Why it happens:** SkColor uses `uint8_t` alpha, not float.
**How to avoid:** Use `SkColorSetARGB(25, 41, 29, 20)` (rounds 0.10*255) and document the intentional rounding. For `accent-soft/glow`, use `ui::AlphaBlend()` for the derivation rather than a hardcoded hex.
**Warning signs:** Tests asserting exact hex values on rgba tokens will see off-by-one on alpha channel.

### Pitfall 2: Mixing Up `sets=chrome` vs `sets=ui` in colors.css URL

**What goes wrong:** WebUI page requests `chrome://theme/colors.css?sets=ui` instead of `sets=chrome`. The `ui` set covers `kUiColorsStart..kUiColorsEnd` (platform/shared ids). Prometheus ids are in the `chrome` set. The `--color-prometheus-*` variables never appear.
**Why it happens:** Documentation/precedent for `sets=ui` is more visible; the chrome-specific set is less obvious.
**How to avoid:** Verify in `theme_source.cc` lines 292-310 — the "chrome" set maps `kChromeColorsStart..kChromeColorsEnd` via `ChromeColorIdName`. Use `?sets=chrome` or `?sets=ui,chrome` if also needing ui tokens.
**Warning signs:** `--color-prometheus-accent` is undefined in WebUI but Colors DevTools shows no error (the unknown property is silently ignored).

### Pitfall 3: Font Awesome SVG Comments Stripped by Build Tooling

**What goes wrong:** An SVG optimization pass (SVGO, htmlmin, grit preprocessing) strips XML comments from FA SVGs. The CC BY 4.0 attribution comment is inside the SVG; stripping it violates the license.
**Why it happens:** SVGO default config strips comments for size reduction.
**How to avoid:** Configure SVGO with `--config` that sets `{ "name": "removeComments", "active": false }`. The conversion helper script must pass this flag. The asset validation gate must grep for the FA attribution pattern in every bundled SVG.
**Warning signs:** Asset validation gate fails with "FA SVG missing CC BY 4.0 comment".

### Pitfall 4: Building Phase 14 Patches on Detached HEAD or Wrong Branch

**What goes wrong:** Developer creates `.icon` files or mixer code while on a detached HEAD or on the Phase 13 branch directly. Phase 14 patches overwrite Phase 13 patches when exported, or Phase 14 changes lose the Phase 13 branding patches on a fresh checkout.
**Why it happens:** `git format-patch` from the pinned baseline includes all commits since that SHA; if Phase 13 and 14 are on the same branch, they're interleaved.
**How to avoid:** Branch from Phase 13 tip (`git new-branch prometheus/phase-14-assets`) — this creates a Phase-14-only branch that inherits Phase 13 commits but keeps Phase 14 patches cleanly separable. Export with `git format-patch <phase13-tip-sha>..HEAD -o …/phase-14-assets/`.
**Warning signs:** `git format-patch` output includes files from Phase 13 branding patches.

### Pitfall 5: kColorPrometheus Ids Outside the COMMON_CHROME_COLOR_IDS macro

**What goes wrong:** Developer adds Prometheus ids to the enum body directly (not through the `COMMON_CHROME_COLOR_IDS` macro). The `color_id_map_macros.inc` mechanism only generates the id-name pairs for ids declared via `E_CPONLY` inside the macro. Ids added directly to the enum are invisible to `ChromeColorIdName()` → the CSS emission loop skips them → no `--color-prometheus-*` properties emitted.
**Why it happens:** The macro-based indirection is non-obvious; the enum `ChromeColorIds` looks directly editable.
**How to avoid:** All `kColorPrometheus*` ids must appear inside `COMMON_CHROME_COLOR_IDS` as `E_CPONLY(...)` entries.
**Warning signs:** Unit test for CSS custom-property emission fails — `--color-prometheus-accent` absent in colors.css output.

### Pitfall 6: aggregate_vector_icons Template Not Finding Templates

**What goes wrong:** `aggregate_vector_icons("prometheus_vector_icons")` runs but fails because `vector_icons.cc.template` and `vector_icons.h.template` are not found in `icon_directory`.
**Why it happens:** The template requires these files to exist in the same directory as the `.icon` sources (see `vector_icons.gni` lines: `inputs = rebase_path(templates + invoker.sources, ".", invoker.icon_directory)`).
**How to avoid:** Copy `components/vector_icons/vector_icons.cc.template`, `vector_icons.h.template`, and (if needed) `vector_icons_unittest.h.template` into the `chrome/browser/resources/prometheus/vector_icons/` directory alongside the `.icon` files.
**Warning signs:** GN action fails with "No such file" error on template files.

---

## Code Examples

### Dark/Light Mixer Hex Values (verbatim from styles.css)

```cpp
// Source: .planning/design/prometheus-browser/prometheus/styles.css (verified)
// DARK THEME (data-theme="dark"):
// --bg-app:     #0d0a09 -> SkColorSetRGB(0x0d, 0x0a, 0x09)
// --chrome:     #1d1816 -> SkColorSetRGB(0x1d, 0x18, 0x16)
// --chrome-2:   #181311 -> SkColorSetRGB(0x18, 0x13, 0x11)
// --surface:    #141110 -> SkColorSetRGB(0x14, 0x11, 0x10)
// --surface-2:  #1d1816 -> SkColorSetRGB(0x1d, 0x18, 0x16)  [same as chrome]
// --surface-3:  #26201d -> SkColorSetRGB(0x26, 0x20, 0x1d)
// --tab-active: #2a221e -> SkColorSetRGB(0x2a, 0x22, 0x1e)
// --tab-idle:   transparent -> SK_ColorTRANSPARENT (or SkColorSetARGB(0,0,0,0))
// --tab-hover:  rgba(255,241,232,0.06) -> SkColorSetARGB(15, 255, 241, 232)
// --text:       #f6efe9 -> SkColorSetRGB(0xf6, 0xef, 0xe9)
// --text-2:     #d2c1b4 -> SkColorSetRGB(0xd2, 0xc1, 0xb4)
// --text-3:     #a99283 -> SkColorSetRGB(0xa9, 0x92, 0x83)
// --border:     rgba(255,241,232,0.10) -> SkColorSetARGB(25, 255, 241, 232)
// --border-2:   rgba(255,241,232,0.18) -> SkColorSetARGB(45, 255, 241, 232)
// --hairline:   rgba(255,241,232,0.06) -> SkColorSetARGB(15, 255, 241, 232)

// LIGHT THEME (data-theme="light"):
// --bg-app:     #e9e2da -> SkColorSetRGB(0xe9, 0xe2, 0xda)
// --chrome:     #f3ede6 -> SkColorSetRGB(0xf3, 0xed, 0xe6)
// --chrome-2:   #ece4db -> SkColorSetRGB(0xec, 0xe4, 0xdb)
// --surface:    #fffdfb -> SkColorSetRGB(0xff, 0xfd, 0xfb)
// --surface-2:  #f8f4ef -> SkColorSetRGB(0xf8, 0xf4, 0xef)
// --surface-3:  #f1ebe4 -> SkColorSetRGB(0xf1, 0xeb, 0xe4)
// --tab-active: #fffdfb -> SkColorSetRGB(0xff, 0xfd, 0xfb)  [same as surface]
// --tab-idle:   transparent -> SK_ColorTRANSPARENT
// --tab-hover:  rgba(41,29,20,0.05) -> SkColorSetARGB(12, 41, 29, 20)
// --text:       #1f1a17 -> SkColorSetRGB(0x1f, 0x1a, 0x17)
// --text-2:     #6a584d -> SkColorSetRGB(0x6a, 0x58, 0x4d)
// --text-3:     #8d7a6e -> SkColorSetRGB(0x8d, 0x7a, 0x6e)
// --border:     rgba(41,29,20,0.10) -> SkColorSetARGB(25, 41, 29, 20)
// --border-2:   rgba(41,29,20,0.16) -> SkColorSetARGB(40, 41, 29, 20)
// --hairline:   rgba(41,29,20,0.08) -> SkColorSetARGB(20, 41, 29, 20)

// ACCENT (same both themes):
// --accent:     #ff6b35 -> SkColorSetRGB(0xff, 0x6b, 0x35)
// --accent-2:   #ff8c42 -> SkColorSetRGB(0xff, 0x8c, 0x42)
// accent-soft:  color-mix(accent 12%, transparent) -> SkColorSetARGB(30, 0xff, 0x6b, 0x35)
// accent-soft-2: color-mix(accent 18%, transparent) -> SkColorSetARGB(45, 0xff, 0x6b, 0x35)
// accent-glow:  color-mix(accent 24%, transparent) -> SkColorSetARGB(61, 0xff, 0x6b, 0x35)
```

### README.chromium Schema (third_party/poppins/)

```text
# Source: third_party/test_fonts/README.chromium (verified at baseline)
Name: Poppins
URL: https://github.com/itfoundry/poppins
Version: 8.003
Revision: N/A
Update Mechanism: Manual
License: OFL-1.1
License File: OFL.txt
Security Critical: no
Shipped: yes

Description:
Poppins typeface bundled for use as the Prometheus display/wordmark/UI font.
Required weights: Thin (100), Light (300), ExtraBold (800), Black (900).
Both woff2 (WebUI) and ttf (native Views shim) formats are bundled.
```

### VIS Checks Satisfied by Phase 14 Harness

[ASSUMED: The exact VIS check IDs below are drawn from the FALKON-TO-CHROMIUM-PRESERVATION.md ledger. The planner must confirm against the ledger before tagging `satisfied-by-Ph14-harness`.]

From the 26 carry-forward visual checks, Phase 14 harness satisfies:
- **VIS-09-01** (Two-weight PM monogram rendering — Poppins weights bundled and rendered)
- **VIS-09-02** (About dialog PrometheusMarkWidget at 128px — shared with Phase 13, Phase 14 confirms font delivery)
- **VIS-09-03** (Dark/light theme toggle without restart — ColorChangeHandler test)
- **VIS-09-04** (Accent swatch picker changes accent immediately — accent token pref test)
- **VIS-09-05** (Toolbar icons are bundled FA vector glyphs, not platform-theme — VectorIcon resource test)
- **VIS-09-07** (Font license OFL text accessible — OFL.txt present in third_party/, NOTICES.md correct)
- **VIS-09-08** (No network font requests during cold start — grep gate on remote URLs)
- **VIS-10-07** (Offline asset validation — grep gate on remote URLs in all bundled CSS/HTML/SVG)

NOT satisfied by Phase 14 (stay with later owner phases):
- VIS-08-* (all 10 control-panel/side-panel checks) → Phase 16/20
- VIS-09-06 (App icon in Finder/Dock at packaged size) → Phase 13/24
- VIS-10-01..VIS-10-06, VIS-10-08 (start-page checks) → Phase 16

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| QSS token files (`falkon/themes/prometheus/*.qss`) | Chromium color mixer + auto-emitted CSS custom properties | Phase 14 (this phase) | Single C++ source of truth; no dual QSS+CSS maintenance |
| `QIcon::fromTheme()` for icons | `gfx::VectorIcon` + `aggregate_vector_icons` | Phase 14 | Deterministic, offline, not dependent on platform icon theme |
| `QFontDatabase::addApplicationFont()` | GRIT .pak + @font-face (WebUI); SkTypeface shim (Views) | Phase 14 | Bundled in Chromium resource pack; no Qt dependency |
| Falkon QSS `[data-theme]` selector | `BrowserColorScheme` pref + mixer `dark_mode` flag | Phase 14 | Integrated with Chromium's native dark mode infrastructure |

**Note on Color Naming Convention:** The CSS output from `ConvertColorProviderColorIdToCSSColorId` produces double-dash CSS custom property names automatically. `kColorPrometheusAccent` → `--color-prometheus-accent`. WebUI CSS uses `var(--color-prometheus-accent)`. This is verified by checking how `kColorToolbarButtonIcon` is referenced in `chrome/browser/resources/webui_toolbar/toolbar_button.css` as `var(--color-toolbar-button-icon)`.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | VIS check assignments (VIS-09-01..09-08, VIS-10-07 as Phase 14 scope) are drawn from the preservation ledger; the planner must confirm the exact ids before tagging | Common Pitfalls / Code Examples | Planner over- or under-tags satisfied checks |
| A2 | Accent-soft derivations (12%/18%/24% alpha mixing) can be computed as integer alpha values in SkColor without perceptible error vs. CSS `color-mix()` | Code Examples | Slight visual drift in accent-glow / focus ring softness; acceptable given 8-bit alpha precision |
| A3 | Poppins woff2 files from the v1 Falkon bundle (`falkon/src/lib/data/fonts/poppins/`) have the 4 required weights and can be re-vendored as-is | Standard Stack | If v1 bundle has different weights, new woff2 files must be sourced from Google Fonts / original repo |
| A4 | FA Free 6.x SVG files from v1 bundle have intact CC BY 4.0 attribution comments; the preservation pipeline did not strip them | Common Pitfalls | If stripped during v1 pipeline, comments must be re-added before vendoring |
| A5 | `chrome://prometheus-theme-preview` is the host name; `chrome://prometheus-internals/theme` is an alternative (Claude's Discretion) | Architecture Patterns | No user impact; planner picks one |

---

## Open Questions

1. **Accent pref storage location**
   - What we know: D-05 says accent is stored in a Prometheus-owned pref, NOT `ColorProviderKey::user_color`.
   - What's unclear: Where the pref is registered (new Prometheus pref file vs. extending `chrome/common/pref_names.h`) and how the mixer reads it (pref service is not available in mixer context; may need ColorProviderKey custom data or a `PrefService*` callback).
   - Recommendation: For Phase 14, hardcode the default accent (`#ff6b35`) in the mixer; stub the pref-reading path. The picker UI (deferred to Phase 16) is what needs live pref → mixer wiring. The planner should note this as a Wave 1 implementation constraint.

2. **Poppins ttf availability for Views shim**
   - What we know: D-11 says ship TTF for the Views shim path. The v1 Falkon bundle has `falkon/src/lib/data/fonts/poppins/*.ttf`.
   - What's unclear: Whether Space Mono and Poppins TTFs from the v1 bundle are the exact versions that should be vendored, or whether fresh download from source is required to confirm provenance.
   - Recommendation: Source fresh from upstream (fonts.google.com / github.com/itfoundry/poppins) to ensure clean provenance for `README.chromium`; do not rely on the v1 bundle as the authoritative font source.

3. **accent-soft/glow derivation in CSS vs. C++**
   - What we know: `styles.css` uses `color-mix(in srgb, var(--accent) 12%, transparent)`. C++ mixer must produce an SkColor equivalent.
   - What's unclear: Whether `SkColorSetARGB(30, 0xff, 0x6b, 0x35)` (12% of 255 ≈ 30) matches browsers' `color-mix(in srgb, #ff6b35 12%, transparent)` output precisely.
   - Recommendation: Use `SkColorSetARGB(static_cast<uint8_t>(0.12 * 255), ...)` and document the rounding. The DESIGN-07 visual verification will catch any perceptible drift.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Chromium checkout | All patches | ✓ | `0e8499df5172f55d0d29e2b92ef7e6a704529578` | None — required |
| Chromium build (`autoninja`) | Rebuild after patches | ✓ | depot_tools `ea253a3e` | Rerun `build-chromium-baseline.sh` |
| Xcode 26.5 | Chromium macOS build | ✓ | Xcode 26.5 Build 17F42 | None |
| Metal Toolchain | ANGLE Metal shader compilation | ✓ | Apple metal 32023.883 | None |
| skiafy (external) | convert-fa-icons.sh | Not verified (build-time only) | Unknown | Manual `.icon` authoring for glyphs |
| SVGO (external) | convert-fa-icons.sh | Not verified (build-time only) | Unknown | Skip SVGO step; FA SVGs are already optimized |
| Poppins woff2/ttf source files | GRIT packaging | In v1 Falkon bundle (ttf); fresh woff2 from upstream | Various | See Open Question 2 |
| FA Free 6.x SVG sources | Icon port | In v1 Falkon bundle (69 SVGs) | 6.x (exact version TBD) | Fresh download from fontawesome.com/download |

**Missing dependencies with fallback:**
- skiafy: if unavailable, `.icon` files can be authored manually from FA SVG path data, but the conversion helper must document the tool install steps.
- SVGO: skip the optimization step; FA SVGs are already compact.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | GTest (Chromium's standard C++ test harness) |
| Config file | `chrome/browser/prometheus/BUILD.gn` (new) — test target to be created |
| Quick run command | `autoninja -C out/Default prometheus_color_mixer_unittests && ./out/Default/prometheus_color_mixer_unittests` |
| Full suite command | `autoninja -C out/Default prometheus_color_mixer_unittests && ./out/Default/prometheus_color_mixer_unittests --gtest_filter=*` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DESIGN-01 | Each `kColorPrometheus*` id resolves to correct SkColor in dark mode | unit | `prometheus_color_mixer_unittests --gtest_filter=*DarkMode*` | ❌ Wave 0 |
| DESIGN-01 | Each `kColorPrometheus*` id resolves to correct SkColor in light mode | unit | `prometheus_color_mixer_unittests --gtest_filter=*LightMode*` | ❌ Wave 0 |
| DESIGN-01+06 | `--color-prometheus-*` CSS custom properties appear in colors.css output when `sets=chrome` | unit | `prometheus_color_mixer_unittests --gtest_filter=*CssEmission*` | ❌ Wave 0 |
| DESIGN-02 | `kColorPrometheusAccent` resolves to `#ff6b35` (default swatch) | unit | `--gtest_filter=*AccentDefault*` | ❌ Wave 0 |
| DESIGN-03 | No `https://` or `fonts.googleapis.com` URLs in bundled CSS/woff2 paths | static grep | `grep -rn 'https://\|fonts.googleapis.com' chrome/browser/resources/prometheus/` | ❌ Wave 0 (gate script) |
| DESIGN-03 | IDR constants for Poppins and Space Mono woff2 resources resolve (non-null) | unit | `--gtest_filter=*FontResource*` | ❌ Wave 0 |
| DESIGN-04 | CC BY 4.0 attribution comment present in each bundled FA SVG | static grep | `bash .planning/chromium/verify-asset-pipeline.sh` | ❌ Wave 0 (gate script) |
| DESIGN-04 | IDR constants for FA SVGs resolve (non-null) | unit | `--gtest_filter=*IconResource*` | ❌ Wave 0 |
| DESIGN-05 | IDR constants for PM mark, wordmark, FSB logos (dark+light) resolve | unit | `--gtest_filter=*BrandAsset*` | ❌ Wave 0 |
| DESIGN-06 | `kColorPrometheus*` ids are in `kChromeColorsStart..kChromeColorsEnd` range | unit | `--gtest_filter=*ColorIdRange*` | ❌ Wave 0 |
| DESIGN-07 | Visual token gallery renders (dev surface evidence capture) | manual/screenshot | Open `chrome://prometheus-theme-preview`, switch dark/light | ❌ Wave 4 |
| DESIGN-07 | Views token gallery rebuilds correctly on `OnThemeChanged()` | unit/visual | Build views_examples with Prometheus tokens | ❌ Wave 4 |

### Sampling Rate

- **Per task commit:** Quick unit test run (`prometheus_color_mixer_unittests`)
- **Per wave merge:** Full unit suite + `verify-asset-pipeline.sh` + `check-falkon-gpl-guard.sh` + `verify-artifact-isolation.sh`
- **Phase gate:** Full suite green + dev surface screenshot evidence captured + VIS checks marked `satisfied-by-Ph14-harness` before `/gsd-verify-work`

### Wave 0 Gaps

- [ ] `chrome/browser/prometheus/prometheus_color_mixer_unittest.cc` — covers DESIGN-01, DESIGN-02, DESIGN-06 dark/light resolution
- [ ] `chrome/browser/prometheus/prometheus_css_emission_unittest.cc` — covers DESIGN-01+06 CSS property emission
- [ ] `chrome/browser/prometheus/prometheus_asset_resource_unittest.cc` — covers DESIGN-03, DESIGN-04, DESIGN-05 IDR resolution
- [ ] `chrome/browser/prometheus/BUILD.gn` — test target declaration
- [ ] `.planning/chromium/verify-asset-pipeline.sh` — covers DESIGN-03, DESIGN-04 static grep gate
- [ ] `chrome/browser/ui/color/prometheus_color_mixer.{cc,h}` — Wave 0 stubs with placeholder values

---

## Security Domain

> `security_enforcement` not explicitly disabled in `.planning/config.json` — section included.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Assets are static resources, no auth boundary |
| V3 Session Management | no | No session state in design tokens |
| V4 Access Control | partial | `chrome://prometheus-theme-preview` is dev-only; must not be accessible in release builds (feature gate via `DCHECK` or buildflags) |
| V5 Input Validation | no | No user input in token/asset pipeline |
| V6 Cryptography | no | No crypto in this phase |
| V7 Error Handling | no | |
| V8 Data Protection | partial | Font and icon assets are public; no secrets. OFL/CC-BY license metadata is a legal obligation, not a security concern |
| V9 Communication | no | All assets are bundled offline; no network communication |
| V13 API Security | no | |

### Known Threat Patterns for Asset/Color Pipeline

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Remote URL in bundled CSS (DESIGN-03 breach) | Tampering / Info Disclosure | `verify-asset-pipeline.sh` grep gate; no `https://` in any bundled CSS/HTML/SVG |
| GPL Falkon source copied into Chromium | Tampering (license violation) | `check-falkon-gpl-guard.sh` runs before every phase-14 commit |
| `chrome://prometheus-theme-preview` accessible in production | Elevation of Privilege | Wrap controller registration in `#if DCHECK_IS_ON()` or a `prometheus_dev` buildflag; not needed for Phase 14 timeline but note as hardening |
| Font files without OFL provenance | Tampering (license violation) | `verify-asset-pipeline.sh` asserts OFL.txt present per third_party dir and root LICENSES/ placeholders filled |

---

## Sources

### Primary (HIGH confidence — verified in Chromium source tree at `0e8499df5172f55d0d29e2b92ef7e6a704529578`)

- `chrome/browser/ui/color/chrome_color_id.h` — `kChromeColorsStart`, `kChromeColorsEnd`, `E_CPONLY` macro, `COMMON_CHROME_COLOR_IDS`, `kColorActorUi*` cluster as precedent
- `chrome/browser/ui/color/chrome_color_mixers.cc` — `AddChromeColorMixers()` signature, mixer call order, `AddNativeChromeColorMixer` as last position before custom theme
- `chrome/browser/ui/color/chrome_color_mixer.cc` — mixer implementation pattern, `dark_mode` flag from `key.color_mode`
- `chrome/browser/ui/color/tab_strip_color_mixer.cc` — canonical simple mixer pattern
- `chrome/browser/ui/color/chrome_color_provider_utils.cc` — `ChromeColorIdName()` implementation
- `chrome/browser/ui/color/BUILD.gn` — `source_set("mixers")` target structure
- `ui/color/color_provider_utils.cc` — `ConvertColorProviderColorIdToCSSColorId()` implementation (lines 296-322); double-dash naming confirmed
- `ui/color/color_id_map_macros.inc` — `E_CPONLY` macro expansion producing `{enum_name, #enum_name}` pairs
- `chrome/browser/ui/webui/theme_source.cc` — `GenerateColorsCss()` implementation; `{kChromeColorsStart, kChromeColorsEnd, ...}` set definition (line 295); loop format `{var_name, ":", color_str, ";"}` (line 354)
- `ui/webui/color_change_listener/color_change_handler.h` — `ColorChangeHandler` Mojo class, `OnColorProviderChanged()` override
- `components/vector_icons/vector_icons.gni` — `aggregate_vector_icons` GN template, confirmed `icon_directory` parameter and template file requirement
- `components/vector_icons/aggregate_vector_icons.py` — confirmed no SVG-to-.icon conversion capability (composites only)
- `components/vector_icons/add_2.icon` — confirmed `.icon` path-command format
- `components/vector_icons/vector_icons.cc.template`, `vector_icons.h.template` — template files that must be in `icon_directory`
- `ui/gfx/vector_icon_types.h` — `gfx::VectorIcon` type
- `ui/base/models/image_model.h` — `ImageModel::FromVectorIcon` API
- `ui/webui/resources/roboto/` — 3 woff2 files confirmed; direct copy pattern for Poppins/Space Mono
- `ui/webui/resources/css/roboto.css` — @font-face pattern with `url(//resources/roboto/…)` format
- `ui/webui/resources/css/BUILD.gn` — `preprocess_if_expr` + `generate_grd` pattern for WebUI CSS resources
- `ui/gfx/platform_font_mac.h` line 48 — `PlatformFontMac(sk_sp<SkTypeface> typeface, std::optional<SystemFontType>)` constructor confirmed
- `chrome/browser/themes/theme_service.h` — `BrowserColorScheme { kSystem=0, kLight=1, kDark=2 }`, `SetBrowserColorScheme()`, `GetBrowserColorScheme()`
- `chrome/common/pref_names.h` line 694 — `kBrowserColorScheme[] = "browser.theme.color_scheme2"` confirmed
- `chrome/browser/ui/webui/chrome_web_ui_configs.cc` — `RegisterChromeWebUIConfigs()`, `WebUIConfigMap::GetInstance().AddWebUIConfig()` pattern
- `chrome/browser/ui/webui/internals/internals_ui.cc` — minimal WebUIController pattern (~65 lines): `DefaultWebUIConfig`, `WebUIDataSource::CreateAndAdd`, `WEB_UI_CONTROLLER_TYPE_IMPL`
- `ui/views/examples/colors_example.cc` — `InsertColorRow()`, `GetColorProvider()->GetColor()`, Views gallery pattern
- `ui/color/color_mixer_unittest.cc` — GTest unit test pattern for color mixer
- `chrome/browser/ui/color/chrome_color_provider_utils_unittest.cc` — ChromeColorIdName test pattern
- `third_party/test_fonts/README.chromium` — canonical README.chromium field schema
- `tools/licenses/licenses.py` — license tooling confirmed present

### Primary (HIGH confidence — verified in project planning files)

- `.planning/design/prometheus-browser/prometheus/styles.css` — all token hex values, rgba derivations, `color-mix` formulas
- `.planning/design/DESIGN-REFERENCE.md` — palette table, typography weights, PM mark construction
- `.planning/preservation/FALKON-TO-CHROMIUM-PRESERVATION.md` — VIS check ledger (VIS-08-* through VIS-10-*), asset inventory
- `NOTICES.md` (repo root) — Phase 13 legal baseline; FA/Poppins/SpaceMono sections present
- `.planning/chromium/LEGAL-NOTICE-INVENTORY.md` — `LICENSES/poppins-OFL.txt` and `LICENSES/spacemono-OFL.txt` are placeholders to be filled in Phase 14
- `.planning/chromium/check-falkon-gpl-guard.sh` — gate script convention (`set -euo pipefail`, `fail()`, `SCRIPT_DIR→PROJECT_ROOT`)
- `.planning/chromium/CHROMIUM-CHECKOUT.md` — current Chromium branch (`prometheus/phase-13-branding`), pinned baseline, patch discipline

### Secondary (MEDIUM confidence — CSS naming convention traced by code inspection)

- CSS double-dash naming: traced through `ConvertColorProviderColorIdToCSSColorId` implementation — `k`→`-`, `C`→`-c` combined = `--color-...`; cross-verified by `chrome/browser/resources/webui_toolbar/toolbar_button.css` which uses `var(--color-toolbar-button-icon)` for `kColorToolbarButtonIcon`

---

## Metadata

**Confidence breakdown:**
- Color pipeline (D-01, D-04): HIGH — every function and file verified at pinned baseline; implementation pattern traced end to end
- CSS emission naming: HIGH — `ConvertColorProviderColorIdToCSSColorId` read and traced; cross-verified with existing WebUI usage
- Icon pipeline (D-06, D-07, D-08, D-09): HIGH — template GN file read, .icon format inspected, no SVG converter confirmed
- Font/asset pipeline (D-10, D-11): HIGH — Roboto precedent verified; PlatformFontMac constructor confirmed
- Theme switching (D-03): HIGH — `BrowserColorScheme` enum and pref string confirmed in source
- Verification harness (D-13, D-14): HIGH — InternalsUI pattern and colors_example.cc read
- License gate (D-12): HIGH — check-falkon-gpl-guard.sh convention and tools/licenses confirmed
- VIS check assignments: MEDIUM (A1) — IDs from preservation ledger, planner must confirm

**Research date:** 2026-06-24
**Valid until:** 2026-07-24 (Chromium baseline is pinned; primitives will not change until a rebase)
