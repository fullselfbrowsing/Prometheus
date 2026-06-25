---
phase: 14
cycle: 2
reviewers: [codex]
reviewed_at: 2026-06-25T07:32:22Z
plans_reviewed: [14-01-PLAN.md, 14-02-PLAN.md, 14-03-PLAN.md, 14-04-PLAN.md, 14-05-PLAN.md, 14-06-PLAN.md, 14-07-PLAN.md, 14-08-PLAN.md]
model: codex (codex-cli 0.142.0, default model)
prior_cycle_commit: 173575b6e
replan_commit: 04a4f4e97
unresolved_high: 1
---

# Cross-AI Plan Review — Phase 14: Asset and Design System Port (CYCLE 2 — RE-REVIEW)

> Re-review of the plan set AFTER the replan (commit `04a4f4e97`) that was made to resolve
> the 13 HIGH + several MEDIUM findings from Cycle 1 (preserved below under
> "Cycle 1 Review — Archived"). Codex re-audited each prior finding against the current plan
> text AND was asked to surface any NEW concerns the revisions introduced. The reviewer's
> three load-bearing new findings (TTF IDR mismatch, the 14-08 YAML defect, and the 14-08
> line-120 coverage escape hatch) were each independently re-confirmed against the plan files
> before publishing — see "Reviewer-Verified Findings (Cycle 2)".

## Codex Review (Cycle 2)

**Summary**

The revised plan set genuinely closes most of the prior HIGH/MEDIUM findings, especially the
Wave 0 drift, duplicate-symbol risk, icon-resolver ownership, real pak-load tests, WebUI build
wiring, Views layering, and the VIS-09-04 over-claim. It is NOT ready to execute as-is yet:
there is one NEW HIGH cross-plan mismatch around TTF IDRs, plus a malformed `14-08` frontmatter
block that will break YAML parsing.

**Prior-Finding Resolution Audit**

| Prior finding (Cycle 1) | Status | Mechanism |
|---|---|---|
| 14-02 stale color-id insertion | RESOLVED | 14-02 Task 1 is now verification-only and explicitly warns not to re-insert (14-02:118-139). |
| Duplicate mixer symbol (direct test source + `:mixers`) | RESOLVED | 14-02 removes `../ui/color/prometheus_color_mixer.cc` and adds `//chrome/browser/ui/color:mixers` dep (14-02:158-175). |
| Asset gate disagrees with 14-04 names/layout | RESOLVED | 14-04 adopts the exact PNG gate names and TTF root paths (14-04:142-158, 271-296). |
| Offline-URL vs CC-BY provenance conflict (top blocker) | RESOLVED | 14-08 rewrites Assertion 5 to a load-bearing-URL grep only (14-08:167-172). |
| Converter not manifest-driven / no exact-69 gate | RESOLVED | 14-05 adds `fa-glyph-manifest.txt`, a manifest loop, and an exact-69 count gate (14-05:152-169). |
| D-08 resolver orphaned | RESOLVED | 14-05 owns `prometheus_action.cc` + GN target + unit tests (14-05:270-308). |
| Resource tests unreliable / static-assert fallback | RESOLVED | 14-06 mandates `AddDataPackFromPath` + non-empty `GetRawDataResource()`; static_assert path banned (14-06:169-183, 213). |
| WebUI resources not addressable | PARTIALLY RESOLVED | 14-07 adds `AddResourcePath` for every asset (14-07:188, 220-222). Residual font-URL host ambiguity → see New Concerns (MEDIUM). |
| WebUI `.cc` not wired into a GN target | RESOLVED | 14-07 adds `chrome/browser/ui/webui/prometheus/BUILD.gn` + webui-target wiring (14-07:191-193, 222). |
| Views gallery `//ui/views/examples` layering violation | RESOLVED | 14-07 moves the gallery to a Chrome-owned target + browsertest; excludes `ui/views/examples` (14-07:226-274). |
| D-14 coverage weaker than the validation contract | PARTIALLY RESOLVED | 14-08 mostly requires full tables (14-08:26, 127, 151), but line 120 still permits "a representative set" of icon IDRs → see New Concerns (MEDIUM). |
| D-05 swatches missing / VIS-09-04 over-claim | RESOLVED | 14-03 adds all four swatch constants + `AccentSwatchConstantsDefined` (14-03:102-120). 14-08 keeps VIS-09-04 `carry_forward` (14-08:83-86, 184-186). |
| `pm_mark_light` copy-of-dark fallback | RESOLVED | 14-04 requires a real recolored light variant + a `cmp -s` guard (14-04:153, 276-278, 294). |
| Mixer "not literally last" (prior MEDIUM) | PARTIALLY RESOLVED | Main instruction places it after the custom_theme block (14-02:92-95, 158); the documented fallback (14-02:96-99) still lets custom_theme win — acceptable only as an explicitly-documented edge, but worth confirming at execution. |
| Unrealistic manual 69-icon fallback (prior MEDIUM) | RESOLVED | 14-05 now CHECKPOINTS if `skiafy` is unobtainable; no hand-authoring of 69 icons (14-05:187-189). |
| Broken 14-04 verify command (prior MEDIUM) | RESOLVED | 14-04 verify uses concrete shell vars / real checks, no empty `""`-expansions (14-04:290-294). |
| `DCHECK_IS_ON()` dev gate too broad (prior MEDIUM) | RESOLVED | 14-07 adds a channel guard (`chrome::GetChannel() == UNKNOWN`) so canary/dev do not expose the preview (14-07:120-123, 208-211). |

