---
phase: 19
slug: mcp-bridge-and-multi-agent-runtime-compatibility
status: complete
researched: 2026-07-12
confidence: high
---

# Phase 19 Research: MCP Bridge and Multi-Agent Runtime Compatibility

## Executive Summary

Phase 19 is not a small adapter around an already-running service. The verified
Phase 17/18 route core exists, but it is constructed only by browser tests. No
production profile service, lifecycle hook, JSON codec, loopback listener,
endpoint descriptor, or external bridge currently exists.

The recommended design has two cleanly separated authorities:

1. A profile-keyed Chromium service owns sessions, tab ownership, permissions,
   page/frame resolution, action execution, audit, and diagnostics.
2. A Prometheus-owned, dependency-free Node stdio process implements MCP
   lifecycle/schema compatibility and forwards bounded requests to the native
   service over an authenticated ephemeral loopback endpoint.

The external process is a connector launched by Claude Code, Cursor, Codex, or
another MCP host. It neither contains nor launches an agent engine. The browser
never embeds a third-party CLI, terminal, alternate engine, or CLI-specific
prompt.

## Confirmed Current State

### Reusable Chromium core

- `prometheus_agent_route.{h,cc}` provides closed route/error enums and typed
  request/result structs for tabs, navigation, internal surfaces, page reads,
  snapshots, JavaScript, and safe page actions.
- `prometheus_agent_session.{h,cc}` provides opaque browser-issued session IDs,
  a cap, touch/expiry, and typed failure results.
- `prometheus_agent_tab_data.{h,cc}` attaches ownership to stable
  `tabs::TabInterface` identity rather than mutable indices.
- `prometheus_agent_service.{h,cc}` resolves targets within the profile of the
  supplied browser, enforces ownership, dispatches synchronous tab routes and
  asynchronous page routes, and finishes every route through the audit seam.
- `prometheus_page_adapter.{h,cc}` and its helpers implement verified normal-page
  reads, snapshots, permissioned isolated-world JavaScript, actions, waits,
  mutation readback, and restricted-frame denial.
- `prometheus_render_frame.mojom` plus the renderer observer/dispatcher provide
  the existing exact-frame script/action IPC seam.

### Production wiring gaps

`PrometheusAgentService` is constructed only in
`prometheus_agent_service_browsertest.cc` and
`prometheus_page_adapter_browsertest.cc`. Its source set is linked by the
Prometheus browser-test source set, not normal browser startup. It requires an
injected `AgentSessionRegistry*` and a caller-supplied
`BrowserWindowInterface*`; production owns neither.

Missing pieces:

- regular-profile keyed lifetime and factory;
- process-global gateway startup/shutdown;
- authenticated endpoint discovery;
- JSON request/result codec and bounds;
- MCP tool catalog, schemas, aliases, and compatibility errors;
- Node stdio lifecycle;
- structured tab/window results;
- native `get_text`/`get_attribute` routes;
- truthful layered diagnostics;
- real browser-to-stdio smoke coverage.

### Correctness gaps exposed by transport

- Closing or expiring a session does not release tabs owned by that session.
  Without repair, future sessions can receive permanent `TAB_NOT_OWNED` on an
  orphaned owner.
- `list_tabs` returns `changed_state` strings such as `tab:<handle>` instead of
  structured title, URL, active, window, ownership, and health metadata.
- `open_tab` always activates the new tab; current FSB-style clients expect an
  explicit background path.
- `get_text` and arbitrary `get_attribute` are absent. Snapshot data cannot
  safely synthesize all attributes.
- Page-level scroll/key compatibility differs from current ref-targeted action
  contracts and must be mapped explicitly or rejected with guidance.

## Protocol Research

The current official MCP specification version is `2025-11-25`. Its stdio
transport requires individual UTF-8 JSON-RPC messages separated by newlines;
stdout cannot contain logs or non-protocol text. The archived v1 bridge instead
used LSP-style `Content-Length` framing. Phase 19 should use newline framing by
default and retain a connection-local `Content-Length` compatibility mode for
the frozen v1 smoke/client behavior.

