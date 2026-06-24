# Phase 14: Asset and Design System Port - Pattern Map

**Mapped:** 2026-06-24
**Files analyzed:** 22 new/modified files
**Analogs found:** 22 / 22

All Chromium source analogs are read from
`.context/chromium/src/` at pinned baseline `0e8499df5172f55d0d29e2b92ef7e6a704529578`
(branch `prometheus/phase-13-branding`). Gate script analogs are read from
`.planning/chromium/`.

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `chrome/browser/ui/color/chrome_color_id.h` | config (modify) | transform | self — `kColorActorUi*` block (lines 29–36) | exact |
| `chrome/browser/ui/color/prometheus_color_mixer.h` | config | transform | `chrome/browser/ui/color/tab_strip_color_mixer.h` | role-match |
| `chrome/browser/ui/color/prometheus_color_mixer.cc` | service | transform | `chrome/browser/ui/color/tab_strip_color_mixer.cc` + `chrome_color_mixer.cc` | exact |
| `chrome/browser/ui/color/chrome_color_mixers.cc` | config (modify) | transform | self — `AddChromeColorMixers` body (lines 57–86) | exact |
| `chrome/browser/ui/color/BUILD.gn` | config (modify) | — | self — `source_set("mixers")` (lines 19–50) | exact |
| `chrome/browser/resources/prometheus/css/prometheus_fonts.css` | utility | request-response | `ui/webui/resources/css/roboto.css` (lines 1–27) | exact |
| `chrome/browser/resources/prometheus/vector_icons/` (69 `.icon` files) | utility | transform | `components/vector_icons/add_2.icon` (lines 1–32) | exact |
| `chrome/browser/resources/prometheus/vector_icons/vector_icons.cc.template` | config | — | `components/vector_icons/vector_icons.cc.template` | exact copy |
| `chrome/browser/resources/prometheus/vector_icons/vector_icons.h.template` | config | — | `components/vector_icons/vector_icons.h.template` | exact copy |
| `chrome/browser/resources/prometheus/BUILD.gn` (vector icons target) | config | — | `components/vector_icons/BUILD.gn` lines 1–60 | exact |
| `chrome/browser/ui/webui/prometheus/prometheus_theme_preview_ui.cc` | controller | request-response | `chrome/browser/ui/webui/internals/internals_ui.cc` (lines 1–65) | exact |
| `chrome/browser/ui/webui/chrome_web_ui_configs.cc` (modify) | config | — | self — `RegisterChromeWebUIConfigs` (lines 245–274) | exact |
| `chrome/browser/prometheus/prometheus_action.h` | utility | transform | `ui/base/models/image_model.h` (API), `components/vector_icons/vector_icons.h.template` (constants) | role-match |
| `chrome/browser/prometheus/prometheus_color_mixer_unittest.cc` | test | transform | `ui/color/color_mixer_unittest.cc` (lines 1–60) | exact |
| `chrome/browser/prometheus/prometheus_css_emission_unittest.cc` | test | request-response | `chrome/browser/ui/color/chrome_color_provider_utils_unittest.cc` (lines 1–17) | role-match |
| `chrome/browser/prometheus/prometheus_asset_resource_unittest.cc` | test | file-I/O | `ui/color/color_mixer_unittest.cc` (structure) | role-match |
| `chrome/browser/prometheus/BUILD.gn` | config | — | `chrome/browser/ui/color/BUILD.gn` lines 19–50 | role-match |
| `third_party/poppins/README.chromium` | config | — | `third_party/test_fonts/README.chromium` (lines 1–9) | exact |
| `third_party/space_mono/README.chromium` | config | — | `third_party/test_fonts/README.chromium` (lines 1–9) | exact |
| `third_party/font_awesome_free/README.chromium` | config | — | `third_party/test_fonts/README.chromium` (lines 1–9) | exact |
| `.planning/chromium/verify-asset-pipeline.sh` | utility | batch | `.planning/chromium/verify-artifact-isolation.sh` + `check-falkon-gpl-guard.sh` | exact |
| `.planning/chromium/convert-fa-icons.sh` | utility | transform | `.planning/chromium/check-falkon-gpl-guard.sh` (shell conventions) | role-match |

---

## Pattern Assignments

---

### `chrome/browser/ui/color/chrome_color_id.h` (config, transform) — MODIFY

**Analog:** `chrome/browser/ui/color/chrome_color_id.h` — the `kColorActorUi*` cluster block (lines 29–36).

**Core pattern** (lines 14–36 of the analog — the `COMMON_CHROME_COLOR_IDS` macro context and the `kColorActorUi*` precedent block):

```cpp
// chrome/browser/ui/color/chrome_color_id.h lines 14-36
// clang-format off
#define COMMON_CHROME_COLOR_IDS \
  /* App menu colors. */ \
  E_CPONLY(kColorAppMenuHighlightSeverityLow, kChromeColorsStart, \
           kChromeColorsStart) \
  ...
  /* Actor UI colors.*/ \
  E_CPONLY(kColorActorUiHandoffButtonBorder) \
  E_CPONLY(kColorActorUiOverlayBorder) \
  E_CPONLY(kColorActorUiOverlayBorderGlow) \
  E_CPONLY(kColorActorUiScrimStart) \
  E_CPONLY(kColorActorUiScrimMiddle) \
  E_CPONLY(kColorActorUiScrimEnd) \
  E_CPONLY(kColorActorUiMagicCursor) \
```

**What to add** — insert this block before `kChromeColorsEnd`, following the same `E_CPONLY` form and comment style as `kColorActorUi*`:

