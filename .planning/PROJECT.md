# FSB Browser

## What This Is

FSB Browser is an agent-native, lightweight desktop browser derived from the local Falkon/QtWebEngine codebase, but intended to become a fully FSB-owned browser product rather than a visible Falkon variant. It brings Full Self-Browsing's DOM-first automation, MCP control surface, task execution, memory, vault, observability, and live supervision into the browser itself instead of depending on a Chrome extension.

The browser is for AI agents and humans supervising them: agents should be able to inspect, script, click, type, navigate, configure, and recover across normal web pages, browser-owned pages, settings, tabs, extension surfaces, downloads, history, and other non-web UI through first-class native APIs.

## Core Value

Agents get fast, precise, auditable control of the whole browser through DOM/native structure, not screenshots, brittle extension injection, or human-only UI.

## Requirements

### Validated

(None yet - ship this browser to validate)

### Active

- [ ] Build on the local Falkon fork as the bootstrap browser engine while progressively replacing product identity, app shell, and agent-specific architecture with FSB-owned implementation.
- [ ] Preserve and improve FSB's existing MCP-compatible browser control surface, including manual action tools, read tools, autopilot, observability, vault flows, session lifecycle, and typed recovery errors.
- [ ] Provide native direct JavaScript execution for web pages where the browser can execute page scripts safely, with verification and read-back through DOM snapshots/page snapshots.
- [ ] Provide agent control over browser-owned and restricted surfaces that Chrome extensions cannot normally control, including settings, tabs, downloads, history, extension management surfaces if supported, and internal pages.
- [ ] Support full tab and window control for multiple concurrent agents, including ownership, isolation, background-tab execution where possible, reconnect recovery, and explicit concurrency limits.
- [ ] Port or reimplement FSB's DOM-first page understanding: element refs, selectors, forms, ARIA labels, hidden/structural controls, smart waiting, action verification, stuck detection, and change reports.
- [ ] Integrate a native MCP server or optimized bridge that remains compatible with existing FSB MCP client expectations where practical while removing extension-specific latency and failure modes.
- [ ] Rebuild FSB user-facing surfaces inside the browser: agent side panel, settings/control panel, diagnostics, logs, analytics, memory/site guides, vault, sync/dashboard entry points, and provider configuration.
- [ ] Use PhantomStream-style DOM-native live mirroring for supervised sessions and remote dashboard preview instead of pixel/video streaming as the primary architecture.
- [ ] Keep FSB's provider flexibility: xAI, Gemini, OpenAI, Anthropic, OpenRouter, LM Studio, and custom OpenAI-compatible endpoints, with live model discovery where supported.
- [ ] Theme the browser around the current FSB identity: dark/near-black surfaces, FSB orange action color, dense agent/operator dashboards, visible action glow, and FSB logos/assets rather than Falkon/KDE branding.
- [ ] Remove product-visible Falkon identity by the end state: app name, bundle IDs, desktop files, icons, default bookmarks, settings labels, docs, package names, window titles, and user-facing strings should be FSB-owned.
- [ ] Keep legally required third-party, GPL, Qt, KDE, and Falkon copyright/license notices and source-availability obligations intact.
- [ ] Keep the browser lightweight: avoid Electron, avoid screenshot-heavy control loops, minimize bundled services, and prefer native Qt/QtWebEngine integration plus small local agent services.

### Out of Scope

- Deleting required license or copyright notices - the product should be rebranded, but the inherited GPL and third-party obligations must remain satisfied.
- Stealth automation or account-abuse workflows - the browser should remain a supervised, auditable automation product.
- Pixel-first computer-use architecture as the primary strategy - screenshots can be fallback diagnostics, but the core bet is DOM/native structure.
- Hosted fleet control plane for v1 - local browser control, local MCP, and optional dashboard pairing come first.
- Rewriting the rendering engine from scratch - QtWebEngine/Falkon is the bootstrap path; replacement is about product architecture and surfaces, not implementing a browser engine.

## Context

The Full Self Browsing GitHub organization currently has four public repositories:

- `FSB` - Chrome extension and MCP bridge for DOM-first browser automation. Current README version is v0.9.72. It exposes 59 registered MCP handlers across manual actions, read tools, autopilot, observability, vault, and compatibility stubs.
- `Lattice` - TypeScript capability-first runtime SDK for AI applications, provider routing, policy, receipts, tools, survivability, and agent loops. Useful as an optional future runtime dependency or design reference, not a blocker for browser v1.
- `PhantomStream` - DOM-native live browser mirroring extracted from FSB. It streams one style-inlined DOM snapshot and MutationObserver diffs with stable node IDs, plus remote-control reverse mapping.
- `cmd-k` - Lightweight Tauri desktop utility for natural-language terminal commands. It is less central to this browser, but its native overlay, secure key storage, provider flexibility, and cross-platform packaging lessons are relevant.