The lifecycle is initialize -> initialized notification -> operation -> stream
closure. Protocol version negotiation must echo a supported requested version
or return another supported version; a server should not always claim the old
`2024-11-05` version. Requests need timeouts and cancellation handling.

Application/tool errors belong in `tools/call` results with `isError: true`.
JSON-RPC errors are reserved for malformed messages, unknown methods, invalid
protocol parameters, and server/protocol failures. Structured results should
also include a serialized text block for broad client compatibility.

Official guidance says stdio credentials should come from the environment or
local process context rather than MCP HTTP OAuth. The native browser hop is an
internal custom transport, so it needs its own strong local controls: loopback
bind, random bearer token, owner-only descriptor, origin/host rejection, and
bounded requests.

The official TypeScript SDK v2 is pre-alpha as of this research, with v1.x still
recommended for production. Prometheus does not need SDK-only capabilities for
tools/list/call and would otherwise have to package a dependency tree. A small
clean-room Node 20 implementation is therefore lower risk if its JSON-RPC,
framing, lifecycle, and schema behavior are fixture-locked.

Primary protocol references:

- https://modelcontextprotocol.io/specification/2025-11-25/basic/transports
- https://modelcontextprotocol.io/specification/2025-11-25/basic/lifecycle
- https://modelcontextprotocol.io/specification/2025-11-25/server/tools
- https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization
- https://modelcontextprotocol.io/docs/tutorials/security/security_best_practices
- https://github.com/modelcontextprotocol/typescript-sdk

## Clean-Room and Licensing Boundary

The preserved Falkon implementation is inside the GPL preservation bundle. The
current `.context/fsb-reference/mcp/package.json` identifies the reference
implementation as BUSL-1.1. Both are behavior-contract evidence only.

Phase 19 may use their public tool names, request/response shapes, typed error
vocabulary, and tests as compatibility facts. It must not copy implementation
code or long descriptions. New Chromium C++ and Node modules should be written
from the phase context, official MCP specification, concise clean-room schemas,
and observable compatibility fixtures.

## Compatibility Inventory

### Frozen Prometheus v1 catalog

The archived bridge exposed 46 names:

- tabs/navigation: `list_tabs`, `new_tab`, `switch_tab`, `navigate`, `reload`,
  `close_tab`, `wait_for_load`;
- reads: `read_page`, `get_text`, `get_attribute`, `get_dom_snapshot`,
  `get_page_snapshot`;
- actions: `execute_js`, `click`, `type`, `press_key`, `scroll`, `hover`,
  `select`, `clear`, `drag_drop`;
- browser: `diagnostics`, `open_internal_surface`;
- tasks/providers: `submit_task`, `cancel_task`, `task_status`, `list_tasks`,
  `get_provider_config`, `list_providers`, `discover_models`,
  `set_provider_config`;
- logs/memory/guides: `list_runtime_logs`, `action_history`,
  `runtime_diagnostics`, `save_memory`, `list_memory`, `save_site_guide`,
  `list_site_guides`;
- vault: `create_vault_entry`, `list_vault_entries`, `vault_autofill`;
- supervision: `create_supervision_pairing`, `start_supervision_session`,
  `get_supervision_snapshot`, `get_supervision_diff`,
  `end_supervision_session`.

Its schemas were intentionally permissive and declared only the optional
visual fields. Phase 19 should preserve callable names but tighten schemas
where the real route contract is known.

### Current FSB reference catalog

The current reference exposes 59 handlers across manual actions, reads,
autopilot, observability, vault, and removed visual-session stubs. Only 15 names
overlap exactly with the frozen 46; their union contains 90 names.

The compatibility manifest must fixture-lock the two input sets and assign all
90 union names exactly one disposition:

- `native`: implemented safely by Chromium now;
- `alias`: translated to a native route without contract loss;
- `typed_stub`: name and schema remain discoverable, behavior is unsupported;
- `later_phase`: owner and recovery identify Phase 20 or 21;
- `removed`: explicit `TOOL_REMOVED` result and replacement guidance.