```cpp
  /* Prometheus design system token colors. */ \
  E_CPONLY(kColorPrometheusBgApp) \
  E_CPONLY(kColorPrometheusChrome) \
  E_CPONLY(kColorPrometheusChrome2) \
  E_CPONLY(kColorPrometheusSurface) \
  E_CPONLY(kColorPrometheusSurface2) \
  E_CPONLY(kColorPrometheusSurface3) \
  E_CPONLY(kColorPrometheusTabActive) \
  E_CPONLY(kColorPrometheusTabIdle) \
  E_CPONLY(kColorPrometheusTabHover) \
  E_CPONLY(kColorPrometheusText) \
  E_CPONLY(kColorPrometheusText2) \
  E_CPONLY(kColorPrometheusText3) \
  E_CPONLY(kColorPrometheusBorder) \
  E_CPONLY(kColorPrometheusBorder2) \
  E_CPONLY(kColorPrometheusHairline) \
  E_CPONLY(kColorPrometheusAccent) \
  E_CPONLY(kColorPrometheusAccent2) \
  E_CPONLY(kColorPrometheusAccentSoft) \
  E_CPONLY(kColorPrometheusAccentSoft2) \
  E_CPONLY(kColorPrometheusAccentGlow)
```

CSS emission key: `ConvertColorProviderColorIdToCSSColorId` (verified in `ui/color/color_provider_utils.cc` lines 296–314) strips the leading `k`, then inserts a `-` before each uppercase letter and lowercases it, prepending one more `-` for the leading dash:
- `kColorPrometheusBgApp` → `--color-prometheus-bg-app`
- `kColorPrometheusAccent` → `--color-prometheus-accent`

WebUI must request `chrome://theme/colors.css?sets=chrome` (not `sets=ui`) because the "chrome" set maps `kChromeColorsStart..kChromeColorsEnd` (confirmed `theme_source.cc` line 295).

---

### `chrome/browser/ui/color/prometheus_color_mixer.h` (config, transform) — NEW

**Analog:** `chrome/browser/ui/color/tab_strip_color_mixer.h`

**Pattern** — minimal forward-declaration header:

```cpp
// chrome/browser/ui/color/tab_strip_color_mixer.h (representative; read actual file for exact guards)
#ifndef CHROME_BROWSER_UI_COLOR_TAB_STRIP_COLOR_MIXER_H_
#define CHROME_BROWSER_UI_COLOR_TAB_STRIP_COLOR_MIXER_H_

namespace ui {
class ColorProvider;
struct ColorProviderKey;
}  // namespace ui

void AddTabStripColorMixer(ui::ColorProvider* provider,
                           const ui::ColorProviderKey& key);

#endif  // CHROME_BROWSER_UI_COLOR_TAB_STRIP_COLOR_MIXER_H_
```

Copy the same structure, substituting `AddPrometheusColorMixer` and updating the header guard.

---

### `chrome/browser/ui/color/prometheus_color_mixer.cc` (service, transform) — NEW

**Analog 1:** `chrome/browser/ui/color/tab_strip_color_mixer.cc` — function signature and `dark_mode` flag pattern (lines 1–22).

**Analog 2:** `chrome/browser/ui/color/chrome_color_mixer.cc` — `dark_mode` guard structure, SkColor assignment idiom (lines 1–30).

**Imports pattern** (from `tab_strip_color_mixer.cc` lines 1–18):

```cpp
// Copyright 2022 The Chromium Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "chrome/browser/ui/color/prometheus_color_mixer.h"

#include "chrome/browser/ui/color/chrome_color_id.h"
#include "third_party/skia/include/core/SkColor.h"
#include "ui/color/color_mixer.h"
#include "ui/color/color_provider.h"
#include "ui/color/color_recipe.h"
#include "ui/gfx/color_utils.h"
```

**Core mixer pattern** (from `tab_strip_color_mixer.cc` lines 19–22 for signature, combined with `chrome_color_mixer.cc` dark_mode pattern):