**New Concerns (introduced or surfaced by the revision)**

- **[HIGH] TTF IDR manifest/GRDP mismatch (cross-plan).** 14-04 Task 0 says the authoritative
  manifest lists TTF rows for "same 5 files" with `IDR_PROMETHEUS_FONT_*_TTF` (14-04:193), and
  14-04 copies all 5 TTFs into the resource tree (14-04:274). But 14-05's GRDP declares only
  TWO TTF IDRs: `IDR_PROMETHEUS_FONT_POPPINS_THIN_TTF` and `IDR_PROMETHEUS_FONT_SPACE_MONO_TTF`
  (14-05:243). 14-08 then table-drives the asset test over "EVERY IDR in 14-ASSET-MANIFEST.md"
  (14-08:26, 127). If the manifest lists 5 TTF IDRs but the GRDP only declares 2, the
  full-manifest IDR test references 3 undeclared symbols (Poppins Light/ExtraBold/Black TTF) and
  fails to compile / fails at runtime. The planner must reconcile the TTF set in ONE place: either
  trim the manifest to the 2 TTF IDRs D-11 actually needs for the as-needed Views shim
  (Poppins Thin + Space Mono), or expand the GRDP to declare all 5. (D-11 frames TTF as a minimal
  as-needed shim, which argues for trimming the manifest to 2.)

- **[MEDIUM] `14-08-PLAN.md` frontmatter is invalid YAML.** `must_haves:` (line 24) is immediately
  followed by a sequence of strings (lines 25-34) with NO `truths:` sub-key, then `artifacts:` /
  `key_links:` are indented as if nested under that sequence (lines 35-39). Every other plan uses
  `must_haves: → truths: → [list]` (cf. 14-02:18-19, 14-05:24-25). A strict YAML parser raises
  "did not find expected key"; the decision-coverage gate scans `must_haves`, so a parse failure
  there can silently drop 14-08's truths. Re-add the `truths:` key and fix the indentation.

- **[MEDIUM] 14-08 still contains a coverage escape hatch.** The behavior block line 120 permits
  "at minimum a representative set across the 69; ideally all 69" for IconResource, which directly
  contradicts the full-manifest mandate at 14-08:26, 127, and 151. Pick one: either commit to all
  69 icon IDRs table-driven (consistent with the D-14 depth fix) or down-scope the must_have. As
  written, an executor could ship "representative" icon coverage and still mark the must_have green.

- **[MEDIUM] WebUI font addressability is ambiguous.** `prometheus_fonts.css` uses
  `url(//resources/prometheus/fonts/...)` (14-04:135-140 / 285), but 14-07 maps the fonts as
  `fonts/...` paths on the `chrome://prometheus-theme-preview` data source (14-07:101-110). Unless
  the woff2 are ALSO served from `chrome://resources/` (or the `@font-face` url and the
  `AddResourcePath` key are made to resolve to the same origin/path), the preview's font loads can
  404 even though every asset is "addressable." 14-07 should pin the exact url()-to-resource-path
  mapping (or switch the CSS to relative `fonts/...` URLs that match the data-source keys).

- **[MEDIUM] Manifest tag-parsing order is internally ambiguous (14-05).** The 69-glyph manifest
  carries `# SUBSTITUTE=arrow-down` and `# PLACEHOLDER` as inline trailing comments (14-05:152-160),
  but the same instruction tells the converter to "strip comments/blank lines" while reading. If the
  script strips comments before reading the tags, the substitution/placeholder branches never fire.
  The plan should state explicitly: parse the trailing tag FIRST, then strip the comment.

- **[LOW] 14-08 unit-test verify can false-green.** Line 149's
  `... | grep -q "FAILED" && echo "TESTS FAILING" || echo "ALL TESTS GREEN"` prints a message but
  the compound command exits 0 regardless of whether tests failed, so as a `<automated>` gate it can
  never actually fail the task. Invert it (e.g. `! grep -q "FAILED"`) so a failing suite returns
  non-zero.

