---
phase: 15
slug: chromium-ui-shell-compact-chrome-and-tab-model
status: approved
shadcn_initialized: false
preset: none
created: 2026-07-07
verified: 2026-07-07
---

# Phase 15 - UI Design Contract

> Visual and interaction contract for the Chromium-native Prometheus browser
> chrome, compact tab layout, tab-management entry points, side-panel toggle,
> and tab/session state affordances.

---

## Design System

| Property | Value |
|----------|-------|
| Tool | none |
| Implementation | Chromium desktop Views (`BrowserView`, `ToolbarView`, `LocationBarView`, `TabStrip`, `HorizontalTabStripRegionView`, `SidePanelCoordinator`) |
| Component library | Chromium Views and existing Chrome browser UI primitives |
| Icon library | Phase 14 Prometheus Font Awesome resolver (`PrometheusAction`) with `ui::ImageModel::FromVectorIcon`; no remote icons |
| Font | Native system UI for chrome/body labels; Poppins only for brand lockups if needed; Space Mono only for URL-like metadata, version tags, compact status IDs |
| Tokens | Phase 14 `kColorPrometheus*` color ids; no new ad hoc chrome color literals |

The React prototype under `.planning/design/prometheus-browser/` is the visual
reference only. Shipping UI must be Chromium-native Views, not a WebUI toolbar or
embedded web shell.

---

## Anatomy and Layout

### Compact Top Chrome

- Height target: 50px, matching the canonical prototype's `--chrome-h`.
- Left cluster: native macOS traffic lights remain owned by the platform frame,
  followed by Back, Forward, and Side Panel toggle.
- Center cluster: tab strip with pinned icon tabs, regular tabs, active tab as
  address/search, and New Tab.
- Right cluster: fixed utility buttons: FSB/agent, Search Tabs or All Tabs,
  theme/profile/menu as Chromium permits.
- Compact mode must preserve a minimum active address/search visual width of
  240px at standard widths and degrade gracefully at narrow widths by
  compressing inactive tabs first.
- Separate layout remains available and must keep Chromium's conventional tab
  strip and toolbar behavior.

### Responsive Widths

| Width | Contract |
|-------|----------|
| 800px narrow | Active address/search remains readable; Search Tabs and Side Panel toggle remain reachable; inactive tabs compress or overflow before fixed controls disappear. |
| 1280px standard | Pinned tabs, active tab/address, 4-6 regular tabs, side panel toggle, FSB button, Search Tabs, and menu fit without overlap. |
| 1728px+ wide | Tabs can expand, but row height, icon sizes, focus rings, and status affordance placement remain stable. |

### Side Panel Toggle

- Toggle is a 32px visual icon button with a stable accessible name: `Toggle
  Prometheus side panel`.
- The button uses the bundled sidebar/table-columns glyph from
  `PrometheusAction` if available.
- Active/open state uses `kColorPrometheusAccentSoft2` background and
  `kColorPrometheusAccent` foreground.
- The side panel content and four modes are Phase 16/20 scope; this phase owns
  only the native open/collapse entry point and layout integration.

### Tab Search, Overview, and Quick Switch

- Search Tabs remains a native/top-chrome entry point, never hidden behind
  compact tab overflow.
- Reuse Chromium's tab search bubble stack where practical.
- Quick switch favors MRU ordering. Search/overview can group by Chromium tab
  group while preserving active/source-order signals.
- Popups must have fixed row heights and no text overlap when titles, URLs,
  group labels, or status glyphs are long.

---

## Spacing Scale

Declared values are multiples of 4 unless inherited from Chromium native frame
metrics.

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4px | Icon-to-label gaps, badge gaps |
| sm | 8px | Button internal padding, tab chip gaps, toolbar cluster gaps |
| md | 16px | Group-to-group separation, popup row horizontal padding |
| lg | 24px | Popup section separation and menu body padding |
| xl | 32px | Standard icon button visual square, tab-search row height |
| chrome | 50px | Compact top chrome height target |

Exceptions: platform traffic-light placement and native window drag regions may
use Chromium/macOS frame metrics. Do not override platform frame metrics for
visual symmetry.

---

## Typography

| Role | Family | Size | Weight | Line Height |
|------|--------|------|--------|-------------|
| Toolbar label | system UI | 12px | 500 | 1.25 |
| URL / search text | system UI | 12.5px | 400 | 1.3 |
| Popup row title | system UI | 13px | 500 | 1.35 |
| Popup row metadata | Space Mono or system UI | 11px | 400 | 1.25 |
| Compact status tooltip | system UI | platform default | platform default | platform default |

Use Poppins only for Prometheus brand lockups or future side-panel headers. Do
not use display-scale typography inside compact chrome.

---

## Color

All new Prometheus chrome surfaces consume Phase 14 token ids.

| Role | Token | Usage |
|------|-------|-------|
| Chrome background | `kColorPrometheusChrome`, `kColorPrometheusChrome2` | Top toolbar and compact chrome base |
| Active tab | `kColorPrometheusTabActive` | Active tab/address chip |
| Idle tab | `kColorPrometheusTabIdle` | Inactive tab background |
| Hover tab | `kColorPrometheusTabHover` | Tab/button hover state |
| Primary text | `kColorPrometheusText` | Active URL/title and enabled controls |
| Secondary text | `kColorPrometheusText2` | Inactive tab labels and metadata |
| Tertiary text | `kColorPrometheusText3` | URL scheme, placeholder, disabled metadata |
| Hairline/border | `kColorPrometheusHairline`, `kColorPrometheusBorder` | Toolbar divider, tab outline, popup dividers |
| Accent | `kColorPrometheusAccent` | Active side panel toggle, FSB button active state, focus ring, agent/supervision active glyphs |
| Accent soft | `kColorPrometheusAccentSoft`, `kColorPrometheusAccentSoft2` | Active/selected backgrounds only |

