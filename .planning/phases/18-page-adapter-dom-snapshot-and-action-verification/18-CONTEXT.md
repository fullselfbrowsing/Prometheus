# Phase 18: Page Adapter, DOM Snapshot, and Action Verification - Context

**Gathered:** 2026-07-07
**Status:** Ready for planning
**Mode:** Autonomous smart discuss defaults accepted

<domain>
## Phase Boundary

Phase 18 extends the Phase 17 browser-process route service from browser-owned
tab/window navigation into page understanding and verified page actions. It owns
normal-page text reads, DOM snapshots, compact page snapshots, permissioned JS
execution, safe page actions, waits, change reports, repeated-action detection,
and explicit frame/restriction failures on Chromium `WebContents` and
`RenderFrameHost` primitives.

Phase 18 does not build the MCP stdio bridge, provider-backed task runtime,
vault/provider secret flows, memory/site-guide storage, live supervision
streaming, extension permission policy, or release packaging. Those stay in
Phases 19 through 24. Phase 18 should create the browser-native page adapter
that those later phases call.

</domain>

<decisions>
## Implementation Decisions

### Route Surface and Phase 17 Integration

- **D-01:** Add page routes to the existing Phase 17 typed route spine instead
  of creating a parallel page-control authority. All page routes must validate
  session, target, ownership, profile scope, and route allowlist through the
  Phase 17 service boundary before reading or mutating a page.
- **D-02:** Preserve the Phase 17 data-minimal audit model. Page routes may
  return page text, snapshots, JS values, and change reports in route results,
  but audit records must keep stable metadata only: route, session, target,
  result code, timing, and non-content changed-state strings.
- **D-03:** Keep route names compatible with the future Phase 19 MCP bridge:
  `read_page`, `get_dom_snapshot`, `get_page_snapshot`, `execute_js`,
  `click`, `type_text`, `press_key`, `scroll`, `hover`, `select_option`,
  `clear`, `drag`, and `drop_file` or equivalent typed enum entries.
- **D-04:** Continue to reject internal WebUI, settings, downloads, history,
  extension, and Prometheus runtime mutation unless an explicit adapter exists.
  Phase 18 is for normal web pages and frame-aware failure reporting.

### Page Reads and Snapshot Shape

- **D-05:** Provide three read levels: visible text for quick context, full DOM
  snapshot for tool planning, and compact page snapshot for next-action
  planning. The compact snapshot should be intentionally smaller and action
  oriented, not a prettified full DOM dump.
- **D-06:** Snapshot entries should include stable ephemeral element refs,
  preferred selectors, tag/role/name/text snippets, attributes needed for action
  planning, form/input state, disabled/hidden/actionability hints, frame
  context, and limited bounding/visibility metadata where Chromium exposes it
  safely.
- **D-07:** Element refs are per-snapshot and per-frame. Do not promise durable
  refs across navigation, renderer process changes, frame detach, or DOM
  replacement. Mutating actions must re-resolve and re-validate refs at action
  time.
- **D-08:** Bound page-read output. Use deterministic truncation and explicit
  `truncated` / `omitted_count` style metadata rather than silently returning
  arbitrarily large page content.

### Frame and Target Policy

- **D-09:** Target pages through Phase 17 stable tab ownership first, then
  resolve the live `WebContents`, then resolve frame targets. Use Chromium
  frame identity primitives rather than raw renderer-controlled selectors as the
  authority boundary.
- **D-10:** Default to the primary main frame when no frame is specified. Allow
  explicit same-origin child frame targeting when the frame can be identified
  and is live.
- **D-11:** Cross-origin, sandboxed, fenced, detached, prerendered, crashed,
  restricted, or otherwise unsupported frames must fail explicitly with typed
  errors and recovery guidance. Do not fall back to a different frame.
- **D-12:** Frame/snapshot results may describe that restricted frames exist,
  but must not leak content from frames Chromium policy does not permit this
  adapter to inspect.

### JavaScript Execution

- **D-13:** `execute_js` is explicit, permissioned, result-capturing, and
  audited as a page route. It should never be hidden inside read/action routes
  as an untracked helper that bypasses route policy.
- **D-14:** JS execution is allowed only on normal, owned page targets that pass
  the same profile/session/ownership/frame policy as other page routes. Keep
  internal WebUI and privileged `chrome://` surfaces blocked unless a later
  explicit adapter says otherwise.
- **D-15:** Capture JS success values and script errors in structured route
  results. Do not write raw scripts, prompt text, page text, secrets, vault
  values, or provider keys into audit records.
