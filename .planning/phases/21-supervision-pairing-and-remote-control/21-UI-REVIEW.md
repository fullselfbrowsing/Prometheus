---
phase: 21-supervision-pairing-and-remote-control
review_type: retroactive_six_pillar_ui_audit
reviewed: 2026-07-26
evidence_mode: code_only
screenshots_captured: false
overall_score: 13
maximum_score: 24
per_pillar:
  copywriting: 3
  visuals: 2
  color: 1
  typography: 2
  spacing: 2
  experience: 3
status: changes_required
needs_human_review: true
---

# Phase 21 UI Review

## Result

Phase 21 scores **13/24**. The functional and security test evidence is broad,
but the implemented presentation does not yet meet the approved UI contract.
The light-theme treatment of safety-critical destructive actions is a blocker;
the remaining pillars contain warnings.

This was a code-only review. No screenshots were captured, so rendered
hierarchy, perceived density, icon recognition, motion, and cross-platform
native-dialog polish remain human-review items. The existing closeout report
also records `human_uat: not_run`
(`21-VERIFICATION.md:1-12`, `21-VERIFICATION.md:271-274`).

### Evidence boundary

- **Automated/code evidence:** current HTML, CSS, JavaScript, Chromium Views
  code, browser-test source, and the freshly recorded Phase 21 closeout results.
- **Human-review evidence:** none. Any finding that depends on visual balance or
  actual rasterized appearance is explicitly marked below.
- The closeout records 190/190 Phase 21 native, 14/14 Blink, 52/52 browser, and
  81/81 Node tests passing (`21-VERIFICATION.md:56-76`). Those results establish
  strong behavioral coverage; they do not substitute for the unrun subjective
  visual review.

## Scorecard

| Pillar | Score | Classification | Summary |
|---|---:|---|---|
| Copywriting | 3/4 | WARNING | Primary, pairing, side-strip, and confirmation copy is strong, but required generic/service failure recovery copy is not rendered. |
| Visuals | 2/4 | WARNING | Connected, recent, audit, stream, and summary content use nested card-like containers despite the flat-list contract. |
| Color | 1/4 | BLOCKER | Light-theme destructive controls have approximately 1.19–1.35:1 text contrast; focus/accent boundaries also miss the 3:1 target. |
| Typography | 2/4 | WARNING | Phase 21 applies Poppins to body/controls, renders several supervision labels at 11px, and does not load the packaged font stylesheet on these surfaces. |
| Spacing | 2/4 | WARNING | Effective supervision rows use 1/3/6/9/12/14/18px spacing, and the 320px path applies 12px container padding, outside the approved token set. |
| Experience | 3/4 | WARNING | Focus, lifecycle, responsive, and safety behavior are well covered, but unavailable/error snapshots can leave stale UI and omit required recovery actions. |

## Pillar Findings

### 1. Copywriting — 3/4

**What is working (code/automated evidence)**

- The side-panel activity vocabulary matches the closed copy set, including
  `Viewing current page`, `Remote control ready`, `Validating remote action`,
  `Confirmation required in Prometheus`, resync states, and
  `Remote action blocked`
  (`prometheus_webui.js:66-86`, `prometheus_webui.js:460-467`).
- Viewer count, `View only`, `Controlled by`, stop/end/manage actions, and the
  exact bulk-end body are rendered directly
  (`prometheus_webui.js:505-553`, `prometheus_webui.js:578-637`).
- The one-time-code heading, explanatory copy, timer, copy/cancel actions, and
  lifecycle copy are implemented and exercised by the exact-copy browser test
  (`prometheus_control_panel.html:489-528`,
  `prometheus_web_ui_browsertest.cc:5434-5653`).
- Native supervision confirmations use the required safe-cancel labels and
  titles (`prometheus_runtime_dialogs.cc:316-381`).

**WARNING — required recovery copy is absent**

When a supervision snapshot is absent, `renderControlSupervision()` changes
only the status heading to `Loading supervision state` or
`Prometheus could not load supervision state`, then returns
(`prometheus_webui.js:2479-2487`). It does not render the contract-required
`Refresh diagnostics, then try again.` body or a `Refresh diagnostics` action.
Likewise, a non-null snapshot with `available: false` has no dedicated
`Supervision unavailable` heading/body path
(`prometheus_webui.js:1785-1804`, `prometheus_webui.js:2489-2496`).

**Recommendation:** add explicit loading, generic-error, and
service-unavailable presentation blocks with the exact approved body and action
copy. Test the complete heading/body/action triplets, not only the heading.

### 2. Visuals — 2/4

**WARNING — the implementation contradicts the flat-list direction**

The design contract calls for flat lists, compact summaries, hairline
separators, and only one purposeful pairing-code panel
(`21-UI-SPEC.md:77-83`). Instead:

- connected dashboards are `article.control-card` nodes
  (`prometheus_webui.js:2231-2299`);
- recent access and audit rows are also `article.control-card` nodes
  (`prometheus_webui.js:2317-2377`);
