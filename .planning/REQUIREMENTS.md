# Requirements: Prometheus v2.0 Chromium Engine Migration

**Defined:** 2026-06-17
**Milestone:** v2.0 Chromium Engine Migration
**Core Value:** Agents get fast, precise, auditable control of the whole browser through DOM/native structure, not screenshots, brittle extension injection, or human-only UI.

## Milestone Goal

Replace the Falkon/QtWebEngine implementation with a Chromium-based Prometheus browser while preserving the v1 Prometheus/FSB product DNA, design language, local MCP contract, native agent control, supervision, memory/vault/provider surfaces, compact browser chrome goals, start page, parity discipline, and release validation.

This milestone intentionally treats Falkon as a historical reference and preservation archive, not the future codebase.

## v2 Requirements

### Preservation And Retirement

- [ ] **PRES-01**: Developer can recover the full Falkon-based Prometheus v1 source reference from a local preservation bundle after the active `falkon/` tree is removed.
- [ ] **PRES-02**: Project has a written inventory of v1 product decisions, design tokens, UI surfaces, asset paths, tool contracts, tests, validation scripts, and deferred verification items before source removal.
- [ ] **PRES-03**: Project has an explicit migration map from each v1 Falkon/Qt implementation surface to a Chromium-native owner or a deliberately deferred/out-of-scope item.
- [ ] **PRES-04**: Project distinguishes behavior/design contracts from GPL-derived Falkon implementation code so Chromium work does not copy GPL source without license review.
- [ ] **PRES-05**: Developer can remove the active `falkon/` checkout from the workspace without losing source history, patches, assets, or planning context.
- [ ] **PRES-06**: Root project documentation no longer presents Falkon/QtWebEngine as the production architecture after the Chromium baseline is established.
- [ ] **PRES-07**: v1 deferred human-visual verification items are either re-run against Chromium equivalents or explicitly retired with rationale because the Falkon UI surface no longer exists.

### Chromium Baseline

- [ ] **CHROM-01**: Developer can check out upstream Chromium using official `depot_tools`/`fetch chromium` workflow into a Prometheus-owned source location.
- [ ] **CHROM-02**: Developer can generate a local macOS Chromium build directory with GN and build the `chrome` target using Ninja/autoninja.
- [ ] **CHROM-03**: Project documents minimum disk, time, SDK, Xcode, depot_tools, GN, and Ninja requirements for local Chromium development.
- [ ] **CHROM-04**: Chromium source is kept in a patch-discipline structure that allows upstream rebases without mixing generated build output, local caches, or `.gclient` state into the root planning repo.
- [ ] **CHROM-05**: Project records the exact Chromium revision used as the Prometheus migration baseline.
- [ ] **CHROM-06**: Developer can run the unmodified Chromium app from the local build before Prometheus modifications begin.
- [ ] **CHROM-07**: Project has a reproducible build/run script for macOS that fits Conductor/workspace constraints and avoids fixed-port or global-state conflicts where possible.
- [ ] **CHROM-08**: Chromium checkout/build artifacts are excluded or isolated so the root repository does not accidentally commit massive generated directories.

### Product Identity, Legal, And Branding

- [ ] **BRAND-01**: User sees Prometheus as the app name, window title, profile/application identity, app icon, first-run/about identity, and primary product documentation.
- [ ] **BRAND-02**: User sees "Powered by FSB" as the explicit affiliation/tagline in the side panel, start page, about/legal surfaces, and relevant docs.
- [ ] **BRAND-03**: User does not see Chromium/Chrome/Falkon/KDE branding in primary Prometheus product surfaces except where legally required or intentionally left as upstream attribution.
- [ ] **BRAND-04**: Required Chromium, third-party, Font Awesome, Poppins, Space Mono, FSB-owned, and any retained inherited notices are visible in source and in an appropriate legal/about surface.
- [ ] **BRAND-05**: Migration avoids copying GPL Falkon source into Chromium unless the project explicitly accepts and documents the resulting license obligations.
- [ ] **BRAND-06**: Product metadata and bundle identifiers are Prometheus-owned and do not conflict with installed Chrome/Chromium profiles or apps.
- [ ] **BRAND-07**: README and release docs describe Prometheus as a Chromium-based agent-native browser after the baseline migration.

### Design System And Assets

