# Phase 18: Page Adapter, DOM Snapshot, and Action Verification - Research

**Researched:** 2026-07-07 [VERIFIED: system date]
**Domain:** Chromium browser-process page adapter, renderer page execution, DOM/text snapshotting, page action verification [VERIFIED: .planning/phases/18-page-adapter-dom-snapshot-and-action-verification/18-CONTEXT.md]
**Confidence:** HIGH for Phase 17 integration, Chromium frame/read/stability APIs, and test strategy; MEDIUM for exact production action-dispatch implementation because the final choice between reusing actor internals and creating a Prometheus-specific renderer seam is still a planning decision [VERIFIED: local source review]

<user_constraints>
## User Constraints (from CONTEXT.md)

All bullets in this section are copied verbatim from `.planning/phases/18-page-adapter-dom-snapshot-and-action-verification/18-CONTEXT.md`; the source file is the authority for these locked decisions. [VERIFIED: .planning/phases/18-page-adapter-dom-snapshot-and-action-verification/18-CONTEXT.md]

### Locked Decisions

#### Route Surface and Phase 17 Integration

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

#### Page Reads and Snapshot Shape

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

#### Frame and Target Policy

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

#### JavaScript Execution

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

#### Page Actions and Verification

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

#### Security and Data Boundaries

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

#### Test and Fixture Strategy

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

### Claude's Discretion

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

### Deferred Ideas (OUT OF SCOPE)

The CONTEXT.md phase boundary explicitly excludes the MCP stdio bridge, provider-backed task runtime, vault/provider secret flows, memory/site-guide storage, live supervision streaming, extension permission policy, and release packaging from Phase 18. [VERIFIED: .planning/phases/18-page-adapter-dom-snapshot-and-action-verification/18-CONTEXT.md]
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PAGE-01 | Agent can read visible text from the active or owned target page. [VERIFIED: .planning/REQUIREMENTS.md] | Use Phase 17 ownership -> `WebContents` -> primary frame, then `content_extraction::GetInnerText`, with explicit load/stability timing handled by the adapter. [VERIFIED: .context/chromium/src/chrome/browser/prometheus/prometheus_agent_service.cc; VERIFIED: .context/chromium/src/components/content_extraction/content/browser/inner_text.h] |
| PAGE-02 | Agent can request DOM snapshots with stable refs, selectors, forms, ARIA labels, text, attributes, frame context, and actionability hints. [VERIFIED: .planning/REQUIREMENTS.md] | Use `optimization_guide::GetAIPageContent` in actionable mode as the snapshot substrate, then adapt `AnnotatedPageContent` into bounded Prometheus refs. [VERIFIED: .context/chromium/src/components/optimization_guide/content/browser/page_content_proto_provider.h; VERIFIED: .context/chromium/src/components/optimization_guide/content/browser/page_content_proto_util.h] |
| PAGE-03 | Agent can request compact page snapshots suitable for planning the next action. [VERIFIED: .planning/REQUIREMENTS.md] | Derive compact snapshots from the same annotated content and keep only actionable/visible/form/navigation-relevant nodes plus omitted counts. [VERIFIED: .planning/phases/18-page-adapter-dom-snapshot-and-action-verification/18-CONTEXT.md; VERIFIED: .context/chromium/src/components/optimization_guide/content/browser/page_content_proto_provider.cc] |
| PAGE-04 | Agent can execute audited JavaScript on normal web pages with explicit permission, result capture, and read-back verification. [VERIFIED: .planning/REQUIREMENTS.md] | Do not use production `RenderFrameHost::ExecuteJavaScript` for normal pages because the public API is restricted to `chrome://` or `devtools://`; implement a permissioned renderer/Mojo page adapter patterned after actor `ScriptToolHost` and `ChromeRenderFrame`. [VERIFIED: .context/chromium/src/content/public/browser/render_frame_host.h; VERIFIED: .context/chromium/src/chrome/browser/actor/tools/script_tool_host.cc; VERIFIED: .context/chromium/src/chrome/common/chrome_render_frame.mojom] |
| PAGE-05 | Agent can click, type, press keys, scroll, hover, select options, clear inputs, drag, and drop files where Chromium permits the action safely. [VERIFIED: .planning/REQUIREMENTS.md] | Reuse the actor page-tool design where it fits: target validation against observed APC, renderer-side tool execution, OOPIF coordinate handling, and typed unsupported denials for gaps such as unsafe file drop. [VERIFIED: .context/chromium/src/chrome/browser/actor/tools/page_tool.cc; VERIFIED: .context/chromium/src/chrome/browser/actor/tools/page_target_util.cc; VERIFIED: .context/chromium/src/chrome/common/actor.mojom] |
| PAGE-06 | Browser waits for page load, DOM stability, visible state change, or target-specific readiness after mutating actions. [VERIFIED: .planning/REQUIREMENTS.md] | Use `PageSettledMonitor` or a Prometheus wrapper around its pattern, plus `WebContentsObserver` for navigation/load and explicit value/focus/scroll checks. [VERIFIED: .context/chromium/src/components/page_content_annotations/content/browser/page_settled_monitor.h; VERIFIED: .context/chromium/src/chrome/browser/actor/tools/observation_delay_controller.h] |
| PAGE-07 | Browser returns change reports for mutating actions and identifies repeated/stuck action patterns. [VERIFIED: .planning/REQUIREMENTS.md] | Keep contentful reports in route results, keep audit changed-state content-free, and store recent session/tab/action fingerprints in the route service or page adapter. [VERIFIED: .planning/phases/18-page-adapter-dom-snapshot-and-action-verification/18-CONTEXT.md; VERIFIED: .context/chromium/src/chrome/browser/prometheus/prometheus_agent_service.cc] |
| PAGE-08 | Page adapters work across same-origin frames, cross-origin frames where browser privileges permit, and failure cases where the target is sandboxed or restricted. [VERIFIED: .planning/REQUIREMENTS.md] | Resolve frames through `RenderFrameHost` identity, active/live checks, document identifiers, and APC redaction metadata; return typed failures for unsupported cross-origin, sandboxed, fenced, detached, prerendered, or crashed targets. [VERIFIED: .context/chromium/src/content/public/browser/render_frame_host.h; VERIFIED: .context/chromium/src/components/optimization_guide/content/browser/page_content_proto_provider.cc; VERIFIED: .context/chromium/src/components/optimization_guide/content/browser/page_content_proto_util.cc] |
</phase_requirements>

## Summary

Phase 18 should extend the existing `PrometheusAgentService` route path instead of adding a separate control authority: validate session, touch session, resolve the browser/tab target, enforce tab ownership, then dispatch page reads/actions through a new page adapter. [VERIFIED: .context/chromium/src/chrome/browser/prometheus/prometheus_agent_service.cc; VERIFIED: .planning/phases/18-page-adapter-dom-snapshot-and-action-verification/18-CONTEXT.md]

For page understanding, the strongest local substrate is Chromium's annotated page-content pipeline: `GetAIPageContent` returns an `AnnotatedPageContent` proto plus document identifiers, actionable mode exists, and utility functions can find nodes by document token and DOM node id. [VERIFIED: .context/chromium/src/components/optimization_guide/content/browser/page_content_proto_provider.h; VERIFIED: .context/chromium/src/components/optimization_guide/content/browser/page_content_proto_util.h]

For normal-page JavaScript and actions, do not call `RenderFrameHost::ExecuteJavaScript` as the production mechanism because this checkout documents that API as valid only for `chrome://` or `devtools://`, and the unrestricted JavaScript APIs are explicitly test-only. [VERIFIED: .context/chromium/src/content/public/browser/render_frame_host.h] Use a production renderer/Mojo seam patterned after Chromium actor page tools and script tools, but keep the Phase 17 Prometheus route service as the authority boundary. [VERIFIED: .context/chromium/src/chrome/browser/actor/tools/page_tool.cc; VERIFIED: .context/chromium/src/chrome/browser/actor/tools/script_tool_host.cc; VERIFIED: .context/chromium/src/chrome/common/chrome_render_frame.mojom]

