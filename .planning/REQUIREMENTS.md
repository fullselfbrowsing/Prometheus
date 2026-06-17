# Requirements: Prometheus

**Defined:** 2026-06-16
**Core Value:** Agents get fast, precise, auditable control of the whole browser through DOM/native structure, not screenshots, brittle extension injection, or human-only UI.

## v1 Requirements

### Foundation

- [ ] **BASE-01**: Developer can build and run the local Falkon-derived browser from the workspace on the initial target platform.
- [ ] **BASE-02**: Developer can run a repeatable smoke test that opens a page, navigates, creates a tab, and exits cleanly.
- [ ] **BASE-03**: Project has an inventory of inherited Falkon/KDE/Qt product identifiers, assets, packaging files, and legal notices.
- [ ] **BASE-04**: Required GPL and third-party legal notices remain available in source and in the browser's legal/about surface.

### Product Identity

- [ ] **BRAND-01**: User sees Prometheus branding in the app name, primary window title, icons, first-run/about surfaces, and main browser chrome, with "Powered by FSB" used as the explicit affiliation/tagline where appropriate.
- [ ] **BRAND-02**: User no longer sees Falkon/KDE product branding in primary browser UI, default bookmarks, desktop/bundle metadata, or documentation intended for this product.
- [ ] **BRAND-03**: Browser UI uses FSB visual language: near-black surfaces, FSB orange primary actions, dense operator controls, visible action state, and FSB assets.
- [ ] **BRAND-04**: Rebrand changes preserve buildability and package/install metadata on the initial target platform.

### Native Agent Control

- [ ] **AGENT-01**: Browser exposes a native tool router that validates tool input, selects the target surface, executes the action, logs the action, and returns structured results.
- [ ] **AGENT-02**: Agent can list windows/tabs, open a tab, switch tabs, close a tab, navigate, refresh, go back, and go forward through native browser control.
- [ ] **AGENT-03**: Agent can target normal web pages and browser-owned internal surfaces through distinct adapters behind one control contract.
- [ ] **AGENT-04**: Agent can execute JavaScript on normal web pages through a permissioned API that records the code, target, result, and verification state.
- [ ] **AGENT-05**: Agent can control at least one browser-owned settings/internal surface through structured native commands without visual clicking.
- [ ] **AGENT-06**: Browser rejects unsafe or unsupported agent actions with typed errors rather than silent failure.

### Page Understanding and Actions

- [ ] **PAGE-01**: Agent can read visible page text from the active tab.
- [ ] **PAGE-02**: Agent can request a structured DOM snapshot with element refs, selectors, forms, ARIA labels, and key attributes.
- [ ] **PAGE-03**: Agent can request a compact page snapshot suitable for planning the next action.
- [ ] **PAGE-04**: Agent can click, type, press keys, scroll, hover, select options, clear inputs, and drag/drop on normal web pages.
- [ ] **PAGE-05**: Browser waits for page load, DOM stability, or visible state change after mutating actions.
- [ ] **PAGE-06**: Browser returns change reports for mutating actions and supports read-back verification.
- [ ] **PAGE-07**: Browser detects repeated or stuck actions and reports recovery guidance.

### MCP Compatibility

- [ ] **MCP-01**: Existing MCP clients can connect to Prometheus through a local MCP interface.
- [ ] **MCP-02**: Prometheus exposes compatible manual action tools for the existing FSB core contract, including `execute_js`, navigation, interaction, scrolling, tabs, and coordinate/mutation tools where supported.
- [ ] **MCP-03**: Prometheus exposes compatible read tools, including `read_page`, `get_dom_snapshot`, `get_page_snapshot`, `get_text`, `get_attribute`, `list_tabs`, and site-guide/memory reads when available.
- [ ] **MCP-04**: MCP action tools support the implicit visual-session fields `visual_reason`, `client`, and `is_final`.
- [ ] **MCP-05**: Removed legacy tools such as explicit visual-session start/end calls return typed compatibility errors with migration guidance.
- [ ] **MCP-06**: MCP diagnostics can report whether the browser, bridge/server, active tab, content/page adapter, and internal-surface adapter are healthy.