Raw tool count is not acceptance. Zero silently unmapped names is acceptance.

### Recommended native/alias set

Native or direct alias candidates:

- tab/navigation: `list_tabs`, `open_tab`, `new_tab`, `switch_tab`,
  `activate_tab`, `navigate`, `refresh`, `reload`, `go_back`, `back`,
  `go_forward`, `close_tab`;
- reads: `read_page`, `get_text`, `get_attribute`, `get_dom_snapshot`,
  `get_page_snapshot`;
- actions: `execute_js`, `click`, `type_text`, `type`, `press_enter`,
  `press_key`, `scroll`, `hover`, `select_option`, `select`, `clear_input`,
  `clear`;
- browser: `diagnostics` and explicit named Prometheus internal surfaces.

`open_tab`/`new_tab` need a foreground option and should default to background.
Only switch/activate should foreground by definition.

### Typed stubs and later owners

- Coordinate tools, drag variants, unsafe mutation tools, spreadsheet tools,
  waits that no longer match the native model, and unimplemented interaction
  variants remain discoverable with `UNSUPPORTED_ROUTE` or
  `CAPABILITY_NOT_READY` plus replacements.
- Task/autopilot, providers, runtime logs/observability, memory/site guides, and
  vault names are Phase 20-owned stubs.
- Supervision/pairing/snapshot/diff names are Phase 21-owned stubs.
- Explicit `start_visual_session`/`end_visual_session` are removed in the
  current FSB contract and return `TOOL_REMOVED` with the implicit field recipe.
- Retired background-agent/third-party-agent names never become an embedded
  engine; if retained for compatibility, they return removal guidance.

## Recommended Native Architecture

### 1. Profile-keyed service

Add a regular-profile-only keyed wrapper/factory under
`chrome/browser/prometheus/`. It owns `AgentSessionRegistry` and
`PrometheusAgentService`, and uses Chromium `ProfileSelections` to exclude OTR.
Model factory lifetime on `chrome/browser/actor/actor_keyed_service_factory.*`
without importing actor policy.

The gateway records the selected regular profile when it creates a session and
routes every later request through the matching keyed service. A session ID is
opaque authority; a client label and profile path are not.

Production defaults:

- active-session cap: 8, with a bounded 1–64 configuration seam;
- reconnect grace: 10 seconds;
- bridge heartbeat: frequent enough to keep a live stdio process active;
- graceful close: immediate session/tab release;
- abrupt loss: expiry after the grace;
- expired owner: released before ownership denial to a current session.

### 2. Browser route contract and codec

Extend the plain-data route contract with:

- bounded visual metadata (`visual_reason`, `client`, `is_final`);
- structured tab/window metadata;
- explicit tab foreground preference;
- element attribute name and safe element-read result;
- diagnostics component records;
- optional closed compatibility detail fields;
- stable serialization helpers and body/result bounds.

The JSON codec accepts only known fields, normalizes numeric strings for
numeric schema fields, rejects conflicting target aliases, and constructs the
typed C++ request. It never dispatches from arbitrary route strings without the
closed enum lookup.

### 3. Missing safe element reads

Implement `get_text` and `get_attribute` through a bounded renderer read IPC.
The browser first performs the same fresh APC ref/selector resolution and exact
document/frame policy used by actions, then the renderer resolves the browser-
validated DOM node in that exact frame. The renderer returns a bounded value
and explicit presence flag. It does not execute caller JavaScript, mutate DOM,
or fall back to another frame.

### 4. Process-global secure gateway

Add a desktop `ChromeBrowserMainExtraParts` hook that starts after profile/UI
initialization and stops before teardown. The server follows the existing
Chromium pattern in `components/ui_devtools/devtools_server.cc`:

- dedicated IO sequence;
- `net::TCPServerSocket` bound to `127.0.0.1:0`;
- `net::HttpServer` delegate;
- bounded UI/IO posts with weak cancellation;
- no IPv4 wildcard, external interface, or browser-accessible CORS path.

Suggested versioned endpoints:

- `POST /v1/session/create`
- `POST /v1/session/resume`
- `POST /v1/session/touch`
- `POST /v1/session/close`
- `POST /v1/agent/command`
- `GET /v1/health`

Every endpoint requires the descriptor bearer. Reject any `Origin` header,
non-loopback host/peer, unsupported content type/method, oversized body,
malformed JSON, and excessive in-flight work. Page/action requests retain their
existing timeouts; the gateway adds an outer bounded completion and exactly-once
shutdown result.

Generate a fresh token/nonce per browser process and atomically publish a
mode-0600 descriptor in the per-user runtime/temp directory. Include endpoint,
protocol, PID, and nonce. The shutdown path deletes the file only when its
nonce still belongs to this process, preventing an older instance from deleting
a newer descriptor.

### 5. External stdio bridge

Place clean-room production glue under root `tools/prometheus-mcp/`, separate
from Chromium source and from the archived Falkon bridge. Use only Node 20
built-ins (`readline`/streams, `fetch`, `fs`, `os`, `crypto`, `AbortController`).

Modules should separate:

- MCP framing/lifecycle;
- compatibility manifest and JSON Schemas;
- schema normalization/numeric coercion;
- native endpoint discovery/auth/fetch;
- per-session heartbeat/reconnect/close;
- tool-result/error mapping;
- smoke/client fixtures.

The MCP host launches this Prometheus adapter. The adapter never launches the
host or any third-party agent executable.

## Visual-Session Contract

For v1 compatibility, `visual_reason`, `client`, and `is_final` remain optional
on action tools. When supplied:

- reason and client must be nonempty and bounded;
- known badge labels are normalized against the FSB compatibility allowlist;
- unknown supplied badges return `BADGE_NOT_ALLOWED`;
- the field bundle survives aliasing and the native request envelope;
- it is never identity, ownership, or permission authority;
- reason content never enters audit, logs, descriptor, changed-state, or error
  messages;
- read-only calls do not start/refresh visual state;
- explicit visual-session start/end names return the removal recipe.

Newer external clients may omit the bundle and receive safe generic external
client presentation. Phase 21 owns the visible sliding lifecycle.

## Numeric and Target Compatibility

Some MCP hosts stringify JSON numbers. Numeric schema fields accept a JSON
number or nonempty numeric string, then normalize before the native call.

Reject:

- empty/whitespace strings;
- NaN and infinity;
- fractions for integer fields;
- overflow/out-of-range values;
- negative identifiers where positive IDs are required.

Support `tab_id`, `tabId`, and legacy `tabIndex` in the compatibility layer.
Stable `TabHandle` identity is canonical. A mutable index is resolved at call
time and never stored as ownership authority. Conflicting target forms fail
with `INVALID_TARGET`.

## Diagnostics Shape

Return a bounded component map with these stable keys:

- `browser`
- `bridge`
- `active_tab`
- `content_adapter`
- `internal_adapter`
- `webui_adapter`
- `vault`
- `provider`
- `supervision`
- `extensions`

Each reports a closed status such as `ready`, `degraded`, `not_ready`, or
`unavailable`, a stable reason, and a next action. Phase 20–22 components must
report their true later-phase state, not fake empty success or overall failure.
No token, page text, secret, profile path, script, or raw prompt is diagnostic
data.

## Validation Architecture

### Fast Node tests

- newline and archived `Content-Length` framing;
- initialize/version negotiation/initialized/ping/shutdown;
- stdout protocol cleanliness and stderr-only logs;
- all 90 names mapped exactly once;
- schema fixtures and aliases;
- numeric-string coercion plus invalid numeric rejection;
- visual-field forwarding and badge denial;
- native typed error and structured result mapping;
- removed/unsupported/later-phase stubs;
- cancellation, endpoint rediscovery, heartbeat, resume, close;
- malformed/oversized message bounds.

### C++ unit tests

