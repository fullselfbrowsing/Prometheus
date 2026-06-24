# Phase 14: Asset and Design System Port - Context

**Gathered:** 2026-06-24
**Status:** Ready for planning
**Mode:** Advisor discuss (research-backed) — 4 gray areas, each researched before locking

<domain>
## Phase Boundary

Port the canonical warm design system into Chromium so it is available to **both**
Chromium native Views **and** WebUI — token sets (warm dark + warm light), Poppins
and Space Mono fonts, the Font Awesome Free icon subset, the PM monogram /
Prometheus wordmark / FSB logo brand assets, and the visual-state rules — with
attribution intact and zero network dependency. This is the design **foundation**
that Phase 15 (compact chrome / tab model, native Views) and Phase 16 (WebUI
surfaces: start page, side panel, FSB control panel) consume.

In scope for this phase:
- A single Prometheus color pipeline (one C++ color mixer) feeding Views and WebUI.
- Bundled Poppins + Space Mono fonts and the full Font Awesome Free icon subset as
  Chromium resources, with license metadata and a validation gate.
- PM / wordmark / FSB brand assets as Chromium resources for dark/light contexts.
- A Prometheus action→icon resolver spanning both surfaces.
- A throwaway verification surface + automated tests proving tokens/fonts/icons/states render.

Explicitly NOT in this phase (owned later):
- The compact browser chrome / tab-strip Views that consume these tokens/icons → Phase 15.
- The themed WebUI surfaces (start page, side panel, FSB control panel, themed About) → Phase 16.
- The accent swatch-picker UI and other tweaks (side-panel side, tab density) → Phase 16 / 20.
- Packaged-notice validation, app-icon-in-package, OFL-in-about checks → Phase 24.
- Product-layout / responsive carried-forward visual checks → their later owner phases.

</domain>

<decisions>
## Implementation Decisions

### Area 1 — Token pipeline (Views + WebUI)
- **D-01:** Use a **single Chromium-idiomatic color mixer** as the one source of
  truth. Add `kColorPrometheus*` color ids in the `kChromeColorsStart` block of
  `chrome/browser/ui/color/chrome_color_id.h`; assign dark/light values in a new
  `prometheus_color_mixer.cc` registered via `AddChromeColorMixers`
  (`chrome/browser/ui/color/chrome_color_mixers.cc`). Native Views reads
  `ColorProvider->GetColor(kColorPrometheus*)`; WebUI consumes the **auto-emitted**
  `--color-prometheus-*` custom properties from `chrome://theme/colors.css` (the
  `color_change_listener` / `ColorChangeHandler` pipeline). The CSS is *generated*
  from the C++ values, so the two surface families cannot drift (satisfies
  DESIGN-06). Precedent: the in-tree `kColorActorUi*` agent-UI cluster does exactly this.
- **D-02:** Define the token family to mirror the canonical `styles.css` set:
  `bg-app, chrome, chrome-2, surface, surface-2, surface-3, tab-active, tab-idle,
  tab-hover, text, text-2, text-3, border, border-2, hairline, accent, accent-2,
  accent-soft, accent-soft-2, accent-glow`. Exact dark/light hex values come verbatim
  from DESIGN-01 / `styles.css`; `accent-soft/soft-2/glow` are derived from `accent`
  (the `color-mix` derivations in `styles.css`).
- **D-03:** Theme switching reuses Chromium's `BrowserColorScheme {kSystem, kLight,
  kDark}` pref (`prefs::kBrowserColorScheme`, `chrome/browser/themes/theme_service.*`).
  Default = **follow system**; wire the preserved v1 explicit theme toggle to write
  `kLight`/`kDark` to that same pref. No new switching machinery.
- **D-04:** **Force** the warm palette wholesale at the leaf — the Prometheus mixer
  runs **last** (after `AddMaterial*`/GM3) so it overrides GM3/dynamic color for
  product surfaces, while Chromium's own dark/light infra selects which warm set is
  active. Do NOT route warm colors through GM3 `user_color` /
  `UserColorSource::kAccent` (that regenerates a *neutral* tonal ramp and fights the
  warm palette).
- **D-05:** Model **accent as an overridable token now; defer the picker UI.** Give
  the active accent its own `kColorPrometheusAccent`/`Accent2` ids resolved from a
  Prometheus-owned pref (NOT `ColorProviderKey::user_color`); derive accent-soft /
  soft-2 / glow from it. Build **no** swatch-picker UI in Phase 14 (deferred to
  Phase 16/20). Lock all four swatch hexes as named constants now: **FSB Orange
  `#ff6b35`, Indigo `#6366f1`, Teal `#14b8a6`, Rose `#f43f5e`** (carried from v1
  `09-04-SUMMARY.md`).

