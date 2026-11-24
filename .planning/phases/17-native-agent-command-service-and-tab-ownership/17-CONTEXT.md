# Phase 17: Native Agent Command Service and Tab Ownership - Context

**Gathered:** 2026-07-07
**Status:** Ready for planning
**Mode:** Autonomous smart discuss defaults accepted

<domain>
## Phase Boundary

Phase 17 builds the first Chromium-native Prometheus agent command service in
the browser process. It owns route validation, browser-issued agent sessions,
stable tab/window identity, tab ownership enforcement, a small set of
browser-owned tab/window/navigation/internal-surface actions, typed errors, and
audit-ready route results.

Phase 17 does not implement DOM snapshots, page text reads, arbitrary JS, page
mutation tools, MCP stdio compatibility, provider-backed FSB runtime tasks,
vault/provider secrets, memory/site guides, or supervision pairing. Those remain
Phase 18 through Phase 21 scope. Phase 17 must create the service boundary and
policy spine that those later phases call into.

</domain>

<decisions>
## Implementation Decisions

### Route Service Boundary

- **D-01:** Build a Prometheus-owned C++ browser-process service under the
  existing Prometheus Chromium area, starting in `chrome/browser/prometheus/`
  and splitting to `chrome/browser/prometheus/agent/` only when file count or
  ownership warrants it.
- **D-02:** Keep Phase 17 in-process and browser-owned. Do not open a network
  listener or MCP stdio bridge in this phase; Phase 19 can adapt the same route
  API to MCP.
- **D-03:** Define route requests/results as typed C++ structs/enums with stable
  string serialization helpers for tests and future MCP compatibility. Avoid
  raw JSON string dispatch in the core service.
- **D-04:** Route names should be allowlisted and boring: list tabs/windows,
  open tab, activate/switch tab, close tab, navigate, reload, back, forward,
  duplicate, move/detach where already supported, and open explicit internal
  Prometheus surfaces. Unsupported page actions must return typed errors until
  Phase 18.

### Sessions and Authentication

- **D-05:** Agent sessions are browser-issued and opaque. The service may accept
  a local bootstrap/test path for Phase 17, but caller-provided client labels
  are never trusted as identity or ownership authority.
- **D-06:** Session state lives in the browser process, scoped to a `Profile`
  unless a narrower browser-window scope is required by Chromium APIs. The
  planner should prefer profile-keyed service ownership for long-lived session
  registries and browser/window parameters for target resolution.
- **D-07:** Expose explicit concurrent-agent caps and reconnect-grace policy in
  the service data model even if the first implementation uses conservative
  defaults. The route result must be able to report `AGENT_CAP_REACHED` and
  reconnect/expired-session errors.
- **D-08:** Session display labels are metadata only. They may appear in tab
  state for human readability after the browser assigns the session, but they
  cannot authorize actions.

### Tab Identity and Ownership

- **D-09:** Key ownership to stable Chromium tab identity, not mutable tab
  indices. Prefer `tabs::TabInterface::GetHandle()` / `tabs::TabHandle` where
  available, with `TabListInterface` for tab operations and `WebContents` only
  as an adapter boundary.
- **D-10:** Do not cache raw `WebContents*` as the durable target identity.
  Chromium explicitly allows a tab's `WebContents` to be replaced on discard;
  hold tab handles or `TabInterface` references and resolve contents at action
  time.
- **D-11:** Extend the existing `PrometheusTabState` safe-default seam so
  owner, automation, supervision, and health state come from browser-owned tab
  data. Preserve the current invariant that arbitrary caller/user data cannot
  inject an owner label.
- **D-12:** Cross-agent control defaults to deny. A session can control tabs it
  owns or tabs with no owner when the action policy permits claiming; attempts
  against another owner return a typed `TAB_NOT_OWNED` result with recovery
  guidance.
- **D-13:** Tab ownership must survive tab reordering and index changes.
  Ownership may be cleared or transferred on close/detach/window move only
  through explicit browser-observed lifecycle events.

### Target Resolution and Internal Surfaces

