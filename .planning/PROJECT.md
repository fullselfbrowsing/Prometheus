# Prometheus

## What This Is

Prometheus is an agent-native, lightweight desktop browser derived from the local Falkon/QtWebEngine codebase, branded as **Prometheus** with the affiliation/tagline **Powered by FSB**. It is intended to become a fully FSB-powered browser product rather than a visible Falkon variant. It brings Full Self-Browsing's DOM-first automation, MCP control surface, task execution, memory, vault, observability, and live supervision into the browser itself instead of depending on a Chrome extension.

The browser is for AI agents and humans supervising them: agents should be able to inspect, script, click, type, navigate, configure, and recover across normal web pages, browser-owned pages, settings, tabs, extension surfaces, downloads, history, and other non-web UI through first-class native APIs.

## Core Value

Agents get fast, precise, auditable control of the whole browser through DOM/native structure, not screenshots, brittle extension injection, or human-only UI.

## Current State

Phase 7 is complete. Prometheus now has optional compact Safari-style browser chrome, native tab groups, tab overview/search, quick switch, advanced tab operations, and agent-aware tab state with ownership/supervision safeguards verified by smoke tests, focused Qt tests, code review, and human visual approval.

## Requirements

### Validated

- [x] Validated in Phase 7: Provide compact native browser chrome similar in spirit to Safari's compact layout: tabs share the toolbar, the active tab becomes the address/search field, and the layout remains optional for users who prefer separate tabs.
- [x] Validated in Phase 7: Provide advanced native tab management for humans and agents: tab groups, overview/search, quick switch, close/restore, unload/suspend, duplicate, detach, ownership, health, and supervision state.

### Active

- [ ] Build on the local Falkon fork as the bootstrap browser engine while progressively replacing product identity, app shell, and agent-specific architecture with Prometheus-owned, FSB-powered implementation.
- [ ] Preserve and improve FSB's existing MCP-compatible browser control surface, including manual action tools, read tools, autopilot, observability, vault flows, session lifecycle, and typed recovery errors.
- [ ] Provide native direct JavaScript execution for web pages where the browser can execute page scripts safely, with verification and read-back through DOM snapshots/page snapshots.
- [ ] Provide agent control over browser-owned and restricted surfaces that Chrome extensions cannot normally control, including settings, tabs, downloads, history, extension management surfaces if supported, and internal pages.
- [ ] Support full tab and window control for multiple concurrent agents, including ownership, isolation, background-tab execution where possible, reconnect recovery, and explicit concurrency limits.
- [ ] Port or reimplement FSB's DOM-first page understanding: element refs, selectors, forms, ARIA labels, hidden/structural controls, smart waiting, action verification, stuck detection, and change reports.
- [ ] Integrate a native MCP server or optimized bridge that remains compatible with existing FSB MCP client expectations where practical while removing extension-specific latency and failure modes.
- [ ] Rebuild FSB user-facing surfaces inside the browser: agent side panel, settings/control panel, diagnostics, logs, analytics, memory/site guides, vault, sync/dashboard entry points, and provider configuration.
- [ ] Upgrade the Prometheus side panel into a native FSB-plus control center that explicitly matches or improves every FSB feature category through a maintained parity matrix.
- [ ] Use PhantomStream-style DOM-native live mirroring for supervised sessions and remote dashboard preview instead of pixel/video streaming as the primary architecture.
- [ ] Keep FSB's provider flexibility: xAI, Gemini, OpenAI, Anthropic, OpenRouter, LM Studio, and custom OpenAI-compatible endpoints, with live model discovery where supported.
- [ ] Theme the browser around a minimal Prometheus identity: restrained native surfaces, sparse FSB orange action accents, clear supervised/action states, and no decorative visual noise.
- [ ] Use bundled offline Font Awesome Free assets for common native UI icons where licensing permits, with attribution and release validation, instead of relying on network or platform theme availability.
- [ ] Remove product-visible Falkon identity by the end state: app name, bundle IDs, desktop files, icons, default bookmarks, settings labels, docs, package names, window titles, and user-facing strings should be Prometheus-owned, with "Powered by FSB" used as the explicit affiliation/tagline where appropriate.
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

