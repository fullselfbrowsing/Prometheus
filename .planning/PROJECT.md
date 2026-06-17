# Prometheus

## What This Is

Prometheus is an agent-native, lightweight desktop browser derived from the local Falkon/QtWebEngine codebase, branded as **Prometheus** with the affiliation/tagline **Powered by FSB**. It is intended to become a fully FSB-powered browser product rather than a visible Falkon variant. It brings Full Self-Browsing's DOM-first automation, MCP control surface, task execution, memory, vault, observability, and live supervision into the browser itself instead of depending on a Chrome extension.

The browser is for AI agents and humans supervising them: agents should be able to inspect, script, click, type, navigate, configure, and recover across normal web pages, browser-owned pages, settings, tabs, extension surfaces, downloads, history, and other non-web UI through first-class native APIs.

## Core Value

Agents get fast, precise, auditable control of the whole browser through DOM/native structure, not screenshots, brittle extension injection, or human-only UI.

## Current State

**Shipped: v1.0 MVP (2026-06-17)** — all 10 phases, 51 plans complete.

Prometheus is a working agent-native desktop browser built on the Falkon/QtWebEngine fork. v1.0 delivered a buildable, legally-inventoried baseline; Prometheus product identity with the "Powered by FSB" affiliation; a native agent command router with surface adapters, permissioned JS execution, and DOM/page reads; FSB-compatible MCP tooling with multi-agent ownership, typed errors, and visual-session fields; native FSB runtime surfaces (side panel, providers, autopilot, logs, memory/site guides, secure vault); PhantomStream-style supervision, safe pairing, and a local macOS validation package; compact Safari-style chrome with advanced tab management; a native FSB-Plus control center with a release-gated feature parity matrix; an offline Font Awesome Free icon system with Poppins/Space Mono brand fonts and warm dark/light themes; and a Prometheus start page.

v1.0 is code-complete and statically verified (177/177 build targets link, code review and parity gates pass). 26 human-visual verification items across phases 08/09/10 require a live binary run and are carried forward as deferred items (see STATE.md). The internal Falkon → Prometheus namespace/class rename and a notarized public macOS release also remain deferred.

## Next Milestone Goals

- Run the deferred human-visual verification pass on a live build and close the 26 outstanding UAT items.
- Complete the internal Falkon → Prometheus namespace/class/library rename (product-visible identity is done; internal symbols are not).
- Produce a notarized, distributable macOS release beyond the current local validation package.
- Ship polished Linux and Windows builds after macOS-first validation (V2-01).
- Evaluate Lattice for provider routing, receipts, policy, or agent runtime (V2-02).
- Add hosted/fleet control and advanced extension-ecosystem compatibility once local control is validated (V2-03, V2-04).

## Requirements

### Validated

- ✓ Build on the local Falkon fork as the bootstrap engine while progressively replacing product identity, app shell, and agent architecture with Prometheus-owned, FSB-powered implementation — v1.0
- ✓ Preserve and improve FSB's MCP-compatible browser control surface: manual action tools, read tools, autopilot, observability, vault flows, session lifecycle, typed recovery errors — v1.0
- ✓ Native direct JavaScript execution for web pages with verification and read-back through DOM/page snapshots — v1.0
- ✓ Agent control over browser-owned and restricted surfaces Chrome extensions cannot reach: settings, tabs, internal pages — v1.0
- ✓ Full tab and window control for multiple concurrent agents: ownership, isolation, background-tab execution, reconnect recovery, concurrency caps — v1.0
- ✓ FSB's DOM-first page understanding: element refs, selectors, forms, ARIA labels, smart waiting, action verification, stuck detection, change reports — v1.0
- ✓ Native MCP bridge compatible with existing FSB MCP client expectations while removing extension-specific latency and failure modes — v1.0
- ✓ FSB user-facing surfaces inside the browser: agent side panel, settings/control panel, diagnostics, logs, memory/site guides, vault, provider configuration — v1.0
- ✓ Native FSB-plus control center matching or improving every FSB feature category through a maintained, release-gated parity matrix — v1.0
- ✓ PhantomStream-style DOM-native live supervision for supervised sessions and remote preview — v1.0
- ✓ Provider flexibility: xAI, Gemini, OpenAI, Anthropic, OpenRouter, LM Studio, and custom OpenAI-compatible endpoints — v1.0
- ✓ Minimal Prometheus identity: restrained native surfaces, sparse FSB orange accents, clear supervised/action states, warm dark/light themes — v1.0
- ✓ Bundled offline Font Awesome Free icons plus Poppins/Space Mono brand fonts, with attribution and release validation — v1.0
- ✓ Product-visible Falkon identity removed: app name, titles, icons, bookmarks, settings labels, user-facing strings are Prometheus-owned, "Powered by FSB" as affiliation — v1.0 (internal symbol rename deferred)
- ✓ Required third-party, GPL, Qt, KDE, and Falkon copyright/license notices and source-availability obligations kept intact — v1.0
- ✓ Lightweight architecture: no Electron, no screenshot-heavy control loops, native Qt/QtWebEngine plus small local agent services — v1.0
- ✓ Compact Safari-style chrome: tabs share the toolbar, active tab becomes the address/search field, separate layout stays optional — v1.0 (Phase 7)
- ✓ Advanced native tab management: groups, overview/search, quick switch, close/restore, unload/suspend, duplicate, detach, ownership, health, supervision — v1.0 (Phase 7)

