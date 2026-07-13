---
phase: 19-mcp-bridge-and-multi-agent-runtime-compatibility
plan: 06
subsystem: external-stdio-mcp-bridge
tags: [node, mcp, stdio, json-rpc, framing, loopback, sessions, compatibility]

requires:
  - phase: 19-01
    provides: Frozen clean-room 90-name catalog, schemas, errors, and fixtures
  - phase: 19-05
    provides: Authenticated loopback gateway and owner-only endpoint descriptor
provides:
  - Dependency-free Node 20 external stdio MCP entry point
  - Newline and archived Content-Length framing with complete MCP lifecycle
  - Secure descriptor discovery and one browser-issued session lifecycle
  - Exact 90-name manifest-backed native, alias, deferred, unsupported, and removed behavior
  - Optional visual metadata preservation and sanitized ten-component diagnostics
affects: [19-07, 20, 21, 22, 24]

key-files:
  created:
    - tools/prometheus-mcp/bin/prometheus-mcp.mjs
    - tools/prometheus-mcp/src/framing.mjs
    - tools/prometheus-mcp/src/protocol.mjs
    - tools/prometheus-mcp/src/native-client.mjs
    - tools/prometheus-mcp/src/session.mjs
    - tools/prometheus-mcp/src/server.mjs
    - tools/prometheus-mcp/src/tool-handler.mjs
    - tools/prometheus-mcp/test/tools.test.mjs
  modified:
    - tools/prometheus-mcp/package.json
    - tools/prometheus-mcp/test/transport.test.mjs
    - tools/prometheus-mcp/test/native-client.test.mjs
    - tools/prometheus-mcp/test/visual-session.test.mjs
    - tools/prometheus-mcp/test/diagnostics.test.mjs
    - tools/prometheus-mcp/test/errors.test.mjs

requirements-completed: []
requirements-progressed: [MCP-01, MCP-02, MCP-03, MCP-04, MCP-05, MCP-06, MCP-07]

duration: 40min
completed: 2026-07-13
---

# Phase 19 Plan 06: External Stdio MCP Bridge Summary

**External MCP hosts can now launch a Prometheus-owned, dependency-free Node adapter that speaks both supported stdio framing modes, owns one authenticated browser session, and exposes the frozen 90-name compatibility surface without embedding any agent runtime.**

## Accomplishments

- Added an executable Node entry point using built-in modules only. It launches no browser, agent CLI, terminal, engine, prompt provisioner, or third-party runtime; the external host remains responsible for process launch.
- Implemented a bounded streaming parser that locks to newline or archived Content-Length framing from the first message, supports fragmented UTF-8 and multiple frames, mirrors response framing, and rejects malformed, duplicate-length, invalid-UTF-8, and greater-than-1-MiB input.
- Implemented MCP initialize/initialized negotiation for `2025-11-25`, `2025-06-18`, `2025-03-26`, and `2024-11-05`, plus ping, tools/list, tools/call, JSON-RPC errors, notifications, request-id tracking, cancellation, EOF, signals, and a two-second graceful drain.
- Kept stdout protocol-only and diagnostics on stderr through fixed, content-free categories. Cancellation, browser failures, descriptor secrets, session ids, profile paths, page content, scripts, and visual reasons are not logged.
- Added exact default descriptor discovery at the same per-user temp child used by Chromium, with absolute override only, lstat/non-symlink validation, exact five-field schema, exact loopback origin, owner UID/mode checks, and 64-hex process secrets.
- Added bounded authenticated fetches to all six gateway endpoints, a 2-MiB streaming response cap, 1-to-30-second timeout configuration, caller cancellation, and one rediscovery retry only when a connection fails and the browser nonce/endpoint credentials rotate.
- Added one in-memory browser-issued session per bridge process: create from a UTF-8-bounded client label or resume only an explicit opaque id, touch every three seconds, stop heartbeat before shutdown, close once on graceful EOF/signal, and leave abrupt loss to browser expiry.
- Exposed exactly 90 unique tool names from the clean-room manifest. Native and eight alias names use strict schemas and canonical routes; deferred, typed-stub, and removed dispositions return deterministic local MCP tool errors before argument normalization and never contact the browser.
- Translated public compatibility fields into the exact native codec shape: stable/index targets, nested element and frame data, attribute names, scroll deltas, visual metadata, and the closed three-value internal-surface enum.
- Exposed the browser-owned explicit JavaScript permission and mutation-verification booleans so `execute_js` remains denied by default but can satisfy the Phase 18 permission/read-back contract when the caller grants it explicitly.
- Preserved every subset of `visual_reason`, `client`, and `is_final` independently while using none for session, target, or authentication. Unknown badges are rejected before native dispatch.
- Returned byte-identical text and structured tool payloads, structurally removed forbidden credential/session/profile metadata, and converted authenticated browser health into exactly ten sanitized components with vault, provider, supervision, and extensions truthfully `not_ready`.
- Closed shutdown-during-initialize races by draining an in-flight create/resume, suppressing late protocol output and heartbeat installation, and closing a just-issued session exactly once on graceful termination. Framing errors now emit one parse error and terminate instead of reusing a poisoned buffer, and native fetch refuses redirects.

