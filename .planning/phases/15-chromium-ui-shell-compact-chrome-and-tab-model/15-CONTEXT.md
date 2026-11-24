# Phase 15: Chromium UI Shell, Compact Chrome, and Tab Model - Context

**Gathered:** 2026-07-07
**Status:** Ready for planning
**Mode:** Autonomous smart discuss defaults accepted

<domain>
## Phase Boundary

Phase 15 rebuilds the Prometheus browser chrome and advanced tab workflows on
Chromium-native desktop UI primitives. It owns compact/separate chrome layout,
tab strip integration, tab search/overview/quick switch entry points, side panel
toggle placement, tab groups/actions, and visible tab/session state in native
Views. It does not build the Phase 16 WebUI pages, the Phase 17 native agent
service, or the Phase 20 runtime/control-panel internals, though it must leave
stable hooks and stub state for those later phases.

</domain>

<decisions>
## Implementation Decisions

### Compact Chrome Shape
- Use Safari compact mode as the interaction reference, not the visual clone:
  compact mode should keep tabs in the top chrome and make the active tab feel
  like the address/search surface while retaining Prometheus's warm, sparse,
  agent-aware identity.
- Keep Chromium's conventional horizontal tab strip as the default fallback and
  preserve a user-switchable separate layout. Compact mode can be introduced
  behind a Prometheus-owned pref/feature gate until visual and interaction
  checks pass.
- Prefer adapting Chromium's existing `BrowserView`, `ToolbarView`,
  `HorizontalTabStripRegionView`, `TabStrip`, and `LocationBarView` layout
  boundaries over replacing the browser frame. The planner may add Prometheus
  wrapper views where needed, but should preserve Chromium-owned focus,
  accelerators, drag regions, accessibility, and window-frame behavior.
- At narrow widths, protect the active location/search affordance and fixed
  command buttons first; compress or overflow inactive tabs before hiding tab
  search, side panel, or safety/status affordances.

### Toolbar and Entry Points
- Place the Prometheus side panel toggle as a stable native toolbar button with
  a keyboard path, using the existing Chromium side-panel coordinator/pinning
  architecture where practical. The side panel's content is Phase 16/20 scope,
  but the open/collapse chrome affordance is Phase 15 scope.
- Keep Tab Overview, Search Tabs, and quick switch as native/top-chrome entry
  points. Reuse Chromium's existing tab search bubble/WebUI host and command
  controller where possible rather than inventing a second tab picker stack.
- Use the Phase 14 `kColorPrometheus*` tokens and `PrometheusAction` icon
  resolver for all new Prometheus native controls. Do not add ad hoc colors,
  remote icons, SVG-only toolbar assets, or a separate icon system.
- Keep macOS expectations intact: traffic lights remain native, standard
  shortcuts such as Cmd-L/Cmd-T/Cmd-W/Cmd-Shift-T remain authoritative, toolbar
  focus rings/accessibility names are required, and draggable titlebar regions
  must not be broken by compact layout changes.

### Agent and Tab State Affordances
- Show agent ownership, active automation, supervision, tab health,
  audio/private/security, and extension-relevant state as compact glyph/status
  affordances, not verbose text. Tooltips and accessible names should carry the
  details.
- Until Phase 17 provides the real native agent service, use explicit stub
  state with safe defaults: no owner, automation off, supervision off, health
  OK, no secrets, and no caller-provided labels trusted for UI display.
- Destructive or context-changing tab actions should surface owner/supervision
  state before execution when the state is available. This carries forward the
  Phase 7 rule that close/unload/detach/group actions must not obscure agent
  ownership or supervision.
- Avoid cluttering the active tab/address field. Status affordances can attach
  to tab chips, group headers, toolbar buttons, or tab search rows, but the
  location text must stay readable at narrow, standard, and wide widths.

