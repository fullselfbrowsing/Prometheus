# Phase 16: Prometheus WebUI Surfaces and New Tab - Context

**Gathered:** 2026-07-07
**Status:** Ready for UI contract and planning
**Mode:** Autonomous smart discuss defaults accepted

<domain>
## Phase Boundary

Phase 16 builds Chromium-backed Prometheus WebUI surfaces: the Prometheus start
page/new-tab equivalent, the four-mode side panel shell, and the internal FSB
Control Panel shell. It owns WebUI host/controller/resource registration,
packaged HTML/CSS/JS resources, browser-process data-source stubs, safe
renderer communication boundaries, and tests proving the surfaces render without
remote resources or prompt leakage.

Phase 16 does not implement the real native agent command service, provider
runtime, MCP bridge, vault secret handling, supervision pairing, or live page
adapter data. Those remain Phase 17 through Phase 21 scope. Phase 16 must expose
stable UI seams and safe placeholder data so later phases can wire real browser
services without redesigning the surfaces.

</domain>

<decisions>
## Implementation Decisions

### WebUI Architecture
- Build real Chromium WebUI controllers under `chrome/browser/ui/webui/prometheus/`
  and real packaged resources under `chrome/browser/resources/prometheus/`.
  Reuse the Phase 14 `chrome://prometheus-theme-preview` pattern for
  `WebUIController`, `WebUIDataSource`, GRIT resource IDs, `chrome_web_ui_configs`
  registration, and GN target ownership.
- Promote or replace the dev-only preview surface; do not leave production
  Phase 16 surfaces behind the Phase 14 DCHECK/UNKNOWN-channel guard.
- Prefer separate hosts for different trust/entry semantics:
  `chrome://prometheus-newtab/` for the start surface,
  `chrome://prometheus-side-panel/` for the side panel content, and
  `chrome://prometheus-control-panel/` for the dense operator page. If Chromium
  constraints make a host split costly, a single `chrome://prometheus/` host with
  path routing is acceptable only if tests prove all required routes render.
- Keep WebUI pages self-contained and packaged. No network fonts, remote SVGs,
  CDN scripts, inline secret data, or URL query prompt transport.

### Start Page and Ask FSB
- The start page should render PM mark, Prometheus wordmark, a prominent
  address/search/Ask FSB input, favorites, and suggested automations. The visual
  target is `.planning/design/prometheus-browser/prometheus/StartPage.jsx`,
  adapted to Chromium WebUI and Phase 14 tokens.
- Ask FSB from the start page must seed the side panel through a browser-owned
  command or message path. Prompt text must not be placed in a URL, query string,
  fragment, navigation history entry, or console log.
- Until Phase 17/20 provides real task execution, Ask FSB may open the side panel
  and populate a local composer/seed state only. It must not pretend that a real
  task has started.
- Favorites should use browser-owned data where practical. If bookmark plumbing
  is not ready in an early plan, use deterministic safe placeholder rows behind
  an adapter interface and keep the final data-source plan explicit.

### Side Panel
- The side panel content contract is the canonical four-mode shell from Phase 8:
  `FSB Agent`, `Explorer`, `Tabs`, and `Tools`.
- The Phase 15 toolbar button already creates a stable Prometheus side-panel
  entry point. Phase 16 should replace the placeholder side-panel view/content
  with a WebUI-backed surface or a WebUI-hosting view using Chromium side-panel
  infrastructure.
- The side panel remains compact everyday UI, not the dense control panel. It
  can show safe stub task/chat rows, bookmark/history examples, tab summaries,
  and page-tool toggles, but it must not expose secrets or privileged mutation.
- When real browser data is unavailable, use explicit empty/safe states from
  the UI contract rather than fake success states.

### FSB Control Panel
- Build the internal FSB Control Panel shell with the nine sections established
  in Phase 8: Tasks, Providers & Models, MCP Status, Permissions & Agents,
  Vault, Memory & Site Guides, Logs & Diagnostics, Supervision & Pairing, and
  Parity Matrix.
- Phase 16 should focus on shell, section navigation, copy, layout, safe empty
  states, and browser-owned WebUI plumbing. Phase 20 owns real provider/vault/
  memory/log runtime integration.
- All secret-bearing sections must render metadata-only or empty states. Never
  place secret values in generated HTML, JS fixtures, WebUI load-time data, or
  tests.

### Security and Data Boundaries
- Use Chromium WebUI resource/data-source APIs and Mojo/chrome-send style
  browser/renderer communication where appropriate. Avoid page-level hacks,
  extension injection, or arbitrary JS bridges.
- Treat renderer messages as untrusted. Validate route names, prompt lengths,
  section IDs, and navigation targets in browser code.
- The renderer can request handoff actions and safe metadata, but native
  secrets, provider keys, vault contents, and permission grants remain browser
  process only.
- Register resource paths explicitly and test them. Missing resource mappings
  should fail tests before a page can render blank.

### Verification Priorities
- Add WebUI browser tests that navigate to each Prometheus host/route and assert
  visible required strings, section labels, and no URL prompt leakage.
- Add resource/offline tests that scan Prometheus WebUI HTML/CSS/JS for remote
  resource loads and verify packaged resource bytes exist.
- Add side-panel tests that the Phase 15 toolbar entry point opens the
  Prometheus side panel content, not the placeholder.
- Add responsive or DOM-level layout checks for start page, side panel, and
  control panel at the documented breakpoints. Native screenshot capture may
  remain a human checkpoint if Conductor cannot foreground the app.

### the agent's Discretion
- Exact host names and file names are at planner discretion if the tests and
  UI-SPEC document the selected routing.