```cpp
void AddPrometheusColorMixer(ui::ColorProvider* provider,
                             const ui::ColorProviderKey& key) {
  const bool dark_mode =
      key.color_mode == ui::ColorProviderKey::ColorMode::kDark;

  ui::ColorMixer& mixer = provider->AddMixer();

  if (dark_mode) {
    // Verbatim hex from styles.css DARK THEME (verified in RESEARCH.md §Code Examples)
    mixer[kColorPrometheusBgApp]      = {SkColorSetRGB(0x0d, 0x0a, 0x09)};
    mixer[kColorPrometheusChrome]     = {SkColorSetRGB(0x1d, 0x18, 0x16)};
    mixer[kColorPrometheusChrome2]    = {SkColorSetRGB(0x18, 0x13, 0x11)};
    mixer[kColorPrometheusSurface]    = {SkColorSetRGB(0x14, 0x11, 0x10)};
    mixer[kColorPrometheusSurface2]   = {SkColorSetRGB(0x1d, 0x18, 0x16)};
    mixer[kColorPrometheusSurface3]   = {SkColorSetRGB(0x26, 0x20, 0x1d)};
    mixer[kColorPrometheusTabActive]  = {SkColorSetRGB(0x2a, 0x22, 0x1e)};
    mixer[kColorPrometheusTabIdle]    = {SK_ColorTRANSPARENT};
    mixer[kColorPrometheusTabHover]   = {SkColorSetARGB(15,  0xff, 0xf1, 0xe8)};
    mixer[kColorPrometheusText]       = {SkColorSetRGB(0xf6, 0xef, 0xe9)};
    mixer[kColorPrometheusText2]      = {SkColorSetRGB(0xd2, 0xc1, 0xb4)};
    mixer[kColorPrometheusText3]      = {SkColorSetRGB(0xa9, 0x92, 0x83)};
    mixer[kColorPrometheusBorder]     = {SkColorSetARGB(25,  0xff, 0xf1, 0xe8)};
    mixer[kColorPrometheusBorder2]    = {SkColorSetARGB(45,  0xff, 0xf1, 0xe8)};
    mixer[kColorPrometheusHairline]   = {SkColorSetARGB(15,  0xff, 0xf1, 0xe8)};
  } else {
    // LIGHT THEME
    mixer[kColorPrometheusBgApp]      = {SkColorSetRGB(0xe9, 0xe2, 0xda)};
    mixer[kColorPrometheusChrome]     = {SkColorSetRGB(0xf3, 0xed, 0xe6)};
    mixer[kColorPrometheusChrome2]    = {SkColorSetRGB(0xec, 0xe4, 0xdb)};
    mixer[kColorPrometheusSurface]    = {SkColorSetRGB(0xff, 0xfd, 0xfb)};
    mixer[kColorPrometheusSurface2]   = {SkColorSetRGB(0xf8, 0xf4, 0xef)};
    mixer[kColorPrometheusSurface3]   = {SkColorSetRGB(0xf1, 0xeb, 0xe4)};
    mixer[kColorPrometheusTabActive]  = {SkColorSetRGB(0xff, 0xfd, 0xfb)};
    mixer[kColorPrometheusTabIdle]    = {SK_ColorTRANSPARENT};
    mixer[kColorPrometheusTabHover]   = {SkColorSetARGB(12,  0x29, 0x1d, 0x14)};
    mixer[kColorPrometheusText]       = {SkColorSetRGB(0x1f, 0x1a, 0x17)};
    mixer[kColorPrometheusText2]      = {SkColorSetRGB(0x6a, 0x58, 0x4d)};
    mixer[kColorPrometheusText3]      = {SkColorSetRGB(0x8d, 0x7a, 0x6e)};
    mixer[kColorPrometheusBorder]     = {SkColorSetARGB(25,  0x29, 0x1d, 0x14)};
    mixer[kColorPrometheusBorder2]    = {SkColorSetARGB(40,  0x29, 0x1d, 0x14)};
    mixer[kColorPrometheusHairline]   = {SkColorSetARGB(20,  0x29, 0x1d, 0x14)};
  }

  // Accent (same both themes; default FSB Orange — pref wiring deferred to Phase 16)
  mixer[kColorPrometheusAccent]     = {SkColorSetRGB(0xff, 0x6b, 0x35)};
  mixer[kColorPrometheusAccent2]    = {SkColorSetRGB(0xff, 0x8c, 0x42)};
  // accent-soft derivations: color-mix(accent 12/18/24%, transparent)
  // C++ approximation: SkColorSetARGB(alpha, r, g, b) where alpha = pct * 255
  mixer[kColorPrometheusAccentSoft] = {SkColorSetARGB(30,  0xff, 0x6b, 0x35)}; // 12%
  mixer[kColorPrometheusAccentSoft2]= {SkColorSetARGB(45,  0xff, 0x6b, 0x35)}; // 18%
  mixer[kColorPrometheusAccentGlow] = {SkColorSetARGB(61,  0xff, 0x6b, 0x35)}; // 24%
}
```

Hex values are verbatim from `styles.css` as documented in RESEARCH.md §Code Examples. rgba tokens use `SkColorSetARGB`; see Pitfall 1 (8-bit alpha rounding).

---

### `chrome/browser/ui/color/chrome_color_mixers.cc` (config, transform) — MODIFY

**Analog:** self — `AddChromeColorMixers()` body (lines 57–86).

**Registration pattern** (lines 57–86, confirmed):

```cpp
// chrome/browser/ui/color/chrome_color_mixers.cc lines 57-86
void AddChromeColorMixers(ui::ColorProvider* provider,
                          const ui::ColorProviderKey& key) {
  // ... existing mixer calls ...
  AddTabStripColorMixer(provider, key);
  AddMaterialChromeColorMixer(provider, key);
  // ...
  // Must be the last one in order to override other mixer colors.
  AddNativeChromeColorMixer(provider, key);

  // ADD: Prometheus mixer runs AFTER AddNativeChromeColorMixer
  // so it overrides GM3/Material defaults wholesale (D-04).
  AddPrometheusColorMixer(provider, key);  // <-- NEW LINE

  if (key.custom_theme) {
    key.custom_theme->AddColorMixers(provider, key);
  }
  if (key.app_controller) {
    key.app_controller->AddColorMixers(provider, key);
  }
}
```

Also add `#include "chrome/browser/ui/color/prometheus_color_mixer.h"` to the include block at the top, following the alphabetical ordering of existing mixer includes (lines 14–26).

---

### `chrome/browser/ui/color/BUILD.gn` (config) — MODIFY

**Analog:** self — `source_set("mixers")` (lines 19–50).

**Pattern** — add `prometheus_color_mixer.cc` and `prometheus_color_mixer.h` to the `sources` list inside `source_set("mixers")`:

```gn
# chrome/browser/ui/color/BUILD.gn — source_set("mixers") lines 19-50
source_set("mixers") {
  sources = [
    "chrome_color_mixer.cc",
    "chrome_color_mixer.h",
    "chrome_color_mixers.cc",
    "chrome_color_mixers.h",
    # ... existing entries ...
    "prometheus_color_mixer.cc",   # <-- NEW
    "prometheus_color_mixer.h",    # <-- NEW
    "tab_strip_color_mixer.cc",
    "tab_strip_color_mixer.h",
  ]
  # deps, configs unchanged
}
```

---

### `chrome/browser/resources/prometheus/css/prometheus_fonts.css` (utility, request-response) — NEW

**Analog:** `ui/webui/resources/css/roboto.css` (lines 1–27).

**Full analog** (lines 1–27 verbatim):

```css
/* Copyright 2015 The Chromium Authors
 * Use of this source code is governed by a BSD-style license that can be
 * found in the LICENSE file. */

@font-face {
  font-family: 'Roboto';
  font-style: normal;
  font-weight: 400;
  src: local('Roboto'), local('Roboto-Regular'),
      url(//resources/roboto/roboto-regular.woff2) format('woff2');
}
/* ... two more weights */
```