- [ ] **DESIGN-01**: Prometheus implements the canonical warm dark and warm light token sets: `#0d0a09`, `#141110`, `#1d1816`, `#f6efe9`, `#d2c1b4`, `#a99283`, `#fffdfb`, `#f3ede6`, `#e9e2da`, `#ff6b35`, and `#ff8c42`.
- [ ] **DESIGN-02**: Prometheus uses FSB orange sparingly for primary action, active agent/supervision state, selected/focus state, and logo treatment rather than broad decoration.
- [ ] **DESIGN-03**: Prometheus bundles or otherwise reliably serves Poppins and Space Mono with required OFL notices and no network font dependency.
- [ ] **DESIGN-04**: Prometheus bundles a curated Font Awesome Free icon subset with CC BY 4.0 attribution preserved and no network icon dependency.
- [ ] **DESIGN-05**: Prometheus ships the PM monogram, Prometheus wordmark, and FSB logo assets in dark/light contexts with correct clear-space, minimum-size, and fallback behavior.
- [ ] **DESIGN-06**: Prometheus WebUI and native Views surfaces use the same token vocabulary and state colors so side panel, control panel, start page, and chrome feel like one product.
- [ ] **DESIGN-07**: Visual verification covers dark/light themes, accent states, text fit, icon rendering, font loading, focus rings, disabled states, warning states, and private/supervised states.

### Browser Chrome And Tab Experience

- [ ] **UX-01**: User can use a compact browser chrome where tabs share the toolbar and the active tab behaves as the address/search field.
- [ ] **UX-02**: User can switch to a separate/conventional tab layout if compact chrome is not desired.
- [ ] **UX-03**: User can use tab groups, tab overview/search, quick switch, reorder, close/restore, unload/suspend, duplicate, and detach flows in the Chromium-based browser.
- [ ] **UX-04**: Browser shows agent ownership, active automation, supervision, tab health, audio/private/security state, and extension-relevant state without cluttering compact chrome.
- [ ] **UX-05**: User can open and collapse the Prometheus side panel from the browser chrome with a stable location and keyboard path.
- [ ] **UX-06**: Compact chrome passes desktop visual checks at narrow, standard, and wide sizes with no overlap, layout jump, unreadable labels, or missing action affordances.
- [ ] **UX-07**: Browser preserves native platform expectations on macOS first: traffic lights, keyboard shortcuts, menu behavior, accessibility labels, and window focus behavior.

### Chromium WebUI Surfaces

- [ ] **WEBUI-01**: Prometheus has a Chromium WebUI start page that replaces or owns the default new tab experience.
- [ ] **WEBUI-02**: The start page shows the PM hero mark, Prometheus wordmark, omnibox, Ask FSB action, favorites, and suggested automations.
- [ ] **WEBUI-03**: Ask FSB from the start page seeds the FSB Agent mode in the Prometheus side panel without leaking prompt text into navigation history or URLs.
- [ ] **WEBUI-04**: Prometheus has an internal FSB Control Panel WebUI with Tasks, Providers & Models, MCP Status, Permissions & Agents, Vault, Memory & Site Guides, Logs & Diagnostics, Supervision & Pairing, and Parity Matrix.
- [ ] **WEBUI-05**: Prometheus WebUI pages use browser-process data sources and browser/renderer communication instead of page-level hacks for privileged control.
- [ ] **WEBUI-06**: Internal WebUI surfaces use strict security boundaries: no remote resource loading, no arbitrary secret exposure, no cross-origin prompt leakage, and audited browser-process actions.
- [ ] **WEBUI-07**: WebUI development has a documented fast iteration mode using Chromium-supported WebUI resource loading where practical.

### Native Agent Control

- [ ] **AGENT-01**: Browser exposes a Chromium-native Prometheus agent service that validates route input, selects target surface, executes action, audits action, and returns structured results.
- [ ] **AGENT-02**: Agent can list windows/tabs, open tabs, switch tabs, close tabs, navigate, reload, go back, and go forward using browser-owned APIs.
- [ ] **AGENT-03**: Agent can target normal pages, internal WebUI pages, settings, downloads, history, extension surfaces, and Prometheus runtime surfaces through explicit adapters.
- [ ] **AGENT-04**: Agent sessions are authenticated and assigned by the browser/native service, not trusted from caller-provided client labels.
- [ ] **AGENT-05**: Browser enforces tab ownership by stable tab/WebContents identity and rejects cross-agent control with typed errors.
- [ ] **AGENT-06**: Browser enforces configurable concurrent-agent caps and reconnect grace.
- [ ] **AGENT-07**: Browser rejects unsafe, unsupported, unauthorized, or scope-mismatched actions with typed errors and recovery guidance.
- [ ] **AGENT-08**: Agent route results include enough timing, target, verification, audit, and changed-state information for debugging without leaking secrets.