**Primary recommendation:** Build a `PrometheusPageAdapter` browser source set that consumes Phase 17 validated targets, uses `GetInnerText` and `GetAIPageContent` for reads/snapshots, adds a Prometheus-specific renderer/Mojo execution seam for JS/actions, and wraps every mutating route with wait + read-back verification + content-free audit metadata. [VERIFIED: local source review]

## Project Constraints

- No `./AGENTS.md` file exists in the workspace root, so no additional root agent directives were available. [VERIFIED: shell probe 2026-07-07]
- No `./CLAUDE.md` file exists in the workspace root, so there are no CLAUDE.md directives to include. [VERIFIED: shell probe 2026-07-07]
- No `.claude/skills/` or `.agents/skills/` project skill directory exists in the workspace root. [VERIFIED: shell probe 2026-07-07]
- `.planning/config.json` has `workflow.nyquist_validation: true`, so this research includes Validation Architecture. [VERIFIED: .planning/config.json]
- `.planning/config.json` does not disable security enforcement, so this research includes Security Domain. [VERIFIED: .planning/config.json]
- `.planning/graphs/graph.json` is absent, so no graph context was available for Phase 18 discovery. [VERIFIED: shell probe 2026-07-07]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Route authorization and tab ownership | Browser process / API service | Tab ownership data | Phase 17 already validates session, target, profile scope, and ownership through `PrometheusAgentService` and `PrometheusAgentTabData`. [VERIFIED: .context/chromium/src/chrome/browser/prometheus/prometheus_agent_service.cc; VERIFIED: .context/chromium/src/chrome/browser/prometheus/prometheus_agent_tab_data.h] |
| Page text read | Browser process page adapter | Renderer content extraction agent | Browser owns target policy; `GetInnerText` requests renderer inner text for the selected frame and same-origin local iframes. [VERIFIED: .context/chromium/src/components/content_extraction/content/browser/inner_text.h] |
| Full DOM/action snapshot | Browser process page adapter | Renderer APC agent | `GetAIPageContent` is invoked from browser code and requests renderer-provided annotated page content. [VERIFIED: .context/chromium/src/components/optimization_guide/content/browser/page_content_proto_provider.h; VERIFIED: .context/chromium/src/components/optimization_guide/content/browser/page_content_proto_provider.cc] |
| Compact action snapshot | Browser process page adapter | Snapshot transformer | Compactness, truncation, refs, and schema stability are Prometheus route-result concerns after the Chromium snapshot is collected. [VERIFIED: .planning/phases/18-page-adapter-dom-snapshot-and-action-verification/18-CONTEXT.md] |
| Normal-page JS execution | Renderer page adapter | Browser route policy and audit | Public browser `ExecuteJavaScript` is not the production normal-page path; actor script execution uses a renderer tool invocation pattern with browser-side document validation. [VERIFIED: .context/chromium/src/content/public/browser/render_frame_host.h; VERIFIED: .context/chromium/src/chrome/browser/actor/tools/script_tool_host.cc] |
| Page actions | Renderer page tool execution | Browser target/action verification | Actor page tools validate browser-observed targets and execute renderer-side tool actions, with browser wait/observation after execution. [VERIFIED: .context/chromium/src/chrome/browser/actor/tools/page_tool.cc; VERIFIED: .context/chromium/src/chrome/browser/actor/tools/tool_controller.cc] |
| Waits and visible state readiness | Browser observer | Renderer page stability monitor | `PageSettledMonitor` observes `WebContents` and creates a renderer-side stability monitor; actor's delay controller adds navigation handling around it. [VERIFIED: .context/chromium/src/components/page_content_annotations/content/browser/page_settled_monitor.h; VERIFIED: .context/chromium/src/chrome/browser/actor/tools/observation_delay_controller.h] |
| Audit and change reporting | Browser process / route service | Page adapter result builder | Existing audit records only carry route/session/target/result/timing/changed-state metadata, so contentful payloads must stay in route results. [VERIFIED: .context/chromium/src/chrome/browser/prometheus/prometheus_agent_service.cc; VERIFIED: .context/chromium/src/chrome/browser/prometheus/prometheus_agent_audit.h] |

## Standard Stack

### Core

| Component | Version | Purpose | Why Standard |
|-----------|---------|---------|--------------|
| Local Chromium checkout | `ad736125eefc5d60744124015b0418342740e86f` | Browser, content, renderer, and test API substrate. | Phase 18 implementation must patch this Chromium checkout and preserve Phase 17 routes. [VERIFIED: `git -C .context/chromium/src rev-parse HEAD`; VERIFIED: .planning/STATE.md] |
| `PrometheusAgentService` / `AgentRouteRequest` / `AgentRouteResult` | Local source | Typed route dispatch, target resolution, ownership, and audit recording. | Phase 18 decisions require extending this existing route spine instead of adding parallel authority. [VERIFIED: .context/chromium/src/chrome/browser/prometheus/prometheus_agent_service.cc; VERIFIED: .context/chromium/src/chrome/browser/prometheus/prometheus_agent_route.h] |
| `content::WebContents` and `content::RenderFrameHost` | Chromium public browser API | Live page and frame targeting. | Public APIs provide primary main frame, live/active checks, global frame ids/tokens, document weak pointers, sandbox/fenced-frame detection, and test-only JS boundaries. [VERIFIED: .context/chromium/src/content/public/browser/web_contents.h; VERIFIED: .context/chromium/src/content/public/browser/render_frame_host.h] |
| `content_extraction::GetInnerText` | Chromium component API | Visible text read path. | It returns combined inner text for a frame and local same-origin iframes, with an explicit note that it does not wait for load. [VERIFIED: .context/chromium/src/components/content_extraction/content/browser/inner_text.h] |
| `optimization_guide::GetAIPageContent` | Chromium component API | Full/actionable page snapshot substrate. | It returns `AIPageContentResult` for the primary page and has default/actionable modes. [VERIFIED: .context/chromium/src/components/optimization_guide/content/browser/page_content_proto_provider.h; VERIFIED: .context/chromium/src/components/optimization_guide/content/browser/page_content_proto_provider.cc] |
| `optimization_guide::DocumentIdentifierUserData` and page-content util functions | Chromium component API | Snapshot refs, document identity, and node lookup. | Utilities support document-token lookup, node lookup by document id + DOM node id, and RFH lookup for a document identifier. [VERIFIED: .context/chromium/src/components/optimization_guide/content/browser/page_content_proto_provider.h; VERIFIED: .context/chromium/src/components/optimization_guide/content/browser/page_content_proto_util.h] |
| `page_content_annotations::PageSettledMonitor` | Chromium component API | Post-action wait for page stability/load/visual update. | It defines settled state as page stability, load completion, visual state update, and optional LCP/PDF waits. [VERIFIED: .context/chromium/src/components/page_content_annotations/content/browser/page_settled_monitor.h] |
| Chromium actor page-tool patterns | Local Chromium source | Production reference for action dispatch and validation. | Page tools validate target frames against observed APC, convert coordinates across frame/widget spaces, call renderer tools, and wait after actions. [VERIFIED: .context/chromium/src/chrome/browser/actor/tools/page_tool.cc; VERIFIED: .context/chromium/src/chrome/browser/actor/tools/page_target_util.cc] |

### Supporting

