---
phase: 14
reviewers: [codex]
reviewed_at: 2026-06-24T21:30:12Z
plans_reviewed: [14-01-PLAN.md, 14-02-PLAN.md, 14-03-PLAN.md, 14-04-PLAN.md, 14-05-PLAN.md, 14-06-PLAN.md, 14-07-PLAN.md, 14-08-PLAN.md]
model: codex (codex-cli 0.142.0, default model)
---

# Cross-AI Plan Review — Phase 14: Asset and Design System Port

> Single-reviewer cycle (`--codex`). Codex inspected both the plan set (14-02 through
> 14-08) and the already-executed Wave 0 artifacts on disk (`chrome_color_id.h`,
> `BUILD.gn`, `verify-asset-pipeline.sh`, `convert-fa-icons.sh`, the RED unit tests).
> Several HIGH findings were independently re-verified against the on-disk gate scripts
> before publishing (see "Reviewer-Verified Findings" below).

## Codex Review

**Summary**

The plan set is directionally strong, but not ready to execute as-is. The biggest risks are not architectural; they are deterministic execution failures caused by Wave 0 reality drift, asset manifest mismatches, WebUI resource serving gaps, and incomplete icon resolver implementation. Several final gates can currently pass too weakly or fail for the wrong reason, so the plans need tightening before continuing past 14-02.

**Strengths**

- The phase decomposition is sensible: color IDs/mixer, vendored assets, icon conversion, GRIT packaging, preview surfaces, then final gates.
- The locked decisions are mostly reflected: `COMMON_CHROME_COLOR_IDS`, `sets=chrome`, no GM3 `user_color`, packaged fonts/icons, and no GPL Falkon code copying.
- The plan correctly identifies hard Chromium pitfalls like `aggregate_vector_icons` template placement and SVG comment stripping.
- The Wave 0 summary honestly records deviations, especially pre-added color IDs and direct mixer inclusion.
- The final gate intent is good: unit tests, license/offline script, GPL guard, artifact isolation, VIS ledger, patch export.

**Concerns**

- [HIGH] 14-02 Task 1 is stale after Wave 0. The 20 `kColorPrometheus*` IDs already exist in `chrome_color_id.h` (added in Wave 0), but 14-02 still instructs inserting them again at `14-02-PLAN.md:93`. Literal execution risks duplicate enum declarations and compile failure. Its verify (`grep -c 'E_CPONLY(kColorPrometheus' ... | grep -q '^20$'`) already passes, so the plan would "succeed" while doing redundant/destructive work.

- [HIGH] 14-02 adds `prometheus_color_mixer.cc` to `:mixers` but does not remove the Wave 0 direct test source. The test target still compiles `../ui/color/prometheus_color_mixer.cc` directly (`chrome/browser/prometheus/BUILD.gn:16`), while 14-02 adds it to the `mixers` source set (`14-02-PLAN.md:147`). Once `prometheus_unittests` also depends on `:mixers`, that is a likely duplicate-symbol link failure.

- [HIGH] The executed asset gate disagrees with 14-04's asset layout and names. `verify-asset-pipeline.sh` requires PNG marks named `pm_mark_dark.png`, `pm_mark_light.png`, `pm_wordmark_dark.png`, `pm_wordmark_light.png` (`verify-asset-pipeline.sh:55-58`), while 14-04 writes `.svg` files with different names (`pm_mark_dark.svg`, `prometheus_wordmark_dark.svg`) (`14-04-PLAN.md:211`). The final gate (14-08) will fail.

- [HIGH] The offline URL gate conflicts with the planned FA provenance text. The converter injects `License: CC BY 4.0 (https://creativecommons.org/licenses/by/4.0/)` into `.icon` and SVG comments (`convert-fa-icons.sh:126,154`), while Assertion 5 greps the whole `chrome/browser/resources/prometheus/` tree (including `svg/`) for `https://` and fails on any match (`verify-asset-pipeline.sh:125`). Meanwhile Assertion 4 *requires* the CC BY 4.0 attribution in every `fa_*.svg`. The two assertions are mutually unsatisfiable: a correctly-attributed conversion makes the offline gate fail, so `verify-asset-pipeline.sh` can never exit 0 in 14-08.