- **D-14:** Target resolution accepts explicit browser/session/tab handles and a
  safe active-tab fallback. It must reject ambiguous or stale targets rather
  than guessing.
- **D-15:** Internal surfaces are explicit adapters. Phase 17 can open or focus
  `chrome://prometheus-newtab/`, `chrome://prometheus-side-panel/`, and
  `chrome://prometheus-control-panel/`, but mutation of internal WebUI state
  stays behind named adapters and permissions.
- **D-16:** Normal web page content actions are out of scope except for
  navigation/reload/history actions that Chromium browser APIs already own.
  Click/type/JS/read/snapshot routes should return Phase-18 typed compatibility
  errors if surfaced.

### Route Results, Errors, and Audit

- **D-17:** Every route result should include success/failure, stable error
  code, human-readable recovery guidance, target browser/window/tab identifiers,
  timing, and a minimal changed-state summary.
- **D-18:** Errors should preserve the existing Prometheus/FSB vocabulary where
  applicable: `TAB_NOT_OWNED`, `AGENT_CAP_REACHED`, `TAB_OUT_OF_SCOPE`,
  `PERMISSION_BLOCKED`, `UNSUPPORTED_ROUTE`, `STALE_TARGET`, and
  `BROWSER_SHUTTING_DOWN`.
- **D-19:** Audit records should be data-minimal and secrets-safe: route name,
  session id, target ids, result code, timing, and changed-state metadata. Do
  not log prompts, provider secrets, vault values, page text, or raw URLs beyond
  what the route result explicitly allows.

### Verification Priorities

- **D-20:** Use unit tests for pure route validation, session registry,
  ownership policy, typed error mapping, and result serialization.
- **D-21:** Use browser tests for tab/window operations that require real
  Chromium objects: list tabs, open/activate/close/navigate/reload/back/forward,
  ownership denial across two sessions, and owner state reflected through
  `PrometheusTabState`.
- **D-22:** Keep root Chromium environment, GPL guard, artifact isolation, and
  patch export gates in the final plan, matching Phases 15 and 16.

### the agent's Discretion

- The planner may choose exact class names, GN target names, and file splits as
  long as Prometheus-owned code remains isolated under the existing Chromium
  Prometheus directories and tests cover the chosen API.
- The planner may decide whether the first service is profile-keyed,
  browser-window-attached through `UnownedUserData`, or a small facade over both,
  but must document lifecycle and shutdown behavior.
- The planner may defer public Mojo/WebUI exposure if C++ route tests and a
  browser-test callable seam provide enough verification for Phase 17.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and requirements

- `.planning/ROADMAP.md` section "Phase 17: Native Agent Command Service and
  Tab Ownership" - phase goal, success criteria, and planned work.
- `.planning/REQUIREMENTS.md` AGENT-01 through AGENT-08 - native service,
  tab/window actions, target surfaces, sessions, tab ownership, caps, typed
  errors, and route-result requirements.
- `.planning/PROJECT.md` - product thesis: native/DOM structural control,
  supervised and auditable behavior, and screenshot-last architecture.
- `.planning/preservation/FALKON-TO-CHROMIUM-PRESERVATION.md` sections
  "Native Agent Control", "Page Understanding And Actions", and "MCP
  Compatibility" - preserved contracts and phase boundaries.

### Prior Prometheus decisions

- `.planning/phases/15-chromium-ui-shell-compact-chrome-and-tab-model/15-06-SUMMARY.md`
  - existing tab command helper coverage and Phase 15 patch/export pattern.
- `.planning/phases/16-prometheus-webui-surfaces-and-new-tab/16-VERIFICATION.md`
  - WebUI surfaces and Ask FSB handoff state that Phase 17 may open/target but
  should not turn into runtime execution yet.
- `.planning/phases/16-prometheus-webui-surfaces-and-new-tab/16-CONTEXT.md`
  - Phase 16 decision that real task execution, agent routing, MCP, and runtime
  data are Phase 17+ scope.

### Chromium implementation anchors

