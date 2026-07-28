---
phase: 22
slug: chrome-extension-ecosystem-and-policy
status: approved
shadcn_initialized: false
preset: none
created: 2026-07-28
reviewed_at: 2026-07-28
---

# Phase 22 — UI Design Contract

> Visual and interaction contract for extension management handoff,
> per-extension Agent policy, extension diagnostics, and compatibility evidence.
> Prepared from the accepted Phase 22 context for verification by
> gsd-ui-checker.

---

## Product and Surface Boundary

Phase 22 extends existing Chromium and Prometheus surfaces. It does not create
a new extension manager or a tenth Control Panel section.

| Surface | Role | Phase 22 contract |
|---------|------|-------------------|
| Chromium extensions toolbar and `chrome://extensions` | Extension lifecycle authority | Install where supported; load unpacked; inspect, reload, enable, disable, and remove extensions through Chromium-owned UI. |
| Control Panel `Permissions & Agents` | Prometheus policy authority | Show live extension subsystem state and safe installed-extension metadata; set `Blocked`, `Read only`, or `Interact`; control Private Agent access separately. |
| Control Panel `Logs & Diagnostics` | Local health | Show bounded extension subsystem readiness, install-path status, and recovery guidance without page content or authority material. |
| Control Panel `Parity Matrix` | Compatibility evidence | Show the five required extension categories with exact `Verified`, `Degraded`, or `Unsupported` evidence and limitations. |
| Browser-owned Views dialog | Sensitive escalation | Confirm a fresh, exact extension grant escalation to `Interact`, with `Keep current access` as the safe default. |

The existing nine-section order is unchanged. `Permissions & Agents` owns
extension policy; `chrome://extensions` remains the lifecycle manager.

The Phase 22 UI must not:

- duplicate extension install, enable/disable, reload, or removal controls;
- imply Chrome Web Store support before a built-app proof passes;
- expose background workers, offscreen documents, hidden hosts, or DevTools
  internals as Agent targets;
- expose or request gateway tokens, Agent sessions, vault authority, extension
  page content, form values, scripts, profile paths, or full installed-extension
  inventories through MCP diagnostics;
- suggest that Chrome permissions imply Prometheus Agent permission;
- claim universal Chrome compatibility from five representative fixtures.

---

## Design System

| Property | Value |
|----------|-------|
| Tool | Existing Prometheus Chromium WebUI and native Views only |
| Preset | Not applicable |
| Component library | Dependency-free packaged HTML/CSS/minimal JavaScript plus Chromium Views dialogs |
| Icon library | Existing packaged Font Awesome Free subset through the Prometheus semantic icon resolver |
| Font | System UI for body/controls, Space Mono for metadata, Poppins for the single surface title |
| Radius | Existing 8px maximum; pills only for compact status labels |
| Remote resources | None |

Do not add React, shadcn, another component registry, remote fonts/icons,
extension-provided decorative imagery, a second token vocabulary, or a new
card system. Extension rows are flat list rows separated by hairlines. Use one
generic extension glyph; do not render untrusted extension icons in the
Prometheus policy list.

### Visual hierarchy

Within `Permissions & Agents`, order the extension content as:

1. `Extension policy` heading and explanatory copy;
2. live subsystem/install-path summary;
3. `Manage extensions` action;
4. installed-extension policy list;
5. selected extension detail and grant controls;
6. Private Agent-access control when eligible;
7. bounded recovery or limitation copy.

The selected extension and its current grant are the focal point. Subsystem
status is compact context, not a dashboard of counters. Use no nested cards,
large metrics, decorative gradients, avatars, extension logos, or connection
maps.

---

## Spacing Scale

These are the only values permitted for margin, padding, gap, and inset in new
or touched Phase 22 UI:

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4px | Icon-to-label and compact inline gaps |
| sm | 8px | Status-label internals, adjacent controls, row-cell gaps |
| md | 16px | Section padding, field groups, narrow-screen page inset |
| lg | 24px | Section separation and dialog padding |
| xl | 32px | List/detail separation and passive row minimum |
| 2xl | 48px | Minimum interactive target and action row |
| 3xl | 64px | Major empty-state separation only |

