# Architecture Research

**Domain:** Agent-native desktop browser
**Researched:** 2026-06-16
**Confidence:** MEDIUM

## Standard Architecture

### System Overview

```text
FSB Browser App (Qt/C++)
  Browser chrome
    Tabs, windows, address bar, downloads, history, settings
  Web engine
    QtWebEngine profiles, pages, scripts, permissions, network hooks
  Internal surfaces
    fsb://settings, fsb://agents, fsb://logs, fsb://memory, fsb://vault
  Agent control core
    Native command router, page adapters, internal-page adapters, tab ownership
  FSB automation runtime
    DOM snapshots, action execution, JS execution, wait/verify, change reports
  Local agent interfaces
    MCP stdio/http, WebSocket bridge if needed, dashboard pairing
  Storage/security
    Settings, provider keys, vault, sessions, memory, logs, audit records
  Supervision
    Visual session overlay, PhantomStream DOM mirror, diagnostics
```

### Component Responsibilities

| Component | Responsibility | Typical Implementation |
|-----------|----------------|------------------------|
| Browser shell | Human browser UI and native app lifecycle | Rebrand and refactor Falkon Qt widgets. |
| Page adapter | Web-page reads/actions/JS | QtWebEngine page scripts plus native event APIs. |
| Internal surface adapter | Settings/history/downloads/extensions control | Structured native commands, not scraped UI. |
| MCP server | Public agent tool contract | TypeScript Node service or native process with compatibility adapter. |
| Tool registry | Single source of truth for tool schemas/routes | Start from FSB tool definitions and mark native routes. |
| Agent registry | Tab ownership and concurrency | Native state persisted across reconnects. |
| Verification layer | Post-action checks and stuck detection | DOM snapshots, load state, mutation/state diffs. |
| Vault/security layer | Provider keys and sensitive autofill | Native secure storage plus visible consent flows. |
| Supervision layer | Human-visible session state | Visual badge/overlay and PhantomStream mirror. |

## Recommended Project Structure

The initial repo is Falkon, so the first phase should avoid inventing a new tree before the build works. Over time, isolate FSB-owned modules:

```text
falkon/
  src/
    main/                 # App entrypoint and bundle identity
    lib/                  # Existing Falkon browser internals
    fsb/                  # New FSB-owned agent/browser modules
      agent/              # Tool router, ownership, permissions
      mcp/                # Native bridge/server integration
      pages/              # Internal fsb:// pages and command models
      automation/         # DOM snapshot, actions, waits, verification
      supervision/        # Visual session, PhantomStream integration
      security/           # Vault, provider config, audit boundaries
  packaging/ or platform dirs
  docs/legal/             # Required third-party and fork attribution
```

### Structure Rationale

- **Keep Falkon stable first:** prove build and rebrand before moving core modules.
- **Add `src/fsb/`:** gives new code a clear ownership boundary from inherited browser code.
- **Separate page and internal adapters:** web pages and browser-owned pages need different security and execution models.
- **Keep tool schemas central:** MCP, side panel, and autopilot must not drift.

## Architectural Patterns

### Pattern 1: Native Tool Router

**What:** Route every action through a single command layer with schema validation, permissions, tab ownership, execution, and verification.

**When to use:** All MCP, side-panel, and autopilot actions.

**Trade-offs:** More upfront structure, but avoids three separate action implementations.

### Pattern 2: Adapter Per Surface Type

**What:** Treat web pages, internal pages, settings, downloads/history, and extension surfaces as different adapters behind one tool contract.

**When to use:** Any tool that can target both a URL page and browser UI.

**Trade-offs:** More explicit routing, but avoids unsafe JS injection into privileged UI.

### Pattern 3: DOM-Native Supervision

**What:** Use PhantomStream-style snapshot/diff mirroring for web content, with native overlays for browser chrome/internal pages.

**When to use:** Remote dashboard, live supervision, replay/debugging.

**Trade-offs:** More complex than screenshots, but keeps semantic handles and lower bandwidth.

## Data Flow

### MCP Manual Action Flow

```text
MCP client
  -> MCP server/bridge
  -> Tool schema validation
  -> Agent/tab ownership gate
  -> Surface adapter selection
  -> Native/page execution
  -> Wait/verification
  -> Change report + logs + visual session update
  -> MCP response
```

### Internal Page Control Flow

```text
Agent command
  -> Native command router
  -> Settings/downloads/history model
  -> State mutation or query
  -> UI update
  -> Audit log + structured response
```

### Supervision Flow

```text
Page/internal state
  -> DOM snapshot or native surface snapshot
  -> PhantomStream/overlay transport
  -> Dashboard/viewer
  -> Optional remote-control action
  -> Tool router
```

## Integration Points

| Boundary | Communication | Notes |
|----------|---------------|-------|
| MCP client to browser | stdio/http/WebSocket bridge | Preserve FSB tool names where practical. |
| Native browser to web page | QtWebEngine scripts/events | Must handle page lifecycle and reinjection. |
| Agent core to internal pages | Native C++ command APIs | Do not rely on visual clicking for settings/history/downloads. |
| Browser to dashboard | PhantomStream/WebSocket | Session-stamped messages and backpressure required. |
| Browser to providers | FSB provider layer or Lattice later | Keep provider config secure and auditable. |

## Anti-Patterns

### Anti-Pattern 1: Extension-Port Thinking

**What people do:** Port FSB content scripts and assume the browser is just another Chrome profile.
**Why it is wrong:** It misses the browser-native advantage and preserves extension restrictions.
**Do this instead:** Build a native command layer and use content/page scripts only where appropriate.

### Anti-Pattern 2: Rebrand Before Build Safety

**What people do:** Bulk replace every string and filename before proving the fork builds.
**Why it is wrong:** Breaks CMake, translations, plugins, app IDs, and packaging in one opaque change.
**Do this instead:** Establish build baseline, then rebrand in audited layers.

### Anti-Pattern 3: MCP Drift

**What people do:** Create new browser tools while leaving FSB MCP compatibility untested.
**Why it is wrong:** Existing FSB agents and skills lose the contract.
**Do this instead:** Use contract tests from FSB tool definitions.

## Sources

- Local Falkon CMake/source structure.
- FSB architecture and MCP docs.
- FSB tool registry.
- PhantomStream architecture.
- Lattice agent/provider design as optional reference.

---
*Architecture research for: FSB Browser*
*Researched: 2026-06-16*
