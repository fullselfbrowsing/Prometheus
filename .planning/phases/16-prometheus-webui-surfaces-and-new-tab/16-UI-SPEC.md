---
phase: 16
slug: prometheus-webui-surfaces-and-new-tab
status: approved
created: 2026-07-07
shadcn_initialized: false
preset: none
---

# Phase 16 - UI Design Contract: Prometheus WebUI Surfaces and New Tab

> Visual and interaction contract for Chromium-backed Prometheus WebUI surfaces:
> start page/new tab, side panel content, and FSB Control Panel shell.

## Product Frame

Phase 16 surfaces are product UI, not marketing pages. The first screen for each
host must be usable:

- Start page: search/address input, Ask FSB handoff, favorites, suggestions.
- Side panel: four-mode operator surface with FSB Agent, Explorer, Tabs, Tools.
- Control panel: dense nine-section operator shell with empty states and safe
  metadata placeholders.

The design should feel quiet, native, and work-focused. Avoid hero pages, nested
cards, decorative gradients, decorative blobs, oversized type, and copy that
explains how to use the app.

## Implementation Mechanism

| Surface | Preferred Host | Role |
|---------|----------------|------|
| Start page | `chrome://prometheus-newtab/` | New-tab replacement/equivalent with Ask FSB handoff. |
| Side panel | `chrome://prometheus-side-panel/` | WebUI content hosted in the Phase 15 side-panel entry. |
| Control panel | `chrome://prometheus-control-panel/` | Internal operator page with nine sections. |

Separate hosts are preferred for test clarity and future security policy. A
single host with path routing is acceptable only if the planner documents the
reason and adds route coverage for all three surfaces.

All assets must be packaged through Chromium resources. The surfaces must not
load remote fonts, remote SVGs, CDN scripts, tracking pixels, or external CSS.
Prompt text, secrets, provider keys, vault values, pairing codes, and audit data
must not be embedded in URLs or static resources.

## Design System

| Property | Value |
|----------|-------|
| Implementation | Chromium WebUI HTML/CSS/TypeScript or minimal JavaScript, backed by browser-process controllers/handlers. |
| Component approach | Native WebUI DOM components; use Chromium `cr-*` components only where they fit operational UI without adding visual noise. |
| Icon library | Phase 14 packaged Font Awesome Free SVG resources through Prometheus GRIT IDs. |
| Brand assets | Phase 14 PM/FSB assets and Prometheus resource pack. |
| Font | Packaged Poppins for display/wordmark where available, Space Mono for compact metadata, system UI for body. Fallback must remain readable if packaged WebUI font host mapping is incomplete. |
| Radius | 8px maximum for cards, controls, inputs, and buttons unless a pill is functionally required for segmented controls or chips. |

## Color

Use the Phase 14 warm token family. Do not introduce a one-note orange/brown UI:
orange is an accent, not a page wash.

| Role | Dark | Light | Usage |
|------|------|-------|-------|
| App background | `#0d0a09` | `#e9e2da` | Browser/window backdrop only. |
| Primary surface | `#141110` | `#fffdfb` | Page and main content background. |
| Secondary surface | `#1d1816` | `#f3ede6` | Side panel body, section rail, input background. |
| Tertiary surface | `#26201d` | `#f1ebe4` | Hover rows, selected section fills, empty-state panels. |
| Text | `#f6efe9` | `#1f1a17` | Main readable text. |
| Secondary text | `#d2c1b4` | `#6a584d` | Descriptions and metadata. |
| Muted text | `#a99283` | `#8d7a6e` | URLs, timestamps, disabled copy. |
| Accent | `#ff6b35` | `#ff6b35` | Primary actions, focus rings, selected mode indicator. |
| Healthy | `#2f9e7e` | `#2f9e7e` | Verified/ready/healthy chips. |
| Warning | `#d29b36` | `#9a6a1e` | Needs attention or partial state. |
| Destructive | `#ff6666` | `#a65b5b` | Destructive action only. |

Rules:

- Accent appears on primary action, selected mode/section marker, and focus ring.
- Body text contrast must remain readable on dark and light surfaces.
- Never rely on color alone; chips and statuses require text or accessible names.
- No radial-gradient, orb, bokeh, or decorative background treatment in product
  surfaces. The prototype gradient is reference-only and not carried forward.

## Typography