Exceptions: none. Values such as 1px borders, icon/font sizes, column widths,
and responsive breakpoints are dimensions, not spacing exceptions. In
particular, do not inherit or introduce 3px, 6px, 9px, 12px, 14px, or 18px
margin, padding, or gap values on the extension-policy path.

Stable dimensions:

- buttons, links styled as controls, radio choices, selectable rows, and icon
  hit targets: 48px minimum;
- passive compatibility and diagnostic rows: 32px minimum and allowed to grow
  for wrapped copy;
- generic extension glyph: 16px inside a 48px row target;
- status labels: intrinsic width with a 24px minimum line box;
- grant changes, refreshes, errors, and theme swaps must not move the selected
  row, grant controls, or `Manage extensions` action.

---

## Typography

Phase 22 uses exactly these four sizes and two weights:

| Role | Family | Size | Weight | Line Height | Usage |
|------|--------|------|--------|-------------|-------|
| Metadata | Space Mono / system monospace | 12px | 400 | 16px | ID suffix, source, manifest version, build/revision, typed status |
| Body | system UI | 13px | 400 | 20px | Descriptions, rows, helper/error text, controls |
| Heading | system UI | 16px | 800 | 20px | Subsection, extension, dialog, and state headings |
| Display | Poppins / system fallback | 20px | 800 | 24px | Existing Control Panel surface title only |

Buttons, selected navigation, grant labels, and emphasized status use the Body
size at weight 800. Poppins must not be applied globally to body text or
controls. No Phase 22 role may resolve to 11px. Letter spacing is zero.

Long sanitized extension names ellipsize visually after one line in list rows
and wrap to at most two lines in detail headings. The accessible name exposes
only the same bounded sanitized name, never raw markup or hidden authority.

---

## Color

Use the existing warm 60/30/10 palette, with scheme-specific focus and danger
treatments that meet contrast after compositing:

| Role | Dark | Light | Usage |
|------|------|-------|-------|
| Dominant (60%) | `#141110` | `#fffdfb` | Page background and flat content |
| Secondary (30%) | `#1d1816` | `#f3ede6` | Section rail, selected detail, inputs |
| Tertiary | `#26201d` | `#f1ebe4` | Hover and selected-row fill |
| Primary text | `#f6efe9` | `#1f1a17` | Main readable text |
| Secondary text | `#d2c1b4` | `#6a584d` | Supporting copy |
| Muted text | `#a99283` | `#75645a` | Inactive metadata and timestamps |
| Interaction / brand | `#ff6b35` | `#7a3215` | Scheme-specific selection markers, outlines, text-link treatment, and brand cues |
| Filled accent surface | `#ff6b35` | `#ff6b35` | Enabled filled primary control only; pair with `#1f1a17` text/icons |
| Focus outer ring | `#ff8c42` | `#7a3215` | Scheme-specific 2px outer keyboard ring |
| Healthy | `#5fc6a6` | `#176b55` | `Ready` and `Verified` text/icon with label |
| Warning | `#e2b459` | `#7b5414` | `Degraded`, stale, and store limitation |
| Destructive text | `#ffb4a8` | `#7a1f18` | Blocking error and destructive text |
| Destructive surface | `#3a1c19` | `#fbe9e6` | Bounded destructive state/confirmation only |
| Destructive border | `#d24736` | `#a7352b` | Bounded destructive outline only |

The scheme-specific interaction color is reserved for:

- the selected Control Panel section marker;
- the selected extension row marker;
- the enabled `Manage extensions` primary link/action;
- the selected grant choice only when it is not destructive;
- an inner brand-colored focus cue paired with the scheme-specific outer ring;
- PM/FSB brand treatment.

In light theme, selection markers, selected-choice outlines, focus cues, and
text-link treatment use `#7a3215`. The required light interaction pairs are
`#7a3215` on `#fffdfb` (9.0:1), `#7a3215` on `#f3ede6` (7.9:1), and
`#7a3215` on `#f1ebe4` (7.7:1). Light-theme `#ff6b35` is permitted only as the
background of an enabled filled primary control, with `#1f1a17` text and icons
(6.1:1). It must not be used as light-theme text, a text link, marker, border,
outline, glyph, or focus cue. PM/FSB brand treatment uses the scheme-specific
interaction color unless it is the declared orange filled-control pair.