- **D-16:** Mutating JS must run a read-back verification path: wait for load or
  DOM stability where relevant, then return a bounded change report or explicit
  "no verified change" result.

### Page Actions and Verification

- **D-17:** Implement page actions as browser/page-adapter commands with
  verification, not as blind coordinate clicks. Actions should resolve element
  refs/selectors against the live frame, check actionability, execute through
  Chromium-safe input or DOM pathways, then verify the intended state change.
- **D-18:** Phase 18 should cover click, type text, press key, scroll, hover,
  select option, clear input, drag, and drop file where Chromium permits safe
  implementation. Unsupported or unsafe actions must return typed denials.
- **D-19:** Every mutating action should wait for the relevant post-action
  condition: navigation/load, DOM stability, visible change, element value
  change, focus change, scroll position change, or a timeout with a typed
  verification failure.
- **D-20:** Change reports should be compact and structured: changed-state
  constants, target ref/selector, before/after summaries where safe, navigation
  URL/status where applicable, and verification status. Do not return full page
  dumps as action results.
- **D-21:** Detect repeated or stuck actions at the route-service level using
  recent session/tab/action metadata. The first implementation can be
  conservative, but it must surface a typed stuck/repeated-action result instead
  of silently retrying forever.

### Security and Data Boundaries

- **D-22:** Treat all selector strings, element refs, JS snippets, typed text,
  file paths, and frame IDs as untrusted input. Validate and bound them before
  they reach renderer/page execution.
- **D-23:** File drop support must not read arbitrary local files by path from
  untrusted input. If file drops are included, require a browser-approved test
  fixture or explicit safe file handle/path policy documented in the plan.
- **D-24:** Page text and DOM snapshots are allowed in route results for the
  authorized caller, but they must not enter audit logs, browser history, WebUI
  URLs, crash strings, or planning docs.
- **D-25:** Keep screenshot/vision behavior out of the primary control loop.
  Screenshots can remain a diagnostic/fallback concept for later phases, but
  Phase 18 should prove DOM/native structural control.

### Test and Fixture Strategy

- **D-26:** Use unit tests for pure parsing, snapshot compaction, selector/ref
  validation, typed error mapping, output bounding, action-history/stuck logic,
  and change-report construction.
- **D-27:** Use browser tests with local fixtures for real page behavior:
  visible text, forms, ARIA labels, dynamic DOM changes, same-origin iframe,
  cross-origin iframe denial, sandbox/restricted targets, navigation-triggering
  clicks, typing, selection, scrolling, hover/focus, drag/drop if implemented,
  and JS result/error/read-back behavior.
- **D-28:** Preserve the final gate pattern from Phases 16 and 17: build,
  focused `prometheus_unittests`, focused `browser_tests`, root Chromium env,
  GPL guard, artifact isolation, diff checks, preservation ledger update, and
  Chromium patch export.

### the agent's Discretion

- The planner may decide whether the first adapter is a separate
  `PrometheusPageAdapter` source set, a helper owned by `PrometheusAgentService`,
  or a small service/facade split, as long as the Phase 17 route boundary stays
  authoritative.
- The planner may choose the exact element-ref format and compact snapshot
  schema, but it must be deterministic, bounded, frame-aware, and compatible
  with later MCP schema mapping.
- The planner may choose Chromium primitives for dispatching input events and
  script execution after research, but must prefer established Chromium APIs
  and browser-testable seams over custom renderer hacks.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and requirements

- `.planning/ROADMAP.md` section "Phase 18: Page Adapter, DOM Snapshot, and
  Action Verification" - phase goal, success criteria, and planned work.
- `.planning/REQUIREMENTS.md` PAGE-01 through PAGE-08 - page reads, snapshots,
  JS execution, safe actions, waits, change reports, stuck detection, and frame
  behavior.
- `.planning/PROJECT.md` - product thesis: DOM/native structural control,
  screenshot-last architecture, FSB-compatible read/action tools, and
  PhantomStream-style DOM supervision direction.
- `.planning/preservation/FALKON-TO-CHROMIUM-PRESERVATION.md` rows "DOM/page
  snapshots, text reads, audited JS, action verification" and related Phase 18
  carry-forward notes.

### Direct dependency from Phase 17

- `.planning/phases/17-native-agent-command-service-and-tab-ownership/17-CONTEXT.md`
  - locked route/session/ownership/audit decisions and explicit Phase 18
  handoff boundary.
