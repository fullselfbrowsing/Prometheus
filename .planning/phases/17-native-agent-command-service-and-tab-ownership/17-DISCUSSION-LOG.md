# Phase 17: Native Agent Command Service and Tab Ownership - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-07
**Phase:** 17-native-agent-command-service-and-tab-ownership
**Mode:** Autonomous auto-selected defaults
**Areas discussed:** Route service boundary, Sessions and authentication, Tab identity and ownership, Target resolution and internal surfaces, Route results/errors/audit, Verification priorities

---

## Route Service Boundary

| Option | Description | Selected |
|--------|-------------|----------|
| Prometheus-owned browser-process C++ route service | Keeps route authority in Chromium browser process and lets MCP/WebUI adapt later. | yes |
| Network/stdio server now | Would start Phase 19 early and duplicate authority boundaries. | no |
| WebUI/renderer-driven route dispatch | Would put privileged routing too close to renderer-visible code. | no |

**Auto choice:** Prometheus-owned browser-process C++ route service.
**Notes:** Phase 17 owns route validation and command service only; MCP stdio compatibility remains Phase 19.

## Sessions and Authentication

| Option | Description | Selected |
|--------|-------------|----------|
| Browser-issued opaque sessions | Matches prior decisions that caller-provided labels are not trusted. | yes |
| Trust caller-provided client names | Conflicts with Phase 07 and current `PrometheusTabState` safety invariant. | no |
| Full external auth service | Larger than Phase 17 and unnecessary before local MCP bridge work. | no |

**Auto choice:** Browser-issued opaque sessions with caller labels as metadata only.
**Notes:** Concurrent caps and reconnect-grace errors should exist in the model even if defaults are conservative.

## Tab Identity and Ownership

| Option | Description | Selected |
|--------|-------------|----------|
| `tabs::TabHandle` / `TabInterface` identity | Stable across reorder and aligned with Chromium tab APIs. | yes |
| Mutable tab indices | Easy to call but unsafe across reorder, close, and move operations. | no |
| Durable raw `WebContents*` identity | Chromium warns contents can be replaced on discard. | no |

**Auto choice:** Prefer `tabs::TabHandle` / `TabInterface`, resolving `WebContents` at action time.
**Notes:** Extend `PrometheusTabState` with browser-owned data and preserve the no-caller-label trust invariant.

## Target Resolution and Internal Surfaces

| Option | Description | Selected |
|--------|-------------|----------|
| Explicit target handles plus safe active-tab fallback | Avoids guessing while keeping common local use ergonomic. | yes |
| Always target active tab | Too ambiguous for multi-agent ownership and background tabs. | no |
| Allow renderer/WebUI to mutate internal state directly | Violates browser-process boundary. | no |

**Auto choice:** Explicit target handles with safe active-tab fallback.
**Notes:** Phase 17 may open/focus Phase 16 WebUI surfaces, but mutation of those surfaces stays behind named adapters and permissions.

## Route Results, Errors, and Audit

| Option | Description | Selected |
|--------|-------------|----------|
| Structured results with typed errors and minimal audit fields | Supports debugging, MCP mapping, and safety without leaking content. | yes |
| Boolean success/failure only | Too weak for recovery guidance and future MCP compatibility. | no |
| Verbose logs with route payloads | Risks leaking prompts, URLs, page text, or secrets. | no |

**Auto choice:** Structured result objects with stable error codes, recovery guidance, target ids, timing, and changed-state metadata.
**Notes:** Preserve FSB-compatible codes where applicable: `TAB_NOT_OWNED`, `AGENT_CAP_REACHED`, `TAB_OUT_OF_SCOPE`, `PERMISSION_BLOCKED`, `UNSUPPORTED_ROUTE`, `STALE_TARGET`.

## Verification Priorities

| Option | Description | Selected |
|--------|-------------|----------|
| Unit policy tests plus browser tests for real tab actions | Matches Phase 15/16 test style and keeps fast policy feedback. | yes |
| Browser tests only | Slower and makes policy edge cases harder to cover. | no |
| Unit tests only | Cannot prove real Chromium tab/window behavior. | no |

**Auto choice:** Unit tests for route/session/policy/result logic and browser tests for tab/window actions and ownership denial.
**Notes:** Final plan should keep Chromium env, GPL, artifact isolation, diff check, and patch export gates.

## the agent's Discretion

- Exact class/file names and GN target splits.
- Whether the first service is profile-keyed, browser-window-attached, or a facade over both.
- Whether Phase 17 exposes a public Mojo/WebUI seam or only a C++ route seam plus browser-test callable helper.

## Deferred Ideas

- DOM/page actions and snapshots: Phase 18.
- MCP bridge and stdio tool schemas: Phase 19.
- FSB provider runtime, logs, memory, vault, and real task execution: Phase 20.
- Supervision and remote control: Phase 21.