The FSB website at `https://www.full-selfbrowsing.com` positions FSB as DOM-based browser automation that is faster and cheaper than vision-based tools. Its design language is black/near-black UI, orange primary accents (`#ff6b35`, `#ff8c42`), compact feature cards, agent/control-panel surfaces, and messaging around "Pure structural intelligence. Zero vision. Zero guessing."

The local `falkon/` directory is a separate Git checkout from KDE's Falkon repository. It is a QtWebEngine browser with CMake/KDE infrastructure, GPLv3 licensing, many existing product-visible Falkon/KDE strings, app IDs, icons, default bookmarks, plugin metadata, translations, and packaging files. It is a useful bootstrap browser shell, but it carries extensive rebrand and ownership work.

FSB extension capabilities to preserve or improve include:

- DOM snapshots, page snapshots, read-page, text/attribute reads, site guides, and memory search.
- Manual action tools such as `execute_js`, `navigate`, `click`, `type_text`, `press_key`, `scroll`, `drag`, `drop_file`, `fill_sheet`, tab controls, and coordinate tools.
- Autopilot tools: `run_task`, `stop_task`, and `get_task_status`.
- Multi-agent tab ownership, typed errors (`TAB_NOT_OWNED`, `AGENT_CAP_REACHED`, `TAB_INCOGNITO_NOT_SUPPORTED`, `TAB_OUT_OF_SCOPE`), reconnect grace, and background-tab execution where safe.
- Implicit visual session contract with `visual_reason`, `client`, and `is_final`.
- Vault boundaries for credentials and payment methods.
- Session logs, diagnostics, analytics, cost/token accounting, telemetry controls, and dashboard sync.

## Constraints

- **Base architecture**: Start from Falkon/QtWebEngine - this gives a working browser, tabs, networking, downloads, settings, and packaging surface quickly.
- **Licensing**: Falkon is GPLv3-or-later in the inspected source - redistributed modified versions must preserve license terms, source availability, and appropriate legal notices.
- **Branding**: Product-visible identity should become FSB-owned - no Falkon/KDE-facing app identity in the final user experience except required legal attribution.
- **Agent control**: Internal browser pages need native automation APIs - content-script-only approaches cannot satisfy settings, extension pages, and restricted surfaces.
- **Compatibility**: Existing `fsb-mcp-server` clients should keep working where practical - optimize or replace the bridge internally without casually breaking tool names and contracts.
- **Performance**: DOM/native inspection and action verification should remain the core control loop - avoid vision-only approaches except as fallback.
- **Security**: JavaScript execution, vault use, internal-page control, and remote dashboard control need explicit permission boundaries, audit logs, and visible user supervision.
- **Initial platform assumption**: macOS-first validation in this workspace, with Qt/CMake decisions kept compatible with Linux and Windows unless doing so blocks progress.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Use `FSB Browser` as the working product name | Keeps the existing FSB identity while distinguishing this from the Chrome extension. | - Pending |
| Start from the local Falkon fork | It provides a lightweight QtWebEngine browser foundation immediately. | - Pending |
| Rebrand product-visible Falkon identity but preserve legal notices | The desired end state is not visibly Falkon, but GPL/copyleft obligations still apply. | - Pending |
| Make agent-native browser control the first product wedge | This is the main advantage over the Chrome extension and solves restricted/internal page control. | - Pending |
| Preserve FSB MCP compatibility while moving the implementation native | Existing FSB users and agents should not lose the tool contract, but the browser can remove extension bridge limitations. | - Pending |
| Use PhantomStream as the live supervision reference architecture | DOM-native mirroring matches FSB's structural-intelligence philosophy and avoids video-stream cost/latency. | - Pending |
| Treat Lattice as optional architecture leverage | Lattice may help provider routing, policy, receipts, and agent runtime, but browser v1 should not depend on completing Lattice integration. | - Pending |
| Prioritize agent core before full FSB parity | A usable native agent browser should land before every extension dashboard and analytics surface is rebuilt. | - Pending |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `$gsd-transition`):
1. Requirements invalidated? -> Move to Out of Scope with reason
2. Requirements validated? -> Move to Validated with phase reference
3. New requirements emerged? -> Add to Active
4. Decisions to log? -> Add to Key Decisions
5. "What This Is" still accurate? -> Update if drifted

**After each milestone** (via `$gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check - still the right priority?
3. Audit Out of Scope - reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-06-16 after initialization*
