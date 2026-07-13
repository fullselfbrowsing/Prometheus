---
phase: 19-mcp-bridge-and-multi-agent-runtime-compatibility
plan: 07
subsystem: live-mcp-integration-and-verification
tags: [chromium, mcp, stdio, browser-test, lifecycle, ownership, security, preservation]

requires:
  - phase: 19-02
    provides: Strict native route/result codec
  - phase: 19-03
    provides: Profile-keyed browser sessions and ownership lifetime
  - phase: 19-04
    provides: Structured background tab and exact-frame read routes
  - phase: 19-05
    provides: Authenticated loopback gateway and owner-only descriptor
  - phase: 19-06
    provides: Dependency-free external stdio MCP bridge
provides:
  - Built-Prometheus-to-external-stdio live compatibility proof
  - Consolidated multi-session, background, exact-frame, visual, diagnostic, and shutdown browser inventory
  - Exact-tab resume, expired-resume, ownership-release, and bounded session-churn evidence
  - Full automated Phase 19 verification with no human-UAT dependency
  - Nineteen-patch clean-room Chromium export and truthful external-host documentation
affects: [20, 21, 22, 23, 24]

key-files:
  created:
    - .context/chromium/src/chrome/browser/prometheus/prometheus_mcp_integration_browsertest.cc
    - tools/prometheus-mcp/test/fixture-server.mjs
    - tools/prometheus-mcp/test/smoke-client.mjs
    - tools/prometheus-mcp/smoke-browser.sh
    - .planning/phases/19-mcp-bridge-and-multi-agent-runtime-compatibility/19-VERIFICATION.md
    - .planning/phases/19-mcp-bridge-and-multi-agent-runtime-compatibility/patches/
  modified:
    - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_session.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_gateway.cc
    - tools/prometheus-mcp/test/smoke.test.mjs
    - .planning/phases/19-mcp-bridge-and-multi-agent-runtime-compatibility/19-VALIDATION.md
    - .planning/preservation/FALKON-TO-CHROMIUM-PRESERVATION.md
    - README.md

requirements-completed: [MCP-01, MCP-02, MCP-03, MCP-04, MCP-05, MCP-06, MCP-07]
requirements-progressed: []

duration: 3h
completed: 2026-07-13
---

# Phase 19 Plan 07: Live MCP Integration and Verification Summary

**The built Prometheus app and a separately spawned Prometheus stdio bridge now
prove all seven MCP requirements across the real authenticated process boundary,
including exact-tab resume authority, bounded retired-session cleanup, and
truthful later-phase failures.**

## Accomplishments

- Added ten consolidated browser integration cases through the real loopback
  gateway for caps/ownership, graceful and abrupt cleanup, opaque resume,
  background focus, stable reordered tabs, visual subsets, exact-frame reads,
  ten-component diagnostics, and exactly-once shutdown.
- Added a deterministic local fixture, independent JSON-RPC client, and shell
  gate that launch the built Prometheus app and then spawn only the
  Prometheus-owned Node bridge. The smoke never imports bridge internals or
  launches Claude Code, Cursor, Codex, a terminal, or another agent runtime.
- Proved the exact 90-name catalog, background navigation without focus theft,
  snapshot-derived element/frame handles, present-empty versus missing
  attributes, verified type/clear/click mutations, typed unsupported/later/
  removed results, all ten diagnostics, and second-session ownership denial.
- Strengthened resume evidence so an abruptly disconnected bridge owns a real
  tab, a fresh session is denied, and the resumed opaque session alone can
  navigate that exact tab. Expired resume is rejected before another live
  session reclaims the tab.
- Erased closed and expired session records instead of retaining inactive ids
  and labels, pruned stale gateway bindings on authenticated traffic, and added
  unit/browser churn coverage well beyond the active-session cap.
- Required graceful bridge children to exit with code zero and no signal.
  Full parsed JSON-RPC responses are retained only in memory for private-value
  scanning; persisted transcripts remain metadata-only, while explicitly
  requested page content is allowed only inside successful tool results.