Additional milestone-extension research on 2026-06-16 clarified three product targets:

- FSB's current public feature bar includes 50+ browser actions, smart DOM analysis, visual feedback, site intelligence, MCP integration, remote dashboard pairing, memory, provider flexibility, vault flows, and 59 registered MCP handlers. Prometheus should maintain a parity matrix and only call a category complete when the native browser version is verified.
- Safari's compact tab layout is a useful UX reference because it moves tabs into the toolbar and makes the active tab the Smart Search field, while still allowing separate tab layout and tab title/icon preferences. Prometheus should borrow the space-saving model, not copy Safari branding or platform-specific implementation details.
- Font Awesome Free is usable offline in a GPL-friendly project when the relevant icon/font/code licenses and attribution comments are preserved. Prometheus should bundle a curated subset in Qt resources and validate that icons do not depend on network or host theme availability.

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
- **Branding**: Product-visible identity should become Prometheus-owned and FSB-powered - no Falkon/KDE-facing app identity in the final user experience except required legal attribution. The app name is `Prometheus`; the affiliation/tagline is `Powered by FSB`.
- **Agent control**: Internal browser pages need native automation APIs - content-script-only approaches cannot satisfy settings, extension pages, and restricted surfaces.
- **Compatibility**: Existing `fsb-mcp-server` clients should keep working where practical - optimize or replace the bridge internally without casually breaking tool names and contracts.
- **Performance**: DOM/native inspection and action verification should remain the core control loop - avoid vision-only approaches except as fallback.
- **Security**: JavaScript execution, vault use, internal-page control, and remote dashboard control need explicit permission boundaries, audit logs, and visible user supervision.
- **Initial platform assumption**: macOS-first validation in this workspace, with Qt/CMake decisions kept compatible with Linux and Windows unless doing so blocks progress.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Use `Prometheus` as the product name with `Powered by FSB` as the affiliation/tagline | Creates a distinct browser product identity while preserving the FSB brand connection. | - Accepted |
| Start from the local Falkon fork | It provides a lightweight QtWebEngine browser foundation immediately. | - Pending |
| Rebrand product-visible Falkon identity but preserve legal notices | The desired end state is not visibly Falkon, but GPL/copyleft obligations still apply. | - Pending |
| Make agent-native browser control the first product wedge | This is the main advantage over the Chrome extension and solves restricted/internal page control. | - Pending |
| Preserve FSB MCP compatibility while moving the implementation native | Existing FSB users and agents should not lose the tool contract, but the browser can remove extension bridge limitations. | - Pending |
| Use a native Prometheus sidebar plus `AgentRuntime` for FSB runtime parity | Native UI keeps provider/vault secrets out of MCP/agent transports while sharing task/log/provider state with the router and MCP bridge. | - Accepted |
| Use PhantomStream as the live supervision reference architecture | DOM-native mirroring matches FSB's structural-intelligence philosophy and avoids video-stream cost/latency. | - Accepted |
| Ship a local validation artifact before notarized public release work | A repeatable macOS tarball with legal/source notices gives a concrete release candidate while notarization and polished distribution stay separate. | - Accepted |
| Treat Lattice as optional architecture leverage | Lattice may help provider routing, policy, receipts, and agent runtime, but browser v1 should not depend on completing Lattice integration. | - Pending |
| Prioritize agent core before full FSB parity | A usable native agent browser should land before every extension dashboard and analytics surface is rebuilt. | - Pending |
| Extend v1.0 beyond the initial release-hardening milestone for native UX polish | The first six phases produced a functional agent-native browser, but the product still needs explicit FSB-plus parity, compact chrome, native tab management, offline icons, and minimal themes before claiming the intended product bar. | - Accepted |
| Use Safari compact mode as an interaction reference, not a visual clone | Compact tabs in the toolbar and active-tab address/search behavior are useful, but Prometheus should keep its own minimal native identity and agent/supervision affordances. | - Accepted |
| Use Font Awesome Free as a curated offline icon source | Font Awesome Free is GPL-friendly when licenses and attribution are preserved; bundling a curated subset improves deterministic native icon rendering. | - Accepted |

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
*Last updated: 2026-06-16 after Phase 7 verification*