### Page Understanding And Action Verification

- [ ] **PAGE-01**: Agent can read visible text from the active or owned target page.
- [ ] **PAGE-02**: Agent can request DOM snapshots with stable refs, selectors, forms, ARIA labels, text, attributes, frame context, and actionability hints.
- [ ] **PAGE-03**: Agent can request compact page snapshots suitable for planning the next action.
- [ ] **PAGE-04**: Agent can execute audited JavaScript on normal web pages with explicit permission, result capture, and read-back verification.
- [ ] **PAGE-05**: Agent can click, type, press keys, scroll, hover, select options, clear inputs, drag, and drop files where Chromium permits the action safely.
- [ ] **PAGE-06**: Browser waits for page load, DOM stability, visible state change, or target-specific readiness after mutating actions.
- [ ] **PAGE-07**: Browser returns change reports for mutating actions and identifies repeated/stuck action patterns.
- [ ] **PAGE-08**: Page adapters work across same-origin frames, cross-origin frames where browser privileges permit, and failure cases where the target is sandboxed or restricted.

### MCP Compatibility And Multi-Agent Runtime

- [ ] **MCP-01**: Existing FSB-style MCP clients can connect to the Chromium-based Prometheus through a local stdio-compatible bridge.
- [ ] **MCP-02**: Prometheus exposes compatible manual action tools including `execute_js`, navigation, interaction, scrolling, tabs, coordinate tools, and mutation tools where supported.
- [ ] **MCP-03**: Prometheus exposes compatible read tools including `read_page`, `get_dom_snapshot`, `get_page_snapshot`, `get_text`, `get_attribute`, `list_tabs`, memory reads, and site-guide reads.
- [ ] **MCP-04**: MCP action tools accept and preserve visual-session fields `visual_reason`, `client`, and `is_final` for existing FSB client compatibility.
- [ ] **MCP-05**: Removed or changed legacy tools return typed compatibility errors with migration guidance rather than disappearing.
- [ ] **MCP-06**: MCP diagnostics report browser, bridge/server, active tab, content adapter, internal adapter, WebUI adapter, vault, provider, supervision, and extension-system health.
- [ ] **MCP-07**: Bridge tests cover client lifecycle, authorization, tab ownership, background tab routing, numeric parameter coercion, visual-session compatibility, and recovery messaging.

### FSB Runtime, Providers, Memory, Vault, And Logs

- [ ] **FSB-01**: User can submit natural-language browser tasks from the Prometheus side panel FSB Agent mode.
- [ ] **FSB-02**: Browser can run provider-backed, local/offline, and MCP-driven task paths with visible execution mode, progress, cancellation, final result, and failure reporting.
- [ ] **FSB-03**: User can configure providers for OpenAI, Anthropic, Gemini, xAI, OpenRouter, LM Studio, hosted/routed/local/custom endpoints, and fallback order.
- [ ] **FSB-04**: Provider secrets are saved through platform/browser secure storage and never displayed after save.
- [ ] **FSB-05**: Browser stores and displays task logs, action history, diagnostics, metrics, token/cost accounting, and task outcomes.
- [ ] **FSB-06**: Browser provides memory and site-guide primitives for saving, listing, retrieving, and applying site-specific automation knowledge.
- [ ] **FSB-07**: Browser provides vault metadata and native-only secret flows with explicit confirmation for autofill-like actions.
- [ ] **FSB-08**: User-facing settings expose internal-surface permissions, agent caps, tab ownership, background actions, telemetry, vault boundaries, and supervision pairing.

### Supervision And Remote Control

- [ ] **SUP-01**: Browser shows visible trusted-client, active-agent, and supervised-action state while external clients control the browser.
- [ ] **SUP-02**: Browser can stream DOM-native snapshots/diffs or equivalent structured supervision data for live supervised sessions.
- [ ] **SUP-03**: Supervision messages carry session identity so stale snapshots, diffs, or remote-control actions cannot affect the wrong tab/session.
- [ ] **SUP-04**: Browser supports safe remote-control pairing with visible pairing state, expiration, revocation, audit logs, and target validation.
- [ ] **SUP-05**: Remote control honors tab ownership, internal-surface permissions, vault boundaries, and user-visible confirmation requirements.

### Extension Ecosystem