## Root Commits

1. `7a8ed6199` — `test(19-06): specify stdio MCP lifecycle and tools`
2. `83315eb1c` — `feat(19-06): implement dependency-free MCP stdio protocol`
3. `88cc9c8b2` — `feat(19-06): connect MCP bridge to browser sessions`
4. `492e684fe` — `feat(19-06): expose manifest-backed MCP tools`
5. `8a2f30d36` — `fix(19-06): close bridge lifecycle race gaps`

## Verification

- Node full-suite command — 56/56 passed, with no skipped or unfinished cases.
- Catalog inventory — 46 frozen names, 59 current names, 15-name overlap, 90-name union, and 90/90 dispositions.
- Framing/protocol inventory — 14/14 passed across fragmentation, UTF-8, mode locking, versions, lifecycle, cancellation, init/shutdown races, terminal framing errors, stdout, EOF, and signals.
- Native descriptor/session inventory — 11/11 passed across all six bearer-authenticated endpoints, permissions, redirect denial, retry, timeout, cancellation, heartbeat, init/shutdown races, resume, close, response bounds, and authority-injection denial.
- Tool/visual/diagnostic/error inventory — 25/25 passed across exact routes and local dispositions, all eight aliases, explicit JavaScript permission/verification, all eight visual subsets, strict native nesting, ten diagnostics, typed errors, and text/structured parity.
- Static scans found only the three documented environment variables, no dependencies, no child-process use, no `console.log`, no embedded runtime/terminal/engine/`CLAUDE.md` path, and no stdout call outside the frame writer default.
- Root `git diff --check` — passed; root worktree clean.
- Human UAT — not run, as required.

## Deviations

- Descriptor validation is intentionally stricter than the minimum reader contract: it accepts only the exact lowercase 64-hex nonce/bearer format emitted by the Chromium writer and rejects symlinks, non-regular files, endpoint credentials, query strings, and fragments.
- Native result sanitation rejects structural credential/session/profile metadata but does not inspect or alter legitimate bounded page-content string values.
- Verification ran on the installed Node `v24.14.1`; production code uses only APIs available in the declared Node 20 baseline and has no package dependencies.

## Next Plan Readiness

Plan 19-07 can launch the built Prometheus app, discover its real mode-0600 descriptor, spawn this stdio adapter as a separate process, and prove the complete external-host path. Claude Code, Cursor, Codex, VS Code, and similar tools remain external MCP clients; Prometheus does not bundle or launch them.

## Self-Check: PASSED

- FOUND: all five commits and all seven production bridge modules.
- VERIFIED: all 56 tests and the exact 90-name catalog.
- VERIFIED: secure descriptor/session transport, real native envelope shapes, disposition-first compatibility, optional visual subsets, sanitized diagnostics/results, and no embedded runtime surface.

---
*Phase: 19-mcp-bridge-and-multi-agent-runtime-compatibility*
*Completed: 2026-07-13*