**What to replicate** (four Poppins weights + Space Mono, no `local()` fallback — D-11 forbids CDN/local system font fallback):

```css
/* Copyright 2026 The Chromium Authors ... */

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
@font-face {
  font-family: 'Poppins';
  font-style: normal;
  font-weight: 800;
  src: url(//resources/prometheus/fonts/Poppins-ExtraBold.woff2) format('woff2');
}
@font-face {
  font-family: 'Poppins';
  font-style: normal;
  font-weight: 900;
  src: url(//resources/prometheus/fonts/Poppins-Black.woff2) format('woff2');
}
@font-face {
  font-family: 'Space Mono';
  font-style: normal;
  font-weight: 400;
  src: url(//resources/prometheus/fonts/SpaceMono-Regular.woff2) format('woff2');
}
```

URL scheme: `//resources/prometheus/fonts/…` mirrors `//resources/roboto/…` in the Roboto analog. No `local()` hints — offline requirement is absolute (DESIGN-03).

**BUILD.gn pattern** (from `ui/webui/resources/css/BUILD.gn` lines 1–42):

```gn
# Prometheus CSS resources BUILD.gn — mirrors ui/webui/resources/css/BUILD.gn
import("//tools/grit/preprocess_if_expr.gni")
import("//ui/webui/resources/tools/generate_grd.gni")

generate_grd("build_grdp") {
  grd_prefix = "prometheus_css"
  out_grd = "$target_gen_dir/resources.grdp"
  public_deps = [ ":preprocess" ]
  manifest_files = [ "$target_gen_dir/$preprocess_manifest" ]
  resource_path_prefix = "css"
}

preprocess_if_expr("preprocess") {
  in_folder = "."
  out_folder = "$target_gen_dir/preprocessed"
  out_manifest = "$target_gen_dir/$preprocess_manifest"
  in_files = [ "prometheus_fonts.css" ]
}
```

---

### `.icon` files (69 glyphs) under `chrome/browser/resources/prometheus/vector_icons/` (utility, transform) — NEW

**Analog:** `components/vector_icons/add_2.icon` (lines 1–32 verbatim).

**Full analog** (add_2.icon lines 1–32):

```
// Copyright 2026 The Chromium Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

CANVAS_DIMENSIONS, 16,
FILL_RULE_NONZERO,
MOVE_TO, 7.51f, 13.54f,
R_ARC_TO, 0.66f, 0.66f, 0, 0, 1, -0.2f, -0.49f,
V_LINE_TO, 8.7f,
H_LINE_TO, 2.96f,
R_ARC_TO, 0.67f, 0.67f, 0, 0, 1, -0.49f, -0.2f,
...
CLOSE
```

**What each Prometheus `.icon` file must contain:**

1. Standard Chromium copyright header (3 lines).
2. An injected provenance comment block (D-07): source FA glyph name + CC BY 4.0 attribution.
3. `CANVAS_DIMENSIONS, 20,` (FA Free SVGs are 512x512, normalize to 20dp via skiafy).
4. Path commands produced by skiafy from the SVGO-optimized FA SVG.

**Provenance header pattern** (required by D-07, injected by `convert-fa-icons.sh`):

```
// Copyright 2026 The Chromium Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
// Source: Font Awesome Free 6.x — fa-bolt (solid)
// License: CC BY 4.0 (https://creativecommons.org/licenses/by/4.0/)

CANVAS_DIMENSIONS, 20,
FILL_RULE_NONZERO,
MOVE_TO, ...
```

Path commands come verbatim from skiafy output. CANVAS_DIMENSIONS value must match the `viewBox` dimension skiafy normalizes to.

---

### `prometheus_vector_icons` GN target in `chrome/browser/resources/prometheus/BUILD.gn` (config) — NEW

**Analog:** `components/vector_icons/BUILD.gn` lines 1–60 and `components/vector_icons/vector_icons.gni` (lines 1–73 verbatim).

**GNI template** (`vector_icons.gni` lines 24–73, key parameters):

```gni
# components/vector_icons/vector_icons.gni lines 24-73
template("aggregate_vector_icons") {
  assert(defined(invoker.sources), ...)
  assert(defined(invoker.icon_directory), ...)

  action(target_name) {
    script = "//components/vector_icons/aggregate_vector_icons.py"
    output_cc = "$target_gen_dir/vector_icons.cc"
    output_h  = "$target_gen_dir/vector_icons.h"
    templates = ["vector_icons.cc.template", "vector_icons.h.template"]
    inputs = rebase_path(templates + invoker.sources, ".", invoker.icon_directory)
             + [ "//components/vector_icons/aggregate_vector_icons.py" ]
    outputs = [ output_cc, output_h ]
    response_file_contents =
        rebase_path(invoker.sources, root_build_dir, invoker.icon_directory)
    args = [
      "--working_directory=" +
          rebase_path(invoker.icon_directory, root_build_dir),
      "--file_list={{response_file_name}}",
      "--output_cc=" + rebase_path(output_cc, root_build_dir),
      "--output_h=" + rebase_path(output_h, root_build_dir),
    ]
  }
}
```

**What to write** in `chrome/browser/resources/prometheus/BUILD.gn` (modeled on `components/vector_icons/BUILD.gn` lines 1–15):

```gn
import("//components/vector_icons/vector_icons.gni")

aggregate_vector_icons("prometheus_vector_icons") {
  icon_directory = "vector_icons"

  sources = [
    "fa_arrow_down.icon",
    "fa_bolt.icon",
    "fa_book_open.icon",
    "fa_compass.icon",
    "fa_highlighter.icon",
    "fa_layer_group.icon",
    "fa_sidebar_flip.icon",        # bundled placeholder (Pro-only)
    "fa_wand_magic_sparkles.icon",
    # ... all 69 glyphs
  ]
}
```