**Strengths**

- The replan correctly RECONCILES Wave 0 reality (pre-added IDs, direct mixer wiring) instead of
  pretending 14-01 did not happen — 14-02 is now a clean idempotent reconciliation.
- D-08 (the action→icon resolver) is now owned end-to-end by 14-05 (.cc + GN target + tests); it is
  no longer orphaned.
- The pak-load testing approach (14-06) is substantially stronger and matches the real
  resource-packaging risk; the static_assert/uninitialized-bundle false-GREEN path is explicitly banned.
- The Views gallery layering fix (Chrome-owned target + browsertest, no upward `//ui/views/examples`
  dependency) is the correct Chromium direction.
- VIS-09-04 is no longer over-claimed; the manifest-as-single-source-of-truth pattern (when its IDRs
  are made consistent) is the right structural fix for the gate/plan-drift class of bug.

**Risk Assessment**

Overall risk: **HIGH** until the TTF IDR mismatch and the 14-08 YAML defect are fixed. Of the 13
prior HIGH findings, **0 remain unresolved** (most are fully resolved; the residuals of the two
"partially resolved" prior HIGHs are themselves rated MEDIUM, not HIGH). **1 NEW HIGH** was
introduced by the revision (the cross-plan TTF IDR mismatch). The remaining items are MEDIUM/LOW
internal-consistency tightenings.

**Unresolved HIGH count this cycle: 1.**

---

## Reviewer-Verified Findings (Cycle 2)

The following Cycle-2 findings were independently re-confirmed against the current plan files
during this review (not just taken from the model output):

1. **TTF IDR mismatch (CONFIRMED, new HIGH).**
   - `14-04-PLAN.md:193` — manifest "Fonts (ttf): same 5 files, ttf, ... `IDR_PROMETHEUS_FONT_*_TTF`".
   - `14-05-PLAN.md:243` — GRDP declares only `IDR_PROMETHEUS_FONT_POPPINS_THIN_TTF` and
     `IDR_PROMETHEUS_FONT_SPACE_MONO_TTF` (no Light/ExtraBold/Black TTF IDRs anywhere in 14-05/06/08).
   - `14-08-PLAN.md:26,127` — asset test is table-driven over "EVERY IDR in 14-ASSET-MANIFEST.md".
   The 5-vs-2 gap makes the 14-08 full-manifest IDR test reference 3 undeclared TTF IDRs → a
   deterministic compile/test break. Reconcile the TTF set in one place (D-11 favors trimming the
   manifest to the 2 needed for the as-needed Views shim).

2. **14-08 frontmatter YAML defect (CONFIRMED, MEDIUM).**
   `14-08-PLAN.md:24-39` — `must_haves:` is followed directly by a 5-space-indented string sequence
   (no `truths:` key), then `artifacts:`/`key_links:` at 3-space indent. All sibling plans nest the
   list under `truths:`. This is a structural regression from the replan edit; the decision-coverage
   gate reads `must_haves`, so a parse failure can silently drop 14-08's truths.

3. **14-08 line-120 coverage escape hatch (CONFIRMED, MEDIUM).**
   `14-08-PLAN.md:120` ("at minimum a representative set across the 69; ideally all 69") contradicts
   the FULL-manifest mandate at lines 26/127/151 — the exact D-14-depth concern Cycle 1 raised,
   re-opened by a softer behavior-block phrasing.

> Note on on-disk gate scripts: `verify-asset-pipeline.sh` and `convert-fa-icons.sh` are still the
> committed Wave 0 versions and therefore still contain the prior Assertion-4-vs-5 contradiction and
> the `*.svg`-glob (non-manifest) loop. This is BY DESIGN — 14-08 (Assertion 5) and 14-05 (manifest
> loop) own those edits during later-wave execution. The plans specify the fixes correctly. The only
> residual risk is that the contradictory script is what runs at every wave boundary per
> 14-VALIDATION.md until 14-08 lands; that is acceptable because the script is RED-by-design pre-assets
> and the assets that would trip the Assertion-4/5 conflict do not exist until 14-04/14-05 run.

---

## Consensus Summary

Single-reviewer cycle (`--codex`) plus reviewer re-verification of the load-bearing claims.

### Agreed Strengths

- The replan genuinely closed the Cycle-1 HIGH set: Wave 0 reconciliation (14-02), manifest-driven
  exact-69 conversion (14-05), in-phase D-08 resolver ownership (14-05), real pak-load tests (14-06),
  WebUI build wiring + Chrome-owned gallery (14-07), the offline-vs-CC-BY Assertion 5 fix (14-08),
  and the VIS-09-04 carry_forward correction (14-08).