| Component | Version | Purpose | When to Use |
|-----------|---------|---------|-------------|
| `chrome::mojom::ChromeRenderFrame` actor methods | Chromium Mojo interface | Reference renderer associated-interface pattern for tool and script invocation. | Use as a model for a Prometheus renderer seam or direct reuse if layering/feature gates are acceptable. [VERIFIED: .context/chromium/src/chrome/common/chrome_render_frame.mojom] |
| `content::WebContentsObserver` | Chromium public browser API | Navigation, load, frame, crash, deletion, and page-change observation. | Use for wait/read-back, stale target detection, and action race handling. [VERIFIED: .context/chromium/src/content/public/browser/web_contents.h; VERIFIED: .context/chromium/src/chrome/browser/actor/tools/script_tool_host.cc] |
| `content::WeakDocumentPtr` | Chromium public browser API | Avoids holding durable raw frame pointers across navigation. | Use when an action targets a specific document and must validate time-of-use state. [VERIFIED: .context/chromium/src/content/public/browser/render_frame_host.h; VERIFIED: .context/chromium/src/chrome/browser/actor/tools/script_tool_host.cc] |
| `content/public/test/browser_test_utils.h` | Chromium test API | Browser-test JS, input simulation, frame helpers, and load waits. | Use in tests only; do not copy test-only production behavior into page adapter code. [VERIFIED: .context/chromium/src/content/public/test/browser_test_utils.h] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| APC-backed snapshots | Custom DOM crawler JS | Custom JS would fight cross-frame policy, output bounding, renderer trust, and actionability semantics that Chromium already exposes in APC. [VERIFIED: .context/chromium/src/components/optimization_guide/content/browser/page_content_proto_provider.cc; VERIFIED: .planning/phases/18-page-adapter-dom-snapshot-and-action-verification/18-CONTEXT.md] |
| Prometheus renderer/Mojo JS/action seam | `RenderFrameHost::ExecuteJavaScript` | Public production API is documented as only valid for `chrome://` or `devtools://`, and unrestricted variants are test-only. [VERIFIED: .context/chromium/src/content/public/browser/render_frame_host.h] |
| Time-of-use frame validation | Durable `FrameTreeNodeId` or raw RFH pointer | `WebContents::UnsafeFindFrameByFrameTreeNodeId` is explicitly unsafe across RFH/privilege changes, and RFH docs recommend global ids/tokens for stable reference. [VERIFIED: .context/chromium/src/content/public/browser/web_contents.h; VERIFIED: .context/chromium/src/content/public/browser/render_frame_host.h] |
| `PageSettledMonitor` wait path | Fixed sleeps | Chromium already has page stability/load/visual-state coordination and actor wrappers for action observation. [VERIFIED: .context/chromium/src/components/page_content_annotations/content/browser/page_settled_monitor.h; VERIFIED: .context/chromium/src/chrome/browser/actor/tools/observation_delay_controller.h] |

**Installation:** No npm or external package installation is recommended for this Chromium C++ phase. [VERIFIED: .context/chromium/src/chrome/browser/prometheus/BUILD.gn]

**Version verification:** `npm view` is not applicable because the standard stack is Chromium C++ source, not npm packages; the local Chromium HEAD was verified with git as `ad736125eefc5d60744124015b0418342740e86f`. [VERIFIED: `git -C .context/chromium/src rev-parse HEAD`]

## Architecture Patterns

### System Architecture Diagram

```text
Route request
  -> PrometheusAgentService
      -> Validate session and touch session
      -> Resolve browser/tab target within profile
      -> Ensure tab ownership
      -> Reject internal/restricted URL surfaces
      -> PrometheusPageAdapter
          -> Resolve live WebContents
          -> Resolve frame target
              -> default: primary main frame
              -> explicit frame: document token / RFH identity / live active checks
              -> unsupported: typed failure
          -> Read branch
              -> read_page: wait policy if requested -> GetInnerText -> truncate/result
              -> get_dom_snapshot: GetAIPageContent actionable/default -> full bounded schema
              -> get_page_snapshot: same snapshot -> compact action schema
          -> Mutating branch
              -> resolve ref/selector against current snapshot/frame
              -> actionability and permission checks
              -> renderer/Mojo JS or action invocation
              -> wait for navigation/load/stability/visible/value/focus/scroll change
              -> bounded read-back and change report
      -> AgentRouteResult with content payload
      -> RecordAudit with route/session/target/status/timing/content-free changed_state
```

This data flow keeps Phase 17 route authority before every page operation and keeps page content out of audit records. [VERIFIED: .context/chromium/src/chrome/browser/prometheus/prometheus_agent_service.cc; VERIFIED: .planning/phases/18-page-adapter-dom-snapshot-and-action-verification/18-CONTEXT.md]

### Recommended Project Structure

```text
chrome/browser/prometheus/
+-- prometheus_page_adapter.h/.cc          # route-owned page read/action facade
+-- prometheus_page_snapshot.h/.cc         # APC -> full/compact snapshot schemas
+-- prometheus_page_action.h/.cc           # action request/result, validation, stuck keys
+-- prometheus_page_waiter.h/.cc           # WebContentsObserver/PageSettledMonitor wrapper
+-- prometheus_page_error.h/.cc            # typed page/frame/action error mapping
+-- prometheus_page_adapter_unittest.cc    # pure snapshot/ref/error/bounding/stuck tests
+-- prometheus_agent_service_browsertest.cc or prometheus_page_adapter_browsertest.cc
```

This structure keeps pure schema/validation logic unit-testable while the service and browser tests cover Chromium integration. [VERIFIED: .planning/phases/18-page-adapter-dom-snapshot-and-action-verification/18-CONTEXT.md; VERIFIED: .context/chromium/src/chrome/browser/prometheus/BUILD.gn]

### Pattern 1: Extend the Existing Route Spine

**What:** Add page route enum values and request/result payload fields to `AgentRouteName`, `AgentRouteRequest`, and `AgentRouteResult`, then dispatch them inside `PrometheusAgentService::ExecuteRoute` after Phase 17 validation. [VERIFIED: .context/chromium/src/chrome/browser/prometheus/prometheus_agent_route.h; VERIFIED: .context/chromium/src/chrome/browser/prometheus/prometheus_agent_service.cc]

**When to use:** Use this for every Phase 18 route, including read-only routes, because the locked decision requires session, target, ownership, profile, and route allowlist policy before page access. [VERIFIED: .planning/phases/18-page-adapter-dom-snapshot-and-action-verification/18-CONTEXT.md]

**Example:**

```cpp
// Source: local Phase 17 route pattern + Phase 18 context.
case AgentRouteName::kReadPage:
case AgentRouteName::kGetDomSnapshot:
case AgentRouteName::kClick: {
  ResolvedTarget resolved;
  AgentRouteResult resolved_result =
      ResolveTarget(browser, request.target, /*require_tab=*/true, &resolved);
  if (!resolved_result.ok) {
    return FinishRoute(request, timestamp, started_at, resolved_result);
  }
  AgentRouteResult control = EnsureCanControl(resolved.tab, session);
  if (!control.ok) {
    return FinishRoute(request, timestamp, started_at, control);
  }
  return FinishRoute(request, timestamp, started_at,
                     page_adapter_.Execute(resolved, request));
}
```

### Pattern 2: Resolve Frame Targets at Time of Use

**What:** Convert a route target into `WebContents`, then resolve a live active `RenderFrameHost` using primary-main-frame defaulting, document identifier tokens, RFH global ids/tokens, and `WeakDocumentPtr` for document-specific actions. [VERIFIED: .context/chromium/src/content/public/browser/web_contents.h; VERIFIED: .context/chromium/src/content/public/browser/render_frame_host.h; VERIFIED: .context/chromium/src/chrome/browser/actor/tools/script_tool_host.cc]

**When to use:** Use this for snapshots, JS, and every action that targets an element or frame because refs are per-snapshot and not durable across navigation. [VERIFIED: .planning/phases/18-page-adapter-dom-snapshot-and-action-verification/18-CONTEXT.md]

**Example:**