| Role | Family | Size | Weight | Line Height | Usage |
|------|--------|------|--------|-------------|-------|
| Surface title | Poppins/system fallback | 24px | 600 | 1.2 | Start page wordmark only. |
| Page title | Poppins/system fallback | 18px | 600 | 1.25 | Control panel heading, side-panel brand. |
| Section heading | system UI | 14px | 600 | 1.35 | Section titles, card titles. |
| Body | system UI | 13px | 400 | 1.45 | Rows, messages, forms. |
| Label | system UI | 12px | 500 | 1.35 | Field labels, tabs, buttons. |
| Metadata | Space Mono/system monospace | 11px | 400 | 1.35 | Status chips, URLs, IDs, log snippets. |

Letter spacing must be `0`. Do not use negative tracking from the prototype.
Uppercase section labels may use text transform, but not extra letter spacing.

## Layout

### Global Rules

- Use an 8px spacing grid.
- Keep page sections unframed; use cards only for repeated individual items
  such as favorite tiles, suggestion actions, task rows, and section panels.
- Do not place cards inside cards.
- Stable dimensions are required for icon buttons, segmented controls, rows, and
  tiles so hover/focus states never shift layout.
- Text must not overflow buttons, chips, rows, or tiles. Long URLs and section
  names use ellipsis with accessible full text.

### Start Page

| Element | Contract |
|---------|----------|
| Root | Full WebUI page, centered content max width 960px, side padding 24px desktop / 16px mobile. |
| Brand row | PM mark + `Prometheus` wordmark + `Powered by FSB` metadata; no giant marketing hero. |
| Input | One combined search/address/Ask FSB input row, minimum 48px high, stable Ask FSB button at right. |
| Favorites | 4-column desktop, 2-column tablet, 1-column narrow; each tile 96px minimum height with favicon/mono, title, URL tooltip. |
| Suggestions | Dense action grid, not promotional cards; 3 columns desktop, 1 column narrow. |
| Empty state | If no favorites, show `No favorites yet` and a short body. |

Responsive breakpoints:

- `<= 480px`: single-column tiles, Ask FSB button becomes icon+tooltip if text
  would wrap.
- `481px..899px`: two-column favorites/suggestions.
- `>= 900px`: compact multi-column layout.

### Side Panel

| Element | Contract |
|---------|----------|
| Width | Designed for 320px; must remain usable down to 300px. |
| Header | PM mark, Prometheus label, `Powered by FSB`, and icon-only segmented mode control. |
| Modes | Exactly `FSB Agent`, `Explorer`, `Tabs`, `Tools` in that order. |
| Body | Scrollable; rows 40px minimum, compact chips 28px, composer 44px. |
| Agent mode | Ready/working status, message list, suggestions, composer. Phase 16 uses safe local seed state only. |
| Explorer mode | Bookmarks/history/reading-list sections with empty states if data source is stubbed. |
| Tabs mode | Current tab summaries and groups from safe stub/adapter until live tab data is wired. |
| Tools mode | Non-mutating toggles/chips unless a browser-process handler exists. |

The side panel cannot contain the nine dense control-panel sections.

### Control Panel

| Element | Contract |
|---------|----------|
| Root | Full internal WebUI page, no hero, no marketing copy. |
| Header | 48px band with `Prometheus`, `Powered by FSB`, and compact status chips. |
| Navigation | Left section rail at widths >= 720px; top segmented/select control below 720px. |
| Content | Section detail pane with dense tables/forms/empty states. |
| Sections | Tasks; Providers & Models; MCP Status; Permissions & Agents; Vault; Memory & Site Guides; Logs & Diagnostics; Supervision & Pairing; Parity Matrix. |
| Secrets | Metadata-only; never render raw keys, vault values, or pairing secrets. |

Rows and forms should be dense but calm. Favor tables, lists, segmented controls,
toggles, and icon buttons over large decorative cards.

## Copywriting

Required visible labels:

| Surface | Required Copy |
|---------|---------------|
| Start page title | `Prometheus` |
| Tagline | `Powered by FSB` |
| Start input placeholder | `Search or ask FSB` |
| Primary handoff | `Ask FSB` |
| Favorites heading | `Favorites` |
| Suggestions heading | `Suggested automations` |
| Side-panel modes | `FSB Agent`, `Explorer`, `Tabs`, `Tools` |
| Control panel title | `Prometheus` |
| Control panel subtitle | `Powered by FSB` |

Required control-panel sections:

1. `Tasks`
2. `Providers & Models`
3. `MCP Status`
4. `Permissions & Agents`
5. `Vault`
6. `Memory & Site Guides`
7. `Logs & Diagnostics`
8. `Supervision & Pairing`
9. `Parity Matrix`