### Multi-Agent Execution

- [ ] **MULTI-01**: Browser assigns each connected MCP agent an identity controlled by the browser/server, not caller-supplied trust.
- [ ] **MULTI-02**: Browser enforces tab ownership so one agent cannot control another agent's tab.
- [ ] **MULTI-03**: Browser enforces a configurable concurrent-agent cap and returns `AGENT_CAP_REACHED` when exceeded.
- [ ] **MULTI-04**: Browser supports reconnect recovery for active agent sessions where practical.
- [ ] **MULTI-05**: Browser can execute safe actions on background tabs without stealing focus when the tool does not require foreground focus.

### FSB Runtime Parity

- [ ] **FSB-01**: User can open a Prometheus side panel or equivalent agent surface to submit natural-language browser tasks.
- [ ] **FSB-02**: User can configure AI providers for xAI, Gemini, OpenAI, Anthropic, OpenRouter, LM Studio, and custom OpenAI-compatible endpoints.
- [ ] **FSB-03**: Browser can run FSB-style autopilot tasks with progress, cancellation, final result, and failure reporting.
- [ ] **FSB-04**: Browser stores and displays session logs, action history, diagnostics, token/cost accounting, and task outcomes.
- [ ] **FSB-05**: Browser provides memory/site-guide primitives for reusing site-specific automation knowledge.
- [ ] **FSB-06**: Browser provides secure vault flows for credentials and payment-like sensitive values without sending secrets across MCP or remote-control transports.

### Native FSB-Plus Control Center

- [x] **FSBP-01**: Prometheus has a native side panel/control center for tasks, providers, MCP status, permissions, vault, memory, site guides, logs, diagnostics, supervision, and dashboard pairing.
- [x] **FSBP-02**: Prometheus maintains a feature parity matrix against FSB covering side panel, provider settings, model discovery, MCP tools, DOM snapshots, action tools, visual feedback, memory, vault, remote dashboard, tab management, and diagnostics.
- [x] **FSBP-03**: Prometheus documents and verifies native improvements over FSB where browser ownership helps, including internal settings control, safer secret handling, richer tab/session state, lower-latency native routing, and offline-capable UI assets.
- [x] **FSBP-04**: Side panel task execution can use configured provider-backed execution when available and local/MCP execution paths when provider-backed execution is unavailable.
- [x] **FSBP-05**: User-facing settings expose internal-surface permissions, agent caps, tab ownership, visual feedback, telemetry, vault boundaries, and supervision pairing state.
- [x] **FSBP-06**: Release validation includes a parity gate that fails when required FSB feature categories are missing, regressed, undocumented, or unverified.

### Browser Chrome and Tab Management

- [x] **UX-01**: Browser supports a compact chrome mode where tabs live in the toolbar and the active tab acts as the unified address/search field.
- [x] **UX-02**: Browser keeps a separate tab layout option for users who prefer conventional toolbar plus tab bar behavior.
- [x] **UX-03**: Browser supports advanced tab management: tab groups, tab overview/search, reorder, duplicate, detach, close/restore, unload/suspend, and quick switch.
- [x] **UX-04**: Browser exposes tab group and tab state through native agent/MCP reads without letting agents bypass tab ownership or supervision boundaries.
- [x] **UX-05**: Compact chrome preserves visible agent ownership, active automation state, supervision state, tab health, and secure-origin cues without overwhelming the browser chrome.
- [x] **UX-06**: Compact chrome and tab management pass visual checks across narrow, standard, and wide desktop window sizes with no text overlap or layout shift.

### Icon and Theme System