- summary metrics use `.control-metric` boxes
  (`prometheus_webui.js:2380-2413`);
- stream and current-action regions receive their own background, border,
  radius, and padding (`prometheus_webui.css:1204-1212`);
- `.control-card` and `.control-metric` share a secondary background, border,
  radius, and internal padding inside the already framed `.section-panel`
  (`prometheus_webui.css:897-909`).

This creates the nested-card dashboard treatment the contract explicitly
rejects and weakens the intended operator-first hierarchy.

**Recommendation:** retain the bounded pairing-code panel, but flatten summary,
connected, recent, audit, stream, and action regions onto the dominant surface.
Use hairline separators and spacing to group rows rather than repeated rounded
containers.

**Human review required:** after flattening, inspect the 60/30/10 balance,
summary hierarchy, row scanability, tab-badge recognition, and native-dialog
visual hierarchy in actual dark/light browser windows.

### 3. Color — 1/4

**BLOCKER — safety actions are unreadable in the light theme**

The same dark-theme danger treatment is used in both schemes:

```css
.danger-button {
  background: rgba(210, 71, 54, 0.16);
  border-color: rgba(210, 71, 54, 0.48);
  color: #ffb4a8;
}
```

(`prometheus_webui.css:540-544`). No light-scheme override is defined
(`prometheus_webui.css:29-46`). Calculating contrast from the declared sRGB
values gives:

- approximately **1.35:1** for `#ffb4a8` over the composited danger background
  on `#fffdfb`;
- approximately **1.19:1** over the composited danger background on `#f3ede6`.

These labels include `Stop control`, `Revoke access`, and `End supervision`,
which are safety-critical 13px controls. Both results are far below the
contract's 4.5:1 text target (`21-UI-SPEC.md:181-186`).

The orange focus/selected-state color also calculates to approximately
**2.79:1** against `#fffdfb` and **2.44:1** against `#f3ede6`, below the 3:1
non-text/focus target. Focus rings use that accent directly
(`prometheus_webui.css:416-424`,
`prometheus_webui.css:1242-1258`). In addition, the implemented light primary
text token is `#211a16` (`prometheus_webui.css:35,43`) rather than the approved
`#1f1a17` (`21-UI-SPEC.md:153-162`).

**Recommendation:** introduce scheme-specific destructive foreground,
background, and border tokens and verify their *composited* contrast. Preserve
the orange accent while adding a contrasting separation ring or other
accessible focus treatment in light mode. Add computed contrast assertions for
every text/background and focus/background pair; a literal token-presence test
is insufficient.

### 4. Typography — 2/4

**WARNING — effective type roles do not match the four-role contract**

The contract assigns system UI to body/controls, Poppins only to display
emphasis, Space Mono to metadata/code, and permits only 12/13/16/20px
(`21-UI-SPEC.md:128-144`). Current code diverges in several proven ways:

- `:root` assigns `Poppins, system-ui, sans-serif` to the entire WebUI, so body
  copy and controls inherit Poppins (`prometheus_webui.css:5-27`).
- the Phase 21 global supervision status inherits `.status { font-size: 11px; }`
  (`prometheus_control_panel.html:18-23`,
  `prometheus_webui.css:828-832`);
- viewer/controller badges use `.control-badge { font-size: 11px; }`
  (`prometheus_webui.js:2236-2244`,
  `prometheus_webui.css:937-945`);
- connected/audit metadata labels use
  `.control-detail dt { font-size: 11px; }`
  (`prometheus_webui.js:818-823`,
  `prometheus_webui.js:2245-2261`,
  `prometheus_webui.js:2357-2375`,
  `prometheus_webui.css:947-968`);
- summary labels use `.control-metric-label { font-size: 11px; }`
  (`prometheus_webui.js:1549-1555`,
  `prometheus_webui.js:2403-2412`,
  `prometheus_webui.css:1066-1074`).

There is also no font declaration loaded by either Phase 21 page. Both HTML
files link only `prometheus_webui.css`
(`prometheus_side_panel.html:7-8`,
`prometheus_control_panel.html:7-8`), that stylesheet contains no
`@font-face`, and the common data source maps the page CSS/JS/images/icons but
not `prometheus_fonts.css` (`prometheus_web_ui.cc:1081-1104`). The packaged
Poppins/Space Mono declarations therefore are not connected to these surfaces,
so named families resolve to fallbacks.

**Recommendation:** restore system UI at the root, load the packaged font
stylesheet through an explicitly mapped resource, scope Poppins to the 20px
display title, retain Space Mono for code/time/metadata, replace every effective
11px supervision role with 12px, and explicitly set 400/800 weights.

**Human review required:** after the resource and role fix, verify actual
Poppins/Space Mono rendering, fallback behavior, truncation, and hierarchy on
each supported platform.

### 5. Spacing — 2/4

**WARNING — effective Phase 21 layout uses values outside the approved tokens**