Accent is reserved for: active Prometheus side panel state, FSB/agent active
state, focus ring, selected/active tab state where required, supervision/agent
status glyphs, and PM/FSB brand lockups. Do not use orange for every toolbar
button, every hover state, or passive metadata.

Allowed bounded status colors:

| State | Treatment |
|-------|-----------|
| Agent active | Accent glyph/badge plus tooltip and accessible name |
| Supervised | Accent or verified-green glyph/badge plus tooltip and accessible name |
| Warning/partial health | Warm warning chip/glyph, not full-row orange |
| Blocked/unsafe | Destructive chip/glyph only for blocking/error states |
| Private/security/audio/extension | Chromium-native icon semantics plus Prometheus token-compatible color where possible |

---

## Interaction Contract

### Layout Mode

- Default startup remains conventional/separate until compact mode is explicitly
  enabled or the planner determines the feature flag can default on safely.
- Switching between compact and separate must not lose the active tab, current
  omnibox text, focus, tab groups, or side panel state.
- Theme switching must rebuild/repaint compact chrome without layout jump.

### Active Tab as Address/Search

- In compact mode the active tab chip replaces its title label with
  address/search content.
- Placeholder copy for empty/new-tab state: `Search or enter address`.
- The URL scheme/lock/security affordance remains visible where Chromium already
  exposes it; do not fake security state.
- Editing, Cmd-L, Escape, reload, and navigation must preserve Chromium omnibox
  behavior.

### Tab Actions

- Context menus expose existing Chromium actions where supported: New Tab to
  Right, Duplicate, Pin, Mute, Add to Group, Move to Window, Close, Close Others,
  Close Tabs to Right.
- Unload/suspend should use Chromium discard/performance-manager behavior and
  user-facing wording `Unload Tab` only if the implementation actually discards
  or suspends the tab.
- Destructive or state-changing actions should show available owner/supervision
  status in the initiating row, menu, confirmation, or tooltip.

### Accessibility

- Every new button needs an accessible name matching the visible or tooltip
  command.
- Icon-only buttons require tooltips.
- Focus order follows visual order: navigation cluster, tab strip, new tab,
  right tools, menu.
- Keyboard shortcuts remain Chromium/macOS standard unless a Prometheus-specific
  command is explicitly introduced and tested.

---

## Copywriting Contract

| Element | Copy |
|---------|------|
| Side panel toggle tooltip | Toggle Prometheus side panel |
| FSB/agent button tooltip | Ask FSB |
| Tab search tooltip | Search tabs |
| Tab overview tooltip | Tab overview |
| Quick switch command | Quick switch tabs |
| New tab placeholder | Search or enter address |
| Empty tab search heading | No matching tabs |
| Empty tab search body | Try a different title, URL, or group name. |
| Unload action | Unload Tab |
| Duplicate action | Duplicate Tab |
| Detach/move action | Move Tab to New Window |

Status tooltip patterns:

| State | Copy |
|-------|------|
| Unowned | No agent owns this tab |
| Owned | Owned by %1 |
| Automation active | Agent is working in this tab |
| Supervised | Supervision active |
| Health OK | Tab health OK |
| Health warning | Tab needs attention |

Do not describe features or keyboard shortcuts in persistent in-app text. Put
command names in menus/tooltips only.

---

## Verification Contract

### Automated Checks

- Preference/feature tests for compact/separate layout mode.
- Views/browser tests proving the side panel toggle button exists, has the
  expected accessible name, and toggles `SidePanelCoordinator` visibility.
- Browser/UI tests proving Search Tabs remains reachable in compact mode.
- Tab model tests or browser tests for duplicate, detach/move, close/restore,
  group, reorder, and unload/discard paths used by Prometheus entry points.
- Color/theme tests proving compact chrome consumes `kColorPrometheus*` tokens
  and repaints on dark/light changes.
- Stub-state tests proving owner/automation/supervision/health defaults render
  safe values without trusting caller-provided labels.

### Rendered Checks

Record evidence at 800px, 1280px, and 1728px+:

- No text/icon overlap in compact top chrome.
- Active address/search field remains readable.
- Search Tabs, Side Panel toggle, FSB/agent button, New Tab, and menu are
  reachable.
- Focus rings are visible and not clipped.
- Pinned tabs and group indicators retain stable height.
- Dark/light theme switch changes colors without moving controls.
- Long page titles and long URLs truncate cleanly.

### Carry-Forward Checks

Carry Phase 7 compact chrome visual checks into this phase's Chromium
verification. Do not retire a carried check unless the Chromium equivalent no
longer exists and the rationale is documented in the preservation ledger.

---

## Registry Safety

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| shadcn official | none | not applicable |
| third-party registries | none | not applicable |
| Web UI templates | none for top chrome | Phase 15 is native Views; WebUI is Phase 16 except reused Chromium tab-search internals |

---

## Checker Sign-Off

- [x] Dimension 1 Copywriting: PASS
- [x] Dimension 2 Visuals: PASS
- [x] Dimension 3 Color: PASS
- [x] Dimension 4 Typography: PASS
- [x] Dimension 5 Spacing: PASS
- [x] Dimension 6 Registry Safety: PASS

**Approval:** approved 2026-07-07
