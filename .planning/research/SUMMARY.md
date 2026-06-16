# Project Research Summary

**Project:** FSB Browser
**Domain:** Agent-native desktop browser
**Researched:** 2026-06-16
**Confidence:** MEDIUM

## Executive Summary

FSB Browser should be treated as a browser-native implementation of FSB, not merely a Chrome-extension port. The local Falkon fork gives a working QtWebEngine browser foundation, but the product value comes from a native agent control layer that can operate on both web pages and browser-owned surfaces such as settings, tabs, history, downloads, and extension management if supported.

The safest strategy is phased: first prove the Falkon build and establish legal/rebrand boundaries, then replace product-visible identity, then build the native agent control core, then restore FSB MCP compatibility and FSB feature parity on top. PhantomStream is the strongest live-supervision reference because it matches FSB's DOM-first philosophy and avoids screenshot/video weaknesses.

The main risks are license mistakes during rebrand, preserving extension limitations by copying FSB too literally, breaking the browser build through broad renames, unsafe direct JavaScript execution, and drifting from the existing FSB MCP contract.

## Key Findings

### Recommended Stack

Use Falkon/QtWebEngine/CMake/C++ as the browser base. Use TypeScript/Node for MCP compatibility where it accelerates reuse, but keep the browser control layer native enough to manage internal pages. Use PhantomStream-style DOM mirroring for supervision. Treat Lattice as optional leverage for provider routing, receipts, policy, and agent loops after the browser control path is proven.

**Core technologies:**
- Qt 6 / QtWebEngine - browser shell and rendering.
- CMake/C++ - native browser integration and packaging.
- MCP stdio/http/WebSocket - public agent interface.
- TypeScript/Node - existing FSB MCP compatibility and schema tooling.
- PhantomStream - DOM-native session supervision.

### Expected Features

**Must have:**
- Buildable FSB-branded browser shell.
- Core FSB MCP manual/read tool compatibility.
- Direct JS execution on web pages with verification.
- Native control over at least one browser-owned internal surface.
- Multi-agent tab ownership and typed errors.
- Product-visible Falkon rebrand with legal notices preserved.

**Should have:**
- Full FSB side panel/control panel parity.
- Vault, memory, logs, analytics, and provider configuration.
- PhantomStream dashboard preview.
- Autopilot parity.

**Defer:**
- Hosted control plane.
- Lattice as a hard dependency.
- Browser engine rewrite.

### Architecture Approach

Create a native command router that validates tools, enforces permissions and tab ownership, selects a surface adapter, executes the action, waits for observable state, verifies the result, and returns a change report. Web pages, internal browser pages, and remote dashboard supervision should be separate adapters behind one agent-facing contract.

**Major components:**
1. Browser shell - rebranded Falkon/Qt app.
2. Agent control core - tool router, ownership, permissions, command adapters.
3. FSB automation runtime - DOM snapshots, JS/actions, waits, verification, stuck detection.
4. MCP compatibility layer - existing FSB tool contract over native routes.
5. Supervision/security layer - visual session, PhantomStream, vault, logs, audit.

### Critical Pitfalls

1. **License removal during rebrand** - keep legal notices separate from product identity.
2. **Extension-port thinking** - internal pages require native command APIs.
3. **Build breakage during rebrand** - rename by layer and build after each layer.
4. **Unsafe JS execution** - require permissions, audit logs, and read-back verification.
5. **MCP drift** - contract-test existing FSB tool names and typed errors.

## Implications for Roadmap

### Phase 1: Baseline, Legal Inventory, and Build Proof
**Rationale:** A browser fork must build before large rebrand or agent work.
**Delivers:** Build baseline, source/license inventory, Falkon identity map, FSB repo capability map.
**Avoids:** License and build-breakage pitfalls.

### Phase 2: Product Identity and Lightweight FSB Shell
**Rationale:** The user explicitly wants the end state to no longer look like Falkon.
**Delivers:** Primary app name, icons, bundle IDs, desktop/appdata, default bookmarks, first-run/about surfaces, FSB theme.
**Avoids:** Partial rebrand.

### Phase 3: Native Agent Control Spine
**Rationale:** Whole-browser control is the unique browser-native advantage.
**Delivers:** Tool router, tab/window model, internal-page command proof, JS execution, read/snapshot primitives, logs.
**Avoids:** Extension-port thinking.

### Phase 4: FSB MCP Compatibility and Multi-Agent Execution
**Rationale:** Existing FSB agents should be able to drive the browser.
**Delivers:** MCP server/bridge, manual/read tool parity, typed errors, ownership, queueing, visual-session fields.
**Avoids:** MCP drift and unsafe concurrency.

### Phase 5: FSB Runtime Parity Surfaces
**Rationale:** After the control spine works, rebuild the full product experience.
**Delivers:** Side panel, settings/control panel, providers, vault, memory/site guides, logs, analytics, autopilot.
**Uses:** Existing FSB UI/feature contract adapted to native browser.

### Phase 6: Supervision, PhantomStream, Packaging, and Release Hardening
**Rationale:** The browser needs supervised operation and installable artifacts.
**Delivers:** PhantomStream dashboard preview, remote-control pairing, packaging, smoke tests, release docs, legal bundle.
**Avoids:** Demo-only product state.

### Phase Ordering Rationale

- Build and legal inventory come before rebrand because Falkon names are mixed through code, packaging, and legal files.
- Native control comes before full FSB parity because the browser-native differentiator is control over surfaces the extension cannot reach.
- MCP compatibility follows the control spine so existing tool contracts map to real native routes rather than temporary stubs.
- Full parity and dashboard work come after core action/read reliability.

### Research Flags

- **Phase 1:** Build tooling and local platform dependencies need live validation.
- **Phase 3:** QtWebEngine script injection, internal-page command architecture, and secure JS execution need deeper implementation research.
- **Phase 4:** MCP compatibility needs contract tests against existing FSB tool definitions.
- **Phase 6:** Packaging/notarization/update strategy needs platform-specific research.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | MEDIUM | Local Falkon and FSB manifests verified; exact Qt/platform build state still needs validation. |
| Features | HIGH | Existing FSB feature set is well documented in cloned repos. |
| Architecture | MEDIUM | Direction is clear; exact QtWebEngine seams need implementation research. |
| Pitfalls | MEDIUM | Based on local source inspection and FSB project history. |

**Overall confidence:** MEDIUM

### Gaps to Address

- Exact product name may change; currently using `FSB Browser`.
- Target platform beyond macOS-first is assumed but not confirmed.
- QtWebEngine support for desired extension-management surfaces needs validation.
- Legal/compliance should be treated as engineering constraints, not final legal advice.

## Sources

### Primary (HIGH confidence)
- https://github.com/fullselfbrowsing/FSB - current FSB README, MCP docs, extension manifest, tool registry.
- https://github.com/fullselfbrowsing/PhantomStream - DOM streaming architecture.
- Local `falkon/` checkout - browser source, build files, GPL COPYING, rebrand inventory.
- https://www.full-selfbrowsing.com - current brand and product positioning.

### Secondary (MEDIUM confidence)
- https://github.com/fullselfbrowsing/Lattice - optional runtime/provider/agent design reference.
- https://github.com/fullselfbrowsing/cmd-k - native app/provider/storage design reference.

---
*Research completed: 2026-06-16*
*Ready for roadmap: yes*