- The planner may stage implementation as static resource shell first, then
  browser tests, then side-panel integration, then data-source/adapters.
- The planner may defer real bookmark/history/tab data to later phases only if
  the adapter interfaces and safe placeholder/empty states are explicit.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and requirements
- `.planning/ROADMAP.md` section "Phase 16: Prometheus WebUI Surfaces and New
  Tab" - phase goal, planned work, and success criteria.
- `.planning/REQUIREMENTS.md` WEBUI-01 through WEBUI-07 - start page, Ask FSB
  handoff, control panel, browser-process data, security boundaries, and fast
  iteration docs.
- `.planning/PROJECT.md` - Chromium migration goal, DOM/native control thesis,
  side panel/control panel split, and no screenshot-first architecture.
- `.planning/preservation/FALKON-TO-CHROMIUM-PRESERVATION.md` - preserved
  behavior contracts for side panel, control panel, start page, and visual
  carry-forward checks.

### Design and prior UI contracts
- `.planning/design/prometheus-browser/prometheus/StartPage.jsx` - start page
  look/behavior target.
- `.planning/design/prometheus-browser/prometheus/SidePanel.jsx` - four-mode
  side panel look/behavior target.
- `.planning/design/prometheus-browser/prometheus/styles.css` - warm tokens,
  spacing, typography, and component classes.
- `.planning/phases/08-native-fsb-plus-settings-side-panel-and-feature-parity-matri/08-UI-SPEC.md`
  - side panel/control panel split, nine control-panel sections, copy,
  empty states, and status labels.
- `.planning/phases/10-new-tab-start-page/10-UI-SPEC.md` - start page content,
  Ask FSB no-URL-leak rule, favorites, and suggested automation requirements.
- `.planning/phases/14-asset-and-design-system-port/14-07-SUMMARY.md` - Phase
  14 Prometheus WebUI preview pattern and known font/resource host caveat.
- `.planning/phases/15-chromium-ui-shell-compact-chrome-and-tab-model/15-06-SUMMARY.md`
  - Phase 15 side-panel entry point and visual capture limitation.

### Chromium implementation anchors
- `.context/chromium/src/chrome/browser/ui/webui/prometheus/prometheus_theme_preview_ui.{h,cc}`
  - existing Prometheus WebUI controller/data-source pattern.
- `.context/chromium/src/chrome/browser/resources/prometheus/prometheus_resources.grd`
  and `.grdp` - existing Prometheus GRIT resource package.
- `.context/chromium/src/chrome/browser/resources/prometheus/BUILD.gn` - GRIT,
  pak copy, and vector icon targets.
- `.context/chromium/src/chrome/browser/ui/webui/chrome_web_ui_configs.cc` -
  WebUI config registration.
- `.context/chromium/src/chrome/browser/ui/webui/BUILD.gn` - WebUI target
  wiring.
- `.context/chromium/src/chrome/browser/ui/views/side_panel/` - side-panel
  hosting/coordinator infrastructure.
- `.context/chromium/src/chrome/browser/ui/webui/ntp/` and
  `.context/chromium/src/chrome/browser/ui/webui/new_tab_page/` - existing new
  tab WebUI patterns and browser tests.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- Phase 14 already packages Prometheus resources and exposes generated
  `chrome/grit/prometheus_resources.h` IDs.
- Phase 14 already registers a Prometheus WebUI controller and maps local
  resource paths through `WebUIDataSource`.
- Phase 14 token/icon/font resource tests can be extended to cover Phase 16
  page HTML/CSS/JS resources.
- Phase 15 toolbar entry points and side panel placeholder provide the native
  opening path for Phase 16 side-panel content.

### Established Patterns
- Prometheus Chromium source lives in `.context/chromium/src`; root stores
  planning docs, logs, and exported patches.
- GRIT targets with `output_dir = "$root_gen_dir/chrome"` include generated
  headers as `chrome/grit/<name>.h`.
- WebUI pages should use explicit `AddResourcePath` mapping for every local
  asset referenced by HTML/CSS.
- Dev-only throwaway surfaces can be DCHECK/UNKNOWN gated, but Phase 16 product
  surfaces must be available in the normal Prometheus build.

### Integration Points
- Start page route connects to WebUI config/controller registration and later
  new-tab replacement plumbing.
- Side-panel content connects to `SidePanelCoordinator`, the Phase 15 toolbar
  button, and a WebUI view/content host.
- Control panel route connects to WebUI resource/controller registration first,
  then Phase 20 runtime providers.
- Ask FSB handoff connects to a browser-owned side-panel open/seed command now,
  and to Phase 17/20 task services later.

</code_context>

<specifics>
## Specific Ideas

- Build the first usable screen, not a marketing landing page. The new tab is a
  work surface with omnibox/Ask FSB, favorites, and suggestions.
- Side panel is compact and repeated-use; control panel is dense operator UI.
- "Powered by FSB" remains visible in appropriate WebUI surfaces.
- Use icon imagery from Phase 14 packaged Font Awesome/Prometheus assets, not
  remote icon fonts or platform-theme icons.
- Use safe placeholders only where they are visibly placeholders or empty
  states; do not imply provider/runtime features exist before Phase 20.

</specifics>

<deferred>
## Deferred Ideas

- Real task execution, agent routing, provider calls, and task logs - Phase 17
  and Phase 20.
- Real vault secret values, provider keys, and autofill - Phase 20 with secure
  browser-process storage.
- Live DOM/page explorer data - Phase 18.
- MCP bridge health and multi-agent compatibility - Phase 19.
- Supervision pairing and remote control - Phase 21.
- Final packaged-app visual UAT/screenshots - Phase 24 release validation, with
  any Phase 16 manual visual gaps carried forward.

</deferred>