- [ ] **ICON-01**: Prometheus bundles a curated offline Font Awesome Free icon subset in Qt resources with required license and attribution metadata preserved.
- [ ] **ICON-02**: Prometheus provides a central native icon resolver for browser, tab, agent, MCP, provider, vault, diagnostics, supervision, and settings actions.
- [ ] **ICON-03**: Primary UI icons have deterministic bundled fallbacks instead of depending on platform theme availability.
- [ ] **ICON-04**: Release validation fails when required bundled icons are missing, network-loaded, legally unattributed, or unreadable at intended sizes.
- [ ] **THEME-01**: Prometheus themes are minimal and native-feeling, with restrained surfaces, clear focus/hover/active states, and no decorative visual noise.
- [ ] **THEME-02**: Minimal themes support normal, private, supervised, warning, disabled, and active-agent states without relying on heavy gradients or one-note color treatment.
- [ ] **THEME-03**: Prometheus implements the canonical warm dark and warm light token sets and an accent recolor option as pure token swaps, per the design reference.
- [ ] **FONT-01**: Prometheus bundles the Poppins (display) and Space Mono (mono) brand fonts offline as Qt resources with required license and attribution, with no network font loading.
- [ ] **LOGO-01**: Prometheus uses the real PM brand mark and the "Prometheus" / "Powered by FSB" wordmark per the brand sheet across app icon, side panel header, start page, and about/first-run surfaces, retiring placeholder marks with correct clear-space and minimum-size rules.

### New Tab Start Page

- [ ] **START-01**: Opening a New Tab shows the Prometheus start page with the hero PM mark, the Prometheus wordmark, and an omnibox.
- [ ] **START-02**: The start page omnibox accepts a search or address and offers an Ask FSB action that hands a natural-language prompt to the FSB Agent side panel.
- [ ] **START-03**: The start page shows a favorites grid that navigates to the chosen entry.
- [ ] **START-04**: The start page shows FSB suggested automations that seed the agent panel when chosen.
- [ ] **START-05**: The start page uses the canonical Prometheus design system (warm tokens, Poppins, Space Mono, Font Awesome) and renders correctly in both themes.

### Supervision and Remote View

- [ ] **SUP-01**: Browser shows a visible trusted-client badge or overlay while an external agent controls the browser.
- [ ] **SUP-02**: Browser highlights or describes current agent actions so a supervising human can understand what is happening.
- [ ] **SUP-03**: Browser can stream a live supervised view of a web page using DOM-native snapshot/diff mirroring or an equivalent PhantomStream-derived approach.
- [ ] **SUP-04**: Remote supervision messages carry session identity so stale snapshots, diffs, or remote-control actions cannot affect the wrong session.
- [ ] **SUP-05**: Browser supports a safe remote-control pairing flow for dashboard/sync use.

### Security and Release

- [ ] **SEC-01**: Sensitive settings, API keys, vault entries, and provider credentials are stored through an encrypted or platform-secure storage path.
- [ ] **SEC-02**: Agent actions on internal pages, settings, vault, downloads, history, and extension surfaces require explicit browser-side permission boundaries.
- [ ] **SEC-03**: Browser produces audit logs for JS execution, vault use, remote-control pairing, and internal-surface mutations.
- [ ] **REL-01**: Project has a repeatable package/build artifact for the initial target platform.
- [ ] **REL-02**: Release artifact includes required legal notices and source/license guidance for inherited GPL code.
- [ ] **REL-03**: Release validation runs build, smoke, MCP compatibility, core automation, internal-surface, security, and branding checks.

## v2 Requirements

### Future Platform and Runtime

- **V2-01**: Browser ships polished builds for Linux and Windows after macOS-first validation.
- **V2-02**: Browser adopts Lattice for provider routing, receipts, policy, or agent runtime if it materially simplifies the native architecture.
- **V2-03**: Browser supports hosted/fleet control after local control and supervision are validated.
- **V2-04**: Browser supports advanced extension ecosystem compatibility if QtWebEngine/Falkon surfaces make it practical.

## Out of Scope