- The 14-ASSET-MANIFEST.md "single source of truth" pattern is the right structural antidote to the
  gate/plan drift that caused most of Cycle 1's HIGHs — provided its IDR rows are made internally
  consistent (see the TTF finding).

### Agreed Concerns (highest priority first)

1. **TTF IDR mismatch between the 14-04 manifest (5) and the 14-05 GRDP (2)** breaks the 14-08
   full-manifest asset test. (HIGH — the one unresolved HIGH this cycle.)
2. **14-08 frontmatter is invalid YAML** (`must_haves` missing its `truths:` key). (MEDIUM)
3. **14-08 line-120 icon-coverage escape hatch** contradicts the full-manifest D-14 mandate. (MEDIUM)
4. **WebUI font url() vs AddResourcePath host/path mismatch** can 404 preview fonts. (MEDIUM)
5. **14-05 manifest tag-parse-vs-strip-comment ordering** could disable the substitution/placeholder
   branches. (MEDIUM)
6. **14-08 unit-test verify** is informational-only and can false-green. (LOW)

### Divergent Views

None — single reviewer. The reviewer's "PARTIALLY RESOLVED" labels on the WebUI-addressability and
D-14-coverage prior HIGHs were checked: in both cases the underlying prior HIGH is resolved and the
residual is a NEW MEDIUM (not a lingering HIGH), so neither counts toward the unresolved-HIGH total.

---

## Recommended Next Step

One genuine HIGH plus a small set of MEDIUM/LOW internal-consistency fixes remain — all mechanical.
Feed this review back into planning before executing Wave 1+:

```
/gsd-plan-phase 14 --reviews
```

Priority replan targets:
1. Reconcile the TTF IDR set in ONE place (trim the 14-04 manifest to the 2 TTF IDRs D-11 needs, OR
   expand the 14-05 GRDP to declare all 5) so 14-08's full-manifest test compiles. (HIGH)
2. Fix the 14-08 frontmatter: restore `must_haves: → truths:` and re-indent `artifacts`/`key_links`.
3. Remove the 14-08 line-120 "representative set" escape hatch (commit to all 69 icon IDRs) to match
   lines 26/127/151.
4. Pin the WebUI font url()-to-AddResourcePath mapping in 14-07 (or serve fonts from chrome://resources).
5. State the 14-05 tag-parse-before-strip-comment order explicitly.
6. Invert the 14-08 line-149 verify so a failing suite returns non-zero.

---

## Cycle 1 Review — Archived

> The full Cycle-1 single-reviewer (`--codex`) review that produced the 13 HIGH + MEDIUM findings the
> replan (`04a4f4e97`) addressed. Retained for traceability; the resolution status of each item is in
> the "Prior-Finding Resolution Audit" above.

**Cycle 1 Summary:** The plan set was directionally strong but not ready to execute — the biggest
risks were deterministic execution failures from Wave 0 reality drift, asset-manifest mismatches,
WebUI resource-serving gaps, and an unimplemented icon resolver. Cycle 1 raised 13 HIGH findings:

1. 14-02 Task 1 stale (re-inserting the 20 ids already added in Wave 0 → duplicate-enum compile break).
2. 14-02 added the mixer to `:mixers` without removing the Wave 0 direct test source → duplicate symbol.
3. The executed asset gate (PNG mark names) disagreed with 14-04's SVG names → 14-08 gate fails.
4. Offline-URL Assertion 5 vs the mandated CC BY 4.0 provenance URL → mutually unsatisfiable gate.
5. 14-05 converter not manifest-driven → no "exactly 69" guarantee; substitution/placeholder unreliable.
6. The icon resolver (D-08) was left unimplemented and owned by no plan.
7. Resource tests relied on `HasDataResource`/`static_assert` → false-RED / false-GREEN.
8. 14-07 WebUI resources not made addressable (no `AddResourcePath`) → blank preview.
9. 14-07 WebUI `.cc` not wired into a GN target → link failure.
10. 14-07 registered the Views gallery into `//ui/views/examples` → Chromium layering violation.
11. D-14 coverage weaker than the validation contract (sample tokens/assets, not the full set).
12. D-05's four named accent swatches (Indigo/Teal/Rose) unimplemented; VIS-09-04 proposed satisfied.
13. 14-04's `pm_mark_light.svg` was a copy-of-dark placeholder → fails DESIGN-05.

Plus MEDIUMs: mixer not literally last; unrealistic hand-author-69-icons fallback; broken 14-04 verify
command (empty-variable expansions); `DCHECK_IS_ON()` exposing the preview on canary/dev.

**Cycle 1 Risk Assessment:** HIGH — several plans would fail deterministic build/gate checks, and
D-05/D-08/D-14 were not fully satisfied. Recommended `/gsd-plan-phase 14 --reviews` — which produced
commit `04a4f4e97`, re-reviewed in Cycle 2 above.