### Area 2 — Icon port (FULL PARITY — user override of the hybrid recommendation)
- **D-06:** **Full parity** — convert the **entire** curated Font Awesome Free subset
  (~69 glyphs) into `gfx::VectorIcon` `.icon` files so the same FA glyph renders
  natively in Views **and** as SVG in WebUI. Native chrome shows the real FA glyphs,
  not Chromium Material substitutes (chosen over the hybrid for cross-surface
  consistency / DESIGN-06). Ship the `.icon` set via a Prometheus-owned
  `aggregate_vector_icons("prometheus_vector_icons")` GN target (the
  `components/vector_icons/vector_icons.gni` template + local `.cc/.h.template`),
  generating a `const gfx::VectorIcon&` constant per glyph.
- **D-07:** Conversion is **scripted and repeatable.** There is **no in-tree
  SVG→.icon converter** (`aggregate_vector_icons.py` only composes existing `.icon`
  files). Wrap the external skiafy + SVGO conversion in a `.planning/chromium/` helper
  that (a) regenerates the whole `.icon` set when the FA source is upgraded and
  (b) injects a **provenance header** (source FA glyph name + CC BY 4.0) into each
  generated `.icon` file. (User chose the scripted+provenance option; an additional
  gate-fail-on-missing-provenance is *not* required — see Claude's Discretion.)
- **D-08:** Port v1's resolver as **one semantic-action header** mapping a
  `PrometheusAction` enum to surface-specific lookups: **Views** →
  `base::flat_map<PrometheusAction, const gfx::VectorIcon*>` consumed at call sites
  via `ui::ImageModel::FromVectorIcon(kPrometheus…Icon, kColorPrometheusAccent, size)`
  — accent applied as a **color id** (`ui::ColorVariant`), not a recolored asset;
  **WebUI** → the same enum to an iconset symbol id / resource path. Deterministic and
  host-theme-independent (replaces v1's `QIcon::fromTheme`). Carry the v1 substitution
  notes: `arrow-down-to-line`→`arrow-down` (missing in FA Free 6 solid), and
  `sidebar-flip` as a bundled placeholder (Pro-only, not in FA Free).
- **D-09:** WebUI keeps the **raw FA SVG subset** (served as a `cr-iconset` or images
  resource) so the CC BY 4.0 comment survives inside the XML and Phase 16's named
  glyphs (`fa-bolt`, `fa-compass`, `fa-layer-group`, `fa-wand-magic-sparkles`,
  `fa-book-open`, `fa-highlighter`, …) are directly usable. Under full parity, **both**
  formats ship for each glyph: `.icon` (Views) + `.svg` (WebUI), from the same source.

### Area 3 — Font + asset resource & license pipeline
- **D-10:** Use a **Prometheus-owned GRIT/.pak resource pipeline.** Vendored
  third-party assets under `third_party/{poppins,space_mono,font_awesome_free}/`, each
  with a `README.chromium` (Name/URL/Version/License/License File/Shipped — the
  `tools/licenses` schema) + the verbatim `OFL.txt` / CC-BY / MIT `LICENSE`.
  Product-owned marks (PM monogram, Prometheus wordmark, FSB logos, app icons) under
  `chrome/browser/resources/prometheus/`. All declared in one Prometheus GRD/grdp
  compiled to `.pak`.
- **D-11:** **Font reach.** WebUI ships Poppins (4 weights: Thin 100, Light 300,
  ExtraBold 800, Black 900) + Space Mono as **woff2**, consumed via a
  `prometheus_fonts.css` `@font-face` using `url(//resources/prometheus/fonts/…woff2)`
  — mirrors the in-tree `ui/webui/resources/roboto/` + `ui/webui/resources/css/roboto.css`
  precedent. ~All Poppins use is on WebUI surfaces. Native Views needs **very little**
  font support — system UI is the native default; do NOT add OS-level `CTFontManager`
  registration (no `ui/gfx` precedent). If a native Views label genuinely needs
  Space Mono / Poppins before Phase 15/16, load bytes via
  `ResourceBundle::GetRawDataResource(IDR_…)` + build `PlatformFontMac(sk_sp<SkTypeface>, …)`
  from an `SkTypeface` made from that data (ship **ttf** for the Views shim path) — an
  as-needed shim, not a font-registration subsystem.
- **D-12:** **License-validation gate** — a `.planning/chromium/` script (e.g.
  `verify-asset-pipeline.sh`, matching the `set -euo pipefail` / `fail()` /
  SCRIPT_DIR→PROJECT_ROOT conventions of `verify-artifact-isolation.sh` /
  `check-falkon-gpl-guard.sh`) asserting: (1) every declared asset present + non-zero
  (4 Poppins weights, Space Mono, every FA glyph in the curated subset, PM / wordmark /
  FSB dark+light, app icons); (2) `OFL.txt`/`LICENSE` present per font family and the
  root `LICENSES/poppins-OFL.txt` + `LICENSES/spacemono-OFL.txt` placeholders (left by
  Phase 13) are filled; (3) a `README.chromium` exists per
  `third_party/{poppins,space_mono,font_awesome_free}`; (4) a CC BY 4.0 attribution
  comment is preserved inside every bundled FA **SVG** (and an MIT notice if any FA JS
  ships); (5) **no** remote/network URL (`http://`, `https://`, external `src:` /
  `url(//fonts.`) in any bundled CSS/HTML/SVG (the offline guarantee); (6) root
  `NOTICES.md` still contains the Font Awesome / Poppins / Space Mono sections +
  CC BY 4.0 + OFL + the `chrome://credits` pointer (ties back to the Phase 13 legal
  baseline; absorbs/extends the grep check Phase 13 sketched in `LEGAL-NOTICE-INVENTORY.md`).

### Area 4 — Phase-14 verification harness
- **D-13:** Build a **dev-only verification surface** *plus* an automated substrate.
  (1) A feature-gated `chrome://prometheus-theme-preview` WebUI page (a ~65-line
  `WebUIController` + `WebUIConfig` registration in `chrome_web_ui_configs.cc` + a GRIT
  resource) rendering every token swatch (resolved hex), both fonts at all weights,
  every bundled glyph, and every DESIGN-07 state. (2) A native **Views token gallery**
  mirroring `ui/views/examples/colors_example.cc` (enumerate ids → `ColorProvider->GetColor()`
  → swatch, rebuild on `OnThemeChanged()` = live theme-toggle proof). Both are explicitly
  throwaway dev surfaces that Phase 16 deletes or folds into the real FSB Control Panel.
- **D-14:** **Automated tests are the real gate** (the project auto-approves visual
  checkpoints). Unit tests assert: each `kColorPrometheus*` id resolves to the correct
  `SkColor` in both dark and light; the `--color-prometheus-*` CSS custom properties
  emit; fonts load with sane metrics; every declared icon/asset resource ID resolves.
  Build on `ui/color/color_provider_unittest.cc` / `color_mixer_unittest.cc` patterns.
  The dev surfaces are the screenshot/evidence artifact an auto-approved human
  checkpoint captures.
- **D-15:** Carried-forward visual checks — Phase 14 **satisfies-now (does NOT retire)**
  the asset/token/font/icon subset of the 26 carried-forward v1 checks via the harness:
  Poppins weights / PM mark rendering, dark↔light token swap without restart,
  accent-swatch recolor, bundled-FA-vector-not-platform-theme icons, and the
  no-network-asset checks. Mark them `satisfied-by-Ph14-harness`. Do **not** retire
  product-layout / packaging checks: about-dialog PM mark at 128px, packaged app-icon /
  OFL-in-about (→ Phase 24), or any layout/responsive/handoff check — those stay with
  their later owner phases. (The exact ledger ids are the area-4 researcher's reading;
  the planner confirms them against the dossier ledger before tagging.)

### Cross-cutting (carried forward — locked, do not re-derive)
- **Patch discipline:** edits live in `.context/chromium/src` on a
  `prometheus/phase-14-*` branch, exported via `git format-patch` from the pinned
  baseline `0e8499df5172f55d0d29e2b92ef7e6a704529578`; the root repo holds docs,
  scripts, and exported patches only (Phase 12).
- **License boundary:** NO GPL Falkon C++/Qt/QSS copied into Chromium; the v1 `.qss`
  themes are **design-token reference only**; assets re-enter only through the
  license-reviewed pipeline (Phase 11/13).
- **Display family unified on Poppins:** `styles.css`'s `--font-display: "Space Grotesk"`
  was a stand-in; the brand sheet is authoritative → **Poppins**. Do NOT carry Space
  Grotesk into Chromium.
- **Phase-12 gates still apply:** `check-chromium-env.sh`, `build-chromium-baseline.sh`,
  `verify-artifact-isolation.sh` — design-system changes must still pass them.

### Claude's Discretion
- Exact `kColorPrometheus*` id names, the precise mixer recipe / derivations for
  accent-soft/glow, GRD/grdp organization and IDR naming, the `prometheus_vector_icons`
  GN target name, the dev-preview host name
  (`chrome://prometheus-theme-preview` vs `chrome://prometheus-internals/theme`), the
  conversion-helper script structure/filenames, and the validation-script filename are
  at the planner's/executor's discretion, provided the decisions above and the success
  criteria are met.
- Whether the asset/license gate **additionally** fails on a missing `.icon` provenance
  header — the user chose the scripted+provenance option, *not* the explicit gate-fail
  variant; the planner may add it as hardening but it is not required.
- The planner should confirm the exact carried-forward VIS check ids against the
  preservation dossier ledger before marking any `satisfied-by-Ph14-harness`.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope & requirements
- `.planning/ROADMAP.md` §"Phase 14: Asset and Design System Port" — goal, DESIGN-01..07,
  the 5 success criteria, and planned work; also the Phase 15 (chrome/tabs) and Phase 16
  (WebUI) sections so this phase provides the foundation without duplicating them.
- `.planning/REQUIREMENTS.md` — DESIGN-01 (the exact 11 warm hex values), DESIGN-02
  (sparse accent), DESIGN-03 (offline Poppins/Space Mono + OFL), DESIGN-04 (FA Free
  subset + CC BY 4.0), DESIGN-05 (PM/wordmark/FSB marks dark/light + clear-space /
  min-size / fallback), DESIGN-06 (shared token vocabulary across WebUI + Views),
  DESIGN-07 (visual verification matrix).
- `.planning/PROJECT.md` — v2.0 Chromium migration goals, constraints, license boundary.

### Canonical design language (source of truth — MUST read)
- `.planning/design/DESIGN-REFERENCE.md` — authoritative palette (dark/light),
  typography (Poppins/Space Mono roles, the Space Grotesk→Poppins decision), logo /
  PM-mark construction, state semantics, the accent-sparseness rule.
- `.planning/design/prometheus-browser/prometheus/styles.css` — **THE canonical token
  source**: the full token set, the `[data-theme]` swap, the `--accent` override tweak,
  and the state styles (focus ring, hover, disabled, status pill, supervised/active
  treatments).
- `.planning/design/prometheus-brand/Prometheus Logo.html` — PM monogram (P Poppins
  Thin / M Poppins Black / `▽0.1` Space Mono), wordmark (Pro 300 + metheus 800 accent),
  app icon (24% radius, treatments), clear-space / min-size rules.
- `.planning/design/prometheus-browser/prometheus/assets/` — FSB logo references
  (`fsb_logo_dark.png`, `fsb_logo_light.png`, `fsb_icon.png`).
- `assets/` (repo root) — product marks already outside Falkon: `prometheus.svg`,
  `prometheus-icon.svg`, `prometheus-wordmark.svg`, `prometheus-wordmark-light.svg`,
  `fsb_logo_{dark,light}{,_footer}.png`.

### Migration contract & license boundary (MUST read)
- `.planning/preservation/FALKON-TO-CHROMIUM-PRESERVATION.md` — the asset inventory
  (exact v1 Falkon paths for fonts/icons/marks), the "license-reviewed asset pipeline"
  rule, the `third_party_attribution_required` vs `product_owned` classification, the
  deferred visual-check ledger (the 26 carried-forward checks), and the canonical
  palette/typography tables.

### Chromium baseline, patch discipline, gates, legal baseline
- `.planning/chromium/CHROMIUM-CHECKOUT.md` — pinned revision, GN args, patch
  branch/export discipline, gate-script conventions.
- `.planning/chromium/PRODUCT-IDENTITY-INVENTORY.md` — Phase-13 identity/override
  inventory (where Prometheus already overrides Chromium surfaces).
- `.planning/phases/13-product-identity-branding-and-legal-baseline/13-CONTEXT.md` —
  Phase-13 decisions: the NOTICES section authored for FA / Poppins / Space Mono / FSB
  (asset port explicitly deferred here), the GPL-Falkon static guard, the BRANDING/`.grd`
  patch approach, and the bundle id.
- `NOTICES.md` (repo root) + `LICENSES/poppins-OFL.txt` + `LICENSES/spacemono-OFL.txt` —
  the legal baseline this phase's assets must keep satisfied; the two OFL files are
  Phase-13 placeholders to fill.
- `.planning/phases/09-offline-font-awesome-free-icon-system-and-minimal-themes/09-CONTEXT.md`
  (+ its `09-UI-SPEC.md` if present for the glyph list) — v1 intent: curated FA subset,
  central resolver + action→icon map, deterministic bundled fallbacks (the concept being
  ported).

### Key Chromium primitives confirmed present in `.context/chromium/src` (cite while planning)
- `chrome/browser/ui/color/chrome_color_id.h` (`kChromeColorsStart`, `E_CPONLY`),
  `chrome/browser/ui/color/chrome_color_mixers.cc` (`AddChromeColorMixers`),
  `ui/color/color_mixers.cc` — where `kColorPrometheus*` ids + `prometheus_color_mixer.cc`
  hook in.
- `ui/webui/color_change_listener/color_change_handler.*`,
  `chrome/browser/ui/webui/theme_source.cc` (emits the `{kChromeColorsStart,kChromeColorsEnd}`
  range to `chrome://theme/colors.css`), `ui/color/color_provider_utils.cc`
  (`ConvertColorProviderColorIdToCSSColorId`) — the C++→CSS emission path.
- `chrome/browser/themes/theme_service.*` (`BrowserColorScheme {kSystem,kLight,kDark}`,
  `prefs::kBrowserColorScheme`), `ui/native_theme/native_theme.h` (`ShouldUseDarkColors`)
  — theme switching.
- `components/vector_icons/` (the `.icon` format, `aggregate_vector_icons.py`,
  `vector_icons.gni`, `vector_icons.{cc,h}.template`), `ui/gfx/vector_icon_types.h`,
  `ui/base/models/image_model.h` (`ImageModel::FromVectorIcon`) — the Views icon path +
  the Prometheus aggregate target.
- `ui/webui/resources/roboto/` + `ui/webui/resources/css/roboto.css` +
  `ui/webui/resources/css/BUILD.gn` — the font-bundling precedent for Poppins/Space Mono
  woff2.
- `ui/gfx/platform_font_mac.mm` (`PlatformFontMac(sk_sp<SkTypeface>, …)` ctor) — the
  as-needed native font shim path.
- `ui/views/examples/colors_example.cc`, `chrome/browser/ui/webui/internals/internals_ui.cc`,
  `chrome/browser/ui/webui/chrome_web_ui_configs.cc` — templates for the dev preview surfaces.
- `tools/licenses` / `about_credits` / the `README.chromium` schema (example:
  `third_party/test_fonts/README.chromium`) — the license-metadata machinery the
  validation gate ties into.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `kColorActorUi*` agent-UI color cluster (`chrome_color_id.h` / `chrome_color_mixer.cc`):
  direct in-tree precedent for a product-owned color-id family auto-emitted to WebUI.
- `ui/webui/resources/roboto/` font bundle: copy-paste pattern for the Poppins/Space Mono woff2 bundle.
- `ui/views/examples/colors_example.cc`: near-verbatim template for the Views token gallery.
- `components/vector_icons` aggregate machinery: reuse the GN template for a `prometheus_vector_icons` target.
- Phase-12/13 gate scripts under `.planning/chromium/`: pattern for the asset-validation gate;
  the Phase-13 `NOTICES.md` + `LEGAL-NOTICE-INVENTORY.md` grep check to absorb.
- v1 assets in the Falkon bundle/patches (`falkon/src/lib/data/fonts/{poppins,spacemono}/*.ttf`
  + `OFL.txt`, `…/icons/fa/*.svg`, `…/assets/pm_{dark,light}.png`, FSB logos): the source
  material to re-vendor through the license-reviewed pipeline.

### Established Patterns
- The Chromium color pipeline (color id → mixer → `ColorProvider` → WebUI CSS) is THE
  way to theme both surfaces from one source.
- `.icon` authoring is manual (no in-tree SVG converter) — hence the scripted skiafy/SVGO helper.
- Planning-owned operational scripts live under `.planning/chromium/`; Chromium source
  edits are tracked as exportable patches; large assets/checkout stay under `.context/`.
- Third-party assets carry `README.chromium` + `LICENSE` so `tools/licenses` /
  `about_credits` discover them.

### Integration Points
- Phase 15 (compact chrome/tabs, native Views) consumes `kColorPrometheus*`, the
  `prometheus_vector_icons` set, and the resolver map.
- Phase 16 (WebUI surfaces) consumes `--color-prometheus-*`, `prometheus_fonts.css`, the
  FA SVG iconset, and the same resolver enum; it also deletes/folds the dev preview surface.
- The asset-validation gate ties into the Phase-13 `NOTICES.md` and the Phase-24
  packaged-notice validation.

</code_context>

<specifics>
## Specific Ideas

- Exact warm hex values (DESIGN-01 / `styles.css`), both themes — the planner copies these
  verbatim into the mixer (dark `#0d0a09 #141110 #1d1816 …`; light `#fffdfb #f3ede6 #e9e2da …`).
- Accent swatches locked: FSB Orange `#ff6b35`, gradient end `#ff8c42`; Indigo `#6366f1`,
  Teal `#14b8a6`, Rose `#f43f5e`.
- Poppins weights required: Thin 100, Light 300, ExtraBold 800, Black 900. Space Mono regular.
- PM monogram is weight-split: `P` Poppins Thin 100 + `M` Poppins Black 900 + `▽0.1` Space
  Mono (`▽` = U+25BD, 0.45em tracking).
- v1 glyph substitutions to carry forward: `arrow-down-to-line`→`arrow-down`;
  `sidebar-flip` bundled placeholder (Pro-only, not in FA Free).
- Fonts ship twice where both surfaces need them: **woff2** (WebUI) + **ttf** (Views shim).

</specifics>

<deferred>
## Deferred Ideas

- Accent swatch-picker UI / tweaks surface (accent, side-panel side, tab density) → Phase 16 / 20.
- Themed Prometheus "About" WebUI page with full brand treatment → Phase 16.
- The actual compact chrome / tab-strip Views and the WebUI pages that consume these
  tokens/icons → Phase 15 / 16.
- Packaged-notice validation, app-icon-in-package, and OFL-in-about checks → Phase 24.
- Product-layout / responsive / handoff carried-forward visual checks (about-dialog mark,
  control-panel layout, start-page responsive) → their later owner phases.

None — discussion stayed within phase scope (all of the above are explicit later-phase owners, not dropped scope).

</deferred>

---

*Phase: 14-asset-and-design-system-port*
*Context gathered: 2026-06-24*