```cpp
// Source: local RenderFrameHost lifecycle API and actor ScriptToolHost pattern.
content::RenderFrameHost* frame = web_contents->GetPrimaryMainFrame();
if (!frame || !frame->IsActive() || !frame->IsRenderFrameLive()) {
  return PageError::StaleFrame("Target frame is not live and active");
}
if (frame->IsNestedWithinFencedFrame() || IsUnsupportedSandbox(frame)) {
  return PageError::RestrictedFrame("Target frame is restricted");
}
content::WeakDocumentPtr document = frame->GetWeakDocumentPtr();
```

### Pattern 3: Use APC as the Snapshot Source of Truth

**What:** Call `GetAIPageContent` with `ActionableAIPageContentOptions` for DOM/action snapshots, then map Chromium nodes into bounded Prometheus refs, selectors, snippets, attributes, form state, frame context, and actionability fields. [VERIFIED: .context/chromium/src/components/optimization_guide/content/browser/page_content_proto_provider.h; VERIFIED: .context/chromium/src/components/optimization_guide/content/browser/page_content_proto_provider.cc]

**When to use:** Use for `get_dom_snapshot`, `get_page_snapshot`, action target resolution by node id/document id, and compact change reports. [VERIFIED: .planning/REQUIREMENTS.md; VERIFIED: .context/chromium/src/components/optimization_guide/content/browser/page_content_proto_util.h]

**Example:**

```cpp
// Source: local optimization_guide page_content_proto_provider API.
auto options =
    optimization_guide::ActionableAIPageContentOptions(/*on_critical_path=*/true);
optimization_guide::GetAIPageContent(
    web_contents, std::move(options),
    base::BindOnce(&PrometheusPageAdapter::OnSnapshotReady,
                   weak_factory_.GetWeakPtr(), std::move(context)));
```

### Pattern 4: Keep Normal-Page JS Behind Explicit Permission and Renderer IPC

**What:** Implement `execute_js` as an explicit page route whose payload is validated/bounded, sent to a renderer-side Prometheus executor, and returned as structured success/error data with read-back verification if mutating. [VERIFIED: .planning/phases/18-page-adapter-dom-snapshot-and-action-verification/18-CONTEXT.md; VERIFIED: .context/chromium/src/chrome/browser/actor/tools/script_tool_host.cc]

**When to use:** Use this for PAGE-04; do not hide JS under read/action helpers or write raw scripts into audit logs. [VERIFIED: .planning/phases/18-page-adapter-dom-snapshot-and-action-verification/18-CONTEXT.md]

**Example:**

```cpp
// Source: local RenderFrameHost JS boundary and ChromeRenderFrame actor IPC pattern.
if (!request.page_js_permission_granted) {
  return PageError::PermissionBlocked("execute_js requires explicit permission");
}
if (!IsNormalWebPage(frame->GetLastCommittedURL())) {
  return PageError::PermissionBlocked("execute_js is blocked on internal pages");
}
// Send bounded script text over the Prometheus renderer interface; do not use
// RenderFrameHost::ExecuteJavaScript for normal pages.
```

### Pattern 5: Verify Every Mutation with Wait + Read-Back

**What:** After action dispatch, wait for the most relevant condition and compare bounded before/after facts: navigation URL/status, DOM snapshot digest, target value, focus, scroll position, visibility, or explicit no-change. [VERIFIED: .planning/phases/18-page-adapter-dom-snapshot-and-action-verification/18-CONTEXT.md; VERIFIED: .context/chromium/src/components/page_content_annotations/content/browser/page_settled_monitor.h]

**When to use:** Use for JS mutations and all actions except read-only hover when no visible/focus change is expected; hover should still report verification status. [VERIFIED: .planning/REQUIREMENTS.md]

**Example:**

```cpp
// Source: local PageSettledMonitor API and Phase 18 D-19/D-20.
auto delegate = std::make_unique<page_content_annotations::PageSettledMonitor::Delegate>(
    page_content_annotations::PageSettledMonitor::PageStabilityConfig{
        .supports_paint_stability = true});
auto monitor = std::make_unique<page_content_annotations::PageSettledMonitor>(
    target_frame, std::move(delegate));
monitor->Wait(web_contents, base::BindOnce(&PrometheusPageWaiter::OnSettled,
                                           weak_factory_.GetWeakPtr()));
```

### Anti-Patterns to Avoid

- **Direct production normal-page `RenderFrameHost::ExecuteJavaScript`:** The public API is documented as valid only for `chrome://` or `devtools://`, and unrestricted variants are test-only. [VERIFIED: .context/chromium/src/content/public/browser/render_frame_host.h]
- **Using `WebContents::ForEachRenderFrameHost` without primary-page filtering:** `WebContents` can include prerendered or BFCache frames; primary-page descendant traversal should start from `GetPrimaryMainFrame()` where primary-page scope is required. [VERIFIED: .context/chromium/src/content/public/browser/web_contents.h]
- **Durable element refs across navigations:** Phase 18 explicitly forbids durable refs across navigation, renderer process changes, frame detach, or DOM replacement. [VERIFIED: .planning/phases/18-page-adapter-dom-snapshot-and-action-verification/18-CONTEXT.md]
- **Contentful audit strings:** Existing audit writes `changed_state` into audit records, so page text, DOM snippets, scripts, typed text, and file paths must stay out of `changed_state`. [VERIFIED: .context/chromium/src/chrome/browser/prometheus/prometheus_agent_service.cc]
- **Copying `content/public/test/browser_test_utils.h` behavior into production:** `EvalJs`, `ExecJs`, simulated input helpers, and many frame utilities are test APIs. [VERIFIED: .context/chromium/src/content/public/test/browser_test_utils.h]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Visible text extraction | Ad hoc JS `innerText` crawler | `content_extraction::GetInnerText` plus adapter-level waiting/truncation | Chromium already has browser-to-renderer inner-text extraction and documents same-origin iframe behavior. [VERIFIED: .context/chromium/src/components/content_extraction/content/browser/inner_text.h] |
| DOM/action snapshot | Custom serialized DOM walker | `optimization_guide::GetAIPageContent` and APC utilities | APC already carries annotated page content, document identifiers, redaction metadata, and actionable mode. [VERIFIED: .context/chromium/src/components/optimization_guide/content/browser/page_content_proto_provider.h; VERIFIED: .context/chromium/src/components/optimization_guide/content/browser/page_content_proto_util.h] |
| Frame identity | Raw selectors, raw `FrameTreeNodeId`, or raw RFH pointer storage | RFH global ids/tokens, document identifiers, `WeakDocumentPtr`, and live re-resolution | Chromium warns `UnsafeFindFrameByFrameTreeNodeId` is generally unsafe across RFH/privilege changes, and actor code validates documents at time of use. [VERIFIED: .context/chromium/src/content/public/browser/web_contents.h; VERIFIED: .context/chromium/src/chrome/browser/actor/tools/script_tool_host.cc] |
| Page stability waits | Fixed sleeps or polling loops only | `PageSettledMonitor` / actor `ObservationDelayController` pattern | Chromium already coordinates renderer page stability, load completion, visual updates, and navigation restart behavior. [VERIFIED: .context/chromium/src/components/page_content_annotations/content/browser/page_settled_monitor.h; VERIFIED: .context/chromium/src/chrome/browser/actor/tools/observation_delay_controller.h] |
| Action coordinate validation | Blind coordinates or renderer-controlled selector authority | APC-backed target validation and actor page-target utilities | Actor code validates observed targets, local-root frames, OOPIF widget transforms, and device-scale coordinate conversion. [VERIFIED: .context/chromium/src/chrome/browser/actor/tools/page_tool.cc; VERIFIED: .context/chromium/src/chrome/browser/actor/tools/page_target_util.cc] |
| Browser tests for JS/input | Custom test harness | `content::EvalJs`, `ExecJs`, `WaitForLoadStop`, `SimulateMouse*`, `SimulateKeyPress` in tests only | Chromium provides focused browser-test helpers that should stay in test code. [VERIFIED: .context/chromium/src/content/public/test/browser_test_utils.h] |