`Interact` is not colored as healthy merely because it is selected. `Blocked`
is a neutral safe default, not an error. Destructive colors are reserved for a
blocking subsystem failure or explicit destructive upstream action; grant
revocation uses ordinary neutral controls.

Every state has visible text. Body text must meet WCAG 4.5:1 and focus,
selection, borders carrying state, and icons must meet 3:1 against their actual
composited backgrounds. Automated tests must calculate every declared pair in
both themes, including the three light-theme `#7a3215` interaction pairs and
the `#1f1a17` on `#ff6b35` filled-control pair; literal token-presence checks
are insufficient.

---

## Copywriting Contract

| Element | Exact copy |
|---------|------------|
| Section heading | `Extension policy` |
| Section body | `Choose which visible extension pages Prometheus Agents may read or interact with. Chrome permissions do not grant Agent access.` |
| Primary action | `Manage extensions` |
| Empty heading | `No extensions installed` |
| Empty body | `Install or load an extension in Chromium’s manager, then return to set Agent access.` |
| Loading | `Loading extension policy` |
| Generic error heading | `Prometheus could not load extension policy` |
| Generic error body/action | `Refresh diagnostics, then try again.` / `Refresh diagnostics` |
| Unavailable heading | `Extension system unavailable` |
| Unavailable body | `This build cannot initialize Chromium’s extension subsystem. Review diagnostics and the documented build limitations.` |
| Web Store unverified | `Chrome Web Store installation is not verified in this build. Use developer mode to load an unpacked extension.` |
| Reverse-boundary helper | `Extensions cannot use Chrome permissions to gain Prometheus Agent, vault, or internal-page access.` |
| Interact confirmation title | `Allow Agent interaction with {extension}?` |
| Interact confirmation body | `Prometheus Agents will be able to use approved read and interaction actions on this extension’s visible pages. This does not allow scripts, hidden contexts, vault access, or extension access to Prometheus.` |
| Confirmation actions | `Keep current access` / `Allow interaction` |
| Stale confirmation | `The extension list changed. Review the current extension and try again.` |

### Grant labels and descriptions

| Grant | Exact label | Exact helper |
|-------|-------------|--------------|
| Blocked | `Blocked` | `Agents cannot read or interact with this extension.` |
| Read only | `Read only` | `Agents may read approved visible extension pages but cannot change them.` |
| Interact | `Interact` | `Agents may use approved typed actions on visible extension pages. Scripts and hidden contexts remain blocked.` |

### Diagnostic and typed-error recovery

| Condition | Visible copy |
|-----------|--------------|
| Extension not found | `Extension no longer available. Refresh the policy list.` |
| Surface blocked | `Extension surface blocked. Change Agent access from the local Prometheus control panel.` |
| Read denied | `Read access is blocked for this extension.` |
| Interaction denied | `Interaction is blocked for this extension. Choose Interact locally, then retry.` |
| Unsupported context | `This extension context is not available to Agents. Open a visible extension page and retry.` |
| Script denied | `Scripts are blocked on extension surfaces. Use an approved read or interaction action.` |
| Stale policy | `Extension policy changed before the action ran. Refresh the target and try again.` |
| Private denied | `Agent access is blocked for this extension in Private mode.` |

Copy is direct, sentence case, and recovery-oriented. Never describe an
extension as safe, trusted, verified, or compatible solely because it is
installed, enabled, store-sourced, or granted `Interact`.

---

## Browser-Owned UI Data Contract

The Control Panel receives a closed sanitized snapshot. It may render:

- subsystem state: `Ready`, `Degraded`, or `Unavailable`;
- install path: `Developer mode available`, `Web Store verified`, or
  `Web Store unverified`;
- bounded sanitized extension name, enabled state, source category, manifest
  version, and ID suffix;
- ordinary Private eligibility reported by Chromium;
- regular and Private Prometheus Agent grants;
- a browser-issued row ordinal and snapshot generation;
- compatibility category/status summaries and safe limitation copy.

The renderer must not receive or retain:

- gateway bearer material, Agent session IDs, policy-service handles, profile
  paths, background-host identifiers, document tokens, or hidden-context
  handles;
- extension page content, DOM snapshots, form values, scripts, network request
  bodies, storage contents, or permission-derived secrets;
- a caller-supplied extension name, ID, origin, grant, or health claim.

Grant messages contain only the row ordinal, snapshot generation, closed target
grant, and closed Private-mode intent. Native code resolves the exact current
extension ID from the same generation before presenting confirmation and again
before applying the change. A refresh, install, removal, replacement, enable
change, or generation change dismisses a pending confirmation.

External MCP diagnostics retain the existing `extensions` key but return only
status, bounded reason, and next action. They never enumerate installed
extensions or grants.

---

## Permissions & Agents Interaction Contract

### Summary and lifecycle handoff

The summary line shows:

- `Extension system: Ready`, `Extension system: Degraded`, or
  `Extension system: Unavailable`;
- `Install path: Developer mode`, `Install path: Web Store verified`, or
  `Install path: Web Store unverified`;
- `{n} installed` and `{n} Agent-enabled` only in local Control Panel UI.

`Manage extensions` opens or focuses Chromium’s native
`chrome://extensions` page. It never performs install, reload, enable, disable,
or removal itself. When the user returns, request a fresh policy snapshot and
preserve selection only if the exact extension still exists.

### Flat list and detail

Each extension list row presents, in order:

1. generic extension glyph and sanitized name;
2. enabled/disabled text;
3. `Manifest V3`, `Manifest V2`, or `Manifest unknown`;
4. source label;
5. current Agent grant;
6. Private summary: `Private extension off`, `Private Agent blocked`,
   `Private Agent read only`, or `Private Agent interact`.

Selecting a row opens a detail pane with the same metadata, the three-choice
`Agent access` radio group, Private access controls, and the reverse-boundary
helper. The full extension ID and permission manifest remain available in
Chromium’s manager, not duplicated here.

Changing `Blocked` to `Read only`, or reducing any grant, may apply directly
after a fresh native revalidation. Any transition to `Interact` opens the
browser-owned confirmation. `Keep current access` is the safe default and
initially focused action. Choosing it, pressing Escape, closing the dialog,
focus loss caused by destruction, stale generation, extension removal, profile
shutdown, and Private-context loss all dismiss the confirmation without
changing access.

While a mutation is pending, disable only that extension’s grant controls and
show `Updating policy`. Do not optimistically change the row. Reconcile from a
fresh browser-owned snapshot after completion. On failure, retain the prior
grant and show one typed recovery message.

### Private Agent access

- Ordinary Chromium Private eligibility is read-only here and managed through
  `chrome://extensions`.
- Private Agent access defaults to `Blocked` and never inherits the regular
  grant.
- Private Agent controls appear only when Chromium reports the extension as
  eligible in Private windows.
- A Private grant cannot exceed the regular grant. Private `Interact` uses the
  same confirmation with `in Private windows` added to the title.
- Disabling ordinary Private eligibility immediately collapses Private Agent
  access to `Blocked` and removes the editable Private controls after the fresh
  snapshot.

---

## Diagnostics and Compatibility Contract

`Logs & Diagnostics` shows one flat `Extensions` component row:

| State | Summary | Recovery |
|-------|---------|----------|
| Ready | `Extension system ready` | `Manage extension lifecycle in Chromium and Agent access in Permissions & Agents.` |
| Degraded | `Extension system degraded` | Show one bounded proven limitation, such as unverified Web Store support, plus the documented developer path. |
| Unavailable | `Extension system unavailable` | `Review the build configuration and extension subsystem diagnostics.` |

The `Parity Matrix` adds exactly five extension-category rows:

1. `Password manager`
2. `Ad blocker`
3. `Productivity content script`
4. `Side panel and tooling`
5. `Developer extension`

Each row contains status (`Verified`, `Degraded`, or `Unsupported`), exact
fixture/version, Manifest version, install source, behaviors exercised,
Chromium/Prometheus revision, last verification time, and a bounded limitation.
Do not show a single global `Chrome-compatible` badge.

---

## Responsive, Keyboard, and Accessibility Contract

