# Phase 18: Page Adapter, DOM Snapshot, and Action Verification - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md - this log preserves the alternatives considered.

**Date:** 2026-07-07T09:50:11Z
**Phase:** 18-page-adapter-dom-snapshot-and-action-verification
**Mode:** Autonomous smart discuss defaults accepted
**Areas discussed:** Route surface and integration, page reads and snapshot shape, frame and target policy, JavaScript execution, page actions and verification, security and data boundaries, test and fixture strategy

---

## Route Surface and Integration

| Option | Description | Selected |
|--------|-------------|----------|
| Extend Phase 17 route spine | Page routes reuse the existing route/session/ownership/audit service boundary. | yes |
| Create separate page authority | New standalone service bypassing Phase 17 route validation. | |

**Auto choice:** Extend the Phase 17 route spine so all page routes inherit session, ownership, profile, typed error, and audit policy.

---

## Page Reads and Snapshot Shape

| Option | Description | Selected |
|--------|-------------|----------|
| Three read levels | Visible text, full DOM snapshot, and compact action-oriented snapshot. | yes |
| One general DOM dump | Single large snapshot for all reads. | |
| Text-only first | Defer structured snapshots. | |

**Auto choice:** Implement three read levels. This matches PAGE-01 through PAGE-03 and keeps compact snapshots useful for action planning.

---

## Frame and Target Policy

| Option | Description | Selected |
|--------|-------------|----------|
| Main frame default with explicit frame targeting | Default to primary main frame; allow explicit live frame targets with typed failures. | yes |
| Best-effort frame guessing | Try a selector in any frame until one matches. | |
| Main frame only | Defer all iframe behavior. | |

**Auto choice:** Use main-frame default plus explicit frame targets. Never guess across frames; restricted frames fail with typed errors.

---

## JavaScript Execution

| Option | Description | Selected |
|--------|-------------|----------|
| Explicit permissioned route | `execute_js` is a named route with result capture, errors, read-back verification, and metadata-only audit. | yes |
| Hidden helper inside actions | Use JS internally without exposing route-level policy. | |
| Defer JS | Leave PAGE-04 incomplete. | |

**Auto choice:** Implement JS as an explicit permissioned page route and keep internal WebUI / privileged pages blocked.

---

## Page Actions and Verification

| Option | Description | Selected |
|--------|-------------|----------|
| Verified structural actions | Resolve refs/selectors, check actionability, dispatch through Chromium-safe paths, wait, and report change. | yes |
| Blind coordinates | Click/type by coordinates without DOM/frame verification. | |
| JS-only mutations | Emulate every action through injected JS. | |

**Auto choice:** Use verified structural actions as the primary loop. Screenshots/vision remain fallback diagnostics, not Phase 18 architecture.

---

## Security and Data Boundaries

| Option | Description | Selected |
|--------|-------------|----------|
| Route results may contain page data, audits stay metadata-only | Authorized callers can receive bounded page text/snapshots/results; audit logs never store content. | yes |
| Store full page data in audits | Easier debugging but leaks content. | |
| Suppress all page result data | Too weak for PAGE-01 through PAGE-04. | |

**Auto choice:** Return bounded page data only in route results and keep audit/content logs data-minimal.

---

## Test and Fixture Strategy

| Option | Description | Selected |
|--------|-------------|----------|
| Unit logic plus local browser fixtures | Unit tests for pure logic; browser tests for forms, frames, dynamic DOM, restrictions, actions, waits, and JS. | yes |
| Browser tests only | Strong integration but slower and weaker for pure logic. | |
| Unit tests only | Fast but cannot prove real Chromium frame/action behavior. | |

**Auto choice:** Use unit tests plus local browser fixtures and preserve the final gate pattern from Phases 16 and 17.

---

## the agent's Discretion

- Exact C++ class/file split for the page adapter.
- Exact element-ref schema and compact snapshot fields.
- Exact Chromium primitives for production action dispatch after research.

## Deferred Ideas

- MCP bridge and external tool schemas stay in Phase 19.
- Provider runtime, vault, memory, logs, and control-panel data stay in Phase 20.
- Supervision and remote pairing stay in Phase 21.
- Extension surface policy stays in Phase 22.