The permitted margin/padding/gap/inset values are only
4/8/16/24/32/48/64px, with no exceptions
(`21-UI-SPEC.md:93-109`). Phase 21's new rows opt into shared rules that render:

- 12px list gaps (`prometheus_webui.css:891-895`);
- 14px card padding (`prometheus_webui.css:897-909`);
- 12px card-heading gaps (`prometheus_webui.css:921-926`);
- 1px detail-grid gaps and 14px top margins
  (`prometheus_webui.css:947-952`);
- 9px detail padding and 3px description margins
  (`prometheus_webui.css:954-968`);
- 14px action margins (`prometheus_webui.css:983-989`);
- 6px note margins (`prometheus_webui.css:847-853`);
- an inherited 18px section-heading margin
  (`prometheus_webui.css:783-795`).

The 320px path also applies the requested **12px token mismatch** directly to
the active Phase 21 surface: control-panel padding is 12px and nested
`.section-panel` padding is 12px
(`prometheus_webui.css:1332-1350`). Those mobile rules predate the supervision
section, but they are the effective geometry of the Phase 21 UI and still
contradict the approved no-exception spacing system.

**Recommendation:** flatten the rows and add supervision-scoped overrides (or
normalize the shared control styles) so every effective gap, margin, and padding
lands on 4/8/16/24/32/48/64px. Use 16px for mobile surface/section padding unless
the contract is deliberately revised.

**Human review required:** inspect perceived density, wrapped row rhythm,
pairing-panel stability, and action grouping at 320/480/720/1024px and 200%
zoom after token normalization.

### 6. Experience — 3/4

**What is working (code/automated evidence)**

- The tab badge uses exact 12px icons, 4px gaps, three slots, and
  supervision-first compression
  (`prometheus_tab_status_badge.h:28-31`,
  `prometheus_tab_status_badge.cc:250-279`).
- Side-panel stop/end/manage actions preserve authority and focus behavior
  (`prometheus_webui.js:484-555`, `prometheus_webui.js:578-637`).
- Native remote-control dialogs default and initially focus the safe cancel
  action (`prometheus_runtime_dialogs.cc:321-328`,
  `prometheus_runtime_dialogs.cc:375-381`).
- The browser suite checks the four required widths, minimum control height,
  overflow, layout tracks, type size, and 200% zoom
  (`prometheus_web_ui_browsertest.cc:6200-6278`).
- Pairing lifecycle, exact copy, focus restoration, stale confirmation
  cancellation, and Private mode have dedicated browser coverage
  (`prometheus_web_ui_browsertest.cc:5434-6119`).

**WARNING — error/unavailable snapshots do not replace stale presentation**

`renderControlSnapshot()` replaces the normalized supervision model with
`null` when no valid supervision object is supplied
(`prometheus_webui.js:2555-2584`). `renderControlSupervision()` then changes
only the heading and returns without clearing the prior target, rows, summary,
or transient pairing-code presentation
(`prometheus_webui.js:2479-2487`). An `available: false` model likewise proceeds
through the ordinary renderer instead of presenting the required unavailable
state (`prometheus_webui.js:2489-2496`).

This can leave visually stale, apparently enabled controls after a load/service
failure. Event handlers fail closed against the current model, but the visible
state and recovery affordance are misleading.

**Recommendation:** make loading, error, unavailable, Private, and loaded
states mutually exclusive. On authority/load loss, erase transient code
characters, clear old rows and summaries, disable all mutation controls, close
stale dialogs, and render the exact recovery block plus `Refresh diagnostics`.
Add a loaded-to-error browser test, not only initial/error or happy-path tests.

## Prioritized Remediation

1. **BLOCKER:** correct and test light-theme destructive-control contrast,
   including composited backgrounds and safety-action labels.
2. Connect the packaged font stylesheet, restore system body/controls, and
   normalize all effective supervision sizes/weights.
3. Flatten summary/stream/client/recent/audit presentation and normalize its
   spacing tokens, including the 12px mobile container mismatch.
4. Implement complete generic-error and service-unavailable recovery states
   that clear stale UI and transient pairing-code presentation.
5. Run the deferred human visual walkthrough in dark, light, and Private states
   at 320/480/720/1024px plus 200% zoom, including the native badge and dialogs.

## Human Review Checklist

These items cannot be closed from source inspection alone:

- [ ] Dark/light 60/30/10 balance and orange-accent restraint.
- [ ] Flat-list hierarchy and scanability after card removal.
- [ ] Poppins/Space Mono rasterization, fallbacks, wrapping, and truncation.
- [ ] Side-panel density and no-overlap behavior with long localized-safe copy.
- [ ] Tab-badge glyph recognition at normal, compact, and severe compression.
- [ ] Native confirmation-dialog hierarchy and safe-cancel salience.
- [ ] State transitions without perceived layout jump or distracting motion.
- [ ] Private-state muted presentation without appearing disabled by color alone.

No component registry audit is applicable: the approved and implemented stack is
native Chromium Views plus dependency-free packaged WebUI, and no Phase 21
shadcn/third-party component registry is present.
