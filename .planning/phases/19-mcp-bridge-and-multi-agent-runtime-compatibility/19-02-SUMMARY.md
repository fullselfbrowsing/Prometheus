---
phase: 19-mcp-bridge-and-multi-agent-runtime-compatibility
plan: 02
subsystem: native-mcp-transport-contract
tags: [chromium, cpp, json, transport, security, tdd]

requires:
  - phase: 17-native-agent-command-service-and-tab-ownership
    provides: Closed native route and audit contracts
  - phase: 18-page-adapter-dom-snapshot-and-action-verification
    provides: Bounded page request/result types and typed failures
provides:
  - Closed native route, visual, tab/window, element-read, diagnostic, and internal-surface data contracts
  - Strict 1 MiB request parser and 2 MiB result serializer
  - Numeric target normalization with positive stable handles and zero-based mutable tabIndex
  - Exact ten-key diagnostic and content-exclusion validation
affects: [19-03, 19-04, 19-05, 19-06, 19-07]

tech-stack:
  added: [Chromium base JSON transport codec]
  patterns:
    - Raw JSON terminates at a bounded codec before browser service dispatch
    - External aliases remain Node-owned while C++ accepts canonical route names only
    - Internal surfaces use a closed enum rather than arbitrary internal URLs

key-files:
  created:
    - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_transport_codec.h
    - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_transport_codec.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_transport_unittest.cc
  modified:
    - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_route.h
    - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_route.cc
    - .context/chromium/src/chrome/browser/prometheus/BUILD.gn

requirements-completed: []
requirements-progressed: [MCP-02, MCP-03, MCP-04, MCP-05, MCP-06, MCP-07]

completed: 2026-07-12
---

# Phase 19 Plan 02: Native MCP Transport Contract Summary

**Chromium now has a closed, bounded native JSON boundary for canonical MCP routes and structured results; raw route strings and JSON do not enter the agent service.**

## Accomplishments

- Added route/result types for optional visual metadata, structured tabs/windows, exact element reads, four diagnostic states, and the exact ten diagnostic components.
- Added canonical `get_text`, `get_attribute`, `diagnostics`, and `open_internal_surface` routes. Internal surfaces accept only `new_tab`, `side_panel`, or `control_panel`.
- Added a strict codec that rejects unknown fields, malformed values, oversized input/output, ambiguous target spellings, spoofed badges, and invalid route-specific surface values.
- Preserved independently optional visual fields and kept page/visual/credential content out of audit, error, and diagnostic metadata.
- Corrected target bounds: stable IDs are positive; `tabIndex` is zero-based and accepts the first tab at index 0.

## Nested Chromium Commits

1. `1a22d6e56516155b387dd3352ae7260c34f3b961` — `test(19-02): specify native MCP transport contracts`
2. `d6ee3978a5d71762edfaaaee3a2cad1b985ec13b` — `feat(19-02): extend native MCP route contracts`
3. `71f3fae9632ca233bc271b8f75db39c21e71a947` — `feat(19-02): add strict native MCP JSON codec`

## Verification

- `autoninja -C out/Default prometheus_unittests` — passed.
- `*PrometheusAgentTransport*:*PrometheusAgentRoute*:*PrometheusAgentAudit*` — 36/36 passed: 14 transport, 14 route, 8 audit.
- Static boundary scan — no JSON or `base::Value` parameter reaches `PrometheusAgentService`.
- Nested `git diff --check` — passed; nested worktree clean.

## Deviations

The four new route enums made existing service/page-adapter switches non-exhaustive under `-Werror`. The codec commit therefore adds minimal typed-unsupported placeholder cases in `prometheus_agent_service.cc` and `prometheus_page_adapter.cc`. They return no empty success and carry nonempty recovery. Plan 19-04 replaces the page-read/internal-surface placeholders; Plan 19-05 replaces diagnostics.

## Next Plan Readiness

Plan 19-03 can build profile-keyed production lifetime on the closed request/result types. Plans 19-04 through 19-06 can replace the explicit placeholders without changing the transport envelope.

## Self-Check: PASSED

- FOUND: all three nested commits.
- VERIFIED: production build target and 36 focused tests.
- VERIFIED: strict target, visual, diagnostic, internal-surface, and size-bound behavior.

---
*Phase: 19-mcp-bridge-and-multi-agent-runtime-compatibility*
*Completed: 2026-07-12*