- [HIGH] 14-05's converter is not manifest-driven. `convert-fa-icons.sh` loops over whatever SVGs exist in `FA_SOURCE_DIR` (`convert-fa-icons.sh:173`). Pointed at full FA Free it generates far more than 69; the `arrow-down-to-line` substitution and `sidebar-flip` placeholder branches only fire when those (nonexistent) source filenames are encountered, so neither is reliably produced. There is no "exactly 69" guarantee.

- [HIGH] The icon resolver is left unimplemented. 14-05 creates only the `prometheus_action.h` declarations and defers the map to 14-08 (`14-05-PLAN.md:190,198`), but 14-08's `files_modified` does not include a `prometheus_action.cc` or a build target (`14-08-PLAN.md:11`). D-08 (the semantic action→icon resolver) is therefore not actually satisfied by any plan.

- [HIGH] Resource tests are unreliable as specified. 14-06 claims `ResourceBundle::HasDataResource()` is safe without initialization and offers `static_assert(IDR > 0)` as a fallback (`14-06-PLAN.md:160`). The runtime check can false-RED if the pak is not loaded in the GTest environment; the static assert can false-GREEN while the pak is missing. Either way the "GREEN" signal does not prove the asset is actually packaged.

- [HIGH] WebUI resources are not actually made addressable. 14-07 links `prometheus_fonts.css` and `<img>` SVG resources in the preview HTML (`14-07-PLAN.md:149-154`) but only sets the default HTML resource (`14-07-PLAN.md:145`). There is no `AddResourcePath` mapping for the CSS, the 69 SVGs, the images, or the font URLs, so the preview can render blank/missing assets even when the pak exists — undermining the DESIGN-07 visual evidence.

- [HIGH] 14-07 does not wire the new WebUI `.cc` into a GN target. The frontmatter lists new `prometheus_theme_preview_ui.{h,cc}` sources (`14-07-PLAN.md:10`) but no Chrome `BUILD.gn` is modified. Registering and instantiating `PrometheusThemePreviewUIConfig` without compiling the implementation risks a link failure.

- [HIGH] The Views gallery registration plan likely violates Chromium layering. 14-07 proposes adding Chrome-owned `chrome/browser/ui/views/prometheus` sources to `//ui/views/examples` (`14-07-PLAN.md:202`). `//ui/views/examples` must not depend upward on `//chrome/browser`, and adding sources alone does not register a visible examples tab. The `views_examples` build gate in 14-08 would then fail.

- [HIGH] D-14 coverage is weaker than the validation contract. Current color tests assert only accent and `bg-app`, while 14-VALIDATION.md requires *each* token in dark and light (`14-VALIDATION.md:52-61`). Current asset tests cover one FA icon and one mark, not all declared resources. As written, "full suite GREEN" does not equal "all tokens/assets verified."

- [HIGH] D-05's four named accent swatches are not implemented. 14-03 only assigns FSB Orange and `Accent2` (`14-03-PLAN.md:96`). Indigo, Teal, and Rose are locked decisions (D-05), but no constants or tests are planned. 14-08 then proposes tagging the accent-swatch live-change VIS check (VIS-09-04) satisfied (`14-08-PLAN.md:70`), despite Phase 14 only hardcoding the default accent — an over-claim.

- [HIGH] 14-04's `pm_mark_light.svg` fallback is not acceptable for DESIGN-05. Copying the dark mark and adding a TODO (`14-04-PLAN.md:213`) does not satisfy "render correctly on dark/light surfaces," which is Phase 14 success criterion #4.

- [MEDIUM] 14-02 says the Prometheus mixer is "last," but the planned insertion before the `key.custom_theme` block (`14-02-PLAN.md:79`) is not literally last; `custom_theme`/`app_controller` mixers run after native (`chrome_color_mixers.cc:79`). Either place it after those or document that "last" means "last built-in mixer." (D-04 intent could be subtly violated if a custom theme is active.)

- [MEDIUM] 14-05's external-tool fallback is unrealistic. Manual conversion of 69 SVG paths is described as acceptable (`14-05-PLAN.md:138`), but hand-authoring 69 Skia path-command files is not a credible autonomous fallback for a wave gate.