**Critical:** `vector_icons.cc.template` and `vector_icons.h.template` must be present inside `vector_icons/` alongside the `.icon` files. Copy them verbatim from `components/vector_icons/` — the template path resolution in `vector_icons.gni` (line 47: `rebase_path(templates + invoker.sources, ".", invoker.icon_directory)`) requires this.

---

### `chrome/browser/ui/webui/prometheus/prometheus_theme_preview_ui.cc` (controller, request-response) — NEW

**Analog:** `chrome/browser/ui/webui/internals/internals_ui.cc` (lines 1–65 verbatim).

**Full analog** (lines 1–65):

```cpp
// chrome/browser/ui/webui/internals/internals_ui.cc lines 1-65
#include "chrome/browser/ui/webui/internals/internals_ui.h"
#include "chrome/browser/profiles/profile.h"
#include "chrome/common/url_constants.h"
#include "content/public/browser/web_ui.h"
#include "content/public/browser/web_ui_controller.h"
#include "content/public/browser/web_ui_data_source.h"
#include "ui/webui/webui_util.h"

InternalsUIConfig::InternalsUIConfig()
    : DefaultWebUIConfig(content::kChromeUIScheme,
                         chrome::kChromeUIInternalsHost) {}

InternalsUI::InternalsUI(content::WebUI* web_ui)
    : content::WebUIController(web_ui) {
  auto* profile = Profile::FromWebUI(web_ui);
  auto* source = content::WebUIDataSource::CreateAndAdd(
      profile, chrome::kChromeUIInternalsHost);
  // optional: SetRequestFilter, AddResourcePath, UseStringsJs, etc.
}

InternalsUI::~InternalsUI() = default;

WEB_UI_CONTROLLER_TYPE_IMPL(InternalsUI)
```

**What to replicate** as `PrometheusThemePreviewUI`:

```cpp
// PrometheusThemePreviewUIConfig (in prometheus_theme_preview_ui.cc or .h)
class PrometheusThemePreviewUIConfig
    : public DefaultWebUIConfig<PrometheusThemePreviewUI> {
 public:
  PrometheusThemePreviewUIConfig()
      : DefaultWebUIConfig(content::kChromeUIScheme,
                           "prometheus-theme-preview") {}
};

// PrometheusThemePreviewUI constructor
PrometheusThemePreviewUI::PrometheusThemePreviewUI(content::WebUI* web_ui)
    : content::WebUIController(web_ui) {
  auto* profile = Profile::FromWebUI(web_ui);
  auto* source = content::WebUIDataSource::CreateAndAdd(
      profile, "prometheus-theme-preview");
  // Add GRIT resource paths for the token gallery HTML/JS/CSS
  webui::SetupWebUIDataSource(source, ...);
}

PrometheusThemePreviewUI::~PrometheusThemePreviewUI() = default;

WEB_UI_CONTROLLER_TYPE_IMPL(PrometheusThemePreviewUI)
```

The host name `"prometheus-theme-preview"` is at Claude's discretion per CONTEXT.md.

---

### `chrome/browser/ui/webui/chrome_web_ui_configs.cc` (config) — MODIFY

**Analog:** self — `RegisterChromeWebUIConfigs()` (lines 245–274).

**Registration pattern** (lines 252–261 extract):

```cpp
// chrome/browser/ui/webui/chrome_web_ui_configs.cc lines 252-261
void RegisterChromeWebUIConfigs() {
  auto& map = content::WebUIConfigMap::GetInstance();
  map.AddWebUIConfig(std::make_unique<AccessibilityUIConfig>());
  map.AddWebUIConfig(std::make_unique<AutofillInternalsUIConfig>());
  // ...
}
```

**What to add:**

```cpp
// Add near other dev/internals configs (alphabetical by class name):
#include "chrome/browser/ui/webui/prometheus/prometheus_theme_preview_ui.h"
// ...
map.AddWebUIConfig(std::make_unique<PrometheusThemePreviewUIConfig>());
```

If the page must be dev-only in release builds, wrap in `#if DCHECK_IS_ON()` or a `prometheus_dev` buildflag.

---

### `chrome/browser/prometheus/prometheus_action.h` (utility, transform) — NEW

**Analog:** `ui/base/models/image_model.h` (ImageModel::FromVectorIcon API) + `components/vector_icons/vector_icons.h.template` (constant form).

**Pattern for Views resolver** (combining the two analogs):

```cpp
// prometheus_action.h
#include "base/containers/flat_map.h"
#include "chrome/browser/ui/color/chrome_color_id.h"   // kColorPrometheusAccent
#include "ui/base/models/image_model.h"                  // ImageModel::FromVectorIcon
#include "ui/gfx/vector_icon_types.h"                    // gfx::VectorIcon

enum class PrometheusAction {
  kDownload,     // arrow-down (substitution for arrow-down-to-line, FA Free missing)
  kBolt,
  kCompass,
  kLayerGroup,
  kWandMagicSparkles,
  kBookOpen,
  kHighlighter,
  kSidebarFlip,  // bundled placeholder (sidebar-flip is Pro-only)
  // ... all 69 semantic actions
};

// Views resolver: maps PrometheusAction -> gfx::VectorIcon*
// Call site: ui::ImageModel::FromVectorIcon(*icon, kColorPrometheusAccent, size)
const base::flat_map<PrometheusAction, const gfx::VectorIcon*>&
GetPrometheusActionIconMap();

// WebUI resolver: maps PrometheusAction -> FA SVG resource path
const char* GetPrometheusActionSvgPath(PrometheusAction action);
```

`ImageModel::FromVectorIcon` call site pattern (from `ui/base/models/image_model.h`):

```cpp
// Views icon usage (at call site, e.g. in Phase 15 toolbar button):
ui::ImageModel::FromVectorIcon(
    *GetPrometheusActionIconMap().at(PrometheusAction::kBolt),
    kColorPrometheusAccent,   // color applied as ColorId, not baked into asset
    /*icon_size=*/16);
```