**Key insight:** The risky parts of Phase 18 are not string formatting; they are browser security boundaries, frame/document lifetime, renderer IPC, cross-origin redaction, OOPIF coordinates, and action verification, all of which already have Chromium patterns to reuse or mirror. [VERIFIED: local Chromium source review]

## Common Pitfalls

### Pitfall 1: Treating test-only JavaScript APIs as production APIs

**What goes wrong:** A route appears to work in browser tests but uses unrestricted JS execution that is documented for tests only. [VERIFIED: .context/chromium/src/content/public/browser/render_frame_host.h; VERIFIED: .context/chromium/src/content/public/test/browser_test_utils.h]

**Why it happens:** `EvalJs`, `ExecJs`, and `ExecuteJavaScriptForTests` are convenient and powerful, but they are test support APIs rather than a production normal-page route mechanism. [VERIFIED: .context/chromium/src/content/public/test/browser_test_utils.h; VERIFIED: .context/chromium/src/content/public/browser/render_frame_host.h]

**How to avoid:** Put PAGE-04 behind a permissioned Prometheus renderer/Mojo execution interface or a carefully justified reuse of Chromium actor script tooling. [VERIFIED: .context/chromium/src/chrome/browser/actor/tools/script_tool_host.cc; VERIFIED: .context/chromium/src/chrome/common/chrome_render_frame.mojom]

**Warning signs:** Production code includes `ExecuteJavaScriptForTests`, includes `content/public/test/browser_test_utils.h`, or calls `RenderFrameHost::ExecuteJavaScript` on HTTP/HTTPS pages. [VERIFIED: .context/chromium/src/content/public/browser/render_frame_host.h]

### Pitfall 2: Traversing non-primary or inactive frames

**What goes wrong:** Snapshots or actions touch prerendered, BFCache, detached, or inactive frames instead of the visible page. [VERIFIED: .context/chromium/src/content/public/browser/web_contents.h; VERIFIED: .context/chromium/src/content/public/browser/render_frame_host.h]

**Why it happens:** `WebContents::ForEachRenderFrameHost` can include frames outside the primary page, while RFH lifecycle APIs distinguish active/live state. [VERIFIED: .context/chromium/src/content/public/browser/web_contents.h; VERIFIED: .context/chromium/src/content/public/browser/render_frame_host.h]

**How to avoid:** Default to `GetPrimaryMainFrame()`, traverse descendants from the primary main frame when needed, and require `IsActive()` plus `IsRenderFrameLive()` before renderer IPC. [VERIFIED: .context/chromium/src/content/public/browser/web_contents.h; VERIFIED: .context/chromium/src/content/public/browser/render_frame_host.h]

**Warning signs:** Code uses `WebContents::ForEachRenderFrameHost` directly for page content or sends IPC without `IsRenderFrameLive()`. [VERIFIED: .context/chromium/src/content/public/browser/web_contents.h; VERIFIED: .context/chromium/src/content/public/browser/render_frame_host.h]

### Pitfall 3: Confusing snapshot refs with durable handles

**What goes wrong:** Actions target stale DOM nodes after navigation, process swaps, or DOM replacement. [VERIFIED: .planning/phases/18-page-adapter-dom-snapshot-and-action-verification/18-CONTEXT.md]

**Why it happens:** Snapshot refs are planner conveniences, not browser authority; Chromium frame/document identity can change between observation and action. [VERIFIED: .planning/phases/18-page-adapter-dom-snapshot-and-action-verification/18-CONTEXT.md; VERIFIED: .context/chromium/src/chrome/browser/actor/tools/page_tool.cc]

**How to avoid:** Encode refs as per-snapshot document token + DOM node id + checksum/schema version, then re-resolve against a fresh/live frame or fail typed stale-target. [VERIFIED: .context/chromium/src/components/optimization_guide/content/browser/page_content_proto_util.h; VERIFIED: .planning/phases/18-page-adapter-dom-snapshot-and-action-verification/18-CONTEXT.md]

**Warning signs:** Ref format lacks frame/document identity or action code trusts a previous snapshot without revalidation. [VERIFIED: .planning/phases/18-page-adapter-dom-snapshot-and-action-verification/18-CONTEXT.md]

### Pitfall 4: Leaking content through audit or changed-state strings

**What goes wrong:** Page text, selectors, typed text, scripts, or file paths end up in audit records. [VERIFIED: .planning/phases/18-page-adapter-dom-snapshot-and-action-verification/18-CONTEXT.md]

**Why it happens:** `RecordAudit` persists `changed_state`, so using human-readable content there violates D-02 and D-24. [VERIFIED: .context/chromium/src/chrome/browser/prometheus/prometheus_agent_service.cc; VERIFIED: .planning/phases/18-page-adapter-dom-snapshot-and-action-verification/18-CONTEXT.md]

**How to avoid:** Keep audit `changed_state` to constants such as `page_text_read`, `snapshot_returned`, `element_clicked`, `navigation_observed`, and put contentful payloads only in route results. [VERIFIED: .context/chromium/src/chrome/browser/prometheus/prometheus_agent_service.cc]

**Warning signs:** Tests assert audit entries contain selector strings, JS text, input values, or page snippets. [VERIFIED: .planning/phases/18-page-adapter-dom-snapshot-and-action-verification/18-CONTEXT.md]

### Pitfall 5: OOPIF and device-scale coordinate mistakes

**What goes wrong:** Click/hover/drag hits the wrong frame or wrong point under out-of-process iframes or non-1.0 device scale. [VERIFIED: .context/chromium/src/chrome/browser/actor/tools/page_target_util.cc; VERIFIED: .context/chromium/src/chrome/browser/actor/tools/page_tool.cc]

**Why it happens:** APC hit testing uses Blink-space/device-pixel concepts while browser action coordinates often use DIPs and local root frame widget space. [VERIFIED: .context/chromium/src/chrome/browser/actor/tools/page_target_util.h; VERIFIED: .context/chromium/src/chrome/browser/actor/tools/page_tool.cc]

**How to avoid:** Prefer DOM node/document targeting for actions; when coordinates are needed, mirror actor target utilities and test under same-origin iframe, cross-origin iframe, OOPIF, and scaled cases. [VERIFIED: .context/chromium/src/chrome/browser/actor/tools/page_target_util.cc; VERIFIED: .planning/phases/18-page-adapter-dom-snapshot-and-action-verification/18-CONTEXT.md]

**Warning signs:** Action code accepts raw page coordinates without local-root frame resolution or scale conversion. [VERIFIED: .context/chromium/src/chrome/browser/actor/tools/page_target_util.cc]

## Code Examples

Verified patterns from local source:

### Frame Liveness Gate

```cpp
// Source: content/public/browser/render_frame_host.h
content::RenderFrameHost* frame = web_contents->GetPrimaryMainFrame();
if (!frame || !frame->IsActive() || !frame->IsRenderFrameLive()) {
  return PageError::StaleTarget("Target frame is not active and live");
}
```

This check matches Chromium's active/live RFH distinction and avoids silent IPC failure to non-live frames. [VERIFIED: .context/chromium/src/content/public/browser/render_frame_host.h]

### APC Snapshot Request

```cpp
// Source: components/optimization_guide/content/browser/page_content_proto_provider.h
auto options =
    optimization_guide::ActionableAIPageContentOptions(/*on_critical_path=*/true);
optimization_guide::GetAIPageContent(web_contents, std::move(options),
                                     std::move(done_callback));
```

This uses Chromium's actionable annotated-page-content mode rather than custom DOM crawling. [VERIFIED: .context/chromium/src/components/optimization_guide/content/browser/page_content_proto_provider.h; VERIFIED: .context/chromium/src/components/optimization_guide/content/browser/page_content_proto_provider.cc]

### Document-Scoped Node Lookup

