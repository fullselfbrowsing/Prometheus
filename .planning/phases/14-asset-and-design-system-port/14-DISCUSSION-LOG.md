# Phase 14: Asset and Design System Port - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-24
**Phase:** 14-asset-and-design-system-port
**Areas discussed:** Token pipeline (Views + WebUI), Icon port, Font + asset resource & license pipeline, Verification harness
**Mode:** Advisor (research-backed) — each selected area was researched by a `gsd-advisor-researcher` agent before a comparison table was presented. Calibration tier: standard.

---

## Token pipeline (Views + WebUI)

| Option | Description | Selected |
|--------|-------------|----------|
| (a) Single Chromium color mixer | `kColorPrometheus*` ids + `prometheus_color_mixer.cc`; Views via `ColorProvider`, WebUI via auto-emitted `--color-*` CSS. CSS generated → no drift. | ✓ |
| (b) Codegen from a JSON token manifest | Single token file generates both C++ + CSS at build time; net-new codegen, bypasses live color pipeline. | |
| (c) Parallel C++/CSS synced by a test | Hand-authored mixer + CSS `:root`, equality test; two sources of truth, loses live theme switch. | |

**User's choice:** (a) Single Chromium color mixer (the recommendation).
**Notes:** Recommendation folded in three sub-decisions, all accepted: theme switch = follow-system default + wire the v1 toggle to `prefs::kBrowserColorScheme`; force the warm palette at the leaf (mixer runs last, no GM3 `user_color`); accent modeled as its own pref-backed token now with the picker UI deferred. All four swatch hexes carried forward locked from v1 (Orange `#ff6b35`, Indigo `#6366f1`, Teal `#14b8a6`, Rose `#f43f5e`).

---

## Icon port (FA Free across WebUI + native Views)

| Option | Description | Selected |
|--------|-------------|----------|
| (c) Hybrid | FA SVG for WebUI; convert only brand-critical glyphs to `.icon` for Views; reuse built-in `vector_icons` for the rest. (Recommended.) | |
| (a) Split by surface | FA SVG for WebUI; native chrome reuses Chromium's built-in `vector_icons` — FSB-bolt brand glyph would be missing in Views. | |
| (b) Full parity | Convert ALL ~69 FA glyphs to `.icon` so the real FA glyph renders in Views AND WebUI. Manual per-glyph conversion; `.icon` drops CC BY comment. | ✓ |

**User's choice:** (b) Full parity — **override of the hybrid recommendation.**
**Notes:** User prioritized true cross-surface visual consistency (real FA glyphs in native chrome, not Material substitutes) over conversion cost. Follow-up resolved how conversion is set up (below). WebUI still keeps the raw FA SVGs (CC BY comment + Phase 16 named glyphs); both `.icon` + `.svg` ship per glyph.

### Follow-up — full-parity conversion setup

| Option | Description | Selected |
|--------|-------------|----------|
| Scripted / repeatable | Wrap skiafy + SVGO conversion + provenance headers in a `.planning/chromium/` helper so FA upgrades regenerate the `.icon` set. | ✓ |
| One-time manual, documented | Convert once by hand, document the steps only. | |
| Scripted + gate-fail | Scripted, AND fail the asset gate if any `.icon` lacks a provenance header / NOTICES entry. | |

**User's choice:** Scripted / repeatable with provenance headers.
**Notes:** No in-tree SVG→.icon converter exists (`aggregate_vector_icons.py` only composes). Helper injects a provenance header (FA glyph name + CC BY 4.0) per `.icon` and regenerates on FA upgrade. The explicit gate-fail variant was not selected — left as optional planner hardening.

---

## Font + asset resource & license pipeline

| Option | Description | Selected |
|--------|-------------|----------|
| (a) Prometheus GRIT/.pak target | `third_party/{poppins,space_mono,font_awesome_free}/` + `chrome/browser/resources/prometheus/`; woff2 `@font-face` (roboto precedent); README.chromium per asset; `.planning/chromium/` validation gate. | ✓ |
| (b) macOS app-bundle + OS font registration | `CTFontManager`/`SkFontMgr` registration — no `ui/gfx` precedent, mac-only, net-new startup code. | |
| (c) chrome://theme + ThemeService | Designed for images not fonts — leaves the font problem unsolved. | |

**User's choice:** (a) Prometheus GRIT/.pak target (the recommendation).
**Notes:** WebUI carries ~all Poppins via woff2 `@font-face`; native Views needs very little font support (system UI default; `PlatformFontMac(SkTypeface)` shim only if a native label needs Space Mono before 15/16). Validation gate is a `.planning/chromium/` script asserting asset presence, OFL/LICENSE + README.chromium, CC BY comment in every FA SVG, no network URLs, and NOTICES.md integrity.

---

## Verification harness

| Option | Description | Selected |
|--------|-------------|----------|
| (a)+(b) Dev preview surface + automated tests | Feature-gated `chrome://prometheus-theme-preview` WebUI page + a Views token gallery (`colors_example.cc` template) + unit tests (color resolution, CSS emission, font/icon resolution). | ✓ |
| (b) Automated tests only | No human surface — can't cover text-fit / focus-ring / state appearance. | |
| (c) Defer to Phase 15/16 | Ship tokens+tests only — Phase 14 then can't claim its own success criterion. | |

**User's choice:** (a)+(b) Dev preview surface + automated tests (the recommendation).
**Notes:** Project auto-approves visual checkpoints, so the automated layer is the real gate and the dev surfaces are the screenshot/evidence artifact. Phase 14 satisfies-now (does not retire) the asset/token/font/icon subset of the 26 carried-forward v1 checks; product-layout/packaging checks stay with their later owner phases. Dev surfaces are throwaway — Phase 16 deletes or folds them into the real FSB Control Panel.

---

## Claude's Discretion

- Exact `kColorPrometheus*` id names, mixer derivations for accent-soft/glow, GRD/grdp organization + IDR naming, the `prometheus_vector_icons` GN target name, the dev-preview host name, the conversion-helper and validation-script filenames.
- Whether to additionally fail the asset gate on a missing `.icon` provenance header (user chose the lighter scripted+provenance option).
- Confirming the exact carried-forward VIS ledger ids against the preservation dossier before tagging `satisfied-by-Ph14-harness`.

## Deferred Ideas

- Accent swatch-picker UI / tweaks surface → Phase 16 / 20.
- Themed Prometheus "About" WebUI page → Phase 16.
- The compact chrome / tab-strip Views + WebUI pages consuming these tokens/icons → Phase 15 / 16.
- Packaged-notice validation, app-icon-in-package, OFL-in-about → Phase 24.
- Product-layout / responsive carried-forward visual checks → their later owner phases.