---

### `chrome/browser/prometheus/prometheus_color_mixer_unittest.cc` (test, transform) — NEW

**Analog:** `ui/color/color_mixer_unittest.cc` (lines 1–60).

**Test structure** (lines 1–60 verbatim):

```cpp
// ui/color/color_mixer_unittest.cc lines 1-33
#include "ui/color/color_mixer.h"
#include "base/functional/bind.h"
#include "base/functional/callback.h"
#include "testing/gtest/include/gtest/gtest.h"
#include "ui/color/color_recipe.h"
#include "ui/color/color_test_ids.h"

namespace ui { namespace {

TEST(ColorMixerTest, AccessOperator) {
  ColorMixer mixer;
  mixer[kColorTest0] = {SK_ColorGREEN};
  EXPECT_EQ(SK_ColorGREEN, mixer.GetResultColor(kColorTest0));
}
```

**What to replicate** for `prometheus_color_mixer_unittest.cc`:

```cpp
#include "chrome/browser/ui/color/prometheus_color_mixer.h"
#include "chrome/browser/ui/color/chrome_color_id.h"
#include "testing/gtest/include/gtest/gtest.h"
#include "ui/color/color_provider.h"
#include "ui/color/color_provider_key.h"

// Test dark mode token resolution (DESIGN-01)
TEST(PrometheusColorMixerTest, DarkModeAccentResolvesToFsbOrange) {
  ui::ColorProviderKey key;
  key.color_mode = ui::ColorProviderKey::ColorMode::kDark;
  ui::ColorProvider provider;
  AddPrometheusColorMixer(&provider, key);
  EXPECT_EQ(SkColorSetRGB(0xff, 0x6b, 0x35),
            provider.GetColor(kColorPrometheusAccent));
}

// Test light mode bg token (DESIGN-01)
TEST(PrometheusColorMixerTest, LightModeBgAppToken) {
  ui::ColorProviderKey key;
  key.color_mode = ui::ColorProviderKey::ColorMode::kLight;
  ui::ColorProvider provider;
  AddPrometheusColorMixer(&provider, key);
  EXPECT_EQ(SkColorSetRGB(0xe9, 0xe2, 0xda),
            provider.GetColor(kColorPrometheusBgApp));
}
```

---

### `chrome/browser/prometheus/prometheus_css_emission_unittest.cc` (test, request-response) — NEW

**Analog:** `chrome/browser/ui/color/chrome_color_provider_utils_unittest.cc` (lines 1–17).

**Full analog** (lines 1–17):

```cpp
// chrome/browser/ui/color/chrome_color_provider_utils_unittest.cc lines 1-17
#include "chrome_color_provider_utils.h"
#include "base/test/gtest_util.h"
#include "chrome/browser/ui/color/chrome_color_id.h"
#include "testing/gtest/include/gtest/gtest.h"
#include "ui/color/color_id.h"

using ChromeColorProviderUtilsTest = ::testing::Test;

TEST_F(ChromeColorProviderUtilsTest, ChromeColorIdNameTest) {
  EXPECT_EQ("kColorToolbarBackgroundSubtleEmphasis",
            ChromeColorIdName(kColorToolbarBackgroundSubtleEmphasis));
}
```

**What to replicate** for CSS property emission test (DESIGN-01 + DESIGN-06):

```cpp
// prometheus_css_emission_unittest.cc
#include "chrome/browser/ui/color/chrome_color_provider_utils.h"
#include "chrome/browser/ui/color/chrome_color_id.h"
#include "testing/gtest/include/gtest/gtest.h"
#include "ui/color/color_provider_utils.h"

TEST(PrometheusColorCssEmissionTest, AccentIdHasCorrectCssName) {
  // ChromeColorIdName returns "kColorPrometheusAccent"
  // ConvertColorProviderColorIdToCSSColorId converts that to "--color-prometheus-accent"
  EXPECT_EQ("--color-prometheus-accent",
            ui::ConvertColorProviderColorIdToCSSColorId(
                ChromeColorIdName(kColorPrometheusAccent)));
}

TEST(PrometheusColorCssEmissionTest, BgAppIdHasCorrectCssName) {
  EXPECT_EQ("--color-prometheus-bg-app",
            ui::ConvertColorProviderColorIdToCSSColorId(
                ChromeColorIdName(kColorPrometheusBgApp)));
}
```

---

### Views Token Gallery (new file, modeled on `ui/views/examples/colors_example.cc`) — NEW

**Analog:** `ui/views/examples/colors_example.cc` (lines 1–199).

**Core excerpt — `InsertColorRow` helper** (lines 39–60):

```cpp
// ui/views/examples/colors_example.cc lines 39-60
void InsertColorRow(View* parent,
                    std::u16string_view label_string,
                    ui::ColorId color_id) {
  auto* label_view = parent->AddChildView(
      std::make_unique<Label>(std::u16string(label_string)));
  label_view->SetHorizontalAlignment(gfx::HorizontalAlignment::ALIGN_LEFT);

  auto* color_view = parent->AddChildView(std::make_unique<Label>());
  auto background_color = color_view->GetColorProvider()->GetColor(color_id);
  // ... format hex string, set background ...
}
```

**`OnThemeChanged` live-rebuild pattern** (lines 177–181):

```cpp
// ui/views/examples/colors_example.cc lines 177-181
void OnThemeChanged() override {
  ScrollView::OnThemeChanged();
  CreateAllColorsView(this);  // rebuild all rows with fresh colors
}
```

**What to replicate** for `prometheus_token_gallery_view.cc`:

```cpp
// prometheus_token_gallery_view.cc — subclass ScrollView, enumerate kColorPrometheus* ids
void CreatePrometheusColorsView(ScrollView* scroll_view) {
  auto* container = scroll_view->SetContents(std::make_unique<View>());
  // TableLayout with 2 columns: label + swatch
  InsertColorRow(container, u"kColorPrometheusBgApp",    kColorPrometheusBgApp);
  InsertColorRow(container, u"kColorPrometheusChrome",   kColorPrometheusChrome);
  InsertColorRow(container, u"kColorPrometheusAccent",   kColorPrometheusAccent);
  // ... all 20 kColorPrometheus* ids
}

void OnThemeChanged() override {
  ScrollView::OnThemeChanged();
  CreatePrometheusColorsView(this);  // live dark/light toggle proof (D-13)
}
```

---

### `third_party/{poppins,space_mono,font_awesome_free}/README.chromium` (config) — NEW

**Analog:** `third_party/test_fonts/README.chromium` (lines 1–9 — the field schema).

**Full analog** (lines 1–9):

```
Name: test_fonts
URL: https://pagure.io/lohit, ...
Version: N/A
Revision: DEPS
Update Mechanism: Manual
License: OFL-1.1, GPL-2.0, ...
License File: LICENSE
Security Critical: no
Shipped: no
```

**What to write** for `third_party/poppins/README.chromium`:

```
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

For `third_party/space_mono/README.chromium`: same schema, `Name: Space Mono`, `URL: https://github.com/googlefonts/spacemono`, `License: OFL-1.1`.

For `third_party/font_awesome_free/README.chromium`: `Name: Font Awesome Free`, `URL: https://github.com/FortAwesome/Font-Awesome`, `License: CC-BY-4.0` (icons), `License File: LICENSE`.

---

### Native Views Font Shim (as-needed, within Phase 14 Views label code) (utility, file-I/O) — NEW (as-needed)

**Analog:** `ui/gfx/platform_font_mac.h` lines 45–50.

**Constructor signature** (lines 45–50):

```cpp
// ui/gfx/platform_font_mac.h lines 45-50
// Constructs a PlatformFontMac representing the font specified by |typeface|
// and the size |font_size_pixels|.
PlatformFontMac(sk_sp<SkTypeface> typeface,
                int font_size_pixels,
                const std::optional<FontRenderParams>& params);
```

**Usage pattern** (D-11 shim):

```cpp
// As-needed when a native Views label needs Poppins/Space Mono before Phase 15/16
auto bytes = ui::ResourceBundle::GetSharedInstance()
    .GetRawDataResource(IDR_PROMETHEUS_FONT_SPACE_MONO_TTF);
auto stream = SkMemoryStream::MakeDirect(bytes.data(), bytes.size());
sk_sp<SkTypeface> tf = SkTypeface::MakeFromStream(std::move(stream));
auto* font = new gfx::PlatformFontMac(tf, font_size_pixels, std::nullopt);
```

TTF files must be declared in the Prometheus GRD with `IDR_PROMETHEUS_FONT_*` constants. Shim is NOT used for WebUI (which uses woff2 + @font-face).

---

### Theme Switching (no new files — reuse existing pref)

**Analog:** `chrome/browser/themes/theme_service.h` lines 60–70 + `chrome/common/pref_names.h` line 694.

**`BrowserColorScheme` enum** (lines 60–70):

```cpp
// chrome/browser/themes/theme_service.h lines 64-70
enum class BrowserColorScheme {
  kSystem = 0,
  kLight = 1,
  kDark = 2,
};
```

**Pref string** (`chrome/common/pref_names.h` line 694):

```cpp
inline constexpr char kBrowserColorScheme[] = "browser.theme.color_scheme2";
```

D-03: The v1 explicit theme toggle writes `kLight`/`kDark` to `prefs::kBrowserColorScheme`. Default is `kSystem` (follow OS dark mode). The Prometheus mixer reads `key.color_mode` which is populated by this pref. No new pref or switching machinery needed in Phase 14.

---

### `.planning/chromium/verify-asset-pipeline.sh` (utility, batch) — NEW

**Analog:** `.planning/chromium/verify-artifact-isolation.sh` (lines 1–86) + `check-falkon-gpl-guard.sh` (lines 1–76).

**Shell conventions** (from `verify-artifact-isolation.sh` lines 1–14 and `check-falkon-gpl-guard.sh` lines 1–25):

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
cd "${PROJECT_ROOT}"

CHROMIUM_SRC="${PROJECT_ROOT}/.context/chromium/src"

fail() {
  printf 'asset pipeline check failed: %s\n' "$1" >&2
  exit 1
}
```

**Pattern for each assertion** (from `verify-artifact-isolation.sh` lines 18–28 `grep -qF` / file-exists pattern):

```bash
# Assertion 1: asset present and non-zero
[ -s "${CHROMIUM_SRC}/third_party/poppins/Poppins-Thin.woff2" ] \
  || fail "Poppins Thin woff2 missing or empty"

# Assertion 3: README.chromium per third_party dir
[ -f "${CHROMIUM_SRC}/third_party/poppins/README.chromium" ] \
  || fail "third_party/poppins/README.chromium missing"

# Assertion 4: CC BY 4.0 comment in every FA SVG
for svg in "${CHROMIUM_SRC}/chrome/browser/resources/prometheus/svg"/fa_*.svg; do
  grep -q "CC BY 4.0\|Font Awesome Free" "${svg}" \
    || fail "CC BY 4.0 attribution missing from ${svg}"
done

# Assertion 5: no remote URLs in bundled CSS/HTML/SVG
grep -rn 'https://\|http://\|fonts\.googleapis\.com' \
  "${CHROMIUM_SRC}/chrome/browser/resources/prometheus/" \
  && fail "Remote URL found in bundled Prometheus resources"

# Assertion 6: NOTICES.md sections present
grep -q "Font Awesome" "${PROJECT_ROOT}/NOTICES.md" \
  || fail "Font Awesome section missing from NOTICES.md"