- [MEDIUM] 14-04's verification command is broken in the checked-in plan: it uses `ls ""/*.woff2` and `[ -s "/" ]` (`14-04-PLAN.md:228`) — empty variable expansions — so it will not validate the intended directories (the shell-variable interpolation was lost in the plan text).

- [MEDIUM] The dev-only gate via `DCHECK_IS_ON()` is probably fine for local debug, but it is not a product-policy buildflag. 14-07 relies on it (`14-07-PLAN.md:136`); DCHECK-enabled non-release (e.g. canary/dev) builds would still expose `chrome://prometheus-theme-preview`.

**Suggestions**

- Rewrite 14-02 as an idempotent reconciliation plan: verify the existing 20 IDs (do not insert them), remove the direct mixer source from `chrome/browser/prometheus/BUILD.gn`, then add the mixer to `:mixers`.
- Create one authoritative Phase 14 asset manifest with exact filenames, paths, IDR names, expected count, source URL/revision/hash, and license. Drive `verify-asset-pipeline.sh`, GRDP generation, tests, and preview rendering from that single manifest so the gate and the plans cannot diverge.
- Fix the offline-URL/provenance conflict: either drop the URL from the resource comments and keep only the `CC BY 4.0` token (and relax Assertion 4 to match), or make Assertion 5 detect only load-bearing/executable URLs (`src=`, `href=`, `url(`) rather than license-comment URLs.
- Make `convert-fa-icons.sh` iterate a curated 69-glyph manifest, explicitly generate the `arrow-down-to-line`→`arrow-down` substitution and the `sidebar-flip` placeholder, and fail unless exactly 69 `.icon` and 69 `.svg` outputs exist.
- Add `prometheus_action.cc`, a GN target for it, a dep on `prometheus_vector_icons`, and tests asserting every `PrometheusAction` maps to both a `gfx::VectorIcon` and a WebUI SVG resource path. Assign this to a concrete plan (it currently belongs to none).
- Replace the ResourceBundle static-assert path with a real pak-load test: build the grit target, load `prometheus_resources.pak` in the test fixture, and assert `HasDataResource()` + non-empty `GetRawDataResource()` for every declared asset.
- Expand the GTests to table-drive all 20 dark tokens, all 20 light tokens, all accent derivations, CSS output through the actual `sets=chrome` path, and every IDR in the asset manifest.
- In 14-07, register all preview resource paths with `WebUIDataSource::AddResourcePath` (or intentionally serve shared assets from `chrome://resources/`), and add the missing Chrome `BUILD.gn` target for the WebUI controller.
- Put the native token gallery in a Chrome-owned dev/test target (a Views unit/browser test, or a chrome-owned examples surface), not `//ui/views/examples`.
- Source real light/dark brand-mark variants in Phase 14; do not defer a copied light mark to Phase 16 if DESIGN-05 is a Phase 14 success criterion.

**Risk Assessment**

HIGH — several plans would fail deterministic build/gate checks (14-02 duplicate declarations/symbols, the 14-08 asset gate name + offline-URL conflicts, the 14-07 layering/BUILD gaps), and D-05/D-08/D-14 are not fully satisfied without additional implementation and test coverage.

---

## Reviewer-Verified Findings

The following HIGH findings were independently re-confirmed against the on-disk Wave 0
artifacts during this review cycle (not just taken from the model output):

1. **Offline-URL vs CC-BY conflict (CONFIRMED, blocks 14-08).**
   `verify-asset-pipeline.sh` Assertion 4 (lines 97-102) requires `CC BY 4.0` in every
   `fa_*.svg`; Assertion 5 (line 125) greps `chrome/browser/resources/prometheus/`
   (recursively, including `svg/`) for `https://` and calls `fail`. `convert-fa-icons.sh`
   writes the attribution as `License: CC BY 4.0 (https://creativecommons.org/licenses/by/4.0/)`
   into the optimized SVGs. The two assertions cannot both pass once real FA SVGs are
   present, so `verify-asset-pipeline.sh` (the 14-08 phase-close gate) can never exit 0
   as currently authored. This is the single highest-impact issue.