- Exported 19 nonempty source-only Chromium patches from the exact Phase 18 tip
  and updated preservation/README material without claiming Phase 20 runtime,
  Phase 21 supervision, or Phase 22 extension capabilities ready.

## Nested Chromium Commits

1. `f323382835` — `test(19-07): add MCP integration browser inventory`
2. `9342456650` — `fix(19-07): harden live MCP integration`
3. `4318f13eaf` — `test(19-07): expose unbounded session retention`
4. `b74b2ebc79` — `test(19-07): specify bounded session churn`
5. `460caac2f9` — `fix(19-07): bound retired session metadata`

## Root Commits

1. `7249419be` — `test(19-07): specify live browser MCP smoke`
2. `99b5c735e` — `test(19-07): add live browser MCP smoke`
3. `f3f60c308` — `test(19-07): strengthen MCP lifecycle smoke`

## Verification

- Full Chromium build — passed for `chrome`, `browser_tests`,
  `prometheus_unittests`, and `prometheus_action_dispatcher_unittests`.
- Root Node suite — 64/64 passed; zero fail, cancelled, skipped, or TODO.
- Focused gateway/session/transport/compatibility units — 34/34 passed.
- Renderer units — 7/7 passed.
- Phase 19 gateway/profile/element/MCP browser inventory — 32/32 passed
  serially.
- Phase 17/18 native service, page, action, and frame regression — 53/53
  passed serially.
- Built-browser-to-stdio live smoke — passed with deterministic PID-scoped
  teardown and metadata-only captured artifacts.
- Catalog inventory — 46 frozen, 59 current, 15 overlap, 90 union, and 90/90
  dispositions: 22 native, eight aliases, 22 typed stubs, 36 later-phase, and
  two removed.
- Environment, GPL, artifact-isolation, preservation, static boundary, patch
  inventory, and both repository diff gates — passed.
- Human UAT — not run, as required.

## Deviations

- The initial integration inventory exposed an argument-routing defect:
  page-level reads incorrectly received an element frame field and returned
  `STALE_TARGET`. The native codec now routes the frame only to the consumer
  that owns it.
- The first smoke draft used selector-shaped targeting. The final gate derives
  exact document-scoped refs and tokens from the real DOM snapshot, matching
  the public Phase 18 contract.
- Independent closeout review found that the original resume sequence could
  false-pass with a new session and that inactive session metadata accumulated.
  Both findings received RED tests, production cleanup, stronger live proof,
  and fresh full gates before verification was recorded.
- The disposable macOS fixture needs `--use-mock-keychain`,
  `--no-proxy-server`, and narrowly disabled Local Network Access permission
  checks in this Chromium revision. The real Network Service, renderer sandbox,
  authenticated gateway, descriptor permissions, and process boundary remain
  active; this is not evidence for default Local Network Access policy.
- No human screenshots or UAT were captured. Phase 24 retains the consolidated
  non-blocking human visual review.

## Next Phase Readiness

Phase 20 can consume the browser-issued session, ownership, route, diagnostic,
and external MCP contracts without embedding a third-party agent runtime.
Runtime/provider/vault/memory/log names currently fail closed with Phase 20
ownership and must not be presented as implemented until that phase passes its
own automated gates.

## Self-Check: PASSED

- FOUND: all implementation/test commits and all 19 exported patches.
- VERIFIED: 64 Node, 34 focused native, seven renderer, 32 Phase 19 browser,
  and 53 prior-phase regression tests plus the live built-app smoke.
- VERIFIED: exact 90-name inventory, authenticated external-host boundary,
  exact-tab resume, bounded session churn, no embedded third-party runtime, and
  `human_uat: not_run`.

---
*Phase: 19-mcp-bridge-and-multi-agent-runtime-compatibility*
*Completed: 2026-07-13*