```

From `check-falkon-gpl-guard.sh` lines 59–73: iterate a patterns array, grep, track failure, print clear messages.

---

### `.planning/chromium/convert-fa-icons.sh` (utility, transform) — NEW

**Analog:** `.planning/chromium/check-falkon-gpl-guard.sh` (lines 1–76) for shell conventions.

**Shell preamble** (same as other gate scripts):

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
cd "${PROJECT_ROOT}"

FA_SOURCE_DIR="${PROJECT_ROOT}/.context/falkon-preservation/falkon/src/lib/data/icons/fa"
ICON_OUT_DIR="${PROJECT_ROOT}/.context/chromium/src/chrome/browser/resources/prometheus/vector_icons"

fail() {
  printf 'FA icon conversion failed: %s\n' "$1" >&2
  exit 1
}
```

**Core loop pattern** (modeled on `check-falkon-gpl-guard.sh` lines 59–73):

```bash
for svg in "${FA_SOURCE_DIR}"/*.svg; do
  glyph_name="$(basename "${svg}" .svg)"
  icon_name="fa_${glyph_name//-/_}.icon"

  # 1. Optimize with SVGO (preserve comments for CC BY 4.0)
  svgo --config=svgo-no-strip-comments.json "${svg}" -o "/tmp/${glyph_name}.svg" \
    || fail "SVGO failed for ${glyph_name}"

  # 2. Convert to .icon path commands with skiafy
  skiafy "/tmp/${glyph_name}.svg" -o "/tmp/${icon_name}.raw" \
    || fail "skiafy failed for ${glyph_name}"

  # 3. Inject provenance header
  cat > "${ICON_OUT_DIR}/${icon_name}" <<HEADER
// Copyright 2026 The Chromium Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
// Source: Font Awesome Free 6.x -- ${glyph_name} (solid)
// License: CC BY 4.0 (https://creativecommons.org/licenses/by/4.0/)

HEADER
  cat "/tmp/${icon_name}.raw" >> "${ICON_OUT_DIR}/${icon_name}"
done
```

Substitutions to apply before conversion (D-08): skip `arrow-down-to-line` (not in FA Free 6 solid); convert `arrow-down` instead; include `sidebar-flip.icon` as a hand-authored placeholder.

---

## Shared Patterns

### Dark/Light Mode Selection
**Source:** `chrome/browser/ui/color/tab_strip_color_mixer.cc` lines 19–22 + `chrome/browser/ui/color/chrome_color_mixer.cc` lines conceptually.
**Apply to:** `prometheus_color_mixer.cc`, any future Prometheus mixer extensions.

```cpp
const bool dark_mode =
    key.color_mode == ui::ColorProviderKey::ColorMode::kDark;
```

### SkColor Hex Literals
**Source:** mixer convention across all `chrome/browser/ui/color/` mixer files.
**Apply to:** `prometheus_color_mixer.cc` for all 20 token assignments.

```cpp
// Opaque color:
mixer[kColorPrometheusAccent] = {SkColorSetRGB(0xff, 0x6b, 0x35)};
// Transparent/alpha color:
mixer[kColorPrometheusTabHover] = {SkColorSetARGB(15, 0xff, 0xf1, 0xe8)};
// Fully transparent:
mixer[kColorPrometheusTabIdle] = {SK_ColorTRANSPARENT};
```

### CSS Custom Property Auto-Emission
**Source:** `ui/color/color_provider_utils.cc` lines 296–314 (`ConvertColorProviderColorIdToCSSColorId`) + `chrome/browser/ui/webui/theme_source.cc` lines 295–296 (`chrome` set definition).
**Apply to:** All `kColorPrometheus*` ids — no action needed beyond declaring them inside `COMMON_CHROME_COLOR_IDS`. The machinery auto-emits `--color-prometheus-*` when WebUI requests `chrome://theme/colors.css?sets=chrome`.

```cpp
// ui/color/color_provider_utils.cc lines 296-314
std::string ConvertColorProviderColorIdToCSSColorId(
    std::string_view color_id_name) {
  // Prepend '-', insert '-' before each uppercase, lowercase it.
  // kColorPrometheusAccent -> --color-prometheus-accent
  ...
}
```

### Shell Gate Script Convention
**Source:** `.planning/chromium/verify-artifact-isolation.sh` lines 1–14 + `check-falkon-gpl-guard.sh` lines 1–25.
**Apply to:** `verify-asset-pipeline.sh`, `convert-fa-icons.sh`.

```bash
#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
cd "${PROJECT_ROOT}"
fail() { printf 'check failed: %s\n' "$1" >&2; exit 1; }
```

### WebUI Config Registration
**Source:** `chrome/browser/ui/webui/chrome_web_ui_configs.cc` lines 245–274.
**Apply to:** `PrometheusThemePreviewUIConfig` registration.

```cpp
auto& map = content::WebUIConfigMap::GetInstance();
map.AddWebUIConfig(std::make_unique<PrometheusThemePreviewUIConfig>());
```

### GTest Test Structure
**Source:** `ui/color/color_mixer_unittest.cc` lines 1–60 (framework), `chrome/browser/ui/color/chrome_color_provider_utils_unittest.cc` lines 1–17 (Chrome-layer pattern).
**Apply to:** All three `prometheus_*_unittest.cc` files.

---

## No Analog Found

All files in this phase have close in-tree analogs. No entries.

---

## Metadata

**Analog search scope:** `.context/chromium/src/chrome/browser/ui/color/`, `ui/color/`, `ui/views/examples/`, `chrome/browser/ui/webui/`, `components/vector_icons/`, `ui/webui/resources/css/`, `ui/gfx/`, `chrome/browser/themes/`, `third_party/test_fonts/`, `.planning/chromium/`
**Files scanned:** 22 analog files read
**Pattern extraction date:** 2026-06-24