### Active

(Forward-looking candidates for the next milestone — define fresh requirements via `/gsd-new-milestone`.)

- [ ] Close the 26 deferred human-visual verification items on a live binary build.
- [ ] Complete the internal Falkon → Prometheus namespace/class/library rename.
- [ ] Produce a notarized, distributable macOS release beyond the local validation package.
- [ ] Ship polished Linux and Windows builds (V2-01).
- [ ] Evaluate Lattice for provider routing, receipts, policy, or agent runtime (V2-02).
- [ ] Hosted/fleet control after local control is validated (V2-03).
- [ ] Advanced extension-ecosystem compatibility where QtWebEngine/Falkon surfaces make it practical (V2-04).

### Out of Scope

- Deleting required license or copyright notices — the product is rebranded, but inherited GPL and third-party obligations must remain satisfied.
- Stealth automation or account-abuse workflows — the browser remains a supervised, auditable automation product.
- Pixel-first computer-use architecture as the primary strategy — screenshots are fallback diagnostics only; the core bet is DOM/native structure.
- Hosted fleet control plane for v1 — local browser control, local MCP, and optional dashboard pairing came first (revisit next milestone, V2-03).
- Rewriting the rendering engine from scratch — QtWebEngine/Falkon is the bootstrap path; replacement is about product architecture and surfaces, not a browser engine.

## Context

**v1.0 codebase state (2026-06-17):** The browser is built on the Falkon/QtWebEngine fork, tracked as a separate `falkon/` checkout; this planning repo holds the GSD artifacts. The macOS build links 177/177 targets. Prometheus-specific work spans the native agent command router and adapters, the MCP bridge, the native side panel and FSB-Plus control center, compact chrome and tab management, the offline icon/font/theme system, and the start page. The output is a local macOS validation package, not yet a notarized public release.

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
| Start from the local Falkon fork | It provides a lightweight QtWebEngine browser foundation immediately. | ✓ Good — fork built and shipped v1.0 (177/177 targets link) |
| Rebrand product-visible Falkon identity but preserve legal notices | The desired end state is not visibly Falkon, but GPL/copyleft obligations still apply. | ✓ Good — Phase 2 rebranded product surfaces; legal notices preserved (internal symbol rename deferred) |
| Make agent-native browser control the first product wedge | This is the main advantage over the Chrome extension and solves restricted/internal page control. | ✓ Good — Phase 3 native command spine + Phase 4 MCP shipped |
| Preserve FSB MCP compatibility while moving the implementation native | Existing FSB users and agents should not lose the tool contract, but the browser can remove extension bridge limitations. | ✓ Good — Phase 4 native MCP bridge with compatible tools and typed errors |
| Use a native Prometheus sidebar plus `AgentRuntime` for FSB runtime parity | Native UI keeps provider/vault secrets out of MCP/agent transports while sharing task/log/provider state with the router and MCP bridge. | - Accepted |
| Use PhantomStream as the live supervision reference architecture | DOM-native mirroring matches FSB's structural-intelligence philosophy and avoids video-stream cost/latency. | - Accepted |
| Ship a local validation artifact before notarized public release work | A repeatable macOS tarball with legal/source notices gives a concrete release candidate while notarization and polished distribution stay separate. | - Accepted |
| Treat Lattice as optional architecture leverage | Lattice may help provider routing, policy, receipts, and agent runtime, but browser v1 should not depend on completing Lattice integration. | — Deferred to v2 — v1.0 shipped without Lattice (V2-02) |
| Prioritize agent core before full FSB parity | A usable native agent browser should land before every extension dashboard and analytics surface is rebuilt. | ✓ Good — agent core landed Phases 3-4; FSB-plus parity completed Phase 8 |
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
*Last updated: 2026-06-17 after v1.0 MVP milestone*