```cpp
// Source: components/optimization_guide/content/browser/page_content_proto_util.h
auto target = optimization_guide::FindNodeWithID(
    snapshot.annotated_page_content, ref.document_token, ref.dom_node_id);
if (!target.has_value()) {
  return PageError::StaleTarget("Element ref no longer resolves");
}
```

This makes element refs snapshot/document scoped and allows typed stale-target failures. [VERIFIED: .context/chromium/src/components/optimization_guide/content/browser/page_content_proto_util.h; VERIFIED: .planning/phases/18-page-adapter-dom-snapshot-and-action-verification/18-CONTEXT.md]

### Content-Free Audit Result

```cpp
// Source: chrome/browser/prometheus/prometheus_agent_service.cc
AgentRouteResult result = AgentRouteResult::Success({"element_clicked"});
result.page_payload = std::move(contentful_page_result);
```

The exact payload field does not exist yet, but the pattern keeps stable constants in `changed_state` and content in the returned route result. [VERIFIED: .context/chromium/src/chrome/browser/prometheus/prometheus_agent_route.h; VERIFIED: .context/chromium/src/chrome/browser/prometheus/prometheus_agent_service.cc]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Screenshot-first page control | DOM/native structural control with screenshot fallback out of the primary loop | Locked for Phase 18 in context | Planner should prioritize text/APC/actions and not design a vision-driven control loop. [VERIFIED: .planning/phases/18-page-adapter-dom-snapshot-and-action-verification/18-CONTEXT.md] |
| Custom DOM JS snapshots | `GetAIPageContent` annotated page content | Present in local Chromium checkout | Planner can build bounded full/compact snapshots from Chromium's page-content pipeline. [VERIFIED: .context/chromium/src/components/optimization_guide/content/browser/page_content_proto_provider.h] |
| Test-only `EvalJs`/`ExecJs` style control | Production renderer/Mojo tool invocation | Present in local actor code | Planner must separate production JS/action APIs from browser-test helpers. [VERIFIED: .context/chromium/src/content/public/test/browser_test_utils.h; VERIFIED: .context/chromium/src/chrome/common/chrome_render_frame.mojom] |
| Fixed post-action sleeps | Page stability/load/visual-state monitor | Present in local Chromium checkout | Planner can build deterministic action verification around Chromium page settling. [VERIFIED: .context/chromium/src/components/page_content_annotations/content/browser/page_settled_monitor.h] |

**Deprecated/outdated:**

- Treating `FrameTreeNodeId` as a stable authority is unsafe for this phase because Chromium warns RFH changes can also be privilege changes. [VERIFIED: .context/chromium/src/content/public/browser/web_contents.h]
- Treating unrestricted JS helpers as product implementation is invalid because unrestricted RFH JS variants are marked test-only. [VERIFIED: .context/chromium/src/content/public/browser/render_frame_host.h]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The recommended `PrometheusPageAdapter` class split is a planning recommendation, not a locked architectural decision. [ASSUMED] | Summary / Recommended Project Structure | Low: planner may choose a helper owned by `PrometheusAgentService` or a facade split, which CONTEXT.md allows. [VERIFIED: .planning/phases/18-page-adapter-dom-snapshot-and-action-verification/18-CONTEXT.md] |
| A2 | Direct dependency on the actor feature-gated product stack should be avoided unless the planner confirms layering and feature-flag acceptability. [ASSUMED] | Open Questions / Standard Stack | Medium: if direct actor reuse is allowed, implementation may be smaller; if not, Prometheus needs a parallel renderer seam patterned after actor tools. [VERIFIED: .context/chromium/src/chrome/browser/actor/README.md; VERIFIED: .context/chromium/src/chrome/browser/actor/tools/page_tool.cc] |

## Open Questions

1. **Should Prometheus directly reuse actor page tools or create a Prometheus-specific renderer interface?** [VERIFIED: local actor source review]
   - What we know: actor tools already solve target validation, renderer invocation, page-stability waits, OOPIF coordinates, and script result handling. [VERIFIED: .context/chromium/src/chrome/browser/actor/tools/page_tool.cc; VERIFIED: .context/chromium/src/chrome/browser/actor/tools/script_tool_host.cc]
   - What's unclear: Phase 18 context says actor can inform implementation but does not lock direct reuse, and actor code is tied to Glic/actor feature flags and task/journal concepts. [VERIFIED: .planning/phases/17-native-agent-command-service-and-tab-ownership/17-CONTEXT.md; VERIFIED: .context/chromium/src/chrome/browser/actor/README.md]
   - Recommendation: plan a Prometheus-specific adapter that mirrors actor seams first, and only directly link actor code after a layering/feature-flag check. [ASSUMED]

2. **What is the safe policy for `drop_file`?** [VERIFIED: .planning/phases/18-page-adapter-dom-snapshot-and-action-verification/18-CONTEXT.md]
   - What we know: Phase 18 requires no arbitrary local file reads from untrusted input. [VERIFIED: .planning/phases/18-page-adapter-dom-snapshot-and-action-verification/18-CONTEXT.md]
   - What's unclear: No approved file handle/path policy is chosen in context. [VERIFIED: .planning/phases/18-page-adapter-dom-snapshot-and-action-verification/18-CONTEXT.md]
   - Recommendation: implement typed denial in the first wave, then add fixture-only browser-test support or explicit safe file policy if the planner scopes it. [ASSUMED]

3. **How complete should key/clear support be in the first implementation?** [VERIFIED: .planning/REQUIREMENTS.md]
   - What we know: actor request types cover click, type, scroll, hover/move mouse, select, drag/release, script, and scroll-to; direct press-key and clear routes are not obvious in the actor request list. [VERIFIED: .context/chromium/src/chrome/common/actor.mojom; VERIFIED: .context/chromium/src/chrome/browser/actor/tools/type_tool_request.cc]
   - What's unclear: Prometheus may implement `clear` as a specific input value action and `press_key` through safe browser/renderer input dispatch, or return typed unsupported for unsafe combinations. [ASSUMED]
   - Recommendation: plan key/clear as separate tasks with focused browser tests before claiming PAGE-05 complete. [ASSUMED]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Chromium checkout | All source research and implementation | yes | `ad736125eefc5d60744124015b0418342740e86f` | None. [VERIFIED: `git -C .context/chromium/src rev-parse HEAD`] |
| `out/Default` build directory | Build and test execution | yes | local Chromium build output present | Regenerate GN/build if missing. [VERIFIED: shell probe 2026-07-07] |
| `browser_tests` binary | Browser-test validation | yes | binary present | Build with `autoninja -C out/Default browser_tests`. [VERIFIED: shell probe 2026-07-07] |
| `prometheus_unittests` binary | Unit validation | yes | binary present | Build with `autoninja -C out/Default prometheus_unittests`. [VERIFIED: shell probe 2026-07-07] |
| `autoninja` | Chromium build | yes | `1.13.2` | Use `ninja -C out/Default` if GN output is current. [VERIFIED: shell probe 2026-07-07] |
| `ninja` | Chromium build fallback | yes | `1.13.2` | None needed. [VERIFIED: shell probe 2026-07-07] |
| `python3` | Chromium scripts and local tooling | yes | `Python 3.14.3` | Use depot_tools-managed scripts where required. [VERIFIED: shell probe 2026-07-07] |
| `node` | GSD tooling | yes | `v24.14.1` | None needed. [VERIFIED: shell probe 2026-07-07] |
| `rg` | Source discovery | yes | `ripgrep 15.1.0` | Use `grep` if unavailable. [VERIFIED: shell probe 2026-07-07] |

**Missing dependencies with no fallback:**

- None found during the availability audit. [VERIFIED: shell probe 2026-07-07]

**Missing dependencies with fallback:**