### Advanced Tab Management
- Reuse Chromium's `TabStripModel`, `TabGroupModel`, tab context menu commands,
  tab search bubble, tab group visuals, and existing browser commands for close,
  restore, duplicate, detach/move-to-window, reorder, pin, mute, and group flows.
  Only add Prometheus-specific adapters where an existing Chromium path does not
  expose the required state or entry point.
- Preserve Chromium tab group semantics rather than importing Falkon data
  structures. Prometheus group labels, colors, collapsed state, overview/search
  grouping, and side-panel tab summaries should map to Chromium group model
  primitives.
- Treat unload/suspend as Chromium discard/performance-manager behavior where
  available, with clear user-facing wording and verification that the action
  does not bypass tab ownership/supervision safeguards once those later services
  exist.
- Keep tab overview/search and quick switch ordering predictable: search filters
  by title/URL/group state; quick switch favors MRU behavior; overview can group
  by tab group while preserving active-tab and source-order signals.

### Verification Priorities
- Phase 15 must produce automated coverage for the new native preferences,
  layout switching, toolbar button visibility, tab search/overview entry points,
  group/action routing, and stub-state rendering.
- Add rendered/interactive UI verification across narrow, standard, and wide
  desktop windows. Required checks: no overlap, active location/search minimum
  width, reachable Search Tabs, reachable side panel toggle, visible focus
  states, stable row heights, and no layout jump on theme switch.
- Carry forward unresolved Phase 7 visual checks into Chromium-native
  verification instead of marking them retired. Product-layout checks from the
  preservation ledger remain open until the corresponding Chromium surfaces are
  exercised.
- Chromium source edits must stay in `.context/chromium/src` on a named
  Prometheus phase branch and be exported as patches into the root planning repo,
  following Phase 12 patch discipline.

### the agent's Discretion
- Exact pref names, feature flag names, class names, button ordering within the
  existing toolbar constraints, and the split between unit, browsertest, and
  interactive UI tests are at the planner's discretion.
- The planner may choose whether compact chrome lands as one larger layout plan
  or multiple staged plans, provided separate layout remains usable throughout.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and requirements
- `.planning/ROADMAP.md` section "Phase 15: Chromium UI Shell, Compact Chrome,
  and Tab Model" - phase goal, planned work, and success criteria.
- `.planning/REQUIREMENTS.md` UX-01 through UX-07 - compact chrome, separate
  layout, tab management, state affordances, side-panel toggle, visual checks,
  and macOS behavior requirements.
- `.planning/PROJECT.md` - v2.0 Chromium migration goal, product thesis,
  licensing boundary, and agent-native browser principles.

### Prior Prometheus decisions
- `.planning/phases/07-compact-safari-style-browser-chrome-and-advanced-tab-managem/07-CONTEXT.md`
  - v1 compact chrome intent: Safari-inspired compact mode, separate fallback,
  advanced tab management, and agent/supervision state.
- `.planning/phases/07-compact-safari-style-browser-chrome-and-advanced-tab-managem/07-VALIDATION.md`
  - visual and interaction checks to carry forward into Chromium-native UI.
- `.planning/phases/08-native-fsb-plus-settings-side-panel-and-feature-parity-matri/08-CONTEXT.md`
  - side panel/control panel split, four side-panel modes, and settings/control
  placement.
- `.planning/phases/14-asset-and-design-system-port/14-CONTEXT.md` - native
  token/icon/font/resource decisions Phase 15 must consume.
- `.planning/preservation/FALKON-TO-CHROMIUM-PRESERVATION.md` - migration
  contract, deferred visual-check ledger, and no-GPL-copying boundary.

### Chromium primitives
- `.planning/chromium/CHROMIUM-CHECKOUT.md` - pinned revision, branch/export
  discipline, GN args, and build/test gate conventions.
- `.context/chromium/src/chrome/browser/ui/views/frame/browser_view.h` -
  desktop browser window, top container, tab strip, side panel, and frame
  integration surface.