- route/JSON round-trip and strict parsing;
- target alias conflicts;
- visual metadata bounds and audit exclusion;
- structured result serialization bounds;
- profile session cap, heartbeat/touch, resume, expiry, and ownership release;
- gateway request auth/host/origin/content-type/body/concurrency gates;
- endpoint descriptor mode/nonce behavior;
- diagnostics component schema;
- exact-frame element-read results and renderer bounds.

### Browser tests

- profile-keyed service excludes OTR and cannot cross profiles;
- two sessions enforce ownership and cap;
- abrupt expiry and graceful close release ownership;
- explicit background route does not change active tab;
- structured tab metadata remains stable across reorder;
- `get_text`/`get_attribute` succeed for same-origin exact targets and deny
  restricted/stale targets without fallback;
- real gateway create/touch/command/close and unauthorized denial;
- UI/IO shutdown during async page work completes exactly once;
- diagnostics reflect real and later-phase components.

### End-to-end smoke

Launch the built Prometheus browser with an isolated user-data directory and
explicit endpoint descriptor, serve a local fixture page, spawn the external
stdio bridge, and perform:

1. initialize + initialized;
2. tools/list;
3. background open/navigate without activation theft;
4. read page plus get text/attribute;
5. one verified action or JavaScript route;
6. a typed unsupported/later-phase tool result;
7. diagnostics;
8. a second-session ownership denial and reconnect/cleanup check.

No human UAT or screenshot review is required. Full Phase 17/18 unit/browser
regressions, Chromium environment, GPL guard, artifact isolation,
preservation, static no-embedded-runtime scans, and diff checks remain gates.

## Recommended Plan Structure

1. **19-01 — Compatibility manifest and validation foundation.** Clean-room
   90-name disposition/schema fixtures, result/error vocabulary, visual/numeric
   rules, Node test harness, and Phase 19 validation map.
2. **19-02 — Browser route/JSON/diagnostic contracts.** Plain-data extensions,
   strict codec, structured metadata, bounds, and unit tests.
3. **19-03 — Production profile service and session cleanup.** Keyed factory,
   cap/heartbeat/resume/expiry behavior, orphan ownership repair, OTR denial.
4. **19-04 — Missing native compatibility surfaces.** Structured tabs,
   background open, exact-frame `get_text`/`get_attribute`, renderer/browser
   tests.
5. **19-05 — Secure browser gateway.** Browser-main lifetime, loopback HTTP,
   descriptor/auth/bounds/shutdown, health, and browser tests.
6. **19-06 — External stdio MCP bridge.** Protocol lifecycle, manifest-backed
   tools, aliases/stubs, session heartbeat/reconnect, visual and numeric
   compatibility, Node tests.
7. **19-07 — End-to-end smoke and closeout.** Live browser-to-stdio smoke,
   two-agent/background/diagnostic/security regressions, patch export,
   preservation update, and phase verification inputs.

## Planning Risks

1. **Thread/lifetime risk:** `net::HttpServer` callbacks and async page routes
   cross IO/UI shutdown. Require weak ownership and exactly-once completion.
2. **Profile confused deputy:** last-active browser selection cannot let a
   session migrate profiles. Pin the profile at session creation.
3. **Orphaned ownership:** fix close/expiry release before exposing sessions.
4. **Catalog drift:** generate tests from two frozen name fixtures and fail on
   unmapped/duplicate dispositions.
5. **Schema coercion ambiguity:** coerce only declared numeric fields, twice
   bounded in Node and C++.
6. **False parity:** stubs must fail truthfully with owner/recovery, never
   return empty success.
7. **Token disclosure:** descriptor is the only token bootstrap; health/logs/
   audit/responses never reveal it.
8. **License contamination:** write concise clean-room schemas/implementation;
   do not paste preserved GPL/BUSL code or descriptions.

## Conclusion

Phase 19 is feasible without revisiting the abandoned embedded-runtime plan.
The safest path is to productionize the existing browser authority, expose a
small authenticated local route boundary, and put protocol compatibility in an
external Prometheus-owned adapter. That preserves Claude Code and other MCP
clients while keeping third-party agent execution entirely outside the browser.

---
*Phase: 19-mcp-bridge-and-multi-agent-runtime-compatibility*