- None found during the availability audit. [VERIFIED: shell probe 2026-07-07]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Chromium GN targets with GTest unit tests and `InProcessBrowserTest` browser tests. [VERIFIED: .context/chromium/src/chrome/browser/prometheus/BUILD.gn; VERIFIED: .context/chromium/src/chrome/browser/prometheus/prometheus_agent_service_browsertest.cc] |
| Config file | Unit target: `.context/chromium/src/chrome/browser/prometheus/BUILD.gn`; browser-test inclusion: `.context/chromium/src/chrome/browser/ui/views/prometheus/BUILD.gn` included by `.context/chromium/src/chrome/test/BUILD.gn`. [VERIFIED: .context/chromium/src/chrome/browser/prometheus/BUILD.gn; VERIFIED: .context/chromium/src/chrome/browser/ui/views/prometheus/BUILD.gn; VERIFIED: .context/chromium/src/chrome/test/BUILD.gn] |
| Quick run command | `cd .context/chromium/src && ./out/Default/prometheus_unittests --gtest_filter='*PrometheusPage*:*PrometheusAgent*'` [VERIFIED: local target/binary presence] |
| Focused browser command | `cd .context/chromium/src && ./out/Default/browser_tests --gtest_filter='*Prometheus*Page*:*PrometheusAgentService*'` [VERIFIED: local browser_tests binary presence] |
| Build command | `cd .context/chromium/src && ../../depot_tools/autoninja -C out/Default browser_tests prometheus_unittests` [VERIFIED: local depot_tools/autoninja presence] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| PAGE-01 | `read_page` returns bounded visible text for active/owned tab and fails stale/restricted targets. [VERIFIED: .planning/REQUIREMENTS.md] | browser + unit | `./out/Default/browser_tests --gtest_filter='*Prometheus*ReadPage*'` | No: add browser test fixture/source. [VERIFIED: rg source scan] |
| PAGE-02 | `get_dom_snapshot` returns refs/selectors/form/ARIA/actionability/frame fields with bounded output. [VERIFIED: .planning/REQUIREMENTS.md] | unit + browser | `./out/Default/prometheus_unittests --gtest_filter='*PrometheusPageSnapshot*'` | No: add unit test source. [VERIFIED: rg source scan] |
| PAGE-03 | `get_page_snapshot` returns compact action-oriented snapshot and omitted/truncated metadata. [VERIFIED: .planning/REQUIREMENTS.md] | unit + browser | `./out/Default/prometheus_unittests --gtest_filter='*PrometheusPageSnapshot*Compact*'` | No: add unit test source. [VERIFIED: rg source scan] |
| PAGE-04 | `execute_js` requires explicit permission, captures result/error, blocks internal pages, and verifies mutation. [VERIFIED: .planning/REQUIREMENTS.md] | unit + browser | `./out/Default/browser_tests --gtest_filter='*Prometheus*ExecuteJs*'` | No: add browser test source. [VERIFIED: rg source scan] |
| PAGE-05 | Click/type/key/scroll/hover/select/clear/drag/drop safe routes work or return typed unsupported denial. [VERIFIED: .planning/REQUIREMENTS.md] | browser + unit | `./out/Default/browser_tests --gtest_filter='*Prometheus*PageAction*'` | No: add browser test source. [VERIFIED: rg source scan] |
| PAGE-06 | Mutating routes wait for load/stability/visible/value/focus/scroll changes. [VERIFIED: .planning/REQUIREMENTS.md] | browser | `./out/Default/browser_tests --gtest_filter='*Prometheus*PageWait*'` | No: add browser test source. [VERIFIED: rg source scan] |
| PAGE-07 | Change reports are compact/content-safe and repeated/stuck actions are detected. [VERIFIED: .planning/REQUIREMENTS.md] | unit + browser | `./out/Default/prometheus_unittests --gtest_filter='*PrometheusPageActionHistory*:*PrometheusPageChangeReport*'` | No: add unit test source. [VERIFIED: rg source scan] |
| PAGE-08 | Same-origin frames work; cross-origin/sandbox/fenced/detached/restricted failures are explicit. [VERIFIED: .planning/REQUIREMENTS.md] | browser | `./out/Default/browser_tests --gtest_filter='*Prometheus*Frame*'` | No: add browser test fixture/source. [VERIFIED: rg source scan] |

### Sampling Rate

- **Per task commit:** Run focused `prometheus_unittests` for changed pure logic plus the most relevant single browser-test filter. [VERIFIED: .planning/phases/18-page-adapter-dom-snapshot-and-action-verification/18-CONTEXT.md]
- **Per wave merge:** Build `browser_tests prometheus_unittests` and run all Phase 18 focused filters. [VERIFIED: .planning/phases/18-page-adapter-dom-snapshot-and-action-verification/18-CONTEXT.md]
- **Phase gate:** Build, focused unit tests, focused browser tests, root Chromium env, GPL guard, artifact isolation, diff checks, preservation ledger update, and Chromium patch export. [VERIFIED: .planning/phases/18-page-adapter-dom-snapshot-and-action-verification/18-CONTEXT.md; VERIFIED: .planning/phases/17-native-agent-command-service-and-tab-ownership/17-VERIFICATION.md]

### Wave 0 Gaps

- [ ] `chrome/browser/prometheus/prometheus_page_adapter_unittest.cc` for refs, truncation, selectors, typed errors, audit-safe change strings, and stuck keys. [VERIFIED: rg source scan; VERIFIED: .planning/phases/18-page-adapter-dom-snapshot-and-action-verification/18-CONTEXT.md]
- [ ] `chrome/browser/prometheus/prometheus_page_snapshot_unittest.cc` or equivalent if snapshot compaction is split from adapter logic. [ASSUMED]
- [ ] `chrome/browser/prometheus/prometheus_page_adapter_browsertest.cc` or extensions to `prometheus_agent_service_browsertest.cc` for end-to-end routes. [VERIFIED: .context/chromium/src/chrome/browser/prometheus/prometheus_agent_service_browsertest.cc]
- [ ] Local HTML fixtures under `chrome/test/data/prometheus/page_adapter/` for visible text, forms, ARIA labels, dynamic DOM, same-origin iframe, cross-origin iframe, sandbox/restricted frame, navigation click, typing, selection, scrolling, hover/focus, drag/drop if implemented, and JS success/error/read-back. [VERIFIED: .planning/phases/18-page-adapter-dom-snapshot-and-action-verification/18-CONTEXT.md]
- [ ] GN wiring for new unit-test sources in `chrome/browser/prometheus/BUILD.gn` and browser-test sources in `chrome/browser/ui/views/prometheus/BUILD.gn` unless the planner chooses an existing browser-test file. [VERIFIED: .context/chromium/src/chrome/browser/prometheus/BUILD.gn; VERIFIED: .context/chromium/src/chrome/browser/ui/views/prometheus/BUILD.gn]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | yes | Phase 17 session registry validation before all page routes. [VERIFIED: .context/chromium/src/chrome/browser/prometheus/prometheus_agent_service.cc; VERIFIED: .context/chromium/src/chrome/browser/prometheus/prometheus_agent_session.h] |
| V3 Session Management | yes | Touch session on every route and keep per-session/tab ownership data. [VERIFIED: .context/chromium/src/chrome/browser/prometheus/prometheus_agent_service.cc; VERIFIED: .context/chromium/src/chrome/browser/prometheus/prometheus_agent_tab_data.h] |
| V4 Access Control | yes | Profile-scoped target resolution, tab ownership enforcement, route allowlist, normal-page-only policy, and explicit restricted-frame failures. [VERIFIED: .context/chromium/src/chrome/browser/prometheus/prometheus_agent_service.cc; VERIFIED: .planning/phases/18-page-adapter-dom-snapshot-and-action-verification/18-CONTEXT.md] |
| V5 Input Validation | yes | Bound and validate selector, ref, JS, typed text, key, scroll, file path, and frame inputs before renderer dispatch. [VERIFIED: .planning/phases/18-page-adapter-dom-snapshot-and-action-verification/18-CONTEXT.md] |
| V6 Cryptography | no new crypto | Do not add cryptography in Phase 18; preserve existing session identifiers and do not hand-roll crypto. [VERIFIED: .planning/phases/18-page-adapter-dom-snapshot-and-action-verification/18-CONTEXT.md] |