- `.context/chromium/src/chrome/browser/ui/views/toolbar/toolbar_view.h` -
  toolbar/location bar/buttons and tab-search button access.
- `.context/chromium/src/chrome/browser/ui/views/frame/horizontal_tab_strip_region_view.*`
  - horizontal tab strip region and tab-search placement.
- `.context/chromium/src/chrome/browser/ui/views/tabs/` and
  `.context/chromium/src/chrome/browser/ui/tabs/` - tab strip rendering,
  `TabStripModel`, tab groups, context menus, commands, and tests.
- `.context/chromium/src/chrome/browser/ui/views/tab_search_bubble_host.*` and
  `.context/chromium/src/chrome/browser/ui/webui/tab_search/` - existing tab
  search/overview bubble stack.
- `.context/chromium/src/chrome/browser/ui/views/side_panel/` - native side
  panel coordinator, registry, header, toolbar pinning, and animation paths.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `BrowserView` already owns the browser frame, top container, tab strip,
  toolbar, side panel animation content, focus, accelerators, and widget hooks.
- `ToolbarView` already owns the location bar, tab search button, pinned toolbar
  actions, overflow behavior, and standard toolbar command integration.
- `TabStripModel` and `BrowserTabStripController` already support tab groups,
  tab movement, pinning, close, duplicate, detach/move-to-window, mute, and group
  visual updates.
- `TabSearchBubbleHost` and `chrome://tab-search.top-chrome` already provide a
  top-chrome tab search bubble with browsertest coverage.
- `SidePanelCoordinator` and `SidePanelEntry` already provide the side-panel
  visibility and content-management path.
- Phase 14 provides `kColorPrometheus*` color ids, resource-backed Prometheus
  assets, and the Font Awesome based `PrometheusAction` icon resolver.

### Established Patterns
- Chromium desktop UI changes should preserve existing command-controller,
  focus, accessibility, and Views layout patterns rather than bypassing them.
- Prometheus Chromium source changes happen in `.context/chromium/src`; the root
  repo stores planning docs, scripts, verification evidence, and exported patch
  series only.
- Product colors/icons should flow through the Phase 14 Chromium token/resource
  pipeline, not through one-off CSS or local literals.
- Falkon/Qt code is reference-only. Reimplement behavior on Chromium primitives;
  do not copy GPL-derived implementation.

### Integration Points
- Compact/separate mode connects to browser prefs, `BrowserView` layout,
  top-container/tab-strip region layout, and `ToolbarView` location bar sizing.
- Tab management connects to `TabStripModel`, `TabGroupModel`, tab context menu
  commands, browser commands, and tab search/overview WebUI.
- Side panel entry connects to `SidePanelCoordinator`, toolbar actions/pinning,
  and later Phase 16/20 side-panel content.
- Agent/supervision stubs connect to future Phase 17 tab ownership/session state
  but must already be rendered in compact UI surfaces with safe defaults.

</code_context>

<specifics>
## Specific Ideas

- "Safari compact mode" remains the interaction reference: compact, native,
  minimal, tabs share the toolbar, and the active tab acts like the search field.
- Prometheus should not copy Safari styling; it should use the warm token system,
  sparse orange accent, PM/FSB product identity, and visible agent-state model.
- Search Tabs must stay reachable even when compact tab overflow occurs.
- The side panel is everyday four-mode UI; the dense control panel is not part
  of this phase.

</specifics>

<deferred>
## Deferred Ideas

- Phase 16 owns real WebUI start page, side panel surfaces, and FSB control
  panel pages.
- Phase 17 owns authenticated agent command service and real tab ownership
  state.
- Phase 20 owns provider/runtime/vault/memory/logs content and control-panel
  internals.
- Phase 21 owns full supervision/pairing behavior beyond the visible stub
  affordances needed in compact chrome.

</deferred>
*** End Patch
