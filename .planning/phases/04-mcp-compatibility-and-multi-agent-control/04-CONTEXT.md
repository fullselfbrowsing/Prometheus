# Phase 4: MCP Compatibility and Multi-Agent Control - Context

**Gathered:** 2026-06-16
**Status:** Ready for execution

<domain>
## Phase Boundary

Phase 4 adapts the Phase 3 native command spine toward FSB/MCP compatibility. It should expose a local MCP-style entry point, add common manual/read action tools, enforce basic multi-agent tab ownership, carry visual-session fields, and provide diagnostics. Full autopilot runtime, side panel UX, provider configuration, and remote supervision remain later phases.

</domain>

<decisions>
## Implementation Decisions

- Keep the browser-native JSON router as the source of truth.
- Add a dependency-free Node stdio MCP bridge that forwards tool calls to the native router.
- Add native tool aliases and manual actions to keep semantics close to FSB's existing tool names.
- Use server/browser-assigned `agent-*` identities derived from a connection/client label rather than trusting a caller-supplied identity as authority.
- Enforce tab ownership on mutating tools and return typed `TAB_OWNED_BY_OTHER_AGENT` errors.
- Accept implicit visual-session fields (`visual_reason`, `client`, `is_final`) and surface current actions through the browser status bar.

</decisions>

<verification>
## Verification Strategy

- Build Prometheus after native router changes.
- Run browser smoke and agent-control smoke.
- Add an MCP bridge smoke that starts Prometheus with the agent server, runs JSON-RPC initialize/tools/list/tools/call over stdio, and verifies a manual action and diagnostics.
- Confirm ownership rejection, compatibility errors, and diagnostics through the native smoke path.

</verification>