2. **Brand-mark filename/format mismatch (CONFIRMED, blocks 14-08).**
   The gate requires PNG marks `pm_mark_dark.png` / `pm_mark_light.png` /
   `pm_wordmark_dark.png` / `pm_wordmark_light.png` (lines 55-58). Plan 14-04 produces
   SVG marks with different names (`pm_mark_dark.svg`, `prometheus_wordmark_dark.svg`,
   `prometheus_wordmark_light.svg`). Assertion 1 will fail.

3. **14-02 color-id staleness (CONFIRMED).** 14-01-SUMMARY records that all 20
   `kColorPrometheus*` ids were added to `chrome_color_id.h` in Wave 0 (deviation #1),
   and the Wave 0 test run already shows `ColorIdRange` + both `CssEmission` tests GREEN.
   14-02 Task 1 still instructs inserting the same 20 ids — redundant at best, a
   duplicate-declaration compile break at worst.

> Note on a non-issue: the RESEARCH "Pitfall 1" text suggested `ui::AlphaBlend()` for
> accent-soft/glow, while 14-03 says "do NOT use AlphaBlend / use SkColorSetARGB." This
> is NOT a contradiction — RESEARCH Open Question 3 was later RESOLVED in favor of the
> `SkColorSetARGB` 8-bit-rounded approach, which 14-03 follows. No action needed.

---

## Consensus Summary

Only one reviewer (Codex) ran this cycle, so "consensus" reflects that single
adversarial pass plus reviewer re-verification of the load-bearing claims.

### Agreed Strengths

- Sound wave decomposition and faithful adherence to the locked color-pipeline decisions
  (single `COMMON_CHROME_COLOR_IDS` mixer, `sets=chrome` emission, no GM3 `user_color`,
  no GPL Falkon copying).
- The hard Chromium pitfalls (aggregate_vector_icons template placement, SVG comment
  stripping, mixer ordering) are correctly anticipated in the plans/research.
- Honest Wave 0 deviation accounting.

### Agreed Concerns (highest priority first)

1. **The 14-08 asset gate cannot pass as written** — two independent blockers: the
   offline-URL grep collides with the mandated CC BY 4.0 provenance URL, and the gate's
   PNG mark filenames do not match 14-04's SVG outputs. (HIGH)
2. **14-02 is out of sync with executed Wave 0 reality** — duplicate color-id insertion
   and an unremoved direct mixer test source create duplicate-declaration / duplicate-symbol
   risk. (HIGH)
3. **D-08 resolver is orphaned** — `prometheus_action.h` is declared but no plan owns the
   `prometheus_action.cc` implementation/tests. (HIGH)
4. **Verification is too shallow / unreliable to be the "real gate"** — token/asset tests
   cover a couple of samples rather than the full manifest, and the IDR tests rely on a
   `HasDataResource`/`static_assert` path that can false-GREEN or false-RED. (HIGH)
5. **14-07 WebUI + Views surfaces have build/serving gaps** — missing `AddResourcePath`
   mappings, missing Chrome `BUILD.gn` for the WebUI controller, and a layering-violating
   `//ui/views/examples` registration. (HIGH)
6. **DESIGN-05 under-delivered** — `pm_mark_light.svg` is a copy-of-dark placeholder; the
   four named accent swatches (Indigo/Teal/Rose) are unimplemented yet VIS-09-04 is
   proposed as satisfied. (HIGH)

### Divergent Views

None — single reviewer. The one apparent internal contradiction surfaced (AlphaBlend vs
SkColorSetARGB) was checked and is a non-issue (resolved in RESEARCH Open Question 3).

---

## Recommended Next Step

These HIGH findings are concrete and mostly mechanical (manifest reconciliation, gate
fixes, one missing `.cc` + GN target, deeper test tables). Feed this review back into
planning before executing Wave 1+:

```
/gsd-plan-phase 14 --reviews
```

Priority replan targets: 14-02 (idempotent reconciliation), 14-04 (mark name/format +
fix the verify command), 14-05/14-08 (manifest-driven 69-glyph conversion + own the
`prometheus_action.cc` resolver), the `verify-asset-pipeline.sh` offline/provenance
contradiction, 14-06/14-08 (real pak-load tests + full token/asset tables), and 14-07
(WebUI resource paths, WebUI BUILD target, Chrome-owned gallery target).