- `.planning/phases/17-native-agent-command-service-and-tab-ownership/17-VERIFICATION.md`
  - verified Phase 17 service behavior and carry-forward scope.
- `.planning/phases/17-native-agent-command-service-and-tab-ownership/17-REVIEW.md`
  - clean code review and residual risk that future bridges must not allow
  untrusted callers to choose arbitrary browser pointers.

### Chromium implementation anchors

- `.context/chromium/src/chrome/browser/prometheus/prometheus_agent_route.h`
  and `.cc` - route enum, target, result, and typed error vocabulary to extend.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_agent_service.h`
  and `.cc` - Phase 17 route validation, target resolution, ownership, audit,
  and internal-surface adapter boundary.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_agent_service_browsertest.cc`
  - browser-test patterns for sessions, target ownership, profile scope,
  navigation policy, and audit behavior.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_agent_tab_data.h`
  and `.cc` - browser-owned tab ownership data that page routes must enforce.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_tab_state.h`
  and `.cc` - WebContents-to-tab safe state seam.
- `.context/chromium/src/components/tabs/public/tab_interface.h` - stable tab
  handle and warning against durable raw `WebContents*` identity.
- `.context/chromium/src/content/public/browser/web_contents.h` - live page
  target and frame traversal APIs.
- `.context/chromium/src/content/public/browser/render_frame_host.h` - frame
  identity, lifecycle, and execution boundary APIs.
- `.context/chromium/src/content/public/test/browser_test_utils.h` - test-only
  examples for `EvalJs`, frame helpers, input simulation, accessibility tree
  snapshots, and DOM/message utilities. Use for tests/research, not blindly as
  production implementation.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `PrometheusAgentService` already validates sessions, profile-scoped targets,
  tab ownership, typed errors, audit recording, and changed-state metadata.
- `AgentRouteName`, `AgentRouteRequest`, `AgentRouteResult`, and
  `AgentErrorCode` already provide the typed route/result spine to extend.
- `PrometheusAgentTabData` stores the owner session on stable tab identity and
  is the authorization gate for page-level reads and actions.
- Existing Phase 17 browser tests provide helpers for session creation, route
  execution, tab targeting, and real Chromium browser/tab assertions.
- Chromium content test utilities show available frame, JS, input simulation,
  and accessibility snapshot patterns for browser tests.

### Established Patterns

- Prometheus Chromium code remains isolated under
  `.context/chromium/src/chrome/browser/prometheus/` with focused source sets
  and tests in `chrome/browser/prometheus/BUILD.gn`.
- Root git stores planning docs and exported patches; Chromium source edits are
  committed inside `.context/chromium/src` and exported via `format-patch`.
- Route changed-state strings are stable constants and audit metadata is
  intentionally content-free.
- Unsupported or unsafe behavior returns typed errors with recovery guidance
  instead of disappearing or silently no-oping.

### Integration Points

- Page route dispatch should attach to or be called from
  `PrometheusAgentService::ExecuteRoute()` after Phase 17 validation succeeds.
- Frame resolution starts from the live `WebContents` for the owned
  `tabs::TabInterface`, then resolves the requested frame.
- Snapshot and action result structures should be kept easy for Phase 19 to map
  to MCP `read_page`, `get_dom_snapshot`, `get_page_snapshot`, and manual action
  schemas.
- Preservation ledger evidence must update the DOM/page action row without
  claiming MCP bridge, runtime/provider/vault, or supervision parity.

</code_context>

<specifics>
## Specific Ideas

- Start with the smallest useful page adapter: target/frame resolution, visible
  text, bounded DOM/compact snapshots, JS result capture, then verified actions.
- Prefer deterministic local browser-test fixtures over network-dependent pages.
- Make denied/restricted frame behavior just as explicit and tested as the happy
  path.
- Treat "verified no change" as a valid typed outcome distinct from success.

</specifics>

<deferred>
## Deferred Ideas

- MCP stdio bridge, external tool schemas, visual-session fields, and MCP
  diagnostics belong to Phase 19.
- Provider-backed tasks, runtime logs, vault/provider secrets, memory, and site
  guides belong to Phase 20.
- Supervision streaming, dashboard pairing, remote preview identity, and remote
  control belong to Phase 21.
- Extension-surface adapter policy and extension permission separation belong
  to Phase 22.

</deferred>

---
*Phase: 18-page-adapter-dom-snapshot-and-action-verification*
*Context gathered: 2026-07-07*