- [ ] **EXT-01**: Chromium-based Prometheus keeps or enables Chromium's extension system where legally and technically practical.
- [ ] **EXT-02**: User can install and manage Chrome/Chromium-compatible extensions through a Prometheus-approved flow or documented sideload/developer flow.
- [ ] **EXT-03**: Prometheus distinguishes extension permissions from Prometheus agent permissions so an extension cannot silently gain agent-native internal-surface control.
- [ ] **EXT-04**: Agent routing can identify extension pages/surfaces and apply explicit policy before reading or mutating them.
- [ ] **EXT-05**: Extension compatibility is tested with representative categories: password manager, ad blocker, productivity/content script, side panel/tooling extension, and developer extension.
- [ ] **EXT-06**: Prometheus documents any intentionally disabled Chrome/Google-service extension features and provides user-facing explanations.

### Validation, Security, And Release

- [ ] **REL-01**: Project has a release validation script for Chromium-based Prometheus covering build, smoke, browser chrome, WebUI, MCP, agent control, page adapters, extensions, security, branding, assets, and legal notices.
- [ ] **REL-02**: Parity matrix maps every v1 Falkon-era capability and FSB category to Chromium status: Missing, Partial, Parity, Better, Blocked, or Verified.
- [ ] **REL-03**: Security review covers route auth, tab ownership, JS execution, internal WebUI mutation, extension boundaries, vault, provider secrets, remote pairing, logs, and telemetry.
- [ ] **REL-04**: Visual verification covers side panel, control panel, compact chrome, start page, themes, fonts, icons, extension surfaces, and macOS packaging.
- [ ] **REL-05**: macOS package is reproducible and carries Prometheus identity, required licenses, source guidance, and no Falkon product artifacts.
- [ ] **REL-06**: Release docs explain the Chromium base, upstream revision, supported platforms, known limitations, extension support status, MCP setup, and safety model.
- [ ] **REL-07**: The final migration gate fails if active code still depends on `falkon/`, Qt/Falkon build scripts, Falkon product strings, or unreviewed GPL-derived implementation code.

## Future Requirements

- [ ] **FUT-01**: Linux and Windows Chromium-based builds after macOS-first validation.
- [ ] **FUT-02**: Lattice integration for provider routing, receipts, policy, or agent runtime if it materially simplifies the Chromium architecture.
- [ ] **FUT-03**: Hosted/fleet control after local Chromium control and supervision are stable.
- [ ] **FUT-04**: Signed/notarized public release pipeline and automatic update channel.
- [ ] **FUT-05**: Enterprise policy templates for agent permissions, extension policy, provider allowlists, telemetry, and vault behavior.

## Out Of Scope

| Feature | Reason |
|---------|--------|
| Keeping Falkon as the production browser base | The milestone decision is to migrate to Chromium. Falkon remains a preserved reference only. |
| Copying GPL Falkon implementation into Chromium without review | Could impose unintended license obligations. Reimplement behavior natively unless explicitly reviewed. |
| Rebuilding a rendering engine from scratch | Chromium is the browser engine/platform base. |
| Relying on screenshot/video-first automation as the main architecture | The product thesis remains DOM/native structural control. |
| Stealth automation or account abuse | Prometheus remains supervised, auditable, and safety-bounded. |
| Chrome Web Store publishing guarantees in this milestone | Extension compatibility is in scope; store distribution agreements/policies may need separate work. |
| Public notarized release before migration parity | A local/reproducible validation package comes before public release. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| PRES-01..PRES-07 | Phase 11 | Planned |
| CHROM-01..CHROM-08 | Phase 12 | Planned |
| BRAND-01..BRAND-07 | Phase 13 | Planned |
| DESIGN-01..DESIGN-07 | Phase 14 | Planned |
| UX-01..UX-07 | Phase 15 | Planned |
| WEBUI-01..WEBUI-07 | Phase 16 | Planned |
| AGENT-01..AGENT-08 | Phase 17 | Planned |
| PAGE-01..PAGE-08 | Phase 18 | Planned |
| MCP-01..MCP-07 | Phase 19 | Planned |
| FSB-01..FSB-08 | Phase 20 | Planned |
| SUP-01..SUP-05 | Phase 21 | Planned |
| EXT-01..EXT-06 | Phase 22 | Planned |
| REL-01..REL-07 | Phases 23-24 | Planned |

**Coverage:**

- v2 active requirements: 92 total
- mapped to phases: 92
- unmapped: 0
- planned phases: 14

---
*Requirements defined: 2026-06-17*