- `.context/chromium/src/chrome/browser/prometheus/prometheus_tab_state.h` and
  `.cc` - existing safe-default tab state seam.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_tab_state_unittest.cc`
  - current invariant that caller-provided labels are not trusted.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_tab_commands.h`
  and `.cc` - existing Prometheus wrapper over Chromium tab commands.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_tab_commands_browsertest.cc`
  - browser-test examples for duplicate, move-to-window, group, and unsupported
  unload behavior.
- `.context/chromium/src/components/tabs/public/tab_interface.h` - stable tab
  handle and lifecycle guidance; warns against caching `WebContents*`.
- `.context/chromium/src/chrome/browser/tab_list/tab_list_interface.h` - basic
  cross-platform tab operations by `tabs::TabHandle`.
- `.context/chromium/src/chrome/browser/ui/browser_window/public/browser_window_interface.h`
  - browser window/session/profile and `TabStripModel` access guidance.
- `.context/chromium/src/chrome/browser/actor/actor_keyed_service.h` and
  `.context/chromium/src/chrome/browser/actor/actor_tab_data.h` - upstream
  actor service patterns to evaluate for `tabs::TabInterface` ownership,
  profile-keyed lifetime, and tab-attached data; do not adopt behavior blindly.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `PrometheusTabState` already exposes owner/automation/supervision/health fields
  and has a test proving the safe default has no owner.
- `PrometheusTabCommands` already wraps duplicate, move-to-window, close/pin/mute/
  group, and unsupported unload behavior through Chromium browser/tab APIs.
- `TabListInterface` gives a cleaner handle-based operation surface than raw
  tab indices for open, activate, close, move, duplicate, group, and window
  movement.
- `tabs::TabInterface` provides stable `TabHandle`, lifecycle callbacks, and
  content access that accounts for discarded/replaced `WebContents`.
- Upstream `chrome/browser/actor` code has profile-keyed actor/task patterns and
  tab-attached data patterns that can inform implementation without defining
  Prometheus product policy.

### Established Patterns

- Prometheus Chromium implementation code lives under `.context/chromium/src`;
  root planning tracks docs, logs, and exported patch series only.
- Prometheus C++ helpers are isolated in `chrome/browser/prometheus/BUILD.gn`
  as source sets with focused unit/browser tests.
- Browser tests already use `InProcessBrowserTest`, `BrowserWindowInterface`,
  `TabStripModel`, `GlobalBrowserCollection`, and `ui_test_utils` for real tab
  operations.
- Prior phases prefer browser-owned state and safe defaults over trusting
  renderer-visible or caller-provided data.

### Integration Points

- Phase 17 should extend `PrometheusTabState` from safe default to real
  browser-owned session/ownership data.
- Route actions can initially call `TabListInterface` and the existing
  `PrometheusTabCommands` helper rather than duplicating low-level tab-strip
  logic.
- Internal surface targets connect to Phase 16 WebUI hosts, but only through
  explicit route adapters and permission checks.
- Phase 19 MCP bridge should call the Phase 17 route API rather than inventing
  a parallel authority model.

</code_context>

<specifics>
## Specific Ideas

- Favor a small, testable route spine first: session registry, target resolver,
  ownership policy, typed result, then a conservative tab/window action set.
- Treat all caller labels and route strings as untrusted input.
- Preserve the FSB-compatible error vocabulary early so later MCP work has
  stable codes to map.
- Do not expose secrets or page content in route/audit logs.

</specifics>

<deferred>
## Deferred Ideas

- DOM/page snapshots, text reads, JS, click/type/scroll and verification loops
  belong to Phase 18.
- Local stdio MCP bridge, schema compatibility, visual-session fields, and MCP
  diagnostics belong to Phase 19.
- Provider runtime, task execution, vault/provider secret storage, logs,
  memory, and site guides belong to Phase 20.
- Supervision pairing, remote preview identity, and remote-control audit state
  belong to Phase 21.

</deferred>

---
*Phase: 17-native-agent-command-service-and-tab-ownership*
*Context gathered: 2026-07-07*
