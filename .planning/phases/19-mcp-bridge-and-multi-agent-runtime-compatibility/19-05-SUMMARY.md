---
phase: 19-mcp-bridge-and-multi-agent-runtime-compatibility
plan: 05
subsystem: authenticated-loopback-gateway
tags: [chromium, loopback, http, descriptor, sessions, security, lifecycle]

requires:
  - phase: 19-02
    provides: Closed native route/result contracts and strict transport codec
  - phase: 19-03
    provides: Profile-keyed sessions, opaque resume, expiry, and ownership cleanup
  - phase: 19-04
    provides: Structured tab routes and exact-frame element reads
provides:
  - Authenticated IPv4-only loopback gateway for six closed browser endpoints
  - Atomic mode-0600 nonce-owned endpoint discovery descriptor
  - Profile-pinned session routing with bounded requests and exactly-once completion
  - Ten-component truthful health diagnostics with later systems not ready
  - Normal desktop startup and opt-in integration-test browser lifetime wiring
affects: [19-06, 19-07, 20, 21, 22]

key-files:
  created:
    - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_gateway.h
    - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_gateway.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_gateway_contract.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_endpoint_descriptor.h
    - .context/chromium/src/chrome/browser/prometheus/prometheus_endpoint_descriptor.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_browser_main_extra_parts.h
    - .context/chromium/src/chrome/browser/prometheus/prometheus_browser_main_extra_parts.cc
  modified:
    - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_gateway_browsertest.cc
    - .context/chromium/src/chrome/browser/prometheus/BUILD.gn
    - .context/chromium/src/chrome/browser/chrome_browser_main.cc
    - .context/chromium/src/chrome/browser/BUILD.gn
    - .context/chromium/src/chrome/common/chrome_switches.h
    - .context/chromium/src/chrome/common/chrome_switches.cc

requirements-completed: []
requirements-progressed: [MCP-01, MCP-06, MCP-07]

completed: 2026-07-13
---

# Phase 19 Plan 05: Authenticated Loopback Gateway Summary

**Prometheus now publishes one process-fresh, owner-only descriptor for an authenticated IPv4-loopback browser gateway whose closed endpoints preserve profile, session, ownership, and native route authority.**

## Accomplishments

- Added a dedicated IO-thread HTTP server bound only to `127.0.0.1:0`, with exact loopback peer and Host checks, Origin rejection, constant-time bearer comparison, closed method/path/content-type handling, and authenticated WebSocket rejection.
- Added six closed endpoints for session create, resume, touch, close, native command dispatch, and health; no arbitrary route, profile selector, executable, terminal, or agent-engine endpoint exists.
- Enforced 1 MiB request bodies, sixteen in-flight requests, thirty-second one-shot timeouts, one pending request per connection, bounded JSON transport, and exactly one terminal outcome across reply, timeout, disconnect, and shutdown races.
- Pinned each browser-issued session to its creation profile and rejected off-the-record creation, cross-profile reselection, and caller labels as authority.
- Published an atomic JSON descriptor beneath the per-user temp directory with an owner-only parent, mode `0600`, 256-bit nonce and bearer secrets, flush-before-replace, exact schema validation, and nonce-checked deletion that cannot remove a newer process descriptor.
- Kept descriptor reads/writes/deletion off the browser UI sequence with blocking-aware worker tasks; no bearer is accepted through a command-line switch or emitted through health, logs, or errors.
- Added exact ten-key health diagnostics. Browser, bridge, active-tab, and adapter entries report current readiness; vault, provider, supervision, and extensions remain explicitly `not_ready` with bounded recovery guidance for their owning phases.
- Added desktop browser main extra parts before profile teardown. Normal Prometheus launches start the gateway, integration tests opt in only with the descriptor-path switch, and shutdown drains requests and removes the owned descriptor before profiles disappear.

## Nested Chromium Commits

1. `7ef37e82f8` — `test(19-05): specify secure agent gateway contracts`
2. `d08746abcd` — `feat(19-05): add authenticated loopback agent gateway`
3. `9d8b124870` — `feat(19-05): start Prometheus agent gateway in browser lifetime`

## Verification

- `autoninja -C out/Default chrome browser_tests prometheus_unittests` — passed.
- Gateway, descriptor, and transport unit/contract inventory — 24/24 passed.
- Real-socket gateway and browser-lifecycle inventory — 9/9 passed serially.
- Lifecycle coverage verified explicit integration-test opt-in, authenticated health, and descriptor deletion during browser teardown.
- Static scans found no wildcard listener, bearer switch/logging, embedded third-party runtime, terminal, agent CLI, or engine-selection lifecycle surface.
- Nested `git diff --check` — passed; nested worktree clean.
- Human UAT — not run, as required for this planning and automated implementation sequence.

## Deviations

- The pure request-validation and one-shot-completion contract lives in a narrow source set so focused unit tests do not pull the full browser/UI dependency graph. Production routing remains in the gateway source set and is exercised through real sockets.
- Browser test clients run on dedicated IO threads because Chromium browser-test UI sequences disallow socket operations. Descriptor filesystem access uses test-only blocking scopes; production descriptor IO remains on blocking-aware worker tasks.

## Next Plan Readiness

Plan 19-06 can discover the mode-0600 descriptor and connect a dependency-free external Node stdio MCP adapter to the six authenticated endpoints. The browser remains the sole authority, and the adapter will not launch or embed Claude Code, another agent CLI, a terminal, an alternate engine, prompt provisioning, or `CLAUDE.md` integration.

## Self-Check: PASSED

- FOUND: all three nested commits, gateway/descriptor sources, and production browser extra parts.
- VERIFIED: 24 unit/contract checks and 9 real-socket/lifecycle browser cases.
- VERIFIED: authenticated loopback only, nonce-owned descriptor cleanup, profile pinning, bounded exactly-once completion, truthful diagnostics, and no embedded runtime surface.

---
*Phase: 19-mcp-bridge-and-multi-agent-runtime-compatibility*
*Completed: 2026-07-13*