Required empty states:

| Surface | Heading | Body |
|---------|---------|------|
| Agent | `Ready` | `Ask FSB to work in this browser.` |
| Favorites | `No favorites yet` | `Saved pages will appear here.` |
| Tasks | `No tasks yet` | `Ask Prometheus to work in this browser. Tasks will appear here with progress, cost, and final result.` |
| Providers | `No provider configured` | `Choose a provider, model, endpoint, and save from the control panel.` |
| MCP | `MCP bridge offline` | `Start Prometheus with the native agent server enabled, then refresh diagnostics.` |
| Vault | `No vault entries` | `Save metadata here. Secrets stay in native secure storage.` |
| Logs | `No runtime logs yet` | `Run a task or refresh diagnostics.` |
| Supervision | `No active supervision session` | `Pair a dashboard to begin supervised DOM-native viewing.` |
| Parity | `No parity rows loaded` | `Generate parity evidence before claiming FSB parity.` |

Security/error copy:

- `Provider secret blocked. Store keys from the native Prometheus UI.`
- `Vault secret blocked. Secrets cannot cross MCP or remote transports.`
- `Prompt handoff blocked. Prompt text cannot be placed in a URL.`
- `Permission blocked. Enable internal-surface control for this scope.`

## Interaction Contract

- Pressing Enter in the start input with text invokes the same Ask FSB handoff
  as the button unless the text clearly parses as a URL and the user chooses
  direct navigation.
- Ask FSB handoff opens/focuses the Prometheus side panel in `FSB Agent` mode and
  seeds the composer. It must not create a task until Phase 17/20 service wiring
  exists.
- Section/mode changes must be keyboard reachable and update accessible selected
  state.
- Favorite and history rows navigate only through browser-owned handlers.
- Destructive controls in the control panel are disabled or placeholder-only in
  Phase 16 unless a browser-process confirmation path exists.
- Focus rings use the accent color and are visible in dark and light themes.

## Accessibility

- Every icon-only button needs an accessible name and tooltip.
- Segmented controls expose the selected mode/section.
- Status chips include text labels, not only colored dots.
- Main landmarks: start page main, side panel complementary region, control
  panel navigation, control panel main region.
- Keyboard order follows visual order and does not trap focus inside the side
  panel.
- No text smaller than 11px. Metadata at 11px must remain readable.

## Security and Privacy

- No remote resources.
- No prompt text in URL, query, fragment, history, console logs, or static
  resource names.
- No raw provider keys, vault secrets, cookies, auth headers, pairing secrets, or
  local file paths in renderer-visible state.
- Browser handlers validate route names, prompt length, section IDs, and
  navigation targets.
- WebUI tests must include negative checks for remote resource references and
  prompt leakage.

## Verification Requirements

Minimum automated checks:

- Build `chrome browser_tests prometheus_unittests`.
- Navigate to every Prometheus WebUI host/route and assert required labels.
- Verify packaged resource bytes exist for Phase 16 HTML/CSS/JS resources.
- Scan Prometheus WebUI resources for `http://`, `https://`, `fonts.googleapis`,
  `@import`, external `src=`, and external `href=`.
- Test Ask FSB handoff with a sample prompt and assert the prompt is not present
  in the visible URL.
- Test side-panel toolbar entry opens Prometheus side-panel content.
- Test all nine control-panel section labels render.
- Run root gates: `check-chromium-env.sh`, `check-falkon-gpl-guard.sh`,
  `verify-artifact-isolation.sh`.

Manual/human visual checks can remain carried forward if native screenshot
capture is blocked:

- Start page dark/light rendering.
- Side panel four modes at 320px.
- Control panel responsive rail/select behavior at 320px, 720px, and wide.
- No text/icon overlap, no clipped buttons, and no layout jump on theme switch.

## UI-SPEC Self-Check

| Dimension | Status | Notes |
|-----------|--------|-------|
| Visual hierarchy | APPROVED | Product surfaces are operational, not marketing/hero pages. |
| Interaction coverage | APPROVED | Start, side-panel, and control-panel flows have explicit behavior. |
| Responsiveness | APPROVED | Breakpoints and panel widths are specified. |
| Accessibility | APPROVED | Icon labels, focus order, landmarks, and selected states required. |
| Security/privacy | APPROVED | No remote resources, prompt URL leakage, or secret exposure. |
| Stack alignment | APPROVED | Uses Chromium WebUI, Phase 14 resources, and Phase 15 side-panel entry point. |