| Feature | Reason |
|---------|--------|
| Removing required copyright/license notices | Rebrand must not violate inherited GPL or third-party obligations. |
| Building a browser rendering engine from scratch | QtWebEngine is sufficient for v1; engine work is not the product wedge. |
| Stealth automation or unsupervised account operation | Prometheus should remain supervised, auditable, and safety-bounded. |
| Screenshot/video-first automation as the main architecture | The core value is DOM/native structure; screenshots are fallback diagnostics only. |
| Hosted browser fleet control in v1 | Local browser, local MCP, and optional dashboard pairing come first. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| BASE-01 | Phase 1 | Complete |
| BASE-02 | Phase 1 | Complete |
| BASE-03 | Phase 1 | Complete |
| BASE-04 | Phase 1 | Complete |
| BRAND-01 | Phase 2 | Complete |
| BRAND-02 | Phase 2 | Complete |
| BRAND-03 | Phase 2 | Complete |
| BRAND-04 | Phase 2 | Complete |
| AGENT-01 | Phase 3 | Complete |
| AGENT-02 | Phase 3 | Complete |
| AGENT-03 | Phase 3 | Complete |
| AGENT-04 | Phase 3 | Complete |
| AGENT-05 | Phase 3 | Complete |
| AGENT-06 | Phase 3 | Complete |
| PAGE-01 | Phase 3 | Complete |
| PAGE-02 | Phase 3 | Complete |
| PAGE-03 | Phase 3 | Complete |
| PAGE-04 | Phase 4 | Complete |
| PAGE-05 | Phase 4 | Complete |
| PAGE-06 | Phase 4 | Complete |
| PAGE-07 | Phase 4 | Complete |
| MCP-01 | Phase 4 | Complete |
| MCP-02 | Phase 4 | Complete |
| MCP-03 | Phase 4 | Complete |
| MCP-04 | Phase 4 | Complete |
| MCP-05 | Phase 4 | Complete |
| MCP-06 | Phase 4 | Complete |
| MULTI-01 | Phase 4 | Complete |
| MULTI-02 | Phase 4 | Complete |
| MULTI-03 | Phase 4 | Complete |
| MULTI-04 | Phase 4 | Complete |
| MULTI-05 | Phase 4 | Complete |
| FSB-01 | Phase 5 | Complete |
| FSB-02 | Phase 5 | Complete |
| FSB-03 | Phase 5 | Complete |
| FSB-04 | Phase 5 | Complete |
| FSB-05 | Phase 5 | Complete |
| FSB-06 | Phase 5 | Complete |
| FSBP-01 | Phase 8 | Planned |
| FSBP-02 | Phase 8 | Planned |
| FSBP-03 | Phase 8 | Planned |
| FSBP-04 | Phase 8 | Planned |
| FSBP-05 | Phase 8 | Planned |
| FSBP-06 | Phase 8 | Planned |
| UX-01 | Phase 7 | Complete |
| UX-02 | Phase 7 | Complete |
| UX-03 | Phase 7 | Complete |
| UX-04 | Phase 7 | Complete |
| UX-05 | Phase 7 | Complete |
| UX-06 | Phase 7 | Complete |
| ICON-01 | Phase 9 | Planned |
| ICON-02 | Phase 9 | Planned |
| ICON-03 | Phase 9 | Planned |
| ICON-04 | Phase 9 | Planned |
| THEME-01 | Phase 9 | Planned |
| THEME-02 | Phase 9 | Planned |
| THEME-03 | Phase 9 | Planned |
| FONT-01 | Phase 9 | Planned |
| LOGO-01 | Phase 9 | Planned |
| START-01 | Phase 10 | Planned |
| START-02 | Phase 10 | Planned |
| START-03 | Phase 10 | Planned |
| START-04 | Phase 10 | Planned |
| START-05 | Phase 10 | Planned |
| SUP-01 | Phase 4 | Complete |
| SUP-02 | Phase 4 | Complete |
| SUP-03 | Phase 6 | Complete |
| SUP-04 | Phase 6 | Complete |
| SUP-05 | Phase 6 | Complete |
| SEC-01 | Phase 5 | Complete |
| SEC-02 | Phase 3 | Complete |
| SEC-03 | Phase 3 | Complete |
| REL-01 | Phase 6 | Complete |
| REL-02 | Phase 6 | Complete |
| REL-03 | Phase 6 | Complete |

**Coverage:**
- v1 requirements: 75 total
- Mapped to phases: 75
- Unmapped: 0

---
*Requirements defined: 2026-06-16*
*Last updated: 2026-06-16 after milestone extension through Phase 10 with Prometheus design integration*