### Known Threat Patterns for Chromium Page Adapter

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Confused deputy across tabs/profiles | Elevation of privilege | Resolve targets through Phase 17 profile-scoped browser/tab ownership before page operations. [VERIFIED: .context/chromium/src/chrome/browser/prometheus/prometheus_agent_service.cc] |
| Cross-origin or restricted-frame content leak | Information disclosure | Use APC redaction/frame policy, active/live RFH checks, and typed denial instead of fallback to another frame. [VERIFIED: .context/chromium/src/components/optimization_guide/content/browser/page_content_proto_provider.cc; VERIFIED: .planning/phases/18-page-adapter-dom-snapshot-and-action-verification/18-CONTEXT.md] |
| Renderer-controlled selector/ref spoofing | Tampering / Elevation of privilege | Treat selectors/refs as untrusted, bind refs to snapshot+document identity, and re-resolve at action time. [VERIFIED: .planning/phases/18-page-adapter-dom-snapshot-and-action-verification/18-CONTEXT.md; VERIFIED: .context/chromium/src/components/optimization_guide/content/browser/page_content_proto_util.h] |
| TOCTOU navigation/frame swap | Tampering / Spoofing | Use `WeakDocumentPtr`, RFH identity, `WebContentsObserver`, and time-of-use validation before renderer invocation. [VERIFIED: .context/chromium/src/content/public/browser/render_frame_host.h; VERIFIED: .context/chromium/src/chrome/browser/actor/tools/script_tool_host.cc] |
| Audit/content exfiltration | Information disclosure | Keep page text, DOM, scripts, typed text, file paths, and secrets out of `changed_state` and audit records. [VERIFIED: .context/chromium/src/chrome/browser/prometheus/prometheus_agent_service.cc; VERIFIED: .planning/phases/18-page-adapter-dom-snapshot-and-action-verification/18-CONTEXT.md] |
| Arbitrary local file access via drop | Information disclosure / Tampering | Deny unapproved file paths and require explicit safe file handle/path policy before implementing file drop. [VERIFIED: .planning/phases/18-page-adapter-dom-snapshot-and-action-verification/18-CONTEXT.md] |
| Infinite repeated actions | Denial of service | Store recent session/tab/action fingerprints and return typed stuck/repeated-action results. [VERIFIED: .planning/phases/18-page-adapter-dom-snapshot-and-action-verification/18-CONTEXT.md] |

## Sources

### Primary (HIGH confidence)

- `.planning/phases/18-page-adapter-dom-snapshot-and-action-verification/18-CONTEXT.md` - locked decisions, phase scope, route surface, security/test constraints. [VERIFIED: local file read]
- `.planning/REQUIREMENTS.md` - PAGE-01 through PAGE-08 requirement text. [VERIFIED: local file read]
- `.planning/STATE.md` - current phase state and Phase 17 carry-forward history. [VERIFIED: local file read]
- `.planning/ROADMAP.md` - Phase 18 goal, success criteria, and planned work. [VERIFIED: local file read]
- `.planning/phases/17-native-agent-command-service-and-tab-ownership/17-CONTEXT.md` - direct dependency decisions and Phase 18 handoff. [VERIFIED: local file read]
- `.planning/phases/17-native-agent-command-service-and-tab-ownership/17-VERIFICATION.md` - verified Phase 17 route/session/ownership boundary and gates. [VERIFIED: local file read]
- `.planning/phases/17-native-agent-command-service-and-tab-ownership/17-REVIEW.md` - clean review and residual risk about arbitrary browser pointer trust. [VERIFIED: local file read]
- `.context/chromium/src/chrome/browser/prometheus/prometheus_agent_route.h` and `.cc` - current route/result/error schema. [VERIFIED: local source read]
- `.context/chromium/src/chrome/browser/prometheus/prometheus_agent_service.h` and `.cc` - route validation, target resolution, ownership, audit, internal surface policy. [VERIFIED: local source read]
- `.context/chromium/src/chrome/browser/prometheus/prometheus_agent_service_browsertest.cc` - existing Prometheus browser-test patterns. [VERIFIED: local source read]
- `.context/chromium/src/chrome/browser/prometheus/prometheus_agent_tab_data.h` and `.cc` - tab ownership data. [VERIFIED: local source read]
- `.context/chromium/src/content/public/browser/web_contents.h` - WebContents page/frame traversal API and unsafe frame lookup warning. [VERIFIED: local source read]
- `.context/chromium/src/content/public/browser/render_frame_host.h` - RFH identity, lifecycle, frame policy, weak document, and JS execution boundaries. [VERIFIED: local source read]
- `.context/chromium/src/content/public/test/browser_test_utils.h` - browser-test-only JS/input/load helpers. [VERIFIED: local source read]
- `.context/chromium/src/components/content_extraction/content/browser/inner_text.h` - inner-text API and limitations. [VERIFIED: local source read]
- `.context/chromium/src/components/optimization_guide/content/browser/page_content_proto_provider.h/.cc` - AI page content API, modes, and live main-frame failure. [VERIFIED: local source read]
- `.context/chromium/src/components/optimization_guide/content/browser/page_content_proto_util.h/.cc` - APC node/document lookup utilities and active-frame RFH lookup. [VERIFIED: local source read]
- `.context/chromium/src/components/page_content_annotations/content/browser/page_settled_monitor.h` - page settling architecture. [VERIFIED: local source read]
- `.context/chromium/src/chrome/browser/actor/tools/*.cc/.h` and `.context/chromium/src/chrome/common/chrome_render_frame.mojom` - production page/action/script tool patterns. [VERIFIED: local source read]
- `.context/chromium/src/chrome/browser/prometheus/BUILD.gn`, `.context/chromium/src/chrome/browser/ui/views/prometheus/BUILD.gn`, `.context/chromium/src/chrome/test/BUILD.gn` - unit/browser test target wiring. [VERIFIED: local source read]

### Secondary (MEDIUM confidence)

- None used; local Chromium source and phase artifacts were sufficient. [VERIFIED: research log]

### Tertiary (LOW confidence)

- None used. [VERIFIED: research log]

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH, because recommended APIs and build/test wiring were verified in the local Chromium checkout. [VERIFIED: local source review]
- Architecture: HIGH for route/ownership/read/snapshot/wait boundaries, because Phase 17 and Chromium APIs are explicit. [VERIFIED: .context/chromium/src/chrome/browser/prometheus/prometheus_agent_service.cc; VERIFIED: .context/chromium/src/components/optimization_guide/content/browser/page_content_proto_provider.h; VERIFIED: .context/chromium/src/components/page_content_annotations/content/browser/page_settled_monitor.h]
- Action dispatch: MEDIUM, because actor code is a strong reference but the planner must decide direct reuse versus a Prometheus renderer seam. [VERIFIED: .context/chromium/src/chrome/browser/actor/tools/page_tool.cc; ASSUMED]
- Pitfalls: HIGH, because major pitfalls are documented in public headers or locked phase decisions. [VERIFIED: .context/chromium/src/content/public/browser/render_frame_host.h; VERIFIED: .context/chromium/src/content/public/browser/web_contents.h; VERIFIED: .planning/phases/18-page-adapter-dom-snapshot-and-action-verification/18-CONTEXT.md]
- Security: HIGH for route/audit/input/frame boundaries and MEDIUM for file drop until the safe file policy is chosen. [VERIFIED: .planning/phases/18-page-adapter-dom-snapshot-and-action-verification/18-CONTEXT.md; ASSUMED]

**Research date:** 2026-07-07 [VERIFIED: system date]
**Valid until:** Next Chromium rebase or 2026-08-06, whichever comes first, because Chromium internal APIs and actor implementation details can shift across rebases. [ASSUMED]