Required automated widths are 320, 480, 720, and 1024 CSS pixels, plus 200%
zoom.

- At 1024px and above, use a 40/60 flat list/detail split within the existing
  section content.
- Below 1024px, list and detail use one semantic column; the selected detail
  follows the list and remains reachable without horizontal scrolling.
- At 479px and below, use 16px surface/section padding. Grant choices and
  actions stack full width and remain at least 48px high.
- Names, limitation copy, and error guidance wrap; metadata may ellipsize only
  when the same bounded value is available through the accessible name.
- No policy action is hover-only, icon-only without an accessible name,
  drag-only, color-only, or dependent on horizontal scrolling.

Keyboard order is:

1. `Manage extensions`;
2. extension filter/search if present;
3. extension list rows;
4. selected extension heading;
5. regular grant choices;
6. Private grant choices when present;
7. recovery action.

Arrow keys may move within a radio group; Tab leaves the group. Selecting a row
does not move focus automatically. After confirmation:

- activating `Keep current access`, pressing Escape, or closing the dialog
  returns focus to the originating `Interact` choice;
- success returns focus to the updated grant group;
- stale dismissal returns focus to the matching row when it still exists,
  otherwise to the extension-list heading.

Use a polite live region for one mutation result or subsystem-status change.
Do not announce the entire refreshed list. Reduced-motion mode uses no pulsing,
shimmer, or animated status transition.

---

## State and Failure Matrix

| State | Required presentation |
|-------|-----------------------|
| Loading | Stable list/detail skeleton or `Loading extension policy`; mutation controls absent. |
| Ready, empty | Canonical empty heading/body and `Manage extensions`. |
| Ready, populated | Summary, flat rows, selected detail, truthful grants. |
| Degraded | Keep safe available controls; show one warning and exact recovery. |
| Unavailable | Clear all prior rows/details and show canonical unavailable state. |
| Load error | Clear stale rows/details, show canonical generic error and `Refresh diagnostics`. |
| Mutation pending | Disable only current row controls; show `Updating policy`; preserve old grant until fresh success. |
| Mutation denied | Preserve old grant; show typed recovery; focus remains local. |
| Extension removed | Dismiss the dialog, abort the mutation, clear detail, refresh the list, and announce removal. |
| Private eligibility lost | Collapse Private Agent grant to `Blocked`, remove controls, announce the change. |

Loading, error, unavailable, and loaded states are mutually exclusive. Stale
extension rows or apparently enabled grant controls must never remain visible
after authority or subsystem loss.

---

## Registry Safety

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| shadcn official | None | Not applicable |
| Third-party registries | None | No external blocks permitted |

The active stack is native Chromium Views plus dependency-free packaged WebUI.
No component registry initialization or third-party block review is required.

---

## Verification Contract

Automated UI evidence must cover:

- exact section placement with no tenth top-level section;
- canonical copy and all mutually exclusive loading/empty/data/error states;
- flat list/detail layout at 320/480/720/1024px and 200% zoom;
- 48px controls, no horizontal overflow, and no forbidden spacing values;
- exact 12/13/16/20 typography with system body and no effective 11px roles;
- computed dark/light text, destructive, selection, and focus contrast;
- keyboard traversal, radio-group semantics, safe-default confirmation focus,
  Escape/`Keep current access`, focus restoration, and polite announcements;
- generation-bound confirmation dismissal and no optimistic grant display;
- Private grant non-inheritance and loss handling;
- structural absence of extension page content and authority fields;
- inventory-free external diagnostics and exact five-row compatibility matrix;
- no remote assets, no new component framework, and no duplicated lifecycle
  controls.

Human review remains useful for hierarchy, perceived density, name truncation,
focus salience, and dark/light polish. It is non-blocking and belongs in the
Phase 24 consolidated screenshot walkthrough.

---

## Checker Sign-Off

- [x] Dimension 1 Copywriting: PASS
- [x] Dimension 2 Visuals: PASS
- [x] Dimension 3 Color: PASS
- [x] Dimension 4 Typography: PASS
- [x] Dimension 5 Spacing: PASS
- [x] Dimension 6 Registry Safety: PASS

**Approval:** approved 2026-07-28
